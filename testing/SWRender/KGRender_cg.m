/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRender_cg.h"

@implementation KGRender_cg

-init {
   [super init];
   _context=CGBitmapContextCreate(_data,_pixelsWide,_pixelsHigh,_bitsPerComponent,_bytesPerRow,_colorSpace,_bitmapInfo);
   return self;
}

-(void)setSize:(NSSize)size {
   CGContextRelease(_context);
   [super setSize:size];
   _context=CGBitmapContextCreate(_data,_pixelsWide,_pixelsHigh,_bitsPerComponent,_bytesPerRow,_colorSpace,_bitmapInfo);
}

-(void)drawPath:(CGPathRef)path drawingMode:(CGPathDrawingMode)drawingMode blendMode:(CGBlendMode)blendMode interpolationQuality:(CGInterpolationQuality)interpolationQuality fillColor:(CGColorRef)fillColor strokeColor:(CGColorRef)strokeColor 
lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform {
   CGContextSaveGState(_context);
   CGContextConcatCTM(_context,xform);
   CGContextSetBlendMode(_context,blendMode);
   CGContextSetFillColorWithColor(_context,fillColor);
   CGContextSetStrokeColorWithColor(_context,strokeColor);
   CGContextSetLineWidth(_context,lineWidth);
   CGContextSetLineCap(_context,lineCap);
   CGContextSetLineJoin(_context,lineJoin);
   CGContextSetMiterLimit(_context,miterLimit);
   CGContextSetLineDash(_context,dashPhase,dashLengths,dashLengthsCount);
   CGContextBeginPath(_context);
   CGContextAddPath(_context,path);
   CGContextDrawPath(_context,drawingMode);
   CGContextRestoreGState(_context);
}

@end
