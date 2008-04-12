//
//  KGRender.h
//  SWRender
//
//  Created by Christopher Lloyd on 3/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface KGRender : NSObject {
   int               _pixelsWide;
   int               _pixelsHigh;
   int               _bitsPerComponent;
   int               _bitsPerPixel;
   int               _bytesPerRow;
   NSString         *_colorSpaceName;
   CGColorSpaceRef   _colorSpace;
   CGBitmapInfo      _bitmapInfo;
   void             *_data;
   
   CGImageRef        _imageRef;
}

-(CGImageRef)imageRef;
-(CGImageRef)imageRefOfDifferences:(KGRender *)other;

-(void)setSize:(NSSize)size;

-(void)clear;

-(void)drawPath:(CGPathRef)path drawingMode:(CGPathDrawingMode)drawingMode blendMode:(CGBlendMode)blendMode interpolationQuality:(CGInterpolationQuality)interpolationQuality fillColor:(CGColorRef)fillColor strokeColor:(CGColorRef)strokeColor lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform antialias:(BOOL)antialias;

-(void)drawBitmapImageRep:(NSBitmapImageRep *)imageRep antialias:(BOOL)antialias interpolationQuality:(CGInterpolationQuality)interpolationQuality blendMode:(CGBlendMode)blendMode fillColor:(CGColorRef)fillColor transform:(CGAffineTransform)xform;

@end
