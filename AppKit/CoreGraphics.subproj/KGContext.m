/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGContext.h"
#import <AppKit/KGGraphicsState.h>
#import <AppKit/KGColor.h>
#import <AppKit/KGColorSpace.h>
#import <AppKit/KGFont.h>
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

-init {
   return [self initWithGraphicsState:[[[KGGraphicsState alloc] init] autorelease]];
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
   [self addRects:&rect count:1];
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

-(void)translateCTM:(float)translatex:(float)translatey {
   [self concatCTM:CGAffineTransformMakeTranslation(translatex,translatey)];
}

-(void)scaleCTM:(float)scalex:(float)scaley {
   [self concatCTM:CGAffineTransformMakeScale(scalex,scaley)];
}

-(void)rotateCTM:(float)radians {
   [self concatCTM:CGAffineTransformMakeRotation(radians)];
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
   [self clipToRects:&rect count:1];
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
   KGColor *color=[[KGColor alloc] initWithColorSpace:colorSpace];
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setFillColorSpace:(KGColorSpace *)colorSpace {
   KGColor *color=[[KGColor alloc] initWithColorSpace:colorSpace];

   [self setFillColor:color];
   
   [color release];
}

-(void)setStrokeColorWithComponents:(const float *)components {
   KGColorSpace *colorSpace=[[self strokeColor] colorSpace];
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setStrokeColor:(KGColor *)color {
   [currentState(self) setStrokeColor:color];
}

-(void)setGrayStrokeColor:(float)gray:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setFillColorWithComponents:(const float *)components {
   KGColorSpace *colorSpace=[[self fillColor] colorSpace];
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
}

-(void)setFillColor:(KGColor *)color {
   [currentState(self) setFillColor:color];
}

-(void)setGrayFillColor:(float)gray:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setStrokeAndFillAlpha:(float)alpha {
   [self setStrokeAlpha:alpha];
   [self setFillAlpha:alpha];
}

-(void)setStrokeAlpha:(float)alpha {
   KGColor *color=[[self strokeColor] copyWithAlpha:alpha];
   [self setStrokeColor:color];
   [color release];
}

-(void)setGrayStrokeColor:(float)gray {
   float alpha=[[self strokeColor] alpha];
   
   [self setGrayStrokeColor:gray:alpha];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b {
   float alpha=[[self strokeColor] alpha];
   [self setRGBStrokeColor:r:g:b:alpha];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=[[self strokeColor] alpha];
   [self setCMYKStrokeColor:c:m:y:k:alpha];
}

-(void)setFillAlpha:(float)alpha {
   KGColor *color=[[self fillColor] copyWithAlpha:alpha];
   [self setFillColor:color];
   [color release];
}

-(void)setGrayFillColor:(float)gray {
   float alpha=[[self fillColor] alpha];
   [self setGrayFillColor:gray:alpha];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b {
   float alpha=[[self fillColor] alpha];
   [self setRGBFillColor:r:g:b:alpha];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=[[self fillColor] alpha];
   [self setCMYKFillColor:c:m:y:k:alpha];
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
   NSString *name=[[currentState(self) font] name];
   KGFont   *font=[[KGFont alloc] initWithName:name size:size];
   
   [self setFont:font];
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding {
   KGFont *font=[[KGFont alloc] initWithName:[NSString stringWithCString:name] size:size];
   
   [self setFont:font];
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

-(void)setRenderingIntent:(CGColorRenderingIntent)intent {
   [currentState(self) setRenderingIntent:intent];
}

-(void)setBlendMode:(int)mode {
   [currentState(self) setBlendMode:mode];
}

-(void)setFlatness:(float)flatness {
   [currentState(self) setFlatness:flatness];
}

-(void)setInterpolationQuality:(CGInterpolationQuality)quality {
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
   int i;
   
   [self beginPath];
   for(i=0;i<count;i+=2){
    [self moveToPoint:points[i].x:points[i].y];
    [self addLineToPoint:points[i+1].x:points[i+1].y];
   }
   [self strokePath];
}

-(void)strokeRect:(NSRect)rect {
   [self beginPath];
   [self addRect:rect];
   [self strokePath];
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [self saveGState];
   [self setLineWidth:width];
   [self beginPath];
   [self addRect:rect];
   [self strokePath];
   [self restoreGState];
}

-(void)strokeEllipseInRect:(NSRect)rect {
   [self beginPath];
   [self addEllipseInRect:rect];
   [self strokePath];
}

-(void)fillRect:(NSRect)rect {
   [self fillRects:&rect count:1];
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [self beginPath];
   [self addRects:rects count:count];
   [self fillPath];
}

-(void)fillEllipseInRect:(NSRect)rect {
   [self beginPath];
   [self addEllipseInRect:rect];
   [self fillPath];
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   NSInvalidAbstractInvocation();
// reset path in subclass
}

-(void)strokePath {
   [self drawPath:KGPathStroke];
}

-(void)fillPath {
   [self drawPath:KGPathFill];
}

-(void)evenOddFillPath {
   [self drawPath:KGPathEOFill];
}

-(void)fillAndStrokePath {
   [self drawPath:KGPathFillStroke];
}

-(void)evenOddFillAndStrokePath {
   [self drawPath:KGPathEOFillStroke];
}

-(void)clearRect:(NSRect)rect {
   NSInvalidAbstractInvocation();
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   NSInvalidAbstractInvocation();
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y {
   [self setTextPosition:x:y];
   [self showGlyphs:glyphs count:count];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const NSSize *)advances {
   CGAffineTransform textMatrix=[currentState(self) textMatrix];
   float             x=textMatrix.tx;
   float             y=textMatrix.ty;
   int i;
   
   for(i=0;i<count;i++){
    [self showGlyphs:glyphs+i count:1];
    
    x+=advances[i].width;
    y+=advances[i].height;
    [self setTextPosition:x:y];
   }
}

-(void)showText:(const char *)text length:(unsigned)length {
   unichar unicode[length];
   CGGlyph glyphs[length];
   int     i;
   
// FIX, encoding
   for(i=0;i<length;i++)
    unicode[i]=text[i];
    
   [[currentState(self) font] getGlyphs:glyphs forCharacters:unicode length:length];
   [self showGlyphs:glyphs count:length];
}

-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y {
   [self setTextPosition:x:y];
   [self showText:text length:length];
}

-(void)drawShading:(KGShading *)shading {
   NSInvalidAbstractInvocation();
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   NSInvalidAbstractInvocation();
}

-(void)drawLayer:(KGLayer *)layer atPoint:(NSPoint)point {
   NSSize size=[layer size];
   NSRect rect={point,size};
   
   [self drawLayer:layer inRect:rect];
}

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect {
   NSInvalidAbstractInvocation();
}

-(void)drawPDFPage:(KGPDFPage *)page {
   [page drawInContext:self];
}
   
-(void)flush {
   // do nothing
}

-(void)synchronize {
   // do nothing
}

-(void)beginPage:(const NSRect *)mediaBox {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(KGLayer *)layerWithSize:(NSSize)size unused:(NSDictionary *)unused {
   NSUnimplementedMethod();
}

-(void)beginPrintingWithDocumentName:(NSString *)documentName {
   NSUnimplementedMethod();
}

-(void)endPrinting {
   NSUnimplementedMethod();
}

-(BOOL)getImageableRect:(NSRect *)rect {
   NSUnimplementedMethod();
}

// temporary

-(void)drawContext:(KGContext *)other inRect:(CGRect)rect {
   NSUnimplementedMethod();
}

-(void)resetClip {
   [currentState(self) resetClip];
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
// lame gamma adjustment so that non-system colors appear similar to those on a Mac

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
   NSInvalidAbstractInvocation();
}

@end
