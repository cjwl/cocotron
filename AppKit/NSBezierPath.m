/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBezierPath.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/NSGraphicsContext.h>
#import <Foundation/NSAffineTransform.h>
#import <AppKit/NSRaise.h>

@implementation NSBezierPath

static float           _defaultLineWidth=1.0;
static float           _defaultMiterLimit=10.0;
static float           _defaultFlatness=0.6;
static NSWindingRule   _defaultWindingRule=NSNonZeroWindingRule;
static NSLineCapStyle  _defaultLineCapStyle=NSButtLineCapStyle;
static NSLineJoinStyle _defaultLineJoinStyle=NSMiterLineJoinStyle;

-init {
   _capacityOfElements=16;
   _numberOfElements=0;
   _elements=NSZoneMalloc(NULL,_capacityOfElements*sizeof(uint8_t));
   
   _capacityOfPoints=16;
   _numberOfPoints=0;
   _points=NSZoneMalloc(NULL,_capacityOfPoints*sizeof(CGPoint));

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
   NSZoneFree(NULL,_elements);
   NSZoneFree(NULL,_points);

   if(_dashes!=NULL)
    NSZoneFree(NULL,_dashes);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   NSBezierPath *copy=NSCopyObject(self,0,zone);
   NSInteger i;
   
   copy->_elements=NSZoneMalloc(NULL,_capacityOfElements*sizeof(uint8_t));
   for(i=0;i<_numberOfElements;i++)
    copy->_elements[i]=_elements[i];
    
   copy->_points=NSZoneMalloc(NULL,_capacityOfPoints*sizeof(CGPoint));
   for(i=0;i<_numberOfPoints;i++)
    copy->_points[i]=_points[i];

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


+(NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius {
   NSBezierPath *result=[[[self alloc] init] autorelease];
   
   [result appendBezierPathWithRoundedRect:rect xRadius:xRadius yRadius:yRadius];
   
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
   return _numberOfElements;
}

-(NSBezierPathElement)elementAtIndex:(int)index {
   if(index>=_numberOfElements)
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,_numberOfElements];

   return _elements[index];
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
   int i,pi=0,pcount;
   
   if(index>=_numberOfElements)
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,_numberOfElements];
    
   for(i=0;i<index;i++)
    pi+=numberOfPointsForOperator(_elements[i]);
    
   pcount=numberOfPointsForOperator(_elements[i]);
   for(i=0;i<pcount;i++,pi++)
    associated[i]=_points[pi];
    
   return _elements[index];
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
   return (_numberOfElements==0)?YES:NO;
}

-(NSRect)bounds {
   NSUnimplementedMethod();
   return [self controlPointBounds];
}

-(NSRect)controlPointBounds {
   CGRect result;
   int i;
   
   if(_numberOfPoints==0)
    return CGRectZero;
   
   result.origin=_points[0];
   result.size=CGSizeMake(0,0);
   for(i=1;i<_numberOfPoints;i++){
    CGPoint point=_points[i];
    
    if(point.x>CGRectGetMaxX(result))
     result.size.width=point.x-CGRectGetMinX(result);
    else if(point.x<result.origin.x){
     result.size.width=CGRectGetMaxX(result)-point.x;
     result.origin.x=point.x;
    }
    
    if(point.y>CGRectGetMaxY(result))
     result.size.height=point.y-CGRectGetMinY(result);
    else if(point.y<result.origin.y){
     result.size.height=CGRectGetMaxY(result)-point.y;
     result.origin.y=point.y;
    }
   }   

   return result;
}

-(BOOL)containsPoint:(NSPoint)point {   
   NSUnimplementedMethod();
   return NO;
}

-(NSPoint)currentPoint {
// FIXME: this is wrong w/ closepath last
   return (_numberOfPoints==0)?CGPointZero:_points[_numberOfPoints-1];
}

static inline void expandOperatorCapacity(NSBezierPath *self,unsigned delta){
   if(self->_numberOfElements+delta>self->_capacityOfElements){
    self->_capacityOfElements=self->_numberOfElements+delta;
    self->_capacityOfElements=(self->_capacityOfElements/32+1)*32;
    self->_elements=NSZoneRealloc(NULL,self->_elements,self->_capacityOfElements);
   }
}

static inline void expandPointCapacity(NSBezierPath *self,unsigned delta){
   if(self->_numberOfPoints+delta>self->_capacityOfPoints){
    self->_capacityOfPoints=self->_numberOfPoints+delta;
    self->_capacityOfPoints=(self->_capacityOfPoints/64+1)*64;
    self->_points=NSZoneRealloc(NULL,self->_points,self->_capacityOfPoints*sizeof(CGPoint));
   }
}

-(void)moveToPoint:(NSPoint)point {
   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   _elements[_numberOfElements++]=NSMoveToBezierPathElement;
   _points[_numberOfPoints++]=point;
}

-(void)lineToPoint:(NSPoint)point {
   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   _elements[_numberOfElements++]=NSLineToBezierPathElement;
   _points[_numberOfPoints++]=point;
}

-(void)curveToPoint:(NSPoint)point controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2 {
   expandOperatorCapacity(self,1);
   expandPointCapacity(self,3);
   _elements[_numberOfElements++]=NSCurveToBezierPathElement;   
   _points[_numberOfPoints++]=cp1;
   _points[_numberOfPoints++]=cp2;
   _points[_numberOfPoints++]=point;
}

-(void)closePath {
   expandOperatorCapacity(self,1);
   _elements[_numberOfElements++]=NSClosePathBezierPathElement;   
}

-(void)relativeMoveToPoint:(NSPoint)point {
   CGPoint current=[self currentPoint];
   
   point.x+=current.x;
   point.y+=current.y;
   
   [self moveToPoint:point];
}

-(void)relativeLineToPoint:(NSPoint)point {
   CGPoint current=[self currentPoint];

   point.x+=current.x;
   point.y+=current.y;
   
   [self lineToPoint:point];
}

-(void)relativeCurveToPoint:(NSPoint)point controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2 {
   CGPoint current=[self currentPoint];

   cp1.x+=current.x;
   cp1.y+=current.y;
   cp2.x+=current.x;
   cp2.y+=current.y;
   point.x+=current.x;
   point.y+=current.y;
   
   [self curveToPoint:point controlPoint1:cp1 controlPoint2:cp2];
}

-(void)appendBezierPathWithPoints:(NSPoint *)points count:(unsigned)count {
   int i;
   
   if(count==0)
    return;
    
   [self moveToPoint:points[0] ];
   for(i=1;i<count;i++)
    [self lineToPoint:points[i] ];
}

-(void)appendBezierPathWithRect:(NSRect)rect {
// The line order is correct per documentation, do not change.
   [self moveToPoint:CGPointMake(CGRectGetMinX(rect),CGRectGetMinY(rect))];
   [self lineToPoint:CGPointMake(CGRectGetMaxX(rect),CGRectGetMinY(rect))];
   [self lineToPoint:CGPointMake(CGRectGetMaxX(rect),CGRectGetMaxY(rect))];
   [self lineToPoint:CGPointMake(CGRectGetMinX(rect),CGRectGetMaxY(rect))];
   [self closePath];
}

static void cgApplier(void *info,const CGPathElement *element) {
   NSBezierPath *self=(NSBezierPath *)info;
   
   switch(element->type){

    case kCGPathElementMoveToPoint:
     [self moveToPoint:element->points[0]];
     break;
     
    case kCGPathElementAddLineToPoint:
     [self lineToPoint:element->points[0]];
     break;
     
    case kCGPathElementAddQuadCurveToPoint:
     break;
     
    case kCGPathElementAddCurveToPoint:
     [self curveToPoint:element->points[2] controlPoint1:element->points[0] controlPoint2:element->points[1]];
     break;
     
    case kCGPathElementCloseSubpath:
     [self closePath];
     break;
   }
   
}

static void cgArcApply(void *info,const CGPathElement *element) {
   NSBezierPath *self=(NSBezierPath *)info;
   
   switch(element->type){
   
    case kCGPathElementMoveToPoint:
     if([self isEmpty])
      [self moveToPoint:element->points[0]];
     else
      [self lineToPoint:element->points[0]];
     break;
     
    case kCGPathElementAddCurveToPoint:
     [self curveToPoint:element->points[2] controlPoint1:element->points[0] controlPoint2:element->points[1]];
     break;
   }
   
}

-(void)appendBezierPathWithOvalInRect:(NSRect)rect {
   CGMutablePathRef path=CGPathCreateMutable();
   
   CGPathAddEllipseInRect(path,NULL,rect);
   CGPathApply(path,self,cgApplier);
   CGPathRelease(path);
}

-(void)appendBezierPathWithArcFromPoint:(NSPoint)point toPoint:(NSPoint)toPoint radius:(float)radius {
   CGMutablePathRef path=CGPathCreateMutable();
   
   CGPathAddArcToPoint(path,NULL,point.x,point.y,toPoint.x,toPoint.y,radius);
   CGPathApply(path,self,cgApplier);
   CGPathRelease(path);
}

- (void)appendBezierPathWithRoundedRect:(NSRect)rect xRadius:(CGFloat)radius yRadius:(CGFloat)yRadius {
   [self moveToPoint:NSMakePoint(rect.origin.x+radius, NSMaxY(rect))];
   [self appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius) radius: radius startAngle: 90 endAngle: 0.0f clockwise:YES];
   [self appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + rect.size.width - radius, rect.origin.y + radius) radius: radius  startAngle:360.0f endAngle: 270 clockwise:YES] ;
   [self appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + radius, rect.origin.y + radius) radius:radius startAngle:270 endAngle: 180 clockwise:YES];
   [self appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + radius, rect.origin.y + rect.size.height - radius) radius:radius startAngle: 180 endAngle: 90 clockwise:YES];
   [self closePath];
}

static inline CGFloat degreesToRadians(CGFloat degrees){
   return degrees*M_PI/180.0;
}

-(void)appendBezierPathWithArcWithCenter:(NSPoint)center radius:(float)radius startAngle:(float)startAngle endAngle:(float)endAngle {
   [self appendBezierPathWithArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
}

-(void)appendBezierPathWithArcWithCenter:(NSPoint)center radius:(float)radius startAngle:(float)startAngle endAngle:(float)endAngle clockwise:(BOOL)clockwise {
   CGMutablePathRef path=CGPathCreateMutable();
   CGPathAddArc(path,NULL,center.x,center.y,radius,degreesToRadians(startAngle),degreesToRadians(endAngle),clockwise);
   CGPathApply(path,self,cgArcApply);
   CGPathRelease(path);
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
   unsigned             opsCount=other->_numberOfElements;
   const unsigned char *ops=other->_elements;
   unsigned             pointCount=other->_numberOfPoints;
   const CGPoint       *points=other->_points;
   unsigned             i;
   
   expandOperatorCapacity(self,opsCount);
   expandPointCapacity(self,pointCount);
   
   for(i=0;i<opsCount;i++)
    _elements[_numberOfElements++]=ops[i];
    
   for(i=0;i<pointCount;i++)
    _points[_numberOfPoints++]=points[i];
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
   
   NSInteger i;
   
   for(i=0;i<_numberOfPoints;i++)
    _points[i]=CGPointApplyAffineTransform(_points[i],cgMatrix);
}

-(void)removeAllPoints {
   _numberOfElements=0;
   _numberOfPoints=0;
}

-(void)setAssociatedPoints:(NSPoint *)points atIndex:(int)index {
   int i,pi=0,pcount;
   
   if(index>=_numberOfElements)
    [NSException raise:NSInvalidArgumentException format:@"index (%d) >= numberOfElements (%d)",index,_numberOfElements];
    
   for(i=0;i<index;i++)
    pi+=numberOfPointsForOperator(_elements[i]);
    
   pcount=numberOfPointsForOperator(_elements[i]);
      
   for(i=0;i<pcount;i++)
    _points[pi+i]=points[i];
}

-(NSBezierPath *)bezierPathByFlatteningPath {
   NSUnimplementedMethod();
   return nil;
}

-(NSBezierPath *)bezierPathByReversingPath {
   NSUnimplementedMethod();
   return nil;
}

-(void)_addPathToContext:(CGContextRef)context {
   int i;
   CGPoint *points=_points;
   
   for(i=0;i<_numberOfElements;i++){
    switch(_elements[i]){
    
     case NSMoveToBezierPathElement:{
       CGPoint p=*points++;
       
       CGContextMoveToPoint(context,p.x,p.y);
      }
      break;
      
     case NSLineToBezierPathElement:{
       CGPoint p=*points++;
       CGContextAddLineToPoint(context,p.x,p.y);
      }
      break;
      
     case NSCurveToBezierPathElement:{
      CGPoint cp1=*points++;
      CGPoint cp2=*points++;
      CGPoint end=*points++;
      
      CGContextAddCurveToPoint(context,cp1.x,cp1.y,cp2.x,cp2.y,end.x,end.y);
      }
      break;
     case NSClosePathBezierPathElement:
      CGContextClosePath(context);
      break;
    }
   }
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
   [self _addPathToContext:context];
   CGContextStrokePath(context);
   CGContextRestoreGState(context);
}

-(void)fill {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   
   CGContextBeginPath(context);
   [self _addPathToContext:context];
   if([self windingRule]==NSNonZeroWindingRule)
    CGContextFillPath(context);
   else
    CGContextEOFillPath(context);
}

-(void)addClip {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   if(CGContextIsPathEmpty(context))
    CGContextBeginPath(context);
   [self _addPathToContext:context];
   CGContextClip(context);
}

-(void)setClip {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   CGContextBeginPath(context);
   [self _addPathToContext:context];
   CGContextClip(context);
}

@end
