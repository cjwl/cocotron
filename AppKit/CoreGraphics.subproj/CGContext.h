/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/AppKitExport.h>

@class CGRenderingContext;

@interface CGContext : NSObject

@end

typedef enum {
   kCGEncodingFontSpecific
} CGTextEncoding;

typedef CGContext *CGContextRef;

APPKIT_EXPORT void CGContextSaveGState(CGContextRef context);
APPKIT_EXPORT void CGContextRestoreGState(CGContextRef context);

APPKIT_EXPORT CGAffineTransform CGContextGetCTM(CGContextRef context);
APPKIT_EXPORT void CGContextConcatCTM(CGContextRef context,CGAffineTransform transform);
APPKIT_EXPORT void CGContextTranslateCTM(CGContextRef context,float translatex,float translatey);
APPKIT_EXPORT void CGContextScaleCTM(CGContextRef context,float scalex,float scaley);
APPKIT_EXPORT void CGContextRotateCTM(CGContextRef context,float radians);

APPKIT_EXPORT CGAffineTransform CGContextGetTextMatrix(CGContextRef context);
APPKIT_EXPORT void CGContextSetTextMatrix(CGContextRef context, CGAffineTransform transform);

APPKIT_EXPORT void CGContextClipToRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextClipToRects(CGContextRef context,const CGRect *rects,unsigned count);

APPKIT_EXPORT void CGContextBeginPath(CGContextRef context);
APPKIT_EXPORT void CGContextClosePath(CGContextRef context);
APPKIT_EXPORT void CGContextMoveToPoint(CGContextRef context,float x,float y);
APPKIT_EXPORT void CGContextAddLineToPoint(CGContextRef context,float x,float y);
APPKIT_EXPORT void CGContextAddArc(CGContextRef context,float x,float y,float radius,float startRadian,float endRadian,int clockwise);
APPKIT_EXPORT void CGContextAddArcToPoint(CGContextRef context,float x1,float y1,float x2,float y2,float radius);
APPKIT_EXPORT void CGContextAddCurveToPoint(CGContextRef context,float cx1,float cy1,float cx2,float cy2,float x,float y);

APPKIT_EXPORT void CGContextFillPath(CGContextRef context);
APPKIT_EXPORT void CGContextFillRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextFillRects(CGContextRef context,const CGRect *rects,unsigned count);

APPKIT_EXPORT void CGContextSetLineWidth(CGContextRef context,float width);

APPKIT_EXPORT void CGContextStrokePath(CGContextRef context);
APPKIT_EXPORT void CGContextStrokeRect(CGContextRef context,CGRect rect);
APPKIT_EXPORT void CGContextStrokeRectWithWidth(CGContextRef context,CGRect rect,float width);

APPKIT_EXPORT void CGContextSelectFont(CGContextRef context,const char *name,float size,CGTextEncoding encoding);
APPKIT_EXPORT void CGContextShowTextAtPoint(CGContextRef context,float x,float y,const char *text,unsigned count);
APPKIT_EXPORT void CGContextShowGlyphsAtPoint(CGContextRef context,float x,float y,const CGGlyph *glyphs,unsigned count);
APPKIT_EXPORT void CGContextShowGlyphsWithAdvances(CGContextRef context,const CGGlyph *glyphs,const CGSize *advances,unsigned count);

APPKIT_EXPORT void CGContextBeginPage(CGContextRef context,const CGRect *mediaBox);
APPKIT_EXPORT void CGContextEndPage(CGContextRef context);

// Temporary hacks

APPKIT_EXPORT void CGContextSetDeviceGrayColor(CGContextRef context,float gray,float alpha);
APPKIT_EXPORT void CGContextSetDeviceRGBColor(CGContextRef context,float red,float green,float blue,float alpha);
APPKIT_EXPORT void CGContextSetDeviceCMYKColor(CGContextRef context,float cyan,float magenta,float yellow,float black,float alpha);

APPKIT_EXPORT void CGContextSetCalibratedGrayColor(CGContextRef context,float gray,float alpha);
APPKIT_EXPORT void CGContextSetCalibratedRGBColor(CGContextRef context,float red,float green,float blue,float alpha);

APPKIT_EXPORT void CGContextCopyBits(CGContextRef context,CGRect rect,CGPoint point,int gState);

APPKIT_EXPORT void CGContextSourceOverRGBAImage(CGContextRef context,CGRect rect,int width,int height,unsigned int *data,float fraction);

APPKIT_EXPORT void CGContextBitCopy(CGContextRef context,NSPoint dstOrigin,CGRenderingContext *deviceContext,NSPoint srcOrigin,NSSize size);

APPKIT_EXPORT void CGContextBeginDocument(CGContextRef context);
APPKIT_EXPORT void CGContextScalePage(CGContextRef context,float scalex,float scaley);
APPKIT_EXPORT void CGContextEndDocument(CGContextRef context);
