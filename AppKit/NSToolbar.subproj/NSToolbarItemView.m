/* Copyright (c) 2009 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSToolbarItemView.h"
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>

@interface NSToolbarItem(private)
-(void)drawInRect:(NSRect)bounds highlighted:(BOOL)highlighted;
@end

@implementation NSToolbarItemView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _toolbarItem=nil;
   return self;
}

-(void)dealloc {
   _toolbarItem=nil;
   [super dealloc];
}

-(void)setToolbarItem:(NSToolbarItem *)item {
   _toolbarItem=item;
}

-(void)setSubview:(NSView *)view {
   while([[self subviews] count])
    [[[self subviews] lastObject] removeFromSuperview];
   
   if(view!=nil)
    [self addSubview:view];
}

-(NSView *)view {
   return [[self subviews] lastObject];
}

-(void)drawRect:(NSRect)rect {
   [_toolbarItem drawInRect:[self bounds] highlighted:_isHighlighted];  
}

-(void)mouseDown:(NSEvent *)event {
   BOOL sendAction=NO;

   if(![_toolbarItem isEnabled])
    return;

   do {
    NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];

    _isHighlighted=NSMouseInRect(point,[self bounds],[self isFlipped]);

    [self setNeedsDisplay:YES];
    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask| NSLeftMouseDraggedMask];
   }while([event type]!=NSLeftMouseUp);

   if(_isHighlighted){
    _isHighlighted=NO;
    [NSApp sendAction:[_toolbarItem action] to:[_toolbarItem target] from:_toolbarItem];
    [self setNeedsDisplay:YES];
   }
}

@end

