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

inline BOOL OSSpinLockTry( volatile OSSpinLock *__lock )
{
   return __sync_bool_compare_and_swap(__lock, 0, 1);
}

inline void OSSpinLockLock( volatile OSSpinLock *__lock )
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

inline void OSSpinLockUnlock( volatile OSSpinLock *__lock )
{
   __sync_bool_compare_and_swap(__lock, 1, 0);
}

typedef unsigned int REF_COUNT_TYPE;

void NSIncrementExtraRefCount(id object) {
    OSSpinLockLock(&((REF_COUNT_TYPE *)object)[-2]);
    ((REF_COUNT_TYPE *)object)[-1]++;
    OSSpinLockUnlock(&((REF_COUNT_TYPE *)object)[-2]);
}

BOOL NSDecrementExtraRefCountWasZero(id object) {
   BOOL            result;
    
    OSSpinLockLock(&((REF_COUNT_TYPE *)object)[-2]);
    ((REF_COUNT_TYPE *)object)[-1]--;
    if (((REF_COUNT_TYPE *)object)[-1] == 0) {
        result = YES;
    }
    else {
        result = NO;
    }
    OSSpinLockUnlock(&((REF_COUNT_TYPE *)object)[-2]);

   return result;
}

NSUInteger NSExtraRefCount(id object) {
    NSUInteger      result;
    
    OSSpinLockLock(&((REF_COUNT_TYPE *)object)[-2]);
    result = ((REF_COUNT_TYPE *)object)[-1];
    OSSpinLockUnlock(&((REF_COUNT_TYPE *)object)[-2]);

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

    result = NSZoneCalloc(zone, 1, class->instance_size + (sizeof(REF_COUNT_TYPE) * 2) + extraBytes) + (sizeof(REF_COUNT_TYPE) * 2);
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

    ((REF_COUNT_TYPE *)result)[-1] = 1;

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
    
#if !defined(APPLE_RUNTIME_4)
    //delete associations
    objc_removeAssociatedObjects(object);

#endif
    if (NSZombieEnabled) {
        NSRegisterZombie(object);
    } else {
#if !defined(GCC_RUNTIME_3) && !defined(APPLE_RUNTIME_4)
        object->isa = 0;
#endif

        NSZoneFree(NULL, (REF_COUNT_TYPE *)object - 2);
    }
}


id NSCopyObject(id object, NSUInteger extraBytes, NSZone *zone)
{
    if (object == nil) {
        return nil;
    }

#if defined(GCC_RUNTIME_3) || defined(APPLE_RUNTIME_4)
    id result = NSAllocateObject(object_getClass(object), extraBytes, zone);

    memcpy((REF_COUNT_TYPE *)result - 2, (REF_COUNT_TYPE *)object - 2, class_getInstanceSize(object_getClass(object)) + (sizeof(REF_COUNT_TYPE) * 2) + extraBytes);
#else
    id result = NSAllocateObject(object->isa, extraBytes, zone);

    memcpy((REF_COUNT_TYPE *)result - 2, (REF_COUNT_TYPE *)object - 2, object->isa->instance_size + (sizeof(REF_COUNT_TYPE) * 2) + extraBytes);
#endif

    return result;
}
