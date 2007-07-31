/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGContext.h"
#import <AppKit/KGGraphicsState.h>
#import <AppKit/KGRenderingContext.h>
#import "KGMutablePath.h"
#import "KGLayer.h"
#import "KGPDFPage.h"
#import <Foundation/NSRaise.h>

@implementation KGContext

-initWithGraphicsState:(KGGraphicsState *)state {
   _layerStack=[NSMutableArray new];
   _stateStack=[NSMutableArray new];
   [_stateStack addObject:state];
   _path=[[KGMutablePath alloc] init];
   _allowsAntialiasing=YES;
   return self;
}

-(void)dealloc {
   [_layerStack release];
   [_stateStack release];
   [_path release];
   [super dealloc];
}

static inline KGGraphicsState *currentState(KGContext *self){
   return [self->_stateStack lastObject];
}

-(KGRenderingContext *)renderingContext {
   return [currentState(self) renderingContext];
}


-(void)setAllowsAntialiasing:(BOOL)yesOrNo {
   _allowsAntialiasing=yesOrNo;
}

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused {
   NSUnimplementedMethod();
}

-(void)endTransparencyLayer {
   NSUnimplementedMethod();
}

-(BOOL)pathIsEmpty {
   return (_path==nil)?YES:[_path isEmpty];
}

-(NSPoint)pathCurrentPoint {
   return (_path==nil)?NSZeroPoint:[_path currentPoint];
}

-(NSRect)pathBoundingBox {
   return (_path==nil)?NSZeroRect:[_path boundingBox];
}

-(BOOL)pathContainsPoint:(NSPoint)point drawingMode:(int)pathMode {
   CGAffineTransform ctm=[currentState(self) ctm];

// FIX  evenOdd
   return [_path containsPoint:point evenOdd:NO withTransform:&ctm];
}

-(void)beginPath {
   [_path release];
   _path=[[KGMutablePath alloc] init];
}

-(void)closePath {
   [_path closeSubpath];
}

-(void)moveToPoint:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) ctm];
   
   [_path moveToPoint:NSMakePoint(x,y) withTransform:&ctm];
}

-(void)addLineToPoint:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addLineToPoint:NSMakePoint(x,y) withTransform:&ctm];
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addCurveToControlPoint:NSMakePoint(cx1,cy1) controlPoint:NSMakePoint(cx2,cy2) endPoint:NSMakePoint(x,y) withTransform:&ctm];
}

-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addCurveToControlPoint:NSMakePoint(cx1,cy1) endPoint:NSMakePoint(x,y) withTransform:&ctm];
}

-(void)addLinesWithPoints:(NSPoint *)points count:(unsigned)count {
   CGAffineTransform ctm=[currentState(self) ctm];
   
   [_path addLinesWithPoints:points count:count withTransform:&ctm];
}

-(void)addRect:(NSRect)rect {
   CGAffineTransform ctm=[currentState(self) ctm];
   
   [_path addRect:rect withTransform:&ctm];
}

-(void)addRects:(NSRect *)rect count:(unsigned)count {
   CGAffineTransform ctm=[currentState(self) ctm];
   
   [_path addRects:rect count:count withTransform:&ctm];
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addArcAtPoint:NSMakePoint(x,y) radius:radius startAngle:startRadian endAngle:endRadian clockwise:clockwise withTransform:&ctm];
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addArcToPoint:NSMakePoint(x1,y1) point:NSMakePoint(x2,y2) radius:radius withTransform:&ctm];
}

-(void)addEllipseInRect:(NSRect)rect {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addEllipseInRect:rect withTransform:&ctm];
}

-(void)addPath:(KGPath *)path {
   CGAffineTransform ctm=[currentState(self) ctm];

   [_path addPath:path withTransform:&ctm];
}

-(void)replacePathWithStrokedPath {
   NSUnimplementedMethod();
}

-(void)saveGState {
   KGGraphicsState *current=currentState(self),*next;

   [current save];
   next=[current copy];
   [_stateStack addObject:next];
   [next release];
}

-(void)restoreGState {
   [_stateStack removeLastObject];
   [currentState(self) restore];
}

-(CGAffineTransform)userSpaceToDeviceSpaceTransform {
   [currentState(self) userSpaceToDeviceSpaceTransform];
}

-(void)getCTM:(CGAffineTransform *)matrix {
   *matrix=currentState(self)->_ctm;
}

-(CGAffineTransform)ctm {
   return [currentState(self) ctm];
}

-(NSRect)clipBoundingBox {
   [currentState(self) clipBoundingBox];
}

-(CGAffineTransform)textMatrix {
   return [currentState(self) textMatrix];
}

-(int)interpolationQuality {
   return [currentState(self) interpolationQuality];
}

-(NSPoint)textPosition {
   return [currentState(self) textPosition];
}

-(NSPoint)convertPointToDeviceSpace:(NSPoint)point {
   return [currentState(self) convertPointToDeviceSpace:point];
}

-(NSPoint)convertPointToUserSpace:(NSPoint)point {
   return [currentState(self) convertPointToUserSpace:point];
}

-(NSSize)convertSizeToDeviceSpace:(NSSize)size {
   return [currentState(self) convertSizeToDeviceSpace:size];
}

-(NSSize)convertSizeToUserSpace:(NSSize)size {
   return [currentState(self) convertSizeToUserSpace:size];
}

-(NSRect)convertRectToDeviceSpace:(NSRect)rect {
   return [currentState(self) convertRectToDeviceSpace:rect];
}

-(NSRect)convertRectToUserSpace:(NSRect)rect {
   return [currentState(self) convertRectToUserSpace:rect];
}

-(void)concatCTM:(CGAffineTransform)transform {
   [currentState(self) concatCTM:transform];
}

-(void)translateCTM:(float)tx:(float)ty {
   [currentState(self) translateCTM:tx:ty];
}

-(void)scaleCTM:(float)scalex:(float)scaley {
   [currentState(self) scaleCTM:scalex:scaley];
}

-(void)rotateCTM:(float)radians {
   [currentState(self) rotateCTM:radians];
}

-(void)clipToPath {
   if([_path numberOfOperators]==0)
    return;
    
   [currentState(self) clipToPath:_path];
   [_path reset];
}

-(void)evenOddClipToPath {
   if([_path numberOfOperators]==0)
    return;

   [currentState(self) evenOddClipToPath:_path];
   [_path reset];
}

-(void)clipToMask:(KGImage *)image inRect:(NSRect)rect {
   [currentState(self) clipToMask:image inRect:rect];
}

-(void)clipToRect:(NSRect)rect {
   [currentState(self) clipToRect:rect];
   [_path reset];
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   [currentState(self) clipToRects:rects count:count];
   [_path reset];
}

-(KGColor *)strokeColor {
   return [currentState(self) strokeColor];
}

-(KGColor *)fillColor {
   return [currentState(self) fillColor];
}

-(void)setStrokeColorSpace:(KGColorSpace *)colorSpace {
   [currentState(self) setStrokeColorSpace:colorSpace];
}

-(void)setFillColorSpace:(KGColorSpace *)colorSpace {
   [currentState(self) setFillColorSpace:colorSpace];
}

-(void)setStrokeColorWithComponents:(const float *)components {
   [currentState(self) setStrokeColorWithComponents:components];
}

-(void)setStrokeColor:(KGColor *)color {
   [currentState(self) setStrokeColor:color];
}

-(void)setGrayStrokeColor:(float)gray:(float)alpha {
   [currentState(self) setGrayStrokeColor:gray:alpha];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b:(float)alpha {
   [currentState(self) setRGBStrokeColor:r:g:b:alpha];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   [currentState(self) setCMYKStrokeColor:c:m:y:k:alpha];
}

-(void)setFillColorWithComponents:(const float *)components {
   [currentState(self) setFillColorWithComponents:components];
}

-(void)setFillColor:(KGColor *)color {
   [currentState(self) setFillColor:color];
}

-(void)setGrayFillColor:(float)gray:(float)alpha {
   [currentState(self) setGrayFillColor:gray:alpha];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b:(float)alpha {
   [currentState(self) setRGBFillColor:r:g:b:alpha];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   [currentState(self) setCMYKFillColor:c:m:y:k:alpha];
}

-(void)setStrokeAndFillAlpha:(float)alpha {
   [currentState(self) setStrokeAndFillAlpha:alpha];
}

-(void)setStrokeAlpha:(float)alpha {
   [currentState(self) setStrokeAlpha:alpha];
}

-(void)setGrayStrokeColor:(float)gray {
   [currentState(self) setGrayStrokeColor:gray];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b {
   [currentState(self) setRGBStrokeColor:r:g:b];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k {
   [currentState(self) setCMYKStrokeColor:c:y:m:k];
}

-(void)setFillAlpha:(float)alpha {
   [currentState(self) setFillAlpha:alpha];
}

-(void)setGrayFillColor:(float)gray {
   [currentState(self) setGrayFillColor:gray];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b {
   [currentState(self) setRGBFillColor:r:g:b];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k {
   [currentState(self) setCMYKFillColor:c:y:m:k];
}

-(void)setPatternPhase:(NSSize)phase {
   [currentState(self) setPatternPhase:phase];
}

-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components {
   [currentState(self) setStrokePattern:pattern components:components];
}

-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components {
   [currentState(self) setFillPattern:pattern components:components];
}

-(void)setTextMatrix:(CGAffineTransform)transform {
   [currentState(self) setTextMatrix:transform];
}

-(void)setTextPosition:(float)x:(float)y {
   [currentState(self) setTextPosition:x:y];
}

-(void)setCharacterSpacing:(float)spacing {
   [currentState(self) setCharacterSpacing:spacing];
}

-(void)setTextDrawingMode:(int)textMode {
   [currentState(self) setTextDrawingMode:textMode];
}

-(void)setFont:(KGFont *)font {
   [currentState(self) setFont:font];
}

-(void)setFontSize:(float)size {
   [currentState(self) setFontSize:size];
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding {
   [currentState(self) selectFontWithName:name size:size encoding:encoding];
}

-(void)setShouldSmoothFonts:(BOOL)yesOrNo {
   [currentState(self) setShouldSmoothFonts:yesOrNo];
}

-(void)setLineWidth:(float)width {
   [currentState(self) setLineWidth:width];
}

-(void)setLineCap:(int)lineCap {
   [currentState(self) setLineCap:lineCap];
}

-(void)setLineJoin:(int)lineJoin {
   [currentState(self) setLineJoin:lineJoin];
}

-(void)setMiterLimit:(float)limit {
   [currentState(self) setMiterLimit:limit];
}

-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count {
   [currentState(self) setLineDashPhase:phase lengths:lengths count:count];
}

-(void)setRenderingIntent:(int)intent {
   [currentState(self) setRenderingIntent:intent];
}

-(void)setBlendMode:(int)mode {
   [currentState(self) setBlendMode:mode];
}

-(void)setFlatness:(float)flatness {
   [currentState(self) setFlatness:flatness];
}

-(void)setInterpolationQuality:(int)quality {
   [currentState(self) setInterpolationQuality:quality];
}

-(void)setShadowOffset:(NSSize)offset blur:(float)blur color:(KGColor *)color {
   [currentState(self) setShadowOffset:offset blur:blur color:color];
}

-(void)setShadowOffset:(NSSize)offset blur:(float)blur {
   [currentState(self) setShadowOffset:offset blur:blur];
}

-(void)setShouldAntialias:(BOOL)flag {
   [currentState(self) setShouldAntialias:flag];
}

-(void)strokeLineSegmentsWithPoints:(NSPoint *)points count:(unsigned)count {
   [currentState(self) strokeLineSegmentsWithPoints:points count:count];
}

-(void)strokeRect:(NSRect)rect {
   [currentState(self) strokeRect:rect];
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [currentState(self) strokeRect:rect width:width];
}

-(void)strokeEllipseInRect:(NSRect)rect {
   [currentState(self) strokeEllipseInRect:rect];
}

-(void)fillRect:(NSRect)rect {
   [currentState(self) fillRects:&rect count:1];
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [currentState(self) fillRects:rects count:count];
}

-(void)fillEllipseInRect:(NSRect)rect {
   [currentState(self) fillEllipseInRect:rect];
}

-(void)drawPath:(int)pathMode {
   [currentState(self) drawPath:_path mode:pathMode];
   [_path reset];
}

-(void)strokePath {
   [currentState(self) drawPath:_path mode:KGPathStroke];
   [_path reset];
}

-(void)fillPath {
   [currentState(self) drawPath:_path mode:KGPathFill];
   [_path reset];
}

-(void)evenOddFillPath {
   [currentState(self) drawPath:_path mode:KGPathEOFill];
   [_path reset];
}

-(void)fillAndStrokePath {
   [currentState(self) drawPath:_path mode:KGPathFillStroke];
   [_path reset];
}

-(void)evenOddFillAndStrokePath {
   [currentState(self) drawPath:_path mode:KGPathEOFillStroke];
   [_path reset];
}

-(void)clearRect:(NSRect)rect {
   [currentState(self) clearRect:rect];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   [currentState(self) showGlyphs:glyphs count:count];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y {
   [currentState(self) showGlyphs:glyphs count:count atPoint:x:y];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const NSSize *)advances {
   [currentState(self) showGlyphs:glyphs count:count advances:advances];
}

-(void)showText:(const char *)text length:(unsigned)length {
   [currentState(self) showText:text length:length];
}

-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y {
   [currentState(self) showText:text length:length atPoint:x:y];
}

-(void)drawShading:(KGShading *)shading {
   [currentState(self) drawShading:shading];
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   [currentState(self) drawImage:image inRect:rect];
}

-(void)drawLayer:(KGLayer *)layer atPoint:(NSPoint)point {
   NSSize size=[layer size];
   NSRect rect={point,size};
   
   [self drawLayer:layer inRect:rect];
}

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect {
   [[self renderingContext] drawLayer:layer inRect:rect ctm:[currentState(self) ctm]];
}

-(void)drawPDFPage:(KGPDFPage *)page {
   [page drawInContext:self];
}
   
-(void)flush {
   NSUnimplementedMethod();
}

-(void)synchronize {
   NSUnimplementedMethod();
}

-(void)beginPage:(const NSRect *)mediaBox {
   [[self renderingContext] beginPage];
}

-(void)endPage {
   [[self renderingContext] endPage];
}

// temporary

-(void)resetClip {
   [[self renderingContext] resetClip];
}

-(void)setWordSpacing:(float)spacing {
   [currentState(self) setWordSpacing:spacing];
}

-(void)setTextLeading:(float)leading {
   [currentState(self) setTextLeading:leading];
}

-(void)setCalibratedColorWhite:(float)white alpha:(float)alpha {
   [self setCalibratedColorRed:white green:white blue:white alpha:alpha];
}

-(void)setCalibratedColorRed:(float)r green:(float)g blue:(float)b alpha:(float)alpha {
// NeXT gamma is 2.2 I think, my PC card is probably 1.3. This should be
// assumed = PC card setting
// display = NeXT 2.2
// I think.

   const float assumedGamma=1.3;
   const float displayGamma=2.2;

   r=pow(r,assumedGamma/displayGamma);
   if(r>1.0)
    r=1.0;

   g=pow(g,assumedGamma/displayGamma);
   if(g>1.0)
    g=1.0;

   b=pow(b,assumedGamma/displayGamma);
   if(b>1.0)
    b=1.0;

   [self setRGBStrokeColor:r:g:b:alpha];
   [self setRGBFillColor:r:g:b:alpha];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState {
   [currentState(self) copyBitsInRect:rect toPoint:point];
}

@end
