/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSToolbarSeparatorItemCell.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSColor.h>

@implementation NSToolbarSeparatorItemCell

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control 
{
    NSRect titleFrame = frame;
    NSToolbar *toolbar = [[control window] toolbar];
    NSDictionary *attributes = [NSToolbarView attributesWithSizeMode:[toolbar sizeMode]];
    
    titleFrame.size.height = [[self title] sizeWithAttributes:attributes].height;

    [[NSColor windowBackgroundColor] set];
    NSRectFill(frame);

    if (control == nil && [[self title] length] != 1) {
        [[NSColor controlTextColor] set];
        [[self title] _clipAndDrawInRect:titleFrame withAttributes:attributes];
        
        frame.origin.y += titleFrame.size.height;
        frame.size.height -= titleFrame.size.height;
    }
    
    frame.origin.x = floor(frame.origin.x + (frame.size.width/2));
    frame.size.width = 1;
    NSDottedFrameRect(frame);    
}

@end
