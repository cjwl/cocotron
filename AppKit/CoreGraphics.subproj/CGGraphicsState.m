/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/CGGraphicsState.h>
#import <AppKit/CGRenderingContext.h>

#import <AppKit/CoreGraphics.h>

// Bezier and arc to bezier algorithms from: Windows Graphics Programming by Feng Yuan

@implementation CGGraphicsState

-initWithRenderingContext:(CGRenderingContext *)context transform:(CGAffineTransform)deviceTransform clipRect:(NSRect)clipRect {
   _renderingContext=[context retain];
   _deviceTransform=deviceTransform;
   _clipRect=clipRect;
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   CGGraphicsState *copy=NSCopyObject(self,0,zone);

   copy->_renderingContext=[_renderingContext retain];

   return copy;
}

-(void)moveToPoint:(float)x:(float)y {
   NSInvalidAbstractInvocation();
}

-(void)addLineToPoint:(float)x:(float)y {
   NSInvalidAbstractInvocation();
}

static void bezier(CGGraphicsState *self,double x1,double y1,double x2, double y2,double x3,double y3,double x4,double y4){
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

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
//   bezier(self,_currentPoint.x,_currentPoint.y,cx1,cy1,cx2,cy2,x,y);
   NSInvalidAbstractInvocation();
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
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
     points[i].x=x+(XY[i*2]*c-XY[i*2+1]*s)*radiusx;
     points[i].y=y+(XY[i*2]*s+XY[i*2+1]*c)*radiusy;
    }

    [self moveToPoint:points[0].x:points[0].y];
    [self addCurveToPoint:points[1].x:points[1].y:points[2].x:points[2].y:points[3].x:points[3].y];
   }
}

-(void)save {
   NSInvalidAbstractInvocation();
}

-(void)restore {
   NSInvalidAbstractInvocation();
}

-(void)abort {
   NSInvalidAbstractInvocation();
}

-(void)clipToRect:(NSRect)clipRect  {
   NSInvalidAbstractInvocation();
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   NSInvalidAbstractInvocation();
}


-(void)scaleCTM:(float)scalex:(float)scaley {
   NSInvalidAbstractInvocation();
}

-(void)translateCTM:(float)tx:(float)ty {
   NSInvalidAbstractInvocation();
}

-(void)concatCTM:(CGAffineTransform)transform {
   NSInvalidAbstractInvocation();
}


-(void)beginPath {
   NSInvalidAbstractInvocation();
}

-(void)closePath {
   NSInvalidAbstractInvocation();
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   NSInvalidAbstractInvocation();
}

-(void)fillPath {
   NSInvalidAbstractInvocation();
}

-(void)strokePath {
   NSInvalidAbstractInvocation();
}

-(void)setDeviceColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   NSInvalidAbstractInvocation();
}

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize {
   NSInvalidAbstractInvocation();
}

-(void)setTextMatrix:(CGAffineTransform)transform {
   NSInvalidAbstractInvocation();
}

-(CGAffineTransform)textMatrix {
   NSInvalidAbstractInvocation();
   return CGAffineTransformIdentity;
}

-(void)moveto:(float)x:(float)y
        ashow:(const char *)cString:(int)length:(float)dx:(float)dy {
   NSInvalidAbstractInvocation();
}


-(void)showGlyphs:(const CGGlyph *)glyphs:(unsigned)numberOfGlyphs atPoint:(NSPoint)point {
   NSInvalidAbstractInvocation();
}

-(void)showGlyphs:(const CGGlyph *)glyphs advances:(const CGSize *)advances count:(unsigned)count {
   NSInvalidAbstractInvocation();
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point {
   NSInvalidAbstractInvocation();
}

-(void)fillRects:(const CGRect *)rects count:(unsigned)count {
   NSInvalidAbstractInvocation();
}

-(void)strokeRect:(CGRect)strokeRect width:(float)width {
   NSInvalidAbstractInvocation();
}

-(float)lineWidth {
   NSInvalidAbstractInvocation();
   return 0;
}

-(void)setLineWidth:(float)width {
   NSInvalidAbstractInvocation();
}

-(void)drawRGBAImageInRect:(NSRect)rect width:(int)width height:(int)height data:(unsigned int *)data fraction:(float)fraction {
   NSInvalidAbstractInvocation();
}

-(void)bitCopyToPoint:(NSPoint)dstOrigin renderingContext:(CGRenderingContext *)renderingContext fromPoint:(NSPoint)srcOrigin size:(NSSize)size {
   NSInvalidAbstractInvocation();
}


@end

void CGGraphicsSourceOver_rgba32_onto_bgrx32(unsigned char *sourceRGBA,unsigned char *resultBGRX,int width,int height,float fraction) {
   int sourceIndex=0;
   int sourceLength=width*height*4;
   int destinationReadIndex=0;
   int destinationWriteIndex=0;

   while(sourceIndex<sourceLength){
    unsigned srcr=sourceRGBA[sourceIndex++];
    unsigned srcg=sourceRGBA[sourceIndex++];
    unsigned srcb=sourceRGBA[sourceIndex++];
    unsigned srca=sourceRGBA[sourceIndex++]*fraction;

    unsigned dstb=resultBGRX[destinationReadIndex++];
    unsigned dstg=resultBGRX[destinationReadIndex++];
    unsigned dstr=resultBGRX[destinationReadIndex++];
    unsigned dsta=255-srca;

    destinationReadIndex++;

    dstr=(srcr*srca+dstr*dsta)>>8;
    dstg=(srcg*srca+dstg*dsta)>>8;
    dstb=(srcb*srca+dstb*dsta)>>8;

    resultBGRX[destinationWriteIndex++]=dstb;
    resultBGRX[destinationWriteIndex++]=dstg;
    resultBGRX[destinationWriteIndex++]=dstr;
    destinationWriteIndex++; // skip x
   }
}
