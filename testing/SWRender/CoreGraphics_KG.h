#import "KGContext.h"
#import "KGPath.h"
#import "KGMutablePath.h"
#import "KGColor.h"
#import "KGColorSpace.h"
#import "KGImage.h"
#import "KGImageSource.h"
#import "KGDataProvider.h"

#define CGContextRef KGContext *
#define CGColorRef KGColor *
#define CGColorSpaceRef KGColorSpace *
#define CGPathRef KGPath *
#define CGMutablePathRef KGMutablePath *
#define CGDataProviderRef KGDataProvider *
#define CGImageRef KGImage *
#define CGImageSourceRef KGImageSource *

#define CGContextRetain(context) \
    [context retain]
#define CGContextRelease(context) \
    [context release]
#define CGContextSetAllowsAntialiasing(context,yesOrNo) \
    [context setAllowsAntialiasing:yesOrNo]
#define CGContextBeginTransparencyLayer(context,unused) \
    [context beginTransparencyLayerWithInfo:unused]
#define CGContextEndTransparencyLayer(context) \
    [context endTransparencyLayer]
#define CGContextIsPathEmpty(context) \
    [context pathIsEmpty]
#define CGContextGetPathCurrentPoint(context) \
    [context pathCurrentPoint]
#define CGContextGetPathBoundingBox(context) \
    [context pathBoundingBox]
#define CGContextPathContainsPoint(context,point,pathMode) \
   [context pathContainsPoint:point drawingMode:pathMode]
#define CGContextBeginPath(context) \
    [context beginPath]
#define CGContextClosePath(context) \
    [context closePath]
#define CGContextMoveToPoint(context,x,y) \
    [context moveToPoint:x:y]
#define CGContextAddLineToPoint(context,x,y) \
    [context addLineToPoint:x:y]
#define CGContextAddCurveToPoint(context,cx1,cy1,cx2,cy2,x,y) \
    [context addCurveToPoint:cx1:cy1:cx2:cy2:x:y]
#define CGContextAddQuadCurveToPoint(context,cx1,cy1,x,y) \
    [context addQuadCurveToPoint:cx1:cy1:x:y]
#define CGContextAddLines(context,points,count) \
    [context addLinesWithPoints:points count:count]
#define CGContextAddRect(context,rect) \
    [context addRect:rect]
#define CGContextAddRects(context,rects,count) \
    [context addRects:rects count:count]
#define CGContextAddArc(context,x,y,radius,startRadian,endRadian,clockwise) \
    [context addArc:x:y:radius:startRadian:endRadian:clockwise]
#define CGContextAddArcToPoint(context,x1,y1,x2,y2,radius) \
    [context addArcToPoint:x1:y1:x2:y2:radius]
#define CGContextAddEllipseInRect(context,rect) \
    [context addEllipseInRect:rect]
#define CGContextAddPath(context,path) \
    [context addPath:path]
#define CGContextReplacePathWithStrokedPath(context) \
    [context replacePathWithStrokedPath]
#define CGContextSaveGState(context) \
    [context saveGState]
#define CGContextRestoreGState(context) \
    [context restoreGState]
#define CGContextGetUserSpaceToDeviceSpaceTransform(context) \
    [context userSpaceToDeviceSpaceTransform]
#define CGContextGetCTM(context) \
    [context ctm]
#define CGContextGetClipBoundingBox(context) \
    [context clipBoundingBox]
#define CGContextGetTextMatrix(context) \
    [context textMatrix]
#define CGContextGetInterpolationQuality(context) \
    [context interpolationQuality]
#define CGContextGetTextPosition(context) \
    [context textPosition]
#define CGContextConvertPointToDeviceSpace(context,point) \
    [context convertPointToDeviceSpace:point]
#define CGContextConvertPointToUserSpace(context,point) \
    [context convertPointToUserSpace:point]
#define CGContextConvertSizeToDeviceSpace(context,size) \
    [context convertSizeToDeviceSpace:size]
#define CGContextConvertSizeToUserSpace(context,size) \
    [context convertSizeToUserSpace:size]
#define CGContextConvertRectToDeviceSpace(context,rect) \
    [context convertRectToDeviceSpace:rect]
#define CGContextConvertRectToUserSpace(context,rect) \
    [context convertRectToUserSpace:rect]
#define CGContextSetCTM(context,matrix) \
    [context setCTM:matrix]
#define CGContextConcatCTM(context,matrix) \
    [context concatCTM:matrix]
#define CGContextTranslateCTM(context,tx,ty) \
    [context translateCTM:tx:ty]
#define CGContextScaleCTM(context,scalex,scaley) \
    [context scaleCTM:scalex:scaley]
#define CGContextRotateCTM(context,radians) \
    [context rotateCTM:radians]
#define CGContextClip(context) \
    [context clipToPath]
#define CGContextEOClip(context) \
    [context evenOddClipToPath]
#define CGContextClipToMask(context,rect,image) \
    [context clipToMask:image inRect:rect]
#define CGContextClipToRect(context,rect) \
    [context clipToRect:rect]
#define CGContextClipToRects(context,rects,count) \
    [context clipToRects:rects count:count]
#define CGContextSetStrokeColorSpace(context,colorSpace) \
    [context setStrokeColorSpace:colorSpace]
#define CGContextSetFillColorSpace(context,colorSpace) \
    [context setFillColorSpace:colorSpace]
#define CGContextSetStrokeColor(context,components) \
    [context setStrokeColorWithComponents:components]
#define CGContextSetStrokeColorWithColor(context,color) \
    [context setStrokeColor:color]
#define CGContextSetGrayStrokeColor(context,gray,alpha) \
    [context setGrayStrokeColor:gray:alpha]
#define CGContextSetRGBStrokeColor(context,r,g,b,alpha) \
    [context setRGBStrokeColor:r:g:b:alpha]
#define CGContextSetCMYKStrokeColor(context,c,m,y,k,alpha) \
    [context setCMYKStrokeColor:c:m:y:k:alpha]
#define CGContextSetFillColor(context,components) \
    [context setFillColorWithComponents:components]
#define CGContextSetFillColorWithColor(context,color) \
    [context setFillColor:color]
#define CGContextSetGrayFillColor(context,gray,alpha) \
    [context setGrayFillColor:gray:alpha]
#define CGContextSetRGBFillColor(context,r,g,b,alpha) \
    [context setRGBFillColor:r:g:b:alpha]
#define CGContextSetCMYKFillColor(context,c,m,y,k,alpha) \
    [context setCMYKFillColor:c:m:y:k:alpha]
#define CGContextSetAlpha(context,alpha) \
    [context setStrokeAndFillAlpha:alpha]
#define CGContextSetPatternPhase(context,phase) \
    [context setPatternPhase:phase]
#define CGContextSetStrokePattern(context,pattern,components) \
    [context setStrokePattern:pattern components:components]
#define CGContextSetFillPattern(context,pattern,components) \
    [context setFillPattern:pattern components:components]
#define CGContextSetTextMatrix(context,matrix) \
    [context setTextMatrix:matrix]
#define CGContextSetTextPosition(context,x,y) \
    [context setTextPosition:x:y]
#define CGContextSetCharacterSpacing(context,spacing) \
    [context setCharacterSpacing:spacing]
#define CGContextSetTextDrawingMode(context,textMode) \
    [context setTextDrawingMode:textMode]
#define CGContextSetFont(context,font) \
    [context setFont:font]
#define CGContextSetFontSize(context,size) \
    [context setFontSize:size]
#define CGContextSelectFont(context,name,size,encoding) \
    [context selectFontWithName:name size:size encoding:encoding]
#define CGContextSetShouldSmoothFonts(context,yesOrNo) \
    [context setShouldSmoothFonts:yesOrNo]
#define CGContextSetLineWidth(context,width) \
    [context setLineWidth:width]
#define CGContextSetLineCap(context,lineCap) \
    [context setLineCap:lineCap]
#define CGContextSetLineJoin(context,lineJoin) \
    [context setLineJoin:lineJoin]
#define CGContextSetMiterLimit(context,miterLimit) \
    [context setMiterLimit:miterLimit]
#define CGContextSetLineDash(context,dphase,dlengths,dcount) \
    [context setLineDashPhase:dphase lengths:dlengths count:dcount]
#define CGContextSetRenderingIntent(context,renderingIntent) \
    [context setRenderingIntent:renderingIntent]
#define CGContextSetBlendMode(context,blendMode) \
    [context setBlendMode:blendMode]
#define CGContextSetFlatness(context,flatness) \
    [context setFlatness:flatness]
#define CGContextSetInterpolationQuality(context,quality) \
    [context setInterpolationQuality:quality]
#define CGContextSetShadowWithColor(context,offset,blur,color) \
    [context setShadowOffset:offset blur:blur color:color]
#define CGContextSetShadow(context,offset,blur) \
    [context setShadowOffset:offset blur:blur]
#define CGContextSetShouldAntialias(context,yesOrNo) \
    [context setShouldAntialias:yesOrNo]
#define CGContextStrokeLineSegments(context,points,count) \
    [context strokeLineSegmentsWithPoints:points count:count]
#define CGContextStrokeRect(context,rect) \
    [context strokeRect:rect]
#define CGContextStrokeRectWithWidth(context,rect,width) \
    [context strokeRect:rect width:width]
#define CGContextStrokeEllipseInRect(context,rect) \
    [context strokeEllipseInRect:rect]
#define CGContextFillRect(context,rect) \
    [context fillRect:rect]
#define CGContextFillRects(context,rects,count) \
    [context fillRects:rects count:count]
#define CGContextFillEllipseInRect(context,rect) \
    [context fillEllipseInRect:rect]
#define CGContextDrawPath(context,pathMode) \
    [context drawPath:pathMode]
#define CGContextStrokePath(context) \
    [context strokePath]
#define CGContextFillPath(context) \
    [context fillPath]
#define CGContextEOFillPath(context) \
    [context evenOddFillPath]
#define CGContextClearRect(context,rect) \
    [context clearRect:rect]
#define CGContextShowGlyphs(context,glyphs,count) \
    [context showGlyphs:glyphs count:count]
#define CGContextShowGlyphsAtPoint(context,x,y,glyphs,count) \
    [context showGlyphs:glyphs count:count atPoint:x:y]
#define CGContextShowGlyphsWithAdvances(context,glyphs,advances,count) \
    [context showGlyphs:glyphs count:count advances:advances]
#define CGContextShowText(context,text,count) \
    [context showText:text length:count]
#define CGContextShowTextAtPoint(context,x,y,text,count) \
    [context showText:text length:count atPoint:x:y]
#define CGContextDrawShading(context,shading) \
    [context drawShading:shading]
#define CGContextDrawImage(context,rect,image) \
    [context drawImage:image inRect:rect]
#define CGContextDrawLayerAtPoint(context,point,layer) \
    [context drawLayer:layer atPoint:point]
#define CGContextDrawLayerInRect(context,rect,layer) \
    [context drawLayer:layer inRect:rect]
#define CGContextDrawPDFPage(context,page) \
    [context drawPDFPage:page]
#define CGContextFlush(context) \
    [context flush]
#define CGContextSynchronize(context) \
    [context synchronize]
#define CGContextBeginPage(context,mediaBox) \
    [context beginPage:mediaBox]
#define CGContextEndPage(context) \
    [context endPage]

// bitmap context

#define CGBitmapContextCreate(bytes,w,h,bpc,bpr,cs,bi) \
   [KGContext createWithBytes:bytes width:w height:h bitsPerComponent:bpc bytesPerRow:bpr colorSpace:cs bitmapInfo:bi]

#define CGBitmapContextGetData(self) \
   [self bytes]

#define  CGBitmapContextGetWidth(self) \
   [self width]

#define  CGBitmapContextGetHeight(self) \
   [self height]

#define  CGBitmapContextGetBitsPerComponent(self) \
   [self bitsPerComponent]

#define  CGBitmapContextGetBytesPerRow(self) \
   [self bytesPerRow]

#define  CGBitmapContextGetColorSpace(self) \
   [self colorSpace]

#define  CGBitmapContextGetBitmapInfo(self) \
   [self bitmapInfo]

#define  CGBitmapContextGetBitsPerPixel(self) \
   [self bitsPerPixel]

#define  CGBitmapContextGetAlphaInfo(self) \
   [self alphaInfo]

#define  CGBitmapContextCreateImage(self) \
   [self createImage]

// CGPath
#define CGPathRelease(self) \
   [self release]

#define CGPathRetain(self) \
   [self retain]

#define CGPathEqualToPath(self,other) \
   [self isEqualToPath:other]

#define CGPathGetBoundingBox(self) \
   [self boundingBox]

#define CGPathGetCurrentPoint(self) \
   [self currentPoint]

#define CGPathIsEmpty(self) \
   [self isEmpty]

#define CGPathIsRect(self,rect) \
   [self isRect:rect]

#define CGPathApply(self,info,fn) \
   [self applyWithInfo:info function:fn]

#define CGPathCreateMutableCopy(self) \
   [self mutableCopy]

#define CGPathCreateCopy(self) \
   [self copy]

#define CGPathContainsPoint(self,xform,pt,eo) \
   [self containsPoint:pt evenOdd:eo withTransform:xform]

#define CGPathCreateMutable(void) \
   [[KGMutablePath alloc] init]

#define CGPathMoveToPoint(self,xform,x,y) \
   [self moveToPoint:CGPointMake(x,y) withTransform:xform]

#define CGPathAddLineToPoint(self,xform,x,y) \
   [self addLineToPoint:CGPointMake(x,y) withTransform:xform]

#define CGPathAddCurveToPoint(self,xform,cp1x,cp1y,cp2x,cp2y,x,y) \
   [self addCurveToControlPoint:CGPointMake(cp1x,cp1y) controlPoint:CGPointMake(cp2x,cp2y) endPoint:CGPointMake(x,y) withTransform:xform]

#define CGPathAddQuadCurveToPoint(self,xform,cpx,cpy,x,y) \
   [self addQuadCurveToControlPoint:CGPointMake(cpx,cpy) endPoint:CGPointMake(x,y) withTransform:xform]

#define CGPathCloseSubpath(self) \
   [self closeSubpath]

#define CGPathAddLines(self,xform,points,pointCount) \
   [self addLinesWithPoints:points count:pointCount withTransform:xform]

#define CGPathAddRect(self,xform,rect) \
   [self addRect:rect withTransform:xform]

#define CGPathAddRects(self,xform,rects,rectCount) \
   [self addRects:rects count:rectCount withTransform:xform]

#define CGPathAddArc(self,xform,x,y,r,startRadian,endRadian,cw) \
   [self addArcAtPoint:CGPointMake(x,y) radius:r startAngle:startRadian endAngle:endRadian clockwise:cw withTransform:xform]

#define CGPathAddArcToPoint(self,xform,tx1,ty1,tx2,ty2,radius) \
   [self addArcToPoint:CGPointMake(tx1,ty1) point:CGPointMake(tx2,ty2) radius:radius withTransform:xform]

#define CGPathAddEllipseInRect(self,xform,rect) \
   [self addEllipseInRect:rect withTransform:xform]

#define CGPathAddPath(self,xform,other) \
   [self addPath:other withTransform:xform]


// CGColor

#define CGColorRetain(self) \
   [self retain]

#define CGColorRelease(self) \
   [self release]

#define CGColorCreate(colorSpace,ccomponents) \
   [[KGColor alloc] initWithColorSpace:colorSpace components:ccomponents]

#define CGColorCreateGenericGray(gray,a) \
   [[KGColor alloc] initWithGenericGray:gray alpha:a]

#define CGColorCreateGenericRGB(r,g,b,a) \
   [[KGColor alloc] initWithGenericRed:r green:g blue:b alpha:a]

#define CGColorCreateGenericCMYK(c,m,y,k,a) \
   [[KGColor alloc] initWithGenericCyan:c magenta:m yellow:y black:k alpha:a]

#define CGColorCreateWithPattern(colorSpace,pattern,ccomponents) \
   [[KGColor alloc] initWithColorSpace:colorSpace pattern:pattern components:ccomponents]

#define CGColorCreateCopy(self) \
   [self copy]

#define CGColorCreateCopyWithAlpha(self,a) \
   [self copyWithAlpha:a]

#define CGColorEqualToColor(self,other) \
   [self isEqualToColor:other]

#define CGColorGetColorSpace(self) \
   [self colorSpace]

#define CGColorGetNumberOfComponents(self) \
   [self numberOfComponents]

#define CGColorGetComponents(self) \
   [self components]

#define CGColorGetAlpha(self) \
   [self alpha]

#define CGColorGetPattern(self) \
   [self pattern]

// CGColorSpace

#define CGColorSpaceCreateDeviceRGB() \
    [[KGColorSpace alloc] initWithGenericRGB]

#define CGColorSpaceCreateDeviceGray() \
    [[KGColorSpace alloc] initWithGenericGray]

#define CGColorSpaceCreateDeviceCMYK() \
    [[KGColorSpace alloc] initWithGenericCMYK]

// CGImage

#define  CGImageRetain(image) \
   [image retain]


#define  CGImageRelease(image) \
   [image release]


#define  CGImageCreate(w,h,bpc,bpp,bpr,cs,bi,dp,dec,interp,ri) \
   [[KGImage alloc] initWithWidth:w height:h bitsPerComponent:bpc bitsPerPixel:bpp bytesPerRow:bpr colorSpace:cs bitmapInfo:bi provider:dp decode:dec interpolate:interp renderingIntent:ri]


#define  CGImageMaskCreate(w,h,bpc,bpp,bpr,dp,dec,interp) \
   [[KGImage alloc] initMaskWithWidth:w height:h bitsPerComponent:bpc bitsPerPixel:bpp bytesPerRow:bpr provider:dp decode:dec interpolate:interp]


#define  CGImageCreateCopy(self) \
   [self copy]


#define  CGImageCreateCopyWithColorSpace(self,colorSpace) \
   [self copyWithColorSpace:colorSpace]


#define  CGImageCreateWithImageInRect(self,rect) \
   [self childImageInRect:rect]


#define  CGImageCreateWithJPEGDataProvider(jpegProvider,dec,interpolate, renderingIntent) \
   [[KGImage alloc] initWithJPEGDataProvider:jpegProvider decode:dec interpolate:interpolate renderingIntent:renderingIntent]


#define  CGImageCreateWithPNGDataProvider(pngProvider,dec,interpolate,renderingIntent) \
   [[KGImage alloc] initWithPNGDataProvider:pngProvider decode:dec interpolate:interpolate renderingIntent:renderingIntent]


#define  CGImageCreateWithMask(self,mask) \
   [self copyWithMask:mask]


#define  CGImageCreateWithMaskingColors(self,components) \
   [self copyWithMaskingColors:components]


#define  CGImageGetWidth(self) \
   [self width]


#define  CGImageGetHeight(self) \
   [self height]


#define  CGImageGetBitsPerComponent(self) \
   [self bitsPerComponent]


#define  CGImageGetBitsPerPixel(self) \
   [self bitsPerPixel]


#define  CGImageGetBytesPerRow(self) \
   [self bytesPerRow]


#define  CGImageGetColorSpace(self) \
   [self colorSpace]


#define  CGImageGetBitmapInfo(self) \
   [self bitmapInfo]


#define  CGImageGetDataProvider(self) \
   [self dataProvider]


#define CGImageGetDecode(self) \
   [self decode]


#define  CGImageGetShouldInterpolate(self) \
   [self shouldInterpolate]


#define  CGImageGetRenderingIntent(self) \
   [self renderingIntent]


#define  CGImageIsMask(self) \
   [self isMask]


#define  CGImageGetAlphaInfo(self) \
   [self alphaInfo]

// data provider

#define CGDataProviderCreateWithData(info,data,size, releaseCallback) \
   [[KGDataProvider alloc] initWithBytes:data length:size]
   
// image source

#define CGImageSourceCreateWithData(data,opts) \
   [KGImageSource newImageSourceWithData:data options:opts]

#define CGImageSourceCreateImageAtIndex(self,index,opts) \
   [self imageAtIndex:index options:opts]


