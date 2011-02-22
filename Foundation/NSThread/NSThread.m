/* Copyright (c) 2006-2007 Christopher J. W. Lloyd, 2008 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSThread.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSThread-Private.h>
#import <Foundation/NSSynchronization.h>
#import <Foundation/NSConditionLock.h>
#import <Foundation/objc_debugHelpers.h>
#import <Foundation/NSSelectSet.h>

NSString * const NSDidBecomeSingleThreadedNotification=@"NSDidBecomeSingleThreadedNotification";
NSString * const NSWillBecomeMultiThreadedNotification=@"NSWillBecomeMultiThreadedNotification";
NSString * const NSThreadWillExitNotification=@"NSThreadWillExitNotification";

@implementation NSThread

static BOOL isMultiThreaded = NO;
static NSThread* mainThread = nil;

+(void)initialize
{
	if(self==[NSThread class])
	{
      if(!mainThread)
      {
         mainThread = [NSThread new];
         NSPlatformSetCurrentThread(mainThread);
      }
	}
}

+ (BOOL) isMultiThreaded {
	return isMultiThreaded;
}

+(BOOL)isMainThread {
	return NSCurrentThread()==mainThread;
}

+(NSThread *)mainThread {
   return mainThread;
}


- (id) initWithTarget: (id) aTarget selector: (SEL) aSelector object: (id) anArgument {
   [self init];
   _target   = [aTarget retain];
   _selector = aSelector;
   _argument = [anArgument retain];
   return self;
}

- (void) main {
	[_target performSelector: _selector withObject: _argument];
}

#ifdef WINDOWS
static  unsigned __stdcall nsThreadStartThread(void* t)
#else
static void *nsThreadStartThread(void* t)
#endif
{
   NSThread    *thread = t;
	NSPlatformSetCurrentThread(thread);
	[thread setExecuting:YES];
    NSCooperativeThreadWaiting();
   [thread main];
	[thread setExecuting:NO];
	[thread setFinished:YES];
   [thread release];
   NSSelectSetShutdownForCurrentThread();
   NSPlatformSetCurrentThread(nil);
	return 0;
}

+(void)detachNewThreadSelector:(SEL)selector toTarget:target withObject:argument {
	id newThread = [[self alloc] initWithTarget: target selector: selector object: argument];
	[newThread start];
	[newThread release];
}

+(NSThread *)currentThread {
   return NSPlatformCurrentThread();
}

+(NSArray *)callStackReturnAddresses {
   return _NSStackTrace();
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

   NSCooperativeThreadBlocking();
   NSPlatformSleepThreadForTimeInterval(interval);
   NSCooperativeThreadWaiting();
}

+(void)sleepForTimeInterval:(NSTimeInterval)value {
   NSCooperativeThreadBlocking();
   NSPlatformSleepThreadForTimeInterval(value);
   NSCooperativeThreadWaiting();
}

+(void)exit {
   NSUnimplementedMethod();
}

-init {
   _dictionary=[NSMutableDictionary new];
   _sharedObjects=[NSMutableDictionary new];
   if(isMultiThreaded)
      _sharedObjectLock=[NSLock new];
   return self;
}

- (void) dealloc {
	if([self isExecuting])
		[NSException raise:NSInternalInconsistencyException format:@"trying to dealloc thread %@ while it's running", self];
	[_dictionary release]; _dictionary=nil;

   id oldSharedObjects=_sharedObjects;
   _sharedObjects=nil;
	[oldSharedObjects release];

   [_sharedObjectLock release]; _sharedObjectLock=nil;
   [_name release]; _name=nil;
	[_argument release]; _argument=nil;
	[_target release]; _target=nil;
	[super dealloc];
}

-(void)start {
	[self retain]; // balanced by release in nsThreadStartThread

   if (!isMultiThreaded) {
		[[NSNotificationCenter defaultCenter] postNotificationName: NSWillBecomeMultiThreadedNotification
                                                          object: nil
                                                        userInfo: nil];
		isMultiThreaded = YES;
      // lazily initialize mainThread's lock
      mainThread->_sharedObjectLock=[NSLock new];
		_NSInitializeSynchronizedDirective();
	}
   // if we were init'ed before didBecomeMultithreaded, we won't have a lock either
   if(!_sharedObjectLock)
      _sharedObjectLock=[NSLock new];
    
	if (NSPlatformDetachThread( &nsThreadStartThread, self) == 0) {
		// No thread has been created. Don't leak:
		[self release];
		[NSException raise: @"NSThreadCreationFailedException"
					format: @"Creation of Objective-C thread failed."];
	}
}

-(BOOL)isMainThread {
   return self==mainThread;
}

-(BOOL)isCancelled {
	return _cancelled;
}

-(BOOL)isExecuting {
	return _executing;
}

-(BOOL)isFinished {
	return _finished;
}

-(void)cancel {
	_cancelled=YES;
}

-(NSString *)name {
	return _name;
}

-(void)setExecuting:(BOOL)executing
{
	_executing=executing;
}

-(void)setFinished:(BOOL)finished
{
	_finished=finished;
}

-(NSUInteger)stackSize {
   NSUnimplementedMethod();
   return 0;
}

-(NSMutableDictionary *)threadDictionary {
   return _dictionary;
}

-(void)setName:(NSString *)value {
	if(value!=_name)
	{
		[_name release];
		_name=[value copy];
	}
}

-(void)setStackSize:(NSUInteger)value {
   NSUnimplementedMethod();
}

-(NSMutableDictionary *)sharedDictionary {
   return _sharedObjects;
}

static inline id _NSThreadSharedInstance(NSThread *thread,NSString *className,BOOL create) {
   NSMutableDictionary *shared=thread->_sharedObjects;
   if(!shared)
      return nil;
	id result=nil;
   [thread->_sharedObjectLock lock];
   result=[shared objectForKey:className];
   [thread->_sharedObjectLock unlock];

   if(result==nil && create){
      // do not hold lock during object allocation
      result=[NSClassFromString(className) new];
      [thread->_sharedObjectLock lock];
      [shared setObject:result forKey:className];
      [thread->_sharedObjectLock unlock];
      [result release];
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
   [_sharedObjectLock lock];
   if(object==nil)
    [_sharedObjects removeObjectForKey:className];
   else
    [_sharedObjects setObject:object forKey:className];
   [_sharedObjectLock unlock];
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

-(void)_performSelectorOnThreadHelper:(NSArray*)selectorAndArguments {
   NSConditionLock *waitingLock=[selectorAndArguments objectAtIndex:0];
   SEL              selector=NSSelectorFromString([selectorAndArguments objectAtIndex:1]);
   id               object=[[selectorAndArguments objectAtIndex:2] pointerValue];
   
   [waitingLock lockWhenCondition:0];
   
   [self performSelector:selector withObject:object];
   
   [waitingLock unlockWithCondition:1];
   [selectorAndArguments release];
}

- (void)performSelector:(SEL)selector onThread:(NSThread *)thread withObject:(id)object waitUntilDone:(BOOL)waitUntilDone modes:(NSArray *)modes
{
   if(thread==nil){
    [NSException raise:NSInvalidArgumentException format:@"Thread is nil"];
    return;
   }
	id runloop=_NSThreadSharedInstance(thread, @"NSRunLoop", NO);
	if(waitUntilDone)
	{
		if(thread==[NSThread currentThread])
		{
			[self performSelector:selector withObject:object];
		}
		else
		{
			if(!runloop)
				[NSException raise:NSInvalidArgumentException format:@"thread %@ has no runloop in %@", thread, NSStringFromSelector(_cmd)];
			NSConditionLock *waitingLock=[[NSConditionLock alloc] initWithCondition:0];

         // array retain balanced in _performSelectorOnThreadHelper:
			[runloop performSelector:@selector(_performSelectorOnThreadHelper:)
							  target:self 
							argument:[[NSArray arrayWithObjects:waitingLock, NSStringFromSelector(selector), [NSValue valueWithPointer:object], nil] retain] 
							   order:0 
							   modes:modes];

			[waitingLock lockWhenCondition:1];
			[waitingLock unlock];
			[waitingLock release];
		}
	}
	else
	{
		if(!runloop)
			[NSException raise:NSInvalidArgumentException format:@"thread %@ has no runloop in %@", thread, NSStringFromSelector(_cmd)];

		[runloop performSelector:selector target:self argument:object order:0 modes:modes];
	}
}

- (void)performSelector:(SEL)selector onThread:(NSThread *)thread withObject:(id)object waitUntilDone:(BOOL)waitUntilDone
{
	[self performSelector:selector onThread:thread withObject:object waitUntilDone:waitUntilDone modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

-(void)performSelectorOnMainThread:(SEL)selector withObject:(id)object waitUntilDone:(BOOL)waitUntilDone modes:(NSArray *)modes {
	[self performSelector:selector onThread:[NSThread mainThread] withObject:object waitUntilDone:waitUntilDone modes:modes];
}

-(void)performSelectorOnMainThread:(SEL)selector withObject:(id)object waitUntilDone:(BOOL)waitUntilDone {
	[self performSelectorOnMainThread:selector withObject:object waitUntilDone:waitUntilDone modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

-(void)performSelectorInBackground:(SEL)selector withObject:object {
	[NSThread detachNewThreadSelector:selector toTarget:self withObject:object];
}

@end

FOUNDATION_EXPORT NSThread *NSCurrentThread(void) {
   return NSPlatformCurrentThread();
}

