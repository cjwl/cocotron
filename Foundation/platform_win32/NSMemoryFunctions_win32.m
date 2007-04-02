/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSZombieObject.h>
#import <Foundation/NSPlatform_win32.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/ObjCClass.h>

#import <windows.h>

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

NSThread *NSPlatformCurrentThread() {
   NSThread *thread=TlsGetValue(Win32ThreadStorageIndex());

   if(thread==nil){
    thread=[NSThread new];
    TlsSetValue(Win32ThreadStorageIndex(),thread);
   }

   return thread;
}

NSObject *NSAllocateObject(Class class,unsigned extraBytes,NSZone *zone) {
   id result;

   if(class==Nil)
    ;//OBJCRaiseException("OBJCClassIsNilException","OBJCAllocateObject class is Nil");

   if(zone==NULL)
    zone=GetProcessHeap();

   result=HeapAlloc(zone,HEAP_ZERO_MEMORY,class->instance_size+extraBytes);

   if(result==nil)
    ;//OBJCRaiseException("OBJCAllocationFailure","OBJCAllocateObject, OBJCZoneCalloc returned NULL");

    result->isa=class;

//OBJCLog("allocated instance of %s at %d",class->name,result);

    return result;
}

void NSDeallocateObject(NSObject *object) {
   if(NSZombieEnabled)
    NSRegisterZombie(object);
   else {
    NSZone *zone=NULL;

    if(zone==NULL)
     zone=GetProcessHeap();

    HeapFree(zone,0,object);
   }
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
   if(zone==NULL)
    zone=GetProcessHeap();

   return HeapAlloc(zone,HEAP_ZERO_MEMORY,numElems*numBytes);
}

void NSZoneFree(NSZone *zone,void *pointer){
   if(zone==NULL)
    zone=GetProcessHeap();

   HeapFree(zone,0,pointer);
}

void *NSZoneMalloc(NSZone *zone,unsigned size){
   if(zone==NULL)
    zone=GetProcessHeap();

   return HeapAlloc(zone,0,size);
}

void *NSZoneRealloc(NSZone *zone,void *pointer,unsigned size){
   if(zone==NULL)
    zone=GetProcessHeap();

   return HeapReAlloc(zone,0,pointer,size);
}
