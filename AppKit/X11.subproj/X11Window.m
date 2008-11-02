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
      _frame=[self transformFrame:frame];
      _window = XCreateSimpleWindow(_dpy, DefaultRootWindow(_dpy),
                              _frame.origin.x, _frame.origin.y, _frame.size.width, _frame.size.height, 
                              0, 0, 0);

      XSelectInput(_dpy, _window, ExposureMask | KeyPressMask | StructureNotifyMask |
      ButtonPressMask | ButtonReleaseMask | ButtonMotionMask);
      
      XSetWindowAttributes xattr;
      unsigned long xattr_mask;
      xattr.win_gravity=CenterGravity;
      xattr.override_redirect= styleMask == NSBorderlessWindowMask ? True : False;
      xattr_mask = CWOverrideRedirect | CWWinGravity;
      XChangeWindowAttributes(_dpy, _window, xattr_mask, &xattr);
      XMoveWindow(_dpy, _window, _frame.origin.x, _frame.origin.y);
      
      Atom atm=XInternAtom(_dpy, "WM_DELETE_WINDOW", False);
      XSetWMProtocols(_dpy, _window, &atm , 1);
      
      [(X11Display*)[NSDisplay currentDisplay] setWindow:self forID:_window];
      [self sizeChanged];
      
      if(styleMask == NSBorderlessWindowMask)
      {
         [self removeDecoration];
      }
   }
   return self;
}

-(void)removeDecoration
{
   struct {
      unsigned long flags;
      unsigned long functions;
      unsigned long decorations;
      long input_mode;
      unsigned long status;
   } hints = {
      2, 0, 0, 0, 0,
   };
   XChangeProperty (_dpy, _window,
                    XInternAtom (_dpy, "_MOTIF_WM_HINTS", False),
                    XInternAtom (_dpy, "_MOTIF_WM_HINTS", False),
                    32, PropModeReplace,
                    (const unsigned char *) &hints,
                    sizeof (hints) / sizeof (long));
}

-(void)ensureMapped
{
   if(!_mapped)
   {
      [_cgContext release];
      
      XMapWindow(_dpy, _window);
      _mapped=YES;
      _cgContext = [[CairoContext alloc] initWithWindow:self];
   }
}


-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}

-(void)invalidate {
   _delegate=nil;
   [_cgContext release];
   _cgContext=nil;

   if(_window) {
      [(X11Display*)[NSDisplay currentDisplay] setWindow:nil forID:_window];
      XDestroyWindow(_dpy, _window);
      _window=0;
   }
}


-(KGContext *)cgContext {
   if(!_backingContext)
   {
      _backingContext=[[CairoContext alloc] initWithSize:_frame.size];
   }
   
   return _backingContext;
}


-(void)setTitle:(NSString *)title {
   XTextProperty prop;
   const char* text=[title cString];
   XStringListToTextProperty((char**)&text, 1, &prop);
   XSetWMName(_dpy, _window, &prop);
}

-(void)setFrame:(NSRect)frame {
   frame=[self transformFrame:frame];
   XMoveResizeWindow(_dpy, _window, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
   [_cgContext setSize:[self frame].size];
   [_backingContext setSize:[self frame].size];
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
   // FIXME: find out what this is supposed to do
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
   [_cgContext drawContext:_backingContext]; 
}


-(NSPoint)mouseLocationOutsideOfEventStream {
   NSUnimplementedMethod();
   return NSZeroPoint;
}




-(NSRect)frame
{
   return [self transformFrame:_frame];
}

-(void)frameChanged
{
   Window root, parent;
   Window window=_window;
   int x, y, w, h, d, b;
   Window* children;
   int nchild;
   NSRect rect=NSZeroRect;
   // recursively get geometry to get absolute position
   while(window) {
      XGetGeometry(_dpy, window, &root, &x, &y, &w, &h, &b, &d);
      XQueryTree(_dpy, window, &root, &parent, &children, &nchild);
      if(children)
         XFree(children);
      
      // first iteration: save our own w, h
      if(window==_window)
         rect=NSMakeRect(0, 0, w, h);
      rect.origin.x+=x;
      rect.origin.y+=y;
      window=parent;
   };

   _frame=rect;
   [self sizeChanged];
}

-(void)sizeChanged
{
   [_cgContext setSize:_frame.size];
   [_backingContext setSize:_frame.size];
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

-(NSRect)transformFrame:(NSRect)frame
{
   return NSMakeRect(frame.origin.x, DisplayHeight(_dpy, DefaultScreen(_dpy)) - frame.origin.y - frame.size.height, frame.size.width, frame.size.height);
}

-(NSPoint)transformPoint:(NSPoint)pos;
{
   return NSMakePoint(pos.x, _frame.size.height-pos.y);
}

@end
