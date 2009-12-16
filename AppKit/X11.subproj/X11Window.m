/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/X11Window.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/X11Display.h>
#import <AppKit/NSRaise.h>
#import <X11/Xutil.h>
#import "O2Context_cairo.h"
#import <Foundation/NSException.h>

@implementation X11Window


+(Visual*)visual {
   static Visual* ret=NULL;
   
   if(!ret) {
      int visuals_matched, i;
      XVisualInfo match={0};
      Display *dpy=[(X11Display*)[NSDisplay currentDisplay] display];
   
      XVisualInfo *info=XGetVisualInfo(dpy,0, &match, &visuals_matched);
      
      for(i=0; i<visuals_matched; i++) {
         if(info[i].depth == 32 &&
            (info[i].red_mask   == 0xff0000 &&
             info[i].green_mask == 0x00ff00 &&
             info[i].blue_mask  == 0x0000ff)) {
            ret=info[i].visual;
         }
      }
      XFree(info);
      if(!ret)
         ret=DefaultVisual(dpy, DefaultScreen(dpy));
   }
   
   return ret;
}


-initWithFrame:(O2Rect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(NSUInteger)backingType {
   _backingType=backingType;
   _deviceDictionary=[NSMutableDictionary new];
   _dpy=[(X11Display*)[NSDisplay currentDisplay] display];
   int s = DefaultScreen(_dpy);
   _frame=[self transformFrame:frame];
   if(isPanel && styleMask&NSDocModalWindowMask)
    styleMask=NSBorderlessWindowMask;
      
   XSetWindowAttributes xattr;
   unsigned long xattr_mask;
   xattr.override_redirect = styleMask == NSBorderlessWindowMask ? True : False;
   xattr_mask = CWOverrideRedirect;
      
   _window = XCreateWindow(_dpy, DefaultRootWindow(_dpy),
                              _frame.origin.x, _frame.origin.y, _frame.size.width, _frame.size.height,
                              0, CopyFromParent, InputOutput, 
                              CopyFromParent,
                              xattr_mask, &xattr);

   XSelectInput(_dpy, _window, ExposureMask | KeyPressMask | KeyReleaseMask | StructureNotifyMask |
    ButtonPressMask | ButtonReleaseMask | ButtonMotionMask | VisibilityChangeMask | FocusChangeMask | SubstructureRedirectMask );

   Atom atm=XInternAtom(_dpy, "WM_DELETE_WINDOW", False);
   XSetWMProtocols(_dpy, _window, &atm , 1);
      
   XSetWindowBackgroundPixmap(_dpy, _window, None);
      
   [(X11Display*)[NSDisplay currentDisplay] setWindow:self forID:_window];
      
   if(styleMask == NSBorderlessWindowMask){
     [isa removeDecorationForWindow:_window onDisplay:_dpy];
    }
   return self;
}

-(void)dealloc {
   [self invalidate];
   [_backingContext release];
   [_context release];
   [_deviceDictionary release];   
   [super dealloc];
}

+(void)removeDecorationForWindow:(Window)w onDisplay:(Display*)dpy
{
   return;
   struct {
      unsigned long flags;
      unsigned long functions;
      unsigned long decorations;
      long input_mode;
      unsigned long status;
   } hints = {
      2, 0, 0, 0, 0,
   };
   XChangeProperty (dpy, w,
                    XInternAtom (dpy, "_MOTIF_WM_HINTS", False),
                    XInternAtom (dpy, "_MOTIF_WM_HINTS", False),
                    32, PropModeReplace,
                    (const unsigned char *) &hints,
                    sizeof (hints) / sizeof (long));
}

-(void)ensureMapped {
   if(!_mapped){      
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
   _delegate=nil;
   [_context release];
   _context=nil;

   if(_window) {
      [(X11Display*)[NSDisplay currentDisplay] setWindow:nil forID:_window];
      XDestroyWindow(_dpy, _window);
      _window=0;
   }
}

-(O2Context *)createCGContextIfNeeded {
   if(_context==nil)
    _context=[O2Context createContextWithSize:_frame.size window:self];

   return _context;
}

-(O2Context *)createBackingCGContextIfNeeded {
   if(_backingContext==nil){
    _backingContext=[O2Context createBackingContextWithSize:_frame.size context:[self createCGContextIfNeeded] deviceDictionary:_deviceDictionary];
   }
   
   return _backingContext;
}

-(O2Context *)cgContext {
   switch(_backingType){

    case CGSBackingStoreRetained:
    case CGSBackingStoreNonretained:
    default:
     return [self createCGContextIfNeeded];

    case CGSBackingStoreBuffered:
     return [self createBackingCGContextIfNeeded];
   }
   return nil;
}

-(void)invalidateContextsWithNewSize:(NSSize)size forceRebuild:(BOOL)forceRebuild {
   if(!NSEqualSizes(_frame.size,size) || forceRebuild){
    _frame.size=size;
    if(![_context resizeWithNewSize:size]){
     [_context release];
     _context=nil;
    }
    [_backingContext release];
    _backingContext=nil;
   }  
}

-(void)invalidateContextsWithNewSize:(NSSize)size {
   [self invalidateContextsWithNewSize:size forceRebuild:NO];
}

-(void)setTitle:(NSString *)title {
   XTextProperty prop;
   const char* text=[title cString];
   XStringListToTextProperty((char**)&text, 1, &prop);
   XSetWMName(_dpy, _window, &prop);
}

-(void)setFrame:(O2Rect)frame {
   frame=[self transformFrame:frame];
   XMoveResizeWindow(_dpy, _window, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
   [self invalidateContextsWithNewSize:frame.size];
}

-(void)showWindowForAppActivation:(O2Rect)frame {
   NSUnimplementedMethod();
}

-(void)hideWindowForAppDeactivation:(O2Rect)frame {
   NSUnimplementedMethod();
}

-(void)hideWindow {
   XUnmapWindow(_dpy, _window);
   _mapped=NO;
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

    switch(_backingType){

     case CGSBackingStoreRetained:
     case CGSBackingStoreNonretained:
      O2ContextFlush(_context);
      break;
 
     case CGSBackingStoreBuffered:
      if(_backingContext!=nil){
       O2ContextFlush(_backingContext);
       [_context drawBackingContext:_backingContext size:_frame.size];
       O2ContextFlush(_context);
      }
      break;
    }
}


-(NSPoint)mouseLocationOutsideOfEventStream {
   NSUnimplementedMethod();
   return NSZeroPoint;
}


-(O2Rect)frame
{
   return [self transformFrame:_frame];
}

static int ignoreBadWindow(Display* display,
                        XErrorEvent* errorEvent) {
   if(errorEvent->error_code==BadWindow)
      return 0;
   char buf[512];
   XGetErrorText(display, errorEvent->error_code, buf, 512);
   [NSException raise:NSInternalInconsistencyException format:@"X11 error: %s", buf];
   return 0;
}

-(void)frameChanged
{
   XErrorHandler previousHandler=XSetErrorHandler(ignoreBadWindow);
   @try {
      Window root, parent;
      Window window=_window;
      int x, y;
      unsigned int w, h, d, b, nchild;
      Window* children;
      O2Rect rect=NSZeroRect;
      // recursively get geometry to get absolute position
      BOOL success=YES;
      while(window && success) {
         XGetGeometry(_dpy, window, &root, &x, &y, &w, &h, &b, &d);
         success = XQueryTree(_dpy, window, &root, &parent, &children, &nchild);
         if(children)
            XFree(children);
         
         // first iteration: save our own w, h
         if(window==_window)
            rect=NSMakeRect(0, 0, w, h);
         rect.origin.x+=x;
         rect.origin.y+=y;
         window=parent;
      };
      
     [self invalidateContextsWithNewSize:rect.size];
   }
   @finally {
      XSetErrorHandler(previousHandler);
   }
}

-(Visual*)visual {
   return DefaultVisual(_dpy, DefaultScreen(_dpy));
}

-(Drawable)drawable {
   return _window;
}

-(void)addEntriesToDeviceDictionary:(NSDictionary *)entries  {
   [_deviceDictionary addEntriesFromDictionary:entries];
}

-(O2Rect)transformFrame:(O2Rect)frame {
   return NSMakeRect(frame.origin.x, DisplayHeight(_dpy, DefaultScreen(_dpy)) - frame.origin.y - frame.size.height, fmax(frame.size.width, 1.0), fmax(frame.size.height, 1.0));
}

-(NSPoint)transformPoint:(NSPoint)pos;
{
   return NSMakePoint(pos.x, _frame.size.height-pos.y);
}

-(unsigned int)modifierFlagsForState:(unsigned int)state {
   unsigned int ret=0;
   if(state & ShiftMask)
      ret|=NSShiftKeyMask;
   if(state & ControlMask)
      ret|=NSControlKeyMask;
   if(state & Mod2Mask)
      ret|=NSCommandKeyMask;
   // TODO: alt doesn't work; might want to track key presses/releases instead
   return ret;
}


-(void)handleEvent:(XEvent*)ev fromDisplay:(X11Display*)display {
   static id lastFocusedWindow=nil;
   static NSTimeInterval lastClickTimeStamp=0.0;
   static int clickCount=0;


   switch(ev->type) {
      case DestroyNotify:
      {
         // we should never get this message before the WM_DELETE_WINDOW ClientNotify
         // so normally, window should be nil here.
         [self invalidate];
         break;
      }
      case ConfigureNotify:
      {
         [self frameChanged];
         [_delegate platformWindow:self frameChanged:[self transformFrame:_frame] didSize:YES];
         break;
      }
      case Expose:
      {
         O2Rect rect=NSMakeRect(ev->xexpose.x, ev->xexpose.y, ev->xexpose.width, ev->xexpose.height);
         rect.origin.y=_frame.size.height-rect.origin.y-rect.size.height;
        // rect=NSInsetRect(rect, -10, -10);
   //      [_backingContext addToDirtyRect:rect];
         if(ev->xexpose.count==0)
            [self flushBuffer]; 
         break;
      }
      case ButtonPress:
      {
         NSTimeInterval now=[[NSDate date] timeIntervalSinceReferenceDate];
         if(now-lastClickTimeStamp<[display doubleClickInterval]) {
            clickCount++;
         }
         else {
            clickCount=1;  
         }
         lastClickTimeStamp=now;
         
         NSPoint pos=[self transformPoint:NSMakePoint(ev->xbutton.x, ev->xbutton.y)];
         
         id event=[NSEvent mouseEventWithType:NSLeftMouseDown
                                  location:pos
                             modifierFlags:[self modifierFlagsForState:ev->xbutton.state]
                                    window:_delegate
                                clickCount:clickCount];
         [display postEvent:event atStart:NO];
         break;
      }
      case ButtonRelease:
     {
         NSPoint pos=[self transformPoint:NSMakePoint(ev->xbutton.x, ev->xbutton.y)];

         id event=[NSEvent mouseEventWithType:NSLeftMouseUp
                                  location:pos
                             modifierFlags:[self modifierFlagsForState:ev->xbutton.state]
                                    window:_delegate
                                clickCount:clickCount];
         [display postEvent:event atStart:NO];
         break;
      }
      case MotionNotify:
      {
         NSPoint pos=[self transformPoint:NSMakePoint(ev->xmotion.x, ev->xmotion.y)];
         NSEventType type=NSMouseMoved;
         
         if(ev->xmotion.state&Button1Mask) {
            type=NSLeftMouseDragged;
         }
         else if (ev->xmotion.state&Button2Mask) {
            type=NSRightMouseDragged;
         }
         
         if(type==NSMouseMoved &&
            ![_delegate acceptsMouseMovedEvents])
            break;
         
         id event=[NSEvent mouseEventWithType:type
                                  location:pos
                             modifierFlags:[self modifierFlagsForState:ev->xmotion.state]
                                    window:_delegate
                                clickCount:1];
         [display postEvent:event atStart:NO];
         [display discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:event];
         break;
      }
      case ClientMessage:
      {
         if(ev->xclient.format=32 &&
            ev->xclient.data.l[0]==XInternAtom(_dpy, "WM_DELETE_WINDOW", False))
            [_delegate platformWindowWillClose:self];
         break;
      }
      case KeyRelease:
      case KeyPress:
      {
         unsigned int modifierFlags=[self modifierFlagsForState:ev->xkey.state];
         char buf[4]={0};
         XLookupString((XKeyEvent*)ev, buf, 4, NULL, NULL);
         id str=[[NSString alloc] initWithCString:buf encoding:NSISOLatin1StringEncoding];
         NSPoint pos=[self transformPoint:NSMakePoint(ev->xkey.x, ev->xkey.y)];
         
         id strIg=[str lowercaseString];
         if(ev->xkey.state) {
            ev->xkey.state=0;
            XLookupString((XKeyEvent*)ev, buf, 4, NULL, NULL);
            strIg=[[NSString alloc] initWithCString:buf encoding:NSISOLatin1StringEncoding];
         }
      
         id event=[NSEvent keyEventWithType:ev->type == KeyPress ? NSKeyDown : NSKeyUp
                                   location:pos
                              modifierFlags:modifierFlags
                                  timestamp:0.0 
                               windowNumber:(NSInteger)_delegate
                                    context:nil
                                 characters:str 
                charactersIgnoringModifiers:strIg
                                  isARepeat:NO
                                    keyCode:ev->xkey.keycode];
         
         [display postEvent:event atStart:NO];
         
         [str release];
         break;
      }
      case FocusIn:
         if([_delegate attachedSheet]) {
            [[_delegate attachedSheet] makeKeyAndOrderFront:_delegate];
            break;
         }
         if(lastFocusedWindow) {
            [lastFocusedWindow platformWindowDeactivated:self checkForAppDeactivation:NO];
            lastFocusedWindow=nil;  
         }
         [_delegate platformWindowActivated:self];
         lastFocusedWindow=_delegate;
         break;
      case FocusOut:
         [_delegate platformWindowDeactivated:self checkForAppDeactivation:NO];
         lastFocusedWindow=nil;
         break;
         
      default:
         NSLog(@"type %i", ev->type);
         break;
   }
}


@end
