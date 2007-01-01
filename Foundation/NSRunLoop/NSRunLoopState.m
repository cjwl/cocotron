/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSRunLoopState.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSDelayedPerform.h>
#import <Foundation/NSInputSourceSet.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSString.h>

@implementation NSRunLoopState

-init {
   _inputSourceSet=[[[NSPlatform currentPlatform] inputSourceSetClass] new];
   _timers=[NSMutableArray new];
   return self;
}

-(void)dealloc {
   [_inputSourceSet release];
   [_timers release];
   [super dealloc];
}

-(void)addTimer:(NSTimer *)timer {
   [_timers addObject:timer];
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   NSMutableArray *fire=[NSMutableArray array];
   NSDate         *limit=nil;
   NSDate         *now=[NSDate date];
   int             count;

   count=[_timers count];
   while(--count>=0){
    NSTimer *timer=[_timers objectAtIndex:count];

    if(![timer isValid])
     [_timers removeObjectAtIndex:count];
    else if([now compare:[timer fireDate]]!=NSOrderedAscending)
     [fire addObject:timer];
   }

   [fire makeObjectsPerformSelector:@selector(fire)];

   count=[_timers count];
   while(--count>=0){
    NSTimer *timer=[_timers objectAtIndex:count];

    if(![timer isValid])
     [_timers removeObjectAtIndex:count];
    else if(limit==nil)
     limit=[timer fireDate];
    else
     limit=[limit earlierDate:[timer fireDate]];
   }

   if(limit==nil)
    limit=[_inputSourceSet limitDateForMode:mode];

   return limit;
}

-(void)addInputSource:(NSInputSource *)source {
   [_inputSourceSet addInputSource:source];
}

-(void)removeInputSource:(NSInputSource *)source {
   [_inputSourceSet removeInputSource:source];
}

-(void)invalidateTimerWithDelayedPerform:(NSDelayedPerform *)delayed {
   int count=[_timers count];

   while(--count>=0){
    NSTimer          *timer=[_timers objectAtIndex:count];
    NSDelayedPerform *check=[timer userInfo];

    if([check isKindOfClass:[NSDelayedPerform class]])
     if([check isEqualToPerform:delayed])
      [timer invalidate];
   }
}

-(void)acceptInputForMode:(NSString *)mode beforeDate:(NSDate *)date {
   if([_inputSourceSet immediateInputInMode:mode])
    return;

   [_inputSourceSet waitForInputInMode:mode beforeDate:date];
}

-(BOOL)pollInputForMode:(NSString *)mode {
   if([_inputSourceSet immediateInputInMode:mode])
    return YES;

   return [_inputSourceSet waitForInputInMode:mode beforeDate:[NSDate date]];
}

@end
