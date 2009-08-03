/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2Path.h"
#import "O2MutablePath.h"
#import "KGExceptions.h"

@implementation O2Path

-initWithOperators:(unsigned char *)elements numberOfElements:(unsigned)numberOfElements points:(CGPoint *)points numberOfPoints:(unsigned)numberOfPoints {
   int i;
   
   _numberOfElements=numberOfElements;
   _elements=NSZoneMalloc(NULL,(_numberOfElements==0)?1:_numberOfElements);
   for(i=0;i<_numberOfElements;i++)
    _elements[i]=elements[i];

   _numberOfPoints=numberOfPoints;
   _points=NSZoneMalloc(NULL,(_numberOfPoints==0?1:_numberOfPoints)*sizeof(CGPoint));
   for(i=0;i<_numberOfPoints;i++)
    _points[i]=points[i];
    
   return self;
}

-init {
   return [self initWithOperators:NULL numberOfElements:0 points:NULL numberOfPoints:0];
}

-(void)dealloc {
   NSZoneFree(NULL,_elements);
   NSZoneFree(NULL,_points);
   [super dealloc];
}

void O2PathRelease(O2PathRef self) {
   [self release];
}

O2PathRef O2PathRetain(O2PathRef self) {
   return [self retain];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

O2PathRef O2PathCreateCopy(O2PathRef self) {
   return [self copyWithZone:NULL];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[O2MutablePath allocWithZone:zone] initWithOperators:_elements numberOfElements:_numberOfElements points:_points numberOfPoints:_numberOfPoints];
}

O2MutablePathRef O2PathCreateMutableCopy(O2PathRef self) {
   return [self mutableCopyWithZone:NULL];
}

-(unsigned)numberOfElements {
   return _numberOfElements;
}

-(const unsigned char *)elements {
   return _elements;
}

-(unsigned)numberOfPoints {
   return _numberOfPoints;
}

-(const CGPoint *)points {
   return _points;
}

CGPoint O2PathGetCurrentPoint(O2PathRef self) {
// this is wrong w/ closepath last
   return (self->_numberOfPoints==0)?CGPointZero:self->_points[self->_numberOfPoints-1];
}

BOOL    O2PathEqualToPath(O2PathRef self,O2PathRef other){
   unsigned otherNumberOfOperators=[other numberOfElements];
   
   if(self->_numberOfElements==otherNumberOfOperators){
    unsigned otherNumberOfPoints=[other numberOfPoints];
    
    if(self->_numberOfPoints==otherNumberOfPoints){
     const unsigned char *otherOperators=[other elements];
     const CGPoint       *otherPoints;
     int i;
     
     for(i=0;i<self->_numberOfElements;i++)
      if(self->_elements[i]!=otherOperators[i])
       return NO;
       
     otherPoints=[other points];
     for(i=0;i<self->_numberOfPoints;i++)
      if(!CGPointEqualToPoint(self->_points[i],otherPoints[i]))
       return NO;
       
     return YES;
    }
    
   }
   return NO;
}

BOOL O2PathIsEmpty(O2PathRef self) {
   return self->_numberOfElements==0;
}

BOOL O2PathIsRect(O2PathRef self,CGRect *rect) {
   if(self->_numberOfElements!=5)
    return NO;
   if(self->_elements[0]!=kCGPathElementMoveToPoint)
    return NO;
   if(self->_elements[1]!=kCGPathElementAddLineToPoint)
    return NO;
   if(self->_elements[2]!=kCGPathElementAddLineToPoint)
    return NO;
   if(self->_elements[3]!=kCGPathElementAddLineToPoint)
    return NO;
   if(self->_elements[4]!=kCGPathElementCloseSubpath)
    return NO;
   
   if(self->_points[0].x!=self->_points[1].x)
    return NO;
   if(self->_points[1].y!=self->_points[2].y)
    return NO;
   if(self->_points[2].x!=self->_points[3].x)
    return NO;
   if(self->_points[3].y!=self->_points[0].y)
    return NO;
   
   rect->origin=self->_points[0];
   rect->size=CGSizeMake(self->_points[2].x-self->_points[0].x,self->_points[2].y-self->_points[0].y);
   
   return YES;
}

BOOL O2PathContainsPoint(O2PathRef self,const CGAffineTransform *xform,CGPoint point,BOOL evenOdd) {
   KGUnimplementedFunction();
   return NO;
}

CGRect O2PathGetBoundingBox(O2PathRef self) {
   CGRect result;
   int i;
   
   if(self->_numberOfPoints==0)
    return CGRectZero;
   
   result.origin=self->_points[0];
   result.size=CGSizeMake(0,0);
   for(i=1;i<self->_numberOfPoints;i++){
    CGPoint point=self->_points[i];
    
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

void O2PathApply(O2PathRef self,void *info,CGPathApplierFunction function) {
   int           i,pointIndex=0;
   CGPathElement element;
   
   for(i=0;i<self->_numberOfElements;i++){
    element.type=self->_elements[i];
    element.points=self->_points+pointIndex;

    switch(element.type){
    
     case kCGPathElementMoveToPoint:
      pointIndex+=1;
      break;
       
     case kCGPathElementAddLineToPoint:
      pointIndex+=1;
      break;

     case kCGPathElementAddCurveToPoint:
      pointIndex+=3;
      break;

     case kCGPathElementAddQuadCurveToPoint:
      pointIndex+=2;
      break;

     case kCGPathElementCloseSubpath:
      pointIndex+=0;
      break;
     }
    if(function!=NULL) // CG will ignore function if NULL
     function(info,&element);
   }
}

@end
