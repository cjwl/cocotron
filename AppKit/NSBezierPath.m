/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBezierPath.h>
#import <AppKit/KGMutablePath.h>
#import <ApplicationServices/CGContext.h>
#import <ApplicationServices/CGPath.h>
#import <AppKit/NSGraphicsContext.h>
#import <Foundation/NSAffineTransform.h>
#import <Foundation/NSRaise.h>

#import "CoreGraphics.subproj/VGmath.h"

@implementation NSBezierPath

static float           _defaultLineWidth=1.0;
static float           _defaultMiterLimit=10.0;
static float           _defaultFlatness=0.6;
static NSWindingRule   _defaultWindingRule=NSNonZeroWindingRule;
static NSLineCapStyle  _defaultLineCapStyle=NSButtLineCapStyle;
static NSLineJoinStyle _defaultLineJoinStyle=NSMiterLineJoinStyle;

-init {
   _path=CGPathCreateMutable();
   _lineWidth=_defaultLineWidth;
   _miterLimit=_defaultMiterLimit;
   _flatness=_defaultFlatness;
   _windingRule=_defaultWindingRule;
   _lineCapStyle=_defaultLineCapStyle;
   _lineJoinStyle=_defaultLineJoinStyle;
   _dashCount=0;
   _dashes=NULL;
   _dashPhase=0;
   _cachesPath=NO;
   _lineWidthIsDefault=YES;
   _miterLimitIsDefault=YES;
   _flatnessIsDefault=YES;
   _windingRuleIsDefault=YES;
   _lineCapStyleIsDefault=YES;
   _lineJoinStyleIsDefault=YES;
   return self;
}

-(void)dealloc {
   CGPathRelease(_path);
   if(_dashes!=NULL)
    NSZoneFree(NULL,_dashes);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   NSBezierPath *copy=NSCopyObject(self,0,zone);
   
   copy->_path=CGPathCreateMutableCopy(_path);
   if(_dashCount>0){
    int i;
    
    copy->_dashes=NSZoneMalloc(NULL,sizeof(float)*_dashCount);
    for(i=0;i<_dashCount;i++)
     copy->_dashes[i]=_dashes[i];
   }
   
   return copy;
}

+(NSBezierPath *)bezierPath {
   return [[[self alloc] init] autorelease];
}

+(NSBezierPath *)bezierPathWithOvalInRect:(NSRect)rect {
   NSBezierPath *result=[[[self alloc] init] autorelease];
   
   [result appendBezierPathWithOvalInRect:rect];
   
   return result;
}

+(NSBezierPath *)bezierPathWithRect:(NSRect)rect {
   NSBezierPath *result=[[[self alloc] init] autorelease];
   
   [result appendBezierPathWithRect:rect];
   
   return result;
}

+(float)defaultLineWidth {
   return _defaultLineWidth;
}

+(float)defaultMiterLimit {
   return _defaultMiterLimit;
}

+(float)defaultFlatness {
   return _defaultFlatness;
}

+(NSWindingRule)defaultWindingRule {
   return _defaultWindingRule;
}

+(NSLineCapStyle)defaultLineCapStyle {
   return _defaultLineCapStyle;
}

+(NSLineJoinStyle)defaultLineJoinStyle {
   return _defaultLineJoinStyle;
}

+(void)setDefaultLineWidth:(float)width {
   _defaultLineWidth=width;
}

+(void)setDefaultMiterLimit:(float)limit {
   _defaultMiterLimit=limit;
}

+(void)setDefaultFlatness:(float)flatness {
   _defaultFlatness=flatness;
}

+(void)setDefaultWindingRule:(NSWindingRule)rule {
   _defaultWindingRule=rule;
}

+(void)setDefaultLineCapStyle:(NSLineCapStyle)style {
   _defaultLineCapStyle=style;
}

+(void)setDefaultLineJoinStyle:(NSLineJoinStyle)style {
   _defaultLineJoinStyle=style;
}

+(void)fillRect:(NSRect)rect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextSaveGState(context);
   CGContextFillRect(context,rect);
   CGContextRestoreGState(context);
}

+(void)strokeRect:(NSRect)rect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextSaveGState(context);
   CGContextSetLineWidth(context,[self defaultLineWidth]);
   CGContextSetMiterLimit(context,[self defaultMiterLimit]);
   CGContextSetFlatness(context,[self defaultFlatness]);
   CGContextSetLineCap(context,[self defaultLineCapStyle]);
   CGContextSetLineJoin(context,[self defaultLineJoinStyle]);
   CGContextSetLineDash(context,0,NULL,0);
   CGContextStrokeRect(context,rect);
   CGContextRestoreGState(context);
}

+(void)strokeLineFromPoint:(NSPoint)point toPoint:(NSPoint)toPoint {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextBeginPath(context);
   CGContextMoveToPoint(context,point.x,point.y);
   CGContextAddLineToPoint(context,toPoint.x,toPoint.y);
   CGContextStrokePath(context);
}

+(void)drawPackedGlyphs:(const char *)packed atPoint:(NSPoint)point {
   CGContextRef   context=[[NSGraphicsContext currentContext] graphicsPort];
   const CGGlyph *glyphs=(const CGGlyph *)packed;
   unsigned       count;

   for(count=0;glyphs[count]!=0;count++)
    ;
    
   CGContextShowGlyphsAtPoint(context,point.x,point.y,glyphs,count);
}

+(void)clipRect:(NSRect)rect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextClipToRect(context,rect);
}

-(float)lineWidth {
   if(_lineWidthIsDefault)
    return _defaultLineWidth;
   else
    return _lineWidth;
}

-(float)miterLimit {
   if(_miterLimitIsDefault)
    return _defaultMiterLimit;
   else
    return _miterLimit;
}

-(float)flatness {
   if(_flatnessIsDefault)
    return _defaultFlatness;
   else
    return _flatness;
}

-(NSWindingRule)windingRule {
   if(_windingRuleIsDefault)
    return _defaultWindingRule;
   else
    return _windingRule;
}

-(NSLineCapStyle)lineCapStyle {
   if(_lineCapStyleIsDefault)
    return _defaultLineCapStyle;
   else
    return _lineCapStyle;
}

-(NSLineJoinStyle)lineJoinStyle {
   if(_lineJoinStyleIsDefault)
    return _defaultLineJoinStyle;
   else
    return _lineJoinStyle;
}

-(void)getLineDash:(float *)dashes count:(int *)count phase:(float *)phase {
   if(dashes!=NULL){
    int i;
    
    for(i=0;i<_dashCount;i++)
     dashes[i]=_dashes[i];
   }
   if(count!=NULL)
    *count=_dashCount;
   if(phase!=NULL)
    *phase=_dashPhase;
}

-(BOOL)cachesBezierPath {
   return _cachesPath;
}

-(int)elementCount {
   return [_path numberOfElements];
}

-(NSBezierPathElement)elementAtIndex:(int)index {
   if(index>=[_path numberOfElements])
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,[_path numberOfElements]];

   return [_path elements][index];
}

static int numberOfPointsForOperator(int op){
   switch(op){
    case kCGPathElementMoveToPoint: return 1;
    case kCGPathElementAddLineToPoint: return 1;
    case kCGPathElementAddCurveToPoint: return 3;
    case kCGPathElementAddQuadCurveToPoint: return 2;
    case kCGPathElementCloseSubpath: return 0;
   }
   return 0;
}

-(NSBezierPathElement)elementAtIndex:(int)index associatedPoints:(NSPoint *)associated {
   const unsigned char *elements=[_path elements];
   const CGPoint       *points=[_path points];
   int                  i,pi=0,pcount;
   
   if(index>=[_path numberOfElements])
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,[_path numberOfElements]];
    
   for(i=0;i<index;i++)
    pi+=numberOfPointsForOperator(elements[i]);
    
   pcount=numberOfPointsForOperator(elements[i]);
   for(i=0;i<pcount;i++,pi++)
    associated[i]=points[pi];
    
   return elements[index];
}

-(void)setLineWidth:(float)width {
   _lineWidth=width;
   _lineWidthIsDefault=NO;
}

-(void)setMiterLimit:(float)limit {
   _miterLimit=limit;
   _miterLimitIsDefault=NO;
}

-(void)setFlatness:(float)flatness {
   _flatness=flatness;
   _flatnessIsDefault=NO;
}

-(void)setWindingRule:(NSWindingRule)rule {
   _windingRule=rule;
   _windingRuleIsDefault=NO;
}

-(void)setLineCapStyle:(NSLineCapStyle)style {
   _lineCapStyle=style;
   _lineCapStyleIsDefault=NO;
}

-(void)setLineJoinStyle:(NSLineJoinStyle)style {
   _lineJoinStyle=style;
   _lineJoinStyleIsDefault=NO;
}

-(void)setLineDash:(const float *)dashes count:(int)count phase:(float)phase {
   if(_dashes!=NULL)
    NSZoneFree(NULL,_dashes);
    
   _dashCount=count;
   if(_dashCount==0)
    _dashes=NULL;
   else {
    int i;
   
    _dashes=NSZoneMalloc(NULL,sizeof(float)*_dashCount);
    for(i=0;i<_dashCount;i++)
     _dashes[i]=dashes[i];
   }
   
   _dashPhase=phase;
}

-(void)setCachesBezierPath:(BOOL)flag {
   _cachesPath=flag;
}

-(BOOL)isEmpty {
   return CGPathIsEmpty(_path);
}

-(NSRect)bounds {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(NSRect)controlPointBounds {
   return CGPathGetBoundingBox(_path);
}

-(BOOL)containsPoint:(NSPoint)point {
   BOOL evenOdd=([self windingRule]==NSEvenOddWindingRule)?YES:NO;
   
   return CGPathContainsPoint(_path,NULL,point,evenOdd);
}

-(NSPoint)currentPoint {
   return CGPathGetCurrentPoint(_path);
}

-(void)moveToPoint:(NSPoint)point {
   CGPathMoveToPoint(_path,NULL,point.x,point.y);
}

-(void)lineToPoint:(NSPoint)point {
   CGPathAddLineToPoint(_path,NULL,point.x,point.y);
}

-(void)curveToPoint:(NSPoint)point controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2 {
   [_path addCurveToControlPoint:cp1 controlPoint:cp2 endPoint:point withTransform:NULL];
}

-(void)closePath {
   CGPathCloseSubpath(_path);
}

-(void)relativeMoveToPoint:(NSPoint)point {
   [_path relativeMoveToPoint:point withTransform:NULL];
}

-(void)relativeLineToPoint:(NSPoint)point {
   [_path addRelativeLineToPoint:point withTransform:NULL];
}

-(void)relativeCurveToPoint:(NSPoint)point controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2 {
   [_path addRelativeCurveToControlPoint:point controlPoint:cp1 endPoint:cp2 withTransform:NULL];
}

-(void)appendBezierPathWithPoints:(NSPoint *)points count:(unsigned)count {
   CGPathAddLines(_path,NULL,points,count);
}

-(void)appendBezierPathWithRect:(NSRect)rect {
   CGPathAddRect(_path,NULL,rect);
}

-(void)appendBezierPathWithOvalInRect:(NSRect)rect {
   CGPathAddEllipseInRect(_path,NULL,rect);
}

-(void)appendBezierPathWithArcFromPoint:(NSPoint)point toPoint:(NSPoint)toPoint radius:(float)radius {
   CGPathAddArcToPoint(_path,NULL,point.x,point.y,toPoint.x,toPoint.y,radius);
}

static inline CGFloat degreesToRadians(CGFloat degrees){
   return degrees*M_PI/180.0;
}

-(void)appendBezierPathWithArcWithCenter:(NSPoint)center radius:(float)radius startAngle:(float)startAngle endAngle:(float)endAngle {
   CGPathAddArc(_path,NULL,center.x,center.y,radius,degreesToRadians(startAngle),degreesToRadians(endAngle),YES);
}

-(void)appendBezierPathWithArcWithCenter:(NSPoint)center radius:(float)radius startAngle:(float)startAngle endAngle:(float)endAngle clockwise:(BOOL)clockwise {
   CGPathAddArc(_path,NULL,center.x,center.y,radius,degreesToRadians(startAngle),degreesToRadians(endAngle),clockwise);
}

-(void)appendBezierPathWithGlyph:(NSGlyph)glyph inFont:(NSFont *)font {
   [self appendBezierPathWithGlyphs:&glyph count:1 inFont:font];
}

-(void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs count:(unsigned)count inFont:(NSFont *)font {
   NSUnimplementedMethod();
}

-(void)appendBezierPathWithPackedGlyphs:(const char *)packed {
//   NSGlyph *glyphs;
//   unsigned count=0;
   
// FIX, unpack glyphs
// does this use the current font?
//   [self appendBezierPathWithGlyphs:glyphs count:count inFont:font];
   NSUnimplementedMethod();
}

-(void)appendBezierPath:(NSBezierPath *)other {
   CGPathAddPath(_path,NULL,other->_path);
}

-(void)transformUsingAffineTransform:(NSAffineTransform *)matrix {
   NSAffineTransformStruct atStruct=[matrix transformStruct];
   CGAffineTransform       cgMatrix;
   
   cgMatrix.a=atStruct.m11;
   cgMatrix.b=atStruct.m12;
   cgMatrix.c=atStruct.m21;
   cgMatrix.d=atStruct.m22;
   cgMatrix.tx=atStruct.tX;
   cgMatrix.ty=atStruct.tY;
   
   [_path applyTransform:cgMatrix];
}

-(void)removeAllPoints {
   [_path reset];
}

-(void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index {
   const unsigned char *elements=[_path elements];
   int                  i,pi=0,pcount;
   
   if(index>=[_path numberOfElements])
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,[_path numberOfElements]];
    
   for(i=0;i<index;i++)
    pi+=numberOfPointsForOperator(elements[i]);
    
   pcount=numberOfPointsForOperator(elements[i]);
   
   [_path setPoints:points count:pcount atIndex:pi];
}

-(NSBezierPath *)bezierPathByFlatteningPath {
   NSUnimplementedMethod();
   return nil;
}

-(NSBezierPath *)bezierPathByReversingPath {
   NSUnimplementedMethod();
   return nil;
}

-(void)stroke {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextSaveGState(context);
   CGContextSetLineWidth(context,[self lineWidth]);
   CGContextSetMiterLimit(context,[self miterLimit]);
   CGContextSetFlatness(context,[self flatness]);
   CGContextSetLineCap(context,[self lineCapStyle]);
   CGContextSetLineJoin(context,[self lineJoinStyle]);
   CGContextSetLineDash(context,_dashPhase,_dashes,_dashCount);
   CGContextBeginPath(context);
   CGContextAddPath(context,_path);
   CGContextStrokePath(context);
   CGContextRestoreGState(context);
}

-(void)fill {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextBeginPath(context);
   CGContextAddPath(context,_path);
   if([self windingRule]==NSNonZeroWindingRule)
    CGContextFillPath(context);
   else
    CGContextEOFillPath(context);
}

-(void)addClip {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   if(CGContextIsPathEmpty(context))
    CGContextBeginPath(context);
   CGContextAddPath(context,_path);
   CGContextClip(context);
}

-(void)setClip {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   CGContextBeginPath(context);
   CGContextAddPath(context,_path);
   CGContextClip(context);
}

@end
