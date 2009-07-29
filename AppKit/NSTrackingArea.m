/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSTrackingArea.h>
#import <AppKit/NSView.h>

@implementation NSTrackingArea

-initWithRect:(NSRect)rect view:(NSView *)view flipped:(BOOL)flipped owner:owner userData:(void *)userData
   assumeInside:(BOOL)assumeInside isToolTip:(BOOL)isToolTip {
   _rect=rect;
   _view=view;
   _isFlipped=flipped;
   _owner=[owner retain];
   _userData=userData;
   _mouseInside=assumeInside;
   _isToolTip=isToolTip;
   _tag=-1;
   return self;
}

-(void)dealloc {
   [_owner release];
   [super dealloc];
}

-(NSView *)view {
    return _view;
}

-(int)tag {
   return _tag;
}

-(void)setTag:(int)tag {
   _tag=tag;
}

-(NSRect)rect {
   return _rect;
}

-(BOOL)isFlipped {
   return _isFlipped;
}

-(BOOL)isToolTip {
   return _isToolTip;
}

-owner {
   return _owner;
}

-(void *)userData {
   return _userData;
}

-(BOOL)mouseInside {
   return _mouseInside;
}

-(void)setMouseInside:(BOOL)inside {
   _mouseInside=inside;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] tag: %d rect: %@ view: %@ owner: %@ isToolTip: %@>",
        [self class], self, _tag, NSStringFromRect(_rect), [_view class], [_owner class], _isToolTip ? @"YES" : @"NO"];
}

@end
