/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSWindowBackgroundView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenuView.h>
#import <AppKit/NSToolbarView.h>

@implementation NSWindowBackgroundView

-(BOOL)isOpaque {
   return YES;
}

-(NSBorderType)borderType {
   return _borderType;
}

-(void)setBorderType:(NSBorderType)borderType {
   _borderType = borderType;
   [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)rect {
    NSRect bounds=[self bounds];
    float cheatSheet = 0;

    switch(_borderType){
        case NSNoBorder:
            break;
            
        case NSLineBorder:
            [[NSColor blackColor] setStroke];
            NSFrameRect(bounds);
            bounds = NSInsetRect(bounds, 1, 1);
            cheatSheet = 1;
            break;
            
        case NSBezelBorder:
            NSDrawGrayBezel(bounds,bounds);         // this looks pretty bad here too
            bounds = NSInsetRect(bounds, 2, 2);
            cheatSheet = 2;
            break;
            
        case NSGrooveBorder:
            NSDrawGroove(bounds,bounds);
            bounds = NSInsetRect(bounds, 2, 2);
            cheatSheet = 2;
            break;
            
        case NSButtonBorder:
            NSDrawButton(bounds,bounds);
            bounds = NSInsetRect(bounds, 2, 2);
            cheatSheet = 2;
            break;
   }
    
   if([[self window] isSheet])
    bounds.size.height += cheatSheet;

   [[[self window] backgroundColor] setFill];
   NSRectFill(bounds);
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize {
   NSView *menuView=nil;
   NSView *toolbarView=nil;
   NSView *contentView=nil;
   
// tile the subviews, when/if we add titlebars and such do it here
   for(NSView *view in _subviews){
    if([view isKindOfClass:[NSMenuView class]])
     menuView=view;
    else if([view isKindOfClass:[NSToolbarView class]])
     toolbarView=view;
    else
     contentView=view;
   }
   
   [menuView resizeWithOldSuperviewSize:oldSize];
   [toolbarView resizeWithOldSuperviewSize:oldSize];

   NSRect contentFrame=[self bounds];
   
   if(toolbarView!=nil)
    contentFrame.size.height=[toolbarView frame].origin.y-contentFrame.origin.y;
   else if(menuView!=nil)
    contentFrame.size.height=[menuView frame].origin.y-contentFrame.origin.y;
    
   [contentView setFrame:contentFrame];
}

@end
