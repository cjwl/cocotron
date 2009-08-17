/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSlider.h>
#import <AppKit/NSSliderCell.h>

@implementation NSSlider

+(Class)cellClass {
   return [NSSliderCell class];
}

-(double)minValue {
   return [[self selectedCell] minValue];
}

-(double)maxValue {
   return [[self selectedCell] maxValue];
}

-(int)numberOfTickMarks {
    return [[self selectedCell] numberOfTickMarks];
    [self setNeedsDisplay:YES];
}

-(void)setMinValue:(double)value {
   [[self selectedCell] setMinValue:value];
   [self setNeedsDisplay:YES];
}

-(void)setMaxValue:(double)value {
    [[self selectedCell] setMaxValue:value];
    [self setNeedsDisplay:YES];
}

-(void)setNumberOfTickMarks:(int)value {
    [[self selectedCell] setNumberOfTickMarks:value];
    [self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)moveUp:(id)sender {
    [[self selectedCell] moveUp:sender];
    [self setNeedsDisplay:YES];
}

- (void)moveDown:(id)sender {
    [[self selectedCell] moveDown:sender];
    [self setNeedsDisplay:YES];
}

- (void)moveLeft:(id)sender {
    [[self selectedCell] moveLeft:sender];
    [self setNeedsDisplay:YES];
}

- (void)moveRight:(id)sender {
    [[self selectedCell] moveRight:sender];
    [self setNeedsDisplay:YES];
}

@end
