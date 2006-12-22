/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSInputSource.h>
#import <Foundation/NSSocketDescriptor.h>

enum {
 NSSocketNoActivity=0,
 NSSocketReadableActivity=1,
 NSSocketWritableActivity=2,
 NSSocketExceptionalActivity=4
};

@interface NSSocketMonitor : NSInputSource {
   NSSocketDescriptor _descriptor;
   unsigned           _monitorActivity;
   unsigned           _currentActivity;
   id                 _delegate;
}

+(NSSocketMonitor *)socketMonitorWithDescriptor:(NSSocketDescriptor)descriptor;

-initWithDescriptor:(NSSocketDescriptor)descriptor;

-(NSSocketDescriptor)descriptor;

-(void)setDelegate:delegate;
-delegate;

-(unsigned)currentActivity;
-(void)setCurrentActivity:(unsigned)activity;

-(unsigned)fileActivity;
-(void)monitorFileActivity:(unsigned)activity;
-(void)ceaseMonitoringFileActivity;

-(void)notifyDelegateOfCurrentActivityAndReset;

@end

@interface NSObject(NSSocketMonitor_delegate)

-(void)activityMonitorIndicatesReadable:(NSSocketMonitor *)socketMonitor;
-(void)activityMonitorIndicatesWriteable:(NSSocketMonitor *)socketMonitor;
-(void)activityMonitorIndicatesException:(NSSocketMonitor *)socketMonitor;

@end
