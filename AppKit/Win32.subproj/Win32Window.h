/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/CGWindow.h>
#import <AppKit/NSDragging.h>
#import <OpenGL/OpenGL.h>
#undef WINVER
#define WINVER 0x501 // XP drop shadow constants
#import <windows.h>

@class NSEvent;


@interface Win32Window : CGWindow {
   NSRect                 _frame;
   HWND                   _handle;
   NSSize                 _size;
   O2Context             *_cgContext;

   CGSBackingStoreType  _backingType;
   O2Context             *_backingContext;
   CGLContextObj          _cglContext;

   BOOL                  _isLayered;
   BOOL                  _isOpenGL;
   BOOL                  _ignoreMinMaxMessage;
   BOOL                  _sentBeginSizing;
   BOOL                  _disableDisplay;
   unsigned              _styleMask;
   BOOL                  _isPanel;

   id                    _delegate;
   NSMutableDictionary  *_deviceDictionary;
}

-initWithFrame:(NSRect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(CGSBackingStoreType)backingType;

-(void)setDelegate:delegate;
-delegate;

-(void)invalidate;

-(HWND)windowHandle;

-(void)setStyleMask:(unsigned)mask;
-(void)setTitle:(NSString *)title;
-(void)setFrame:(NSRect)frame;

-(void)showWindowForAppActivation:(NSRect)frame;
-(void)hideWindowForAppDeactivation:(NSRect)frame;

-(void)hideWindow;
-(void)showWindowWithoutActivation;
-(void)bringToTop;
-(void)placeAboveWindow:(Win32Window *)other;
-(void)placeBelowWindow:(Win32Window *)other;

-(void)makeKey;
-(void)captureEvents;
-(void)miniaturize;
-(void)deminiaturize;
-(BOOL)isMiniaturized;

-(void)flushBuffer;

-(NSPoint)convertPOINTLToBase:(POINTL)point;
-(NSPoint)mouseLocationOutsideOfEventStream;

-(void)adjustEventLocation:(NSPoint *)location;

-(void)sendEvent:(CGEvent *)event;

@end

static inline NSRect NSRectFromRECT(RECT rect) {
   NSRect result;

   result.origin.x=rect.left;
   result.origin.y=rect.top;
   result.size.width=rect.right-rect.left;
   result.size.height=rect.bottom-rect.top;

   return result;
}

