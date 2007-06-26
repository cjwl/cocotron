/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/CGContext.h>
#import "KGContext.h"

CGContextRef CGContextRetain(CGContextRef context) {
   return [context retain];
}

void CGContextRelease(CGContextRef context) {
   [context release];
}

void CGContextSetAllowsAntialiasing(CGContextRef context,BOOL yesOrNo) {
   [context setAllowsAntialiasing:yesOrNo];
}

void CGContextBeginTransparencyLayer(CGContextRef context,NSDictionary *unused) {
   [context beginTransparencyLayerWithInfo:unused];
}

void CGContextEndTransparencyLayer(CGContextRef context) {
   [context endTransparencyLayer];
}

BOOL    CGContextIsPathEmpty(CGContextRef context) {
   return [context pathIsEmpty];
}

CGPoint CGContextGetPathCurrentPoint(CGContextRef context) {
   return [context pathCurrentPoint];
}

CGRect  CGContextGetPathBoundingBox(CGContextRef context) {
   return [context pathBoundingBox];
}

BOOL    CGContextPathContainsPoint(CGContextRef context,CGPoint point,CGPathDrawingMode pathMode) {
   return [context pathContainsPoint:point drawingMode:pathMode];
}

void CGContextBeginPath(CGContextRef context) {
   [context beginPath];
}

void CGContextClosePath(CGContextRef context) {
   [context closePath];
}

void CGContextMoveToPoint(CGContextRef context,float x,float y) {
   [context moveToPoint:x:y];
}

void CGContextAddLineToPoint(CGContextRef context,float x,float y) {
   [context addLineToPoint:x:y];
}

void CGContextAddCurveToPoint(CGContextRef context,float cx1,float cy1,float cx2,float cy2,float x,float y) {
   [context addCurveToPoint:cx1:cy1:cx2:cy2:x:y];
}

void CGContextAddQuadCurveToPoint(CGContextRef context,float cx1,float cy1,float x,float y) {
   [context addQuadCurveToPoint:cx1:cy1:x:y];
}

void CGContextAddLines(CGContextRef context,const CGPoint *points,unsigned count) {
   [context addLinesWithPoints:points count:count];
}

void CGContextAddRect(CGContextRef context,CGRect rect) {
   [context addRect:rect];
}

void CGContextAddRects(CGContextRef context,const CGRect *rects,unsigned count) {
   [context addRects:rects count:count];
}

void CGContextAddArc(CGContextRef context,float x,float y,float radius,float startRadian,float endRadian,BOOL clockwise) {
   [context addArc:x:y:radius:startRadian:endRadian:clockwise];
}

void CGContextAddArcToPoint(CGContextRef context,float x1,float y1,float x2,float y2,float radius) {
   [context addArcToPoint:x1:y1:x2:y2:radius];
}

void CGContextAddEllipseInRect(CGContextRef context,CGRect rect) {
   [context addEllipseInRect:rect];
}

void CGContextAddPath(CGContextRef context,CGPathRef path) {
   [context addPath:path];
}

void CGContextReplacePathWithStrokedPath(CGContextRef context) {
   [context replacePathWithStrokedPath];
}

void CGContextSaveGState(CGContextRef context){
   [context saveGState];
}

void CGContextRestoreGState(CGContextRef context){
   [context restoreGState];
}

CGAffineTransform CGContextGetUserSpaceToDeviceSpaceTransform(CGContextRef context) {
   return [context userSpaceToDeviceSpaceTransform];
}

CGAffineTransform CGContextGetCTM(CGContextRef context) {
   return [context ctm];
}

CGRect CGContextGetClipBoundingBox(CGContextRef context) {
   return [context clipBoundingBox];
}

CGAffineTransform CGContextGetTextMatrix(CGContextRef context) {
   return [context textMatrix];
}

CGInterpolationQuality CGContextGetInterpolationQuality(CGContextRef context) {
   return [context interpolationQuality];
}

CGPoint CGContextGetTextPosition(CGContextRef context) {
   return [context textPosition];
}

CGPoint CGContextConvertPointToDeviceSpace(CGContextRef context,CGPoint point) {
   return [context convertPointToDeviceSpace:point];
}

CGPoint CGContextConvertPointToUserSpace(CGContextRef context,CGPoint point) {
   return [context convertPointToUserSpace:point];
}

CGSize  CGContextConvertSizeToDeviceSpace(CGContextRef context,CGSize size) {
   return [context convertSizeToDeviceSpace:size];
}

CGSize  CGContextConvertSizeToUserSpace(CGContextRef context,CGSize size) {
   return [context convertSizeToUserSpace:size];
}

CGRect  CGContextConvertRectToDeviceSpace(CGContextRef context,CGRect rect) {
   return [context convertRectToDeviceSpace:rect];
}

CGRect  CGContextConvertRectToUserSpace(CGContextRef context,CGRect rect) {
   return [context convertRectToUserSpace:rect];
}

void CGContextConcatCTM(CGContextRef context,CGAffineTransform matrix) {
   [context concatCTM:matrix];
}

void CGContextTranslateCTM(CGContextRef context,float tx,float ty){
   [context translateCTM:tx:ty];
}

void CGContextScaleCTM(CGContextRef context,float scalex,float scaley){
   [context scaleCTM:scalex:scaley];
}

void CGContextRotateCTM(CGContextRef context,float radians) {
   [context rotateCTM:radians];
}

void CGContextClip(CGContextRef context) {
   [context clipToPath];
}

void CGContextEOClip(CGContextRef context) {
   [context evenOddClipToPath];
}

void CGContextClipToMask(CGContextRef context,CGRect rect,CGImageRef image) {
   [context clipToMask:image inRect:rect];
}

void CGContextClipToRect(CGContextRef context,CGRect rect){
   [context clipToRect:rect];
}

void CGContextClipToRects(CGContextRef context,const CGRect *rects,unsigned count) {
   [context clipToRects:rects count:count];
}

void CGContextSetStrokeColorSpace(CGContextRef context,CGColorSpaceRef colorSpace) {
   [context setStrokeColorSpace:colorSpace];
}

void CGContextSetFillColorSpace(CGContextRef context,CGColorSpaceRef colorSpace) {
   [context setFillColorSpace:colorSpace];
}

void CGContextSetStrokeColor(CGContextRef context,const float *components) {
   [context setStrokeColorWithComponents:components];
}

void CGContextSetStrokeColorWithColor(CGContextRef context,CGColorRef color) {
   [context setStrokeColor:color];
}

void CGContextSetGrayStrokeColor(CGContextRef context,float gray,float alpha) {
   [context setGrayStrokeColor:gray:alpha];
}

void CGContextSetRGBStrokeColor(CGContextRef context,float r,float g,float b,float alpha) {
   [context setRGBStrokeColor:r:g:b:alpha];
}

void CGContextSetCMYKStrokeColor(CGContextRef context,float c,float m,float y,float k,float alpha) {
   [context setCMYKStrokeColor:c:m:y:k:alpha];
}

void CGContextSetFillColor(CGContextRef context,const float *components) {
   [context setFillColorWithComponents:components];
}

void CGContextSetFillColorWithColor(CGContextRef context,CGColorRef color) {
   [context setFillColor:color];
}

void CGContextSetGrayFillColor(CGContextRef context,float gray,float alpha) {
   [context setGrayFillColor:gray:alpha];
}

void CGContextSetRGBFillColor(CGContextRef context,float r,float g,float b,float alpha) {
   [context setRGBFillColor:r:g:b:alpha];
}

void CGContextSetCMYKFillColor(CGContextRef context,float c,float m,float y,float k,float alpha) {
   [context setCMYKFillColor:c:m:y:k:alpha];
}

void CGContextSetAlpha(CGContextRef context,float alpha) {
   [context setStrokeAndFillAlpha:alpha];
}

void CGContextSetPatternPhase(CGContextRef context,CGSize phase) {
   [context setPatternPhase:phase];
}

void CGContextSetStrokePattern(CGContextRef context,CGPatternRef pattern,const float *components) {
   [context setStrokePattern:pattern components:components];
}

void CGContextSetFillPattern(CGContextRef context,CGPatternRef pattern,const float *components) {
   [context setFillPattern:pattern components:components];
}

void CGContextSetTextMatrix(CGContextRef context,CGAffineTransform matrix) {
   [context setTextMatrix:matrix];
}

void CGContextSetTextPosition(CGContextRef context,float x,float y) {
   [context setTextPosition:x:y];
}

void CGContextSetCharacterSpacing(CGContextRef context,float spacing) {
   [context setCharacterSpacing:spacing];
}

void CGContextSetTextDrawingMode(CGContextRef context,CGTextDrawingMode textMode) {
   [context setTextDrawingMode:textMode];
}

void CGContextSetFont(CGContextRef context,CGFontRef font) {
   [context setFont:font];
}

void CGContextSetFontSize(CGContextRef context,float size) {
   [context setFontSize:size];
}

void CGContextSelectFont(CGContextRef context,const char *name,float size,CGTextEncoding encoding) {
   [context selectFontWithName:name size:size encoding:encoding];
}

void CGContextSetShouldSmoothFonts(CGContextRef context,BOOL yesOrNo) {
   [context setShouldSmoothFonts:yesOrNo];
}

void CGContextSetLineWidth(CGContextRef context,float width) {
   [context setLineWidth:width];
}

void CGContextSetLineCap(CGContextRef context,CGLineCap lineCap) {
   [context setLineCap:lineCap];
}

void CGContextSetLineJoin(CGContextRef context,CGLineJoin lineJoin) {
   [context setLineJoin:lineJoin];
}

void CGContextSetMiterLimit(CGContextRef context,float miterLimit) {
   [context setMiterLimit:miterLimit];
}

void CGContextSetLineDash(CGContextRef context,float phase,const float *lengths,unsigned count) {
   [context setLineDashPhase:phase lengths:lengths count:count];
}

void CGContextSetRenderingIntent(CGContextRef context,CGColorRenderingIntent renderingIntent) {
   [context setRenderingIntent:renderingIntent];
}

void CGContextSetBlendMode(CGContextRef context,CGBlendMode blendMode) {
   [context setBlendMode:blendMode];
}

void CGContextSetFlatness(CGContextRef context,float flatness) {
   [context setFlatness:flatness];
}

void CGContextSetInterpolationQuality(CGContextRef context,CGInterpolationQuality quality) {
   [context setInterpolationQuality:quality];
}

void CGContextSetShadowWithColor(CGContextRef context,CGSize offset,float blur,CGColorRef color) {
   [context setShadowOffset:offset blur:blur color:color];
}

void CGContextSetShadow(CGContextRef context,CGSize offset,float blur) {
   [context setShadowOffset:offset blur:blur];
}

void CGContextSetShouldAntialias(CGContextRef context,BOOL yesOrNo) {
   [context setShouldAntialias:yesOrNo];
}

void CGContextStrokeLineSegments(CGContextRef context,const CGPoint *points,unsigned count) {
   [context strokeLineSegmentsWithPoints:points count:count];
}

void CGContextStrokeRect(CGContextRef context,CGRect rect) {
   [context strokeRect:rect];
}

void CGContextStrokeRectWithWidth(CGContextRef context,CGRect rect,float width) {
   [context strokeRect:rect width:width];
}

void CGContextStrokeEllipseInRect(CGContextRef context,CGRect rect) {
   [context strokeEllipseInRect:rect];
}

void CGContextFillRect(CGContextRef context,CGRect rect) {
   [context fillRect:rect];
}

void CGContextFillRects(CGContextRef context,const CGRect *rects,unsigned count) {
   [context fillRects:rects count:count];
}

void CGContextFillEllipseInRect(CGContextRef context,CGRect rect) {
   [context fillEllipseInRect:rect];
}

void CGContextDrawPath(CGContextRef context,CGPathDrawingMode pathMode) {
   [context drawPath:pathMode];
}

void CGContextStrokePath(CGContextRef context) {
   [context strokePath];
}

void CGContextFillPath(CGContextRef context) {
   [context fillPath];
}

void CGContextEOFillPath(CGContextRef context) {
   [context evenOddFillPath];
}

void CGContextClearRect(CGContextRef context,CGRect rect) {
   [context clearRect:rect];
}

void CGContextShowGlyphs(CGContextRef context,const CGGlyph *glyphs,unsigned count) {
   [context showGlyphs:glyphs count:count];
}

void CGContextShowGlyphsAtPoint(CGContextRef context,float x,float y,const CGGlyph *glyphs,unsigned count) {
   [context showGlyphs:glyphs count:count atPoint:x:y];
}

void CGContextShowGlyphsWithAdvances(CGContextRef context,const CGGlyph *glyphs,const CGSize *advances,unsigned count) {
   [context showGlyphs:glyphs count:count advances:advances];
}

void CGContextShowText(CGContextRef context,const char *text,unsigned count) {
   [context showText:text length:count];
}

void CGContextShowTextAtPoint(CGContextRef context,float x,float y,const char *text,unsigned count) {
   [context showText:text length:count atPoint:x:y];
}

void CGContextDrawShading(CGContextRef context,CGShadingRef shading) {
   [context drawShading:shading];
}

void CGContextDrawImage(CGContextRef context,CGRect rect,CGImageRef image) {
   [context drawImage:image inRect:rect];
}

void CGContextDrawLayerAtPoint(CGContextRef context,CGPoint point,CGLayerRef layer) {
   [context drawLayer:layer atPoint:point];
}

void CGContextDrawLayerInRect(CGContextRef context,CGRect rect,CGLayerRef layer) {
   [context drawLayer:layer inRect:rect];
}

void CGContextDrawPDFPage(CGContextRef context,CGPDFPageRef page) {
   [context drawPDFPage:page];
}

void CGContextFlush(CGContextRef context) {
   [context flush];
}

void CGContextSynchronize(CGContextRef context) {
   [context synchronize];
}

void CGContextBeginPage(CGContextRef context,const CGRect *mediaBox) {
   [context beginPage:mediaBox];
}

void CGContextEndPage(CGContextRef context) {
   [context endPage];
}






/// temporary hacks

void CGContextResetClip(CGContextRef context) {
   [context resetClip];
}

void CGContextSetCalibratedGrayColor(CGContextRef context,float gray,float alpha) {
   [context setCalibratedColorWhite:gray alpha:alpha];
}

void CGContextSetCalibratedRGBColor(CGContextRef context,float red,float green,float blue,float alpha) {
   [context setCalibratedColorRed:red green:green blue:blue alpha:alpha];
}

void CGContextCopyBits(CGContextRef context,CGRect rect,CGPoint point,int gState) {
   [context copyBitsInRect:rect toPoint:point gState:gState];
}

void CGContextBeginDocument(CGContextRef context) {
   [context beginDocument];
}

void CGContextScalePage(CGContextRef context,float scalex,float scaley) {
   [context scalePage:scalex:scaley];
}

void CGContextEndDocument(CGContextRef context) {
   [context endDocument];
}

