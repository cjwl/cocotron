/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSActionCell.h>

typedef enum {
   NSTickMarkBelow,
   NSTickMarkAbove,
   NSTickMarkLeft=NSTickMarkAbove,
   NSTickMarkRight=NSTickMarkBelow
} NSTickMarkPosition;

@interface NSSliderCell : NSActionCell {
    double _minValue;
    double _maxValue;
    float  _knobThickness;
    BOOL   _isVertical;
    NSRect _lastRect;

    int _numberOfTickMarks;
    NSTickMarkPosition _tickMarkPosition;
    BOOL _allowsTickMarkValuesOnly;
}

-(double)minValue;
-(double)maxValue;

-(int)numberOfTickMarks;
-(NSTickMarkPosition)tickMarkPosition;
-(BOOL)allowsTickMarkValuesOnly;
-(float)knobThickness;

-(void)setMinValue:(double)minValue;
-(void)setMaxValue:(double)maxValue;

-(void)setNumberOfTickMarks:(int)number;
-(void)setTickMarkPosition:(NSTickMarkPosition)position;
-(void)setAllowsTickMarkValuesOnly:(BOOL)valuesOnly;
-(void)setKnobThickness:(float)thickness;

-(int)isVertical;

-(int)indexOfTickMarkAtPoint:(NSPoint)point;

-(double)tickMarkValueAtIndex:(int)index;
-(double)closestTickMarkValueToValue:(double)value;

-(NSRect)rectOfTickMarkAtIndex:(int)index;

-(void)drawBarInside:(NSRect)frame flipped:(BOOL)isFlipped;
-(void)drawKnob;
-(void)drawKnob:(NSRect)rect;

@end
