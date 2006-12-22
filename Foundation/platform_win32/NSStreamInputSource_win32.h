/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#if defined(WIN32)
#import <Foundation/NSInputSource.h>
#import <Foundation/NSHandleMonitor_win32.h>

#import <winsock.h>

enum {
 XYXSocketNoActivity=0,
 XYXSocketReadableActivity=1,
 XYXSocketWritableActivity=2,
 XYXSocketExceptionalActivity=4
};

@interface NSStreamInputSource_win32 : NSInputSource  {
   SOCKET   _socket;
   int      _index;
   id       _delegate;
   unsigned _activity;
   BOOL     _inHandler;
}


+socketMonitorWithDescriptor:(SOCKET)descriptor;

-initWithDescriptor:(SOCKET)descriptor;

-(void)setDelegate:(id)delegate;
-(id)delegate;

-(unsigned)fileActivity;
-(void)monitorFileActivity:(unsigned)activity;
-(void)ceaseMonitoringFileActivity;

-(void)addActivityMode:(NSString *)mode;
-(void)removeActivityMode:(NSString *)mode;

@end

@interface NSObject(NSStreamInputSource_win32_delegate)

-(void)activityMonitorIndicatesReadable:(NSStreamInputSource_win32 *)activityMonitor;
-(void)activityMonitorIndicatesWriteable:(NSStreamInputSource_win32 *)activityMonitor;
-(void)activityMonitorIndicatesException:(NSStreamInputSource_win32 *)activityMonitor;

@end
#endif
