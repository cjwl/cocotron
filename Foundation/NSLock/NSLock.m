/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSLock.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSRaise.h>

@implementation NSLock

+allocWithZone:(NSZone *)zone {
   if(self==[NSLock class])
    return NSAllocateObject([[NSPlatform currentPlatform] lockClass],0,zone);
   else
    return NSAllocateObject(self,0,zone);

}

-init {
   NSInvalidAbstractInvocation();
   return self;
}

-(NSString *)name {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)setName:(NSString *)value {
   NSInvalidAbstractInvocation();
}

-(void)lock {
   NSInvalidAbstractInvocation();
}

-(void)unlock {
   NSInvalidAbstractInvocation();
}

-(BOOL)tryLock {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)lockBeforeDate:(NSDate *)value {
   NSInvalidAbstractInvocation();
   return NO;
}

@end

enum {
	OBJC_SYNC_SUCCESS                 = 0,
	OBJC_SYNC_NOT_OWNING_THREAD_ERROR = -1,
	OBJC_SYNC_TIMED_OUT               = -2,
	OBJC_SYNC_NOT_INITIALIZED         = -3		
};

FOUNDATION_EXPORT int objc_sync_enter(id obj)
{
	return OBJC_SYNC_SUCCESS;
}


FOUNDATION_EXPORT int objc_sync_exit(id obj)
{
	return OBJC_SYNC_SUCCESS;
}

FOUNDATION_EXPORT int objc_sync_wait(id obj, long long milliSecondsMaxWait)
{
	return OBJC_SYNC_SUCCESS;
}

FOUNDATION_EXPORT int objc_sync_notify(id obj)
{
	return OBJC_SYNC_SUCCESS;
}

FOUNDATION_EXPORT int objc_sync_notifyAll(id obj)
{
	return OBJC_SYNC_SUCCESS;
}
