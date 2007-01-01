/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKit.h>
#import <AppKit/NSBrowserCellColorList.h>
#import <AppKit/NSStringDrawer.h>

@implementation NSBrowserCellColorList

- (NSColor *)color { return _color; }
- (void)setColor:(NSColor *)color { [_color release]; _color = [color retain]; }

- (void)dealloc
{
    [_color release];
    [super dealloc];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control
{
   NSAttributedString *title=[self attributedStringValue];
   NSRect              colorRect = frame;
   NSSize              titleSize=[title size];
   NSRect              titleRect=frame;

   colorRect.size.width = colorRect.size.height;

   titleRect.origin.x += colorRect.size.width + 2;
   titleRect.origin.y += (titleRect.size.height-titleSize.height)/2;
   titleRect.size.height = titleSize.height;

   titleRect.size.width -= (colorRect.size.width+2);

   if([self isHighlighted] || [self state])
    [[NSColor selectedControlColor] set];
   else
    [[NSColor controlBackgroundColor] set];	// was whiteColor

   NSRectFill(frame);

   [_color drawSwatchInRect:colorRect];
   [title _clipAndDrawInRect:titleRect];
}

@end
