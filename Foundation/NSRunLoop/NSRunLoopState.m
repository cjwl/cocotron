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
   _inputSourceSet=[[[NSPlatform currentPlatform] synchronousInputSourceSet] retain];
   _asyncInputSourceSets=[[[NSPlatform currentPlatform] asynchronousInputSourceSets] retain];
   _timers=[NSMutableArray new];
   return self;
}

-(void)dealloc {
   [_inputSourceSet release];
   [_asyncInputSourceSets release];
   [_timers release];
   [super dealloc];
}

-(void)addTimer:(NSTimer *)timer {
   [_timers addObject:timer];
}

-(void)changingIntoMode:(NSString *)mode {
   int i,count=[_asyncInputSourceSets count];

   [_inputSourceSet changingIntoMode:mode];

   for(i=0;i<count;i++)
    [[_asyncInputSourceSets objectAtIndex:i] changingIntoMode:mode];
}

-(void)fireTimers {
   NSMutableArray *fire=[NSMutableArray array];
   NSDate         *now=[NSDate date];
   int             count=[_timers count];
   
   while(--count>=0){
    NSTimer *timer=[_timers objectAtIndex:count];

    if(![timer isValid])
     [_timers removeObjectAtIndex:count];
    else if([now compare:[timer fireDate]]!=NSOrderedAscending)
     [fire addObject:timer];
   }

   [fire makeObjectsPerformSelector:@selector(fire)];
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   NSDate *limit=nil;
   int     count;

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

-(NSInputSourceSet *)inputSourceSetForInputSource:(NSInputSource *)source {
   if([_inputSourceSet recognizesInputSource:source])
    return _inputSourceSet;
   else {
    int i,count=[_asyncInputSourceSets count];
    
    for(i=0;i<count;i++){
     NSInputSourceSet *check=[_asyncInputSourceSets objectAtIndex:i];
     
     if([check recognizesInputSource:source])
      return check;
    }
   }
   return nil;
}

-(void)addInputSource:(NSInputSource *)source {
   [[self inputSourceSetForInputSource:source] addInputSource:source];
}

-(void)removeInputSource:(NSInputSource *)source {
   [[self inputSourceSetForInputSource:source] removeInputSource:source];
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

-(BOOL)immediateInputInMode:(NSString *)mode {
   if([_inputSourceSet immediateInputInMode:mode])
    return YES;
   else {
    int i,count=[_asyncInputSourceSets count];
    
    for(i=0;i<count;i++)
     if([[_asyncInputSourceSets objectAtIndex:i] immediateInputInMode:mode])
      return YES;
      
    return NO;
   }
}

-(void)acceptInputForMode:(NSString *)mode beforeDate:(NSDate *)date {
   if(![self immediateInputInMode:mode]){
    int i,count=[_asyncInputSourceSets count];
    
    for(i=0;i<count;i++)
     [[_asyncInputSourceSets objectAtIndex:i] waitInBackgroundInMode:mode];

    [_inputSourceSet waitForInputInMode:mode beforeDate:date];
   }
}

-(BOOL)pollInputForMode:(NSString *)mode {
   if([self immediateInputInMode:mode])
    return YES;

   return [_inputSourceSet waitForInputInMode:mode beforeDate:[NSDate date]];
}

@end
