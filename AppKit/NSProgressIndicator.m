/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

// rough estimates
#define BLOCK_WIDTH	8.0
#define BLOCK_SPACING	2.0

@implementation NSProgressIndicator

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned           flags=[keyed decodeIntForKey:@"NSpiFlags"];

    _isBezeled=YES; // obsolete?    
    _isIndeterminate=(flags&0x02)?YES:NO;
    _minValue=[keyed decodeDoubleForKey:@"NSMinValue"];
    _maxValue=[keyed decodeDoubleForKey:@"NSMaxValue"];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }
   return self;
}


-initWithFrame:(NSRect)frame {
    [super initWithFrame:frame];
        _isBezeled = YES;
        _isIndeterminate = YES;
        _value = _minValue = 0.0;
        _maxValue = 100.0;
        _animationDelay = 5.0/60.0;	// 5/60th of a second
        _animationOrigin = 0;

    return self;
}

-(void)dealloc {
    [_animationTimer invalidate];
    [_animationTimer release];

    [super dealloc];
}

-(BOOL)isFlipped {
    return YES;
}

-(NSRect)progressRect {
    if (_isBezeled)
        return NSInsetRect(_bounds,2,2);

    return _bounds;
}

-(void)drawRect:(NSRect)clipRect {
    NSRect progressRect = [self progressRect];
    NSRect blockRect = progressRect;
    float percentage;
    int numBlocks;
    
    [[self graphicsStyle] drawProgressIndicatorBezel:_bounds clipRect:clipRect bezeled:_isBezeled];
    
    [[NSColor selectedControlColor] set];
    
    if (_isIndeterminate) {
        // draw fractional block, if visible..
        if (_animationOrigin > BLOCK_SPACING) {
            blockRect.size.width = _animationOrigin - BLOCK_SPACING;
            NSRectFill(blockRect);
        }

        // fixup origin
        blockRect.origin.x += _animationOrigin;

        // calling doubleValue on an indeterminate NSPI isn't supported anyway
        // use a 100% value to fill in the rest of the blocks
        _value = _maxValue;
    }

    // main block drawing
    percentage = (_value - _minValue)/(_maxValue - _minValue);
    numBlocks = (percentage * progressRect.size.width)/(BLOCK_WIDTH + BLOCK_SPACING);
    
    // make 100% really fill up the progress bar, but leave 0% as blank.
    // progress indication is an inexact science.
    if (numBlocks > 0)
        numBlocks++;

    while (numBlocks--) {
        blockRect.size.width = BLOCK_WIDTH;

        // truncate last block
        if (NSMaxX(blockRect) > NSMaxX(progressRect))
            blockRect.size.width -= (NSMaxX(blockRect) - NSMaxX(progressRect));

        if (blockRect.size.width > 0) {
            NSRectFill(blockRect);
            blockRect.origin.x += BLOCK_WIDTH + BLOCK_SPACING;
        }
    }
}

-(double)minValue {
    return _minValue;
}

-(double)maxValue {
    return _maxValue;
}

-(double)doubleValue {
    return _value;
}

-(NSTimeInterval)animationDelay {
    return _animationDelay;
}

-(BOOL)isIndeterminate {
    return _isIndeterminate;
}

-(BOOL)isBezeled {
    return _isBezeled;
}

-(void)setMinValue:(double)value {
    _minValue = value;
    [self setNeedsDisplay:YES];
}

-(void)setMaxValue:(double)value {
    _maxValue = value;
    [self setNeedsDisplay:YES];
}

-(void)setDoubleValue:(double)value {
    if (value >= _minValue && value <= _maxValue) {
        _value = value;
        [self setNeedsDisplay:YES];
    }
}

-(void)setAnimationDelay:(double)delay {
    _animationDelay = delay;
}

-(void)setIndeterminate:(BOOL)flag {
    _isIndeterminate = flag;
}

-(void)setBezeled:(BOOL)flag {
    _isBezeled = flag;
}

-(void)incrementBy:(double)value {
    [self setDoubleValue:_value+value];
}

-(void)startAnimation:sender {
    if (!_isIndeterminate)
        [NSException raise:NSInternalInconsistencyException
                    format:@"startAnimation: called on determinate NSProgressIndicator"];

    _animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_animationDelay
                                                        target:self
                                                      selector:@selector(animate:)
                                                      userInfo:[NSDictionary dictionary]
                                                       repeats:YES] retain];
}

-(void)stopAnimation:sender {
    if (!_isIndeterminate)
        [NSException raise:NSInternalInconsistencyException
                    format:@"startAnimation: called on determinate NSProgressIndicator"];

    [_animationTimer invalidate];
    [_animationTimer release];
    _animationTimer = nil;
}

-(void)animate:sender {
    _animationOrigin++;
    if (_animationOrigin == BLOCK_WIDTH+BLOCK_SPACING)
        _animationOrigin = 0;
    
    [self setNeedsDisplay:YES];
}

@end
