/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSException.h>
#import <Foundation/NSDate.h>

@class NSDictionary,NSMutableDictionary,NSAutoreleasePool;

FOUNDATION_EXPORT NSString *NSWillBecomeMultiThreadedNotification;
FOUNDATION_EXPORT NSString *NSThreadWillExitNotification;

@interface NSThread : NSObject {
   NSMutableDictionary *_dictionary;
   NSMutableDictionary *_sharedObjects;
   NSAutoreleasePool   *_currentPool;
   NSExceptionFrame    *_currentHandler;
   NSUncaughtExceptionHandler *_uncaughtExceptionHandler;
}

+(BOOL)isMultiThreaded;

+(void)detachNewThreadSelector:(SEL)selector toTarget:target
   withObject:argument;

+(NSThread *)currentThread;

+(void)sleepUntilDate:(NSDate *)date;

+(void)exit;

-(NSMutableDictionary *)threadDictionary;

-(NSMutableDictionary *)sharedDictionary;
-(void)setSharedObject:object forClassName:(NSString *)className;

@end


// PRIVATE
FOUNDATION_EXPORT NSThread *NSCurrentThread(void);
FOUNDATION_EXPORT id NSThreadSharedInstance(NSString *className);
FOUNDATION_EXPORT id NSThreadSharedInstanceDoNotCreate(NSString *className);
