/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRender.h"

@implementation KGRender

-init {
  _pixelsWide=386;
  _pixelsHigh=386;
  _bitsPerComponent=8;
  _bitsPerPixel=32;
  _bytesPerRow=(_pixelsWide*_bitsPerPixel)/8;
  _colorSpace=CGColorSpaceCreateDeviceRGB();
  _bitmapInfo=kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Little;
  _data=NSZoneMalloc([self zone],_bytesPerRow*_pixelsHigh);
  return self;
}

-(void)setSize:(NSSize)size {
   _pixelsWide=size.width;
   _pixelsHigh=size.height;
   _bytesPerRow=(_pixelsWide*_bitsPerPixel)/8;
   _data=NSZoneRealloc([self zone],_data,_bytesPerRow*_pixelsHigh);
}

-(void)drawImageInContext:(CGContextRef)context {
   CGDataProviderRef provider=CGDataProviderCreateWithData(NULL,_data,_pixelsWide*_pixelsHigh*4,NULL);
   CGImageRef        image=CGImageCreate(_pixelsWide,_pixelsHigh,_bitsPerComponent,_bitsPerPixel,_bytesPerRow,_colorSpace,
     kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Little,provider,NULL,NO,kCGRenderingIntentDefault);

   CGContextSaveGState(context);
   CGContextSetBlendMode(context,kCGBlendModeNormal);
   CGContextDrawImage(context,CGRectMake(0,0,_pixelsWide,_pixelsHigh),image);
   CGContextRestoreGState(context);
  
   CGDataProviderRelease(provider);
   CGImageRelease(image);
}

-(void)clear {
   int i;
   
   for(i=0;i<_pixelsHigh*_bytesPerRow;i++)
    ((char *)_data)[i]=0;
}

-(void)setShadowColor:(CGColorRef)value {
   value=CGColorRetain(value);
   CGColorRelease(_shadowColor);
   _shadowColor=value;
}

-(void)setShadowOffset:(CGSize)value {
   _shadowOffset=value;
}

-(void)setShadowBlur:(float)value {
   _shadowBlur=value;
}

-(void)drawPath:(CGPathRef)path drawingMode:(CGPathDrawingMode)drawingMode blendMode:(CGBlendMode)blendMode interpolationQuality:(CGInterpolationQuality)interpolationQuality fillColor:(CGColorRef)fillColor strokeColor:(CGColorRef)strokeColor lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform antialias:(BOOL)antialias {
   [self doesNotRecognizeSelector:_cmd];
}

-(void)drawBitmapImageRep:(NSBitmapImageRep *)imageRep antialias:(BOOL)antialias interpolationQuality:(CGInterpolationQuality)interpolationQuality blendMode:(CGBlendMode)blendMode fillColor:(CGColorRef)fillColor transform:(CGAffineTransform)xform {
   [self doesNotRecognizeSelector:_cmd];
}


@end
