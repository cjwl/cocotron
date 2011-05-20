#import "O2Context_AntiGrain.h"
#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2MutablePath.h>
#import "O2AGGContext.h"

@implementation O2Context_AntiGrain
#ifdef ANTIGRAIN_PRESENT

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

#if 0
// If we supported path clipping we'd need to do this

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
#endif
}

-(void)drawPath:(O2PathDrawingMode)drawingMode { 
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
   
   O2GState    *gState=O2ContextCurrentGState(self);
   O2ColorRef   fillColor=O2ColorConvertToDeviceRGB(gState->_fillColor);
   const float *fillComps=O2ColorGetComponents(fillColor);
   O2ColorRef   strokeColor=O2ColorConvertToDeviceRGB(gState->_strokeColor);
   const float *strokeComps=O2ColorGetComponents(strokeColor);

   O2AGGContextSetBlendMode(_agg,O2GStateBlendMode(gState));

   transferPath(_agg,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));

   O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;

   if(doFill)
    O2AGGContextFillPath(_agg,fillComps[0],fillComps[1],fillComps[2],fillComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
      
   if(doEOFill)
    O2AGGContextEOFillPath(_agg,fillComps[0],fillComps[1],fillComps[2],fillComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

   if(doStroke){
    O2AGGContextSetLineWidth(_agg,gState->_lineWidth);
    O2AGGContextStrokePath(_agg,strokeComps[0],strokeComps[1],strokeComps[2],strokeComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
   }
   
   O2ColorRelease(fillColor);
   O2ColorRelease(strokeColor);
   
   O2PathReset(_path);
}

#endif
@end
