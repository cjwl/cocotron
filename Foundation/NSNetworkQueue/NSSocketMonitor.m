/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSSocketMonitor.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSRunLoop-InputSource.h>

@implementation NSSocketMonitor

+(NSSocketMonitor *)socketMonitorWithDescriptor:(NSSocketDescriptor)descriptor {
   return [[[self allocWithZone:NULL] initWithDescriptor:descriptor] autorelease];
}

-initWithDescriptor:(NSSocketDescriptor)descriptor {
   [super init];
   _descriptor=descriptor;
   _monitorActivity=NSSocketNoActivity;
   _currentActivity=NSSocketNoActivity;
   _delegate=nil;
   return self;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@[0x%lx] descriptor: %d monitorActivity: %d currentActivity: %d delegate: %@>", [[self class] description], self, _descriptor, _monitorActivity, _currentActivity, [_delegate description]];
}

-(NSSocketDescriptor)descriptor {
   return _descriptor;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}

-(unsigned)currentActivity {
   return _currentActivity;
}

-(void)setCurrentActivity:(unsigned)activity {
   _currentActivity=activity;
}

-(unsigned)fileActivity {
   return _monitorActivity;
}

-(void)monitorFileActivity:(unsigned)activity {
   _monitorActivity=activity;
}

-(void)ceaseMonitoringFileActivity {
   _monitorActivity=NSSocketNoActivity;
}

-(BOOL)processInputImmediately {
   if(_currentActivity!=NSSocketNoActivity){
    [self notifyDelegateOfCurrentActivityAndReset];
    return YES;
   }
   return NO;
}

-(void)notifyDelegateOfCurrentActivityAndReset {
   unsigned activity=_currentActivity;
   
   _currentActivity=NSSocketNoActivity;
   
   if(activity&NSSocketReadableActivity)
    [_delegate activityMonitorIndicatesReadable:self];
   if(activity&NSSocketWritableActivity)
    [_delegate activityMonitorIndicatesWriteable:self];
   if(activity&NSSocketExceptionalActivity)
    [_delegate activityMonitorIndicatesException:self];
}

-(void)addActivityMode:(NSString *)mode {
   [[NSRunLoop currentRunLoop] addInputSource:self forMode:mode];
}

-(void)removeActivityMode:(NSString *)mode {
   [[NSRunLoop currentRunLoop] removeInputSource:self forMode:mode];
}

@end
