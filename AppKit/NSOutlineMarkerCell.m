/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSOutlineMarkerCell.h>
#import <AppKit/NSInterfaceGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>

@implementation NSMacintoshOutlineMarkerCell

+ (NSImage *)openMarkerImage {
    return [NSImage imageNamed:@"NSOutlineViewOpen"];
}

+ (NSImage *)closedMarkerImage {
    return [NSImage imageNamed:@"NSOutlineViewClosed"];
}

-(id)initImageCell:(NSImage *)someImage
{
    [super initImageCell:someImage];
    _openMarker = [[[self class] openMarkerImage] retain];
    _closedMarker = [[[self class] closedMarkerImage] retain];

    [self setImageAlignment:NSImageAlignCenter];
    [self setImageFrameStyle:NSImageFrameNone];
    [self setImageScaling:NSScaleProportionally];

    return self;
}

-(void)dealloc
{
    [_openMarker release];
    [_closedMarker release];

    [super dealloc];
}

@end

@implementation NSWindowsOutlineMarkerCell

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control {
    NSInterfaceDrawOutlineMarker(frame, frame, _state);
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView *)control {
    [self drawInteriorWithFrame:NSInsetRect(frame,3,4) inView:control];
}

@end
