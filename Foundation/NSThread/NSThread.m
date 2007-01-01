/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSThread.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>

NSString *NSWillBecomeMultiThreadedNotification=@"NSWillBecomeMultiThreadedNotification";
NSString *NSThreadWillExitNotification=@"NSThreadWillExitNotification";

@implementation NSThread

+(BOOL)isMultiThreaded {
   NSUnsupportedMethod();
   return NO;
}

+(void)detachNewThreadSelector:(SEL)selector toTarget:target
   withObject:argument {
   NSUnsupportedMethod();
}

+(NSThread *)currentThread {
   return NSPlatformCurrentThread();
}

+(void)sleepUntilDate:(NSDate *)date {
   NSTimeInterval interval=[date timeIntervalSinceNow];

   [[NSPlatform currentPlatform] sleepThreadForTimeInterval:interval];
}

+(void)exit {
   NSUnsupportedMethod();
}

-init {
   _dictionary=[NSMutableDictionary new];
   _sharedObjects=[NSMutableDictionary new];
   return self;
}

-(NSMutableDictionary *)threadDictionary {
   return _dictionary;
}

-(NSMutableDictionary *)sharedDictionary {
   return _sharedObjects;
}

static inline id _NSThreadSharedInstance(NSThread *thread,NSString *className,BOOL create) {
   NSMutableDictionary *shared=thread->_sharedObjects;
   id                   result=[shared objectForKey:className];

   if(result==nil && create){
    result=[[NSClassFromString(className) new] autorelease];
    [shared setObject:result forKey:className];
   }

   return result;
}

FOUNDATION_EXPORT id NSThreadSharedInstance(NSString *className) {
   return _NSThreadSharedInstance(NSPlatformCurrentThread(),className,YES);
}

FOUNDATION_EXPORT id NSThreadSharedInstanceDoNotCreate(NSString *className) {
   return _NSThreadSharedInstance(NSPlatformCurrentThread(),className,NO);
}

-sharedObjectForClassName:(NSString *)className {
   return _NSThreadSharedInstance(self,className,YES);
}

-(void)setSharedObject:object forClassName:(NSString *)className {
   [_sharedObjects setObject:object forKey:className];
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@[0x%lx] threadDictionary: %@ currentPool: %@>", isa, self, _dictionary, _currentPool];
}

NSAutoreleasePool *NSThreadCurrentPool(void) {
   return NSPlatformCurrentThread()->_currentPool;
}

void NSThreadSetCurrentPool(NSAutoreleasePool *pool){
   NSPlatformCurrentThread()->_currentPool=pool;
}

NSExceptionFrame *NSThreadCurrentHandler(void) {
   return NSPlatformCurrentThread()->_currentHandler;
}

void NSThreadSetCurrentHandler(NSExceptionFrame *handler) {
   NSPlatformCurrentThread()->_currentHandler=handler;
}

NSUncaughtExceptionHandler *NSThreadUncaughtExceptionHandler(void) {
   return NSPlatformCurrentThread()->_uncaughtExceptionHandler;
}

void NSThreadSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *function) {
   NSPlatformCurrentThread()->_uncaughtExceptionHandler=function;
}

@end

FOUNDATION_EXPORT NSThread *NSCurrentThread(void) {
   return NSPlatformCurrentThread();
}


