/* Copyright (c) 2011 Plasq LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


/*
   To use this plug-in you must have the AntiGrain headers and static library installed, this is done using the install_AntiGrain script in
   the InstallCDT download.
 */
 
#import <Onyx2D/O2Context_builtin_gdi.h>
#import "O2Defines_AntiGrain.h"

#ifdef ANTIGRAIN_PRESENT
#include <agg_basics.h>
#include "o2agg_pixfmt_rgba.h"

#include <agg_pixfmt_gray.h>
#include <agg_alpha_mask_u8.h>
#include <agg_scanline_p.h>
#include <agg_scanline_u.h>
#include <agg_alpha_mask_u8.h>
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

#ifdef WINDOWS
#include "agg_font_win32_tt.h"

typedef agg::font_engine_win32_tt_int32 font_engine_type;
typedef agg::font_cache_manager<font_engine_type> font_manager_type;
#define O2AGG_GLYPH_SUPPORT 1
#endif

@class O2Context_AntiGrain;

class context_renderer;
@class KFont;

typedef agg::pixfmt_gray8_pre pixfmt_alphaMaskType;
typedef agg::renderer_base<pixfmt_alphaMaskType> BaseRendererWithAlphaMaskType;
typedef agg::rasterizer_scanline_aa<> RasterizerType; // We use an anti-aliased scanline rasterizer for AGG rendering.
typedef agg::amask_no_clip_gray8 MaskType;

@interface O2Context_AntiGrain : O2Context_builtin_gdi {
	agg::rendering_buffer *renderingBuffer;
	
	// Rendering buffer to use for shadow rendering
	uint8_t *pixelShadowBytes;
	agg::rendering_buffer *renderingBufferShadow;
	
	agg::path_storage     *path;
	RasterizerType *rasterizer;

	context_renderer *renderer;
	
	// Rendering buffer to use for alpha masking (bezier path clipping)
	agg::rendering_buffer*												rBufAlphaMask[2];
	MaskType*															alphaMask[2];
	pixfmt_alphaMaskType*												pixelFormatAlphaMask[2];
	BaseRendererWithAlphaMaskType*										baseRendererAlphaMask[2];
	agg::renderer_scanline_aa_solid<BaseRendererWithAlphaMaskType>*		solidScanlineRendererAlphaMask[2];
	int currentMask;
	
	NSArray *savedClipPhases;
	BOOL maskValid;
	BOOL useMask;
}

- (BOOL)useMask;
- (MaskType*)currentMask;
- (RasterizerType *)rasterizer;
- (context_renderer *)renderer;
- (BOOL)isPremultiplied;
@end
#else
#import <Onyx2D/O2Context_builtin_gdi.h>

@interface O2Context_AntiGrain : O2Context_builtin_gdi
@end

#endif

