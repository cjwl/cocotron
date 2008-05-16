/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSRulerView.h>
#import <AppKit/NSRulerMarker.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSMeasurementUnit.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSText.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSImage.h>

#define DEFAULT_RULE_THICKNESS      16.0
#define DEFAULT_MARKER_THICKNESS    15.0

#define HASH_MARK_THICKNESS_FACTOR  0.5
#define HASH_MARK_WIDTH             1.0
#define HASH_MARK_REQUIRED_WIDTH    2.0

#define LABEL_TEXT_CORRECTION       2.0
#define LABEL_TEXT_PRIMARY_OFFSET   3.0
#define LABEL_TEXT_SECONDARY_OFFSET 3.0

@implementation NSRulerView

+ (void)registerUnitWithName:(NSString *)name abbreviation:(NSString *)abbreviation unitToPointsConversionFactor:(float)conversionFactor stepUpCycle:(NSArray *)stepUpCycle stepDownCycle:(NSArray *)stepDownCycle
{
    [NSMeasurementUnit registerUnit:[NSMeasurementUnit measurementUnitWithName:name abbreviation:abbreviation pointsPerUnit:conversionFactor stepUpCycle:stepUpCycle stepDownCycle:stepDownCycle]];
}

- initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation
{
    NSRect frame = [scrollView frame];
    
    if (orientation == NSHorizontalRuler)
        frame.size.height = DEFAULT_RULE_THICKNESS;
    else
        frame.size.width = DEFAULT_RULE_THICKNESS;
    
    [super initWithFrame:frame];
    _scrollView = [scrollView retain];
    _orientation = orientation;
        
    _measurementUnit = [NSMeasurementUnit measurementUnitNamed:@"Inches"];
        
    [self setRuleThickness:DEFAULT_RULE_THICKNESS];
    [self setReservedThicknessForMarkers:DEFAULT_MARKER_THICKNESS];
    [self setReservedThicknessForAccessoryView:0.0];
        
    _markers = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_scrollView release];
    [_accessoryView release];
    
    [_markers release];
    
    [super dealloc];
}

- (BOOL)scrollViewNeedsTiling
{
    return _scrollViewNeedsTiling;
}

- (void)setScrollViewNeedsTiling:(BOOL)flag
{
    _scrollViewNeedsTiling = flag;
    [self setNeedsDisplay:YES];
}

- (NSMeasurementUnit *)measurementUnit
{
    return _measurementUnit;
}


- (NSScrollView *)scrollView
{
    return _scrollView;
}

- (NSView *)clientView
{
    return _clientView;
}

- (NSView *)accessoryView
{
    return _accessoryView;
}

- (NSArray *)markers
{
    return _markers;
}

- (NSString *)measurementUnits
{
    return [_measurementUnit name];
}

- (NSRulerOrientation)orientation
{
    return _orientation;
}

- (float)ruleThickness
{
    return _ruleThickness;
}

- (float)reservedThicknessForMarkers
{
    if (_thicknessForMarkers == 0.0) {
        int i, count = [_markers count];
        
        for (i = 0; i < count; ++i)
            if ([[_markers objectAtIndex:i] thicknessRequiredInRuler] > _thicknessForMarkers)
                _thicknessForMarkers = [[_markers objectAtIndex:i] thicknessRequiredInRuler];
    }
    
    return _thicknessForMarkers;
}

- (float)reservedThicknessForAccessoryView
{
    return _thicknessForAccessoryView;
}

- (float)originOffset
{
    return _originOffset;
}

- (float)baselineLocation
{
    return _ruleThickness;          // ??? what goes here
}

- (float)requiredThickness
{
    float result = _ruleThickness;
    
    if ([_markers count] > 0)
        result += _thicknessForMarkers;
    
    if (_accessoryView != nil)
        result += _thicknessForAccessoryView;
    
    return result;
}

- (void)setScrollView:(NSScrollView *)scrollView
{
    [_scrollView release];
    _scrollView = [scrollView retain];
}

- (void)setClientView:(NSView *)view
{
    [_clientView rulerView:self willSetClientView:view];
    [_markers removeAllObjects];
    _clientView = view;
    
    [self setScrollViewNeedsTiling:YES];
}

- (void)setAccessoryView:(NSView *)view
{
    [_accessoryView release];
    _accessoryView = [view retain];

    [self setScrollViewNeedsTiling:YES];
}

- (void)setMarkers:(NSArray *)markers
{
    [_markers release];
    _markers = [markers retain];

//    [self setScrollViewNeedsTiling:YES];
    [[self enclosingScrollView] tile];
}

- (void)addMarker:(NSRulerMarker *)marker
{
    [_markers addObject:marker];
    
//    [self setScrollViewNeedsTiling:YES];
    [[self enclosingScrollView] tile];
}

- (void)addMarkersWithImage:(NSImage *)image measurementUnit:(NSMeasurementUnit *)unit
{
    float length, markerLength;
    float last = 0, location = 0;
    
    if (image == nil)
        image = [NSRulerMarker defaultMarkerImage];
    
    if (unit == nil)
        unit = _measurementUnit;
    
    if (_orientation == NSHorizontalRuler) {
        length = _bounds.size.width;
        markerLength = [image size].width;
    }
    else {
        length = _bounds.size.height;
        markerLength = [image size].height;
    }

    while (location < length) {
        location += [unit pointsPerUnit];
        if (location > (last + markerLength)) {
            [self addMarker:[[[NSRulerMarker alloc] initWithRulerView:self markerLocation:location image:image imageOrigin:NSMakePoint(0, 0)] autorelease]];
            last = location;
        }
    }

//    [self setScrollViewNeedsTiling:YES];
    [[self enclosingScrollView] tile];
}

- (void)removeMarker:(NSRulerMarker *)marker
{
    [_markers removeObject:marker];
    
    [self setScrollViewNeedsTiling:YES];
}

- (void)removeAllMarkers
{
    [_markers removeAllObjects];
    
    [self setScrollViewNeedsTiling:YES];
}

- (void)setMeasurementUnits:(NSString *)unitName
{
    [_measurementUnit release];
    _measurementUnit = [NSMeasurementUnit measurementUnitNamed:unitName];

    [self setScrollViewNeedsTiling:YES];
}

- (void)setOrientation:(NSRulerOrientation)orientation
{
    _orientation = orientation;
}

- (void)setRuleThickness:(float)value
{
    _ruleThickness = value;
    
    [self setScrollViewNeedsTiling:YES];
}

- (void)setReservedThicknessForMarkers:(float)value
{
    _thicknessForMarkers = value;

    [self setScrollViewNeedsTiling:YES];
}

- (void)setReservedThicknessForAccessoryView:(float)value
{
    _thicknessForAccessoryView = value;

    [self setScrollViewNeedsTiling:YES];
}

- (void)setOriginOffset:(float)value
{
    _originOffset = value;
}

- (BOOL)trackMarker:(NSRulerMarker *)marker withMouseEvent:(NSEvent *)event
{
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if(NSMouseInRect(point, [self bounds], [self isFlipped])){            
        [marker trackMouse:event adding:YES];
        
        [self setNeedsDisplay:YES];
    }        
    
    return NO;
}

- (void)mouseDown:(NSEvent *)event
{
    if ([_clientView respondsToSelector:@selector(rulerView:handleMouseDown:)]) {
        [_clientView rulerView:self handleMouseDown:event];
        return;
    }
    else {
        NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        int i, count = [_markers count];
        float location;
        
        for (i = 0; i < count; ++i) {
            NSRulerMarker *marker = [_markers objectAtIndex:i];
            
            if (NSMouseInRect(point, [marker imageRectInRuler], [self isFlipped])) {
                [marker trackMouse:event adding:NO];
                [self setNeedsDisplay:YES];
                return;
            }
        }
        
        // not in a view!
        // experimental
        if ((_orientation == NSHorizontalRuler))
            location = point.x;
        else
            location = point.y;

        [self trackMarker:[[[NSRulerMarker alloc] initWithRulerView:self markerLocation:location image:[NSRulerMarker defaultMarkerImage] imageOrigin:NSMakePoint(0, 0)] autorelease] withMouseEvent:event];
    }
}

- (void)moveRulerlineFromLocation:(float)fromLocation toLocation:(float)toLocation
{
    NSNumber *old = [NSNumber numberWithFloat:fromLocation];
    NSNumber *new = [NSNumber numberWithFloat:toLocation];
    
    if ([_rulerlineLocations containsObject:old])
        [_rulerlineLocations removeObject:old];
    if ([_rulerlineLocations containsObject:new] == NO)
        [_rulerlineLocations addObject:new];
    
    [self setScrollViewNeedsTiling:YES];
}

- (void)invalidateHashMarks
{
}

- (NSDictionary *)attributesForLabel
{
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    
    [style setLineBreakMode:NSLineBreakByClipping];
    [style setAlignment:NSLeftTextAlignment];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:10.0], NSFontAttributeName,
        style, NSParagraphStyleAttributeName,
        nil];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)originalFrame
{
    NSRect frame = originalFrame;
    float pointsPerUnit = [_measurementUnit pointsPerUnit];
    float length = (_orientation == NSHorizontalRuler ? frame.size.width : frame.size.height);
    int i, count = ceil(length / pointsPerUnit);
    NSMutableArray *cycles = [[[_measurementUnit stepDownCycle] mutableCopy] autorelease];
    float extraThickness = 0;
    BOOL scrollViewHasOtherRuler = (_orientation == NSHorizontalRuler ? [[self enclosingScrollView] hasVerticalRuler] : [[self enclosingScrollView] hasHorizontalRuler]);

    if ([_markers count] > 0)
        extraThickness += _thicknessForMarkers;
    if (_accessoryView != nil)
        extraThickness += _thicknessForAccessoryView;
    
    // Some basic calculations.
    if (_orientation == NSHorizontalRuler) {
        originalFrame.size.width = HASH_MARK_WIDTH;
        originalFrame.size.height *= HASH_MARK_THICKNESS_FACTOR;
        originalFrame.origin.y += extraThickness;
    }
    else {
        originalFrame.size.width *= HASH_MARK_THICKNESS_FACTOR;
        originalFrame.size.height = HASH_MARK_WIDTH;
        originalFrame.origin.x += extraThickness;
    }
    
    // Draw major hash marks with labels.
    frame = originalFrame;
    [[NSColor controlShadowColor] setStroke];
    for (i = 0; i < count; ++i) {
        NSString *label = [NSString stringWithFormat:@"%d", i];
        NSPoint textOrigin = frame.origin;

        // A little visual nudge.. I think it looks better.
        if (i == 0 && scrollViewHasOtherRuler == NO)
            ;
        else
            NSFrameRect(frame);
        
        textOrigin.x += LABEL_TEXT_CORRECTION; // minor correction
        if (_orientation == NSHorizontalRuler) {
            textOrigin.x += LABEL_TEXT_PRIMARY_OFFSET;
            textOrigin.y += LABEL_TEXT_SECONDARY_OFFSET;
        }
        else {
            textOrigin.y += LABEL_TEXT_PRIMARY_OFFSET;
            textOrigin.x += LABEL_TEXT_SECONDARY_OFFSET;
        }

        [label drawAtPoint:textOrigin withAttributes:[self attributesForLabel]];

        if (_orientation == NSHorizontalRuler)
            frame.origin.x += pointsPerUnit;
        else
            frame.origin.y += pointsPerUnit;        
    }
    
    // Start minor hash mark processing. size.width still contains the width of major marks.
    do {
        float thisCycle = [[cycles objectAtIndex:0] floatValue];
        float pointsPerMark = pointsPerUnit * thisCycle;
        
        frame.origin = originalFrame.origin;

#if 0
        if (_orientation == NSHorizontalRuler)
            frame.size.height *= HASH_MARK_THICKNESS_FACTOR;
        else
            frame.size.width *= HASH_MARK_THICKNESS_FACTOR;
#endif
        if (_orientation == NSHorizontalRuler)
            frame.size.height *= thisCycle;
        else
            frame.size.width *= thisCycle;        
                
        frame.size.height = floor(frame.size.height);
        
        if (HASH_MARK_REQUIRED_WIDTH < pointsPerMark) {
            count = length / pointsPerMark;
            
            for (i = 0; i < count; ++i) {
                // A little visual nudge.. I think it looks better.
                if (i == 0 && scrollViewHasOtherRuler == NO)
                    ;
                else
                    NSFrameRect(frame);

                if (_orientation == NSHorizontalRuler)
                    frame.origin.x += pointsPerMark;
                else
                    frame.origin.y += pointsPerMark;                        
            }
        }
        
        [cycles removeObjectAtIndex:0];        
    } while ([cycles count] > 0);
}

- (void)drawMarkersInRect:(NSRect)frame
{
    int i, count = [_markers count];
    
    if (_orientation == NSHorizontalRuler)
        frame.size.height = _thicknessForMarkers;
    else
        frame.size.width = _thicknessForMarkers;

    // Clear marker area.    
    [[NSColor windowBackgroundColor] setFill];
    NSRectFill(frame);
    for (i = 0; i < count; ++i)
        [[_markers objectAtIndex:i] drawRect:frame];
}

- (void)drawRulerlineLocationsInRect:(NSRect)rect
{
    int i, count = [_rulerlineLocations count];
    
    if (_orientation == NSHorizontalRuler)
        rect.size.width = 1;
    else
        rect.size.height = 1;
    
    [[NSColor controlHighlightColor] setStroke];
    for (i = 0; i < count; ++i) {
        if (_orientation == NSHorizontalRuler)
            rect.origin.x = [[_rulerlineLocations objectAtIndex:i] floatValue];
        else
            rect.origin.y = [[_rulerlineLocations objectAtIndex:i] floatValue];
        
        NSFrameRect(rect);
    }
}

- (void)drawRect:(NSRect)frame
{
    NSRect rect = frame;
    
    if (_scrollViewNeedsTiling) {
        [[self enclosingScrollView] tile];
        
        _scrollViewNeedsTiling = NO;
    }

    [[NSColor controlShadowColor] setStroke];
    if (_orientation == NSHorizontalRuler) {
        rect.origin.y += rect.size.height - 1;
        rect.size.height = 1;
    }
    else {
        rect.origin.x += rect.size.width - 1;
        rect.size.width = 1;
    }    
    NSFrameRect(rect);
    
    [self drawHashMarksAndLabelsInRect:frame];
    
    if ([_markers count] > 0)
        [self drawMarkersInRect:frame];
    
    if ([_rulerlineLocations count] > 0)
        [self drawRulerlineLocationsInRect:frame];
}

- (BOOL)isFlipped
{
    if (_orientation == NSHorizontalRuler)
        return YES;
    
    return [[_scrollView documentView] isFlipped];
}


@end
