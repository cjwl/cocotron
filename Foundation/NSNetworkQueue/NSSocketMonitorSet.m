/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSSocketMonitorSet.h>
#import <Foundation/NSSocketMonitor.h>
#import <Foundation/NSMutableSet.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSRaise.h>

@implementation NSSocketMonitorSet

-init {
   [super init];
   _monitors=[NSMutableSet new];
   return self;
}

-(void)dealloc {
   [_monitors release];
   [super dealloc];
}

-(unsigned)count {
   return [_monitors count];
}


-(BOOL)willAcceptInputForMode:(NSString *)mode {
   if ([_monitors count] > 0)
      return YES;

   return NO;
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   if([self willAcceptInputForMode:mode])
    return [NSDate distantFuture];

   return [super limitDateForMode:mode];
}

-(void)addInputSource:(NSInputSource *)source {
   if([source isKindOfClass:[NSSocketMonitor class]])
    [_monitors addObject:source];
   else
    [super addInputSource:source];
}

-(void)removeInputSource:(NSInputSource *)source {
   if([source isKindOfClass:[NSSocketMonitor class]])
    [_monitors removeObject:source];
   else
    [super removeInputSource:source];
}

-(BOOL)immediateInputInMode:(NSString *)mode {
   NSEnumerator  *state=[_monitors objectEnumerator];
   NSInputSource *check;

   while((check=[state nextObject])!=nil){
    if([check processInputImmediately])
     return YES;
   }

   return NO;
}

-(NSMutableArray *)waitForActivityBeforeDate:(NSDate *)date {
   NSInvalidAbstractInvocation();
   return nil;
}

-(BOOL)waitForInputInMode:(NSString *)mode beforeDate:(NSDate *)date {
   if([self willAcceptInputForMode:mode]){
    NSMutableArray *array=[self waitForActivityBeforeDate:date];

    [[array lastObject] notifyDelegateOfCurrentActivityAndReset];
    
    return ([array count]>0)?YES:NO;   
   }
   else {
    [NSThread sleepUntilDate:date];
    return NO;
   }
}

@end
