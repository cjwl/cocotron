/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSException.h>
#import <Foundation/NSDate.h>

@class NSDictionary,NSMutableDictionary,NSAutoreleasePool;

FOUNDATION_EXPORT NSString *NSDidBecomeSingleThreadedNotification;
FOUNDATION_EXPORT NSString *NSWillBecomeMultiThreadedNotification;
FOUNDATION_EXPORT NSString *NSThreadWillExitNotification;

@interface NSThread : NSObject {
   NSMutableDictionary *_dictionary;
   NSMutableDictionary *_sharedObjects;
   NSAutoreleasePool   *_currentPool;
   NSExceptionFrame    *_currentHandler;
   NSUncaughtExceptionHandler *_uncaughtExceptionHandler;
   NSString *_name;
   SEL _selector;
   id  _argument;
   id  _target;
}

+(BOOL)isMultiThreaded;
+(BOOL)isMainThread;

+(NSThread *)mainThread;

+(void)detachNewThreadSelector:(SEL)selector toTarget:target
   withObject:argument;

+(NSThread *)currentThread;
+(NSArray *)callStackReturnAddresses;
+(double)threadPriority;
+(BOOL)setThreadPriority:(double)value;

+(void)sleepUntilDate:(NSDate *)date;
+(void)sleepForTimeInterval:(NSTimeInterval)value;

+(void)exit;

-init;
-initWithTarget:target selector:(SEL)selector object:argument;

-(BOOL)isMainThread;
-(BOOL)isCancelled;
-(BOOL)isExecuting;
-(BOOL)isFinished;

-(void)start;
-(void)cancel;
-(void)main;

-(NSString *)name;
-(NSUInteger)stackSize;

-(NSMutableDictionary *)threadDictionary;

-(void)setName:(NSString *)value;
-(void)setStackSize:(NSUInteger)value;


// private
-(NSMutableDictionary *)sharedDictionary;
-(void)setSharedObject:object forClassName:(NSString *)className;

@end

@interface NSObject(NSThread)
-(void)performSelectorOnMainThread:(SEL)selector withObject:object waitUntilDone:(BOOL)waitUntilDone modes:(NSArray *)modes;
-(void)performSelectorOnMainThread:(SEL)selector withObject:object waitUntilDone:(BOOL)waitUntilDone;
-(void)performSelectorInBackground:(SEL)selector withObject:object;
@end

// PRIVATE
FOUNDATION_EXPORT NSThread *NSCurrentThread(void);
FOUNDATION_EXPORT id NSThreadSharedInstance(NSString *className);
FOUNDATION_EXPORT id NSThreadSharedInstanceDoNotCreate(NSString *className);
