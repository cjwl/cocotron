/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGMutablePath.h"
#import "KGPath.h"

// ellipse to 4 spline bezier, http://www.tinaja.com/glib/ellipse4.pdf
void KGMutablePathEllipseToBezier(NSPoint *cp,float x,float y,float xrad,float yrad){
   float magic=0.551784;
   float xmag=xrad*magic;
   float ymag=yrad*magic;
   int   i=0;

   cp[i++]=NSMakePoint(-xrad,0);

   cp[i++]=NSMakePoint(-xrad,ymag);
   cp[i++]=NSMakePoint(-xmag,yrad);
   cp[i++]=NSMakePoint(0,yrad);
   
   cp[i++]=NSMakePoint(xmag,yrad);
   cp[i++]=NSMakePoint(xrad,ymag);
   cp[i++]=NSMakePoint(xrad,0);

   cp[i++]=NSMakePoint(xrad,-ymag);
   cp[i++]=NSMakePoint(xmag,-yrad);
   cp[i++]=NSMakePoint(0,-yrad);

   cp[i++]=NSMakePoint(-xmag,-yrad);
   cp[i++]=NSMakePoint(-xrad,-ymag);
   cp[i++]=NSMakePoint(-xrad,0);
   
   for(i=0;i<13;i++){
    cp[i].x+=x;
    cp[i].y+=y;
   }
}

@implementation KGMutablePath

// Bezier and arc to bezier algorithms from: Windows Graphics Programming by Feng Yuan
#if 0
static void bezier(KGGraphicsState *self,double x1,double y1,double x2, double y2,double x3,double y3,double x4,double y4){
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

-initWithOperators:(unsigned char *)operators numberOfOperators:(unsigned)numberOfOperators points:(NSPoint *)points numberOfPoints:(unsigned)numberOfPoints {
   [super initWithOperators:operators numberOfOperators:numberOfOperators points:points numberOfPoints:numberOfPoints];
   _capacityOfOperators=numberOfOperators;
   _capacityOfPoints=numberOfPoints;
   return self;
}

-copyWithZone:(NSZone *)zone {
   return [[KGPath allocWithZone:zone] initWithOperators:_operators numberOfOperators:_numberOfOperators points:_points numberOfPoints:_numberOfPoints];
}

-(void)reset {
   _numberOfOperators=0;
   _numberOfPoints=0;
}

static void expandOperatorCapacity(KGMutablePath *self,unsigned delta){
   if(self->_numberOfOperators+delta>self->_capacityOfOperators){
    self->_capacityOfOperators=self->_numberOfOperators+delta;
    self->_capacityOfOperators=(self->_capacityOfOperators/16+1)*16;
    self->_operators=NSZoneRealloc(NULL,self->_operators,self->_capacityOfOperators);
   }
}

static void expandPointCapacity(KGMutablePath *self,unsigned delta){
   if(self->_numberOfPoints+delta>self->_capacityOfPoints){
    self->_capacityOfPoints=self->_numberOfPoints+delta;
    self->_capacityOfPoints=(self->_capacityOfPoints/32+1)*32;
    self->_points=NSZoneRealloc(NULL,self->_points,self->_capacityOfPoints*sizeof(NSPoint));
   }
}

-(void)moveToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix {
   if(matrix!=NULL)
    point=CGPointApplyAffineTransform(point,*matrix);

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   _operators[_numberOfOperators++]=kCGPathOperatorMoveToPoint;
   _points[_numberOfPoints++]=point;
}

-(void)addLineToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix {
   if(matrix!=NULL)
    point=CGPointApplyAffineTransform(point,*matrix);

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,1);
   _operators[_numberOfOperators++]=kCGPathOperatorLineToPoint;
   _points[_numberOfPoints++]=point;
}

-(void)addCurveToControlPoint:(NSPoint)cp1 controlPoint:(NSPoint)cp2 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix {
   if(matrix!=NULL){
    cp1=CGPointApplyAffineTransform(cp1,*matrix);
    cp2=CGPointApplyAffineTransform(cp2,*matrix);
    endPoint=CGPointApplyAffineTransform(endPoint,*matrix);
   }

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,3);
   _operators[_numberOfOperators++]=kCGPathOperatorCurveToPoint;   
   _points[_numberOfPoints++]=cp1;
   _points[_numberOfPoints++]=cp2;
   _points[_numberOfPoints++]=endPoint;
}

-(void)addCurveToControlPoint:(NSPoint)cp1 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix {
   if(matrix!=NULL){
    cp1=CGPointApplyAffineTransform(cp1,*matrix);
    endPoint=CGPointApplyAffineTransform(endPoint,*matrix);
   }

   expandOperatorCapacity(self,1);
   expandPointCapacity(self,2);
   _operators[_numberOfOperators++]=kCGPathOperatorQuadCurveToPoint;   
   _points[_numberOfPoints++]=cp1;
   _points[_numberOfPoints++]=endPoint;
}

-(void)closeSubpath {
   expandOperatorCapacity(self,1);
   _operators[_numberOfOperators++]=kCGPathOperatorCloseSubpath;   
}

-(void)relativeMoveToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix {
   NSPoint current=[self currentPoint];
   
   point.x+=current.x;
   point.y+=current.y;
   
   [self moveToPoint:point withTransform:matrix];
}

-(void)addRelativeLineToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix {
   NSPoint current=[self currentPoint];

   point.x+=current.x;
   point.y+=current.y;
   
   [self addLineToPoint:point withTransform:matrix];
}

-(void)addRelativeCurveToControlPoint:(NSPoint)cp1 controlPoint:(NSPoint)cp2 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix {
   NSPoint current=[self currentPoint];

   cp1.x+=current.x;
   cp1.y+=current.y;
   cp2.x+=current.x;
   cp2.y+=current.y;
   endPoint.x+=current.x;
   endPoint.y+=current.y;
   
   [self addCurveToControlPoint:cp1 controlPoint:cp2 endPoint:endPoint withTransform:matrix];
}

-(void)addLinesWithPoints:(NSPoint *)points count:(unsigned)count withTransform:(CGAffineTransform *)matrix {
   int i;
   
   if(count==0)
    return;
    
   [self moveToPoint:points[0] withTransform:matrix];
   for(i=1;i<count;i++)
    [self addLineToPoint:points[i] withTransform:matrix];
}

-(void)addRect:(NSRect)rect withTransform:(CGAffineTransform *)matrix {
   [self moveToPoint:NSMakePoint(NSMinX(rect),NSMinY(rect)) withTransform:matrix];
   [self addLineToPoint:NSMakePoint(NSMaxX(rect),NSMinY(rect)) withTransform:matrix];
   [self addLineToPoint:NSMakePoint(NSMaxX(rect),NSMaxY(rect)) withTransform:matrix];
   [self addLineToPoint:NSMakePoint(NSMinX(rect),NSMaxY(rect)) withTransform:matrix];
   [self closeSubpath];
}

-(void)addRects:(const NSRect *)rects count:(unsigned)count withTransform:(CGAffineTransform *)matrix {
   int i;
   
   for(i=0;i<count;i++)
    [self addRect:rects[i] withTransform:matrix];
}

-(void)addArcAtPoint:(NSPoint)point radius:(float)radius startAngle:(float)startRadian endAngle:(float)endRadian clockwise:(BOOL)clockwise withTransform:(CGAffineTransform *)matrix {
// This is not complete, doesn't handle clockwise and probably doesn't manipulate the current
// point properly
   float   radiusx=radius,radiusy=radius;
   double  remainder=endRadian-startRadian;
   double  delta=3.141592653589793238/2; // 90 degrees
   int     i;

   for(;remainder>0;startRadian+=delta,remainder-=delta){
    double  sweepangle=(remainder>delta)?delta:remainder;
    double  XY[8];
    NSPoint points[4];
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
     points[i].x=point.x+(XY[i*2]*c-XY[i*2+1]*s)*radiusx;
     points[i].y=point.y+(XY[i*2]*s+XY[i*2+1]*c)*radiusy;
    }

    [self moveToPoint:points[0] withTransform:matrix];
    [self addCurveToControlPoint:points[1] controlPoint:points[2] endPoint:points[3] withTransform:matrix];
   }
}

-(void)addArcToPoint:(NSPoint)point1 point:(NSPoint)point2 radius:(float)radius withTransform:(CGAffineTransform *)matrix {
	NSUnimplementedMethod();
}

-(void)addEllipseInRect:(NSRect)rect withTransform:(CGAffineTransform *)matrix {
    float             xradius=rect.size.width/2;
    float             yradius=rect.size.height/2;
    float             x=rect.origin.x+xradius;
    float             y=rect.origin.y+yradius;
    NSPoint           cp[13];
    int               i;
    
    KGMutablePathEllipseToBezier(cp,x,y,xradius,yradius);
    
    [self moveToPoint:cp[0] withTransform:matrix];
    for(i=1;i<13;i+=3)
     [self addCurveToControlPoint:cp[i] controlPoint:cp[i+1] endPoint:cp[i+2] withTransform:matrix];
}

-(void)addPath:(KGPath *)path withTransform:(CGAffineTransform *)matrix {
   unsigned             opsCount=[path numberOfOperators];
   const unsigned char *ops=[path operators];
   unsigned             pointCount=[path numberOfPoints];
   const NSPoint       *points=[path points];
   unsigned             i;
   
   expandOperatorCapacity(self,opsCount);
   expandPointCapacity(self,pointCount);
   
   for(i=0;i<opsCount;i++)
    _operators[_numberOfOperators++]=ops[i];
    
   if(matrix==NULL){
    for(i=0;i<pointCount;i++)
     _points[_numberOfPoints++]=points[i];
   }
   else {    
    for(i=0;i<pointCount;i++)
     _points[_numberOfPoints++]=CGPointApplyAffineTransform(points[i],*matrix);
   }
}

-(void)applyTransform:(CGAffineTransform)matrix {
   int i;
   
   for(i=0;i<_numberOfPoints;i++)
    _points[i]=CGPointApplyAffineTransform(_points[i],matrix);
}

-(void)setPoints:(NSPoint *)points count:(unsigned)count atIndex:(unsigned)index {
   int i;
   
   for(i=0;i<count;i++)
    _points[index+i]=points[i];
}

@end
