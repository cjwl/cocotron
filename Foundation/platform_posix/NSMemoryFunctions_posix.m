/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/ObjCClass.h>

#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>
#import <pthread.h>

// some notes:
// - this uses POSIX thread local storage functions
// - there is no zone support

void *NSAllocateMemoryPages(unsigned byteCount) {
   return malloc(byteCount);
}

void NSDeallocateMemoryPages(void *pointer,unsigned byteCount) {
   free(pointer);
}

void NSCopyMemoryPages(const void *src,void *dst,unsigned byteCount) {
   const unsigned char *srcb=src;
   unsigned char       *dstb=dst;
   int                  i;

   for(i=0;i<byteCount;i++)
    dstb[i]=srcb[i];
}

NSThread *NSPlatformCurrentThread() {
   static pthread_key_t key = -1;
   NSThread *thread;

   if (key == -1) 
      if (pthread_key_create(&key, NULL) != 0)
         return nil;

   thread = pthread_getspecific(key);
   if(thread==nil) {
    thread=[[NSThread alloc] init];
    pthread_setspecific(key, thread);
   }

   return thread;
}

id NSAllocateObject(Class class,unsigned extraBytes,NSZone *zone) {
    id result;

    result=calloc(1,class->instance_size+extraBytes);
    result->isa=class;
	
	if(!object_cxxConstruct(result, result->isa))
	{
		free(result);
		result=nil;
	}

    return result;
}

void NSDeallocateObject(id object) {
	object_cxxDestruct(object, object->isa);

   if(NSZombieEnabled)
    NSRegisterZombie(object);
   else 
    free(object);
}

static inline void byteCopy(void *vsrc,void *vdst,unsigned length){
   unsigned char *src=vsrc;
   unsigned char *dst=vdst;
   unsigned i;

   for(i=0;i<length;i++)
    dst[i]=src[i];
}

id NSCopyObject(id object,unsigned extraBytes,NSZone *zone) {
   id result=NSAllocateObject(object->isa,extraBytes,zone);

   byteCopy(object,result,object->isa->instance_size+extraBytes);

   return result;
}

NSZone *NSCreateZone(unsigned startSize,unsigned granularity,BOOL canFree){
   return NULL;
}

NSZone *NSDefaultMallocZone(void){
   return NULL;
}

void NSRecycleZone(NSZone *zone) {
}

void NSSetZoneName(NSZone *zone,NSString *name){

}

NSString *NSZoneName(NSZone *zone) {
   return @"zone";
}

NSZone *NSZoneFromPointer(void *pointer){
   return NULL;
}

void *NSZoneCalloc(NSZone *zone,unsigned numElems,unsigned numBytes){
   return calloc(numElems,numBytes);
}

void NSZoneFree(NSZone *zone,void *pointer){
   free(pointer);
}

void *NSZoneMalloc(NSZone *zone,unsigned size){
   return malloc(size);
}

void *NSZoneRealloc(NSZone *zone,void *pointer,unsigned size){
   return realloc(pointer, size);
}
