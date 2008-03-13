#ifndef __RIIMAGE_H
#define __RIIMAGE_H

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
 * \brief	Color and Image classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#ifndef OPENVG_H
#include "openvg.h"
#endif

#ifndef __RIMATH_H
#include "riMath.h"
#endif

#ifndef __RIARRAY_H
#include "riArray.h"
#endif

#import <ApplicationServices/ApplicationServices.h>

//==============================================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	A class representing rectangles.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Rectangle
{
public:
	Rectangle() : x(0), y(0), width(0), height(0) {}
	Rectangle(int rx, int ry, int rw, int rh) : x(rx), y(ry), width(rw), height(rh) {}
	void		intersect(const Rectangle& r)
	{
		if(width >= 0 && r.width >= 0 && height >= 0 && r.height >= 0)
		{
			int x1 = RI_INT_MIN(RI_INT_ADDSATURATE(x, width), RI_INT_ADDSATURATE(r.x, r.width));
			x = RI_INT_MAX(x, r.x);
			width = RI_INT_MAX(x1 - x, 0);

			int y1 = RI_INT_MIN(RI_INT_ADDSATURATE(y, height), RI_INT_ADDSATURATE(r.y, r.height));
			y = RI_INT_MAX(y, r.y);
			height = RI_INT_MAX(y1 - y, 0);
		}
		else
		{
			x = 0;
			y = 0;
			width = 0;
			height = 0;
		}
	}

	int			x;
	int			y;
	int			width;
	int			height;
};

/*-------------------------------------------------------------------*//*!
* \brief	A class representing color for processing and converting it
*			to and from various surface formats.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Color
{
public:
	enum InternalFormat
	{
		lRGBA			= 0,
		sRGBA			= 1,
		lRGBA_PRE		= 2,
		sRGBA_PRE		= 3,
		lLA				= 4,
		sLA				= 5,
		lLA_PRE			= 6,
		sLA_PRE			= 7
	};
	enum FormatBits
	{
		NONLINEAR		= (1<<0),
		PREMULTIPLIED	= (1<<1),
		LUMINANCE		= (1<<2)
	};
	struct Descriptor
	{
		int				redBits;
		int				redShift;
		int				greenBits;
		int				greenShift;
		int				blueBits;
		int				blueShift;
		int				alphaBits;
		int				alphaShift;
		int				luminanceBits;
		int				luminanceShift;
		VGImageFormat	format;
		InternalFormat	internalFormat;
		int				bitsPerPixel;
	};

	RI_INLINE Color() : r(0.0f), g(0.0f), b(0.0f), a(0.0f), m_format(lRGBA)													{}
	RI_INLINE Color(RIfloat cl, RIfloat ca, InternalFormat cs) : r(cl), g(cl), b(cl), a(ca), m_format(cs)							{ RI_ASSERT(cs == lLA || cs == sLA || cs == lLA_PRE || cs == sLA_PRE); }
	RI_INLINE Color(RIfloat cr, RIfloat cg, RIfloat cb, RIfloat ca, InternalFormat cs) : r(cr), g(cg), b(cb), a(ca), m_format(cs)	{ RI_ASSERT(cs == lRGBA || cs == sRGBA || cs == lRGBA_PRE || cs == sRGBA_PRE || cs == lLA || cs == sLA || cs == lLA_PRE || cs == sLA_PRE); }
	RI_INLINE Color(const Color& c) : r(c.r), g(c.g), b(c.b), a(c.a), m_format(c.m_format)									{}
	RI_INLINE Color& operator=(const Color&c)										{ r = c.r; g = c.g; b = c.b; a = c.a; m_format = c.m_format; return *this; }
	RI_INLINE void operator*=(RIfloat f)											{ r *= f; g *= f; b *= f; a*= f; }
	RI_INLINE void operator+=(const Color& c1)										{ RI_ASSERT(m_format == c1.getInternalFormat()); r += c1.r; g += c1.g; b += c1.b; a += c1.a; }
	RI_INLINE void operator-=(const Color& c1)										{ RI_ASSERT(m_format == c1.getInternalFormat()); r -= c1.r; g -= c1.g; b -= c1.b; a -= c1.a; }

	void						set(RIfloat cl, RIfloat ca, InternalFormat cs)							{ RI_ASSERT(cs == lLA || cs == sLA || cs == lLA_PRE || cs == sLA_PRE); r = cl; g = cl; b = cl; a = ca; m_format = cs; }
	void						set(RIfloat cr, RIfloat cg, RIfloat cb, RIfloat ca, InternalFormat cs)	{ RI_ASSERT(cs == lRGBA || cs == sRGBA || cs == lRGBA_PRE || cs == sRGBA_PRE); r = cr; g = cg; b = cb; a = ca; m_format = cs; }
	void						unpack(unsigned int inputData, const Descriptor& inputDesc);
	unsigned int				pack(const Descriptor& outputDesc) const;
	RI_INLINE InternalFormat	getInternalFormat() const							{ return m_format; }

	//clamps nonpremultiplied colors and alpha to [0,1] range, and premultiplied alpha to [0,1], colors to [0,a]
	void						clamp()												{ a = RI_CLAMP(a,0.0f,1.0f); RIfloat u = (m_format & PREMULTIPLIED) ? a : (RIfloat)1.0f; r = RI_CLAMP(r,0.0f,u); g = RI_CLAMP(g,0.0f,u); b = RI_CLAMP(b,0.0f,u); }
	void						convert(InternalFormat outputFormat);
	void						premultiply()										{ if(!(m_format & PREMULTIPLIED)) { r *= a; g *= a; b *= a; m_format = (InternalFormat)(m_format | PREMULTIPLIED); } }
	void						unpremultiply()										{ if(m_format & PREMULTIPLIED) { RIfloat ooa = (a != 0.0f) ? 1.0f/a : (RIfloat)0.0f; r *= ooa; g *= ooa; b *= ooa; m_format = (InternalFormat)(m_format & ~PREMULTIPLIED); } }

	static Descriptor			formatToDescriptor(VGImageFormat format);
	static bool					isValidDescriptor(const Descriptor& desc);

	RIfloat		r;
	RIfloat		g;
	RIfloat		b;
	RIfloat		a;
private:
	InternalFormat	m_format;
};

RI_INLINE Color operator*(const Color& c, RIfloat f)			{ return Color(c.r*f, c.g*f, c.b*f, c.a*f, c.getInternalFormat()); }
RI_INLINE Color operator*(RIfloat f, const Color& c)			{ return Color(c.r*f, c.g*f, c.b*f, c.a*f, c.getInternalFormat()); }
RI_INLINE Color operator+(const Color& c0, const Color& c1)		{ RI_ASSERT(c0.getInternalFormat() == c1.getInternalFormat()); return Color(c0.r+c1.r, c0.g+c1.g, c0.b+c1.b, c0.a+c1.a, c0.getInternalFormat()); }
RI_INLINE Color operator-(const Color& c0, const Color& c1)		{ RI_ASSERT(c0.getInternalFormat() == c1.getInternalFormat()); return Color(c0.r-c1.r, c0.g-c1.g, c0.b-c1.b, c0.a-c1.a, c0.getInternalFormat()); }

//==============================================================================================

/*-------------------------------------------------------------------*//*!
* \brief	Storage and operations for VGImage.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Image
{
public:
	Image(const Color::Descriptor& desc, int width, int height, VGbitfield allowedQuality);	//throws bad_alloc
	//use data from a memory buffer. NOTE: data is not copied, so it is user's responsibility to make sure the data remains valid while the Image is in use.
	Image(const Color::Descriptor& desc, int width, int height, int stride, RIuint8* data);	//throws bad_alloc
	//child image constructor
	Image(Image* parent, int x, int y, int width, int height);	//throws bad_alloc
	~Image();

	const Color::Descriptor&	getDescriptor() const		{ return m_desc; }
	int					getWidth() const					{ return m_width; }
	int					getHeight() const					{ return m_height; }
	int					getStride() const					{ return m_stride; }
	Image*				getParent() const					{ return m_parent; }
	VGbitfield			getAllowedQuality() const			{ return m_allowedQuality; }
	void				addInUse()							{ m_inUse++; }
	void				removeInUse()						{ RI_ASSERT(m_inUse > 0); m_inUse--; }
	int					isInUse() const						{ return m_inUse; }
	RIuint8*			getData() const						{ return m_data; }
	void				addReference()						{ m_referenceCount++; }
	int					removeReference()					{ m_referenceCount--; RI_ASSERT(m_referenceCount >= 0); return m_referenceCount; }
	bool				overlaps(const Image* src) const;

	void				resize(int newWidth, int newHeight, const Color& newPixelColor);	//throws bad_alloc
	void				clear(const Color& clearColor, int x, int y, int w, int h);
	void				blit(const Image& src, int sx, int sy, int dx, int dy, int w, int h, bool dither);	//throws bad_alloc
	void				mask(const Image* src, VGMaskOperation operation, int x, int y, int w, int h);

	Color				readPixel(int x, int y) const;
	void				writePixel(int x, int y, const Color& c);
	void				writeFilteredPixel(int x, int y, const Color& c, VGbitfield channelMask);

	RIfloat				readMaskPixel(int x, int y) const;		//can read any image format
	void				writeMaskPixel(int x, int y, RIfloat m);	//can write only to VG_A_8

	Color				resample(RIfloat x, RIfloat y, const Matrix3x3& surfaceToImage, CGInterpolationQuality quality, VGTilingMode tilingMode, const Color& tileFillColor);	//throws bad_alloc
	void				makeMipMaps();	//throws bad_alloc

	void				colorMatrix(const Image& src, const RIfloat* matrix, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				convolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				separableConvolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				gaussianBlur(const Image& src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				lookup(const Image& src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				lookupSingle(const Image& src, const RIuint32 * lookupTable, VGImageChannel sourceChannel, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
private:
	Image(const Image&);					//!< Not allowed.
	void operator=(const Image&);			//!< Not allowed.

	struct ScissorEdge
	{
		ScissorEdge() : x(0), miny(0), maxy(0), direction(0) {}
		int			x;
		int			miny;
		int			maxy;
		int			direction;		//1 start, -1 end
	};

	Color				readTexel(int u, int v, int level, VGTilingMode tilingMode, const Color& tileFillColor) const;

	Color::Descriptor	m_desc;
	int					m_width;
	int					m_height;
	VGbitfield			m_allowedQuality;
	int					m_inUse;
	int					m_stride;
	RIuint8*			m_data;
	int					m_bitOffset;	//VG_lBW_1 only
	int					m_referenceCount;
	bool				m_ownsData;
	bool				m_hasChildren;
	Image*				m_parent;
	int					m_parentOffsetX;
	int					m_parentOffsetY;

	bool				m_mipmapsValid;
	Array<Image*>		m_mipmaps;
};

//==============================================================================================

}	//namespace OpenVGRI

//==============================================================================================

#endif /* __RIIMAGE_H */
