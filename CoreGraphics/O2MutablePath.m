/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2MutablePath.h"
#import "O2Path.h"
#import "KGExceptions.h"
#import <math.h>

// ellipse to 4 spline bezier, http://www.tinaja.com/glib/ellipse4.pdf
void O2MutablePathEllipseToBezier(CGPoint *cp,float x,float y,float xrad,float yrad){
   float magic=0.551784;
   float xmag=xrad*magic;
   float ymag=yrad*magic;
   int   i=0;

   cp[i++]=CGPointMake(-xrad,0);

   cp[i++]=CGPointMake(-xrad,ymag);
   cp[i++]=CGPointMake(-xmag,yrad);
   cp[i++]=CGPointMake(0,yrad);
   
   cp[i++]=CGPointMake(xmag,yrad);
   cp[i++]=CGPointMake(xrad,ymag);
   cp[i++]=CGPointMake(xrad,0);

   cp[i++]=CGPointMake(xrad,-ymag);
   cp[i++]=CGPointMake(xmag,-yrad);
   cp[i++]=CGPointMake(0,-yrad);

   cp[i++]=CGPointMake(-xmag,-yrad);
   cp[i++]=CGPointMake(-xrad,-ymag);
   cp[i++]=CGPointMake(-xrad,0);
   
   for(i=0;i<13;i++){
    cp[i].x+=x;
    cp[i].y+=y;
   }
}

@implementation O2MutablePath

O2MutablePathRef O2PathCreateMutable(void) {
   return [[O2MutablePath alloc] init];
}

// Bezier and arc to bezier algorithms from: Windows Graphics Programming by Feng Yuan
#if 0
static void bezier(O2GState *self,double x1,double y1,double x2, double y2,double x3,double y3,double x4,double y4){
   // Ax+By+C=0 is the line (x1,y1) (x4,y4);
   double A=y4-y1;
   double B=x1-x4;
   double C=y1*(x4-x1)-x1*(y4-y1);
   double AB=A*A+B*B;

   if((A*x2+B*y2+C)*(A*x2+B*y2+C)<AB &&
      (A*x3+B*y3+C)*(A*x3+B*y3+C)<AB){
    [self moveToPoint:x1:y1];
    [self addLineToPoint:x4:y4];
    return;
   }
   else {
    double x12=x1+x2;
    double y12=y1+y2;
    double x23=x2+x3;
    double y23=y2+y3;
    double x34=x3+x4;
    double y34=y3+y4;
    double x1223=x12+x23;
    double y1223=y12+y23;
    double x2334=x23+x34;
    double y2334=y23+y34;
    double x=x1223+x2334;
    double y=y1223+y2334;

    bezier(self,x1,y1,x12/2,y12/2,x1223/4,y1223/4,x/8,y/8);
    bezier(self,x/8,y/8,x2334/4,y2334/4,x34/2,y34/2,x4,y4);
   }
}

#endif

-initWithOperators:(unsigned char *)elements numberOfElements:(unsigned)numberOfElements points:(CGPoint *)points numberOfPoints:(unsigned)numberOfPoints {
   [super initWithOperators:elements numberOfElements:numberOfElements points:points numberOfPoints:numberOfPoints];
   _capacityOfElements=numberOfElements;
   _capacityOfPoints=numberOfPoints;
   return self;
}

-copyWithZone:(NSZone *)zone {
   return [[O2Path allocWithZone:zone] initWithOperators:_elements numberOfElements:_numberOfElements points:_points numberOfPoints:_numberOfPoints];
}

void O2PathReset(O2MutablePathRef self) {
   self->_numberOfElements=0;
   self->_numberOfPoints=0;
}

static inline void expandOperatorCapacity(O2MutablePath *self,unsigned delta){
   if(self->_numberOfElements+delta>self->_capacityOfElements){
    self->_capacityOfElements=self->_numberOfElements+delta;
    self->_capacityOfElements=(self->_capacityOfElements/32+1)*32;
    self->_elements=NSZoneRealloc(NULL,self->_elements,self->_capacityOfElements);
   }
}

static inline void expandPointCapacity(O2MutablePath *self,unsigned delta){
   if(self->_numberOfPoints+delta>self->_capacityOfPoints){
    self->_capacityOfPoints=self->_numberOfPoints+delta;
    self->_capacityOfPoints=(self->_capacityOfPoints/64+1)*64;
    self->_points=NSZoneRealloc(NULL,self->_points,self->_capacityOfPoints*sizeof(CGPoint));
   }
}

void O2PathMoveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y) {
   CGPoint point=CGPointMake(x,y);
   
   if(matrix!=NULL)
    point=CGPointApplyAffineTransform(point,*matrix);

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   self->_elements[self->_numberOfElements++]=kCGPathElementMoveToPoint;
   self->_points[self->_numberOfPoints++]=point;
}

void O2PathAddLineToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y) {
   CGPoint point=CGPointMake(x,y);

   if(matrix!=NULL)
    point=CGPointApplyAffineTransform(point,*matrix);

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   self->_elements[self->_numberOfElements++]=kCGPathElementAddLineToPoint;
   self->_points[self->_numberOfPoints++]=point;
}

void O2PathAddCurveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat cp1x,CGFloat cp1y,CGFloat cp2x,CGFloat cp2y,CGFloat x,CGFloat y) {
   CGPoint cp1=CGPointMake(cp1x,cp1y);
   CGPoint cp2=CGPointMake(cp2x,cp2y);
   CGPoint endPoint=CGPointMake(x,y);
   
   if(matrix!=NULL){
    cp1=CGPointApplyAffineTransform(cp1,*matrix);
    cp2=CGPointApplyAffineTransform(cp2,*matrix);
    endPoint=CGPointApplyAffineTransform(endPoint,*matrix);
   }

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,3);
   self->_elements[self->_numberOfElements++]=kCGPathElementAddCurveToPoint;   
   self->_points[self->_numberOfPoints++]=cp1;
   self->_points[self->_numberOfPoints++]=cp2;
   self->_points[self->_numberOfPoints++]=endPoint;
}

void O2PathAddQuadCurveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat cpx,CGFloat cpy,CGFloat x,CGFloat y) {
   CGPoint cp1=CGPointMake(cpx,cpy);
   CGPoint endPoint=CGPointMake(x,y);

   if(matrix!=NULL){
    cp1=CGPointApplyAffineTransform(cp1,*matrix);
    endPoint=CGPointApplyAffineTransform(endPoint,*matrix);
   }

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,2);
   self->_elements[self->_numberOfElements++]=kCGPathElementAddQuadCurveToPoint;   
   self->_points[self->_numberOfPoints++]=cp1;
   self->_points[self->_numberOfPoints++]=endPoint;
}

void O2PathCloseSubpath(O2MutablePathRef self) {
   expandOperatorCapacity(self,1);
   self->_elements[self->_numberOfElements++]=kCGPathElementCloseSubpath;   
}

void O2PathAddLines(O2MutablePathRef self,const CGAffineTransform *matrix,const CGPoint *points,size_t count) {
   int i;
   
   if(count==0)
    return;
    
   O2PathMoveToPoint(self,matrix,points[0].x,points[0].y);
   for(i=1;i<count;i++)
    O2PathAddLineToPoint(self,matrix,points[i].x,points[i].y);
}

void O2PathAddRect(O2MutablePathRef self,const CGAffineTransform *matrix,CGRect rect) {
// The line order is correct per documentation, do not change.
   O2PathMoveToPoint(self,matrix,CGRectGetMinX(rect),CGRectGetMinY(rect));
   O2PathAddLineToPoint(self,matrix,CGRectGetMaxX(rect),CGRectGetMinY(rect));
   O2PathAddLineToPoint(self,matrix,CGRectGetMaxX(rect),CGRectGetMaxY(rect));
   O2PathAddLineToPoint(self,matrix,CGRectGetMinX(rect),CGRectGetMaxY(rect));
   O2PathCloseSubpath(self);
}

void O2PathAddRects(O2MutablePathRef self,const CGAffineTransform *matrix,const CGRect *rects,size_t count) {
   int i;
   
   for(i=0;i<count;i++)
    O2PathAddRect(self,matrix,rects[i]);
}

void O2PathAddArc(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y,CGFloat radius,CGFloat startRadian,CGFloat endRadian,BOOL clockwise) {

   if(clockwise){
    float tmp=startRadian;
    startRadian=endRadian;
    endRadian=tmp;
   }

   float   radiusx=radius,radiusy=radius;
   double  remainder=endRadian-startRadian;
   double  delta=M_PI_2; // 90 degrees
   int     i;
   CGPoint points[4*((int)ceil(remainder/delta)+1)];
   int     pointsIndex=0;
   
   for(;remainder>0;startRadian+=delta,remainder-=delta){
    double  sweepangle=(remainder>delta)?delta:remainder;
    double  XY[8];
    double  B=sin(sweepangle/2);
    double  C=cos(sweepangle/2);
    double  A=1-C;
    double  X=A*4/3;
    double  Y=B-X*(1-A)/B;
    double  s=sin(startRadian+sweepangle/2);
    double  c=cos(startRadian+sweepangle/2);

    XY[0]= C;
    XY[1]=-B;
    XY[2]= C+X;
    XY[3]=-Y;
    XY[4]= C+X;
    XY[5]= Y;
    XY[6]= C;
    XY[7]= B;

    for(i=0;i<4;i++){
     points[pointsIndex].x=x+(XY[i*2]*c-XY[i*2+1]*s)*radiusx;
     points[pointsIndex].y=y+(XY[i*2]*s+XY[i*2+1]*c)*radiusy;
     pointsIndex++;
    }
   }
   
   if(clockwise){
    // just reverse points
    for(i=0;i<pointsIndex/2;i++){
     CGPoint tmp;
     
     tmp=points[i];
     points[i]=points[(pointsIndex-1)-i];
     points[(pointsIndex-1)-i]=tmp;
    }     
   }
   
   BOOL first=YES;
   for(i=0;i<pointsIndex;i+=4){
    if(first){
     if(O2PathIsEmpty(self)) {
      O2PathMoveToPoint(self,matrix,points[i].x,points[i].y);
     } else {
      O2PathAddLineToPoint(self,matrix,points[i].x,points[i].y);
     }
    first=NO;
    }
    O2PathAddCurveToPoint(self,matrix,points[i+1].x,points[i+1].y,points[i+2].x,points[i+2].y,points[i+3].x,points[i+3].y);
   }
}

void O2PathAddArcToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat tx1,CGFloat ty1,CGFloat tx2,CGFloat ty2,CGFloat radius) {
	KGUnimplementedFunction();
}

void O2PathAddEllipseInRect(O2MutablePathRef self,const CGAffineTransform *matrix,CGRect rect) {
   float             xradius=rect.size.width/2;
   float             yradius=rect.size.height/2;
   float             x=rect.origin.x+xradius;
   float             y=rect.origin.y+yradius;
   CGPoint           cp[13];
   int               i;
    
   O2MutablePathEllipseToBezier(cp,x,y,xradius,yradius);
    
   O2PathMoveToPoint(self,matrix,cp[0].x,cp[0].y);
   for(i=1;i<13;i+=3)
    O2PathAddCurveToPoint(self,matrix,cp[i].x,cp[i].y,cp[i+1].x,cp[i+1].y,cp[i+2].x,cp[i+2].y);
}

void O2PathAddPath(O2MutablePathRef self,const CGAffineTransform *matrix,O2PathRef path) {
   unsigned             opsCount=[path numberOfElements];
   const unsigned char *ops=[path elements];
   unsigned             pointCount=[path numberOfPoints];
   const CGPoint       *points=[path points];
   unsigned             i;
   
   expandOperatorCapacity(self,opsCount);
   expandPointCapacity(self,pointCount);
   
   for(i=0;i<opsCount;i++)
    self->_elements[self->_numberOfElements++]=ops[i];
    
   if(matrix==NULL){
    for(i=0;i<pointCount;i++)
     self->_points[self->_numberOfPoints++]=points[i];
   }
   else {    
    for(i=0;i<pointCount;i++)
     self->_points[self->_numberOfPoints++]=CGPointApplyAffineTransform(points[i],*matrix);
   }
}

void O2PathApplyTransform(O2MutablePathRef self,const CGAffineTransform matrix) {
   int i;
   
   for(i=0;i<self->_numberOfPoints;i++)
    self->_points[i]=CGPointApplyAffineTransform(self->_points[i],matrix);
}

@end
