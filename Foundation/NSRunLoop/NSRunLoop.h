/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSDate.h>
#import <Foundation/NSMapTable.h>

@class NSTimer,NSDate,NSMutableArray,NSInputSource,NSPort,NSPipe;

FOUNDATION_EXPORT NSString * const NSDefaultRunLoopMode;
FOUNDATION_EXPORT NSString * const NSRunLoopCommonModes;

@interface NSRunLoop : NSObject {
   NSMapTable      *_modes;
   NSString        *_currentMode;
   NSMutableArray  *_orderedPerforms;
}

+(NSRunLoop *)currentRunLoop;
+(NSRunLoop *)mainRunLoop;

-(NSString *)currentMode;
-(NSDate *)limitDateForMode:(NSString *)mode;
-(void)acceptInputForMode:(NSString *)mode beforeDate:(NSDate *)date;

-(BOOL)runMode:(NSString *)mode beforeDate:(NSDate *)date;
-(void)runUntilDate:(NSDate *)date;
-(void)run; 

-(void)addPort:(NSPort *)port forMode:(NSString *)mode;
-(void)removePort:(NSPort *)port forMode:(NSString *)mode;

-(void)addInputSource:(NSInputSource *)source forMode:(NSString *)mode;
-(void)removeInputSource:(NSInputSource *)source forMode:(NSString *)mode;

-(void)addTimer:(NSTimer *)timer forMode:(NSString *)mode;

-(void)performSelector:(SEL)selector target:target argument:argument order:(NSUInteger)order modes:(NSArray *)modes;

-(void)cancelPerformSelector:(SEL)selector target:target argument:argument;

@end

@interface NSObject(NSRunLoop_delayedPerform)

-(void)performSelector:(SEL)selector withObject:object
  afterDelay:(NSTimeInterval)delay;

+(void)cancelPreviousPerformRequestsWithTarget:target selector:(SEL)selector
  object:object;

@end

