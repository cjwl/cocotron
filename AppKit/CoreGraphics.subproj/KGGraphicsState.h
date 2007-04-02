/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGGeometry.h>

@class KGRenderingContext,KGImage,KGColorSpace,KGColor,KGPattern,KGShading,KGMutablePath,KGPath;

@interface KGGraphicsState : NSObject <NSCopying> {
@public
   KGRenderingContext *_renderingContext;
   CGAffineTransform   _ctm;
   CGAffineTransform   _textTransform;
   
   id                  _deviceState;
   NSRect              _clipRect;
   KGColor            *_strokeColor;
   KGColor            *_fillColor;
   NSSize              _patternPhase;   
   float               _characterSpacing;
   int                 _textDrawingMode;
   BOOL                _shouldSmoothFonts;
   float               _lineWidth;
   int                 _lineCap;
   int                 _lineJoin;
   float               _miterLimit;
   float               _dashPhase;
   float               _dashLengthsCount;
   float              *_dashLengths;
   int                 _renderingIntent;
   int                 _blendMode;
   float               _flatness;
   int                 _interpolationQuality;
   NSSize              _shadowOffset;
   float               _shadowBlur;
   KGColor            *_shadowColor;
   BOOL                _shouldAntialias;
   
   float               _wordSpacing;
   float               _textLeading;
}

-initWithRenderingContext:(KGRenderingContext *)context transform:(CGAffineTransform)deviceTransform userSpaceSize:(NSSize)userSpaceSize;

-(KGRenderingContext *)renderingContext;

-(void)save;
-(void)restore;

-(CGAffineTransform)userSpaceToDeviceSpaceTransform;
-(CGAffineTransform)ctm;
-(NSRect)clipBoundingBox;
-(CGAffineTransform)textMatrix;
-(int)interpolationQuality;
-(NSPoint)textPosition;
-(NSPoint)convertPointToDeviceSpace:(NSPoint)point;
-(NSPoint)convertPointToUserSpace:(NSPoint)point;
-(NSSize)convertSizeToDeviceSpace:(NSSize)size;
-(NSSize)convertSizeToUserSpace:(NSSize)size;
-(NSRect)convertRectToDeviceSpace:(NSRect)rect;
-(NSRect)convertRectToUserSpace:(NSRect)rect;

-(void)concatCTM:(CGAffineTransform)transform;
-(void)translateCTM:(float)tx:(float)ty;
-(void)scaleCTM:(float)scalex:(float)scaley;
-(void)rotateCTM:(float)radians;

-(void)clipToPath:(KGPath *)path;
-(void)evenOddClipToPath:(KGPath *)path;
-(void)clipToMask:(KGImage *)image inRect:(NSRect)rect;
-(void)clipToRect:(NSRect)clipRect;
-(void)clipToRects:(const NSRect *)rects count:(unsigned)count;

-(void)setStrokeColorSpace:(KGColorSpace *)colorSpace;
-(void)setFillColorSpace:(KGColorSpace *)colorSpace;

-(void)setStrokeColorWithComponents:(const float *)components;
-(void)setStrokeColor:(KGColor *)color;
-(void)setGrayStrokeColor:(float)gray:(float)alpha;
-(void)setRGBStrokeColor:(float)r:(float)g:(float)b:(float)alpha;
-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k:(float)alpha;

-(void)setFillColorWithComponents:(const float *)components;
-(void)setFillColor:(KGColor *)color;
-(void)setGrayFillColor:(float)gray:(float)alpha;
-(void)setRGBFillColor:(float)r:(float)g:(float)b:(float)alpha;
-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k:(float)alpha;

-(void)setStrokeAndFillAlpha:(float)alpha;

-(void)setStrokeAlpha:(float)alpha;
-(void)setGrayStrokeColor:(float)gray;
-(void)setRGBStrokeColor:(float)r:(float)g:(float)b;
-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k;

-(void)setFillAlpha:(float)alpha;
-(void)setGrayFillColor:(float)gray;
-(void)setRGBFillColor:(float)r:(float)g:(float)b;
-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k;

-(void)setPatternPhase:(NSSize)phase;
-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components;
-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components;

-(void)setTextMatrix:(CGAffineTransform)transform;
-(void)setTextPosition:(float)x:(float)y;
-(void)setCharacterSpacing:(float)spacing;
-(void)setTextDrawingMode:(int)textMode;
-(void)setFont:(KGFont *)font;
-(void)setFontSize:(float)size;
-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding;
-(void)setShouldSmoothFonts:(BOOL)yesOrNo;

-(void)setLineWidth:(float)width;
-(void)setLineCap:(int)lineCap;
-(void)setLineJoin:(int)lineJoin;
-(void)setMiterLimit:(float)limit;
-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count;

-(void)setRenderingIntent:(int)intent;
-(void)setBlendMode:(int)mode;

-(void)setFlatness:(float)flatness;
-(void)setInterpolationQuality:(int)quality;

-(void)setShadowOffset:(NSSize)offset blur:(float)blur color:(KGColor *)color;
-(void)setShadowOffset:(NSSize)offset blur:(float)blur;

-(void)setShouldAntialias:(BOOL)flag;

-(void)strokeLineSegmentsWithPoints:(NSPoint *)points count:(unsigned)count;
-(void)strokeRect:(NSRect)rect;
-(void)strokeRect:(NSRect)rect width:(float)width;
-(void)strokeEllipseInRect:(NSRect)rect;

-(void)fillRects:(const NSRect *)rects count:(unsigned)count;
-(void)fillEllipseInRect:(NSRect)rect;

-(void)drawPath:(KGPath *)path mode:(int)mode;

-(void)clearRect:(NSRect)rect;

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)numberOfGlyphs atPoint:(float)x:(float)y;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const NSSize *)advances;

-(void)showText:(const char *)text length:(unsigned)length;
-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y;

-(void)drawShading:(KGShading *)shading;
-(void)drawImage:(KGImage *)image inRect:(NSRect)rect;

// temporary

-(void)setWordSpacing:(float)spacing;
-(void)setTextLeading:(float)leading;

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point;

@end

void CGGraphicsSourceOver_rgba32_onto_bgrx32(unsigned char *sourceRGBA,unsigned char *resultRGBX,int width,int height,float fraction);
