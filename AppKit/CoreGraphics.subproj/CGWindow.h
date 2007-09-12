/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

@class KGContext,CGEvent;

@interface CGWindow : NSObject

-(void)setDelegate:delegate;
-delegate;

-(void)invalidate;

-(KGContext *)cgContext;

-(void)setTitle:(NSString *)title;
-(void)setFrame:(NSRect)frame;

-(void)showWindowForAppActivation:(NSRect)frame;
-(void)hideWindowForAppDeactivation:(NSRect)frame;

-(void)hideWindow;

-(void)placeAboveWindow:(CGWindow *)other;
-(void)placeBelowWindow:(CGWindow *)other;

-(void)makeKey;
-(void)captureEvents;
-(void)miniaturize;
-(void)deminiaturize;
-(BOOL)isMiniaturized;

-(void)flushBuffer;

-(NSPoint)mouseLocationOutsideOfEventStream;

-(void)sendEvent:(CGEvent *)event;

@end

@interface NSObject(CGWindow_delegate)

-(void)platformWindow:(CGWindow *)window frameChanged:(NSRect)frame;
-(NSSize)platformWindow:(CGWindow *)window frameSizeWillChange:(NSSize)size;
-(void)platformWindowWillBeginSizing:(CGWindow *)window;
-(void)platformWindowDidEndSizing:(CGWindow *)window;
-(void)platformWindowExitMove:(CGWindow *)window;

-(void)platformWindow:(CGWindow *)window needsDisplayInRect:(NSRect)rect;
-(void)platformWindowStyleChanged:(CGWindow *)window;
-(void)platformWindowWillClose:(CGWindow *)window;

-(void)platformWindowWillMove:(CGWindow *)window;
-(void)platformWindowDidMove:(CGWindow *)window;

-(void)platformWindowDeminiaturized:(CGWindow *)window;
-(void)platformWindowMiniaturized:(CGWindow *)window;
-(void)platformWindowActivated:(CGWindow *)window;
-(void)platformWindowDeactivated:(CGWindow *)window checkForAppDeactivation:(BOOL)checkForApp;

-(BOOL)platformWindowIgnoreModalMessages:(CGWindow *)window;

-(BOOL)platformWindowSetCursorEvent:(CGWindow *)window;

@end
