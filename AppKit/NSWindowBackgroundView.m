/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSWindowBackgroundView.h>
#import <AppKit/NSWindowAnimationContext.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>

// FIX, the border stuff should probably be moved into a sheet background view or somesuch

@implementation NSWindowBackgroundView

-(BOOL)isOpaque {
   return YES;
}

- (NSBorderType)borderType
{
    return _borderType;
}

- (void)setBorderType:(NSBorderType)borderType
{
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
    
    // If we want to be *extra* tricky (and we do), we cheat for sheets: 
    // during the animation cycle, the top part of the border is not drawn.
    if ([[[self window] _animationContext] stepCount] > 0)
        bounds.size.height += cheatSheet;

    [[[self window] backgroundColor] setFill];
    NSRectFill(bounds);
}

- (BOOL)cachesImageForAnimation
{
    return _cachesImageForAnimation;
}

- (void)setCachesImageForAnimation:(BOOL)flag
{
    _cachesImageForAnimation = flag;
}


// BROKEN
- (void)displayRectIgnoringOpacity:(NSRect)rect 
{
    if ([[self window] _animationContext] != nil && [self cachesImageForAnimation]) {
        if (_animationCache == nil)
            [self cacheImageForAnimation];
        
//         NSLog(@"hmm: %@ at %@", NSStringFromPoint(_bounds.origin), _animationCache);
//        [_animationCache compositeToPoint:_bounds.origin operation:NSCompositeSourceOver];
        [_animationCache compositeToPoint:NSMakePoint(50,50) operation:NSCompositeSourceOver];
    }
    else
        [super displayRectIgnoringOpacity:rect];
}

- (void)cacheImageForAnimation
{
    int i, count = [_subviews count];
    
    _animationCache = [[NSImage alloc] initWithSize:_bounds.size];
    
    [_animationCache setCachedSeparately:YES];    
    [_animationCache lockFocus];
    
    [self drawRect:_bounds];
    
    for (i = 0; i < count; i++) {
        NSView *view = [_subviews objectAtIndex:i];
        NSRect  check = [self convertRect:_bounds toView:view];
        
        [view drawRect:[view bounds]];
//        [view displayRectIgnoringOpacity:check];        
#if 0
        if(NSIntersectsRect(check, [view bounds])){
            check = NSIntersectionRect(check, [view visibleRect]);
            [view displayRectIgnoringOpacity:check];
        }
#endif
    }
    
    [_animationCache unlockFocus];
}

- (BOOL)cachedImageIsValid
{
    return _animationCache != nil;
}

- (void)invalidateCachedImage
{
    [_animationCache release];
    _animationCache = nil;
}

@end
