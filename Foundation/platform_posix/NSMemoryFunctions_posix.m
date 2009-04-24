/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSPlatform.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

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

static pthread_key_t _NSThreadInstanceKey() {
	static pthread_key_t key = -1;	
	if (key == -1) 
	{
		if (pthread_key_create(&key, NULL) != 0)
			[NSException raise:NSInternalInconsistencyException format:@"pthread_key_create failed"];
	}

	return key;
}

void NSPlatformSetCurrentThread(NSThread *thread) {
	pthread_setspecific(_NSThreadInstanceKey(), thread);
}

NSThread *NSPlatformCurrentThread() {
	NSThread *thread=pthread_getspecific(_NSThreadInstanceKey());
	
	if(!thread)
	{
		// maybe NSThread is not +initialize'd
		[NSThread class];
		thread=pthread_getspecific(_NSThreadInstanceKey());
		if(!thread)
		{
			[NSException raise:NSInternalInconsistencyException format:@"No current thread"];
		}
	}
	
	return thread;
}

int NSPlatformDetachThread(unsigned (*func)(void *arg), void *arg) {
	pthread_t thread;
	pthread_create(&thread, NULL, func, arg);
	return (int)thread;
}

/* This will fail with W^X. See win32 implementation for how to get this running. */

void *_NSClosureAlloc(unsigned size)
{
   return malloc(size);
}

void _NSClosureProtect(void* closure, unsigned size)
{
}
