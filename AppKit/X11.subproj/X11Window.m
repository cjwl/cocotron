/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/X11Window.h>
#import <AppKit/NSWindow.h>
#import <AppKit/X11Display.h>
#import <X11/Xutil.h>
#import <AppKit/CairoContext.h>

@implementation X11Window

-initWithFrame:(NSRect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(NSUInteger)backingType;
{
   if(self=[super init])
	{
      _deviceDictionary=[NSMutableDictionary new];
      _dpy=[(X11Display*)[NSDisplay currentDisplay] display];
      int s = DefaultScreen(_dpy);
      _window = XCreateSimpleWindow(_dpy, DefaultRootWindow(_dpy),
                              frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, 
                              0, BlackPixel(_dpy, s), WhitePixel(_dpy, s));

      XSelectInput(_dpy, _window, ExposureMask | KeyPressMask | StructureNotifyMask |
      ButtonPressMask | ButtonReleaseMask | ButtonMotionMask);
      
      XSetWindowAttributes xattr;
      unsigned long xattr_mask;
      xattr.backing_store = WhenMapped;
      xattr_mask = CWBackingStore;
      XChangeWindowAttributes(_dpy, _window, xattr_mask, &xattr);
      XMoveWindow(_dpy, _window, frame.origin.x, frame.origin.y);
      NSLog(@"frame: %f, %f", frame.origin.x, frame.origin.y);
      
      [(X11Display*)[NSDisplay currentDisplay] setWindow:self forID:_window];
      [self sizeChanged];
   }
   return self;
}

-(void)ensureMapped
{
   if(!_mapped)
   {
      XMapWindow(_dpy, _window);
      _mapped=YES;
   }
}


-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}

-(void)invalidate {
   [(X11Display*)[NSDisplay currentDisplay] setWindow:self forID:_window];
         
   XDestroyWindow(_dpy, _window);
   _window=0;
   _delegate=nil;
}


-(KGContext *)cgContext {
   if(!_cgContext)
   {
      _cgContext=[[CairoContext alloc] initWithWindow:self];
   }
   
   return _cgContext;
}


-(void)setTitle:(NSString *)title {
   XTextProperty prop;
   const char* text=[title cString];
   XStringListToTextProperty((char**)&text, 1, &prop);
   XSetWMName(_dpy, _window, &prop);
}

-(void)setFrame:(NSRect)frame {
   XMoveResizeWindow(_dpy, _window, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
   [_cgContext setSize:[self frame].size];
 }


-(void)showWindowForAppActivation:(NSRect)frame {
   NSUnimplementedMethod();
}

-(void)hideWindowForAppDeactivation:(NSRect)frame {
   NSUnimplementedMethod();
}


-(void)hideWindow {
   XUnmapWindow(_dpy, _window);
   _mapped=NO;
   [_cgContext release];
   _cgContext=nil;
}


-(void)placeAboveWindow:(X11Window *)other {
   [self ensureMapped];

   if(!other) {
      XRaiseWindow(_dpy, _window);
   }
   else {
      Window w[2]={_window, other->_window};
      XRestackWindows(_dpy, w, 1);
   }
}

-(void)placeBelowWindow:(X11Window *)other {
   [self ensureMapped];

   if(!other) {
      XLowerWindow(_dpy, _window);
   }
   else {
      Window w[2]={other->_window, _window};
      XRestackWindows(_dpy, w, 1);
   }
}

-(void)makeKey {
   [self ensureMapped];
   XRaiseWindow(_dpy, _window);
}

-(void)captureEvents {
   NSUnimplementedMethod();
}

-(void)miniaturize {
   NSUnimplementedMethod();

}

-(void)deminiaturize {
   NSUnimplementedMethod();

}

-(BOOL)isMiniaturized {
   return NO;
}

-(void)flushBuffer {
   [_cgContext flush];
}


-(NSPoint)mouseLocationOutsideOfEventStream {
   NSUnimplementedMethod();
   return NSZeroPoint;
}


-(void)sendEvent:(CGEvent *)event {
   NSLog(@"%@", event);
   NSUnimplementedMethod();
}

-(NSRect)frame
{
   return _frame;
}

-(void)sizeChanged
{
   Window root;
   int x, y, w, h, b, d;
   XGetGeometry(_dpy, _window, &root, 
                &x, &y, &w, &h,
                &b, &d);
   
   _frame = NSMakeRect(x, y, w, h);
   
   [_cgContext setSize:_frame.size];
}

-(Visual*)visual
{
   return DefaultVisual(_dpy, DefaultScreen(_dpy));
}

-(Drawable)drawable
{
   return _window;
}

-(void)addEntriesToDeviceDictionary:(NSDictionary *)entries 
{
   [_deviceDictionary addEntriesFromDictionary:entries];
}


-(NSPoint)transformPoint:(NSPoint)pos;
{
   return NSMakePoint(pos.x, _frame.size.height-pos.y);
}

@end
