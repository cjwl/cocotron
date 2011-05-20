#import "O2Context_AntiGrain.h"
#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2MutablePath.h>

@implementation O2Context_AntiGrain
#ifdef ANTIGRAIN_PRESENT

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   
   renderingBuffer=new agg::rendering_buffer((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),O2SurfaceGetBytesPerRow(surface));
   pixelFormat=new pixfmt_type(*(self->renderingBuffer));
   rasterizer=new agg::rasterizer_scanline_aa<>();
   ren_base=new renderer_base(*(self->pixelFormat));
   path=new agg::path_storage();

   return self;
}

static void transferPath(O2Context_AntiGrain *self,O2PathRef path,O2AffineTransform xform){
   const unsigned char *elements=O2PathElements(path);
   const O2Point       *points=O2PathPoints(path);
   unsigned             i,numberOfElements=O2PathNumberOfElements(path),pointIndex;

   pointIndex=0;

   self->path->remove_all();
   
   for(i=0;i<numberOfElements;i++){
   
    switch(elements[i]){

     case kO2PathElementMoveToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
    
       self->path->move_to(point.x,point.y);
      }
      break;
       
     case kO2PathElementAddLineToPoint:{
       NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
        
       self->path->line_to(point.x,point.y);
      }
      break;

     case kO2PathElementAddCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint end=O2PointApplyAffineTransform(points[pointIndex++],xform);

       self->path->curve4(cp1.x,cp1.y,cp2.x,cp2.y,end.x,end.y);
      }
      break;

     case kO2PathElementAddQuadCurveToPoint:{
       NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
       NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);

       self->path->curve3(cp1.x,cp1.y,cp2.x,cp2.y);
      }
      break;

     case kO2PathElementCloseSubpath:
      self->path->end_poly();
      break;
    }    
   }
   
}

-(void)clipToState:(O2ClipState *)clipState {
   [super clipToState:clipState];

   self->ren_base->reset_clipping(1);
   self->ren_base->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight);

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

void O2AGGContextSetBlendMode(O2Context_AntiGrain *self,O2BlendMode blendMode){
   enum agg::comp_op_e blendModeMap[28]={
    agg::comp_op_src_over,
    agg::comp_op_multiply,
    agg::comp_op_screen,
    agg::comp_op_overlay,
    agg::comp_op_darken,
    agg::comp_op_lighten,
    agg::comp_op_color_dodge,
    agg::comp_op_color_burn,
    agg::comp_op_hard_light,
    agg::comp_op_soft_light,
    agg::comp_op_difference,
    agg::comp_op_exclusion,
    agg::comp_op_src_over, // Hue
    agg::comp_op_src_over, // Saturation
    agg::comp_op_src_over, // Color
    agg::comp_op_src_over, // Luminosity
    agg::comp_op_clear,
    agg::comp_op_src,
    agg::comp_op_src_in,
    agg::comp_op_src_out,
    agg::comp_op_src_atop,
    agg::comp_op_dst_over,
    agg::comp_op_dst_in,
    agg::comp_op_dst_out,
    agg::comp_op_dst_atop,
    agg::comp_op_xor,
    agg::comp_op_plus, // PlusDarker
    agg::comp_op_minus, // PlusLighter
   };

   self->pixelFormat->comp_op(blendModeMap[blendMode]);
}


void O2AGGContextFillPathWithRule(O2Context_AntiGrain *self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty,agg::filling_rule_e fillingRule) {
   
   agg::scanline_u8 sl;

   agg::trans_affine mtx(xa,xb,xc,xd,xtx,xty);

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, mtx);

   curve.approximation_scale(mtx.scale());
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(fillingRule);
   
   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),agg::rgba(r,g,b,a));
}

void O2AGGContextFillPath(O2Context_AntiGrain *self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   O2AGGContextFillPathWithRule(self,r,g,b,a,xa,xb,xc,xd,xtx,xty,agg::fill_non_zero);
}

void O2AGGContextEOFillPath(O2Context_AntiGrain *self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   O2AGGContextFillPathWithRule(self,r,g,b,a,xa,xb,xc,xd,xtx,xty,agg::fill_even_odd);
}

void O2AGGContextStrokePath(O2Context_AntiGrain *self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   O2GState *gState=O2ContextCurrentGState(self);

   agg::scanline_u8 sl;

   agg::trans_affine mtx(xa,xb,xc,xd,xtx,xty);

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
   agg::conv_transform<agg::conv_stroke<agg::conv_curve<agg::path_storage> >, agg::trans_affine> trans(stroke, mtx);

   curve.approximation_scale(mtx.scale());
   

   
   stroke.width(gState->_lineWidth);
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(agg::fill_non_zero);

   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),agg::rgba(r,g,b,a));
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

   O2AGGContextSetBlendMode(self,O2GStateBlendMode(gState));

   transferPath(self,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));

   O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;

   if(doFill)
    O2AGGContextFillPath(self,fillComps[0],fillComps[1],fillComps[2],fillComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
      
   if(doEOFill)
    O2AGGContextEOFillPath(self,fillComps[0],fillComps[1],fillComps[2],fillComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

   if(doStroke){
    O2AGGContextStrokePath(self,strokeComps[0],strokeComps[1],strokeComps[2],strokeComps[3],
      deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
   }
   
   O2ColorRelease(fillColor);
   O2ColorRelease(strokeColor);
   
   O2PathReset(_path);
}

#endif
@end
