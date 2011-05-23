/* Copyright (c) 2011 Plasq LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Onyx2D/O2Context_builtin_gdi.h>
#import "O2Defines_AntiGrain.h"

#ifdef ANTIGRAIN_PRESENT
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
#include <agg_conv_dash.h>
#include <agg_conv_adaptor_vcgen.h>

typedef agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_bgra> blender_type;
typedef agg::pixfmt_custom_blend_rgba<blender_type, agg::rendering_buffer> pixfmt_type;

typedef agg::renderer_base<pixfmt_type> renderer_base;

@interface O2Context_AntiGrain : O2Context_builtin_gdi {
   agg::rendering_buffer *renderingBuffer;
   pixfmt_type    *pixelFormat;
   agg::rasterizer_scanline_aa<> *rasterizer;
   renderer_base    *ren_base;
   agg::path_storage     *path;
}

@end

#else

@interface O2Context_AntiGrain : O2Context_builtin_gdi
@end

#endif

