#import "O2Context_AntiGrain.h"
#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2MutablePath.h>

@implementation O2Context_AntiGrain
#ifdef ANTIGRAIN_PRESENT
// If AntiGrain is not present it will just be a non-overriding subclass of the builtin context, so no problems

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   
   renderingBuffer=new agg::rendering_buffer((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),O2SurfaceGetBytesPerRow(surface));
   pixelFormat=new pixfmt_type(*(self->renderingBuffer));
   rasterizer=new agg::rasterizer_scanline_aa<>();
   ren_base=new renderer_base(*(self->pixelFormat));
   path=new agg::path_storage();

   return self;
}

-(void)dealloc {
   delete renderingBuffer;
   delete pixelFormat;
   delete rasterizer;
   delete ren_base;
   delete path;
   [super dealloc];
}

/* Transfer path from Onyx2D to AGG. Not a very expensive operation, tessellation, stroking and rasterization are the expensive pieces
 */
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

/*
   The builtin Onyx2D renderer only supports viewport clipping (one integer rect), so once the superclass has clipped
   the viewport is what we want to clip to also. The base AGG renderer also does viewport clipping, so we just set it.
 */
   self->ren_base->reset_clipping(1);
   self->ren_base->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight);

/*
   It's possible to add path clipping using an alpha mask but that is not implemented here.
 */

}

void O2AGGContextSetBlendMode(O2Context_AntiGrain *self,O2BlendMode blendMode){
// Onyx2D -> AGG blend mode conversion

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


void O2AGGContextFillPathWithRule(O2Context_AntiGrain *self,agg::rgba color,agg::trans_affine deviceMatrix,agg::filling_rule_e fillingRule) {
   
   agg::scanline_u8 sl;

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, deviceMatrix);

   curve.approximation_scale(deviceMatrix.scale());
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(fillingRule);
   
   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),color);
}

static void O2AGGContextStrokePath(O2Context_AntiGrain *self,agg::rgba color,agg::trans_affine deviceMatrix) {
   O2GState *gState=O2ContextCurrentGState(self);

   agg::scanline_u8 sl;

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
   agg::conv_transform<agg::conv_stroke<agg::conv_curve<agg::path_storage> >, agg::trans_affine> trans(stroke, deviceMatrix);

   curve.approximation_scale(deviceMatrix.scale());
   stroke.approximation_scale(deviceMatrix.scale());
   
   switch(gState->_lineJoin){
    case kO2LineJoinMiter:
     stroke.line_join(agg::miter_join);
     break;
     
    case kO2LineJoinRound:
     stroke.line_join(agg::round_join);
     break;

    case kO2LineJoinBevel:
     stroke.line_join(agg::bevel_join);
     break;

   }
   
   switch(gState->_lineCap){
    case kO2LineCapButt:
     stroke.line_cap(agg::butt_cap);
     break;

    case kO2LineCapRound:
     stroke.line_cap(agg::round_cap);
     break;

    case kO2LineCapSquare:
     stroke.line_cap(agg::square_cap);
     break;
   }
   
   stroke.width(gState->_lineWidth);
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(agg::fill_non_zero);

   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),color);
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

   agg::rgba aggFillColor(fillComps[0],fillComps[1],fillComps[2],fillComps[3]);
   agg::rgba aggStrokeColor(strokeComps[0],strokeComps[1],strokeComps[2],strokeComps[3]);
   agg::trans_affine aggDeviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

   if(doFill)
    O2AGGContextFillPathWithRule(self,aggFillColor,aggDeviceMatrix,agg::fill_non_zero);
      
   if(doEOFill)
    O2AGGContextFillPathWithRule(self,aggFillColor,aggDeviceMatrix,agg::fill_even_odd);

   if(doStroke){
    O2AGGContextStrokePath(self,aggStrokeColor,aggDeviceMatrix);
   }
   
   O2ColorRelease(fillColor);
   O2ColorRelease(strokeColor);
   
   O2PathReset(_path);
}

#endif
@end
