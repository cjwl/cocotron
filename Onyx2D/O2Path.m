/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2Path.h>
#import <Onyx2D/O2MutablePath.h>
#import <Onyx2D/O2Exceptions.h>

@implementation O2Path

-initWithOperators:(unsigned char *)elements numberOfElements:(unsigned)numberOfElements points:(O2Point *)points numberOfPoints:(unsigned)numberOfPoints {
   return O2PathInitWithOperators(self,elements,numberOfElements,points,numberOfPoints);
}

id O2PathInitWithOperators(O2Path *self,unsigned char *elements,unsigned numberOfElements,O2Point *points,unsigned numberOfPoints) {
   int i;
   
   self->_numberOfElements=numberOfElements;
   self->_elements=NSZoneMalloc(NULL,(self->_numberOfElements==0)?1:self->_numberOfElements);
   for(i=0;i<self->_numberOfElements;i++)
    self->_elements[i]=elements[i];

   self->_numberOfPoints=numberOfPoints;
   self->_points=NSZoneMalloc(NULL,(self->_numberOfPoints==0?1:self->_numberOfPoints)*sizeof(O2Point));
   for(i=0;i<self->_numberOfPoints;i++)
    self->_points[i]=points[i];
    
   return self;
}

-init {
   return [self initWithOperators:NULL numberOfElements:0 points:NULL numberOfPoints:0];
}

-(void)dealloc {
   if(_elements!=NULL)
   NSZoneFree(NULL,_elements);
   if(_points!=NULL)
   NSZoneFree(NULL,_points);
   [super dealloc];
}

void O2PathRelease(O2PathRef self) {
   if(self!=NULL)
    CFRelease(self);
}

O2PathRef O2PathRetain(O2PathRef self) {
   return (self!=NULL)?(O2PathRef)CFRetain(self):NULL;
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

O2PathRef O2PathCreateCopy(O2PathRef self) {
   return [self copyWithZone:NULL];
}

O2MutablePathRef O2PathCreateMutableCopy(O2PathRef self) {
   return [[O2MutablePath allocWithZone:NULL] initWithOperators:self->_elements numberOfElements:self->_numberOfElements points:self->_points numberOfPoints:self->_numberOfPoints];
}

unsigned O2PathNumberOfElements(O2PathRef self) {
   return self->_numberOfElements;
}

const unsigned char *O2PathElements(O2PathRef self) {
   return self->_elements;
}

unsigned O2PathNumberOfPoints(O2PathRef self) {
   return self->_numberOfPoints;
}

const O2Point *O2PathPoints(O2PathRef self) {
   return self->_points;
}

O2Point O2PathGetCurrentPoint(O2PathRef self) {
// this is wrong w/ closepath last
   return (self->_numberOfPoints==0)?O2PointZero:self->_points[self->_numberOfPoints-1];
}

BOOL    O2PathEqualToPath(O2PathRef self,O2PathRef other){
   unsigned otherNumberOfOperators=O2PathNumberOfElements(other);
   
   if(self->_numberOfElements==otherNumberOfOperators){
    unsigned otherNumberOfPoints=O2PathNumberOfPoints(other);
    
    if(self->_numberOfPoints==otherNumberOfPoints){
     const unsigned char *otherOperators=O2PathElements(other);
     const O2Point       *otherPoints;
     int i;
     
     for(i=0;i<self->_numberOfElements;i++)
      if(self->_elements[i]!=otherOperators[i])
       return NO;
       
     otherPoints=O2PathPoints(other);
     for(i=0;i<self->_numberOfPoints;i++)
      if(!O2PointEqualToPoint(self->_points[i],otherPoints[i]))
       return NO;
       
     return YES;
    }
    
   }
   return NO;
}

BOOL O2PathIsEmpty(O2PathRef self) {
   return self->_numberOfElements==0;
}

BOOL O2PathIsRect(O2PathRef self,O2Rect *rect) {
   if(self->_numberOfElements!=5)
    return NO;
   if(self->_elements[0]!=kO2PathElementMoveToPoint)
    return NO;
   if(self->_elements[1]!=kO2PathElementAddLineToPoint)
    return NO;
   if(self->_elements[2]!=kO2PathElementAddLineToPoint)
    return NO;
   if(self->_elements[3]!=kO2PathElementAddLineToPoint)
    return NO;
   if(self->_elements[4]!=kO2PathElementCloseSubpath)
    return NO;
   
   if(self->_points[0].y!=self->_points[1].y)
    return NO;
   if(self->_points[1].x!=self->_points[2].x)
    return NO;
   if(self->_points[2].y!=self->_points[3].y)
    return NO;
   if(self->_points[3].x!=self->_points[0].x)
    return NO;
   
// FIXME: this is probably wrong, coordinate order   
   rect->origin=self->_points[0];
   rect->size=O2SizeMake(self->_points[2].x-self->_points[0].x,self->_points[2].y-self->_points[0].y);
   
   return YES;
}

BOOL O2PathContainsPoint(O2PathRef self,const O2AffineTransform *xform,O2Point point,BOOL evenOdd) {
   O2UnimplementedFunction();
   return NO;
}

O2Rect O2PathGetBoundingBox(O2PathRef self) {
   O2Rect result;
   int i;
   
   if(self->_numberOfPoints==0)
    return O2RectZero;
   
   result.origin=self->_points[0];
   result.size=O2SizeMake(0,0);
   for(i=1;i<self->_numberOfPoints;i++){
    O2Point point=self->_points[i];
    
    if(point.x>O2RectGetMaxX(result))
     result.size.width=point.x-O2RectGetMinX(result);
    else if(point.x<result.origin.x){
     result.size.width=O2RectGetMaxX(result)-point.x;
     result.origin.x=point.x;
    }
    
    if(point.y>O2RectGetMaxY(result))
     result.size.height=point.y-O2RectGetMinY(result);
    else if(point.y<result.origin.y){
     result.size.height=O2RectGetMaxY(result)-point.y;
     result.origin.y=point.y;
    }
   }   

   return result;
}

void O2PathApply(O2PathRef self,void *info,O2PathApplierFunction function) {
   int           i,pointIndex=0;
   O2PathElement element;
   
   for(i=0;i<self->_numberOfElements;i++){
    element.type=self->_elements[i];
    element.points=self->_points+pointIndex;

    switch(element.type){
    
     case kO2PathElementMoveToPoint:
      pointIndex+=1;
      break;
       
     case kO2PathElementAddLineToPoint:
      pointIndex+=1;
      break;

     case kO2PathElementAddCurveToPoint:
      pointIndex+=3;
      break;

     case kO2PathElementAddQuadCurveToPoint:
      pointIndex+=2;
      break;

     case kO2PathElementCloseSubpath:
      pointIndex+=0;
      break;
     }
    if(function!=NULL) // O2 will ignore function if NULL
     function(info,&element);
   }
}

@end
