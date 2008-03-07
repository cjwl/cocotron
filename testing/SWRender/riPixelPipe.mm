/*------------------------------------------------------------------------
 *
 * OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and /or associated documentation files
 * (the "Materials "), to deal in the Materials without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Materials,
 * and to permit persons to whom the Materials are furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Materials. 
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE MATERIALS OR
 * THE USE OR OTHER DEALINGS IN THE MATERIALS.
 *
 *//**
 * \file
 * \brief	Implementation of Paint and pixel pipe functionality.
 * \note	
 *//*-------------------------------------------------------------------*/

#include "riPixelPipe.h"

//==============================================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Paint constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Paint::Paint() :
	m_paintType(VG_PAINT_TYPE_COLOR),
	m_paintColor(0,0,0,1,Color::sRGBA_PRE),
	m_inputPaintColor(0,0,0,1,Color::sRGBA),
	m_colorRampSpreadMode(VG_COLOR_RAMP_SPREAD_PAD),
	m_colorRampStops(),
	m_inputColorRampStops(),
	m_colorRampPremultiplied(VG_TRUE),
	m_linearGradientPoint0(0,0),
	m_linearGradientPoint1(1,0),
	m_radialGradientCenter(0,0),
	m_radialGradientFocalPoint(0,0),
	m_radialGradientRadius(1.0f),
	m_patternTilingMode(VG_TILE_FILL),
	m_pattern(NULL),
	m_referenceCount(0)
{
	Paint::GradientStop gs;
	gs.offset = 0.0f;
	gs.color.set(0,0,0,1,Color::sRGBA);
	m_colorRampStops.push_back(gs);	//throws bad_alloc
	gs.offset = 1.0f;
	gs.color.set(1,1,1,1,Color::sRGBA);
	m_colorRampStops.push_back(gs);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Paint destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Paint::~Paint()
{
	RI_ASSERT(m_referenceCount == 0);
	if(m_pattern)
	{
		m_pattern->removeInUse();
		if(!m_pattern->removeReference())
			RI_DELETE(m_pattern);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	PixelPipe constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

PixelPipe::PixelPipe() :
	m_renderingSurface(NULL),
	m_mask(NULL),
	m_image(NULL),
	m_paint(NULL),
	m_defaultPaint(),
	m_blendMode(kCGBlendModeNormal),
	m_imageMode(VG_DRAW_IMAGE_NORMAL),
	m_imageQuality(kCGInterpolationLow),
	m_tileFillColor(0,0,0,0,Color::sRGBA),
	m_surfaceToPaintMatrix(),
	m_surfaceToImageMatrix()
{}

/*-------------------------------------------------------------------*//*!
* \brief	PixelPipe destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

PixelPipe::~PixelPipe()
{
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the rendering surface.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setRenderingSurface(Image* renderingSurface)
{
	RI_ASSERT(renderingSurface);
	m_renderingSurface = renderingSurface;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the blend mode.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setBlendMode(CGBlendMode blendMode)
{
	RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
	m_blendMode = blendMode;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the mask image. NULL disables masking.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setMask(const Image* mask)
{
	m_mask = mask;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the image to be drawn. NULL disables image drawing.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setImage(Image* image, VGImageMode imageMode)
{
	RI_ASSERT(imageMode == VG_DRAW_IMAGE_NORMAL || imageMode == VG_DRAW_IMAGE_MULTIPLY || imageMode == VG_DRAW_IMAGE_STENCIL);
	m_image = image;
	m_imageMode = imageMode;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the surface-to-paint matrix.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setSurfaceToPaintMatrix(const Matrix3x3& surfaceToPaintMatrix)
{
	m_surfaceToPaintMatrix = surfaceToPaintMatrix;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the surface-to-image matrix.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setSurfaceToImageMatrix(const Matrix3x3& surfaceToImageMatrix)
{
	m_surfaceToImageMatrix = surfaceToImageMatrix;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets image quality.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setImageQuality(CGInterpolationQuality imageQuality)
{
	RI_ASSERT(imageQuality == kCGInterpolationNone || imageQuality == kCGInterpolationLow || imageQuality == kCGInterpolationHigh);
	m_imageQuality = imageQuality;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets fill color for VG_TILE_FILL tiling mode (pattern only).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setTileFillColor(const Color& c)
{
	m_tileFillColor = c;
	m_tileFillColor.clamp();
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets paint.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::setPaint(const Paint* paint)
{
	m_paint = paint;
	if(!m_paint)
		m_paint = &m_defaultPaint;
	if(m_paint->m_pattern)
		m_tileFillColor.convert(m_paint->m_pattern->getDescriptor().internalFormat);
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the linear gradient function at (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::linearGradient(RIfloat& g, RIfloat& rho, RIfloat x, RIfloat y) const
{
	RI_ASSERT(m_paint);
	Vector2 u = m_paint->m_linearGradientPoint1 - m_paint->m_linearGradientPoint0;
	RIfloat usq = dot(u,u);
	if( usq <= 0.0f )
	{	//points are equal, gradient is always 1.0f
		g = 1.0f;
		rho = 0.0f;
		return;
	}
	RIfloat oou = 1.0f / usq;

	Vector2 p(x, y);
	p = affineTransform(m_surfaceToPaintMatrix, p);
	p -= m_paint->m_linearGradientPoint0;
	RI_ASSERT(usq >= 0.0f);
	g = dot(p, u) * oou;
	RIfloat dgdx = oou * u.x * m_surfaceToPaintMatrix[0][0] + oou * u.y * m_surfaceToPaintMatrix[1][0];
	RIfloat dgdy = oou * u.x * m_surfaceToPaintMatrix[0][1] + oou * u.y * m_surfaceToPaintMatrix[1][1];
	rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	RI_ASSERT(rho >= 0.0f);
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the radial gradient function at (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void PixelPipe::radialGradient(RIfloat &g, RIfloat &rho, RIfloat x, RIfloat y) const
{
	RI_ASSERT(m_paint);
	if( m_paint->m_radialGradientRadius <= 0.0f )
	{
		g = 1.0f;
		rho = 0.0f;
		return;
	}

	RIfloat r = m_paint->m_radialGradientRadius;
	Vector2 c = m_paint->m_radialGradientCenter;
	Vector2 f = m_paint->m_radialGradientFocalPoint;
	Vector2 gx(m_surfaceToPaintMatrix[0][0], m_surfaceToPaintMatrix[1][0]);
	Vector2 gy(m_surfaceToPaintMatrix[0][1], m_surfaceToPaintMatrix[1][1]);

	Vector2 fp = f - c;

	//clamp the focal point inside the gradient circle
	RIfloat fpLen = fp.length();
	if( fpLen > 0.999f * r )
		fp *= 0.999f * r / fpLen;

	RIfloat D = -1.0f / (dot(fp,fp) - r*r);
	Vector2 p(x, y);
	p = affineTransform(m_surfaceToPaintMatrix, p) - c;
	Vector2 d = p - fp;
	RIfloat s = (RIfloat)sqrt(r*r*dot(d,d) - RI_SQR(p.x*fp.y - p.y*fp.x));
	g = (dot(fp,d) + s) * D;
	if(RI_ISNAN(g))
		g = 0.0f;
	RIfloat dgdx = D*dot(fp,gx) + (r*r*dot(d,gx) - (gx.x*fp.y - gx.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	RIfloat dgdy = D*dot(fp,gy) + (r*r*dot(d,gy) - (gy.x*fp.y - gy.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	if(RI_ISNAN(rho))
		rho = 0.0f;
	RI_ASSERT(rho >= 0.0f);
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns the average color within an offset range in the color ramp.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static Color readStopColor(const Array<Paint::GradientStop>& colorRampStops, int i, VGboolean colorRampPremultiplied)
{
	RI_ASSERT(i >= 0 && i < colorRampStops.size());
	Color c = colorRampStops[i].color;
	RI_ASSERT(c.getInternalFormat() == Color::sRGBA);
	if(colorRampPremultiplied)
		c.premultiply();
	return c;
}

Color PixelPipe::integrateColorRamp(RIfloat gmin, RIfloat gmax) const
{
	RI_ASSERT(gmin <= gmax);
	RI_ASSERT(gmin >= 0.0f && gmin <= 1.0f);
	RI_ASSERT(gmax >= 0.0f && gmax <= 1.0f);
	RI_ASSERT(m_paint->m_colorRampStops.size() >= 2);	//there are at least two stops

	Color c(0,0,0,0,m_paint->m_colorRampPremultiplied ? Color::sRGBA_PRE : Color::sRGBA);
	if(gmin == 1.0f || gmax == 0.0f)
		return c;

	int i=0;
	for(;i<m_paint->m_colorRampStops.size()-1;i++)
	{
		if(gmin >= m_paint->m_colorRampStops[i].offset && gmin < m_paint->m_colorRampStops[i+1].offset)
		{
			RIfloat s = m_paint->m_colorRampStops[i].offset;
			RIfloat e = m_paint->m_colorRampStops[i+1].offset;
			RI_ASSERT(s < e);
			RIfloat g = (gmin - s) / (e - s);

			Color sc = readStopColor(m_paint->m_colorRampStops, i, m_paint->m_colorRampPremultiplied);
			Color ec = readStopColor(m_paint->m_colorRampStops, i+1, m_paint->m_colorRampPremultiplied);
			Color rc = (1.0f-g) * sc + g * ec;

			//subtract the average color from the start of the stop to gmin
			c -= 0.5f*(gmin - s)*(sc + rc);
			break;
		}
	}

	for(;i<m_paint->m_colorRampStops.size()-1;i++)
	{
		RIfloat s = m_paint->m_colorRampStops[i].offset;
		RIfloat e = m_paint->m_colorRampStops[i+1].offset;
		RI_ASSERT(s <= e);

		Color sc = readStopColor(m_paint->m_colorRampStops, i, m_paint->m_colorRampPremultiplied);
		Color ec = readStopColor(m_paint->m_colorRampStops, i+1, m_paint->m_colorRampPremultiplied);

		//average of the stop
		c += 0.5f*(e-s)*(sc + ec);

		if(gmax >= m_paint->m_colorRampStops[i].offset && gmax < m_paint->m_colorRampStops[i+1].offset)
		{
			RIfloat g = (gmax - s) / (e - s);
			Color rc = (1.0f-g) * sc + g * ec;

			//subtract the average color from gmax to the end of the stop
			c -= 0.5f*(e - gmax)*(rc + ec);
			break;
		}
	}
	return c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Maps a gradient function value to a color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Color PixelPipe::colorRamp(RIfloat gradient, RIfloat rho) const
{
	RI_ASSERT(m_paint);
	RI_ASSERT(rho >= 0.0f);

	Color c(0,0,0,0,m_paint->m_colorRampPremultiplied ? Color::sRGBA_PRE : Color::sRGBA);
	Color avg;

	if(rho == 0.0f)
	{	//filter size is zero or gradient is degenerate
		switch(m_paint->m_colorRampSpreadMode)
		{
		case VG_COLOR_RAMP_SPREAD_PAD:
			gradient = RI_CLAMP(gradient, 0.0f, 1.0f);
			break;
		case VG_COLOR_RAMP_SPREAD_REFLECT:
		{
			RIfloat g = RI_MOD(gradient, 2.0f);
			gradient = (g < 1.0f) ? g : 2.0f - g;
			break;
		}
		default:
			RI_ASSERT(m_paint->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
			gradient = gradient - (RIfloat)floor(gradient);
			break;
		}
		RI_ASSERT(gradient >= 0.0f && gradient <= 1.0f);

		for(int i=0;i<m_paint->m_colorRampStops.size()-1;i++)
		{
			if(gradient >= m_paint->m_colorRampStops[i].offset && gradient < m_paint->m_colorRampStops[i+1].offset)
			{
				RIfloat s = m_paint->m_colorRampStops[i].offset;
				RIfloat e = m_paint->m_colorRampStops[i+1].offset;
				RI_ASSERT(s < e);
				RIfloat g = RI_CLAMP((gradient - s) / (e - s), 0.0f, 1.0f);	//clamp needed due to numerical inaccuracies

				Color sc = readStopColor(m_paint->m_colorRampStops, i, m_paint->m_colorRampPremultiplied);
				Color ec = readStopColor(m_paint->m_colorRampStops, i+1, m_paint->m_colorRampPremultiplied);
				return (1.0f-g) * sc + g * ec;	//return interpolated value
			}
		}
		return readStopColor(m_paint->m_colorRampStops, m_paint->m_colorRampStops.size()-1, m_paint->m_colorRampPremultiplied);
	}

	RIfloat gmin = gradient - rho*0.5f;			//filter starting from the gradient point (if starts earlier, radial gradient center will be an average of the first and the last stop, which doesn't look good)
	RIfloat gmax = gradient + rho*0.5f;

	switch(m_paint->m_colorRampSpreadMode)
	{
	case VG_COLOR_RAMP_SPREAD_PAD:
	{
		if(gmin < 0.0f)
			c += (RI_MIN(gmax, 0.0f) - gmin) * readStopColor(m_paint->m_colorRampStops, 0, m_paint->m_colorRampPremultiplied);
		if(gmax > 1.0f)
			c += (gmax - RI_MAX(gmin, 1.0f)) * readStopColor(m_paint->m_colorRampStops, m_paint->m_colorRampStops.size()-1, m_paint->m_colorRampPremultiplied);
		gmin = RI_CLAMP(gmin, 0.0f, 1.0f);
		gmax = RI_CLAMP(gmax, 0.0f, 1.0f);
		c += integrateColorRamp(gmin, gmax);
		c *= 1.0f/rho;
		c.clamp();	//clamp needed due to numerical inaccuracies
		return c;
	}

	case VG_COLOR_RAMP_SPREAD_REFLECT:
	{
		avg = integrateColorRamp(0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = (gmaxi + 1.0f - gmini) * avg;		//full ramps

		//subtract beginning
		if(((int)gmini) & 1)
			c -= integrateColorRamp(RI_CLAMP(1.0f - (gmin - gmini), 0.0f, 1.0f), 1.0f);
		else
			c -= integrateColorRamp(0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f));

		//subtract end
		if(((int)gmaxi) & 1)
			c -= integrateColorRamp(0.0f, RI_CLAMP(1.0f - (gmax - gmaxi), 0.0f, 1.0f));
		else
			c -= integrateColorRamp(RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f);
		break;
	}

	default:
	{
		RI_ASSERT(m_paint->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
		avg = integrateColorRamp(0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = (gmaxi + 1.0f - gmini) * avg;		//full ramps
		c -= integrateColorRamp(0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f));	//subtract beginning
		c -= integrateColorRamp(RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f);	//subtract end
		break;
	}
	}

	//divide color by the length of the range
	c *= 1.0f / rho;
	c.clamp();	//clamp needed due to numerical inaccuracies

	//hide aliasing by fading to the average color
	const RIfloat fadeStart = 0.5f;
	const RIfloat fadeMultiplier = 2.0f;	//the larger, the earlier fade to average is done

	if(rho < fadeStart)
		return c;

	RIfloat ratio = RI_MIN((rho - fadeStart) * fadeMultiplier, 1.0f);
	return ratio * avg + (1.0f - ratio) * c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies paint, image drawing, masking and blending at pixel (x,y).
* \param	
* \return	
* \note		premultiplied blending formulas
			//src
			a = asrc
			r = rsrc
			//src over
			a = asrc + adst * (1-asrc)
			r = rsrc + rdst * (1-asrc)
			//dst over
			a = asrc * (1-adst) + adst
			r = rsrc * (1-adst) + adst
			//src in
			a = asrc * adst
			r = rsrc * adst
			//dst in
			a = adst * asrc
			r = rdst * asrc
			//multiply
			a = asrc + adst * (1-asrc)
			r = rsrc * (1-adst) + rdst * (1-asrc) + rsrc * rdst
			//screen
			a = asrc + adst * (1-asrc)
			r = rsrc + rdst - rsrc * rdst
			//darken
			a = asrc + adst * (1-asrc)
			r = MIN(rsrc + rdst * (1-asrc), rdst + rsrc * (1-adst))
			//lighten
			a = asrc + adst * (1-asrc)
			r = MAX(rsrc + rdst * (1-asrc), rdst + rsrc * (1-adst))
			//additive
			a = MIN(asrc+adst,1)
			r = rsrc + rdst
*//*-------------------------------------------------------------------*/

void PixelPipe::pixelPipe(int x, int y, RIfloat coverage) const
{
	RI_ASSERT(m_renderingSurface);

	//apply masking
	RIfloat cov = coverage;
	if(m_mask)
		cov *= m_mask->readMaskPixel(x, y);
	if(cov == 0.0f)
		return;

	//evaluate paint
	Color s;
	RI_ASSERT(m_paint);
	switch(m_paint->m_paintType)
	{
	case VG_PAINT_TYPE_COLOR:
		s = m_paint->m_paintColor;
		break;

	case VG_PAINT_TYPE_LINEAR_GRADIENT:
	{
		RIfloat g, rho;
		linearGradient(g, rho, x+0.5f, y+0.5f);
		s = colorRamp(g, rho);
		RI_ASSERT((s.getInternalFormat() == Color::sRGBA && !m_paint->m_colorRampPremultiplied) || (s.getInternalFormat() == Color::sRGBA_PRE && m_paint->m_colorRampPremultiplied));
		s.premultiply();
		break;
	}

	case VG_PAINT_TYPE_RADIAL_GRADIENT:
	{
		RIfloat g, rho;
		radialGradient(g, rho, x+0.5f, y+0.5f);
		s = colorRamp(g, rho);
		RI_ASSERT((s.getInternalFormat() == Color::sRGBA && !m_paint->m_colorRampPremultiplied) || (s.getInternalFormat() == Color::sRGBA_PRE && m_paint->m_colorRampPremultiplied));
		s.premultiply();
		break;
	}

	default:
		RI_ASSERT(m_paint->m_paintType == VG_PAINT_TYPE_PATTERN);
		if(m_paint->m_pattern)
			s = m_paint->m_pattern->resample(x+0.5f, y+0.5f, m_surfaceToPaintMatrix, m_imageQuality, m_paint->m_patternTilingMode, m_tileFillColor);
		else
			s = m_paint->m_paintColor;
		break;
	}

	//read destination color
	Color d = m_renderingSurface->readPixel(x, y);
	d.premultiply();
	RI_ASSERT(d.getInternalFormat() == Color::lRGBA_PRE || d.getInternalFormat() == Color::sRGBA_PRE || d.getInternalFormat() == Color::lLA_PRE || d.getInternalFormat() == Color::sLA_PRE);

	//apply image (vgDrawImage only)
	//1. paint: convert paint to dst space
	//2. image: convert image to dst space
	//3. paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst
	//4. paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply
	RIfloat ar = s.a, ag = s.a, ab = s.a;
	if(m_image)
	{
		Color im = m_image->resample(x+0.5f, y+0.5f, m_surfaceToImageMatrix, m_imageQuality, VG_TILE_PAD, Color(0,0,0,0,m_image->getDescriptor().internalFormat));
		RI_ASSERT((s.getInternalFormat() & Color::LUMINANCE && s.r == s.g && s.r == s.b) || !(s.getInternalFormat() & Color::LUMINANCE));	//if luminance, r=g=b
		RI_ASSERT((im.getInternalFormat() & Color::LUMINANCE && im.r == im.g && im.r == im.b) || !(im.getInternalFormat() & Color::LUMINANCE));	//if luminance, r=g=b

		switch(m_imageMode)
		{
		case VG_DRAW_IMAGE_NORMAL:
			s = im;
			ar = im.a;
			ag = im.a;
			ab = im.a;
			s.convert(d.getInternalFormat());	//convert image color to destination color space
			break;
		case VG_DRAW_IMAGE_MULTIPLY:
			//the result will be in image color space. If the number of channels in image and paint
			// colors differ, convert to the number of channels in the image color.
			//paint == RGB && image == RGB: RGB*RGB
			//paint == RGB && image == L  : (0.2126 R + 0.7152 G + 0.0722 B)*L
			//paint == L   && image == RGB: LLL*RGB
			//paint == L   && image == L  : L*L
			if(!(s.getInternalFormat() & Color::LUMINANCE) && im.getInternalFormat() & Color::LUMINANCE)
			{
				s.r = s.g = s.b = RI_MIN(0.2126f*s.r + 0.7152f*s.g + 0.0722f*s.b, s.a);
			}
 			RI_ASSERT(m_surfaceToPaintMatrix.isAffine());
			ar *= im.a;
			ag *= im.a;
			ab *= im.a;
			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;
			s.convert(d.getInternalFormat());	//convert resulting color to destination color space
			break;
		default:
			//the result will be in paint color space.
			//dst == RGB && image == RGB: RGB*RGB
			//dst == RGB && image == L  : RGB*LLL
			//dst == L   && image == RGB: L*(0.2126 R + 0.7152 G + 0.0722 B)
			//dst == L   && image == L  : L*L
			RI_ASSERT(m_imageMode == VG_DRAW_IMAGE_STENCIL);
			if(d.getInternalFormat() & Color::LUMINANCE && !(im.getInternalFormat() & Color::LUMINANCE))
			{
				im.r = im.g = im.b = RI_MIN(0.2126f*im.r + 0.7152f*im.g + 0.0722f*im.b, im.a);
			}
			RI_ASSERT(m_surfaceToPaintMatrix.isAffine());
			//s and im are both in premultiplied format. Each image channel acts as an alpha channel.
			s.convert(d.getInternalFormat());	//convert paint color to destination space already here, since convert cannot deal with per channel alphas used in this mode.
			s.r *= im.r;
			s.g *= im.g;
			s.b *= im.b;
			s.a *= im.a;
			ar *= im.r;
			ag *= im.g;
			ab *= im.b;
			//in nonpremultiplied form the result is
			// s.rgb = paint.a * paint.rgb * image.a * image.rgb
			// s.a = paint.a * image.a
			// argb = paint.a * image.a * image.rgb
			break;
		}
	}
	else s.convert(d.getInternalFormat());	//convert paint color to destination color space

	RI_ASSERT(s.getInternalFormat() == Color::lRGBA_PRE || s.getInternalFormat() == Color::sRGBA_PRE || s.getInternalFormat() == Color::lLA_PRE || s.getInternalFormat() == Color::sLA_PRE);

	//apply blending in the premultiplied format
	Color r(0,0,0,0,d.getInternalFormat());
	RI_ASSERT(s.a >= 0.0f && s.a <= 1.0f);
	RI_ASSERT(s.r >= 0.0f && s.r <= s.a && s.r <= ar);
	RI_ASSERT(s.g >= 0.0f && s.g <= s.a && s.g <= ag);
	RI_ASSERT(s.b >= 0.0f && s.b <= s.a && s.b <= ab);
	RI_ASSERT(d.a >= 0.0f && d.a <= 1.0f);
	RI_ASSERT(d.r >= 0.0f && d.r <= d.a);
	RI_ASSERT(d.g >= 0.0f && d.g <= d.a);
	RI_ASSERT(d.b >= 0.0f && d.b <= d.a);
	switch(m_blendMode)
	{
	case kCGBlendModeNormal:
		r.r = s.r + d.r * (1.0f - ar);
		r.g = s.g + d.g * (1.0f - ag);
		r.b = s.b + d.b * (1.0f - ab);
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeMultiply:
		r.r = s.r * (1.0f - d.a + d.r) + d.r * (1.0f - ar);
		r.g = s.g * (1.0f - d.a + d.g) + d.g * (1.0f - ag);
		r.b = s.b * (1.0f - d.a + d.b) + d.b * (1.0f - ab);
		r.a = s.a + d.a * (1.0f - s.a);
		break;
        
	case kCGBlendModeScreen:
		r.r = s.r + d.r * (1.0f - s.r);
		r.g = s.g + d.g * (1.0f - s.g);
		r.b = s.b + d.b * (1.0f - s.b);
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeOverlay:
        r.r=(2*d.r<d.a)?(2*s.r*d.r+s.r*(1-d.a)+d.r*(1-s.a)):(s.r*d.r-2*(d.a-d.r)*(s.a-s.r)+s.r*(1-d.a)+d.r*(1-s.a));
        r.g=(2*d.g<d.a)?(2*s.g*d.g+s.g*(1-d.a)+d.g*(1-s.a)):(s.g*d.g-2*(d.a-d.g)*(s.a-s.g)+s.g*(1-d.a)+d.g*(1-s.a));
        r.b=(2*d.b<d.a)?(2*s.b*d.b+s.b*(1-d.a)+d.b*(1-s.a)):(s.b*d.b-2*(d.a-d.b)*(s.a-s.b)+s.b*(1-d.a)+d.b*(1-s.a));
        r.a=(2*d.a<d.a)?(2*s.a*d.a+s.a*(1-d.a)+d.a*(1-s.a)):(s.a*d.a-2*(d.a-d.a)*(s.a-s.a)+s.a*(1-d.a)+d.a*(1-s.a));
        break;
        
	case kCGBlendModeDarken:
		r.r = RI_MIN(s.r + d.r * (1.0f - ar), d.r + s.r * (1.0f - d.a));
		r.g = RI_MIN(s.g + d.g * (1.0f - ag), d.g + s.g * (1.0f - d.a));
		r.b = RI_MIN(s.b + d.b * (1.0f - ab), d.b + s.b * (1.0f - d.a));
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeLighten:
		r.r = RI_MAX(s.r + d.r * (1.0f - ar), d.r + s.r * (1.0f - d.a));
		r.g = RI_MAX(s.g + d.g * (1.0f - ag), d.g + s.g * (1.0f - d.a));
		r.b = RI_MAX(s.b + d.b * (1.0f - ab), d.b + s.b * (1.0f - d.a));
		//although the statement below is equivalent to r.a = s.a + d.a * (1.0f - s.a)
		//in practice there can be a very slight difference because
		//of the max operation in the blending formula that may cause color to exceed alpha.
		//Because of this, we compute the result both ways and return the maximum.
		r.a = RI_MAX(s.a + d.a * (1.0f - s.a), d.a + s.a * (1.0f - d.a));
		break;

	case kCGBlendModeColorDodge:
        r.r=(s.r==1)?1:RI_MIN(1,d.r/(1.0-s.r));
        r.g=(s.g==1)?1:RI_MIN(1,d.g/(1.0-s.g));
        r.b=(s.b==1)?1:RI_MIN(1,d.b/(1.0-s.b));
        r.a=(s.a==1)?1:RI_MIN(1,d.a/(1.0-s.a));
        break;
        
	case kCGBlendModeColorBurn:
        r.r=(s.r==0)?0:1.0-RI_MIN(1.0,(1.0-d.r)/s.r);
        r.g=(s.g==0)?0:1.0-RI_MIN(1.0,(1.0-d.g)/s.g);
        r.b=(s.b==0)?0:1.0-RI_MIN(1.0,(1.0-d.b)/s.b);
        r.a=(s.a==0)?0:1.0-RI_MIN(1.0,(1.0-d.a)/s.a);
        break;
        
	case kCGBlendModeHardLight:
        break;
        
	case kCGBlendModeSoftLight:
        break;
        
	case kCGBlendModeDifference:
        r.r=RI_ABS(d.r-s.r);
        r.g=RI_ABS(d.g-s.g);
        r.b=RI_ABS(d.b-s.b);
        r.a=RI_ABS(d.a-s.a);
        break;
        
	case kCGBlendModeExclusion:
        r.r=d.r+s.r-2.0*d.r*s.r;
        r.g=d.g+s.g-2.0*d.g*s.g;
        r.b=d.b+s.b-2.0*d.b*s.b;
        r.a=d.a+s.a-2.0*d.a*s.a;
        break;
        
	case kCGBlendModeHue:
        break;
        
	case kCGBlendModeSaturation:
        break;
        
	case kCGBlendModeColor:
        break;
        
	case kCGBlendModeLuminosity:
        break;
        
	case kCGBlendModeClear:
        r.r=0;
        r.g=0;
        r.b=0;
        r.a=0;
        break;

	case kCGBlendModeCopy:
		r = s;
		break;

	case kCGBlendModeSourceIn:
		r.r = s.r * d.a;
		r.g = s.g * d.a;
		r.b = s.b * d.a;
		r.a = s.a * d.a;
		break;

	case kCGBlendModeSourceOut:
		r.r = s.r *(1.0- d.a);
		r.g = s.g * (1.0- d.a);
		r.b = s.b * (1.0- d.a);
		r.a = s.a * (1.0- d.a);
        break;

	case kCGBlendModeSourceAtop:
		r.r = s.r*d.a+d.r*(1.0-ar);
		r.g = s.g*d.a+d.g*(1.0-ag);
		r.b = s.b*d.a+d.b*(1.0-ab);
		r.a = s.a*d.a+d.a*(1.0-s.a);
        break;

	case kCGBlendModeDestinationOver:
		r.r = s.r * (1.0f - d.a) + d.r;
		r.g = s.g * (1.0f - d.a) + d.g;
		r.b = s.b * (1.0f - d.a) + d.b;
		r.a = s.a * (1.0f - d.a) + d.a;
		break;

	case kCGBlendModeDestinationIn:
		r.r = d.r * ar;
		r.g = d.g * ag;
		r.b = d.b * ab;
		r.a = d.a * s.a;
		break;


	case kCGBlendModeDestinationOut:
		r.r = d.r *(1.0- ar);
		r.g = d.g * (1.0- ag);
		r.b = d.b * (1.0- ab);
		r.a = d.a * (1.0- s.a);
        break;

	case kCGBlendModeDestinationAtop:
        r.r=ar*(1.0-d.a)+d.r*s.a;
        r.g=ag*(1.0-d.a)+d.g*s.a;
        r.b=ab*(1.0-d.a)+d.b*s.a;
        r.a=s.a*(1.0-d.a)+d.a*s.a;
        break;

	case kCGBlendModeXOR:
        r.r=ar*(1.0-d.a)+d.r*(1.0-s.a);
        r.g=ag*(1.0-d.a)+d.g*(1.0-s.a);
        r.b=ab*(1.0-d.a)+d.b*(1.0-s.a);
        r.a=s.a*(1.0-d.a)+d.a*(1.0-s.a);
        break;

	case kCGBlendModePlusDarker:
        r.r=RI_MAX(0,(1.0-d.r)+(1-s.r));
        r.g=RI_MAX(0,(1.0-d.g)+(1-s.g));
        r.b=RI_MAX(0,(1.0-d.b)+(1-s.b));
        r.a=RI_MAX(0,(1.0-d.a)+(1-s.a));
        r.r=RI_MIN(1,r.r);
        r.g=RI_MIN(1,r.g);
        r.b=RI_MIN(1,r.b);
        r.a=RI_MIN(1,r.a);
        break;

	case kCGBlendModePlusLighter:
		r.r = RI_MIN(s.r + d.r, 1.0f);
		r.g = RI_MIN(s.g + d.g, 1.0f);
		r.b = RI_MIN(s.b + d.b, 1.0f);
		r.a = RI_MIN(s.a + d.a, 1.0f);
		break;
	}

	//apply antialiasing in linear color space
	Color::InternalFormat aaFormat = (d.getInternalFormat() & Color::LUMINANCE) ? Color::lLA_PRE : Color::lRGBA_PRE;
	r.convert(aaFormat);
	d.convert(aaFormat);
	r = r * cov + d * (1.0f - cov);

	//write result to the destination surface
	r.convert(m_renderingSurface->getDescriptor().internalFormat);
	m_renderingSurface->writePixel(x, y, r);
}

//=======================================================================
	
}	//namespace OpenVGRI
