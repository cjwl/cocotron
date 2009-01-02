/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "X11InputSource.h"

@class NSSocket_bsd, NSSelectInputSource;
#import <AppKit/X11Display.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRunloop.h>
#import <AppKit/NSApplication.h>
#import <AppKit/X11AsyncInputSource.h>
#import <X11/Xlib.h>

@implementation X11InputSource

+(void)addInputSourceWithDisplay:(X11Display*)display {
   X11InputSource* synchro = [X11InputSource socketInputSourceWithSocket:
             [NSSocket_bsd socketWithDescriptor:ConnectionNumber([display display])]];
   X11AsyncInputSource* async=[X11AsyncInputSource new];
   
   [synchro setDelegate:synchro];
   [synchro setSelectEventMask:NSSelectReadEvent];
   synchro->_display=display;
   async->_display=display;

   for(id mode in [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil]) {
      [[NSRunLoop currentRunLoop] addInputSource:synchro forMode:mode];
      [[NSRunLoop currentRunLoop] addInputSource:async forMode:mode];
   }
}

-(void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(unsigned)selectEvent; {
   if(XEventsQueued([_display display], QueuedAfterReading)) {
      [_display processX11Event];
   }
}


-(BOOL)processImmediateEvents:(unsigned)selectEvent; {
   if(XPending([_display display])) {
      [_display processX11Event];
      return YES;
   }
   
   return [super processImmediateEvents:selectEvent];
}
@end
