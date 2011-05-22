/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2DeviceContext_gdi.h>
#import <Onyx2D/O2Path.h>
#import <Onyx2D/O2Color.h>
#import <Onyx2D/O2ColorSpace.h>

COLORREF COLORREFFromColor(O2Color *color){
   O2ColorRef   rgbColor=O2ColorConvertToDeviceRGB(color);
   const float *components=O2ColorGetComponents(rgbColor);
   
   COLORREF result=RGB(RI_INT_CLAMP(components[0]*255,0,255),RI_INT_CLAMP(components[1]*255,0,255),RI_INT_CLAMP(components[2]*255,0,255));

   O2ColorRelease(rgbColor);
     
   return result;
     }
               
@implementation O2DeviceContext_gdi

-initWithDC:(HDC)dc {
   _dc=dc;
   
   SetGraphicsMode(_dc,GM_ADVANCED);

   if(SetMapMode(_dc,MM_ANISOTROPIC)==0)
    NSLog(@"SetMapMode failed");
   //SetICMMode(_dc,ICM_ON); MSDN says only available on 2000, not NT.

   SetBkMode(_dc,TRANSPARENT);
   SetTextAlign(_dc,TA_BASELINE);

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

void O2DeviceContextEstablishDeviceSpacePath_gdi(HDC dc,O2Path *path,O2AffineTransform xform) {
   unsigned             opCount=O2PathNumberOfElements(path);
   const unsigned char *elements=O2PathElements(path);
   unsigned             pointCount=O2PathNumberOfPoints(path);
   const NSPoint       *points=O2PathPoints(path);
   unsigned             i,pointIndex;
       
   BeginPath(dc);
   
   pointIndex=0;
   for(i=0;i<opCount;i++){
    switch(elements[i]){

     case kO2PathElementMoveToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
        
       MoveToEx(dc,float2int(point.x),float2int(point.y),NULL);
      }
      break;
       
     case kO2PathElementAddLineToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
        
       LineTo(dc,float2int(point.x),float2int(point.y));
      }
      break;

     case kO2PathElementAddCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=O2PointApplyAffineTransform(points[pointIndex++],xform);
       POINT   points[3]={
        { float2int(cp1.x), float2int(cp1.y) },
        { float2int(cp2.x), float2int(cp2.y) },
        { float2int(end.x), float2int(end.y) },
       };
        
       PolyBezierTo(dc,points,3);
      }
      break;

// FIX, this is wrong
     case kO2PathElementAddQuadCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=cp2;
       POINT   points[3]={
        { float2int(cp1.x), float2int(cp1.y) },
        { float2int(cp2.x), float2int(cp2.y) },
        { float2int(end.x), float2int(end.y) },
       };
        
       PolyBezierTo(dc,points,3);
      }
      break;

     case kO2PathElementCloseSubpath:
      CloseFigure(dc);
      break;
    }
   }
   EndPath(dc);
}

void O2DeviceContextClipReset_gdi(HDC dc) {
// These two should effectively be the same, an the latter is preferred. But needs testing. Possibly not working (e.g. AC)
#if 1
   HRGN region=CreateRectRgn(0,0,GetDeviceCaps(dc,HORZRES),GetDeviceCaps(dc,VERTRES));
   if(!SelectClipRgn(dc,region)){
    if(NSDebugEnabled)
     NSLog(@"SelectClipRgn failed (%i), HORZRES=%i,VERTRES=%i", GetLastError(),GetDeviceCaps(dc,HORZRES),GetDeviceCaps(dc,VERTRES));
   }
   DeleteObject(region);
#else
   if(!SelectClipRgn(dc,NULL)){
    if(NSDebugEnabled)
     NSLog(@"SelectClipRgn failed (%i), HORZRES=%i,VERTRES=%i", GetLastError(),GetDeviceCaps(dc,HORZRES),GetDeviceCaps(dc,VERTRES));
   }
#endif
}

void O2DeviceContextClipToPath_gdi(HDC dc,O2Path *path,O2AffineTransform xform,O2AffineTransform deviceXFORM,BOOL evenOdd){
   XFORM current;
   XFORM userToDevice={deviceXFORM.a,deviceXFORM.b,deviceXFORM.c,deviceXFORM.d,deviceXFORM.tx,deviceXFORM.ty};
    
   if(!GetWorldTransform(dc,&current)){
    if(NSDebugEnabled)
     NSLog(@"GetWorldTransform failed (%i) %s %i",GetLastError(),__FILE__,__LINE__);

    current=(XFORM){1.0f,0.0f,0.0f,1.0f,0.0f,0.0f};
   }
   
   if(!SetWorldTransform(dc,&userToDevice)){
    if(NSDebugEnabled)
     NSLog(@"SetWorldTransform failed (%i) %s %i",GetLastError(),__FILE__,__LINE__);
   }
   
   O2DeviceContextEstablishDeviceSpacePath_gdi(dc,path,xform);
   SetPolyFillMode(dc,evenOdd?ALTERNATE:WINDING);
   
   if(!SelectClipPath(dc,RGN_AND)){
    if(NSDebugEnabled)
     NSLog(@"SelectClipPath failed (%i), path size= %d", GetLastError(),O2PathNumberOfElements(path));
   }
    
   if(!SetWorldTransform(dc,&current)){
    if(NSDebugEnabled)
     NSLog(@"SetWorldTransform failed (%i) %s %i",GetLastError(),__FILE__,__LINE__);
   }
}

void O2DeviceContextClipToNonZeroPath_gdi(HDC dc,O2Path *path,O2AffineTransform xform,O2AffineTransform deviceXFORM){
   O2DeviceContextClipToPath_gdi(dc,path,xform,deviceXFORM,NO);
}

void O2DeviceContextClipToEvenOddPath_gdi(HDC dc,O2Path *path,O2AffineTransform xform,O2AffineTransform deviceXFORM){
   O2DeviceContextClipToPath_gdi(dc,path,xform,deviceXFORM,YES);
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
