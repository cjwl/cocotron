/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSToolTipWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindowBackgroundView.h>

#define TOOLTIP_FONT_SIZE   12.0

@implementation NSToolTipWindow

+ (NSToolTipWindow *)sharedToolTipWindow
{
    static NSToolTipWindow *singleton = nil;
    
    if (singleton == nil)
        singleton = [[NSToolTipWindow alloc] initWithContentRect:NSMakeRect(0, 0, 20, 20) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    return singleton;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(unsigned)backing defer:(BOOL)defer
{
    [super initWithContentRect:contentRect styleMask:styleMask backing:backing defer:defer];
    _textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2, 2, contentRect.size.width, contentRect.size.height)];
    [_textField setFont:[NSFont toolTipFontOfSize:TOOLTIP_FONT_SIZE]];
    [self setBackgroundColor:[NSColor yellowColor]];
    [_backgroundView setBorderType:NSLineBorder];
    [[self contentView] addSubview:_textField];
    
    return self;
}

- (void)setToolTip:(NSString *)toolTip
{
    NSRect frame = [self frame];
    
    [_textField setStringValue:toolTip];

    frame.size = [[_textField stringValue] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipFontOfSize:TOOLTIP_FONT_SIZE], NSFontAttributeName, nil]];
    
    [_textField setBoundsSize:frame.size];
    [_textField setFrameSize:frame.size];

    frame = NSInsetRect(frame, -2, -2);

    [self setFrame:frame display:YES];    
}

- (NSString *)toolTip
{
    return [_textField stringValue];
}

- (void)setLocationOnScreen:(NSPoint)location
{
    NSRect frame = [self frame];
    
    frame.origin = location;
    
    [self setFrame:frame display:NO];
}

- (NSPoint)locationOnScreen
{
    return [self frame].origin;
}

@end
