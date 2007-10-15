/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <AppKit/AppKitExport.h>
#import <AppKit/CGGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGImage.h>
#import <AppKit/CGColor.h>
#import <AppKit/CGPath.h>
#import <AppKit/CGPattern.h>
#import <AppKit/CGShading.h>
#import <AppKit/CGPDFPage.h>
#import <AppKit/CGLayer.h>

@class NSDictionary;

typedef enum {
   kCGEncodingFontSpecific
} CGTextEncoding;

typedef int CGLineCap;
typedef int CGLineJoin;

typedef enum {
   kCGPathFill,
   kCGPathEOFill,
   kCGPathStroke,
   kCGPathFillStroke,
   kCGPathEOFillStroke
} CGPathDrawingMode;

typedef enum {
   kCGInterpolationDefault,
   kCGInterpolationNone,
   kCGInterpolationLow,
   kCGInterpolationHigh,
} CGInterpolationQuality;

typedef int CGBlendMode;
typedef int CGTextDrawingMode;

@class KGContext;

typedef KGContext *CGContextRef;

APPKIT_EXPORT CGContextRef CGContextRetain(CGContextRef context);
APPKIT_EXPORT void         CGContextRelease(CGContextRef context);

// context state
APPKIT_EXPORT void CGContextSetAllowsAntialiasing(CGContextRef context,BOOL yesOrNo);

// layers
APPKIT_EXPORT void CGContextBeginTransparencyLayer(CGContextRef context,NSDictionary *unused);
APPKIT_EXPORT void CGContextEndTransparencyLayer(CGContextRef context);

// path
APPKIT_EXPORT BOOL    CGContextIsPathEmpty(CGContextRef context);
APPKIT_EXPORT CGPoint CGContextGetPathCurrentPoint(CGContextRef context);
APPKIT_EXPORT CGRect  CGContextGetPathBoundingBox(CGContextRef context);
APPKIT_EXPORT BOOL    CGContextPathContainsPoint(CGContextRef context,CGPoint point,CGPathDrawingMode pathMode);

APPKIT_EXPORT void CGContextBeginPath(CGContextRef context);
APPKIT_EXPORT void CGContextClosePath(CGContextRef context);
APPKIT_EXPORT void CGContextMoveToPoint(CGContextRef context,float x,float y);
APPKIT_EXPORT void CGContextAddLineToPoint(CGContextRef context,float x,float y);
APPKIT_EXPORT void CGContextAddCurveToPoint(CGContextRef context,float cx1,float cy1,float cx2,float cy2,float x,float y);
APPKIT_EXPORT void CGContextAddQuadCurveToPoint(CGContextRef context,float cx1,float cy1,float x,float y);

APPKIT_EXPORT void CGContextAddLines(CGContextRef context,const CGPoint *points,unsigned count);
APPKIT_EXPORT void CGContextAddRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextAddRects(CGContextRef context,const CGRect *rects,unsigned count);

APPKIT_EXPORT void CGContextAddArc(CGContextRef context,float x,float y,float radius,float startRadian,float endRadian,BOOL clockwise);
APPKIT_EXPORT void CGContextAddArcToPoint(CGContextRef context,float x1,float y1,float x2,float y2,float radius);
APPKIT_EXPORT void CGContextAddEllipseInRect(CGContextRef context,CGRect rect);

APPKIT_EXPORT void CGContextAddPath(CGContextRef context,CGPathRef path);

APPKIT_EXPORT void CGContextReplacePathWithStrokedPath(CGContextRef context);

// gstate

APPKIT_EXPORT void CGContextSaveGState(CGContextRef context);
APPKIT_EXPORT void CGContextRestoreGState(CGContextRef context);

APPKIT_EXPORT CGAffineTransform      CGContextGetUserSpaceToDeviceSpaceTransform(CGContextRef context);
APPKIT_EXPORT CGAffineTransform      CGContextGetCTM(CGContextRef context);
APPKIT_EXPORT CGRect                 CGContextGetClipBoundingBox(CGContextRef context);
APPKIT_EXPORT CGAffineTransform      CGContextGetTextMatrix(CGContextRef context);
APPKIT_EXPORT CGInterpolationQuality CGContextGetInterpolationQuality(CGContextRef context);
APPKIT_EXPORT CGPoint                CGContextGetTextPosition(CGContextRef context);

APPKIT_EXPORT CGPoint CGContextConvertPointToDeviceSpace(CGContextRef context,CGPoint point);
APPKIT_EXPORT CGPoint CGContextConvertPointToUserSpace(CGContextRef context,CGPoint point);
APPKIT_EXPORT CGSize  CGContextConvertSizeToDeviceSpace(CGContextRef context,CGSize size);
APPKIT_EXPORT CGSize  CGContextConvertSizeToUserSpace(CGContextRef context,CGSize size);
APPKIT_EXPORT CGRect  CGContextConvertRectToDeviceSpace(CGContextRef context,CGRect rect);
APPKIT_EXPORT CGRect  CGContextConvertRectToUserSpace(CGContextRef context,CGRect rect);

APPKIT_EXPORT void CGContextConcatCTM(CGContextRef context,CGAffineTransform matrix);
APPKIT_EXPORT void CGContextTranslateCTM(CGContextRef context,float translatex,float translatey);
APPKIT_EXPORT void CGContextScaleCTM(CGContextRef context,float scalex,float scaley);
APPKIT_EXPORT void CGContextRotateCTM(CGContextRef context,float radians);

APPKIT_EXPORT void CGContextClip(CGContextRef context);
APPKIT_EXPORT void CGContextEOClip(CGContextRef context);
APPKIT_EXPORT void CGContextClipToMask(CGContextRef context,CGRect rect,CGImageRef image);
APPKIT_EXPORT void CGContextClipToRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextClipToRects(CGContextRef context,const CGRect *rects,unsigned count);

APPKIT_EXPORT void CGContextSetStrokeColorSpace(CGContextRef context,CGColorSpaceRef colorSpace);
APPKIT_EXPORT void CGContextSetFillColorSpace(CGContextRef context,CGColorSpaceRef colorSpace);

APPKIT_EXPORT void CGContextSetStrokeColor(CGContextRef context,const float *components);
APPKIT_EXPORT void CGContextSetStrokeColorWithColor(CGContextRef context,CGColorRef color);
APPKIT_EXPORT void CGContextSetGrayStrokeColor(CGContextRef context,float gray,float alpha);
APPKIT_EXPORT void CGContextSetRGBStrokeColor(CGContextRef context,float r,float g,float b,float alpha);
APPKIT_EXPORT void CGContextSetCMYKStrokeColor(CGContextRef context,float c,float m,float y,float k,float alpha);

APPKIT_EXPORT void CGContextSetFillColor(CGContextRef context,const float *components);
APPKIT_EXPORT void CGContextSetFillColorWithColor(CGContextRef context,CGColorRef color);
APPKIT_EXPORT void CGContextSetGrayFillColor(CGContextRef context,float gray,float alpha);
APPKIT_EXPORT void CGContextSetRGBFillColor(CGContextRef context,float r,float g,float b,float alpha);
APPKIT_EXPORT void CGContextSetCMYKFillColor(CGContextRef context,float c,float m,float y,float k,float alpha);

APPKIT_EXPORT void CGContextSetAlpha(CGContextRef context,float alpha);

APPKIT_EXPORT void CGContextSetPatternPhase(CGContextRef context,CGSize phase);
APPKIT_EXPORT void CGContextSetStrokePattern(CGContextRef context,CGPatternRef pattern,const float *components);
APPKIT_EXPORT void CGContextSetFillPattern(CGContextRef context,CGPatternRef pattern,const float *components);

APPKIT_EXPORT void CGContextSetTextMatrix(CGContextRef context,CGAffineTransform matrix);

APPKIT_EXPORT void CGContextSetTextPosition(CGContextRef context,float x,float y);
APPKIT_EXPORT void CGContextSetCharacterSpacing(CGContextRef context,float spacing);
APPKIT_EXPORT void CGContextSetTextDrawingMode(CGContextRef context,CGTextDrawingMode textMode);

APPKIT_EXPORT void CGContextSetFont(CGContextRef context,CGFontRef font);
APPKIT_EXPORT void CGContextSetFontSize(CGContextRef context,float size);
APPKIT_EXPORT void CGContextSelectFont(CGContextRef context,const char *name,float size,CGTextEncoding encoding);
APPKIT_EXPORT void CGContextSetShouldSmoothFonts(CGContextRef context,BOOL yesOrNo);

APPKIT_EXPORT void CGContextSetLineWidth(CGContextRef context,float width);
APPKIT_EXPORT void CGContextSetLineCap(CGContextRef context,CGLineCap lineCap);
APPKIT_EXPORT void CGContextSetLineJoin(CGContextRef context,CGLineJoin lineJoin);
APPKIT_EXPORT void CGContextSetMiterLimit(CGContextRef context,float miterLimit);
APPKIT_EXPORT void CGContextSetLineDash(CGContextRef context,float phase,const float *lengths,unsigned count);

APPKIT_EXPORT void CGContextSetRenderingIntent(CGContextRef context,CGColorRenderingIntent renderingIntent);
APPKIT_EXPORT void CGContextSetBlendMode(CGContextRef context,CGBlendMode blendMode);

APPKIT_EXPORT void CGContextSetFlatness(CGContextRef context,float flatness);

APPKIT_EXPORT void CGContextSetInterpolationQuality(CGContextRef context,CGInterpolationQuality quality);

APPKIT_EXPORT void CGContextSetShadowWithColor(CGContextRef context,CGSize offset,float blur,CGColorRef color);
APPKIT_EXPORT void CGContextSetShadow(CGContextRef context,CGSize offset,float blur);

APPKIT_EXPORT void CGContextSetShouldAntialias(CGContextRef context,BOOL yesOrNo);

// drawing
APPKIT_EXPORT void CGContextStrokeLineSegments(CGContextRef context,const CGPoint *points,unsigned count);

APPKIT_EXPORT void CGContextStrokeRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextStrokeRectWithWidth(CGContextRef context,CGRect rect,float width);
APPKIT_EXPORT void CGContextStrokeEllipseInRect(CGContextRef context,CGRect rect);

APPKIT_EXPORT void CGContextFillRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextFillRects(CGContextRef context,const CGRect *rects,unsigned count);
APPKIT_EXPORT void CGContextFillEllipseInRect(CGContextRef context,CGRect rect);

APPKIT_EXPORT void CGContextDrawPath(CGContextRef context,CGPathDrawingMode pathMode);
APPKIT_EXPORT void CGContextStrokePath(CGContextRef context);
APPKIT_EXPORT void CGContextFillPath(CGContextRef context);
APPKIT_EXPORT void CGContextEOFillPath(CGContextRef context);

APPKIT_EXPORT void CGContextClearRect(CGContextRef context,CGRect rect);

APPKIT_EXPORT void CGContextShowGlyphs(CGContextRef context,const CGGlyph *glyphs,unsigned count);
APPKIT_EXPORT void CGContextShowGlyphsAtPoint(CGContextRef context,float x,float y,const CGGlyph *glyphs,unsigned count);
APPKIT_EXPORT void CGContextShowGlyphsWithAdvances(CGContextRef context,const CGGlyph *glyphs,const CGSize *advances,unsigned count);

APPKIT_EXPORT void CGContextShowText(CGContextRef context,const char *text,unsigned count);
APPKIT_EXPORT void CGContextShowTextAtPoint(CGContextRef context,float x,float y,const char *text,unsigned count);

APPKIT_EXPORT void CGContextDrawShading(CGContextRef context,CGShadingRef shading);
APPKIT_EXPORT void CGContextDrawImage(CGContextRef context,CGRect rect,CGImageRef image);
APPKIT_EXPORT void CGContextDrawLayerAtPoint(CGContextRef context,CGPoint point,CGLayerRef layer);
APPKIT_EXPORT void CGContextDrawLayerInRect(CGContextRef context,CGRect rect,CGLayerRef layer);
APPKIT_EXPORT void CGContextDrawPDFPage(CGContextRef context,CGPDFPageRef page);

APPKIT_EXPORT void CGContextFlush(CGContextRef context);
APPKIT_EXPORT void CGContextSynchronize(CGContextRef context);

// pagination

APPKIT_EXPORT void CGContextBeginPage(CGContextRef context,const CGRect *mediaBox);
APPKIT_EXPORT void CGContextEndPage(CGContextRef context);

// Temporary hacks

APPKIT_EXPORT void CGContextDrawContextInRect(CGContextRef context,CGContextRef other,CGRect rect);

APPKIT_EXPORT void CGContextResetClip(CGContextRef context);

APPKIT_EXPORT void CGContextSetCalibratedGrayColor(CGContextRef context,float gray,float alpha);
APPKIT_EXPORT void CGContextSetCalibratedRGBColor(CGContextRef context,float red,float green,float blue,float alpha);

APPKIT_EXPORT void CGContextCopyBits(CGContextRef context,CGRect rect,CGPoint point,int gState);
