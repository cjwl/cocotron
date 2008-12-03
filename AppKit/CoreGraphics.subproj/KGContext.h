/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGColor,KGColorSpace,KGShading,KGImage,KGGraphicsState,KGMutablePath,KGPath,KGPattern,KGLayer,KGPDFPage,NSMutableArray,CGWindow,KGSurface,NSDictionary,NSData;

@interface KGContext : NSObject {
   CGAffineTransform _userToDeviceTransform;
   NSMutableArray   *_layerStack;
   NSMutableArray   *_stateStack;
   KGMutablePath    *_path;
   BOOL              _allowsAntialiasing;
}

+(KGContext *)createContextWithSize:(CGSize)size window:(CGWindow *)window;
+(KGContext *)createBackingContextWithSize:(CGSize)size context:(KGContext *)context deviceDictionary:(NSDictionary *)deviceDictionary;
+(KGContext *)createWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo;

+(BOOL)canInitWithWindow:(CGWindow *)window;
+(BOOL)canInitBackingWithContext:(KGContext *)context deviceDictionary:(NSDictionary *)deviceDictionary;
+(BOOL)canInitBitmap;

-initWithSize:(CGSize)size window:(CGWindow *)window;
-initWithSize:(CGSize)size context:(KGContext *)context;

-initWithGraphicsState:(KGGraphicsState *)state;
-init;

-(KGSurface *)surface;
-(KGSurface *)createSurfaceWithWidth:(size_t)width height:(size_t)height;

-(void)setAllowsAntialiasing:(BOOL)yesOrNo;

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused;
-(void)endTransparencyLayer;

-(BOOL)pathIsEmpty;
-(CGPoint)pathCurrentPoint;
-(CGRect)pathBoundingBox;
-(BOOL)pathContainsPoint:(CGPoint)point drawingMode:(int)pathMode;

-(void)beginPath;
-(void)closePath;
-(void)moveToPoint:(float)x:(float)y;
-(void)addLineToPoint:(float)x:(float)y;
-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y;
-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y;
-(void)addLinesWithPoints:(const CGPoint *)points count:(unsigned)count;
-(void)addRect:(CGRect)rect;
-(void)addRects:(const CGRect *)rect count:(unsigned)count;
-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise;
-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius;
-(void)addEllipseInRect:(CGRect)rect;
-(void)addPath:(KGPath *)path;
-(void)replacePathWithStrokedPath;

-(KGGraphicsState *)currentState;
-(void)saveGState;
-(void)restoreGState;

-(CGAffineTransform)userSpaceToDeviceSpaceTransform;
-(CGAffineTransform)ctm;
-(CGRect)clipBoundingBox;
-(CGAffineTransform)textMatrix;
-(int)interpolationQuality;
-(CGPoint)textPosition;
-(CGPoint)convertPointToDeviceSpace:(CGPoint)point;
-(CGPoint)convertPointToUserSpace:(CGPoint)point;
-(CGSize)convertSizeToDeviceSpace:(CGSize)size;
-(CGSize)convertSizeToUserSpace:(CGSize)size;
-(CGRect)convertRectToDeviceSpace:(CGRect)rect;
-(CGRect)convertRectToUserSpace:(CGRect)rect;

-(void)setCTM:(CGAffineTransform)matrix;
-(void)concatCTM:(CGAffineTransform)matrix;
-(void)translateCTM:(float)translatex:(float)translatey;
-(void)scaleCTM:(float)scalex:(float)scaley;
-(void)rotateCTM:(float)radians;

-(void)deviceClipToNonZeroPath:(KGPath *)path;
-(void)deviceClipToEvenOddPath:(KGPath *)path;

-(void)clipToPath;
-(void)evenOddClipToPath;
-(void)clipToMask:(KGImage *)image inRect:(CGRect)rect;
-(void)clipToRect:(CGRect)rect;
-(void)clipToRects:(const CGRect *)rects count:(unsigned)count;

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

-(void)setPatternPhase:(CGSize)phase;
-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components;
-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components;

-(void)setTextMatrix:(CGAffineTransform)matrix;
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

-(void)setRenderingIntent:(CGColorRenderingIntent)intent;
-(void)setBlendMode:(int)mode;

-(void)setFlatness:(float)flatness;
-(void)setInterpolationQuality:(CGInterpolationQuality)quality;
   
-(void)setShadowOffset:(CGSize)offset blur:(float)blur color:(KGColor *)color;
-(void)setShadowOffset:(CGSize)offset blur:(float)blur;

-(void)setShouldAntialias:(BOOL)yesOrNo;

-(void)strokeLineSegmentsWithPoints:(const CGPoint *)points count:(unsigned)count;
-(void)strokeRect:(CGRect)rect;
-(void)strokeRect:(CGRect)rect width:(float)width;
-(void)strokeEllipseInRect:(CGRect)rect;
   
-(void)fillRect:(CGRect)rect;
-(void)fillRects:(const CGRect *)rects count:(unsigned)count;
-(void)fillEllipseInRect:(CGRect)rect;

-(void)drawPath:(CGPathDrawingMode)pathMode;
-(void)strokePath;
-(void)fillPath;
-(void)evenOddFillPath;
-(void)fillAndStrokePath;
-(void)evenOddFillAndStrokePath;

-(void)clearRect:(CGRect)rect;

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y;
-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const CGSize *)advances;

-(void)showText:(const char *)text length:(unsigned)length;
-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y;

-(void)drawShading:(KGShading *)shading;
-(void)drawImage:(KGImage *)image inRect:(CGRect)rect;
-(void)drawLayer:(KGLayer *)layer atPoint:(CGPoint)point;
-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect;
-(void)drawPDFPage:(KGPDFPage *)page;
   
-(void)flush;
-(void)synchronize;

-(void)beginPage:(const CGRect *)mediaBox;
-(void)endPage;

-(KGLayer *)layerWithSize:(CGSize)size unused:(NSDictionary *)unused;

// printing

-(void)beginPrintingWithDocumentName:(NSString *)documentName;
-(void)endPrinting;

-(BOOL)getImageableRect:(CGRect *)rect;

// bitmap context

-(NSData *)pixelData;
-(void *)pixelBytes;
-(size_t)width;
-(size_t)height;
-(size_t)bitsPerComponent;
-(size_t)bytesPerRow;
-(KGColorSpace *)colorSpace;
-(CGBitmapInfo)bitmapInfo;

-(size_t)bitsPerPixel;
-(CGImageAlphaInfo)alphaInfo;
-(KGImage *)createImage;

// temporary

-(void)drawBackingContext:(KGContext *)other size:(CGSize)size;

-(void)resetClip;

-(void)setAntialiasingQuality:(int)value;
-(void)setWordSpacing:(float)spacing;
-(void)setTextLeading:(float)leading;

-(void)copyBitsInRect:(CGRect)rect toPoint:(CGPoint)point gState:(int)gState;

-(NSData *)captureBitmapInRect:(CGRect)rect;

-(void)deviceClipReset;
-(void)deviceClipToNonZeroPath:(KGPath *)path;
-(void)deviceClipToEvenOddPath:(KGPath *)path;
-(void)deviceClipToMask:(KGImage *)mask inRect:(CGRect)rect;

@end
