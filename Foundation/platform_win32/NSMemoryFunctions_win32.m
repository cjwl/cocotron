/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSPlatform.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSPlatform_win32.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

#import <windows.h>
#import <process.h>

unsigned NSPageSize(void) {
   SYSTEM_INFO info;

   GetSystemInfo(&info);

   return info.dwPageSize;
}

void *NSAllocateMemoryPages(unsigned byteCount) {
   return VirtualAlloc(NULL,byteCount,MEM_RESERVE|MEM_COMMIT,PAGE_READWRITE);
}

void NSDeallocateMemoryPages(void *pointer,unsigned byteCount) {
   VirtualFree(pointer,byteCount,MEM_RELEASE|MEM_DECOMMIT);
}

void NSCopyMemoryPages(const void *src,void *dst,unsigned byteCount) {
   const unsigned char *srcb=src;
   unsigned char       *dstb=dst;
   int                  i;

   for(i=0;i<byteCount;i++)
    dstb[i]=srcb[i];
}

unsigned NSRealMemoryAvailable(void) {
   MEMORYSTATUS status;

   status.dwLength=sizeof(status);

   GlobalMemoryStatus(&status);

   return status.dwTotalPhys;
}

static DWORD Win32ThreadStorageIndex() {
   static DWORD tlsIndex=0xFFFFFFFF;

   if(tlsIndex==0xFFFFFFFF)
    tlsIndex=TlsAlloc();

   if(tlsIndex==0xFFFFFFFF)
    Win32Assert("TlsAlloc");

   return tlsIndex;
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
   if(pointer==NULL)
    return malloc(size);
   else
    return realloc(pointer,size);
}


void NSPlatformSetCurrentThread(NSThread *thread) {
	TlsSetValue(Win32ThreadStorageIndex(),thread);
}


NSThread *NSPlatformCurrentThread() {
    NSThread *thread=TlsGetValue(Win32ThreadStorageIndex());
	
	if(!thread) {
		// maybe NSThread is not +initialize'd
		[NSThread class];
		thread=TlsGetValue(Win32ThreadStorageIndex());
		if(!thread)	{
			[NSException raise:NSInternalInconsistencyException format:@"No current thread"];
		}
	}

    return thread;
}

/* Create a new thread of execution. */
unsigned NSPlatformDetachThread(unsigned (*__stdcall func)(void *arg), void *arg) {
	unsigned	threadId = 0;
	HANDLE win32Handle = (HANDLE)_beginthreadex(NULL, 0, func, arg, 0, &threadId);
	
	if (!win32Handle) {
		threadId = 0; // just to be sure
	}
	
	CloseHandle(win32Handle);
	return threadId;
}


static void *allocation=NULL;
static long used=0;
const long maxSize=64*1024;

/* This must be protected by some kind of lock.
 It is only called from _closure in objc_forward_ffi.m */
void *_NSClosureAlloc(unsigned size)
{
   if(!allocation ||
      used+size>maxSize)
   {
      allocation=VirtualAlloc(NULL, maxSize, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
      used=0;
   }
   else
   {
      VirtualProtect(allocation, maxSize, PAGE_EXECUTE_READWRITE, NULL);
   }
   
   void *ret=allocation+used;
   used+=size;
   
   return ret;
}

void _NSClosureProtect(void* closure, unsigned size)
{
   VirtualProtect(allocation, maxSize, PAGE_EXECUTE_READ, NULL);
}
