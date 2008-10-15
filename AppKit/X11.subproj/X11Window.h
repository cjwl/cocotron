//
//  X11Window.h
//  AppKit
//
//  Created by Johannes Fortmann on 13.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/CGWindow.h>
#import <X11/Xlib.h>

@class CairoContext;

@interface X11Window : CGWindow {
   id _delegate;
   Window _window;
   Display *_dpy;
   CairoContext *_cgContext;
   NSMutableDictionary *_deviceDictionary;
   NSRect _frame;
}
-(NSRect)frame;
-(Visual*)visual;
-(Drawable)drawable;
-(NSPoint)transformPoint:(NSPoint)pos;
@end
