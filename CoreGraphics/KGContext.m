/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGContext.h"
#import "kGBitmapContext.h"
#import "KGGraphicsState.h"
#import "O2Color.h"
#import "O2ColorSpace.h"
#import "O2MutablePath.h"
#import "KGLayer.h"
#import "KGPDFPage.h"
#import "KGClipPhase.h"
#import "KGExceptions.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>

@implementation O2Context

static NSMutableArray *possibleContextClasses=nil;

+(void)initialize {
   if(possibleContextClasses==nil){
    possibleContextClasses=[NSMutableArray new];
    
    [possibleContextClasses addObject:@"KGContext_gdi"];
    [possibleContextClasses addObject:@"KGContext_builtin"];
    [possibleContextClasses addObject:@"KGContext_builtin_gdi"];
    
    NSArray *allPaths=[[NSBundle bundleForClass:self] pathsForResourcesOfType:@"cgContext" inDirectory:nil];
    int      i,count=[allPaths count];
    
    for(i=0;i<count;i++){
     NSString *path=[allPaths objectAtIndex:i];
     NSBundle *check=[NSBundle bundleWithPath:path];
     Class     cls=[check principalClass];
     
     if(cls!=Nil)
      [possibleContextClasses addObject:NSStringFromClass([check principalClass])];
    }
   }
}

+(NSArray *)allContextClasses {
   NSMutableArray *result=[NSMutableArray array];
   int             i,count=[possibleContextClasses count];
   
   for(i=0;i<count;i++){
    Class check=NSClassFromString([possibleContextClasses objectAtIndex:i]);
    
    if(check!=Nil)
     [result addObject:check];
   }
   
   return result;
}

+(O2Context *)createContextWithSize:(CGSize)size window:(CGWindow *)window {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
    
    if([check canInitWithWindow:window]){
     O2Context *result=[[check alloc] initWithSize:size window:window];
     
     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

+(O2Context *)createBackingContextWithSize:(CGSize)size context:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
    
    if([check canInitBackingWithContext:context deviceDictionary:deviceDictionary]){
     O2Context *result=[[check alloc] initWithSize:size context:context];

     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

+(O2Context *)createWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
    
    if([check canInitBitmap]){
     O2Context *result=[[check alloc] initWithBytes:bytes width:width height:height bitsPerComponent:bitsPerComponent bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo flipped:NO];

     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

+(BOOL)canInitWithWindow:(CGWindow *)window {
   return NO;
}

+(BOOL)canInitBackingWithContext:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   return NO;
}

+(BOOL)canInitBitmap {
   return NO;
}

-initWithSize:(CGSize)size window:(CGWindow *)window {
   KGInvalidAbstractInvocation();
   return nil;
}

-initWithSize:(CGSize)size context:(O2Context *)context {
   KGInvalidAbstractInvocation();
   return nil;
}

-initWithGraphicsState:(O2GState *)state {
   _userToDeviceTransform=[state userSpaceToDeviceSpaceTransform];
   _layerStack=[NSMutableArray new];
   _stateStack=[NSMutableArray new];
   [_stateStack addObject:state];
   _path=[[O2MutablePath alloc] init];
   _allowsAntialiasing=YES;
   return self;
}

-init {
   return [self initWithGraphicsState:[[[O2GState alloc] init] autorelease]];
}

-(void)dealloc {
   [_layerStack release];
   [_stateStack release];
   [_path release];
   [super dealloc];
}

static inline O2GState *currentState(O2Context *self){        
   return [self->_stateStack lastObject];
}

-(KGSurface *)surface {
   return nil;
}

-(KGSurface *)createSurfaceWithWidth:(size_t)width height:(size_t)height {
   return nil;
}

-(void)setAllowsAntialiasing:(BOOL)yesOrNo {
   _allowsAntialiasing=yesOrNo;
}

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused {
   KGUnimplementedMethod();
}

-(void)endTransparencyLayer {
   KGUnimplementedMethod();
}

-(BOOL)pathIsEmpty {
   return (_path==nil)?YES:O2PathIsEmpty(_path);
}

-(CGPoint)pathCurrentPoint {
   return (_path==nil)?CGPointZero:O2PathGetCurrentPoint(_path);
}

-(CGRect)pathBoundingBox {
   return (_path==nil)?CGRectZero:O2PathGetBoundingBox(_path);
}

-(BOOL)pathContainsPoint:(CGPoint)point drawingMode:(int)pathMode {
   CGAffineTransform ctm=[currentState(self) userSpaceToDeviceSpaceTransform];

// FIX  evenOdd
   return O2PathContainsPoint(_path,&ctm,point,NO);
}

-(void)beginPath {
   O2PathReset(_path);
}

-(void)closePath {
   O2PathCloseSubpath(_path);
}

/* Path building is affected by the CTM, we transform them here into base coordinates (first quadrant, no transformation)

   A backend can then convert them to where it needs them, base,  current, or device space.
 */

-(void)moveToPoint:(float)x:(float)y {      
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathMoveToPoint(_path,&ctm,x,y);
}

-(void)addLineToPoint:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddLineToPoint(_path,&ctm,x,y);
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddCurveToPoint(_path,&ctm,cx1,cy1,cx2,cy2,x,y);
}

-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddQuadCurveToPoint(_path,&ctm,cx1,cy1,x,y);
}

-(void)addLinesWithPoints:(CGPoint *)points count:(unsigned)count {   
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddLines(_path,&ctm,points,count);
}

-(void)addRect:(CGRect)rect {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddRect(_path,&ctm,rect);
}

-(void)addRects:(const CGRect *)rects count:(unsigned)count {   
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddRects(_path,&ctm,rects,count);
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddArc(_path,&ctm,x,y,radius,startRadian,endRadian,clockwise);
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddArcToPoint(_path,&ctm,x1,y1,x2,y2,radius);
}

-(void)addEllipseInRect:(CGRect)rect {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddEllipseInRect(_path,&ctm,rect);
}

-(void)addPath:(O2Path *)path {
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathAddPath(_path,&ctm,path);
}

-(void)replacePathWithStrokedPath {
   KGUnimplementedMethod();
}

-(O2GState *)currentState {
   return currentState(self);
}

-(void)saveGState {
   O2GState *current=currentState(self),*next;

   next=[current copy];
   [_stateStack addObject:next];
   [next release];
}

-(void)restoreGState {
   [_stateStack removeLastObject];

   NSArray *phases=[[self currentState] clipPhases];
   int      i,count=[phases count];
   
   [self deviceClipReset];
   
   for(i=0;i<count;i++){
    O2ClipPhase *phase=[phases objectAtIndex:i];
    
    switch([phase phaseType]){
    
     case O2ClipPhaseNonZeroPath:{
       O2Path *path=[phase object];
       [self deviceClipToNonZeroPath:path];
      }
      break;
      
     case O2ClipPhaseEOPath:{
       O2Path *path=[phase object];
       [self deviceClipToEvenOddPath:path];
      }
      break;
      
     case O2ClipPhaseMask:
      break;
    }
    
   }
}

-(CGAffineTransform)userSpaceToDeviceSpaceTransform {
   return [currentState(self) userSpaceToDeviceSpaceTransform];
}

-(CGAffineTransform)ctm {
   return [currentState(self) userSpaceTransform];
}

-(CGRect)clipBoundingBox {
   return [currentState(self) clipBoundingBox];
}

-(CGAffineTransform)textMatrix {
   return [currentState(self) textMatrix];
}

-(int)interpolationQuality {
   return [currentState(self) interpolationQuality];
}

-(CGPoint)textPosition {
   return [currentState(self) textPosition];
}

-(CGPoint)convertPointToDeviceSpace:(CGPoint)point {
   return [currentState(self) convertPointToDeviceSpace:point];
}

-(CGPoint)convertPointToUserSpace:(CGPoint)point {
   return [currentState(self) convertPointToUserSpace:point];
}

-(CGSize)convertSizeToDeviceSpace:(CGSize)size {
   return [currentState(self) convertSizeToDeviceSpace:size];
}

-(CGSize)convertSizeToUserSpace:(CGSize)size {
   return [currentState(self) convertSizeToUserSpace:size];
}

-(CGRect)convertRectToDeviceSpace:(CGRect)rect {
   return [currentState(self) convertRectToDeviceSpace:rect];
}

-(CGRect)convertRectToUserSpace:(CGRect)rect {
   return [currentState(self) convertRectToUserSpace:rect];
}

-(void)setCTM:(CGAffineTransform)matrix {
   CGAffineTransform deviceTransform=_userToDeviceTransform;
   
   deviceTransform=CGAffineTransformConcat(matrix,deviceTransform);
   
   [currentState(self) setDeviceSpaceCTM:deviceTransform];

   [currentState(self) setUserSpaceCTM:matrix];
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
   if([_path numberOfElements]==0)
    return;
   
   [currentState(self) addClipToPath:_path];
   [self deviceClipToNonZeroPath:_path];
   O2PathReset(_path);
}

-(void)evenOddClipToPath {
   if([_path numberOfElements]==0)
    return;

   [currentState(self) addEvenOddClipToPath:_path];
   [self deviceClipToEvenOddPath:_path];
   O2PathReset(_path);
}

-(void)clipToMask:(O2Image *)image inRect:(CGRect)rect {
   [currentState(self) addClipToMask:image inRect:rect];
   [self deviceClipToMask:image inRect:rect];
}

-(void)clipToRect:(CGRect)rect {
   [self clipToRects:&rect count:1];
}

-(void)clipToRects:(const CGRect *)rects count:(unsigned)count {   
   CGAffineTransform ctm=[currentState(self) userSpaceTransform];

   O2PathReset(_path);
   O2PathAddRects(_path,&ctm,rects,count);
   [self clipToPath];
}

-(O2Color *)strokeColor {
   return [currentState(self) strokeColor];
}

-(O2Color *)fillColor {
   return [currentState(self) fillColor];
}

-(void)setStrokeColorSpace:(O2ColorSpaceRef)colorSpace {
   int   i,length=[colorSpace numberOfComponents];
   CGFloat components[length+1];
   
   for(i=0;i<length;i++)
    components[i]=0;
   components[i]=1;

   O2Color *color=O2ColorCreate(colorSpace,components);
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setFillColorSpace:(O2ColorSpaceRef)colorSpace {
   int   i,length=[colorSpace numberOfComponents];
   CGFloat components[length+1];
   
   for(i=0;i<length;i++)
    components[i]=0;
   components[i]=1;

   O2Color *color=O2ColorCreate(colorSpace,components);

   [self setFillColor:color];
   
   [color release];
}

-(void)setStrokeColorWithComponents:(const float *)components {
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace([self strokeColor]);
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setStrokeColor:(O2Color *)color {
   [currentState(self) setStrokeColor:color];
}

-(void)setGrayStrokeColor:(float)gray:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setFillColorWithComponents:(const float *)components {
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace([self fillColor]);
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setFillColor:color];
   
   [color release];
}

-(void)setFillColor:(O2Color *)color {
   [currentState(self) setFillColor:color];
}

-(void)setGrayFillColor:(float)gray:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   O2Color      *color=O2ColorCreate(colorSpace,components);
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setStrokeAndFillAlpha:(float)alpha {
   [self setStrokeAlpha:alpha];
   [self setFillAlpha:alpha];
}

-(void)setStrokeAlpha:(float)alpha {
   O2Color *color=O2ColorCreateCopyWithAlpha([self strokeColor],alpha);
   [self setStrokeColor:color];
   [color release];
}

-(void)setGrayStrokeColor:(float)gray {
   float alpha=O2ColorGetAlpha([self strokeColor]);
   
   [self setGrayStrokeColor:gray:alpha];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b {
   float alpha=O2ColorGetAlpha([self strokeColor]);
   [self setRGBStrokeColor:r:g:b:alpha];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=O2ColorGetAlpha([self strokeColor]);
   [self setCMYKStrokeColor:c:m:y:k:alpha];
}

-(void)setFillAlpha:(float)alpha {
   O2Color *color=O2ColorCreateCopyWithAlpha([self fillColor],alpha);
   [self setFillColor:color];
   [color release];
}

-(void)setGrayFillColor:(float)gray {
   float alpha=O2ColorGetAlpha([self fillColor]);
   [self setGrayFillColor:gray:alpha];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b {
   float alpha=O2ColorGetAlpha([self fillColor]);
   [self setRGBFillColor:r:g:b:alpha];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=O2ColorGetAlpha([self fillColor]);
   [self setCMYKFillColor:c:m:y:k:alpha];
}

-(void)setPatternPhase:(CGSize)phase {
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

-(void)setFont:(O2Font *)font {
   [currentState(self) setFont:font];
}

-(void)setFontSize:(float)size {
   [currentState(self) setFontSize:size];
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(CGTextEncoding)encoding {
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

-(void)setShadowOffset:(CGSize)offset blur:(float)blur color:(O2Color *)color {
   [currentState(self) setShadowOffset:offset blur:blur color:color];
}

-(void)setShadowOffset:(CGSize)offset blur:(float)blur {
   [currentState(self) setShadowOffset:offset blur:blur];
}

-(void)setShouldAntialias:(BOOL)flag {
   [currentState(self) setShouldAntialias:flag];
}

-(void)strokeLineSegmentsWithPoints:(CGPoint *)points count:(unsigned)count {
   int i;
   
   [self beginPath];
   for(i=0;i<count;i+=2){
    [self moveToPoint:points[i].x:points[i].y];
    [self addLineToPoint:points[i+1].x:points[i+1].y];
   }
   [self strokePath];
}

-(void)strokeRect:(CGRect)rect {
   [self beginPath];
   [self addRect:rect];
   [self strokePath];
}

-(void)strokeRect:(CGRect)rect width:(float)width {
   [self saveGState];
   [self setLineWidth:width];
   [self beginPath];
   [self addRect:rect];
   [self strokePath];
   [self restoreGState];
}

-(void)strokeEllipseInRect:(CGRect)rect {
   [self beginPath];
   [self addEllipseInRect:rect];
   [self strokePath];
}

-(void)fillRect:(CGRect)rect {
   [self fillRects:&rect count:1];
}

-(void)fillRects:(const CGRect *)rects count:(unsigned)count {
   [self beginPath];
   [self addRects:rects count:count];
   [self fillPath];
}

-(void)fillEllipseInRect:(CGRect)rect {
   [self beginPath];
   [self addEllipseInRect:rect];
   [self fillPath];
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   KGInvalidAbstractInvocation();
// reset path in subclass
}

-(void)strokePath {
   [self drawPath:kCGPathStroke];
}

-(void)fillPath {
   [self drawPath:kCGPathFill];
}

-(void)evenOddFillPath {
   [self drawPath:kCGPathEOFill];
}

-(void)fillAndStrokePath {
   [self drawPath:kCGPathFillStroke];
}

-(void)evenOddFillAndStrokePath {
   [self drawPath:kCGPathEOFillStroke];
}

-(void)clearRect:(CGRect)rect {
// doc.s are not clear. tests say CGContextClearRect resets the path and does not affect gstate color
   [self saveGState];
   [self setBlendMode:kCGBlendModeCopy]; // does it set the blend mode?
   [self setGrayFillColor:0:0];
   [self fillRect:rect];
   [self restoreGState];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   KGInvalidAbstractInvocation();
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y {
   [self setTextPosition:x:y];
   [self showGlyphs:glyphs count:count];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const CGSize *)advances {
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
   KGInvalidAbstractInvocation();
}

-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y {
   [self setTextPosition:x:y];
   [self showText:text length:length];
}

-(void)drawShading:(KGShading *)shading {
   KGInvalidAbstractInvocation();
}

-(void)drawImage:(O2Image *)image inRect:(CGRect)rect {
   KGInvalidAbstractInvocation();
}

-(void)drawLayer:(KGLayer *)layer atPoint:(CGPoint)point {
   CGSize size=[layer size];
   CGRect rect={point,size};
   
   [self drawLayer:layer inRect:rect];
}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
   KGInvalidAbstractInvocation();
}

-(void)drawPDFPage:(O2PDFPage *)page {
   [page drawInContext:self];
}
   
-(void)flush {
   // do nothing
}

-(void)synchronize {
   // do nothing
}

-(void)beginPage:(const CGRect *)mediaBox {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(void)close {
   // do nothing
}

-(KGLayer *)layerWithSize:(CGSize)size unused:(NSDictionary *)unused {
   KGInvalidAbstractInvocation();
   return nil;
}

-(BOOL)getImageableRect:(CGRect *)rect {
   return NO;
}

// bitmap context 

-(NSData *)pixelData {
   return nil;
}

-(void *)pixelBytes {
   return NULL;
}

-(size_t)width {
   return 0;
}

-(size_t)height {
   return 0;
}

-(size_t)bitsPerComponent {
   return 0;
}

-(size_t)bytesPerRow {
   return 0;
}

-(O2ColorSpaceRef)colorSpace {
   return nil;
}

-(CGBitmapInfo)bitmapInfo {
   return 0;
}

-(size_t)bitsPerPixel {
   return 0;
}

-(CGImageAlphaInfo)alphaInfo {
   return 0;
}

-(O2Image *)createImage {
   return nil;
}

// temporary

-(void)drawBackingContext:(O2Context *)other size:(CGSize)size {
   KGInvalidAbstractInvocation();
}

-(void)resetClip {
   [[self currentState] removeAllClipPhases];
   [self deviceClipReset];
}

-(void)setAntialiasingQuality:(int)value {
   [currentState(self) setAntialiasingQuality:value];
}

-(void)setWordSpacing:(float)spacing {
   [currentState(self) setWordSpacing:spacing];
}

-(void)setTextLeading:(float)leading {
   [currentState(self) setTextLeading:leading];
}

-(void)copyBitsInRect:(CGRect)rect toPoint:(CGPoint)point gState:(int)gState {
   KGInvalidAbstractInvocation();
}

-(NSData *)captureBitmapInRect:(CGRect)rect {
   KGInvalidAbstractInvocation();
   return nil;
}

/*
  Notes: OSX generates a clip mask at fill time using the current aliasing setting. Once the fill is complete the clip mask persists with the next clip/fill. This means you can turn off AA, create a clip path, fill, turn on AA, create another clip path, fill, and edges from the first path will be aliased, and ones from the second will not. PDF does not dictate aliasing behavior, so while this is not really expected behavior, it is not a bug. 
    
 */
 
-(void)deviceClipReset {
   KGInvalidAbstractInvocation();
}

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   KGInvalidAbstractInvocation();
}

-(void)deviceClipToEvenOddPath:(O2Path *)path {
   KGInvalidAbstractInvocation();
}

-(void)deviceClipToMask:(O2Image *)mask inRect:(CGRect)rect {
   KGInvalidAbstractInvocation();
}

@end
