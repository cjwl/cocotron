/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSRulerMarker.h>
#import <AppKit/NSRulerView.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWindow.h>

@implementation NSRulerMarker

+ (NSImage *)defaultMarkerImage
{
    return [NSImage imageNamed:@"NSRulerMarkerTab"];
}

- (id)initWithRulerView:(NSRulerView *)ruler markerLocation:(float)location image:(NSImage *)image imageOrigin:(NSPoint)point
{
    _ruler = ruler;
    _markerLocation = location;
    _image = [image retain];
    _imageOrigin = point;
    _isMovable = YES;
    _isRemovable = YES;
    
    return self;
}

- (void)dealloc
{
    [_image release];
    
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    NSRulerMarker *copy = NSCopyObject(self, 0, zone);
    
    copy->_ruler = [_ruler retain];
    copy->_image = [_image retain];
    copy->_representedObject = [_representedObject copy];
    
    return copy;
}

- (NSRulerView *)ruler
{
    return _ruler;
}

- (float)markerLocation
{
    return _markerLocation;
}

- (NSImage *)image
{
    return _image;
}

- (NSPoint)imageOrigin
{
    return _imageOrigin;
}

- (id <NSCopying>)representedObject
{
    return _representedObject;
}

- (BOOL)isRemovable
{
    return _isRemovable;
}

- (BOOL)isMovable
{
    return _isMovable;
}

- (void)setMarkerLocation:(float)location
{
    _markerLocation = location;
}

- (void)setImage:(NSImage *)image
{
    [_image release];
    _image = [image retain];
}

- (void)setImageOrigin:(NSPoint)point
{
    _imageOrigin = point;
}

- (void)setRepresentedObject:(id <NSCopying>)object
{
    [_representedObject release];
    _representedObject = object;
}

- (void)setRemovable:(BOOL)flag
{
    _isRemovable = flag;
}

- (void)setMovable:(BOOL)flag
{
    _isMovable = flag;
}

- (float)thicknessRequiredInRuler
{
    float thickness = 0;
    
    if ([_ruler orientation] == NSVerticalRuler) {
        thickness += [[self image] size].width;
        thickness += _imageOrigin.x;
    }
    else if ([_ruler orientation] == NSHorizontalRuler) {
        thickness += [[self image] size].height;
        thickness += _imageOrigin.y;
    }
    
    return thickness;
}

- (NSRect)imageRectInRuler
{
    NSRect rect = [_ruler frame];
    
    if ([_ruler orientation] == NSHorizontalRuler)
        rect.origin.x += _markerLocation;
    else
        rect.origin.y += _markerLocation;       // how does a flipped system affect this? hm
    
    rect.origin.x += _imageOrigin.x;
    rect.origin.y += _imageOrigin.y;
    
    rect.size = [_image size];
    
    return rect;
}

- (void)drawRect:(NSRect)rect
{
    [[self image] compositeToPoint:[self imageRectInRuler].origin operation:NSCompositeSourceOver];
}

- (BOOL)isDragging
{
    return _isDragging;
}

- (BOOL)trackMouse:(NSEvent *)event adding:(BOOL)adding
{
    NSPoint point = [_ruler convertPoint:[event locationInWindow] fromView:nil];

    if (adding == YES) {
        if ([[_ruler clientView] respondsToSelector:@selector(rulerView:shouldAddMarker:)])
            if ([[_ruler clientView] rulerView:_ruler shouldAddMarker:self] == NO)
                return NO;

        do {            
            float newLocation = [_ruler orientation] == NSHorizontalRuler ? point.x : point.y;
            
            point = [_ruler convertPoint:[event locationInWindow] fromView:nil];
            
            if ([[_ruler clientView] respondsToSelector:@selector(rulerView:willAddMarker:atLocation:)])
                _markerLocation = [[_ruler clientView] rulerView:_ruler willAddMarker:self atLocation:newLocation];
            else
                _markerLocation = newLocation;
            
            [_ruler lockFocus];
            [_ruler drawRect:[_ruler bounds]];
            [self drawRect:[_ruler bounds]];
            [_ruler unlockFocus];
            
            [[_ruler window] flushWindow];
            
            event = [[_ruler window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
        } while ([event type] != NSLeftMouseUp);
        
        // check for adding...
        if (NSMouseInRect(point, [_ruler bounds], [_ruler isFlipped]) == YES) {
            if ([[_ruler clientView] respondsToSelector:@selector(rulerView:shouldAddMarker:)])
                if ([[_ruler clientView] rulerView:_ruler shouldAddMarker:self] == NO)
                    return NO;
            
            [_ruler addMarker:self];
            
            if ([[_ruler clientView] respondsToSelector:@selector(rulerView:didAddMarker:)])
                [[_ruler clientView] rulerView:_ruler didAddMarker:self];

            return YES;
        }
    }
    else {
        if ([[_ruler clientView] respondsToSelector:@selector(rulerView:shouldMoveMarker:)])
            if ([[_ruler clientView] rulerView:_ruler shouldMoveMarker:self] == NO)
                return NO;
        
        do {
            float newLocation = [_ruler orientation] == NSHorizontalRuler ? point.x : point.y;
            
            point = [_ruler convertPoint:[event locationInWindow] fromView:nil];
            
            if ([self isMovable]) {
                if ([[_ruler clientView] respondsToSelector:@selector(rulerView:willMoveMarker:toLocation:)])
                    _markerLocation = [[_ruler clientView] rulerView:_ruler willMoveMarker:self toLocation:newLocation];
                else
                    _markerLocation = newLocation;
                
                [_ruler lockFocus];                
                [_ruler drawRect:[_ruler bounds]];
                [_ruler unlockFocus];

                [[_ruler window] flushWindow];

                if ([[_ruler clientView] respondsToSelector:@selector(rulerView:didMoveMarker:)])
                    [[_ruler clientView] rulerView:_ruler didMoveMarker:self];
            }
                        
            event = [[_ruler window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
        } while ([event type] != NSLeftMouseUp);

        // check for removing...
        if (NSMouseInRect(point, [_ruler bounds], [_ruler isFlipped]) == NO) {
            if ([self isRemovable] == NO)
                return NO;

            if ([[_ruler clientView] respondsToSelector:@selector(rulerView:shouldRemoveMarker:)])
                if ([[_ruler clientView] rulerView:_ruler shouldRemoveMarker:self] == NO)
                    return NO;

            [_ruler removeMarker:self];
            
            if ([[_ruler clientView] respondsToSelector:@selector(rulerView:didRemoveMarker:)])
                [[_ruler clientView] rulerView:_ruler didRemoveMarker:self];
        }

        return YES;
    }
    
    return NO;
}


@end
