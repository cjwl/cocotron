/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSZone.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSDebug.h>
#include <string.h>
#ifdef WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif
// NSZone functions implemented in platform subproject

typedef unsigned int OSSpinLock;

#import <Foundation/NSAtomicCompareAndSwap.h>

BOOL OSSpinLockTry( volatile OSSpinLock *__lock )
{
   return __sync_bool_compare_and_swap(__lock, 0, 1);
}

void OSSpinLockLock( volatile OSSpinLock *__lock )
{
   while(!__sync_bool_compare_and_swap(__lock, 0, 1))
   {
#ifdef WIN32
      Sleep(0);
#else
      usleep(1);
#endif
   }
}

void OSSpinLockUnlock( volatile OSSpinLock *__lock )
{
   __sync_bool_compare_and_swap(__lock, 1, 0);
}

typedef struct RefCountBucket {
   struct RefCountBucket *next;
   id                     object;
   NSUInteger             count;
} RefCountBucket;

typedef struct {
   NSUInteger       count;
   NSUInteger       nBuckets;
   RefCountBucket **buckets;
} RefCountTable;

static OSSpinLock RefCountLock=0;

static inline RefCountTable *CreateRefCountTable() {
   RefCountTable *table;

   table=NSZoneMalloc(NULL,sizeof(RefCountTable));
   table->count=0;
   table->nBuckets=1024;
   table->buckets=NSZoneCalloc(NULL,table->nBuckets,sizeof(RefCountBucket *));

   return table;
}

static inline RefCountBucket *AllocBucketFromTable(RefCountTable *table){
   return NSZoneMalloc(NULL,sizeof(RefCountBucket));
}

static inline void FreeBucketFromTable(RefCountTable *table,RefCountBucket *bucket){
   NSZoneFree(NULL,bucket);
}

static inline NSUInteger hashObject(id ptr){
   return (NSUInteger)ptr>>4;
}

static inline RefCountBucket *XXHashGet(RefCountTable *table,id object) {
   NSUInteger      i=hashObject(object)%table->nBuckets;
   RefCountBucket *check;

   for(check=table->buckets[i];check!=NULL;check=check->next)
    if(check->object==object)
     return check;

   return NULL;
}

static inline void XXHashInsert(RefCountTable *table,RefCountBucket *insert) {
   NSUInteger hash=hashObject(insert->object);
   NSUInteger i=hash%table->nBuckets;

   if(table->count>=table->nBuckets){
    NSInteger        oldnBuckets=table->nBuckets;
    RefCountBucket **buckets=table->buckets;

    table->nBuckets=oldnBuckets*2;
    table->buckets=NSZoneCalloc(NULL,table->nBuckets,sizeof(RefCountBucket *));
    for(i=0;i<oldnBuckets;i++){
     RefCountBucket *check,*next;

     for(check=buckets[i];check!=NULL;check=next){
      NSUInteger newi=hashObject(check->object)%table->nBuckets;
      next=check->next;
      check->next=table->buckets[newi];
      table->buckets[newi]=check;
     }
    }
    NSZoneFree(NULL,buckets);
    i=hash%table->nBuckets;
   }

   insert->next=table->buckets[i];
   table->buckets[i]=insert;
   table->count++;
}

static inline void XXHashRemove(RefCountTable *table,RefCountBucket *remove) {
   NSUInteger      i=hashObject(remove->object)%table->nBuckets;
   RefCountBucket *check=table->buckets[i],*prev=check;

   for(;check!=NULL;check=check->next){
    if(check==remove){
     if(prev==check)
      table->buckets[i]=check->next;
     else
      prev->next=check->next;

     FreeBucketFromTable(table,check);
     table->count--;
     return;
    }
    prev=check;
   }
}

static inline RefCountTable *refTable(void) {
   static RefCountTable *refCountTable=NULL;

   if(refCountTable==NULL)
    refCountTable=CreateRefCountTable();

   return refCountTable;
}

void NSIncrementExtraRefCount(id object) {
   RefCountBucket *refCount;
   RefCountTable  *table=refTable();

   OSSpinLockLock(&RefCountLock);
   if((refCount=XXHashGet(table,object))==NULL){
    refCount=AllocBucketFromTable(table);
    refCount->object=object;
    refCount->count=1;
    XXHashInsert(refTable(),refCount);
   }
   refCount->count++;
   OSSpinLockUnlock(&RefCountLock);
}

BOOL NSDecrementExtraRefCountWasZero(id object) {
   BOOL            result=NO;
   RefCountBucket *refCount;

   OSSpinLockLock(&RefCountLock);
   if((refCount=XXHashGet(refTable(),object))==NULL)
    result=YES;
   else {
    refCount->count--;
    if(refCount->count==1)
     XXHashRemove(refTable(), refCount);
   }
   OSSpinLockUnlock(&RefCountLock);

   return result;
}

NSUInteger NSExtraRefCount(id object) {
   NSUInteger      result=1;
   RefCountBucket *refCount;

   OSSpinLockLock(&RefCountLock);
   if((refCount=XXHashGet(refTable(),object))!=NULL)
    result=refCount->count;
   OSSpinLockUnlock(&RefCountLock);

   return result;
}

BOOL NSShouldRetainWithZone(id object,NSZone *zone) {
   return (zone==NULL || zone==NSDefaultMallocZone() || zone==[object zone])?YES:NO;
}


id NSAllocateObject(Class class, NSUInteger extraBytes, NSZone *zone)
{
    id result;

    if (zone == NULL) {
        zone = NSDefaultMallocZone();
    }

    result = NSZoneCalloc(zone, 1, class->instance_size + extraBytes);
#if defined(GCC_RUNTIME_3)
    object_setClass(result, class);
    // TODO As of gcc 4.6.2 the GCC runtime does not have support for C++ constructor calling.
#elif defined(APPLE_RUNTIME_4)
    objc_constructInstance(class, result);
#else
    result->isa = class;

    if (!object_cxxConstruct(result, result->isa)) {
        NSZoneFree(zone, result);
        result = nil;
    }
#endif

    return result;
}


void NSDeallocateObject(id object)
{
#if defined(GCC_RUNTIME_3)
    // TODO As of gcc 4.6.2 the GCC runtime does not have support for C++ destructor calling.
#elif defined(APPLE_RUNTIME_4)
    objc_destructInstance(object);
#else
    object_cxxDestruct(object, object->isa);
#endif

    if (NSZombieEnabled) {
        NSRegisterZombie(object);
    } else {
        NSZone *zone = NULL;

        if (zone == NULL) {
            zone = NSDefaultMallocZone();
        }

#if !defined(GCC_RUNTIME_3) && !defined(APPLE_RUNTIME_4)
        object->isa = 0;
#endif

        NSZoneFree(zone, object);
    }
}


id NSCopyObject(id object, NSUInteger extraBytes, NSZone *zone)
{
    if (object == nil) {
        return nil;
    }

    id result = NSAllocateObject(object_getClass(object), extraBytes, zone);

    memcpy(result, object, class_getInstanceSize(object_getClass(object)) + extraBytes);

    return result;
}
