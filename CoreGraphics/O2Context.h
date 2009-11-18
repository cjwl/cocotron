/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import "O2Geometry.h"

@class O2Context,O2Color,O2Shading,O2Image,O2GState,O2MutablePath,O2Path,O2Pattern,O2Layer,O2PDFPage,NSMutableArray,CGWindow,O2Surface,NSDictionary,NSData,O2Font;

typedef O2Context *O2ContextRef;

typedef enum {
   kO2EncodingFontSpecific,
   kO2EncodingMacRoman,
} O2TextEncoding;

typedef enum {
   kO2LineCapButt,
   kO2LineCapRound,
   kO2LineCapSquare,
} O2LineCap;

typedef enum {
   kO2LineJoinMiter,
   kO2LineJoinRound,
   kO2LineJoinBevel,
} O2LineJoin;

typedef enum {
   kO2PathFill,
   kO2PathEOFill,
   kO2PathStroke,
   kO2PathFillStroke,
   kO2PathEOFillStroke
} O2PathDrawingMode;

typedef enum {
   kO2InterpolationDefault,
   kO2InterpolationNone,
   kO2InterpolationLow,
   kO2InterpolationHigh,
} O2InterpolationQuality;

typedef enum {
// seperable
   kO2BlendModeNormal,
   kO2BlendModeMultiply,
   kO2BlendModeScreen,
   kO2BlendModeOverlay,
   kO2BlendModeDarken,
   kO2BlendModeLighten,
   kO2BlendModeColorDodge,
   kO2BlendModeColorBurn,
   kO2BlendModeHardLight,
   kO2BlendModeSoftLight,
   kO2BlendModeDifference,
   kO2BlendModeExclusion,
// nonseperable  
   kO2BlendModeHue,
   kO2BlendModeSaturation,
   kO2BlendModeColor,
   kO2BlendModeLuminosity,
// Porter-Duff
   kO2BlendModeClear,
   kO2BlendModeCopy,
   kO2BlendModeSourceIn,
   kO2BlendModeSourceOut,
   kO2BlendModeSourceAtop,
   kO2BlendModeDestinationOver,
   kO2BlendModeDestinationIn,
   kO2BlendModeDestinationOut,
   kO2BlendModeDestinationAtop,
   kO2BlendModeXOR,
   kO2BlendModePlusDarker,
   kO2BlendModePlusLighter,
} O2BlendMode;

typedef int O2TextDrawingMode;

#import "O2Font.h"
#import "O2Layer.h"
#import "O2Color.h"
#import "O2ColorSpace.h"
#import "O2Image.h"
#import "O2Path.h"
#import "O2Pattern.h"
#import "O2Shading.h"
#import "O2PDFPage.h"

@interface O2Context : NSObject {
   O2AffineTransform _userToDeviceTransform;
   NSMutableArray   *_layerStack;
   NSMutableArray   *_stateStack;
   O2MutablePath    *_path;
   BOOL              _allowsAntialiasing;
}

+(O2Context *)createContextWithSize:(O2Size)size window:(CGWindow *)window;
+(O2Context *)createBackingContextWithSize:(O2Size)size context:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary;

+(BOOL)canInitWithWindow:(CGWindow *)window;
+(BOOL)canInitBackingWithContext:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary;
+(BOOL)canInitBitmap;

-initWithSize:(O2Size)size window:(CGWindow *)window;
-initWithSize:(O2Size)size context:(O2Context *)context;

-initWithGraphicsState:(O2GState *)state;
-init;

-(O2Surface *)surface;
-(O2Surface *)createSurfaceWithWidth:(size_t)width height:(size_t)height;

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused;
-(void)endTransparencyLayer;

-(O2Color *)strokeColor;
-(O2Color *)fillColor;
   
-(void)setStrokeAlpha:(O2Float)alpha;
-(void)setGrayStrokeColor:(O2Float)gray;
-(void)setRGBStrokeColor:(O2Float)r:(O2Float)g:(O2Float)b;
-(void)setCMYKStrokeColor:(O2Float)c:(O2Float)m:(O2Float)y:(O2Float)k;

-(void)setFillAlpha:(O2Float)alpha;
-(void)setGrayFillColor:(O2Float)gray;
-(void)setRGBFillColor:(O2Float)r:(O2Float)g:(O2Float)b;
-(void)setCMYKFillColor:(O2Float)c:(O2Float)m:(O2Float)y:(O2Float)k;

-(void)drawPath:(O2PathDrawingMode)pathMode;

-(void)showGlyphs:(const O2Glyph *)glyphs count:(unsigned)count;
-(void)showText:(const char *)text length:(unsigned)length;

-(void)drawShading:(O2Shading *)shading;
-(void)drawImage:(O2Image *)image inRect:(O2Rect)rect;
-(void)drawLayer:(O2LayerRef)layer inRect:(O2Rect)rect;
   
-(void)flush;
-(void)synchronize;

-(void)beginPage:(const O2Rect *)mediaBox;
-(void)endPage;
-(void)close;

-(O2Size)size;
-(O2ContextRef)createCompatibleContextWithSize:(O2Size)size unused:(NSDictionary *)unused;

-(BOOL)getImageableRect:(O2Rect *)rect;

// temporary

-(void)drawBackingContext:(O2Context *)other size:(O2Size)size;

-(void)setAntialiasingQuality:(int)value;
-(void)setWordSpacing:(O2Float)spacing;
-(void)setTextLeading:(O2Float)leading;

-(void)copyBitsInRect:(O2Rect)rect toPoint:(O2Point)point gState:(int)gState;

-(NSData *)captureBitmapInRect:(O2Rect)rect;

-(void)deviceClipReset;
-(void)deviceClipToNonZeroPath:(O2Path *)path;
-(void)deviceClipToEvenOddPath:(O2Path *)path;
-(void)deviceClipToMask:(O2Image *)mask inRect:(O2Rect)rect;


O2ContextRef O2ContextRetain(O2ContextRef self);
void         O2ContextRelease(O2ContextRef self);

// context state
void O2ContextSetAllowsAntialiasing(O2ContextRef self,BOOL yesOrNo);

// layers
void O2ContextBeginTransparencyLayer(O2ContextRef self,NSDictionary *unused);
void O2ContextEndTransparencyLayer(O2ContextRef self);

// path
BOOL    O2ContextIsPathEmpty(O2ContextRef self);
O2Point O2ContextGetPathCurrentPoint(O2ContextRef self);
O2Rect  O2ContextGetPathBoundingBox(O2ContextRef self);
BOOL    O2ContextPathContainsPoint(O2ContextRef self,O2Point point,O2PathDrawingMode pathMode);

void O2ContextBeginPath(O2ContextRef self);
void O2ContextClosePath(O2ContextRef self);
void O2ContextMoveToPoint(O2ContextRef self,O2Float x,O2Float y);
void O2ContextAddLineToPoint(O2ContextRef self,O2Float x,O2Float y);
void O2ContextAddCurveToPoint(O2ContextRef self,O2Float cx1,O2Float cy1,O2Float cx2,O2Float cy2,O2Float x,O2Float y);
void O2ContextAddQuadCurveToPoint(O2ContextRef self,O2Float cx1,O2Float cy1,O2Float x,O2Float y);

void O2ContextAddLines(O2ContextRef self,const O2Point *points,unsigned count);
void O2ContextAddRect(O2ContextRef self,O2Rect rect);
void O2ContextAddRects(O2ContextRef self,const O2Rect *rects,unsigned count);

void O2ContextAddArc(O2ContextRef self,O2Float x,O2Float y,O2Float radius,O2Float startRadian,O2Float endRadian,BOOL clockwise);
void O2ContextAddArcToPoint(O2ContextRef self,O2Float x1,O2Float y1,O2Float x2,O2Float y2,O2Float radius);
void O2ContextAddEllipseInRect(O2ContextRef self,O2Rect rect);

void O2ContextAddPath(O2ContextRef self,O2PathRef path);

void O2ContextReplacePathWithStrokedPath(O2ContextRef self);

// gstate

void O2ContextSaveGState(O2ContextRef self);
void O2ContextRestoreGState(O2ContextRef self);

O2AffineTransform      O2ContextGetUserSpaceToDeviceSpaceTransform(O2ContextRef self);
O2AffineTransform      O2ContextGetCTM(O2ContextRef self);
O2Rect                 O2ContextGetClipBoundingBox(O2ContextRef self);
O2AffineTransform      O2ContextGetTextMatrix(O2ContextRef self);
O2InterpolationQuality O2ContextGetInterpolationQuality(O2ContextRef self);
O2Point                O2ContextGetTextPosition(O2ContextRef self);

O2Point O2ContextConvertPointToDeviceSpace(O2ContextRef self,O2Point point);
O2Point O2ContextConvertPointToUserSpace(O2ContextRef self,O2Point point);
O2Size  O2ContextConvertSizeToDeviceSpace(O2ContextRef self,O2Size size);
O2Size  O2ContextConvertSizeToUserSpace(O2ContextRef self,O2Size size);
O2Rect  O2ContextConvertRectToDeviceSpace(O2ContextRef self,O2Rect rect);
O2Rect  O2ContextConvertRectToUserSpace(O2ContextRef self,O2Rect rect);

void O2ContextConcatCTM(O2ContextRef self,O2AffineTransform matrix);
void O2ContextTranslateCTM(O2ContextRef self,O2Float translatex,O2Float translatey);
void O2ContextScaleCTM(O2ContextRef self,O2Float scalex,O2Float scaley);
void O2ContextRotateCTM(O2ContextRef self,O2Float radians);

void O2ContextClip(O2ContextRef self);
void O2ContextEOClip(O2ContextRef self);
void O2ContextClipToMask(O2ContextRef self,O2Rect rect,O2ImageRef image);
void O2ContextClipToRect(O2ContextRef self,O2Rect rect);
void O2ContextClipToRects(O2ContextRef self,const O2Rect *rects,unsigned count);

void O2ContextSetStrokeColorSpace(O2ContextRef self,O2ColorSpaceRef colorSpace);
void O2ContextSetFillColorSpace(O2ContextRef self,O2ColorSpaceRef colorSpace);

void O2ContextSetStrokeColor(O2ContextRef self,const O2Float *components);
void O2ContextSetStrokeColorWithColor(O2ContextRef self,O2ColorRef color);
void O2ContextSetGrayStrokeColor(O2ContextRef self,O2Float gray,O2Float alpha);
void O2ContextSetRGBStrokeColor(O2ContextRef self,O2Float r,O2Float g,O2Float b,O2Float alpha);
void O2ContextSetCMYKStrokeColor(O2ContextRef self,O2Float c,O2Float m,O2Float y,O2Float k,O2Float alpha);
void O2ContextSetCalibratedRGBStrokeColor(O2ContextRef self,O2Float red,O2Float green,O2Float blue,O2Float alpha);
void O2ContextSetCalibratedGrayStrokeColor(O2ContextRef self,O2Float gray,O2Float alpha);

void O2ContextSetFillColor(O2ContextRef self,const O2Float *components);
void O2ContextSetFillColorWithColor(O2ContextRef self,O2ColorRef color);
void O2ContextSetGrayFillColor(O2ContextRef self,O2Float gray,O2Float alpha);
void O2ContextSetRGBFillColor(O2ContextRef self,O2Float r,O2Float g,O2Float b,O2Float alpha);
void O2ContextSetCMYKFillColor(O2ContextRef self,O2Float c,O2Float m,O2Float y,O2Float k,O2Float alpha);
void O2ContextSetCalibratedGrayFillColor(O2ContextRef self,O2Float gray,O2Float alpha);
void O2ContextSetCalibratedRGBFillColor(O2ContextRef self,O2Float red,O2Float green,O2Float blue,O2Float alpha);

void O2ContextSetAlpha(O2ContextRef self,O2Float alpha);

void O2ContextSetPatternPhase(O2ContextRef self,O2Size phase);
void O2ContextSetStrokePattern(O2ContextRef self,O2PatternRef pattern,const O2Float *components);
void O2ContextSetFillPattern(O2ContextRef self,O2PatternRef pattern,const O2Float *components);

void O2ContextSetTextMatrix(O2ContextRef self,O2AffineTransform matrix);

void O2ContextSetTextPosition(O2ContextRef self,O2Float x,O2Float y);
void O2ContextSetCharacterSpacing(O2ContextRef self,O2Float spacing);
void O2ContextSetTextDrawingMode(O2ContextRef self,O2TextDrawingMode textMode);

void O2ContextSetFont(O2ContextRef self,O2FontRef font);
void O2ContextSetFontSize(O2ContextRef self,O2Float size);
void O2ContextSelectFont(O2ContextRef self,const char *name,O2Float size,O2TextEncoding encoding);
void O2ContextSetShouldSmoothFonts(O2ContextRef self,BOOL yesOrNo);

void O2ContextSetLineWidth(O2ContextRef self,O2Float width);
void O2ContextSetLineCap(O2ContextRef self,O2LineCap lineCap);
void O2ContextSetLineJoin(O2ContextRef self,O2LineJoin lineJoin);
void O2ContextSetMiterLimit(O2ContextRef self,O2Float miterLimit);
void O2ContextSetLineDash(O2ContextRef self,O2Float phase,const O2Float *lengths,unsigned count);

void O2ContextSetRenderingIntent(O2ContextRef self,O2ColorRenderingIntent renderingIntent);
void O2ContextSetBlendMode(O2ContextRef self,O2BlendMode blendMode);

void O2ContextSetFlatness(O2ContextRef self,O2Float flatness);

void O2ContextSetInterpolationQuality(O2ContextRef self,O2InterpolationQuality quality);

void O2ContextSetShadowWithColor(O2ContextRef self,O2Size offset,O2Float blur,O2ColorRef color);
void O2ContextSetShadow(O2ContextRef self,O2Size offset,O2Float blur);

void O2ContextSetShouldAntialias(O2ContextRef self,BOOL yesOrNo);

// drawing
void O2ContextStrokeLineSegments(O2ContextRef self,const O2Point *points,unsigned count);

void O2ContextStrokeRect(O2ContextRef self,O2Rect rect);
void O2ContextStrokeRectWithWidth(O2ContextRef self,O2Rect rect,O2Float width);
void O2ContextStrokeEllipseInRect(O2ContextRef self,O2Rect rect);

void O2ContextFillRect(O2ContextRef self,O2Rect rect);
void O2ContextFillRects(O2ContextRef self,const O2Rect *rects,unsigned count);
void O2ContextFillEllipseInRect(O2ContextRef self,O2Rect rect);

void O2ContextDrawPath(O2ContextRef self,O2PathDrawingMode pathMode);
void O2ContextStrokePath(O2ContextRef self);
void O2ContextFillPath(O2ContextRef self);
void O2ContextEOFillPath(O2ContextRef self);

void O2ContextClearRect(O2ContextRef self,O2Rect rect);

void O2ContextShowGlyphs(O2ContextRef self,const O2Glyph *glyphs,unsigned count);
void O2ContextShowGlyphsAtPoint(O2ContextRef self,O2Float x,O2Float y,const O2Glyph *glyphs,unsigned count);
void O2ContextShowGlyphsWithAdvances(O2ContextRef self,const O2Glyph *glyphs,const O2Size *advances,unsigned count);

void O2ContextShowText(O2ContextRef self,const char *text,unsigned count);
void O2ContextShowTextAtPoint(O2ContextRef self,O2Float x,O2Float y,const char *text,unsigned count);

void O2ContextDrawShading(O2ContextRef self,O2ShadingRef shading);
void O2ContextDrawImage(O2ContextRef self,O2Rect rect,O2ImageRef image);
void O2ContextDrawLayerAtPoint(O2ContextRef self,O2Point point,O2LayerRef layer);
void O2ContextDrawLayerInRect(O2ContextRef self,O2Rect rect,O2LayerRef layer);
void O2ContextDrawPDFPage(O2ContextRef self,O2PDFPageRef page);

void O2ContextFlush(O2ContextRef self);
void O2ContextSynchronize(O2ContextRef self);

// pagination

void O2ContextBeginPage(O2ContextRef self,const O2Rect *mediaBox);
void O2ContextEndPage(O2ContextRef self);

// **PRIVATE** These are private in Apple's implementation as well as ours.

void O2ContextSetCTM(O2ContextRef self,O2AffineTransform matrix);
void O2ContextResetClip(O2ContextRef self);

// Temporary hacks

NSData *O2ContextCaptureBitmap(O2ContextRef self,O2Rect rect);
void O2ContextCopyBits(O2ContextRef self,O2Rect rect,O2Point point,int gState);

@end
