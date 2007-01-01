/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGGeometry.h>

@class CGRenderingContext;

@interface CGGraphicsState : NSObject <NSCopying> {
   CGRenderingContext *_renderingContext;
   CGAffineTransform   _deviceTransform;
   NSRect              _clipRect;
}

-initWithRenderingContext:(CGRenderingContext *)context transform:(CGAffineTransform)deviceTransform clipRect:(NSRect)clipRect;

// primitives
-(void)moveToPoint:(float)x:(float)y;
-(void)addLineToPoint:(float)x:(float)y;
// --

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y;

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise;


-(void)save;
-(void)restore;
-(void)abort;

-(void)clipToRect:(NSRect)clipRect;
-(void)clipToRects:(const NSRect *)rects count:(unsigned)count;

-(void)scaleCTM:(float)scalex:(float)scaley;
-(void)translateCTM:(float)tx:(float)ty;
-(void)concatCTM:(CGAffineTransform)transform;

-(void)beginPath;
-(void)closePath;
-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius;
-(void)fillPath;
-(void)strokePath;

-(void)setDeviceColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize;
-(void)setTextMatrix:(CGAffineTransform)transform;
-(CGAffineTransform)textMatrix;
-(void)moveto:(float)x:(float)y
        ashow:(const char *)cString:(int)length:(float)dx:(float)dy;

-(void)showGlyphs:(const CGGlyph *)glyphs:(unsigned)numberOfGlyphs atPoint:(NSPoint)point;
-(void)showGlyphs:(const CGGlyph *)glyphs advances:(const CGSize *)advances count:(unsigned)count;

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point;
-(void)fillRects:(const CGRect *)rects count:(unsigned)count;
-(void)strokeRect:(CGRect)strokeRect width:(float)width;

-(float)lineWidth;
-(void)setLineWidth:(float)width;

-(void)drawRGBAImageInRect:(NSRect)rect width:(int)width height:(int)height data:(unsigned int *)data fraction:(float)fraction;

-(void)bitCopyToPoint:(NSPoint)dstOrigin renderingContext:(CGRenderingContext *)renderingContext fromPoint:(NSPoint)srcOrigin size:(NSSize)size;

@end

void CGGraphicsSourceOver_rgba32_onto_bgrx32(unsigned char *sourceRGBA,unsigned char *resultRGBX,int width,int height,float fraction);
