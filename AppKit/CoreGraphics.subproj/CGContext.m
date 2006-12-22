/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/CGContext.h>

@interface CGContext(CGContext_private)

-(void)saveGState;
-(void)restoreGState;

-(CGAffineTransform)getCTM;
-(void)concatCTM:(CGAffineTransform)transform;
-(void)scaleCTM:(float)scalex:(float)scaley;
-(void)translateCTM:(float)translatex:(float)translatey;
-(void)rotateCTM:(float)radians;

-(CGAffineTransform)textMatrix;
-(void)setTextMatrix:(CGAffineTransform)transform;

-(void)clipToRect:(NSRect)rect;
-(void)clipToRects:(const NSRect *)rects count:(unsigned)count;

-(void)beginPath;
-(void)closePath;
-(void)moveToPoint:(float)x:(float)y;
-(void)addLineToPoint:(float)x:(float)y;
-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise;
-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius;
-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y;

-(void)fillPath;
-(void)fillRects:(const CGRect *)rects count:(unsigned)count;

-(void)setLineWidth:(float)width;

-(void)strokePath;
-(void)strokeRect:(CGRect)rect width:(float)width;

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize;
-(void)moveto:(float)x:(float)y show:(const char *)cString:(int)length;
-(void)showGlyphs:(const CGGlyph *)glyphs:(unsigned)numberOfGlyphs atPoint:(NSPoint)point;
-(void)showGlyphs:(const CGGlyph *)glyphs advances:(const CGSize *)advances count:(unsigned)count;

-(void)beginPage:(const CGRect *)mediaBox;
-(void)endPage;

-(void)setDeviceColorWhite:(float)white alpha:(float)alpha;
-(void)setDeviceColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
-(void)setDeviceColorCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha;

-(void)setCalibratedColorWhite:(float)white alpha:(float)alpha;
-(void)setCalibratedColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState;

-(void)drawRGBAImageInRect:(NSRect)rect width:(int)width height:(int)height data:(unsigned int *)data fraction:(float)fraction;

-(void)bitCopyToPoint:(NSPoint)dstOrigin renderingContext:(CGRenderingContext *)renderingContext fromPoint:(NSPoint)srcOrigin size:(NSSize)size;

-(void)beginDocument;
-(void)scalePage:(float)scalex:(float)scaley;
-(void)endDocument;

@end

@implementation CGContext

@end

void CGContextSaveGState(CGContext *context){
   [context saveGState];
}

void CGContextRestoreGState(CGContext *context){
   [context restoreGState];
}

CGAffineTransform CGContextGetCTM(CGContext *context) {
   return [context getCTM];
}

void CGContextConcatCTM(CGContext *context,CGAffineTransform transform) {
   [context concatCTM:transform];
}

void CGContextScaleCTM(CGContext *context,float scalex,float scaley){
   [context scaleCTM:scalex:scaley];
}

void CGContextTranslateCTM(CGContext *context,float tx,float ty){
   [context translateCTM:tx:ty];
}

void CGContextRotateCTM(CGContext *context,float radians) {
   [context rotateCTM:radians];
}

CGAffineTransform CGContextGetTextMatrix(CGContextRef context) {
   return [context textMatrix];
}

void CGContextSetTextMatrix(CGContextRef context, CGAffineTransform transform) {
   [context setTextMatrix:transform];
}

void CGContextClipToRect(CGContext *context, CGRect rect){
   [context clipToRect:rect];
}

void CGContextClipToRects(CGContext *context,const CGRect *rects,unsigned count) {
   [context clipToRects:rects count:count];
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

void CGContextAddArc(CGContextRef context,float x,float y,float radius,float startRadian,float endRadian,int clockwise) {
   [context addArc:x:y:radius:startRadian:endRadian:clockwise];
}

void CGContextAddArcToPoint(CGContextRef context,float x1,float y1,float x2,float y2,float radius) {
   [context addArcToPoint:x1:y1:x2:y2:radius];
}


void CGContextAddCurveToPoint(CGContextRef context,float cx1,float cy1,float cx2,float cy2,float x,float y) {
   [context addCurveToPoint:cx1:cy1:cx2:cy2:x:y];
}

void CGContextFillPath(CGContextRef context) {
   [context fillPath];
}

void CGContextFillRect(CGContext *context,CGRect rect) {
   [context fillRects:&rect count:1];
}

void CGContextFillRects(CGContext *context,const CGRect *rects,unsigned count) {
   [context fillRects:rects count:count];
}

void CGContextSetLineWidth(CGContextRef context,float width) {
   [context setLineWidth:width];
}

void CGContextStrokePath(CGContextRef context) {
   [context strokePath];
}

void CGContextStrokeRect(CGContext *context,CGRect rect) {
   [context strokeRect:rect width:1.0];
}

void CGContextStrokeRectWithWidth(CGContext *context,CGRect rect,float width) {
   [context strokeRect:rect width:width];
}

void CGContextSelectFont(CGContext *context,const char *name,float size,CGTextEncoding encoding) {
   [context selectFontWithName:[NSString stringWithCString:name] pointSize:size];
}

void CGContextShowTextAtPoint(CGContext *context,float x,float y,const char *text,unsigned length) {
   [context moveto:x:y show:text:length];
}

void CGContextShowGlyphsAtPoint(CGContext *context,float x,float y,const CGGlyph *glyphs,unsigned count) {
   [context showGlyphs:glyphs:count atPoint:NSMakePoint(x,y)];
}

void CGContextShowGlyphsWithAdvances(CGContextRef context,const CGGlyph *glyphs,const CGSize *advances,unsigned count) {
   [context showGlyphs:glyphs advances:advances count:count];
}

void CGContextBeginPage(CGContext *context,const CGRect *mediaBox) {
   [context beginPage:mediaBox];
}

void CGContextEndPage(CGContext *context) {
   [context endPage];
}

void CGContextSetDeviceGrayColor(CGContext *context,float gray,float alpha) {
   [context setDeviceColorWhite:gray alpha:alpha];
}

void CGContextSetDeviceRGBColor(CGContext *context,float red,float green,float blue,float alpha) {
   [context setDeviceColorRed:red green:green blue:blue alpha:alpha];
}

void CGContextSetDeviceCMYKColor(CGContext *context,float cyan,float magenta,float yellow,float black,float alpha) {
   [context setDeviceColorCyan:cyan magenta:magenta yellow:yellow black:black alpha:alpha];
}

void CGContextSetCalibratedGrayColor(CGContext *context,float gray,float alpha) {
   [context setCalibratedColorWhite:gray alpha:alpha];
}

void CGContextSetCalibratedRGBColor(CGContext *context,float red,float green,float blue,float alpha) {
   [context setCalibratedColorRed:red green:green blue:blue alpha:alpha];
}

void CGContextCopyBits(CGContext *context,CGRect rect,CGPoint point,int gState) {
   [context copyBitsInRect:rect toPoint:point gState:gState];
}

void CGContextSourceOverRGBAImage(CGContext *context,CGRect rect,int width,int height,unsigned int *data,float fraction) {
   [context drawRGBAImageInRect:rect width:width height:height data:data fraction:fraction];
}

void CGContextBitCopy(CGContext *context,NSPoint dstOrigin,CGRenderingContext *renderingContext,NSPoint srcOrigin,NSSize size) {
   [context bitCopyToPoint:dstOrigin renderingContext:renderingContext fromPoint:srcOrigin size:size];
}

void CGContextBeginDocument(CGContext *context) {
   [context beginDocument];
}

void CGContextScalePage(CGContext *context,float scalex,float scaley) {
   [context scalePage:scalex:scaley];
}

void CGContextEndDocument(CGContext *context) {
   [context endDocument];
}

