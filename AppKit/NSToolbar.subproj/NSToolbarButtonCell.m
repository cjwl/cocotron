/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSToolbarButtonCell.h>
#import <AppKit/NSToolbarButton.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>

@implementation NSToolbarButtonCell

- (id)initTextCell:(NSString *)string
{
    [super initTextCell:string];
    [self setFont:[NSFont systemFontOfSize:10.0]];
    [self setImagePosition:NSImageOnly];
    
    return self;
}

- (id)initImageCell:(NSImage *)image 
{
    [super initImageCell:image];
    [self setFont:[NSFont systemFontOfSize:10.0]];
    [self setImagePosition:NSImageOnly];
    
    return self;
}

- (BOOL)drawsSpaceOutline
{
    return _drawsSpaceOutline;
}

- (void)setDrawsSpaceOutline:(BOOL)flag
{
    _drawsSpaceOutline = flag;
}

- (BOOL)drawsFlexibleSpaceOutline
{
    return _drawsFlexibleSpaceOutline;
}

- (void)setDrawsFlexibleSpaceOutline:(BOOL)flag
{
    _drawsFlexibleSpaceOutline = flag;
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control 
{
    NSRect titleFrame = frame;
    NSToolbar *toolbar = [[control window] toolbar];
    NSDictionary *attributes = [NSToolbarView attributesWithSizeMode:[toolbar sizeMode]];
    
    titleFrame.size.height = [[self title] sizeWithAttributes:attributes].height;
    
    if ([toolbar displayMode] == NSToolbarDisplayModeIconAndLabel ||
        [toolbar displayMode] == NSToolbarDisplayModeDefault ||
        [toolbar displayMode] == NSToolbarDisplayModeLabelOnly) {
            [[NSColor controlTextColor] set];
            [[self title] _clipAndDrawInRect:titleFrame withAttributes:attributes];
            if ([self isHighlighted]) {
                titleFrame.origin.x++;
                titleFrame.origin.y--;
                [[self title] _clipAndDrawInRect:titleFrame withAttributes:attributes];
            }
                
            frame.origin.y += titleFrame.size.height;
            frame.size.height -= titleFrame.size.height;
    }
    
    if (control == nil && [self drawsSpaceOutline]) {
        if ([self drawsFlexibleSpaceOutline] == NO) {
            frame.origin.x += (frame.size.width - frame.size.height)/2;
            frame.size.width = frame.size.height;
        }
        
        NSDottedFrameRect(NSInsetRect(frame, 3, 3));
    }
    else if ([toolbar displayMode] == NSToolbarDisplayModeDefault ||
        [toolbar displayMode] == NSToolbarDisplayModeIconAndLabel ||
        [toolbar displayMode] == NSToolbarDisplayModeIconOnly)
            [super drawInteriorWithFrame:frame inView:control];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)control
{
    [[NSColor windowBackgroundColor] set];
    NSRectFill(frame);
    
    [self drawInteriorWithFrame:frame inView:control];
}

@end
