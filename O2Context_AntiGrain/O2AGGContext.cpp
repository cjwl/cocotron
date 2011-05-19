#import "O2AGGContext.h"
#import "O2Defines_AntiGrain.h"
#import <stdio.h>

#ifdef ANTIGRAIN_PRESENT
#include <agg_basics.h>
#include <agg_pixfmt_rgba.h>
#include <agg_path_storage.h>
#include <agg_renderer_base.h>
#include <agg_scanline_u.h>
#include <agg_rasterizer_scanline_aa.h>
#include <agg_renderer_scanline.h>
#include <agg_conv_curve.h>

typedef agg::renderer_base<agg::pixfmt_bgra32> renderer_base;
typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_aa;
typedef agg::renderer_scanline_bin_solid<renderer_base> renderer_aliased;
    
struct O2AGGContext {
   agg::rendering_buffer *renderingBuffer;
   agg::pixfmt_bgra32    pixelFormat;
   agg::rasterizer_scanline_aa<> *rasterizer;
   agg::path_storage     path;
};

#else
struct O2AGGContext {
   int notPresent;
};
#endif

O2AGGContextRef O2AGGContextCreateBGRA32(unsigned char *pixelBytes,size_t width,size_t height,size_t bytesPerRow) {
   O2AGGContextRef self=(O2AGGContextRef)calloc(1,sizeof(struct O2AGGContext));
   
   self->renderingBuffer=new agg::rendering_buffer(pixelBytes,width,height,bytesPerRow);
   self->pixelFormat.attach(*(self->renderingBuffer));
   self->rasterizer=new agg::rasterizer_scanline_aa<>();
   return self;
}


void O2AGGContextBeginPath(O2AGGContextRef self) {
   self->path.remove_all();
}

void O2AGGContextMoveTo(O2AGGContextRef self,double x,double y) {
   self->path.move_to(x,y);
}

void O2AGGContextAddLineTo(O2AGGContextRef self,double x,double y) {
   self->path.line_to(x,y);
}

void O2AGGContextAddCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double cp2x,double cp2y,double endx,double endy) {
   self->path.curve4(cp1x,cp1y,cp2x,cp2y,endx,endy);
}

void O2AGGContextAddQuadCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double endx,double endy) {
   self->path.curve3(cp1x,cp1y,endx,endy);
}

void O2AGGContextCloseSubpath(O2AGGContextRef self) {
   self->path.close_polygon();
}

void O2AGGContextClipReset(O2AGGContextRef self) {
 //  self->renderer.reset_clipping(1);
}

void O2AGGContextClipToPath(O2AGGContextRef self,int evenOdd) {
}

void O2AGGContextFillPath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty) {
   renderer_base   ren_base(self->pixelFormat);
   renderer_aa     ren_aa(ren_base);
   agg::scanline_u8 sl;

   ren_aa.color(agg::rgba(r,g,b,a));
 printf("%s %d %f %f %f %f %f %f\n",__FILE__,__LINE__,xa,xb,xc,xd,xtx,xty);  
   agg::trans_affine mtx(xa,xb,xc,xd,xtx,xty);
 printf("%s %d\n",__FILE__,__LINE__);  
   agg::conv_transform<agg::path_storage, agg::trans_affine> trans(self->path, mtx);
 printf("%s %d\n",__FILE__,__LINE__);  

   self->rasterizer->add_path(trans);
 printf("%s %d\n",__FILE__,__LINE__);  
   self->rasterizer->filling_rule(agg::fill_non_zero);
 printf("%s %d\n",__FILE__,__LINE__);  
   render_scanlines(*(self->rasterizer),sl,ren_aa);
 printf("%s %d\n",__FILE__,__LINE__);  
   
#if 0
   agg::make_polygon(&pf,&curve,0);
   agg::render_polygon(&renderer,&pf);
   
   agg::render_scanlines_aa_solid(rasterizer,sl,renderer,agg::rgba8(0,0,0));
#endif
}

