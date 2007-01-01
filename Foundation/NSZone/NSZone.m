/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSZone.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSDebug.h>

// NSZone functions implemented in platform subproject

// NSAllocateObject implemented in platform subproject
// NSDeallocateObject implemented in platform subproject
// NSCopyObject implemented in platform subproject

BOOL NSShouldRetainWithZone(NSObject *object,NSZone *zone) {
   return (zone==NULL || zone==NSDefaultMallocZone() || zone==[object zone])?YES:NO;
}

typedef struct RefCountBucket {
   struct RefCountBucket *next;
   id                     object;
   unsigned               count;
} RefCountBucket;

typedef struct {
   unsigned         count;
   unsigned         nBuckets;
   RefCountBucket **buckets;
} RefCountTable;

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

static inline unsigned hashObject(id ptr){
   return (unsigned)ptr>>4;
}

static inline RefCountBucket *XXHashGet(RefCountTable *table,id object) {
   unsigned        i=hashObject(object)%table->nBuckets;
   RefCountBucket *check;

   for(check=table->buckets[i];check!=NULL;check=check->next)
    if(check->object==object)
     return check;

   return NULL;
}

static inline void XXHashInsert(RefCountTable *table,RefCountBucket *insert) {
   unsigned hash=hashObject(insert->object);
   unsigned i=hash%table->nBuckets;

   if(table->count>=table->nBuckets){
    int              oldnBuckets=table->nBuckets;
    RefCountBucket **buckets=table->buckets;

    table->nBuckets=oldnBuckets*2;
    table->buckets=NSZoneCalloc(NULL,table->nBuckets,sizeof(RefCountBucket *));
    for(i=0;i<oldnBuckets;i++){
     RefCountBucket *check,*next;

     for(check=buckets[i];check!=NULL;check=next){
      unsigned newi=hashObject(check->object)%table->nBuckets;
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
   unsigned        i=hashObject(remove->object)%table->nBuckets;
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
   static RefCountTable *table=NULL;

   if(table==NULL)
    table=CreateRefCountTable();
   return table;
}

void NSIncrementExtraRefCount(id object) {
   RefCountBucket *refCount;
   RefCountTable  *table=refTable();

   if((refCount=XXHashGet(table,object))==NULL){
    refCount=AllocBucketFromTable(table);
    refCount->object=object;
    refCount->count=1;
    XXHashInsert(refTable(),refCount);
   }
   refCount->count++;
}

BOOL NSDecrementExtraRefCountWasZero(id object) {
   BOOL            result=NO;
   RefCountBucket *refCount;

   if((refCount=XXHashGet(refTable(),object))==NULL)
    result=YES;
   else {
    refCount->count--;
    if(refCount->count==1)
     XXHashRemove(refTable(), refCount);
   }

   return result;
}

unsigned NSExtraRefCount(id object) {
   unsigned        result=1;
   RefCountBucket *refCount;

   if((refCount=XXHashGet(refTable(),object))!=NULL)
    result=refCount->count;

   return result;
}
