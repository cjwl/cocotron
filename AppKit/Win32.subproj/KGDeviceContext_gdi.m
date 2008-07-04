/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/KGDeviceContext_gdi.h>
#import <AppKit/KGPath.h>

@implementation KGDeviceContext_gdi

-initWithDC:(HDC)dc {
   _dc=dc;
   return self;
}

-(HDC)dc {
   return _dc;
}

-(Win32DeviceContextWindow *)windowDeviceContext {
   return nil;
}

static inline int float2int(float coord){
   return floorf(coord);
}

-(void)establishDeviceSpacePath:(KGPath *)path withTransform:(CGAffineTransform)xform {
   unsigned             opCount=[path numberOfElements];
   const unsigned char *elements=[path elements];
   unsigned             pointCount=[path numberOfPoints];
   const NSPoint       *points=[path points];
   unsigned             i,pointIndex;
       
   BeginPath(_dc);
   
   pointIndex=0;
   for(i=0;i<opCount;i++){
    switch(elements[i]){

     case kCGPathElementMoveToPoint:{
       NSPoint point=CGPointApplyAffineTransform(points[pointIndex++],xform);
        
       MoveToEx(_dc,float2int(point.x),float2int(point.y),NULL);
      }
      break;
       
     case kCGPathElementAddLineToPoint:{
       NSPoint point=CGPointApplyAffineTransform(points[pointIndex++],xform);
        
       LineTo(_dc,float2int(point.x),float2int(point.y));
      }
      break;

     case kCGPathElementAddCurveToPoint:{
       NSPoint cp1=CGPointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=CGPointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=CGPointApplyAffineTransform(points[pointIndex++],xform);
       POINT   points[3]={
        { float2int(cp1.x), float2int(cp1.y) },
        { float2int(cp2.x), float2int(cp2.y) },
        { float2int(end.x), float2int(end.y) },
       };
        
       PolyBezierTo(_dc,points,3);
      }
      break;

// FIX, this is wrong
     case kCGPathElementAddQuadCurveToPoint:{
       NSPoint cp1=CGPointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=CGPointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=cp2;
       POINT   points[3]={
        { float2int(cp1.x), float2int(cp1.y) },
        { float2int(cp2.x), float2int(cp2.y) },
        { float2int(end.x), float2int(end.y) },
       };
        
       PolyBezierTo(_dc,points,3);
      }
      break;

     case kCGPathElementCloseSubpath:
      CloseFigure(_dc);
      break;
    }
   }
   EndPath(_dc);
}

-(void)clipReset {
   HRGN _clipRegion=CreateRectRgn(0,0,GetDeviceCaps(_dc,HORZRES),GetDeviceCaps(_dc,VERTRES));
   SelectClipRgn(_dc,_clipRegion);
   DeleteObject(_clipRegion);
}

-(void)clipToPath:(KGPath *)path withTransform:(CGAffineTransform)xform deviceTransform:(CGAffineTransform)deviceXFORM evenOdd:(BOOL)evenOdd {
   XFORM current;
   XFORM userToDevice={deviceXFORM.a,deviceXFORM.b,deviceXFORM.c,deviceXFORM.d,deviceXFORM.tx,deviceXFORM.ty};

   if(!GetWorldTransform(_dc,&current))
    NSLog(@"GetWorldTransform failed");

   if(!SetWorldTransform(_dc,&userToDevice))
    NSLog(@"ModifyWorldTransform failed");

   [self establishDeviceSpacePath:path withTransform:xform];
   SetPolyFillMode(_dc,evenOdd?ALTERNATE:WINDING);
   if(!SelectClipPath(_dc,RGN_AND))
    NSLog(@"SelectClipPath failed (%i), path size= %d", GetLastError(),[path numberOfElements]);

   if(!SetWorldTransform(_dc,&current))
    NSLog(@"SetWorldTransform failed");
}

-(void)clipToNonZeroPath:(KGPath *)path withTransform:(CGAffineTransform)xform deviceTransform:(CGAffineTransform)deviceXFORM {
   [self clipToPath:(KGPath *)path withTransform:(CGAffineTransform)xform deviceTransform:(CGAffineTransform)deviceXFORM evenOdd:NO];
}

-(void)clipToEvenOddPath:(KGPath *)path withTransform:(CGAffineTransform)xform deviceTransform:(CGAffineTransform)deviceXFORM {
   [self clipToPath:(KGPath *)path withTransform:(CGAffineTransform)xform deviceTransform:(CGAffineTransform)deviceXFORM evenOdd:YES];
}

-(void)beginPrintingWithDocumentName:(NSString *)name {
   // do nothing
}

-(void)endPrinting {
   // do nothing
}

-(void)beginPage {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(unsigned)bitsPerPixel {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(NSSize)pixelsPerInch {
   [self doesNotRecognizeSelector:_cmd];
   return NSMakeSize(0,0);
}

-(NSSize)pixelSize {
   float pixelsWide=GetDeviceCaps(_dc,HORZRES);
   float pixelsHigh=GetDeviceCaps(_dc,VERTRES);
   
   return NSMakeSize(pixelsWide,pixelsHigh);
}

-(NSSize)pointSize {
   NSSize pixelPerInch=[self pixelsPerInch];
   NSSize pixelSize=[self pixelSize];

   float pointsWide=(pixelSize.width/pixelPerInch.width)*72.0;
   float pointsHigh=(pixelSize.height/pixelPerInch.height)*72.0;
   
   return NSMakeSize(pointsWide,pointsHigh);
}

-(NSRect)paperRect {
   NSRect result;
   
   result.size=[self pointSize];
   result.origin=NSMakePoint(0,0);
   
   return result;
}

-(NSRect)imageableRect {
   return [self paperRect];
}


@end
