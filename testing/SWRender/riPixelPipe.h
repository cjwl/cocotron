#ifndef __RIPIXELPIPE_H
#define __RIPIXELPIPE_H

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
 * \brief	Paint and PixelPipe classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#import <Foundation/Foundation.h>

#ifndef __RIMATH_H
#include "riMath.h"
#endif

#ifndef __RIIMAGE_H
#include "riImage.h"
#endif

//=======================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Storage and operations for VGPaint.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Paint
{
public:
	Paint();
	~Paint();
	void					addReference()							{ m_referenceCount++; }
	int						removeReference()						{ m_referenceCount--; RI_ASSERT(m_referenceCount >= 0); return m_referenceCount; }

	struct GradientStop
	{
		GradientStop() : offset(0.0f), color(0.0f, 0.0f, 0.0f, 0.0f, Color::sRGBA) {}
		RIfloat		offset;
		Color		color;
	};

	VGPaintType				m_paintType;
	Color					m_paintColor;
	Color					m_inputPaintColor;
	VGColorRampSpreadMode	m_colorRampSpreadMode;
	Array<GradientStop>		m_colorRampStops;
	Array<GradientStop>		m_inputColorRampStops;
	BOOL				m_colorRampPremultiplied;
	Vector2					m_linearGradientPoint0;
	Vector2					m_linearGradientPoint1;
	Vector2					m_radialGradientCenter;
	Vector2					m_radialGradientFocalPoint;
	RIfloat					m_radialGradientRadius;
	VGTilingMode			m_patternTilingMode;
	Image*					m_pattern;
private:
	Paint(const Paint&);						//!< Not allowed.
	const Paint& operator=(const Paint&);		//!< Not allowed.

	int						m_referenceCount;
};

/*-------------------------------------------------------------------*//*!
* \brief	Encapsulates all information needed for painting a pixel.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/
	
class PixelPipe
{
public:
	PixelPipe();	//throws bad_alloc
	~PixelPipe();

	void	pixelPipe(int x, int y, RIfloat coverage) const;	//rasterizer calls this function for each pixel

	void	setRenderingSurface(Image* renderingSurface);
	void	setBlendMode(CGBlendMode blendMode);
	void	setMask(const Image* mask);	//mask = NULL disables masking
	void	setImage(Image* image, VGImageMode imageMode);	//image = NULL disables drawImage functionality
	void	setSurfaceToPaintMatrix(const Matrix3x3& surfaceToPaintMatrix);
	void	setSurfaceToImageMatrix(const Matrix3x3& surfaceToImageMatrix);
	void	setImageQuality(CGInterpolationQuality imageQuality);
	void	setTileFillColor(const Color& c);
	void	setPaint(const Paint* paint);

private:
	void	linearGradient(RIfloat& g, RIfloat& rho, RIfloat x, RIfloat y) const;
	void	radialGradient(RIfloat& g, RIfloat& rho, RIfloat x, RIfloat y) const;
	Color	integrateColorRamp(RIfloat gmin, RIfloat gmax) const;
	Color	colorRamp(RIfloat gradient, RIfloat rho) const;

	PixelPipe(const PixelPipe&);						//!< Not allowed.
	const PixelPipe& operator=(const PixelPipe&);		//!< Not allowed.

	Image*					m_renderingSurface;
	const Image*			m_mask;
	Image*					m_image;
	const Paint*			m_paint;
	Paint					m_defaultPaint;
	CGBlendMode				m_blendMode;
	VGImageMode				m_imageMode;
	CGInterpolationQuality			m_imageQuality;
	Color					m_tileFillColor;
	Matrix3x3				m_surfaceToPaintMatrix;
	Matrix3x3				m_surfaceToImageMatrix;
};

//=======================================================================

}	//namespace OpenVGRI

//=======================================================================

#endif /* __RIPIXELPIPE_H */
