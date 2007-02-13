/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class KGColorSpace,KGShading,KGImage;

@interface KGContext : NSObject

@end

@interface KGContext(platform)

-(void)saveGState;
-(void)restoreGState;

-(void)beginPath;
-(void)closePath;
-(void)strokePath;
-(void)fillPath;
-(void)eoFillPath;
-(void)fillAndStrokePath;
-(void)eoFillAndStrokePath;
-(void)clipToPath;
-(void)eoClipToPath;

-(void)addCurveToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)x3:(float)y3;
-(void)addQuadCurveToPoint:(float)x2:(float)y2:(float)x3:(float)y3;
-(void)addLineToPoint:(float)x:(float)y;
-(void)moveToPoint:(float)x:(float)y;
-(void)addRect:(float)x:(float)y:(float)width:(float)height;

-(void)concatCTM:(float)a:(float)b:(float)c:(float)d:(float)tx:(float)ty;

-(void)setRenderingIntent:(int)intent;

-(void)setStrokeColorSpace:(KGColorSpace *)colorSpace;
-(void)setFillColorSpace:(KGColorSpace *)colorSpace;

-(void)setStrokeAlpha:(float)alpha;
-(void)setFillAlpha:(float)alpha;

// use gstate alpha
-(void)setGrayFillColor:(float)gray;
-(void)setGrayStrokeColor:(float)gray;

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k;
-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k;

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b;
-(void)setRGBFillColor:(float)r:(float)g:(float)b;

-(void)setLineWidth:(float)width;
-(void)setFlatness:(float)flatness;
-(void)setLineDashPhase:(float)phase lengths:(float *)lengths count:(unsigned)count;
-(void)setMiterLimit:(float)limit;
-(void)setLineJoin:(int)lineJoin;
-(void)setLineCap:(int)lineCap;

-(void)setCharacterSpacing:(float)spacing;
-(void)setWordSpacing:(float)spacing;
-(void)setTextPosition:(float)x:(float)y;
-(void)setTextLeading:(float)x:(float)y;
-(void)setTextMatrixIdentity;
-(void)setTextMatrix:(float)a:(float)b:(float)c:(float)d:(float)tx:(float)ty;
-(void)selectFont:(const char *)baseFont scale:(float)scale encoding:(int)encoding;
-(void)showText:(const char *)bytes length:(unsigned)length;

-(void)drawImage:(KGImage *)image inRect:(float)x:(float)y:(float)width:(float)height;
-(void)drawShading:(KGShading *)shading;

@end
