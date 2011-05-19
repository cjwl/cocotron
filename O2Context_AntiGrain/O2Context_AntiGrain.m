#import "O2Context_AntiGrain.h"
#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2MutablePath.h>
#import "O2AGGContext.h"

@implementation O2Context_AntiGrain

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   
   _agg=O2AGGContextCreateBGRA32((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),O2SurfaceGetBytesPerRow(surface));
   // if _agg is NULL here it's 
   return self;
}

static void transferPath(O2AGGContextRef agg,O2PathRef path,O2AffineTransform xform){
   const unsigned char *elements=O2PathElements(path);
   const O2Point       *points=O2PathPoints(path);
   unsigned             i,numberOfElements=O2PathNumberOfElements(path),pointIndex;

   pointIndex=0;

   O2AGGContextBeginPath(agg);
   
   for(i=0;i<numberOfElements;i++){
   
    switch(elements[i]){

     case kO2PathElementMoveToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
    
       O2AGGContextMoveTo(agg,point.x,point.y);
      }
      break;
       
     case kO2PathElementAddLineToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
        
       O2AGGContextAddLineTo(agg,point.x,point.y);
      }
      break;

     case kO2PathElementAddCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=O2PointApplyAffineTransform(points[pointIndex++],xform);

       O2AGGContextAddCurveToPoint(agg,cp1.x,cp1.y,cp2.x,cp2.y,end.x,end.y);
      }
      break;

     case kO2PathElementAddQuadCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);

       O2AGGContextAddQuadCurveToPoint(agg,cp1.x,cp1.y,cp2.x,cp2.y);
      }
      break;

     case kO2PathElementCloseSubpath:
      O2AGGContextCloseSubpath(agg);
      break;
    }    
   }
   
}

-(void)clipToState:(O2ClipState *)clipState {
   [super clipToState:clipState];

   O2AGGContextSetDeviceViewport(_agg,_vpx,_vpy,_vpwidth,_vpheight);
       
   O2GState *gState=O2ContextCurrentGState(self);
   NSArray  *phases=[O2GStateClipState(gState) clipPhases];
   int       i,count=[phases count];
   
  // O2AGGContextClipReset(_agg);
   
   for(i=0;i<count;i++){
    O2ClipPhase *phase=[phases objectAtIndex:i];
    O2Path      *path;
    
    switch(O2ClipPhasePhaseType(phase)){
    
     case O2ClipPhaseNonZeroPath:
      path=O2ClipPhaseObject(phase);
   
  //    O2DeviceContextClipToNonZeroPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      break;
      
     case O2ClipPhaseEOPath:
      path=O2ClipPhaseObject(phase);

  //    O2DeviceContextClipToEvenOddPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      break;
      
     case O2ClipPhaseMask:
      break;
    }

   }
}

-(void)drawPath:(O2PathDrawingMode)drawingMode {
   O2GState *gState=O2ContextCurrentGState(self);
   
   transferPath(_agg,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));

   O2ColorRef   fillColor=O2ColorConvertToDeviceRGB(gState->_fillColor);
   const float *fill=O2ColorGetComponents(fillColor);
   O2ColorRef   strokeColor=O2ColorConvertToDeviceRGB(gState->_strokeColor);
   const float *stroke=O2ColorGetComponents(strokeColor);

   O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;

   BOOL doFill=NO;
   BOOL doEOFill=NO;
   BOOL doStroke=NO;
   
   switch(drawingMode){
   
    case kO2PathFill:
     doFill=YES;
     break;

    case kO2PathEOFill:
     doEOFill=YES;
     break;

    case kO2PathStroke:
     doStroke=YES;
     break;

    case kO2PathFillStroke:
     doFill=YES;
     doStroke=YES;
     break;

    case kO2PathEOFillStroke:
     doEOFill=YES;
     doStroke=YES;
     break;
     
   }
   
   if(doFill)
    O2AGGContextFillPath(_agg,fill[0],fill[1],fill[2],fill[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
      
   if(doEOFill)
    O2AGGContextEOFillPath(_agg,fill[0],fill[1],fill[2],fill[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

   if(doStroke)
    O2AGGContextStrokePath(_agg,stroke[0],stroke[1],stroke[2],stroke[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

    O2ColorRelease(fillColor);
    O2ColorRelease(strokeColor);
   
   O2PathReset(_path);
}

@end
