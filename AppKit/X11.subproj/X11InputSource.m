/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "X11InputSource.h"

@class NSSocket_bsd, NSSelectInputSource;
#import <AppKit/X11Display.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRunloop.h>
#import <Foundation/NSSocket_bsd.h>
#import <AppKit/NSApplication.h>
#import <AppKit/X11AsyncInputSource.h>
#import <X11/Xlib.h>
#import <fcntl.h>

@implementation X11InputSource

+(void)addInputSourceWithDisplay:(X11Display*)display {
   int connectionNumber=ConnectionNumber([display display]);
   int flags=fcntl(connectionNumber, F_GETFL);
   flags&=~O_NONBLOCK;
   fcntl(connectionNumber, F_SETFL, flags & ~O_NONBLOCK);

   X11InputSource* synchro = [X11InputSource socketInputSourceWithSocket:
             [NSSocket_bsd socketWithDescriptor:connectionNumber]];
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

-(BOOL)processImmediateEvents:(unsigned)selectEvent; {
   return [_display processX11Event];
}
@end
