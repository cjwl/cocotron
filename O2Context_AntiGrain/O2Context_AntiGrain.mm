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
#include <agg_pixfmt_rgb.h>
#include <agg_span_image_filter_rgba.h>
#include <agg_span_image_filter_rgb.h>

#include <agg_conv_dash.h>
#include "partial_stack_blur.h"

typedef enum {
	kImageInterpolationNone,
	kImageInterpolationBilinear,
	kImageInterpolationBicubic,
	kImageInterpolationLanczos
} ImageInterpolationType;

//#define DEBUG

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
typedef agg::scanline_u8_am<agg::alpha_mask_gray8> scanline_mask_type;

// Apply some alpha value to its input spans
template<class color_type> struct span_alpha_converter
{
	span_alpha_converter(float alpha) : m_alpha(alpha) {};
	
	void prepare() {}
	
	void generate(color_type* span, int x, int y, unsigned len)
	{
		if(m_alpha < 1.) {
			do {
				span->opacity(span->opacity()*m_alpha);
				++span;
			} while(--len);
		} 
	}		
private:
	double m_alpha;
};

// Replace spans with a fixed color, keeping the original opacity - used as a transformer to render shadow for non-plain color
template<class color_type> struct span_color_converter
{
	span_color_converter(color_type &color) : m_color(color) {};
	
	void prepare() {}
	
	void generate(color_type* span, int x, int y, unsigned len)
	{
		do {
			// Replace the span color, with m_color * span opacity
			if (span->opacity() > 0) {
				color_type color = m_color;
				color.opacity(color.opacity()*span->opacity());
				*span = color;
			}
			++span;
		} while(--len);
	}		
private:
	color_type m_color;
};

class context_renderer
{
	class context_renderer_helper_base
	{
	public:
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
	
	template<class Order> class context_renderer_helper : public context_renderer_helper_base
	{
		typedef agg::comp_op_adaptor_rgba<agg::rgba8, Order> blender_type;
		typedef agg::pixfmt_custom_blend_rgba<blender_type, agg::rendering_buffer> pixfmt_type;
		
		typedef agg::pixfmt_rgba32 pixfmt_shadow_type;
		
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
			shadowOffset = offset;;
		}
		
		void clipBox(int a, int b, int c, int d)
		{
			ren_base->reset_clipping(1);
			ren_base->clip_box(a, b, c, d);
			ren_shadow->reset_clipping(1);
			ren_shadow->clip_box(a, b, c, d);
		}
		
		template<class Ras, class S> void blur(S &sl)
		{
			float xmin = ren_base->xmin();
			float ymin = ren_base->ymin();
			float xmax = ren_base->xmax();
			float ymax = ren_base->ymax();
			
			// Blur the shadows
			if (shadowBlurRadius > 0) {
				O2Log("Shadow: blur shadow - are : ((%.0f,%.0f),(%.0f,%.0f))", xmin, ymin, xmax - xmin, ymax - ymin);
				// Stack blur - not really a gaussian one but much faster and good enough
				// Blur only the current clipped area - no need to process pixels we won't see
				partial_stack_blur_rgba32(*pixelFormatShadow, agg::uround(shadowBlurRadius), agg::uround(shadowBlurRadius), 
										  xmin, xmax, ymin, ymax);
				O2Log("Shadow: done blur");
			}
			
			Ras r;
			r.clip_box(xmin, ymin, xmax, ymax);

			// Rasterize the shadow to our main renderer
			agg::span_allocator<typename pixfmt_shadow_type::color_type> sa;
			typedef agg::image_accessor_clone<pixfmt_shadow_type> img_accessor_type;
			
			typedef agg::span_interpolator_linear<agg::trans_affine> interpolator_type;
			
			agg::path_storage aggPath;
			
			// We'll use a path that cover the current clipped rect, and render that path using the shadow image
			aggPath.move_to(xmin, ymin);
			aggPath.line_to(xmax, ymin);
			aggPath.line_to(xmax, ymax);
			aggPath.line_to(xmin, ymax);
			aggPath.end_poly();
			
			agg::conv_curve<agg::path_storage> curve(aggPath);
			r.add_path(curve);					
			
			img_accessor_type ia(*pixelFormatShadow);
			agg::trans_affine transform;
			transform.translate(-shadowOffset.width, shadowOffset.height);  // Transform from the shadow to the original content
			interpolator_type interpolator(transform);
			typedef agg::span_image_filter_rgba_nn<img_accessor_type, interpolator_type> span_gen_type;
			span_gen_type sg(ia, interpolator);
			
			pixelFormat->comp_op(agg::comp_op_src_over); // Always use src_over when copying the shadow
			agg::render_scanlines_aa(r, sl, *ren_base, sa, sg);
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
				span_color_converter<agg::rgba8> color_converter(color);
				agg::span_converter<T, span_color_converter<agg::rgba8> > converter(type, color_converter);
				agg::render_scanlines_aa(rasterizer, sl, *ren_shadow, span_allocator, converter);

				// Blur the shadow buffer
				blur<Ras>(sl);
				O2Log("%p:Done Drawing shadow Image", this);
			}
			
			// And finally do the "normal" drawing
			if (alpha >= 1) {
				// No need for an alpha converter
				agg::render_scanlines_aa(rasterizer, sl, *ren_base, span_allocator, type);
			} else {
				span_alpha_converter<agg::rgba8> alpha_converter(alpha);
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
				agg::render_scanlines_aa_solid(rasterizer, sl, *ren_shadow, color);
				
				// Blur the shadow buffer
				blur<Ras>(sl);
			}
			// And finally do the "normal" drawing
			T color = type;
			color.opacity(color.opacity() * alpha );
			agg::render_scanlines_aa_solid(rasterizer, sl, *ren_base, color);
		}
		
		bool isRGBA() { return NO; };
		bool isBGRA() { return NO; };
		bool isARGB() { return NO; };
		bool isABGR() { return NO; };
	};
	
	
	context_renderer_helper_base* helper;
	
	typedef class context_renderer_helper<agg::order_rgba> rgba_helper;
	typedef class context_renderer_helper<agg::order_bgra> bgra_helper;
	typedef class context_renderer_helper<agg::order_argb> argb_helper;
	typedef class context_renderer_helper<agg::order_abgr> abgr_helper;
	
public:
	virtual ~context_renderer()
	{
		delete helper;
	}
	template<class Order> void init(agg::rendering_buffer &renderingBuffer, agg::rendering_buffer &renderingShadowBuffer)
	{
		helper = new context_renderer_helper<Order>(renderingBuffer, renderingShadowBuffer);
	}
	
	// Not sure how to better write that since we can't have virtual template methods and we don't know some type
	// at compile time (like pixel format)
	template<class Ras, class S, class T> void render_scanlines(Ras &rasterizer, S &sl, T &type)
	{
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
	template<class Ras, class S, class SA, class T> void render_scanlines_aa(Ras &rasterizer, S &sl, SA &span_allocator, T &type)
	{
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
	template<class Ras, class S, class T> void render_scanlines_aa_solid(Ras &rasterizer, S &sl, T &type)	
	{
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


class gradient_evaluator
{
public:
	// We don't really care about the size - we just need it is big enough for what we draw
	gradient_evaluator(O2Shading *shading, unsigned size = 4096) :
	m_shading(shading), m_size(size) {}
	
	int size() const { return m_size; }
	agg::rgba operator [] (unsigned v) const 
	{
		O2Float result[4] = { 1 };
		O2FunctionEvaluate([m_shading function], v/float(m_size-1), result);
		agg::rgba color;
		color.r = result[0];
		color.g = result[1];
		color.b = result[2];
		color.a = result[3];
		return color;
	}
private:
	O2Shading *m_shading;
	unsigned m_size;
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
	typedef agg::pixfmt_bgra32 pixfmt_type; // That should be the same pixel type as the context - so that probably should be moved to the renderer - probably mostly everything should be moved there
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
	
	gradient_func_type gradient_func; 
	color_func_type color_func(shading); 
	
	agg::trans_affine gradient_mtx; 
	gradient_mtx.reset(); 
	double angle = atan2(y2-y1, x2-x1); 
	gradient_mtx *= agg::trans_affine_rotation(angle); 
	gradient_mtx *= agg::trans_affine_translation(x1, y1); 
	gradient_mtx.invert(); 
	
	interpolator_type span_interpolator(gradient_mtx); 
	span_allocator_type span_allocator;
	float startValue = [shading isAxial]?0.:[shading startRadius];
	float endValue = [shading isAxial]?sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1)):[shading endRadius];
	span_gradient_type  span_gradient(span_interpolator, gradient_func, color_func, startValue, endValue); 
	
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

template <class pixfmt> void O2AGGContextDrawImage(O2Context_AntiGrain *self, agg::rendering_buffer &imageBuffer, agg::trans_affine transform, ImageInterpolationType interpolationQuality)
{
	agg::span_allocator<typename pixfmt::color_type> sa;
	pixfmt          img_pixf(imageBuffer);
	typedef agg::image_accessor_clone<pixfmt> img_accessor_type;
	img_accessor_type ia(img_pixf);
	
	typedef agg::span_interpolator_linear<agg::trans_affine> interpolator_type;
	interpolator_type interpolator(transform);
	
	// Use a filter according to the wanted interpolation quality
	switch (interpolationQuality) {
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
	}
}

template <class StrokeType> void O2AGGContextStrokePath(O2Context_AntiGrain *self, StrokeType &stroke, agg::rgba color,agg::trans_affine deviceMatrix) 
{
	O2GState *gState=O2ContextCurrentGState(self);
	
	agg::conv_transform<StrokeType, agg::trans_affine> trans(stroke, deviceMatrix);
	
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
	
	[self rasterizer]->add_path(trans);
	[self rasterizer]->filling_rule(agg::fill_non_zero);
	
	render_scanlines_aa_solid(self, color);	
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

static void O2AGGContextFillPathWithRule(O2Context_AntiGrain *self,agg::rgba color,agg::trans_affine deviceMatrix,agg::filling_rule_e fillingRule) {
	agg::conv_curve<agg::path_storage> curve(*(self->path));
	agg::conv_transform<agg::conv_curve<agg::path_storage>, agg::trans_affine> trans(curve, deviceMatrix);
	
	curve.approximation_scale(deviceMatrix.scale());
	
	[self rasterizer]->add_path(trans);
	[self rasterizer]->filling_rule(fillingRule);
	
	render_scanlines_aa_solid(self,color);
}

static void O2AGGContextStrokePath(O2Context_AntiGrain *self,agg::rgba color,agg::trans_affine deviceMatrix) {	
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
		O2AGGContextStrokePath<typeof(stroke)>(self,stroke,color,deviceMatrix);
	} else {
		// Just stroke
		agg::conv_stroke<agg::conv_curve<agg::path_storage> > stroke(curve);
		O2AGGContextStrokePath<typeof(stroke)>(self,stroke,color,deviceMatrix);
	}
}


/* Transfer path from Onyx2D to AGG. Not a very expensive operation, tessellation, stroking and rasterization are the expensive pieces
 */
static void buildAGGPathFromO2PathAndTransform(agg::path_storage *aggPath,O2PathRef path,O2AffineTransform xform){
	const unsigned char *elements=O2PathElements(path);
	const O2Point       *points=O2PathPoints(path);
	unsigned             i,numberOfElements=O2PathNumberOfElements(path),pointIndex;
	
	pointIndex=0;
	
	aggPath->remove_all();
	
	for(i=0;i<numberOfElements;i++){
		
		switch(elements[i]){
				
			case kO2PathElementMoveToPoint:{
				NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->move_to(point.x,point.y);
			}
				break;
				
			case kO2PathElementAddLineToPoint:{
				NSPoint point=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->line_to(point.x,point.y);
			}
				break;
				
			case kO2PathElementAddCurveToPoint:{
				NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
				NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
				NSPoint end=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->curve4(cp1.x,cp1.y,cp2.x,cp2.y,end.x,end.y);
			}
				break;
				
			case kO2PathElementAddQuadCurveToPoint:{
				NSPoint cp1=O2PointApplyAffineTransform(points[pointIndex++],xform);
				NSPoint cp2=O2PointApplyAffineTransform(points[pointIndex++],xform);
				
				aggPath->curve3(cp1.x,cp1.y,cp2.x,cp2.y);
			}
				break;
				
			case kO2PathElementCloseSubpath:
				aggPath->end_poly();
				break;
		}    
	}
	
}

static void transferPath(O2Context_AntiGrain *self,O2PathRef path,O2AffineTransform xform) {
	buildAGGPathFromO2PathAndTransform(self->path, path, xform);
}


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
				case kO2ImageAlphaLast:
					renderer->init<agg::order_rgba>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaPremultipliedFirst:
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
				case kO2ImageAlphaLast:
					renderer->init<agg::order_abgr>(*renderingBuffer, *renderingBufferShadow);
					break;
				case kO2ImageAlphaPremultipliedFirst:
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
		void *alphaBuffer = malloc(O2SurfaceGetWidth(surface)*O2SurfaceGetHeight(surface));
		rBufAlphaMask[i] = new agg::rendering_buffer((unsigned char *)alphaBuffer, O2SurfaceGetWidth(surface),O2SurfaceGetHeight(surface), O2SurfaceGetWidth(surface));
		alphaMask[i] = new agg::alpha_mask_gray8(*rBufAlphaMask[i]);
		pixelFormatAlphaMask[i] = new pixfmt_alphaMaskType(*rBufAlphaMask[i]);
		baseRendererAlphaMask[i] = new BaseRendererWithAlphaMaskType(*pixelFormatAlphaMask[i]);
		
		solidScanlineRendererAlphaMask[i] = new agg::renderer_scanline_aa_solid<BaseRendererWithAlphaMaskType>(*baseRendererAlphaMask[i]);
		solidScanlineRendererAlphaMask[i]->color(agg::gray8(255, 255));
	}
}

- (RasterizerType *)rasterizer
{
	O2LayerRef layer=[self->_layerStack lastObject];
	if (layer) {
		// Use the layer rasterizer
		O2Context_AntiGrain *context = (O2Context_AntiGrain *)O2LayerGetContext(layer);
		return [context rasterizer];
	}
	
	return rasterizer;
}

- (context_renderer *)renderer;
{
	O2LayerRef layer=[self->_layerStack lastObject];
	if (layer) {
		// Use the layer renderer
		O2Context_AntiGrain *context = (O2Context_AntiGrain *)O2LayerGetContext(layer);
		return [context renderer];
	}
	
	return renderer;
}

- (BOOL)useMask
{
	return useMask;
}

- (agg::alpha_mask_gray8*)currentMask
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
		agg::comp_op_minus, // MinusLighter
	};
	O2GState    *gState=O2ContextCurrentGState(self);
	
	[self renderer]->setBlendMode(blendModeMap[O2GStateBlendMode(gState)]);
	[self renderer]->setAlpha(O2GStateAlpha(gState));
	
	// TODO : We suppose the color is RGBA - convert it if needed
	O2ColorRef shadowColor = gState->_shadowColor;
	if (shadowColor) {
		shadowColor = O2ColorConvertToDeviceRGB(shadowColor);
		const O2Float *components = O2ColorGetComponents(shadowColor);
		[self renderer]->setShadowColor(agg::rgba(components[0], components[1], components[2], components[3]));
		[self renderer]->setShadowBlurRadius(gState->_shadowBlur);
		[self renderer]->setShadowOffset(gState->_shadowOffset);
	} else {
		[self renderer]->setShadowColor(agg::rgba(0, 0, 0, 0));
	}
}


// Update the AGG alpha mask from current GState clip phases
- (void)updateMask
{
	if (maskValid == YES) {
		return;
	}
	currentMask = 0;
	
	if ([savedClipPhases count]) {
		typedef agg::conv_curve<agg::path_storage> conv_crv_type;
		typedef agg::conv_transform<conv_crv_type> transStroke;
		
		[self rasterizer]->reset();
		[self rasterizer]->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
		O2GState *gState=O2ContextCurrentGState(self);
		O2AffineTransform deviceTransform=gState->_deviceSpaceTransform;
		agg::trans_affine deviceMatrix(deviceTransform.a,deviceTransform.b,deviceTransform.c,deviceTransform.d,deviceTransform.tx,deviceTransform.ty);
		
		agg::path_storage aggPath;
		useMask = NO;
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
							[self rasterizer]->filling_rule(agg::fill_non_zero);
						else
							[self rasterizer]->filling_rule(agg::fill_even_odd);
						
						[self rasterizer]->add_path(curve);
						
						// Render the path masked by the previous mask
						scanline_mask_type sl(*self->alphaMask[!currentMask]);
						[self renderer]->render_scanlines(*[self rasterizer], sl, *solidScanlineRendererAlphaMask[currentMask]);
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
	[self renderer]->clipBox(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight);
	
	// That will force a rebuild of the mask next time we need to draw something - no need to build it now as it might
	// be not needed
	maskValid = NO;
}

-(void)drawPath:(O2PathDrawingMode)drawingMode { 
	BOOL doFill=NO;
	BOOL doEOFill=NO;
	BOOL doStroke=NO;
	
	[self updateMask];
	[self updateBlendMode];
	
	[self rasterizer]->reset();
	[self rasterizer]->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
	
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
	
	if(doStroke){
		O2ColorRef   strokeColor=O2ColorConvertToDeviceRGB(gState->_strokeColor);
		const float *strokeComps=O2ColorGetComponents(strokeColor);
		agg::rgba aggStrokeColor(strokeComps[0],strokeComps[1],strokeComps[2],strokeComps[3]);
		O2AGGContextStrokePath(self,aggStrokeColor,aggDeviceMatrix);
		O2ColorRelease(strokeColor);
	}
	
	O2PathReset(_path);
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

		[self rasterizer]->reset();
		[self rasterizer]->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
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
		[self rasterizer]->add_path(trans);
		
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
			if (compoundTransform[i] != 1.f && compoundTransform[i] != 0.f)
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
						O2AGGContextDrawImage<agg::pixfmt_rgba32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaLast:
						O2AGGContextDrawImage<agg::pixfmt_rgba32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaPremultipliedFirst:
						O2AGGContextDrawImage<agg::pixfmt_argb32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaFirst:
						O2AGGContextDrawImage<agg::pixfmt_argb32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					default:
						O2Log("UNKNOW ALPHA");
						// Fallback to the default implementation - that means clipping, shadow, layers... won't work on this one
						[super drawImage:image inRect:rect];
				}
				break;
				// Little Endian is BG
			case kO2BitmapByteOrderDefault:
			case kO2BitmapByteOrder32Little:
				switch (bitmapInfo & kO2BitmapAlphaInfoMask) {
					case kO2ImageAlphaPremultipliedLast:
						O2AGGContextDrawImage<agg::pixfmt_abgr32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaLast:
						O2AGGContextDrawImage<agg::pixfmt_abgr32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaPremultipliedFirst:
						O2AGGContextDrawImage<agg::pixfmt_bgra32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					case kO2ImageAlphaFirst:
						O2AGGContextDrawImage<agg::pixfmt_bgra32>(self, imageBuffer, globalTransform, interpolationType);
						break;
					default:
						// Fallback to the default implementation - that means clipping, shadow, layers... won't work on this one
						O2Log("UNKNOW ALPHA");
						[super drawImage:image inRect:rect];
				}
				break;
			default:
				O2Log("UNKNOW ORDER");
				[super drawImage:image inRect:rect];
				break;
		}
	}
	else
	{
		O2Log("Unsuported image format");
		// Fallback to the default implementation - that means clipping, shadow, layers... won't work on this one
		[super drawImage:image inRect:rect];
	}
}

-(void)drawShading:(O2Shading *)shading
{ 
	[self updateMask];
	[self updateBlendMode];
	
	[self rasterizer]->reset();
	[self rasterizer]->clip_box(self->_vpx,self->_vpy,self->_vpx+self->_vpwidth,self->_vpy+self->_vpheight); 
		
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
	O2ContextSaveGState(self);

	// Be sure we'll update the clipping area for the layer context
	[savedClipPhases release];
	savedClipPhases = nil;
	
	/**
	 * From Cocoa doc :
	 * graphics state parameters remain unchanged except for alpha (which is set to 1), shadow (which is turned off), blend mode (which is set to normal), 
	 * and other parameters that affect the final composite.
	 */
	O2GStateSetBlendMode(O2ContextCurrentGState(self), kO2BlendModeNormal);
	[O2ContextCurrentGState(self) setShadowOffset:O2SizeZero blur:0. color:nil];
	O2GStateSetAlpha(O2ContextCurrentGState(self), 1.);
}

-(void)endTransparencyLayer {
	O2LayerRef layer=O2LayerRetain([self->_layerStack lastObject]);
	
	O2ContextRestoreGState(self);
	[self->_layerStack removeLastObject];
	
	O2Size size=[self size];
	
	// Be sure we'll update the clipping area
	[savedClipPhases release];
	savedClipPhases = nil;
	
	// Draw the layer content into our surface
	O2AffineTransform transform = O2ContextGetCTM(self);
	O2ContextSaveGState(self);
	// We want no transform here as the layer surface matches the context one
	O2ContextConcatCTM(self, O2AffineTransformInvert(O2ContextGetCTM(self)));
	[self drawImage:O2LayerGetSurface(layer) inRect:O2RectMake(0,0,size.width,size.height)];
	O2ContextRestoreGState(self);

	O2LayerRelease(layer);
}
#endif
@end
