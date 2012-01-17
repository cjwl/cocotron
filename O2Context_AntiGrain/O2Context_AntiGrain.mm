#import "O2Context_AntiGrain.h"
#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2MutablePath.h>

#ifdef ANTIGRAIN_PRESENT

#include <agg_color_rgba.h>
#include <agg_span_gradient.h>
#include <agg_span_interpolator_linear.h>
#include <agg_span_allocator.h>
#include <agg_span_converter.h>

#include <agg_image_accessors.h>
#include <agg_span_image_filter_rgba.h>
#include <agg_span_image_filter_rgb.h>

#include <agg_conv_dash.h>
#include "partial_stack_blur.h"
#ifdef WINDOWS
#include <AppKit/KTFont.h>
#endif

typedef enum {
	kImageInterpolationNone,
	kImageInterpolationBilinear,
	kImageInterpolationBicubic,
	kImageInterpolationLanczos,
	kImageInterpolationRepeat,
} ImageInterpolationType;

//#define DEBUG

static const int kKFontCacheSize = 100;

inline float fract(float f)
{
	return f - truncf(f);
}

#ifdef O2AGG_GLYPH_SUPPORT
// They are shared by all the contexts
static font_engine_type      *font_engine = 0;
static font_manager_type     *font_manager = 0;
#endif

// Like NSLog, but works in C++ code - format is a C strings (""), not a Obj-C string (@"")
#ifdef DEBUG
static void O2Log(const char *format,...)
{
    va_list ap;
    va_start(ap, format); //Requires the last fixed parameter (to get the address)
	NSString *f = [NSString stringWithUTF8String:format];
	NSLogv(f, ap);
    va_end(ap);
}
#else
static void O2Log(const char *format,...)
{
}
#endif

// Multiply the alpha spans with a ratio - used as a transformer to render alpha for non-plain color
typedef agg::scanline_u8_am<MaskType> scanline_mask_type;


// render_scanlines_aa_solid with some added translation parameter - we've just added the "+dx, +dy" part
template<class Rasterizer, class Scanline, 
class BaseRenderer, class ColorT>
void render_scanlines_aa_solid_translate(Rasterizer& ras, Scanline& sl, 
							   BaseRenderer& ren, const ColorT& color, int dx, int dy)
{
	if(ras.rewind_scanlines())
	{
		// Explicitly convert "color" to the BaseRenderer color type.
		// For example, it can be called with color type "rgba", while
		// "rgba8" is needed. Otherwise it will be implicitly 
		// converted in the loop many times.
		//----------------------
		typename BaseRenderer::color_type ren_color(color);
		
		sl.reset(ras.min_x(), ras.max_x());
		while(ras.sweep_scanline(sl))
		{
			//render_scanline_aa_solid(sl, ren, ren_color);
			//
			// This code is equivalent to the above call (copy/paste). 
			// It's just a "manual" optimization for old compilers,
			// like Microsoft Visual C++ v6.0
			//-------------------------------
			int y = sl.y();
			unsigned num_spans = sl.num_spans();
			typename Scanline::const_iterator span = sl.begin();
			
			for(;;)
			{
				int x = span->x;
				if(span->len > 0)
				{
					ren.blend_solid_hspan(x+dx, y+dy, (unsigned)span->len, 
										  ren_color, 
										  span->covers);
				}
				else
				{
					ren.blend_hline(x+dx, y+dy, (unsigned)(x - span->len - 1), 
									ren_color, 
									*(span->covers));
				}
				if(--num_spans == 0) break;
				++span;
			}
		}
	}
}

// render_scanlines_aa with some added translation parameter - we've just added the "+dx, +dy" part
template<class Scanline, class BaseRenderer, 
class SpanAllocator, class SpanGenerator> 
void render_scanline_aa_translate(const Scanline& sl, BaseRenderer& ren, 
						SpanAllocator& alloc, SpanGenerator& span_gen, int dx, int dy)
{
	int y = sl.y();
	
	unsigned num_spans = sl.num_spans();
	typename Scanline::const_iterator span = sl.begin();
	for(;;)
	{
		int x = span->x;
		int len = span->len;
		const typename Scanline::cover_type* covers = span->covers;
		
		if(len < 0) len = -len;
		typename BaseRenderer::color_type* colors = alloc.allocate(len);
		span_gen.generate(colors, x, y, len);
		ren.blend_color_hspan(x + dx, y + dy, len, colors, 
							  (span->len < 0) ? 0 : covers, *covers);
		
		if(--num_spans == 0) break;
		++span;
	}
}

// render_scanlines_aa with some added translation parameter
template<class Rasterizer, class Scanline, class BaseRenderer, 
class SpanAllocator, class SpanGenerator>
void render_scanlines_aa_translate(Rasterizer& ras, Scanline& sl, BaseRenderer& ren, 
						 SpanAllocator& alloc, SpanGenerator& span_gen, int dx, int dy)
{
	if(ras.rewind_scanlines())
	{
		sl.reset(ras.min_x(), ras.max_x());
		span_gen.prepare();
		while(ras.sweep_scanline(sl))
		{
			render_scanline_aa_translate(sl, ren, alloc, span_gen, dx, dy);
		}
	}
}

// Apply some alpha value to its input spans
template<class color_type> struct span_alpha_converter
{
	span_alpha_converter(float alpha, bool premultiply) : m_alpha(alpha), m_premultiply(premultiply) {};
	
	void prepare() {}
	
	inline void generate(color_type* span, int x, int y, unsigned len)
	{
		if(m_alpha < 1.) {
			if (m_premultiply) {
				do {
					span->demultiply();
					span->opacity(span->opacity()*m_alpha);
					span->premultiply();
					++span;
				} while(--len);
			} else {
				do {
					span->opacity(span->opacity()*m_alpha);
					++span;
				} while(--len);
			}
		} 
	}		
private:
	bool m_premultiply;
	double m_alpha;
};

// Replace spans with a fixed color, keeping the original opacity - used as a transformer to render shadow for non-plain color
class span_color_converter
{
public:
	span_color_converter(agg::rgba8 &color, bool premultiply) : m_color(color), m_premultiply(premultiply) {};
	
	void prepare() {}
	
	inline void generate(agg::rgba8* span, int x, int y, unsigned len)
	{
		if (m_premultiply) {
			do {
				// Replace the span color, with m_color * span opacity
				if (span->opacity() > 0) {
					agg::rgba8 color = m_color;
					color.opacity(color.opacity()*span->opacity());
					color.premultiply();
					*span = color;
				}
				++span;
			} while(--len);
		} else {
			do {
				// Replace the span color, with m_color * span opacity
				if (span->opacity() > 0) {
					agg::rgba8 color = m_color;
					color.opacity(color.opacity()*span->opacity());
					*span = color;
				}
				++span;
			} while(--len);
		}
	}		
private:
	bool m_premultiply;
	agg::rgba8 m_color;
};

class context_renderer
{
	class context_renderer_helper_base
	{
	protected:
		bool premultiply;
	public:
		void setPremultiply(bool pre) { premultiply = pre; };
		virtual bool isRGBA() { return false; }
		virtual bool isBGRA() { return false; }
		virtual bool isARGB() { return false; }
		virtual bool isABGR() { return false; }
		virtual void setBlendMode(int blendMode) = 0;
		virtual void setAlpha(float alpha) = 0;
		virtual void setShadowColor(agg::rgba color) = 0;
		virtual void setShadowBlurRadius(float radius) = 0;
		virtual void setShadowOffset(O2Size offset) = 0;
		virtual void clipBox(int a, int b, int c, int d) = 0;
	};
	
	template<class blender_type> class context_renderer_helper : public context_renderer_helper_base
	{
		typedef o2agg::pixfmt_custom_blend_rgba<blender_type, agg::rendering_buffer> pixfmt_type;
		
		typedef o2agg::pixfmt_rgba32 pixfmt_shadow_type;
		
		typedef agg::renderer_base<pixfmt_type> renderer_base;	
		typedef agg::renderer_base<pixfmt_shadow_type> renderer_shadow;	
		
		renderer_base    *ren_base;
		pixfmt_type    *pixelFormat;
		
		renderer_shadow    *ren_shadow;
		pixfmt_shadow_type    *pixelFormatShadow;
		
		float			alpha;
		
		agg::rgba shadowColor;
		O2Size shadowOffset;
		float shadowBlurRadius;
	public:
		context_renderer *renderer;
		context_renderer_helper(agg::rendering_buffer &renderingBuffer, agg::rendering_buffer &renderingBufferShadow)
		{
			pixelFormat=new pixfmt_type(renderingBuffer);
			ren_base=new renderer_base(*pixelFormat);
			
			pixelFormatShadow=new pixfmt_shadow_type(renderingBufferShadow);
			ren_shadow=new renderer_shadow(*pixelFormatShadow);
			
			shadowColor = agg::rgba(0, 0, 0, 0);
			
			alpha = 1.;
		}
		
		virtual ~context_renderer_helper()
		{
			delete pixelFormat;
			delete ren_base;
			
			delete pixelFormatShadow;
			delete ren_shadow;
		}
		
		void setBlendMode(int blendMode)
		{
			pixelFormat->comp_op(blendMode);
		}
		
		void setAlpha(float a)
		{
			alpha = a;
		}
		
		void setShadowColor(agg::rgba color)
		{
			shadowColor = color;
		}
		
		void setShadowBlurRadius(float radius)
		{
			shadowBlurRadius = radius;
		}
		
		void setShadowOffset(O2Size offset)
		{
			shadowOffset = offset;
		}
		
		void clipBox(int a, int b, int c, int d)
		{
			ren_base->reset_clipping(1);
			ren_base->clip_box(a, b, c, d);
			ren_shadow->reset_clipping(1);
			ren_shadow->clip_box(a, b, c, d);
		}
		
		// Blur the (x1,y1,x2,y2) part of the shadow buffer, and copy it to the main buffer 
		template<class Ras, class S> void blur(S &sl, float x1, float x2, float y1, float y2)
		{
			float xmin = ren_base->xmin();
			float ymin = ren_base->ymin();
			float xmax = ren_base->xmax();
			float ymax = ren_base->ymax();
			if (xmax <= xmin || ymax <= ymin) {
				O2Log("Nothing to do - skip shadow blur");
				return;
			}
			
			// Clip the rect to render - no need to try to blur any clipped area
			xmin = max(xmin, x1);
			xmax = min(xmax, x2);
			ymin = max(ymin, y1);
			ymax = min(ymax, y2);

			xmin = floorf(xmin);
			ymin = floorf(ymin);
			xmax = ceilf(xmax);
			ymax = ceilf(ymax);

			// Blur the shadows
			int radius = agg::iround(shadowBlurRadius);
			if (radius > 0) {
				// Add the blur radius to the area to blur
				xmin -= radius;
				xmax += radius;
				ymin -= radius;
				ymax += radius;
				
				xmin = max(xmin,0);
				ymin = max(ymin,0);
				O2Log("Shadow: blur shadow - area : ((%.0f,%.0f),(%.0f,%.0f))", xmin, ymin, xmax - xmin, ymax - ymin);
				// Stack blur - not really a gaussian one but much faster and good enough
				// Blur only the current clipped area - no need to process pixels we won't see
				if (xmax > xmin && ymax > ymin) {
					partial_stack_blur_rgba32(*pixelFormatShadow, radius, radius,  xmin, xmax, ymin, ymax);
				} else {
					O2Log("Skip blurring");
				}
				O2Log("Shadow: done blur");
			}
			
			// Add the offset to the area to copy - the translated drawing only take the rounded translation into account
			// So add the fractionary part
 			Ras r;
			xmin += fract(shadowOffset.width);
			xmax += fract(shadowOffset.width);
			ymin -= fract(shadowOffset.height);
			ymax -= fract(shadowOffset.height);
			xmin = max(xmin,0);
			ymin = max(ymin,0);
			
			xmin = floorf(xmin);
			ymin = floorf(ymin);
			xmax = ceilf(xmax);
			ymax = ceilf(ymax);
			
			if (xmax <= xmin || ymax <= ymin) {
				O2Log("Nothing to do - skip shadow drawing");
				return;
			}

			r.clip_box(ren_base->xmin(), ren_base->ymin(), ren_base->xmax(), ren_base->ymax());

				// Rasterize the shadow to our main renderer
			agg::span_allocator<typename pixfmt_shadow_type::color_type> sa;
			typedef agg::image_accessor_clone<pixfmt_shadow_type> img_accessor_type;
			
			typedef agg::span_interpolator_linear<agg::trans_affine> interpolator_type;
			
			agg::path_storage aggPath;

			O2Log("Shadow: copying to area : ((%.0f,%.0f),(%.0f,%.0f))", xmin, ymin, xmax - xmin, ymax - ymin);
			// We'll use a path that cover the current used rect, and render that path using the shadow image
			aggPath.move_to(xmin, ymin);
			aggPath.line_to(xmax, ymin);
			aggPath.line_to(xmax, ymax);
			aggPath.line_to(xmin, ymax);
			aggPath.end_poly();
			
			agg::conv_curve<agg::path_storage> curve(aggPath);
			r.add_path(curve);					
			
			img_accessor_type ia(*pixelFormatShadow);
			agg::trans_affine transform;
			transform.translate(-fract(shadowOffset.width), fract(shadowOffset.height)); // Translate using the fract part of the shadow offset
			interpolator_type interpolator(transform);
			typedef agg::span_image_filter_rgba_nn<img_accessor_type, interpolator_type> span_gen_type;
			span_gen_type sg(ia, interpolator);
			
			unsigned oldBlendMode = pixelFormat->comp_op();
			pixelFormat->comp_op(o2agg::comp_op_src_over); // Always use src_over when copying the shadow
			agg::render_scanlines_aa(r, sl, *ren_base, sa, sg);
			pixelFormat->comp_op(oldBlendMode);
		}
		
		template<class Ras, class S, class T> void render_scanlines(Ras &rasterizer, S &sl, T &type)
		{
			agg::render_scanlines(rasterizer, sl, type);
		}
		
		// Used to render images & shadings
		template<class Ras, class S, class SA, class T> void render_scanlines_aa(Ras &rasterizer, S &sl, SA &span_allocator, T &type)
		{
			O2Log("%p:Drawing Image", this);
			if (shadowColor.a > 0.) {
				O2Log("%p:Drawing shadow Image", this);
				ren_shadow->clear(agg::rgba(0, 0, 0, 0));
				// Draw using our shadow rendererer using a transformer to transform original colors by the shadow color * original color alpha (and global alpha)
				agg::rgba8 color = agg::rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a * alpha);
				span_color_converter color_converter(color, premultiply);
				agg::span_converter<T, span_color_converter > converter(type, color_converter);

				// Render to the shadow location (rounded - we are working with pixels here) so we're sure we can properly blur the shadow
				// We'll take into account the fractional part when copying the shadow to the final buffer
				render_scanlines_aa_translate(rasterizer, sl, *ren_shadow, span_allocator, converter, truncf(shadowOffset.width), -truncf(shadowOffset.height));

				// Get the used part of the rasterizer - we don't need to blur a bigger area than that
				float x1 = rasterizer.min_x();
				float x2 = rasterizer.max_x();
				float y1 = rasterizer.min_y();
				float y2 = rasterizer.max_y();
				// Add the translation done during the rendering
				x1 += truncf(shadowOffset.width);
				x2 += truncf(shadowOffset.width);
				y1 -= truncf(shadowOffset.height);
				y2 -= truncf(shadowOffset.height);
				
				// Blur the shadow buffer
				blur<Ras>(sl, x1, x2, y1, y2);
				O2Log("%p:Done Drawing shadow Image", this);
			}
			
			// And finally do the "normal" drawing
			if (alpha >= 1) {
				// No need for an alpha converter
				agg::render_scanlines_aa(rasterizer, sl, *ren_base, span_allocator, type);
			} else {
				span_alpha_converter<agg::rgba8> alpha_converter(alpha, premultiply);
				agg::span_converter<T, span_alpha_converter<agg::rgba8> > converter(type, alpha_converter);
				agg::render_scanlines_aa(rasterizer, sl, *ren_base, span_allocator, converter);
			}
			O2Log("%p:Done Drawing Image", this);
		}
		
		// Used to render path
		template<class Ras, class S, class T> void render_scanlines_aa_solid(Ras &rasterizer, S &sl, T &type)	
		{
			if (shadowColor.a > 0.) {
				ren_shadow->clear(agg::rgba(0, 0, 0, 0));

				// Draw using our shadow rendererer using our shadow color (and global alpha)
				T color = agg::rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a * type.opacity() * alpha);
				color.premultiply();
				
				// Render to the shadow location (rounded - we are working with pixels here) so we're sure we can properly blur the shadow
				// We'll take into account the fractional part when copying the shadow to the final buffer
				render_scanlines_aa_solid_translate(rasterizer, sl, *ren_shadow, color, truncf(shadowOffset.width), -truncf(shadowOffset.height));

				// Get the used part of the rasterizer - we don't need to blur a bigger area than that
				float x1 = rasterizer.min_x();
				float x2 = rasterizer.max_x();
				float y1 = rasterizer.min_y();
				float y2 = rasterizer.max_y();
				// Add the translation done during the rendering
				x1 += truncf(shadowOffset.width);
				x2 += truncf(shadowOffset.width);
				y1 -= truncf(shadowOffset.height);
				y2 -= truncf(shadowOffset.height);
				
				// Blur the shadow buffer
				blur<Ras>(sl, x1, x2, y1, y2);
			}
			// And finally do the "normal" drawing
			T color = type;
			color.opacity(color.opacity() * alpha );
			if (premultiply)
				color.premultiply();
			if (color.opacity() >= 1. && pixelFormat->comp_op() == o2agg::comp_op_src_over) {
				pixelFormat->comp_op(o2agg::comp_op_src);
			}
			agg::render_scanlines_aa_solid(rasterizer, sl, *ren_base, color);
		}
		
		bool isRGBA() { return NO; };
		bool isBGRA() { return NO; };
		bool isARGB() { return NO; };
		bool isABGR() { return NO; };
	};
	
	
	context_renderer_helper_base* helper;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_rgba> > rgba_helper;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_bgra> > bgra_helper;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_argb> > argb_helper;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_abgr> > abgr_helper;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba_pre<agg::rgba8, agg::order_rgba> > rgba_helper_pre;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba_pre<agg::rgba8, agg::order_bgra> > bgra_helper_pre;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba_pre<agg::rgba8, agg::order_argb> > argb_helper_pre;
	typedef class context_renderer_helper<o2agg::comp_op_adaptor_rgba_pre<agg::rgba8, agg::order_abgr> > abgr_helper_pre;
	
public:
	bool premultiplied;
	O2Context_AntiGrain *context;
	virtual ~context_renderer()
	{
		delete helper;
	}
	template<class Order> void init(agg::rendering_buffer &renderingBuffer, agg::rendering_buffer &renderingShadowBuffer)
	{
		typedef o2agg::comp_op_adaptor_rgba<agg::rgba8, Order> blender_type;
		premultiplied = false;
		helper = new context_renderer_helper<blender_type>(renderingBuffer, renderingShadowBuffer);
		helper->setPremultiply(premultiplied);
	}
	template<class Order> void init_pre(agg::rendering_buffer &renderingBuffer, agg::rendering_buffer &renderingShadowBuffer)
	{
		typedef o2agg::comp_op_adaptor_rgba_pre<agg::rgba8, Order> blender_type;
		premultiplied = true;
		helper = new context_renderer_helper<blender_type>(renderingBuffer, renderingShadowBuffer);
		helper->setPremultiply(premultiplied);
	}
	
	// Not sure how to better write that since we can't have virtual template methods and we don't know some type
	// at compile time (like pixel format)
	// But there must be some better way...
	template<class Ras, class S, class T> void render_scanlines(Ras &rasterizer, S &sl, T &type)
	{
		if (premultiplied) {
			if (helper->isRGBA()) {
				((rgba_helper_pre *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isABGR()) {
				((abgr_helper_pre *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines(rasterizer, sl, type);
			}
		} else {
			if (helper->isRGBA()) {
				((rgba_helper *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isABGR()) {
				((abgr_helper *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines(rasterizer, sl, type);
			}
		}
	}
	template<class Ras, class S, class SA, class T> void render_scanlines_aa(Ras &rasterizer, S &sl, SA &span_allocator, T &type)
	{
		if (premultiplied) {
			if (helper->isRGBA()) {
				((rgba_helper_pre *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isABGR()) {
				((abgr_helper_pre *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			}
		} else {
			if (helper->isRGBA()) {
				((rgba_helper *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isABGR()) {
				((abgr_helper *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines_aa(rasterizer, sl, span_allocator, type);
			}
		}
	}
	template<class Ras, class S, class T> void render_scanlines_aa_solid(Ras &rasterizer, S &sl, T &type)	
	{
		if (premultiplied) {
			if (helper->isRGBA()) {
				((rgba_helper_pre *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isABGR()) {
				((abgr_helper_pre *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper_pre *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			}
		} else {
			if (helper->isRGBA()) {
				((rgba_helper *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isABGR()) {
				((abgr_helper *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			} else if (helper->isBGRA()) {
				((bgra_helper *)helper)->render_scanlines_aa_solid(rasterizer, sl, type);
			}
		}
	}
	
	void setBlendMode(int blendMode)
	{
		helper->setBlendMode(blendMode);
	}
	
	void setShadowColor(agg::rgba color)
	{
		helper->setShadowColor(color);
	}
	
	void setShadowOffset(O2Size shadowOffset)
	{
		helper->setShadowOffset(shadowOffset);
	}
	
	void setShadowBlurRadius(float radius)
	{
		helper->setShadowBlurRadius(radius);
	}
	
	void setAlpha(float alpha)
	{
		helper->setAlpha(alpha);
	}
	
	void clipBox(int a, int b, int c, int d)
	{
		helper->clipBox(a, b, c, d);
	}
};

// Make the right type test to return true when needed
template<> bool context_renderer::rgba_helper::isRGBA() { return true; };
template<> bool context_renderer::bgra_helper::isBGRA() { return true; };
template<> bool context_renderer::argb_helper::isARGB() { return true; };
template<> bool context_renderer::abgr_helper::isABGR() { return true; };

template<> bool context_renderer::rgba_helper_pre::isRGBA() { return true; };
template<> bool context_renderer::bgra_helper_pre::isBGRA() { return true; };
template<> bool context_renderer::argb_helper_pre::isARGB() { return true; };
template<> bool context_renderer::abgr_helper_pre::isABGR() { return true; };


class gradient_evaluator
{
public:
	gradient_evaluator(O2FunctionRef function, bool premultiply = true, unsigned size = 4096) :
	m_size(size) { 
		// Precalculate our colors
		m_colors_lut = new agg::rgba[size];
		float invSize = 1./size;
		for (int i = 0; i < size; ++i) {
			O2Float result[4] = { 1 };
			O2FunctionEvaluate(function, i*invSize, result);
			agg::rgba color;
			color.r = result[0];
			color.g = result[1];
			color.b = result[2];
			color.a = result[3];
			if (premultiply)
				color.premultiply();
			m_colors_lut[i] = color;
		}
	}
	~gradient_evaluator() { delete[] m_colors_lut; };
	inline int size() const { return m_size; }
	inline agg::rgba operator [] (unsigned v) const 
	{
		return m_colors_lut[v];
	}
private:
	agg::rgba *m_colors_lut;
	int m_size;
};


template <class SpanAllocator, class SpanGen> void render_scanlines_aa(O2Context_AntiGrain *self, SpanAllocator &sa, SpanGen &sg)
{
	if ([self useMask]) {
		scanline_mask_type sl(*[self currentMask]);
		[self renderer]->render_scanlines_aa(*[self rasterizer], sl, sa, sg);
	} else {
		agg::scanline_u8 sl;
		[self renderer]->render_scanlines_aa(*[self rasterizer], sl, sa, sg);
	}	
}

template <class Type> void render_scanlines_aa_solid(O2Context_AntiGrain *self, Type &type)
{
	if ([self useMask]) {
		scanline_mask_type sl(*[self currentMask]);
		[self renderer]->render_scanlines_aa_solid(*[self rasterizer],sl,type);
	} else {
		agg::scanline_u8 sl;
		[self renderer]->render_scanlines_aa_solid(*[self rasterizer],sl,type);
	}
}

template<class gradient_func_type> void O2AGGContextDrawShading(O2Context_AntiGrain *self, O2Shading* shading, float x, float y, float width, float height)
{
	typedef o2agg::pixfmt_bgra32_pre pixfmt_type; // That should be the same pixel type as the context ?
	typedef pixfmt_type::color_type color_type; 
	typedef gradient_evaluator color_func_type; 
	typedef agg::span_interpolator_linear<> interpolator_type; 
	typedef agg::span_allocator<color_type> span_allocator_type; 
	typedef agg::span_gradient<color_type, interpolator_type, gradient_func_type, color_func_type> span_gradient_type; 
	
	O2GState    *gState=O2ContextCurrentGState(self);
	O2ClipState *clipState=O2GStateClipState(gState);
	O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
	agg::trans_affine deviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
	
	O2Point deviceStart=O2PointApplyAffineTransform([shading startPoint],deviceTransform);
	O2Point deviceEnd=O2PointApplyAffineTransform([shading endPoint],deviceTransform);
	
	double x1=deviceStart.x; 
	double y1=deviceStart.y; 
	double x2=deviceEnd.x; 
	double y2=deviceEnd.y;
	
	float startValue = 0;
	float endValue = 0;

	if ([shading isAxial]) {
		startValue = 0;
		endValue = agg::calc_distance(x1,y1,x2,y2);
	} else {
		double scale = sqrt((deviceTransform.a * deviceTransform.a) + (deviceTransform.c * deviceTransform.c));
		startValue = scale*[shading startRadius];
		endValue = scale*[shading endRadius];
	}
	int gradientSize = ceilf(endValue - startValue);
	if (gradientSize < 1) {
		gradientSize = 1;
	}

	color_func_type color_func([shading function], [self isPremultiplied], gradientSize); 
	
	agg::trans_affine gradient_mtx; 
	gradient_mtx.reset(); 
	double angle = atan2(y2-y1, x2-x1); 
	gradient_mtx *= agg::trans_affine_rotation(angle); 
	gradient_mtx *= agg::trans_affine_translation(x1, y1); 
	gradient_mtx.invert(); 
	
	interpolator_type span_interpolator(gradient_mtx); 
	span_allocator_type span_allocator;
	gradient_func_type gradient_func; 
	span_gradient_type span_gradient(span_interpolator, gradient_func, color_func, startValue, endValue); 
	
	// The rasterizing/scanline stuff
	//----------------
	agg::path_storage aggPath;
	
	// We'll use a path that cover the current clipped rect
	aggPath.move_to(x, y);
	aggPath.line_to(x+width,y);
	aggPath.line_to(x+width,y+height);
	aggPath.line_to(x,y+height);
	aggPath.end_poly();
	
	agg::conv_curve<agg::path_storage> curve(aggPath);
	curve.approximation_scale(deviceMatrix.scale());
	
	[self rasterizer]->add_path(curve);
	
	render_scanlines_aa(self, span_allocator, span_gradient);
}

template <class pixfmt> void O2AGGContextDrawImage(O2Context_AntiGrain *self, agg::rendering_buffer &imageBuffer, const agg::trans_affine &transform, ImageInterpolationType interpolationType)
{
	agg::span_allocator<typename pixfmt::color_type> sa;
	pixfmt          img_pixf(imageBuffer);
	typedef agg::image_accessor_clone<pixfmt> img_accessor_type;
	img_accessor_type ia(img_pixf);
	
	typedef agg::span_interpolator_linear<agg::trans_affine> interpolator_type;
	interpolator_type interpolator(transform);

	// Use a filter according to the wanted interpolation quality
	switch (interpolationType) {
		case kImageInterpolationNone: {
			typedef agg::span_image_filter_rgba_nn<img_accessor_type, interpolator_type> span_gen_type;
			span_gen_type sg(ia, interpolator);
			
			render_scanlines_aa(self, sa, sg);
		}
			break;
		default:
		case kImageInterpolationBilinear: {
			agg::image_filter_bilinear filter_kernel;			
			typedef agg::span_image_filter_rgba_bilinear<img_accessor_type, interpolator_type> span_gen_type;
			span_gen_type sg(ia, interpolator);
			
			render_scanlines_aa(self, sa, sg);
		}
			break;
		case kImageInterpolationBicubic: {
			agg::image_filter_bicubic filter_kernel;
			agg::image_filter_lut filter(filter_kernel, true);
			
			typedef agg::span_image_resample_rgba_affine<img_accessor_type> span_gen_type;
			span_gen_type sg(ia, interpolator, filter);
			
			render_scanlines_aa(self, sa, sg);
		}
			break;
		case kImageInterpolationLanczos: {
			agg::image_filter_lanczos filter_kernel(2.f);
			agg::image_filter_lut filter(filter_kernel, true);
			
			typedef agg::span_image_resample_rgba_affine<img_accessor_type> span_gen_type;
			span_gen_type sg(ia, interpolator, filter);
			
			render_scanlines_aa(self, sa, sg);
		}
			break;
		case kImageInterpolationRepeat: {
			typedef agg::image_accessor_wrap<pixfmt, agg::wrap_mode_repeat, agg::wrap_mode_repeat> img_accessor_type;
			img_accessor_type ia(img_pixf);
			
			agg::image_filter_bilinear filter_kernel;			
			typedef agg::span_image_filter_rgba_bilinear<img_accessor_type, interpolator_type> span_gen_type;
			span_gen_type sg(ia, interpolator);
			
			render_scanlines_aa(self, sa, sg);
		}
			break;
	}
}

template <class StrokeType> void O2AGGContextSetStroke(O2Context_AntiGrain *self, StrokeType &stroke, const agg::trans_affine &deviceMatrix) 
{
	O2GState *gState=O2ContextCurrentGState(self);
	
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
}

template <class StrokeType> void O2AGGContextStrokePath(O2Context_AntiGrain *self, StrokeType &stroke, agg::rgba color, const agg::trans_affine &deviceMatrix) 
{
	agg::conv_transform<StrokeType, agg::trans_affine> trans(stroke, deviceMatrix);
	[self rasterizer]->add_path(trans);
	[self rasterizer]->filling_rule(agg::fill_non_zero);
	
	render_scanlines_aa_solid(self, color);	
}

template <class StrokeType> void O2AGGStrokeToO2Path(O2Context_AntiGrain *self, StrokeType &stroke) 
{
	double x,y;
	int type;
	O2ContextBeginPath(self);
	while ((type = stroke.vertex(&x,&y)) != agg::path_cmd_stop) {
		switch (type) {
			case agg::path_cmd_move_to: {
				O2ContextMoveToPoint(self, x, y);
			}
				break;
			case agg::path_cmd_line_to: {
				O2ContextAddLineToPoint(self, x, y);
			}
				
				break;
			case agg::path_cmd_curve3: {
				// x, y are ctrl_x, ctrl_y
				double to_x, to_y;
				stroke.vertex(&to_x,&to_y);
				O2ContextAddQuadCurveToPoint(self, x, y, to_x, to_y);				
			}
				
				break;
			case agg::path_cmd_curve4: {
				// x, y are ctrl1_x, ctrl1_y
				double ctrl2_x, ctrl2_y;
				stroke.vertex(&ctrl2_x,&ctrl2_y);
				double to_x, to_y;
				stroke.vertex(&to_x,&to_y);
				O2ContextAddCurveToPoint(self, x, y, ctrl2_x, ctrl2_y, to_x, to_y);
				
			}
				break;
			case agg::path_cmd_end_poly: {
				O2ContextClosePath(self);
			}
				
			default:
				break;
		}
	}
}

#endif

@interface O2AGGGState : O2GState
{
	float alpha;
}

@end

@implementation O2Context_AntiGrain

#ifdef ANTIGRAIN_PRESENT
// If AntiGrain is not present it will just be a non-overriding subclass of the builtin context, so no problems

static void O2AGGContextFillPathWithRule(O2Context_AntiGrain *self,agg::rgba color, const agg::trans_affine &deviceMatrix,agg::filling_rule_e fillingRule) {
	agg::conv_curve<agg::path_storage> curve(*(self->path));
	agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, deviceMatrix);
	
	curve.approximation_scale(deviceMatrix.scale());
	
	[self rasterizer]->add_path(trans);
	[self rasterizer]->filling_rule(fillingRule);
	
	render_scanlines_aa_solid(self,color);
}

static void O2AGGContextStrokePath(O2Context_AntiGrain *self,agg::rgba color, const agg::trans_affine &deviceMatrix) {	
	agg::conv_curve<agg::path_storage> curve(*(self->path));
	curve.approximation_scale(deviceMatrix.scale());
	
	O2GState *gState=O2ContextCurrentGState(self);
	if (gState->_dashLengthsCount > 1) {
		agg::conv_dash<agg::conv_curve<agg::path_storage> > dash(curve);
		agg::conv_stroke<agg::conv_dash<agg::conv_curve<agg::path_storage> > > stroke(dash);
		dash.dash_start(gState->_dashPhase);
		for (int i = 0; i < gState->_dashLengthsCount; i += 2) {
			if (i == gState->_dashLengthsCount - 1) {
				// Last dash without an length for the next space
				dash.add_dash(gState->_dashLengths[i], 0);
			} else {
				dash.add_dash(gState->_dashLengths[i], gState->_dashLengths[i+1]);
			}
		}	
		O2AGGContextSetStroke<typeof(stroke)>(self,stroke,deviceMatrix);
		O2AGGContextStrokePath<typeof(stroke)>(self,stroke,color,deviceMatrix);
	} else {
		// Just stroke
		agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
		O2AGGContextSetStroke<typeof(stroke)>(self,stroke,deviceMatrix);
		O2AGGContextStrokePath<typeof(stroke)>(self,stroke,color,deviceMatrix);
	}
}

static void O2AGGReplaceStrokedPath(O2Context_AntiGrain *self, const agg::trans_affine &deviceMatrix) {	
	agg::conv_curve<agg::path_storage> curve(*(self->path));
	curve.approximation_scale(deviceMatrix.scale());
	
	O2GState *gState=O2ContextCurrentGState(self);
	if (gState->_dashLengthsCount > 1) {
		agg::conv_dash<agg::conv_curve<agg::path_storage> > dash(curve);
		agg::conv_stroke<agg::conv_dash<agg::conv_curve<agg::path_storage> > > stroke(dash);
		dash.dash_start(gState->_dashPhase);
		for (int i = 0; i < gState->_dashLengthsCount; i += 2) {
			if (i == gState->_dashLengthsCount - 1) {
				// Last dash without an length for the next space
				dash.add_dash(gState->_dashLengths[i], 0);
			} else {
				dash.add_dash(gState->_dashLengths[i], gState->_dashLengths[i+1]);
			}
		}	
		O2AGGContextSetStroke<typeof(stroke)>(self,stroke,deviceMatrix);
		O2AGGStrokeToO2Path<typeof(stroke)>(self,stroke);
		
	} else {
		// Just stroke
		agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
		O2AGGContextSetStroke<typeof(stroke)>(self,stroke,deviceMatrix);
		O2AGGStrokeToO2Path<typeof(stroke)>(self,stroke);
	}
}


/* Transfer path from Onyx2D to AGG. Not a very expensive operation, tessellation, stroking and rasterization are the expensive pieces
 */
static void buildAGGPathFromO2PathAndTransform(agg::path_storage *aggPath,O2PathRef path, const O2AffineTransform &xform){
	const unsigned char *elements=O2PathElements(path);
	const O2Point       *points=O2PathPoints(path);
	unsigned             i,numberOfElements=O2PathNumberOfElements(path),pointIndex;
	
	pointIndex=0;
	
	aggPath->remove_all();
	
	for(i=0;i<numberOfElements;i++){
		
		switch(elements[i]){
				
			case kO2PathElementMoveToPoint:{
				O2Point point=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->move_to(point.x,point.y);
			}
				break;
				
			case kO2PathElementAddLineToPoint:{
				O2Point point=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->line_to(point.x,point.y);
			}
				break;
				
			case kO2PathElementAddCurveToPoint:{
				O2Point cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
				O2Point cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
				O2Point end=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->curve4(cp1.x,cp1.y,cp2.x,cp2.y,end.x,end.y);
			}
				break;
				
			case kO2PathElementAddQuadCurveToPoint:{
				O2Point cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
				O2Point cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->curve3(cp1.x,cp1.y,cp2.x,cp2.y);
			}
				break;
				
			case kO2PathElementCloseSubpath:
				aggPath->end_poly();
				break;
		}    
	}
	
}

static void transferPath(O2Context_AntiGrain *self,O2PathRef path, const O2AffineTransform &xform) {
	buildAGGPathFromO2PathAndTransform(self->path, path, xform);
}

#ifdef O2AGG_GLYPH_SUPPORT

- (KTFont*)_cachedKTFontWithFont:(O2Font *)font name:(NSString *)name size:(float)size
{
	static NSMutableDictionary *kfontCache = nil;
	static NSMutableArray *kfontLRU = nil;
	if (kfontCache == nil) {
		kfontCache = [[NSMutableDictionary alloc] initWithCapacity:kKFontCacheSize];
	}
	if (kfontLRU == nil) {
		kfontLRU = [[NSMutableArray alloc] initWithCapacity:kKFontCacheSize];
	}
	NSString *key=[NSString stringWithFormat:@"%@-%f", name, size];
	KTFont *kfont = [kfontCache objectForKey:key];
	if (kfont) {
		[kfontLRU removeObject:key];
	}
	// Move the font to the top of our LRU list
	[kfontLRU insertObject:key atIndex:0];
	if (kfont == nil) {
		kfont = [[[KTFont alloc] initWithFont:font size:size] autorelease];
		[kfontCache setObject:kfont forKey:key];
		// Remove the LRU if we reach the max size
		if ([kfontLRU count] > kKFontCacheSize) {
			id lastKey = [kfontLRU lastObject];
			[kfontCache removeObjectForKey:lastKey];
			[kfontLRU removeLastObject];
		}
	}
	return kfont;
}

unsigned O2AGGContextShowGlyphs(O2Context_AntiGrain *self, const O2Glyph *glyphs, const O2Size *advances, unsigned count)
{
	unsigned num_glyphs = 0;
	
	// All context use the same font manager - protect acceses
	@synchronized([self class]) {
		if (font_manager == 0) {
			font_engine = new font_engine_type(::GetDC(NULL));
			font_manager = new font_manager_type(*font_engine);
		}		
		
		// Pipeline to process the vectors glyph paths (curves)
		typedef agg::conv_curve<font_manager_type::path_adaptor_type> conv_curve_type;
		conv_curve_type curves(font_manager->path_adaptor());
		
		O2GState    *gState=O2ContextCurrentGState(self);
		
		O2Font           *font=O2GStateFont(gState);
		NSString *fontName = [(NSString *)O2FontCopyFullName(font) autorelease];
		
		float pointSize = O2GStatePointSize(gState);
		O2AffineTransform Trm=self->_textMatrix;

		O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
		agg::trans_affine deviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
		// Round the drawing start point - that helps at killing blury text
		Trm.tx = roundf(Trm.tx);
		Trm.ty = roundf(Trm.ty);
		agg::trans_affine trmMatrix(Trm.a,Trm.b,Trm.c,Trm.d,Trm.tx,Trm.ty);
		
		agg::trans_affine transformMatrix = deviceMatrix;
		transformMatrix.premultiply(trmMatrix);
		
		O2ColorRef   fillColor=O2ColorConvertToDeviceRGB(gState->_fillColor);
		const float *fillComps=O2ColorGetComponents(fillColor);
		agg::rgba aggFillColor(fillComps[0],fillComps[1],fillComps[2],fillComps[3]);
		O2ColorRelease(fillColor);
		
		[self rasterizer]->filling_rule(agg::fill_non_zero);
		
		font_engine->hinting(false); // For some reason, it looks better without hinting...
		font_engine->height((int)pointSize);
		font_engine->width(0.); // Automatic width
		font_engine->flip_y(false);

		[self rasterizer]->reset();

		if(font_engine->create_font([fontName UTF8String], agg::glyph_ren_outline))
		{
			agg::conv_transform<conv_curve_type, agg::trans_affine> trans(curves, transformMatrix);
			
			CGSize defaultAdvances[count];
			if(advances == NULL) {
				// Using a KTFont because we need to get the advancements the same way the layout manager is 
				// getting them.
				// Of course, it would be better if the layout manager could give us the advances it wants us to use...
				KTFont *kfont = [self _cachedKTFontWithFont:font name:fontName size:pointSize];
				[kfont getAdvancements:defaultAdvances forGlyphs:glyphs count:count];
				for(int i=0;i<count;i++){
					defaultAdvances[i].width+=gState->_characterSpacing;
				}	
				advances = defaultAdvances;
			}
			double x = 0;
			double y = 0;
			
			const O2Glyph* p = glyphs;
			
			for (int i = 0; i < count; ++i)
			{
				const agg::glyph_cache* glyph = font_manager->glyph(*p);
				if(glyph)
				{
					font_manager->init_embedded_adaptors(glyph, x, y);
					switch(glyph->data_type)
					{
						case agg::glyph_data_outline: {
							[self rasterizer]->add_path(trans);
							break;
						}
						default:
							// No data to process
							break;
					}
					
					// increment pen position
					x += advances[i].width;
					y += advances[i].height;
					
					++num_glyphs;
				}
				++p;
			}
			
			render_scanlines_aa_solid(self,aggFillColor);
			O2ContextConcatAdvancesToTextMatrix(self,advances,num_glyphs);
		}
	}
	return num_glyphs;
}
#endif

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
	[super initWithSurface:surface flipped:flipped];
	
	int bytesPerRow = O2SurfaceGetBytesPerRow(surface);
	renderingBuffer=new agg::rendering_buffer((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),bytesPerRow);
	
	// Use rgba32
	pixelShadowBytes = new uint8_t[O2SurfaceGetHeight(surface)*bytesPerRow];
	renderingBufferShadow = new agg::rendering_buffer(pixelShadowBytes,O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),bytesPerRow);
	
	rasterizer=new RasterizerType();

	// Use with the right order depending of the bitmap info of the surface - we'll probably want to pass a pixel type here instead of an order to support non 32 bits surfaces and pre/no pre
	renderer = new context_renderer();
	O2BitmapInfo bitmapInfo = O2ImageGetBitmapInfo(surface);
	renderer->context = self;
	/*
	 AlphaFirst => The Alpha channel is next to the Red channel
	 (ARGB and BGRA are both Alpha First formats)
	 AlphaLast => The Alpha channel is next to the Blue channel
	 (RGBA and ABGR are both Alpha Last formats)
	 
	 LittleEndian => Blue comes before Red 
	 (BGRA and ABGR are Little endian formats)
	 BigEndian => Red comes before Blue 
	 (ARGB and RGBA are Big endian formats).
	 */	
	switch (bitmapInfo & kO2BitmapByteOrderMask) {
		case kO2BitmapByteOrder32Big:
			switch (bitmapInfo & kO2BitmapAlphaInfoMask) {
				case kO2ImageAlphaPremultipliedLast:
					renderer->init_pre<agg::order_rgba>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaLast:
					renderer->init<agg::order_rgba>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaPremultipliedFirst:
					renderer->init_pre<agg::order_argb>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaFirst:
					renderer->init<agg::order_argb>(*renderingBuffer, *renderingBufferShadow);
					break;
				default:
					O2Log("UNKNOW ALPHA : %d", bitmapInfo & kO2BitmapAlphaInfoMask);
					renderer->init<agg::order_bgra>(*renderingBuffer, *renderingBufferShadow);
			}
			break;
		case kO2BitmapByteOrderDefault:
		case kO2BitmapByteOrder32Little:
			switch (bitmapInfo & kO2BitmapAlphaInfoMask) {
				case kO2ImageAlphaPremultipliedLast:
					renderer->init_pre<agg::order_abgr>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaLast:
					renderer->init<agg::order_abgr>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaPremultipliedFirst:
					renderer->init_pre<agg::order_bgra>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaFirst:
					renderer->init<agg::order_bgra>(*renderingBuffer, *renderingBufferShadow);
					break;
				default:
					O2Log("UNKNOW ALPHA : %d", bitmapInfo & kO2BitmapAlphaInfoMask);
					renderer->init<agg::order_bgra>(*renderingBuffer, *renderingBufferShadow);
			}
			break;
		default:
			O2Log("UNKNOW ORDER : %x",bitmapInfo & kO2BitmapByteOrderMask);
			renderer->init<agg::order_bgra>(*renderingBuffer, *renderingBufferShadow);
	}

	path=new agg::path_storage();
	
	return self;
}

-(void)dealloc {
	[savedClipPhases release];
	
	delete renderer;
	delete renderingBuffer;
	delete renderingBufferShadow;
	delete rasterizer;
	delete path;
	delete[] pixelShadowBytes;
	
	if (baseRendererAlphaMask[0]) {
		for (int i = 0; i < 2; ++i) {
			free(rBufAlphaMask[i]->buf());
			delete rBufAlphaMask[i];
			delete alphaMask[i];
			delete pixelFormatAlphaMask[i];
			delete baseRendererAlphaMask[i];
			delete solidScanlineRendererAlphaMask[i];
		}
	}
	[super dealloc];
}

-(BOOL)supportsGlobalAlpha
{
	return YES;
}

- (void)createMaskRenderer
{
	// We use two gray masks to render our alpha mask - one for the current mask, one to render a new clipping path using the current mask
	for (int i = 0; i < 2; ++i) {
		O2Surface *surface = [self surface];
		// For some still mysterious reason, if we don't allocate one additional line, we sometimes get some crash when rendering the mask
		// So we'll just extend that buffer until we fix the problem at its root
		void *alphaBuffer = malloc(O2SurfaceGetWidth(surface)*(O2SurfaceGetHeight(surface)+1));
		rBufAlphaMask[i] = new agg::rendering_buffer((unsigned char *)alphaBuffer, O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface), O2SurfaceGetWidth(surface));
		alphaMask[i] = new MaskType(*rBufAlphaMask[i]);
		pixelFormatAlphaMask[i] = new pixfmt_alphaMaskType(*rBufAlphaMask[i]);
		baseRendererAlphaMask[i] = new BaseRendererWithAlphaMaskType(*pixelFormatAlphaMask[i]);
		
		solidScanlineRendererAlphaMask[i] = new agg::renderer_scanline_aa_solid<BaseRendererWithAlphaMaskType>(*baseRendererAlphaMask[i]);
		solidScanlineRendererAlphaMask[i]->color(agg::gray8(255, 255));
	}
}

- (RasterizerType *)rasterizer
{
	return rasterizer;
}

- (context_renderer *)renderer;
{
	return renderer;
}

- (BOOL)useMask
{
	return useMask;
}

- (BOOL)isPremultiplied;
{
	return renderer->premultiplied;
}

- (MaskType*)currentMask
{
	if (baseRendererAlphaMask[0] == NULL) {
		[self createMaskRenderer];
	}
	return alphaMask[currentMask];
}

- (void)setFillAlpha:(O2Float)alpha
{
	// It's actually handled by the global alpha - that's the way it's supposed to work in Cocoa
}

- (void)setStrokeAlpha:(O2Float)alpha
{
	// It's actually handled by the global alpha - that's the way it's supposed to work in Cocoa
}

-(void)updateBlendMode
{
	// Onyx2D -> AGG blend mode conversion
	//	O2Log("Setting blend mode to %d", blendMode);
	enum o2agg::comp_op_e blendModeMap[28]={
		o2agg::comp_op_src_over,
		o2agg::comp_op_multiply,
		o2agg::comp_op_screen,
		o2agg::comp_op_overlay,
		o2agg::comp_op_darken,
		o2agg::comp_op_lighten,
		o2agg::comp_op_color_dodge,
		o2agg::comp_op_color_burn,
		o2agg::comp_op_hard_light,
		o2agg::comp_op_soft_light,
		o2agg::comp_op_difference,
		o2agg::comp_op_exclusion,
		o2agg::comp_op_src_over, // should be Hue
		o2agg::comp_op_src_over, // should be Saturation
		o2agg::comp_op_src_over, // should be Color
		o2agg::comp_op_src_over, // should be Luminosity
		o2agg::comp_op_clear,
		o2agg::comp_op_src,
		o2agg::comp_op_src_in,
		o2agg::comp_op_src_out,
		o2agg::comp_op_src_atop,
		o2agg::comp_op_dst_over,
		o2agg::comp_op_dst_in,
		o2agg::comp_op_dst_out,
		o2agg::comp_op_dst_atop,
		o2agg::comp_op_xor,
		o2agg::comp_op_plus_darker,
		o2agg::comp_op_minus, // shoud be MinusLighter
	};
	O2GState    *gState=O2ContextCurrentGState(self);
	
	renderer->setBlendMode(blendModeMap[O2GStateBlendMode(gState)]);
	renderer->setAlpha(O2GStateAlpha(gState));
	
	O2ColorRef shadowColor = gState->_shadowColor;
	if (shadowColor) {
		shadowColor = O2ColorConvertToDeviceRGB(shadowColor);
		const O2Float *components = O2ColorGetComponents(shadowColor);
		renderer->setShadowColor(agg::rgba(components[0], components[1], components[2], components[3]));
		renderer->setShadowBlurRadius(gState->_shadowBlur);
		renderer->setShadowOffset(gState->_shadowOffset);
		O2ColorRelease(shadowColor);
	} else {
		renderer->setShadowColor(agg::rgba(0, 0, 0, 0));
	}
}


// Update the AGG alpha mask from current GState clip phases
- (void)updateMask
{
	if (maskValid == YES) {
		return;
	}
	currentMask = 0;
	useMask = NO;
	if ([savedClipPhases count]) {
		typedef agg::conv_curve<agg::path_storage> conv_crv_type;
		typedef agg::conv_transform<conv_crv_type> transStroke;
		
		[self rasterizer]->reset();
		[self rasterizer]->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
		O2GState *gState=O2ContextCurrentGState(self);
		O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
		agg::trans_affine deviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
		
		agg::path_storage aggPath;
		for (int i = 0; i < [savedClipPhases count]; ++i) {
			O2ClipPhase *phase = [savedClipPhases objectAtIndex:i];
			
			switch(O2ClipPhasePhaseType(phase)){
				case O2ClipPhaseNonZeroPath:
				case O2ClipPhaseEOPath: {
					O2PathRef maskPath = O2ClipPhaseObject(phase);
					// We can ignore path that are rect - the default clipping takes that into account
					NSRect rect;
					if (!O2PathIsRect(maskPath, &rect)) {
						if (useMask == NO) {
							// Fill the mask content on first use
							useMask = YES;
							if (baseRendererAlphaMask[0] == NULL) {
								[self createMaskRenderer];
							}
							baseRendererAlphaMask[0]->clear(agg::gray8(255, 255));
						}
						// Switch masks
						currentMask = !currentMask;
						// Clear the new mask
						baseRendererAlphaMask[currentMask]->clear(agg::gray8(0));
						
						buildAGGPathFromO2PathAndTransform(&aggPath,maskPath,O2AffineTransformIdentity);
						
						agg::conv_curve<agg::path_storage> curve(aggPath);
						curve.approximation_scale(deviceMatrix.scale());
						O2ClipPhaseType phaseType = O2ClipPhasePhaseType(phase);
						if (phaseType == O2ClipPhaseNonZeroPath)
							rasterizer->filling_rule(agg::fill_non_zero);
						else
							rasterizer->filling_rule(agg::fill_even_odd);
						
						rasterizer->add_path(curve);
						
						// Render the path masked by the previous mask
						scanline_mask_type sl(*self->alphaMask[!currentMask]);
						renderer->render_scanlines(*rasterizer, sl, *solidScanlineRendererAlphaMask[currentMask]);
					}
					break;
				}
				case O2ClipPhaseMask:
					O2Log("%@:Clip to mask unsupported", self);
					// Unsupported for now
					break;
			}
		}
	}
	maskValid = YES;
}

-(void)clipToState:(O2ClipState *)clipState {
	// No need to change the clipping if the clip phases are the same as before
	NSArray *clipPhases = [clipState clipPhases];
	if ([clipPhases isEqualToArray:savedClipPhases]) {
		return;
	}
	[savedClipPhases release];
	savedClipPhases = [clipPhases copy];
	
	/*
	 The builtin Onyx2D renderer only supports viewport clipping (one integer rect), so once the superclass has clipped
	 the viewport is what we want to clip to also. The base AGG renderer also does viewport clipping, so we just set it.
	 */
	[super clipToState:clipState];
	renderer->clipBox(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight);
	
	// That will force a rebuild of the mask next time we need to draw something - no need to build it now as it might
	// be not needed
	maskValid = NO;
}

-(void)drawPath:(O2PathDrawingMode)drawingMode { 
	renderer->premultiplied = YES;
	BOOL doFill=NO;
	BOOL doEOFill=NO;
	BOOL doStroke=NO;
	
	[self updateMask];
	[self updateBlendMode];

	rasterizer->reset();
	rasterizer->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
	
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
	
	transferPath(self,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));

	O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
	
	agg::trans_affine aggDeviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

	if(doFill || doEOFill) {
		O2PatternRef pattern = O2ColorGetPattern(gState->_fillColor);
		if (pattern) {
			// Note: pattern support is incomplete :
			// We don't make much use of the pattern phase, pattern color or pattern bounds
			
			// Create a context with the size of our pattern tile
			O2Surface       *surface=[self createSurfaceWithWidth:[pattern xstep] height:[pattern ystep]];
			O2Context_AntiGrain *context=[[self->isa alloc] initWithSurface:surface flipped:YES];
			
			// Draw the pattern tile
			[pattern drawInContext:context];
			O2ContextRelease(context);
			
			// Build the global transform from the pattern to the device
			O2AffineTransform matrix = O2AffineTransformConcat( ([pattern matrix]), O2AffineTransformInvert(gState->_userSpaceTransform));
			
			agg::trans_affine globalTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
			globalTransform.multiply(aggDeviceMatrix);
			globalTransform.invert();
			
			// Create an agg buffer from the Surface content
			uint8_t *imgBytes = (uint8_t *)[surface pixelBytes];
			agg::rendering_buffer imageBuffer(imgBytes, O2SurfaceGetWidth(surface) , O2SurfaceGetHeight(surface), O2SurfaceGetBytesPerRow(surface));

			// Fill the current agg path with the repeated tile
			agg::conv_curve<agg::path_storage> curve(*(self->path));
			agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, aggDeviceMatrix);
			[self rasterizer]->add_path(trans);
			renderer->premultiplied = YES;
			O2AGGContextDrawImage<o2agg::pixfmt_bgra32_pre>(self, imageBuffer, globalTransform, kImageInterpolationRepeat);
			
			[surface release];
		} else {
			O2ColorRef   fillColor=O2ColorConvertToDeviceRGB(gState->_fillColor);
			const float *fillComps=O2ColorGetComponents(fillColor);
			agg::rgba aggFillColor(fillComps[0],fillComps[1],fillComps[2],fillComps[3]);
			if (doFill) {
				O2AGGContextFillPathWithRule(self,aggFillColor,aggDeviceMatrix,agg::fill_non_zero);
			} else {
				O2AGGContextFillPathWithRule(self,aggFillColor,aggDeviceMatrix,agg::fill_even_odd);
			}
			O2ColorRelease(fillColor);
		}
	}
	
	if(doStroke){
		// Note: pattern stroking not supported for now
		O2ColorRef   strokeColor=O2ColorConvertToDeviceRGB(gState->_strokeColor);
		const float *strokeComps=O2ColorGetComponents(strokeColor);
		agg::rgba aggStrokeColor(strokeComps[0],strokeComps[1],strokeComps[2],strokeComps[3]);
		O2AGGContextStrokePath(self,aggStrokeColor,aggDeviceMatrix);
		O2ColorRelease(strokeColor);
	}
	
	O2PathReset(_path);
}

-(void)replacePathWithStrokedPath 
{
	O2GState    *gState=O2ContextCurrentGState(self);
	
	transferPath(self,(O2PathRef)_path,O2AffineTransformInvert(gState->_userSpaceTransform));
	
	O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
	agg::trans_affine aggDeviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);

	O2AGGReplaceStrokedPath(self,aggDeviceMatrix);
}

-(void)drawImage:(O2Image *)image inRect:(O2Rect)rect
{ 
	int width = O2ImageGetWidth(image);
	int height = O2ImageGetHeight(image);
	int bytesPerRow = O2ImageGetBytesPerRow(image);
	int bpp = O2ImageGetBitsPerPixel(image);
	int bitmapInfo = O2ImageGetBitmapInfo(image);
	
	if (bpp == 32) { // We don't support other modes for now
		[self updateMask];
		[self updateBlendMode];

		rasterizer->reset();
		rasterizer->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
		agg::path_storage p2;
		p2.move_to(rect.origin.x, rect.origin.y);
		p2.line_to(rect.origin.x+rect.size.width, rect.origin.y);
		p2.line_to(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
		p2.line_to(rect.origin.x, rect.origin.y+rect.size.height);
		p2.close_polygon();
		
		O2GState    *gState=O2ContextCurrentGState(self);
		O2AffineTransform deviceTransform= gState->_deviceSpaceTransform;
		
		agg::trans_affine transform(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
		
		agg::conv_transform<agg::path_storage> trans(p2, transform); // Global Affine transformer
		rasterizer->add_path(trans);
		
		// Flipped scaled transfrom from the original image bounds to the destination rect
		O2AffineTransform imageTransform = O2AffineTransformMakeTranslation(rect.origin.x, rect.origin.y + rect.size.height);
		imageTransform = O2AffineTransformScale(imageTransform, rect.size.width/float(width),  -rect.size.height/float(height));
		
		agg::trans_affine globalTransform(imageTransform.a, imageTransform.b, imageTransform.c, imageTransform.d, imageTransform.tx, imageTransform.ty);
		globalTransform.multiply(transform);
		
		// We use bilinear scaling for images that need to be shrunk.  At 100% scale size it preserves the image better.
		// Remember we don't even think about doing this for images that need to expand; those should always use the bicubic filter; however,
		//    that is user-selectable.
		
		double compoundTransform[6];
		globalTransform.store_to(compoundTransform);
		
		bool reducedScale = true;
		bool isUnity = true;
		for (int i = 0; i < 4; ++i)
		{
			if (fabsf((float) compoundTransform[i]) >= (1.f + 1e-06f))
			{
				reducedScale = false;
			}
			if (fabs(fabs(compoundTransform[i]) - 1.f) > 1e-6f  && fabs(compoundTransform[i]) > 1e-6f)
			{
				isUnity = false;
			}
		}
		// Round the physical screen coordinate to an integer boundary so filtering works better.  This seems to make images that are 1x1 rasterize
		//    exactly.  Changing the pixel coordinates on smaller scaled images introuduces unpleasant artifacts.
		if (isUnity)
		{
			compoundTransform[4] = floor(compoundTransform[4]);
			compoundTransform[5] = floor(compoundTransform[5]);
		}
		globalTransform.load_from(compoundTransform);
		
		globalTransform.invert();
		
		uint8_t *imgBytes = (uint8_t *)[image directBytes];
		agg::rendering_buffer imageBuffer(imgBytes, width, height, bytesPerRow);
		
		BOOL noInterpolation = isUnity;
		
		int interpolationQuality = [gState interpolationQuality];
		if (interpolationQuality == kO2InterpolationNone) {
			noInterpolation = YES;
		}
		
		ImageInterpolationType interpolationType = kImageInterpolationBilinear;
		if (noInterpolation) {
			interpolationType = kImageInterpolationNone;
		} 
		/*
		 From David Duncan :
		 
		 AlphaFirst => The Alpha channel is next to the Red channel
		 (ARGB and BGRA are both Alpha First formats)
		 AlphaLast => The Alpha channel is next to the Blue channel
		 (RGBA and ABGR are both Alpha Last formats)
		 
		 LittleEndian => Blue comes before Red 
		 (BGRA and ABGR are Little endian formats)
		 BigEndian => Red comes before Blue 
		 (ARGB and RGBA are Big endian formats).
		 */
		switch (bitmapInfo & kO2BitmapByteOrderMask) {
				// Big Endian is RB
			case kO2BitmapByteOrder32Big:
				switch (bitmapInfo & kO2BitmapAlphaInfoMask) {
					case kO2ImageAlphaPremultipliedLast:
						renderer->premultiplied = YES;
						O2AGGContextDrawImage<o2agg::pixfmt_rgba32_pre>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaLast:
						renderer->premultiplied = NO;
						O2AGGContextDrawImage<o2agg::pixfmt_rgba32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaPremultipliedFirst:
						renderer->premultiplied = YES;
						O2AGGContextDrawImage<o2agg::pixfmt_argb32_pre>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaFirst:
						renderer->premultiplied = NO;
						O2AGGContextDrawImage<o2agg::pixfmt_argb32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					default:
						O2Log("UNKNOW ALPHA");
						// Fallback to the default implementation - that means path clipping, shadow, layers... won't work well on this one
						[super drawImage:image inRect:rect];
				}
				break; 
				// Little Endian is BG
			case kO2BitmapByteOrderDefault:
			case kO2BitmapByteOrder32Little:
				switch (bitmapInfo & kO2BitmapAlphaInfoMask) {
					case kO2ImageAlphaPremultipliedLast:
						renderer->premultiplied = YES;
						O2AGGContextDrawImage<o2agg::pixfmt_abgr32_pre>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaLast:
						renderer->premultiplied = NO;
						O2AGGContextDrawImage<o2agg::pixfmt_abgr32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaPremultipliedFirst:
						renderer->premultiplied = YES;
						O2AGGContextDrawImage<o2agg::pixfmt_bgra32_pre>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaFirst:
						renderer->premultiplied = NO;
						O2AGGContextDrawImage<o2agg::pixfmt_bgra32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					default:
						// Fallback to the default implementation - that means clipping, shadow, layers... won't work on this one
						O2Log("UNKNOW ALPHA");
						[super drawImage:image inRect:rect];
				}
				break;
			default:
				O2Log("UNKNOW ORDER");
				// Fallback to the default implementation - that means path clipping, shadow, layers... won't work well on this one
				[super drawImage:image inRect:rect];
				break;
		}
	}
	else
	{
		O2Log("Unsuported image format");
		// Fallback to the default implementation - that means path clipping, shadow, layers... won't work well on this one
		[super drawImage:image inRect:rect];
	}
}

-(void)drawShading:(O2Shading *)shading
{ 
	renderer->premultiplied = YES;
	[self updateMask];
	[self updateBlendMode];
	
	rasterizer->reset();
	rasterizer->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
	if ([shading isAxial]) {
		O2AGGContextDrawShading<agg::gradient_x>(self, shading, _vpx, _vpy, _vpwidth, _vpheight);
	} else {
		// Note: we only support circle gradient for now where startPoint = endPoint
		O2AGGContextDrawShading<agg::gradient_circle>(self, shading, _vpx, _vpy, _vpwidth, _vpheight);
	}
}

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused {
	// NOTE: We could create a new context with only the current clipping size, and offset all clipping/drawing from the clipping origin
	O2LayerRef layer=O2LayerCreateWithContext(self,[self size],unused);
	
	[self->_layerStack addObject:layer];
	O2LayerRelease(layer);

	// Attach to the layer surface
	O2Surface *surface = O2LayerGetSurface(layer);
	renderingBuffer->attach((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),O2SurfaceGetBytesPerRow(surface));

	O2ContextSaveGState(self); // Save the pre layer-time context
	
	/**
	 * From Cocoa doc :
	 * graphics state parameters remain unchanged except for alpha (which is set to 1), shadow (which is turned off), blend mode (which is set to normal), 
	 * and other parameters that affect the final composite.
	 */
	
	O2ContextResetClip(self); // Starts with a clean clipping region
	O2GStateSetBlendMode(O2ContextCurrentGState(self), kO2BlendModeNormal);
	O2GStateSetAlpha(O2ContextCurrentGState(self), 1.);
	// We're keeping the shadow for when we render the layer
	
	O2ContextSaveGState(self); // Save that clean state - we'll use it to render the layer

	// No shadow from now
	[O2ContextCurrentGState(self) setShadowOffset:O2SizeZero blur:0. color:nil];

}

-(void)endTransparencyLayer {
	O2LayerRef layer=O2LayerRetain([self->_layerStack lastObject]);
	
	[self->_layerStack removeLastObject];
	
	O2Size size=[self size];
	
	// Reattach the renderer to the top surface (either to the new top layer if any or the context one)
	O2LayerRef newTopLayer = [self->_layerStack lastObject];
	O2Surface *surface = newTopLayer?O2LayerGetSurface(newTopLayer):_surface;
	renderingBuffer->attach((unsigned char *)O2SurfaceGetPixelBytes(surface),O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface),O2SurfaceGetBytesPerRow(surface));

	O2ContextRestoreGState(self); // Restore the clean state

	// Draw the layer content into our surface
	O2ContextSaveGState(self);
	// We want no transform here as the layer surface matches the context one
	O2ContextConcatCTM(self, O2AffineTransformInvert(O2ContextGetCTM(self)));
	[self drawImage:O2LayerGetSurface(layer) inRect:O2RectMake(0,0,size.width,size.height)];
	O2ContextRestoreGState(self);

	O2ContextRestoreGState(self); // Restore the pre layer-time context

	O2LayerRelease(layer);
}

#ifdef O2AGG_GLYPH_SUPPORT
-(void)showGlyphs:(const O2Glyph *)glyphs advances:(const O2Size *)advances count:(unsigned)count
{
	renderer->premultiplied = YES;
	[self updateMask];
	[self updateBlendMode];
	
	rasterizer->reset();
	rasterizer->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
	
	O2AGGContextShowGlyphs(self,glyphs,advances,count);
}
#endif
#endif
@end
