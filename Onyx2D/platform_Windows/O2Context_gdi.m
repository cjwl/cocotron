/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Onyx2D/O2Context_gdi.h>
#import "O2DeviceContext_gdiDIBSection.h"
#import <Onyx2D/O2Surface_DIBSection.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2DeviceContext_gdi.h>
#import <Onyx2D/O2MutablePath.h>
#import <Onyx2D/O2Color.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2DataProvider.h>
#import <Onyx2D/O2Shading.h>
#import <Onyx2D/O2Function.h>
#import <Onyx2D/O2Context_builtin.h>
#import <Onyx2D/O2PDFContext.h>
#import <Onyx2D/O2Font_gdi.h>
#import <Onyx2D/O2Image.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/Win32Font.h>
#import <Foundation/NSRaise.h>

static inline int float2int(float coord){
   return floorf(coord);
}

static inline BOOL transformIsFlipped(O2AffineTransform matrix){
   return (matrix.d<0)?YES:NO;
}

static NSRect Win32TransformRect(O2AffineTransform matrix,NSRect rect) {
   NSPoint point1=O2PointApplyAffineTransform(rect.origin,matrix);
   NSPoint point2=O2PointApplyAffineTransform(NSMakePoint(NSMaxX(rect),NSMaxY(rect)),matrix);

   if(point2.y<point1.y){
    float temp=point2.y;
    point2.y=point1.y;
    point1.y=temp;
   }

  return NSMakeRect(point1.x,point1.y,point2.x-point1.x,point2.y-point1.y);
}

static inline void GrayAToRGBA(float *input,float *output){
   output[0]=input[0];
   output[1]=input[0];
   output[2]=input[0];
   output[3]=input[1];
}

static inline void RGBAToRGBA(float *input,float *output){
   output[0]=input[0];
   output[1]=input[1];
   output[2]=input[2];
   output[3]=input[3];
}

static inline void CMYKAToRGBA(float *input,float *output){
#if 1
   float K=input[3];
   float C=(input[0]*(1-K)+K);
   float M=(input[1]*(1-K)+K);
   float Y=(input[2]*(1-K)+K);
   
   output[0]=(1-C);
   output[1]=(1-M);
   output[2]=(1-Y);
   output[3]=input[4];
#else
   float white=1-input[3];
   
   output[0]=(input[0]>white)?0:white-input[0];
   output[1]=(input[1]>white)?0:white-input[1];
   output[2]=(input[2]>white)?0:white-input[2];
#endif
}

static RECT NSRectToRECT(NSRect rect) {
   RECT result;

   if(rect.size.height<0)
    rect=NSZeroRect;
   if(rect.size.width<0)
    rect=NSZeroRect;

   result.top=float2int(rect.origin.y);
   result.left=float2int(rect.origin.x);
   result.bottom=float2int(rect.origin.y+rect.size.height);
   result.right=float2int(rect.origin.x+rect.size.width);

   return result;
}

@implementation O2Context_gdi

+(BOOL)canInitWithWindow:(CGWindow *)window {
   return YES;
}

+(BOOL)canInitBackingWithContext:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   NSString *name=[deviceDictionary objectForKey:@"O2Context"];
   
   if(name==nil || [name isEqual:@"GDI"])
    return YES;
    
   return NO;
}

-initWithGraphicsState:(O2GState *)state deviceContext:(O2DeviceContext_gdi *)deviceContext {
   [self initWithGraphicsState:state];
   _deviceContext=[deviceContext retain];
   _dc=[_deviceContext dc];
   _gdiFont=nil;

   return self;
}

-(void)dealloc {
   [_deviceContext release];
   [_gdiFont release];
   [super dealloc];
}

-(O2Surface *)createSurfaceWithWidth:(size_t)width height:(size_t)height {
   return [[O2Surface_DIBSection alloc] initWithWidth:width height:height compatibleWithDeviceContext:[self deviceContext]];
}

-(NSSize)pointSize {
   return [[self deviceContext] pointSize];
}

-(HDC)dc {
   return _dc;
}

-(HFONT)fontHandle {
   return [_gdiFont fontHandle];
}

-(O2Surface *)surface {
   return _surface;
}

-(O2DeviceContext_gdi *)deviceContext {
   return _deviceContext;
}

-(void)clipToState:(O2ClipState *)clipState {
   O2GState *gState=O2ContextCurrentGState(self);
   NSArray  *phases=[O2GStateClipState(gState) clipPhases];
   int       i,count=[phases count];
   
   O2DeviceContextClipReset_gdi(_dc);

   for(i=0;i<count;i++){
    O2ClipPhase *phase=[phases objectAtIndex:i];
    
    switch(O2ClipPhasePhaseType(phase)){
    
     case O2ClipPhaseNonZeroPath:;
      O2Path   *path=O2ClipPhaseObject(phase);

      O2DeviceContextClipToNonZeroPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      break;
      
     case O2ClipPhaseEOPath:{
       O2Path   *path=O2ClipPhaseObject(phase);

       O2DeviceContextClipToEvenOddPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      }
      break;

     case O2ClipPhaseMask:
      break;
}

}
}

-(void)drawPathInDeviceSpace:(O2Path *)path drawingMode:(int)mode state:(O2GState *)state {
   O2AffineTransform deviceTransform=state->_deviceSpaceTransform;
   O2Color *fillColor=state->_fillColor;
   O2Color *strokeColor=state->_strokeColor;
   XFORM current;
   XFORM userToDevice={deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,
                       (deviceTransform.d<0.0)?deviceTransform.ty/*-1.0*/:deviceTransform.ty};
   
   if(!GetWorldTransform(_dc,&current))
    NSLog(@"GetWorldTransform failed");

   if(!SetWorldTransform(_dc,&userToDevice))
    NSLog(@"ModifyWorldTransform failed");

   O2DeviceContextEstablishDeviceSpacePath_gdi(_dc,path,O2AffineTransformInvert(state->_userSpaceTransform));
      
   {
    HBRUSH fillBrush=CreateSolidBrush(COLORREFFromColor(fillColor));
    HBRUSH oldBrush=SelectObject(_dc,fillBrush);

    if(mode==kO2PathFill || mode==kO2PathFillStroke){
     SetPolyFillMode(_dc,WINDING);
     FillPath(_dc);
    }
    if(mode==kO2PathEOFill || mode==kO2PathEOFillStroke){
     SetPolyFillMode(_dc,ALTERNATE);
     FillPath(_dc);
    }
    SelectObject(_dc,oldBrush);
    DeleteObject(fillBrush);
   }
   
   if(mode==kO2PathStroke || mode==kO2PathFillStroke || mode==kO2PathEOFillStroke){
    DWORD    style;
    LOGBRUSH logBrush={BS_SOLID,COLORREFFromColor(strokeColor),0};
    
    style=PS_GEOMETRIC;
    if(state->_dashLengthsCount==0)
     style|=PS_SOLID;
    else
     style|=PS_USERSTYLE;
     
    switch(state->_lineCap){
     case kO2LineCapButt:
      style|=PS_ENDCAP_FLAT;
      break;
     case kO2LineCapRound:
      style|=PS_ENDCAP_ROUND;
      break;
     case kO2LineCapSquare:
      style|=PS_ENDCAP_SQUARE;
      break;
    }
    
    switch(state->_lineJoin){
     case kO2LineJoinMiter:
      style|=PS_JOIN_MITER;
      break;
     case kO2LineJoinRound:
      style|=PS_JOIN_ROUND;
      break;
     case kO2LineJoinBevel:
      style|=PS_JOIN_BEVEL;
      break;
    }

    DWORD  *dashes=NULL;
    DWORD   dashesCount=state->_dashLengthsCount;
    if(dashesCount>0){
     int i;
     dashes=__builtin_alloca(dashesCount*sizeof(DWORD));
     
     for(i=0;i<dashesCount;i++)
      dashes[i]=float2int(state->_dashLengths[i]);
    }
    
    HPEN   pen=ExtCreatePen(style,float2int(state->_lineWidth),&logBrush,dashesCount,dashes);
    HPEN   oldpen=SelectObject(_dc,pen);
    
    SetMiterLimit(_dc,state->_miterLimit,NULL);
    StrokePath(_dc);
    SelectObject(_dc,oldpen);
    DeleteObject(pen);
   }
   
   if(!SetWorldTransform(_dc,&current))
    NSLog(@"SetWorldTransform failed");
}


-(void)drawPath:(O2PathDrawingMode)pathMode {

   [self drawPathInDeviceSpace:_path drawingMode:pathMode state:O2ContextCurrentGState(self) ];
   
   O2PathReset(_path);
}

-(void)establishFontStateInDeviceIfDirty {
   O2GState *gState=O2ContextCurrentGState(self);
   
   if(gState->_fontIsDirty){
    O2GStateClearFontIsDirty(gState);
    [_gdiFont release];
    _gdiFont=[(O2Font_gdi *)O2GStateFont(gState) createGDIFontSelectedInDC:_dc pointSize:O2GStatePointSize(gState)];
   }
}

-(void)showGlyphs:(const O2Glyph *)glyphs advances:(const O2Size *)advances count:(unsigned)count {
// FIXME: use advances if not NULL
   O2AffineTransform transformToDevice=O2ContextGetUserSpaceToDeviceSpaceTransform(self);
   O2GState  *gState=O2ContextCurrentGState(self);
   O2AffineTransform Trm=O2AffineTransformConcat(_textMatrix,transformToDevice);
   NSPoint           point=O2PointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   [self establishFontStateInDeviceIfDirty];

   SetTextColor(_dc,COLORREFFromColor(O2ContextFillColor(self)));

   ExtTextOutW(_dc,lroundf(point.x),lroundf(point.y),ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);

   O2Font *font=O2GStateFont(gState);
   
   O2Size  defaultAdvances[count];
   
   O2ContextGetDefaultAdvances(self,glyphs,defaultAdvances,count);
   
   const O2Size *useAdvances;
    
   if(advances!=NULL)
    useAdvances=advances;
   else
    useAdvances=defaultAdvances;
      
   O2ContextConcatAdvancesToTextMatrix(self,useAdvances,count);
}


// The problem is that the GDI gradient fill is a linear/stitched filler and the
// Mac one is a sampling one. So to preserve color variation we stitch together a lot of samples

// we could use stitched linear PDF functions better, i.e. use the intervals
// we could decompose the rectangles further and just use fills if we don't have GradientFill (or ditch GradientFill altogether)
// we could test for cases where the angle is a multiple of 90 and use the _H or _V constants if we dont have transformations
// we could decompose this better to platform generalize it

static inline float axialBandIntervalFromMagnitude(O2Function *function,float magnitude){
   if(magnitude<1)
    return 0;

   if([function isLinear])
    return 1;
   
   if(magnitude<1)
    return 1;
   if(magnitude<4)
    return magnitude;
    
   return magnitude/4; // 4== arbitrary
}

#ifndef GRADIENT_FILL_RECT_H
#define GRADIENT_FILL_RECT_H 0
#endif

-(void)drawInUserSpace:(O2AffineTransform)matrix axialShading:(O2ShadingRef)shading {
   O2ColorSpaceRef colorSpace=O2ShadingColorSpace(shading);
   O2ColorSpaceModel colorSpaceType=[colorSpace type];
   O2Function   *function=[shading function];
   const float  *domain=[function domain];
   const float  *range=[function range];
   BOOL          extendStart=[shading extendStart];
   BOOL          extendEnd=[shading extendEnd];
   NSPoint       startPoint=O2PointApplyAffineTransform([shading startPoint],matrix);
   NSPoint       endPoint=O2PointApplyAffineTransform([shading endPoint],matrix);
   NSPoint       vector=NSMakePoint(endPoint.x-startPoint.x,endPoint.y-startPoint.y);
   float         magnitude=ceilf(sqrtf(vector.x*vector.x+vector.y*vector.y));
   float         angle=(magnitude==0)?0:(atanf(vector.y/vector.x)+((vector.x<0)?M_PI:0));
   float         bandInterval=axialBandIntervalFromMagnitude(function,magnitude);
   int           bandCount=bandInterval;
   int           i,rectIndex=0;
   float         rectWidth=(bandCount==0)?0:magnitude/bandInterval;
   float         domainInterval=(bandCount==0)?0:(domain[1]-domain[0])/bandInterval;
   GRADIENT_RECT rect[1+bandCount+1];
   int           vertexIndex=0;
   TRIVERTEX     vertices[(1+bandCount+1)*2];
   float         output[O2ColorSpaceGetNumberOfComponents(colorSpace)+1];
   float         rgba[4];
   void        (*outputToRGBA)(float *,float *);
   // should use something different here so we dont get huge numbers on printers, the clip bbox?
   int           hRes=GetDeviceCaps(_dc,HORZRES);
   int           vRes=GetDeviceCaps(_dc,VERTRES);
   float         maxHeight=MAX(hRes,vRes)*2;

   typedef WINGDIAPI BOOL WINAPI (*gradientType)(HDC,PTRIVERTEX,ULONG,PVOID,ULONG,ULONG);
   HANDLE        library=LoadLibrary("MSIMG32");
   gradientType  gradientFill=(gradientType)GetProcAddress(library,"GradientFill");
          
   if(gradientFill==NULL){
    NSLog(@"Unable to locate GradientFill");
    return;
   }

   switch(colorSpaceType){

    case kO2ColorSpaceModelMonochrome:
     outputToRGBA=GrayAToRGBA;
     break;
     
    case kO2ColorSpaceModelRGB:
     outputToRGBA=RGBAToRGBA;
     break;
     
    case kO2ColorSpaceModelCMYK:
     outputToRGBA=CMYKAToRGBA;
     break;
     
    default:
     NSLog(@"axial shading can't deal with colorspace %@",colorSpace);
     return;
   }
      
   if(extendStart){
    O2FunctionEvaluate(function,domain[0],output);
    outputToRGBA(output,rgba);
    
    rect[rectIndex].UpperLeft=vertexIndex;
    vertices[vertexIndex].x=float2int(-maxHeight);
    vertices[vertexIndex].y=float2int(-maxHeight);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;
    
    rect[rectIndex].LowerRight=vertexIndex;
 // the degenerative case for magnitude==0 is to fill the whole area with the extend
    if(magnitude!=0)
     vertices[vertexIndex].x=float2int(0);
    else {
     vertices[vertexIndex].x=float2int(maxHeight);
     extendEnd=NO;
    }
    vertices[vertexIndex].y=float2int(maxHeight);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;

    rectIndex++;
   }
  
   for(i=0;i<bandCount;i++){
    float x0=domain[0]+i*domainInterval;
    float x1=domain[0]+(i+1)*domainInterval;
   
    rect[rectIndex].UpperLeft=vertexIndex;
    vertices[vertexIndex].x=float2int(i*rectWidth);
    vertices[vertexIndex].y=float2int(-maxHeight);
    O2FunctionEvaluate(function,x0,output);
    outputToRGBA(output,rgba);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;
    
    rect[rectIndex].LowerRight=vertexIndex;
    vertices[vertexIndex].x=float2int((i+1)*rectWidth);
    vertices[vertexIndex].y=float2int(maxHeight);
    O2FunctionEvaluate(function,x1,output);
    outputToRGBA(output,rgba);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;

    rectIndex++;
   }
   
   if(extendEnd){
    O2FunctionEvaluate(function,domain[1],output);
    outputToRGBA(output,rgba);

    rect[rectIndex].UpperLeft=vertexIndex;
    vertices[vertexIndex].x=float2int(i*rectWidth);
    vertices[vertexIndex].y=float2int(-maxHeight);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;
    
    rect[rectIndex].LowerRight=vertexIndex;
    vertices[vertexIndex].x=float2int(maxHeight);
    vertices[vertexIndex].y=float2int(maxHeight);
    vertices[vertexIndex].Red=rgba[0]*0xFFFF;
    vertices[vertexIndex].Green=rgba[1]*0xFFFF;
    vertices[vertexIndex].Blue=rgba[2]*0xFFFF;
    vertices[vertexIndex].Alpha=rgba[3]*0xFFFF;
    vertexIndex++;

    rectIndex++;
   }
   
   if(rectIndex==0)
    return;
   
   {
    XFORM current;
    XFORM translate={1,0,0,1,startPoint.x,startPoint.y};
    XFORM rotate={cos(angle),sin(angle),-sin(angle),cos(angle),0,0};
     
    if(!GetWorldTransform(_dc,&current))
     NSLog(@"GetWorldTransform failed %s %d",__FILE__,__LINE__);
     
    if(!ModifyWorldTransform(_dc,&rotate,MWT_RIGHTMULTIPLY))
     NSLog(@"ModifyWorldTransform failed");
    if(!ModifyWorldTransform(_dc,&translate,MWT_RIGHTMULTIPLY))
     NSLog(@"ModifyWorldTransform failed %s %d",__FILE__,__LINE__);
    
    if(!gradientFill(_dc,vertices,vertexIndex,rect,rectIndex,GRADIENT_FILL_RECT_H))
     NSLog(@"GradientFill failed %s %d",__FILE__,__LINE__);

    if(!SetWorldTransform(_dc,&current))
     NSLog(@"GetWorldTransform failed %s %d",__FILE__,__LINE__);
   }
}

static int appendCircle(NSPoint *cp,int position,float x,float y,float radius,O2AffineTransform matrix){
   int i;
   
   O2MutablePathEllipseToBezier(cp+position,x,y,radius,radius);
   for(i=0;i<13;i++)
    cp[position+i]=O2PointApplyAffineTransform(cp[position+i],matrix);
    
   return position+13;
}

static void appendCircleToDC(HDC dc,NSPoint *cp){
   POINT   cPOINT[13];
   int     i,count=13;

   for(i=0;i<count;i++){
    cPOINT[i].x=float2int(cp[i].x);
    cPOINT[i].y=float2int(cp[i].y);
   }
   
   MoveToEx(dc,cPOINT[0].x,cPOINT[0].y,NULL);      
   PolyBezierTo(dc,cPOINT+1,count-1);
}

static void appendCircleToPath(HDC dc,float x,float y,float radius,O2AffineTransform matrix){
   NSPoint cp[13];
   
   appendCircle(cp,0,x,y,radius,matrix);
   appendCircleToDC(dc,cp);
}

static inline float numberOfRadialBands(O2Function *function,NSPoint startPoint,NSPoint endPoint,float startRadius,float endRadius,O2AffineTransform matrix){
   NSPoint startRadiusPoint=NSMakePoint(startRadius,0);
   NSPoint endRadiusPoint=NSMakePoint(endRadius,0);
   
   startPoint=O2PointApplyAffineTransform(startPoint,matrix);
   endPoint=O2PointApplyAffineTransform(endPoint,matrix);
   
   startRadiusPoint=O2PointApplyAffineTransform(startRadiusPoint,matrix);
   endRadiusPoint=O2PointApplyAffineTransform(endRadiusPoint,matrix);
{
   NSPoint lineVector=NSMakePoint(endPoint.x-startPoint.x,endPoint.y-startPoint.y);
   float   lineMagnitude=ceilf(sqrtf(lineVector.x*lineVector.x+lineVector.y*lineVector.y));
   NSPoint radiusVector=NSMakePoint(endRadiusPoint.x-startRadiusPoint.x,endRadiusPoint.y-startRadiusPoint.y);
   float   radiusMagnitude=ceilf(sqrtf(radiusVector.x*radiusVector.x+radiusVector.y*radiusVector.y))*2;
   float   magnitude=MAX(lineMagnitude,radiusMagnitude);

   return magnitude;
}
}

// FIX, still lame
static BOOL controlPointsOutsideClip(HDC dc,NSPoint cp[13]){
   NSRect clipRect,cpRect;
   RECT   gdiRect;
   int    i;
   
   if(!GetClipBox(dc,&gdiRect)){
    NSLog(@"GetClipBox failed");
    return NO;
   }
   clipRect.origin.x=gdiRect.left;
   clipRect.origin.y=gdiRect.top;
   clipRect.size.width=gdiRect.right-gdiRect.left;
   clipRect.size.height=gdiRect.bottom-gdiRect.top;
   
   clipRect.origin.x-=clipRect.size.width;
   clipRect.origin.y-=clipRect.size.height;
   clipRect.size.width*=3;
   clipRect.size.height*=3;
   
   for(i=0;i<13;i++)
    if(cp[i].x>50000 || cp[i].x<-50000 || cp[i].y>50000 || cp[i].y<-50000)
     return YES;
     
   for(i=0;i<13;i++)
    if(NSPointInRect(cp[i],clipRect))
     return NO;
     
   return YES;
}


static void extend(HDC dc,int i,int direction,float bandInterval,NSPoint startPoint,NSPoint endPoint,float startRadius,float endRadius,O2AffineTransform matrix){
// - some edge cases of extend are either slow or don't fill bands accurately but these are undesirable gradients

    {
     NSPoint lineVector=NSMakePoint(endPoint.x-startPoint.x,endPoint.y-startPoint.y);
     float   lineMagnitude=ceilf(sqrtf(lineVector.x*lineVector.x+lineVector.y*lineVector.y));
     
     if((lineMagnitude+startRadius)<endRadius){
      BeginPath(dc);
      if(direction<0)
       appendCircleToPath(dc,startPoint.x,startPoint.y,startRadius,matrix);
      else {
       NSPoint point=O2PointApplyAffineTransform(endPoint,matrix);

       appendCircleToPath(dc,endPoint.x,endPoint.y,endRadius,matrix);
       // FIX, lame
       appendCircleToPath(dc,point.x,point.y,1000000,O2AffineTransformIdentity);
      }
      EndPath(dc);
      FillPath(dc);
      return;
     }
     
     if((lineMagnitude+endRadius)<startRadius){
      BeginPath(dc);
      if(direction<0){
       NSPoint point=O2PointApplyAffineTransform(startPoint,matrix);
       
       appendCircleToPath(dc,startPoint.x,startPoint.y,startRadius,matrix);
       // FIX, lame
       appendCircleToPath(dc,point.x,point.y,1000000,O2AffineTransformIdentity);
      }
      else {
       appendCircleToPath(dc,endPoint.x,endPoint.y,endRadius,matrix);
      }
      EndPath(dc);
      FillPath(dc);
      return;
     }
    }

    for(;;i+=direction){
     float position,x,y,radius;
     RECT  check;
     NSPoint cp[13];
   
     BeginPath(dc);

     position=(float)i/bandInterval;
     x=startPoint.x+position*(endPoint.x-startPoint.x);
     y=startPoint.y+position*(endPoint.y-startPoint.y);
     radius=startRadius+position*(endRadius-startRadius);
     appendCircle(cp,0,x,y,radius,matrix);
     appendCircleToDC(dc,cp);
    
     position=(float)(i+direction)/bandInterval;
     x=startPoint.x+position*(endPoint.x-startPoint.x);
     y=startPoint.y+position*(endPoint.y-startPoint.y);
     radius=startRadius+position*(endRadius-startRadius);
     appendCircle(cp,0,x,y,radius,matrix);
     appendCircleToDC(dc,cp);
     
     EndPath(dc);

     FillPath(dc);
     
     if(radius<=0)
      break;
 
     if(controlPointsOutsideClip(dc,cp))
      break;
    }
}

-(void)drawInUserSpace:(O2AffineTransform)matrix radialShading:(O2ShadingRef)shading {
/* - band interval needs to be improved
    - does not factor resolution/scaling can cause banding
    - does not factor color sampling rate, generates multiple bands for same color
 */
   O2ColorSpaceRef colorSpace=O2ShadingColorSpace(shading);
   O2ColorSpaceModel colorSpaceType=[colorSpace type];
   O2Function   *function=[shading function];
   const float  *domain=[function domain];
   const float  *range=[function range];
   BOOL          extendStart=[shading extendStart];
   BOOL          extendEnd=[shading extendEnd];
   float         startRadius=[shading startRadius];
   float         endRadius=[shading endRadius];
   NSPoint       startPoint=[shading startPoint];
   NSPoint       endPoint=[shading endPoint];
   float         bandInterval=numberOfRadialBands(function,startPoint,endPoint,startRadius,endRadius,matrix);
   int           i,bandCount=bandInterval;
   float         domainInterval=(bandCount==0)?0:(domain[1]-domain[0])/bandInterval;
   float         output[O2ColorSpaceGetNumberOfComponents(colorSpace)+1];
   float         rgba[4];
   void        (*outputToRGBA)(float *,float *);

   switch(colorSpaceType){

    case kO2ColorSpaceModelMonochrome:
     outputToRGBA=GrayAToRGBA;
     break;
     
    case kO2ColorSpaceModelRGB:
     outputToRGBA=RGBAToRGBA;
     break;
     
    case kO2ColorSpaceModelCMYK:
     outputToRGBA=CMYKAToRGBA;
     break;
     
    default:
     NSLog(@"radial shading can't deal with colorspace %@",colorSpace);
     return;
   }

   if(extendStart){
    HBRUSH brush;

    O2FunctionEvaluate(function,domain[0],output);
    outputToRGBA(output,rgba);
    brush=CreateSolidBrush(RGB(rgba[0]*255,rgba[1]*255,rgba[2]*255));
    SelectObject(_dc,brush);
    SetPolyFillMode(_dc,ALTERNATE);
    extend(_dc,0,-1,bandInterval,startPoint,endPoint,startRadius,endRadius,matrix);
    DeleteObject(brush);
   }
   
   for(i=0;i<bandCount;i++){
    HBRUSH brush;
    float position,x,y,radius;
    float x0=((domain[0]+i*domainInterval)+(domain[0]+(i+1)*domainInterval))/2; // midpoint color between edges
    
    BeginPath(_dc);

    position=(float)i/bandInterval;
    x=startPoint.x+position*(endPoint.x-startPoint.x);
    y=startPoint.y+position*(endPoint.y-startPoint.y);
    radius=startRadius+position*(endRadius-startRadius);
    appendCircleToPath(_dc,x,y,radius,matrix);
    
    if(i+1==bandCount)
     appendCircleToPath(_dc,endPoint.x,endPoint.y,endRadius,matrix);
    else {
     position=(float)(i+1)/bandInterval;
     x=startPoint.x+position*(endPoint.x-startPoint.x);
     y=startPoint.y+position*(endPoint.y-startPoint.y);
     radius=startRadius+position*(endRadius-startRadius);
     appendCircleToPath(_dc,x,y,radius,matrix);
    }

    EndPath(_dc);

    O2FunctionEvaluate(function,x0,output);
    outputToRGBA(output,rgba);
    brush=CreateSolidBrush(RGB(output[0]*255,output[1]*255,output[2]*255));
    SelectObject(_dc,brush);
    SetPolyFillMode(_dc,ALTERNATE);
    FillPath(_dc);
    DeleteObject(brush);
   }
   
   if(extendEnd){
    HBRUSH brush;
    
    O2FunctionEvaluate(function,domain[1],output);
    outputToRGBA(output,rgba);
    brush=CreateSolidBrush(RGB(rgba[0]*255,rgba[1]*255,rgba[2]*255));
    SelectObject(_dc,brush);
    SetPolyFillMode(_dc,ALTERNATE);
    extend(_dc,i,1,bandInterval,startPoint,endPoint,startRadius,endRadius,matrix);

    DeleteObject(brush);
   }
}

-(void)drawShading:(O2ShadingRef)shading {
   O2AffineTransform transformToDevice=O2ContextGetUserSpaceToDeviceSpaceTransform(self);

  if([shading isAxial])
   [self drawInUserSpace:transformToDevice axialShading:shading];
  else
   [self drawInUserSpace:transformToDevice radialShading:shading];
}

#if 1

#if 0
static void sourceOverImage(O2Image *image,O2argb8u *resultBGRX,int width,int height,float fraction){
   O2argb8u *span=__builtin_alloca(width*sizeof(O2argb8u));
   int y,coverage=RI_INT_CLAMP(fraction*256,0,256);
   
   for(y=0;y<height;y++){
    O2argb8u *direct=image->_read_lRGBA8888_PRE(image,0,y,span,width);
    O2argb8u *combine=resultBGRX+width*y;
    
    if(direct!=NULL){
     int x;
     
     for(x=0;x<width;x++)
      span[x]=direct[x];
    }
    
    O2argb8u_sover_by_coverage(span,combine,coverage,width);
   }
}
#endif
void O2GraphicsSourceOver_rgba32_onto_bgrx32(unsigned char *sourceRGBA,unsigned char *resultBGRX,int width,int height,float fraction) {
   int sourceIndex=0;
   int sourceLength=width*height*4;
   int destinationReadIndex=0;
   int destinationWriteIndex=0;

   fraction *= 256.0/255.0;
   while(sourceIndex<sourceLength){
    unsigned srcr=sourceRGBA[sourceIndex++];
    unsigned srcg=sourceRGBA[sourceIndex++];
    unsigned srcb=sourceRGBA[sourceIndex++];
    unsigned srca=sourceRGBA[sourceIndex++]*fraction;

    unsigned dstb=resultBGRX[destinationReadIndex++];
    unsigned dstg=resultBGRX[destinationReadIndex++];
    unsigned dstr=resultBGRX[destinationReadIndex++];
    unsigned dsta=256-srca;

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

void O2GraphicsSourceOver_bgra32_onto_bgrx32(unsigned char *sourceBGRA,unsigned char *resultBGRX,int width,int height,float fraction) {
   int sourceIndex=0;
   int sourceLength=width*height*4;
   int destinationReadIndex=0;
   int destinationWriteIndex=0;

   fraction *= 256.0/255.0;
   while(sourceIndex<sourceLength){
    unsigned srcb=sourceBGRA[sourceIndex++];
    unsigned srcg=sourceBGRA[sourceIndex++];
    unsigned srcr=sourceBGRA[sourceIndex++];
    unsigned srca=sourceBGRA[sourceIndex++]*fraction;

    unsigned dstb=resultBGRX[destinationReadIndex++];
    unsigned dstg=resultBGRX[destinationReadIndex++];
    unsigned dstr=resultBGRX[destinationReadIndex++];
    unsigned dsta=256-srca;

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

-(void)drawBitmapImage:(O2Image *)image inRect:(NSRect)rect ctm:(O2AffineTransform)ctm fraction:(float)fraction  {
   int            width=O2ImageGetWidth(image);
   int            height=O2ImageGetHeight(image);
   const unsigned int *data=[image directBytes];
   HDC            sourceDC=_dc;
   HDC            combineDC;
   int            combineWidth=width;
   int            combineHeight=height;
   NSPoint        point=O2PointApplyAffineTransform(rect.origin,ctm);
   HBITMAP        bitmap;
   BITMAPINFO     info;
   void          *bits;
   O2argb8u    *combineBGRX;
   unsigned char *imageRGBA=(void *)data;

   rect.size=O2SizeApplyAffineTransform(rect.size,ctm);
   if(rect.size.height<0)
    rect.size.height=-rect.size.height;
    
   if(transformIsFlipped(ctm))
    point.y-=rect.size.height;

   if((combineDC=CreateCompatibleDC(sourceDC))==NULL){
    NSLog(@"CreateCompatibleDC failed");
    return;
   }

   info.bmiHeader.biSize=sizeof(BITMAPINFO);
   info.bmiHeader.biWidth=combineWidth;
   info.bmiHeader.biHeight=-combineHeight;
   info.bmiHeader.biPlanes=1;
   info.bmiHeader.biBitCount=32;
   info.bmiHeader.biCompression=BI_RGB;
   info.bmiHeader.biSizeImage=0;
   info.bmiHeader.biXPelsPerMeter=0;
   info.bmiHeader.biYPelsPerMeter=0;
   info.bmiHeader.biClrUsed=0;
   info.bmiHeader.biClrImportant=0;

   if((bitmap=CreateDIBSection(sourceDC,&info,DIB_RGB_COLORS,&bits,NULL,0))==NULL){
    NSLog(@"CreateDIBSection failed");
    return;
   }
   combineBGRX=bits;
   SelectObject(combineDC,bitmap);

   StretchBlt(combineDC,0,0,combineWidth,combineHeight,sourceDC,point.x,point.y,rect.size.width,rect.size.height,SRCCOPY);
   GdiFlush();

#if 1
   if((O2ImageGetAlphaInfo(image)==kO2ImageAlphaPremultipliedFirst) && (O2ImageGetBitmapInfo(image)&kO2BitmapByteOrderMask)==kO2BitmapByteOrder32Little)
    O2GraphicsSourceOver_bgra32_onto_bgrx32(imageRGBA,(unsigned char *)combineBGRX,width,height,fraction);
   else
    O2GraphicsSourceOver_rgba32_onto_bgrx32(imageRGBA,(unsigned char *)combineBGRX,width,height,fraction);
#else
   sourceOverImage(image,combineBGRX,width,height,fraction);
#endif

   StretchBlt(sourceDC,point.x,point.y,rect.size.width,rect.size.height,combineDC,0,0,combineWidth,combineHeight,SRCCOPY);

   DeleteObject(bitmap);
   DeleteDC(combineDC);
}

#else
// a work in progress
static void zeroBytes(void *bytes,int size){
   int i;
   
   for(i=0;i<size;i++)
    ((char *)bytes)[i]=0;
}

-(void)drawBitmapImage:(O2Image *)image inRect:(NSRect)rect ctm:(O2AffineTransform)ctm fraction:(float)fraction  {
   int            width=[image width];
   int            height=[image height];
   const unsigned char *bytes=[image bytes];
   HDC            sourceDC;
   BITMAPV4HEADER header;
   HBITMAP        bitmap;
   HGDIOBJ        oldBitmap;
   BLENDFUNCTION  blendFunction;
   
   if((sourceDC=CreateCompatibleDC(_dc))==NULL){
    NSLog(@"CreateCompatibleDC failed");
    return;
   }
   
   zeroBytes(&header,sizeof(header));
 
   header.bV4Size=sizeof(BITMAPINFOHEADER);
   header.bV4Width=width;
   header.bV4Height=height;
   header.bV4Planes=1;
   header.bV4BitCount=32;
   header.bV4V4Compression=BI_RGB;
   header.bV4SizeImage=width*height*4;
   header.bV4XPelsPerMeter=0;
   header.bV4YPelsPerMeter=0;
   header.bV4ClrUsed=0;
   header.bV4ClrImportant=0;
#if 0
   header.bV4RedMask=0xFF000000;
   header.bV4GreenMask=0x00FF0000;
   header.bV4BlueMask=0x0000FF00;
   header.bV4AlphaMask=0x000000FF;
#else
//   header.bV4RedMask=  0x000000FF;
//   header.bV4GreenMask=0x0000FF00;
//   header.bV4BlueMask= 0x00FF0000;
//   header.bV4AlphaMask=0xFF000000;
#endif
   header.bV4CSType=0;
  // header.bV4Endpoints;
  // header.bV4GammaRed;
  // header.bV4GammaGreen;
  // header.bV4GammaBlue;
   
   {
    char *bits;
    int  i;
    
   if((bitmap=CreateDIBSection(sourceDC,&header,DIB_RGB_COLORS,&bits,NULL,0))==NULL){
    NSLog(@"CreateDIBSection failed");
    return;
   }
   for(i=0;i<width*height*4;i++){
    bits[i]=0x00;
   }
   }
   if((oldBitmap=SelectObject(sourceDC,bitmap))==NULL)
    NSLog(@"SelectObject failed");

   rect=Win32TransformRect(ctm,rect);

   blendFunction.BlendOp=AC_SRC_OVER;
   blendFunction.BlendFlags=0;
   blendFunction.SourceConstantAlpha=0xFF;
   blendFunction.BlendOp=AC_SRC_ALPHA;
   {
    typedef WINGDIAPI BOOL WINAPI (*alphaType)(HDC,int,int,int,int,HDC,int,int,int,int,BLENDFUNCTION);

    HANDLE library=LoadLibrary("MSIMG32");
    alphaType alphaBlend=(alphaType)GetProcAddress(library,"AlphaBlend");

    if(alphaBlend==NULL)
     NSLog(@"Unable to get AlphaBlend",alphaBlend);
    else {
     if(!alphaBlend(_dc,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,sourceDC,0,0,width,height,blendFunction))
      NSLog(@"AlphaBlend failed");
    }
   }

   DeleteObject(bitmap);s
   SelectObject(sourceDC,oldBitmap);
   DeleteDC(sourceDC);
}
#endif

-(void)drawImage:(O2Image *)image inRect:(O2Rect)rect {
   O2AffineTransform transformToDevice=O2ContextGetUserSpaceToDeviceSpaceTransform(self);
   O2GState *gState=O2ContextCurrentGState(self);
   O2ClipPhase     *phase=[[O2GStateClipState(gState) clipPhases] lastObject];
   
/* The NSImage drawing methods which take a fraction use a 1x1 alpha mask to set the fraction.
   We don't do alpha masks yet but the rough fraction code already existed so we check for this
   special case and generate a fraction from the 1x1 mask. Any other case is ignored.
 */
   float fraction=1.0;

   if(phase!=nil && O2ClipPhasePhaseType(phase)==O2ClipPhaseMask){
    O2Image *mask=O2ClipPhaseObject(phase);
    
    if(O2ImageGetWidth(mask)==1 && O2ImageGetHeight(mask)==1){
     uint8_t byte=255;
     
     if([O2ImageGetDataProvider(mask) getBytes:&byte range:NSMakeRange(0,1)]==1)
      fraction=(float)byte/255.0f;
    }
   }
   
   [self drawBitmapImage:image inRect:rect ctm:transformToDevice fraction:fraction];
}

-(void)drawDeviceContext:(O2DeviceContext_gdi *)deviceContext inRect:(NSRect)rect ctm:(O2AffineTransform)ctm {
   rect.origin=O2PointApplyAffineTransform(rect.origin,ctm);

   if(transformIsFlipped(ctm))
    rect.origin.y-=rect.size.height;

   BitBlt([self dc],rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,[deviceContext dc],0,0,SRCCOPY);
}

-(void)drawLayer:(O2Layer *)layer inRect:(NSRect)rect {
   O2ContextRef context=O2LayerGetContext(layer);
   
   if(![context isKindOfClass:[O2Context_gdi class]]){
    NSLog(@"layer class is not right %@!=%@",[context class],[self class]);
    return;
   }
   O2DeviceContext_gdi *deviceContext=[(O2Context_gdi *)context deviceContext];
   
   [self drawDeviceContext:deviceContext inRect:rect ctm:O2ContextCurrentGState(self)->_deviceSpaceTransform];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState {
   O2AffineTransform transformToDevice=O2ContextGetUserSpaceToDeviceSpaceTransform(self);
   NSRect  srcRect=Win32TransformRect(transformToDevice,rect);
   NSRect  dstRect=Win32TransformRect(transformToDevice,NSMakeRect(point.x,point.y,rect.size.width,rect.size.height));
   NSRect  scrollRect=NSUnionRect(srcRect,dstRect);
   int     dx=dstRect.origin.x-srcRect.origin.x;
   int     dy=dstRect.origin.y-srcRect.origin.y;
   RECT    winScrollRect=NSRectToRECT(scrollRect);

   ScrollDC(_dc,dx,dy,&winScrollRect,&winScrollRect,NULL,NULL);
}

-(void)close {
   [[self deviceContext] endPrinting];
}

-(void)beginPage:(const NSRect *)mediaBox {
   [[self deviceContext] beginPage];
}

-(void)endPage {
   [[self deviceContext] endPage];
}

-(BOOL)getImageableRect:(NSRect *)rect {
   O2DeviceContext_gdi *deviceContext=[self deviceContext];
   if(deviceContext==nil)
    return NO;
    
   *rect=[deviceContext imageableRect];
   return YES;
}

-(void)flush {
   GdiFlush();
}

@end
