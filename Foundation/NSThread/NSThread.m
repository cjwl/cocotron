/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSThread.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSNotificationCenter.h>

NSString *NSDidBecomeSingleThreadedNotification=@"NSDidBecomeSingleThreadedNotification";
NSString *NSWillBecomeMultiThreadedNotification=@"NSWillBecomeMultiThreadedNotification";
NSString *NSThreadWillExitNotification=@"NSThreadWillExitNotification";

@implementation NSThread

static BOOL isMultiThreaded = NO;

+ (BOOL) isMultiThreaded {
	return isMultiThreaded;
}

+(BOOL)isMainThread {
   NSUnimplementedMethod();
   return 0;
}

+(NSThread *)mainThread {
   NSUnimplementedMethod();
   return 0;
}


- (id) initWithTarget: (id) aTarget selector: (SEL) aSelector object: (id) anArgument {
   [self init];
   _target   = [aTarget retain];
   _selector = aSelector;
   _argument = [anArgument retain];
   return self;
}

- (void) run {
	[_target performSelector: _selector withObject: _argument];
}

static unsigned nsThreadStartThread(void* thread)
{
    [(NSThread*)thread run];
    [(NSThread*)thread release];
	return 0;
}

#ifdef WIN32
/* Create a new thread of execution. */
DWORD objc_thread_detach(unsigned (*func)(void *arg), void *arg) {
	DWORD	threadId = 0;
	HANDLE win32Handle = (HANDLE)_beginthreadex(NULL, 0, func, arg, 0, &threadId);
	
	if (win32Handle) {
		threadId = 0; // just to be sure
	}
	
	CloseHandle(win32Handle);
	return threadId;
}
#else
int objc_thread_detach(unsigned (*func)(void *arg), void *arg) {
	return 0;
}
#endif

+(void)detachNewThreadSelector:(SEL)selector toTarget:target withObject:argument {
	id newThread = [[self alloc] initWithTarget: target selector: selector object: argument];
	
	if (!isMultiThreaded) {
		[[NSNotificationCenter defaultCenter] postNotificationName: NSWillBecomeMultiThreadedNotification
															object: nil
														  userInfo: nil];
		isMultiThreaded = YES;
	}
	
	if (objc_thread_detach( &nsThreadStartThread, newThread) == 0) {
		// No thread has been created. Don't leak:
		[newThread release];
		[NSException raise: @"NSThreadCreationFailedException"
					format: @"Creation of Objective-C thread failed."];
	}
}

+(NSThread *)currentThread {
   return NSPlatformCurrentThread();
}

+(NSArray *)callStackReturnAddresses {
  // dont raise exception as NSException relies on this in raise
  // NSUnimplementedMethod();
   return [NSArray arrayWithObject:@"NSUnimplementedMethod"];
}

+(double)threadPriority {
   NSUnimplementedMethod();
   return 0;
}

+(BOOL)setThreadPriority:(double)value {
   NSUnimplementedMethod();
   return 0;
}

+(void)sleepUntilDate:(NSDate *)date {
   NSTimeInterval interval=[date timeIntervalSinceNow];

   [[NSPlatform currentPlatform] sleepThreadForTimeInterval:interval];
}

+(void)sleepForTimeInterval:(NSTimeInterval)value {
   [[NSPlatform currentPlatform] sleepThreadForTimeInterval:value];
}

+(void)exit {
   NSUnimplementedMethod();
}

-init {
   _dictionary=[NSMutableDictionary new];
   _sharedObjects=[NSMutableDictionary new];
   return self;
}

- (void) dealloc {
	[_dictionary release];
	[_sharedObjects release];
	[_argument release];
	[_target release];
	[super dealloc];
}

-(BOOL)isMainThread {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isCancelled {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isExecuting {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isFinished {
   NSUnimplementedMethod();
   return 0;
}

-(void)start {
   NSUnimplementedMethod();
}

-(void)cancel {
   NSUnimplementedMethod();
}

-(void)main {
   NSUnimplementedMethod();
}

-(NSString *)name {
   NSUnimplementedMethod();
   return 0;
}

-(NSUInteger)stackSize {
   NSUnimplementedMethod();
   return 0;
}

-(NSMutableDictionary *)threadDictionary {
   return _dictionary;
}

-(void)setName:(NSString *)value {
   NSUnimplementedMethod();
}

-(void)setStackSize:(NSUInteger)value {
   NSUnimplementedMethod();
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

@implementation NSObject(NSThread)

-(void)performSelectorOnMainThread:(SEL)selector withObject:(id)object waitUntilDone:(BOOL)waitUntilDone modes:(NSArray *)modes {
	NSUnimplementedMethod();
}

-(void)performSelectorOnMainThread:(SEL)selector withObject:(id)object waitUntilDone:(BOOL)waitUntilDone {
	NSUnimplementedMethod();
}

-(void)performSelectorInBackground:(SEL)selector withObject:object {
	NSUnimplementedMethod();
}

@end

FOUNDATION_EXPORT NSThread *NSCurrentThread(void) {
   return NSPlatformCurrentThread();
}


