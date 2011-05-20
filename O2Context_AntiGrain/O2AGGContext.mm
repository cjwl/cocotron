#import "O2AGGContext.h"
#ifdef ANTIGRAIN_PRESENT

#import <stdio.h>
#include <agg_basics.h>
#include <agg_pixfmt_rgba.h>
#include <agg_path_storage.h>
#include <agg_renderer_base.h>
#include <agg_renderer_mclip.h>
#include <agg_scanline_u.h>
#include <agg_rasterizer_scanline_aa.h>
#include <agg_renderer_scanline.h>
#include <agg_conv_curve.h>
#include <agg_conv_stroke.h>
#include <agg_conv_adaptor_vcgen.h>

typedef agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_bgra> blender_type;
typedef agg::pixfmt_custom_blend_rgba<blender_type, agg::rendering_buffer> pixfmt_type;

typedef agg::renderer_base<pixfmt_type> renderer_base;
    
struct O2AGGContext {
   agg::rendering_buffer *renderingBuffer;
   pixfmt_type    *pixelFormat;
   agg::rasterizer_scanline_aa<> *rasterizer;
   renderer_base    *ren_base;
   agg::path_storage     *path;
   float lineWidth;
   int lineCap;
};

O2AGGContextRef O2AGGContextCreateBGRA32(unsigned char *pixelBytes,size_t width,size_t height,size_t bytesPerRow) {
   O2AGGContextRef self=(O2AGGContextRef)calloc(1,sizeof(struct O2AGGContext));
   
   self->renderingBuffer=new agg::rendering_buffer(pixelBytes,width,height,bytesPerRow);
   self->pixelFormat=new pixfmt_type(*(self->renderingBuffer));
   self->rasterizer=new agg::rasterizer_scanline_aa<>();
   self->ren_base=new renderer_base(*(self->pixelFormat));
   self->path=new agg::path_storage();
   return self;
}

void O2AGGContextBeginPath(O2AGGContextRef self) {
   self->path->remove_all();
}

void O2AGGContextMoveTo(O2AGGContextRef self,double x,double y) {
   self->path->move_to(x,y);
}

void O2AGGContextAddLineTo(O2AGGContextRef self,double x,double y) {
   self->path->line_to(x,y);
}

void O2AGGContextAddCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double cp2x,double cp2y,double endx,double endy) {
   self->path->curve4(cp1x,cp1y,cp2x,cp2y,endx,endy);
}

void O2AGGContextAddQuadCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double endx,double endy) {
   self->path->curve3(cp1x,cp1y,endx,endy);
}

void O2AGGContextCloseSubpath(O2AGGContextRef self) {
   self->path->end_poly();
}

void O2AGGContextClipReset(O2AGGContextRef self) {
}

void O2AGGContextSetDeviceViewport(O2AGGContextRef self,int x,int y,int w,int h) {
   self->ren_base->reset_clipping(1);
   self->ren_base->clip_box(x,y,x+w,y+h);
}

void O2AGGContextClipToPath(O2AGGContextRef self,int evenOdd) {
}

void O2AGGContextSetBlendMode(O2AGGContextRef self,O2BlendMode blendMode){
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

void O2AGGContextSetLineWidth(O2AGGContextRef self,float value){
   self->lineWidth=value;
}

void O2AGGContextSetLineCap(O2AGGContextRef self,O2LineCap lineCap) {
   self->lineCap=lineCap;
}

void O2AGGContextFillPathWithRule(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty,agg::filling_rule_e fillingRule) {
   
   agg::scanline_u8 sl;

   agg::trans_affine mtx(xa,xb,xc,xd,xtx,xty);

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, mtx);

   curve.approximation_scale(mtx.scale());
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(fillingRule);
   
   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),agg::rgba(r,g,b,a));
}

void O2AGGContextFillPath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   O2AGGContextFillPathWithRule(self,r,g,b,a,xa,xb,xc,xd,xtx,xty,agg::fill_non_zero);
}

void O2AGGContextEOFillPath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   O2AGGContextFillPathWithRule(self,r,g,b,a,xa,xb,xc,xd,xtx,xty,agg::fill_even_odd);
}

void O2AGGContextStrokePath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   
   agg::scanline_u8 sl;

   agg::trans_affine mtx(xa,xb,xc,xd,xtx,xty);

   agg::conv_curve<agg::path_storage> curve(*(self->path));
   agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
   agg::conv_transform<agg::conv_stroke<agg::conv_curve<agg::path_storage> >, agg::trans_affine> trans(stroke, mtx);

   curve.approximation_scale(mtx.scale());
   
   switch(self->lineCap){
   }
   
   stroke.width(self->lineWidth);
   
   self->rasterizer->add_path(trans);
   self->rasterizer->filling_rule(agg::fill_non_zero);

   agg::render_scanlines_aa_solid(*(self->rasterizer),sl,*(self->ren_base),agg::rgba(r,g,b,a));
}

#endif

