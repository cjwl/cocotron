/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGContext.h>

enum {
// seperable
   KGBlendModeNormal,
   KGBlendModeMultiply,
   KGBlendModeScreen,
   KGBlendModeOverlay,
   KGBlendModeDarken,
   KGBlendModeLighten,
   KGBlendModeColorDodge,
   KGBlendModeColorBurn,
   KGBlendModeHardLight,
   KGBlendModeSoftLight,
   KGBlendModeDifference,
   KGBlendModeExclusion,
// nonseperable  
   KGBlendModeHue,
   KGBlendModeSaturation,
   KGBlendModeColor,
   KGBlendModeLuminosity,
};

@class KGColor,KGColorSpace,KGShading,KGImage,KGGraphicsState,KGMutablePath,KGPath,KGPattern,KGLayer,KGPDFPage,NSMutableArray;

@interface KGContext : NSObject {
   NSMutableArray *_layerStack;
   NSMutableArray *_stateStack;
   KGMutablePath  *_path;
   BOOL            _allowsAntialiasing;
}

-initWithGraphicsState:(KGGraphicsState *)state;
-init;

-(void)setAllowsAntialiasing:(BOOL)yesOrNo;

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused;
-(void)endTransparencyLayer;

-(BOOL)pathIsEmpty;
-(NSPoint)pathCurrentPoint;
-(NSRect)pathBoundingBox;
-(BOOL)pathContainsPoint:(NSPoint)point drawingMode:(int)pathMode;

-(void)beginPath;
-(void)closePath;
-(void)moveToPoint:(float)x:(float)y;
-(void)addLineToPoint:(float)x:(float)y;
-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y;
-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y;
-(void)addLinesWithPoints:(const NSPoint *)points count:(unsigned)count;
-(void)addRect:(NSRect)rect;
-(void)addRects:(const NSRect *)rect count:(unsigned)count;
-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise;
-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius;
-(void)addEllipseInRect:(NSRect)rect;
-(void)addPath:(KGPath *)path;
-(void)replacePathWithStrokedPath;

-(void)saveGState;
-(void)restoreGState;

-(CGAffineTransform)userSpaceToDeviceSpaceTransform;
-(void)getCTM:(CGAffineTransform *)matrix;
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

-(void)concatCTM:(CGAffineTransform)matrix;
-(void)translateCTM:(float)translatex:(float)translatey;
-(void)scaleCTM:(float)scalex:(float)scaley;
-(void)rotateCTM:(float)radians;

-(void)clipToPath;
-(void)evenOddClipToPath;
-(void)clipToMask:(KGImage *)image inRect:(NSRect)rect;
-(void)clipToRect:(NSRect)rect;
-(void)clipToRects:(const NSRect *)rects count:(unsigned)count;

-(KGColor *)strokeColor;
-(KGColor *)fillColor;

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

-(void)setTextMatrix:(CGAffineTransform)matrix;
-(void)setTextPosition:(float)x:(float)y;
-(void)setCharacterSpacing:(float)spacing;
-(void)setTextDrawingMode:(int)textMode;
-(KGFont *)currentFont;
-(void)setFont:(KGFont *)font;
-(void)setFontSize:(float)size;
-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding;
-(void)setShouldSmoothFonts:(BOOL)yesOrNo;

-(void)setLineWidth:(float)width;
-(void)setLineCap:(int)lineCap;
-(void)setLineJoin:(int)lineJoin;
-(void)setMiterLimit:(float)limit;
-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count;

-(void)setRenderingIntent:(CGColorRenderingIntent)intent;
-(void)setBlendMode:(int)mode;

-(void)setFlatness:(float)flatness;
-(void)setInterpolationQuality:(CGInterpolationQuality)quality;
   
-(void)setShadowOffset:(NSSize)offset blur:(float)blur color:(KGColor *)color;
-(void)setShadowOffset:(NSSize)offset blur:(float)blur;

-(void)setShouldAntialias:(BOOL)yesOrNo;

-(void)strokeLineSegmentsWithPoints:(const NSPoint *)points count:(unsigned)count;
-(void)strokeRect:(NSRect)rect;
-(void)strokeRect:(NSRect)rect width:(float)width;
-(void)strokeEllipseInRect:(NSRect)rect;
   
-(void)fillRect:(NSRect)rect;
-(void)fillRects:(const NSRect *)rects count:(unsigned)count;
-(void)fillEllipseInRect:(NSRect)rect;

-(void)drawPath:(CGPathDrawingMode)pathMode;
-(void)strokePath;
-(void)fillPath;
-(void)evenOddFillPath;
-(void)fillAndStrokePath;
-(void)evenOddFillAndStrokePath;

-(void)clearRect:(NSRect)rect;

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const NSSize *)advances;

-(void)showText:(const char *)text length:(unsigned)length;
-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y;

-(void)drawShading:(KGShading *)shading;
-(void)drawImage:(KGImage *)image inRect:(NSRect)rect;
-(void)drawLayer:(KGLayer *)layer atPoint:(NSPoint)point;
-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect;
-(void)drawPDFPage:(KGPDFPage *)page;
   
-(void)flush;
-(void)synchronize;

-(void)beginPage:(const NSRect *)mediaBox;
-(void)endPage;

-(KGLayer *)layerWithSize:(NSSize)size unused:(NSDictionary *)unused;

// printing

-(void)beginPrintingWithDocumentName:(NSString *)documentName;
-(void)endPrinting;

-(BOOL)getImageableRect:(NSRect *)rect;

// temporary

-(void)drawContext:(KGContext *)other inRect:(CGRect)rect;

-(void)resetClip;

-(void)setWordSpacing:(float)spacing;
-(void)setTextLeading:(float)leading;

-(void)setCalibratedColorWhite:(float)white alpha:(float)alpha;
-(void)setCalibratedColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState;

@end
