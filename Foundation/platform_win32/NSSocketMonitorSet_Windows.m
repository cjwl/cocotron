/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSSocketMonitorSet_Windows.h"
#import <Foundation/NSSocketMonitor.h>
#import <Foundation/NSMutableSet.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

@implementation NSSocketMonitorSet_Windows

-init {
   [super init];
   _readSet=NSSocketSetNew();
   _writeSet=NSSocketSetNew();
   _exceptionSet=NSSocketSetNew();
   return self;
}

-(void)dealloc {
   NSSocketSetDealloc(_readSet);
   NSSocketSetDealloc(_writeSet);
   NSSocketSetDealloc(_exceptionSet);
   [super dealloc];
}

-(BOOL)willAcceptInputForMode:(NSString *)mode {
   if([_monitors count]>0){
    NSEnumerator     *state=[_monitors objectEnumerator];
    NSSocketMonitor *monitor;

    while((monitor=[state nextObject])!=nil)
     if([monitor fileActivity]!=NSSocketNoActivity)
      return YES;
   }
   return NO;
}

-(NSMutableArray *)waitForActivityBeforeDate:(NSDate *)date {
   NSMutableArray   *result=[NSMutableArray array];
   NSEnumerator     *state=[_monitors objectEnumerator];
   NSSocketMonitor  *monitor;
   int               nfds;
   NSTimeInterval    interval=[date timeIntervalSinceNow];
   struct timeval    timeval;

   NSSocketSetZero(_readSet);
   NSSocketSetZero(_writeSet);
   NSSocketSetZero(_exceptionSet);

   nfds=0;
   while((monitor=[state nextObject])!=nil){
    unsigned activity=[monitor fileActivity];

    if(activity!=NSSocketNoActivity){
     NSSocketDescriptor descriptor=[monitor descriptor];

     if(nfds<descriptor)
      nfds=descriptor;

     if(activity&NSSocketReadableActivity)
      NSSocketSetSet(_readSet,descriptor);

     if(activity&NSSocketWritableActivity)
      NSSocketSetSet(_writeSet,descriptor);

     if(activity&NSSocketExceptionalActivity)
      NSSocketSetSet(_exceptionSet,descriptor);
    }
   }
   nfds++;

   if(interval>1000000)
    interval=1000000;
   if(interval<0)
    interval=0;

   timeval.tv_sec=interval;
   interval-=timeval.tv_sec;
   timeval.tv_usec=interval*1000;

   if(select(nfds,NSSocketSetFDSet(_readSet),NSSocketSetFDSet(_writeSet),NSSocketSetFDSet(_exceptionSet),&timeval)<0){
    NSLog(@"select failed: %s", strerror(errno));
    return nil;
   }

   state=[_monitors objectEnumerator];
   while((monitor=[state nextObject])!=nil){
    unsigned            activity=NSSocketNoActivity;
    NSSocketDescriptor descriptor=[monitor descriptor];

    if(NSSocketSetIsSet(_readSet,descriptor))
     activity|=NSSocketReadableActivity;
    if(NSSocketSetIsSet(_writeSet,descriptor))
     activity|=NSSocketWritableActivity;
    if(NSSocketSetIsSet(_exceptionSet,descriptor))
     activity|=NSSocketExceptionalActivity;

    [monitor setCurrentActivity:activity];

    if(activity!=NSSocketNoActivity)
     [result addObject:monitor];
   }

   return result;
}

@end
