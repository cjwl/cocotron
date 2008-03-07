/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGRender;

@interface KGRenderView : NSView {
   KGRender   *_render;
   struct {
    float       _scalex;
    float       _scaley;
    float       _rotation;
    CGBlendMode _blendMode;
    float       _lineWidth;
    CGLineCap   _lineCap;
    CGLineJoin  _lineJoin;
    float        _miterLimit;
    float        _dashPhase;
    unsigned     _dashLengthsCount;
    float       *_dashLengths;
   } gStateX,*gState;
   
   NSColor *_destinationColor;
   NSColor *_sourceColor;
   CGPathDrawingMode _pathDrawingMode;
}

-(void)setRender:(KGRender *)render;

-(void)setDestinationColor:(NSColor *)color;
-(void)setSourceColor:(NSColor *)color;
-(void)setBlendMode:(CGBlendMode)blendMode;
-(void)setPathDrawingMode:(CGPathDrawingMode)pathDrawingMode;
-(void)setLineWidth:(float)width;
-(void)setDashPhase:(float)value;
-(void)setDashLength:(float)value;

-(void)setScaleX:(float)value;
-(void)setScaleY:(float)value;
-(void)setRotation:(float)value;

@end
