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
       
   O2GState *gState=O2ContextCurrentGState(self);
   NSArray  *phases=[O2GStateClipState(gState) clipPhases];
   int       i,count=[phases count];
   
 //  O2DeviceContextClipReset_gdi(_dc);
   
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
   
   if(drawingMode==kO2PathFill){
    O2ColorRef   rgbColor=O2ColorConvertToDeviceRGB(gState->_fillColor);
    const float *components=O2ColorGetComponents(rgbColor);
    
    transferPath(_agg,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));

    O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
    
    O2AGGContextFillPath(_agg,components[0],components[1],components[2],components[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

    O2ColorRelease(rgbColor);
    O2PathReset(_path);
   }
   else {
//    O2PathReset(_path);
    [super drawPath:drawingMode];
   }
}

@end
