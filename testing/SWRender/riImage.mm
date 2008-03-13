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
 * \brief	Implementation of Color and Image functions.
 * \note	
 *//*-------------------------------------------------------------------*/

#include "riImage.h"
#include "riRasterizer.h"

//==============================================================================================

/* TODO Khronos Bugzilla bugs 1094&1095

1094:
2. I would expect B to be the correct behaviour. In theory, an implementation
using the most na•ve implementation, would keep the deleted ancestor around as
a ghost, with the child images still using its original storage. This would
mean that no images that have, or used to have, a common ancestor, can be used
as render targets until it is the only remaining sibling. Even if child images
did not intersect, and you could use them as a valid render target on a given
platform, it cannot be guaranteed to be the case for every VG implementation.

3. "The image may once again be used as a rendering target when all other
images that share storage with it have been destroyed", so in a similar vein, i
would suggest the image can be attached to a pbuffer when it is the only
remaining child.

1095:
This bug is related to spec clarification in bug: 1094

The response to this issue on the mailing list seemed to indicate that both of
these issues are bugs in the RI -- see bug 1094.

3. Can a child image A be bound to a pbuffer after its parent image P has been
deleted (and it has no other siblings)?  The RI does not allow this.  Is this
the expected behavior?
*/

namespace OpenVGRI
{

bool isValidImageFormat(int f)
{
	if(f < VG_sRGBX_8888 || f > VG_lABGR_8888_PRE)
		return false;
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from numBits into a shifted mask
* \param	
* \return	
* \note
*//*-------------------------------------------------------------------*/
	
static unsigned int bitsToMask(unsigned int bits, unsigned int shift)
{
	return ((1<<bits)-1) << shift;
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from color (RIfloat) to an int with 1.0f mapped to the
*			given maximum with round-to-nearest semantics.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/
	
static unsigned int colorToInt(RIfloat c, int maxc)
{
	return RI_INT_MIN(RI_INT_MAX((int)floor(c * (RIfloat)maxc + 0.5f), 0), maxc);
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from int to color (RIfloat) with the given maximum
*			mapped to 1.0f.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static RI_INLINE RIfloat intToColor(unsigned int i, unsigned int maxi)
{
	return (RIfloat)(i & maxi) / (RIfloat)maxi;
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from packed integer in a given format to a Color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Color::unpack(unsigned int inputData, const Color::Descriptor& inputDesc)
{
	int rb = inputDesc.redBits;
	int gb = inputDesc.greenBits;
	int bb = inputDesc.blueBits;
	int ab = inputDesc.alphaBits;
	int lb = inputDesc.luminanceBits;
	int rs = inputDesc.redShift;
	int gs = inputDesc.greenShift;
	int bs = inputDesc.blueShift;
	int as = inputDesc.alphaShift;
	int ls = inputDesc.luminanceShift;

	m_format = inputDesc.internalFormat;
	if(lb)
	{	//luminance
		r = g = b = intToColor(inputData >> ls, (1<<lb)-1);
		a = 1.0f;
	}
	else
	{	//rgba
		r = rb ? intToColor(inputData >> rs, (1<<rb)-1) : (RIfloat)1.0f;
		g = gb ? intToColor(inputData >> gs, (1<<gb)-1) : (RIfloat)1.0f;
		b = bb ? intToColor(inputData >> bs, (1<<bb)-1) : (RIfloat)1.0f;
		a = ab ? intToColor(inputData >> as, (1<<ab)-1) : (RIfloat)1.0f;

		if(m_format & PREMULTIPLIED)
		{	//clamp premultiplied color to alpha to enforce consistency
			r = RI_MIN(r, a);
			g = RI_MIN(g, a);
			b = RI_MIN(b, a);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from Color to a packed integer in a given format.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

unsigned int Color::pack(const Color::Descriptor& outputDesc) const
{
	RI_ASSERT(r >= 0.0f && r <= 1.0f);
	RI_ASSERT(g >= 0.0f && g <= 1.0f);
	RI_ASSERT(b >= 0.0f && b <= 1.0f);
	RI_ASSERT(a >= 0.0f && a <= 1.0f);
    #warning some of the new blending modes trigger this, what's wrong?
//	RI_ASSERT(!(m_format & PREMULTIPLIED) || (r <= a && g <= a && b <= a));	//premultiplied colors must have color channels less than or equal to alpha
	RI_ASSERT((m_format & LUMINANCE && r == g && r == b) || !(m_format & LUMINANCE));	//if luminance, r=g=b

	int rb = outputDesc.redBits;
	int gb = outputDesc.greenBits;
	int bb = outputDesc.blueBits;
	int ab = outputDesc.alphaBits;
	int lb = outputDesc.luminanceBits;
	int rs = outputDesc.redShift;
	int gs = outputDesc.greenShift;
	int bs = outputDesc.blueShift;
	int as = outputDesc.alphaShift;
	int ls = outputDesc.luminanceShift;

	if(lb)
	{	//luminance
		RI_ASSERT(m_format & LUMINANCE);
		return colorToInt(r, (1<<lb)-1) << ls;
	}
	else
	{	//rgb
		RI_ASSERT(!(m_format & LUMINANCE));
		unsigned int cr = rb ? colorToInt(r, (1<<rb)-1) : 0;
		unsigned int cg = gb ? colorToInt(g, (1<<gb)-1) : 0;
		unsigned int cb = bb ? colorToInt(b, (1<<bb)-1) : 0;
		unsigned int ca = ab ? colorToInt(a, (1<<ab)-1) : 0;
		return (cr << rs) | (cg << gs) | (cb << bs) | (ca << as);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from the current internal format to another.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static RIfloat gamma(RIfloat c)
{
#if 1
#warning no gamma
    return c;
#else
    
	if( c <= 0.00304f )
		c *= 12.92f;
	else
		c = 1.0556f * (RIfloat)pow(c, 1.0f/2.4f) - 0.0556f;
	return c;
#endif
}

static RIfloat invgamma(RIfloat c)
{
#if 1
#warning no gamma
    return c;
#else
	if( c <= 0.03928f )
		c /= 12.92f;
	else
		c = (RIfloat)pow((c + 0.0556f)/1.0556f, 2.4f);
	return c;
#endif
}

static RIfloat lRGBtoL(RIfloat r, RIfloat g, RIfloat b)
{
	return 0.2126f*r + 0.7152f*g + 0.0722f*b;
}

void Color::convert(InternalFormat outputFormat)
{
	RI_ASSERT(r >= 0.0f && r <= 1.0f);
	RI_ASSERT(g >= 0.0f && g <= 1.0f);
	RI_ASSERT(b >= 0.0f && b <= 1.0f);
	RI_ASSERT(a >= 0.0f && a <= 1.0f);
	RI_ASSERT((m_format & LUMINANCE && r == g && r == b) || !(m_format & LUMINANCE));	//if luminance, r=g=b

	if( m_format == outputFormat )
		return;

	if(m_format & PREMULTIPLIED)
	{	//unpremultiply
		RI_ASSERT(r <= a);
		RI_ASSERT(g <= a);
		RI_ASSERT(b <= a);
		RIfloat ooa = (a != 0.0f) ? 1.0f / a : (RIfloat)0.0f;
		r *= ooa;
		g *= ooa;
		b *= ooa;
	}

	//From Section 3.4.2 of OpenVG 1.0.1 spec
	//1: sRGB = gamma(lRGB)
	//2: lRGB = invgamma(sRGB)
	//3: lL = 0.2126 lR + 0.7152 lG + 0.0722 lB
	//4: lRGB = lL
	//5: sL = gamma(lL)
	//6: lL = invgamma(sL)
	//7: sRGB = sL

	//Source/Dest lRGB sRGB   lL   sL 
	//lRGB          Ñ    1    3    3,5 
	//sRGB          2    Ñ    2,3  2,3,5 
	//lL            4    4,1  Ñ    5 
	//sL            7,2  7    6    Ñ 

	const unsigned int shift = 3;
	unsigned int conversion = (m_format & (NONLINEAR | LUMINANCE)) | ((outputFormat & (NONLINEAR | LUMINANCE)) << shift);

	switch(conversion)
	{
	case lRGBA | (sRGBA << shift): r = gamma(r); g = gamma(g); b = gamma(b); break;							//1
	case lRGBA | (lLA << shift)  : r = g = b = lRGBtoL(r, g, b); break;										//3
	case lRGBA | (sLA << shift)  : r = g = b = gamma(lRGBtoL(r, g, b)); break;								//3,5
	case sRGBA | (lRGBA << shift): r = invgamma(r); g = invgamma(g); b = invgamma(b); break;				//2
	case sRGBA | (lLA << shift)  : r = g = b = lRGBtoL(invgamma(r), invgamma(g), invgamma(b)); break;		//2,3
	case sRGBA | (sLA << shift)  : r = g = b = gamma(lRGBtoL(invgamma(r), invgamma(g), invgamma(b))); break;//2,3,5
	case lLA   | (lRGBA << shift): break;																	//4
	case lLA   | (sRGBA << shift): r = g = b = gamma(r); break;												//4,1
	case lLA   | (sLA << shift)  : r = g = b = gamma(r); break;												//5
	case sLA   | (lRGBA << shift): r = g = b = invgamma(r); break;											//7,2
	case sLA   | (sRGBA << shift): break;																	//7
	case sLA   | (lLA << shift)  : r = g = b = invgamma(r); break;											//6
	default: RI_ASSERT((m_format & (LUMINANCE | NONLINEAR)) == (outputFormat & (LUMINANCE | NONLINEAR))); break;	//nop
	}

	if(outputFormat & PREMULTIPLIED)
	{	//premultiply
		r *= a;
		g *= a;
		b *= a;
		RI_ASSERT(r <= a);
		RI_ASSERT(g <= a);
		RI_ASSERT(b <= a);
	}
	m_format = outputFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Creates a pixel format descriptor out of VGImageFormat
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Color::Descriptor Color::formatToDescriptor(VGImageFormat format)
{
	Descriptor desc;
	memset(&desc, 0, sizeof(Descriptor));
	RI_ASSERT(isValidImageFormat(format));

	int baseFormat = (int)format & 15;
	RI_ASSERT(baseFormat >= 0 && baseFormat <= 12);
	int swizzleBits = ((int)format >> 6) & 3;

	/* base formats
	VG_sRGBX_8888                               =  0,
	VG_sRGBA_8888                               =  1,
	VG_sRGBA_8888_PRE                           =  2,
	VG_sRGB_565                                 =  3,
	VG_sRGBA_5551                               =  4,
	VG_sRGBA_4444                               =  5,
	VG_sL_8                                     =  6,
	VG_lRGBX_8888                               =  7,
	VG_lRGBA_8888                               =  8,
	VG_lRGBA_8888_PRE                           =  9,
	VG_lL_8                                     = 10,
	VG_A_8                                      = 11,
	VG_BW_1                                     = 12,
	*/

	static const int redBits[13] =       {8, 8, 8, 5, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int greenBits[13] =     {8, 8, 8, 6, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int blueBits[13] =      {8, 8, 8, 5, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int alphaBits[13] =     {0, 8, 8, 0, 1, 4, 0, 0, 8, 8, 0, 8, 0};
	static const int luminanceBits[13] = {0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 8, 0, 1};

	static const int redShifts[4*13] =   {24, 24, 24, 11, 11, 12, 0, 24, 24, 24, 0, 0, 0,	//RGBA
                                          16, 16, 16, 11, 10, 8,  0, 16, 16, 16, 0, 0, 0,	//ARGB
                                          8,  8,  8,  0,  1,  4,  0, 8,  8,  8,  0, 0, 0,	//BGRA
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0};	//ABGR

	static const int greenShifts[4*13] = {16, 16, 16, 5,  6,  8,  0, 16, 16, 16, 0, 0, 0,	//RGBA
                                          8,  8,  8,  5,  5,  4,  0, 8,  8,  8,  0, 0, 0,	//ARGB
                                          16, 16, 16, 5,  6,  8,  0, 16, 16, 16, 0, 0, 0,	//BGRA
                                          8,  8,  8,  5,  5,  4,  0, 8,  8,  8,  0, 0, 0};	//ABGR

	static const int blueShifts[4*13] =  {8,  8,  8,  0,  1,  4,  0, 8,  8,  8,  0, 0, 0,	//RGBA
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//ARGB
                                          24, 24, 24, 11, 11, 12, 0, 24, 24, 24, 0, 0, 0,	//BGRA
                                          16, 16, 16, 11, 10, 8,  0, 16, 16, 16, 0, 0, 0};	//ABGR

	static const int alphaShifts[4*13] = {0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//RGBA
                                          0,  24, 24, 0,  15, 12, 0, 0,  24, 24, 0, 0, 0,	//ARGB
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//BGRA
                                          0,  24, 24, 0,  15, 12, 0, 0,  24, 24, 0, 0, 0};	//ABGR

	static const int bpps[13] = {32, 32, 32, 16, 16, 16, 8, 32, 32, 32, 8, 8, 1};

	static const InternalFormat internalFormats[13] = {sRGBA, sRGBA, sRGBA_PRE, sRGBA, sRGBA, sRGBA, sLA, lRGBA, lRGBA, lRGBA_PRE, lLA, lRGBA, lLA};

	desc.redBits = redBits[baseFormat];
	desc.greenBits = greenBits[baseFormat];
	desc.blueBits = blueBits[baseFormat];
	desc.alphaBits = alphaBits[baseFormat];
	desc.luminanceBits = luminanceBits[baseFormat];

	desc.redShift = redShifts[swizzleBits * 13 + baseFormat];
	desc.greenShift = greenShifts[swizzleBits * 13 + baseFormat];
	desc.blueShift = blueShifts[swizzleBits * 13 + baseFormat];
	desc.alphaShift = alphaShifts[swizzleBits * 13 + baseFormat];
	desc.luminanceShift = 0;	//always zero

	desc.format = format;
	desc.bitsPerPixel = bpps[baseFormat];
	desc.internalFormat = internalFormats[baseFormat];

	return desc;
}

/*-------------------------------------------------------------------*//*!
* \brief	Checks if the pixel format descriptor is valid (i.e. all the
*           values are supported by the RI)
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Color::isValidDescriptor(const Color::Descriptor& desc)
{
	//A valid descriptor has 1, 8, 16, or 32 bits per pixel, and either luminance or rgba channels, but not both.
	//Any of the rgba channels can be missing, and not all bits need to be used. Maximum channel bit depth is 8.
	int rb = desc.redBits;
	int gb = desc.greenBits;
	int bb = desc.blueBits;
	int ab = desc.alphaBits;
	int lb = desc.luminanceBits;
	int rs = desc.redShift;
	int gs = desc.greenShift;
	int bs = desc.blueShift;
	int as = desc.alphaShift;
	int ls = desc.luminanceShift;
	int bpp = desc.bitsPerPixel;

	int rgbaBits = rb + gb + bb + ab;
	if(rb < 0 || rb > 8 || rs < 0 || rs + rb > bpp || !(rb || !rs))
		return false;	//invalid channel description
	if(gb < 0 || gb > 8 || gs < 0 || gs + gb > bpp || !(gb || !gs))
		return false;	//invalid channel description
	if(bb < 0 || bb > 8 || bs < 0 || bs + bb > bpp || !(bb || !bs))
		return false;	//invalid channel description
	if(ab < 0 || ab > 8 || as < 0 || as + ab > bpp || !(ab || !as))
		return false;	//invalid channel description
	if(lb < 0 || lb > 8 || ls < 0 || ls + lb > bpp || !(lb || !ls))
		return false;	//invalid channel description

	if(rgbaBits && lb)
		return false;	//can't have both rgba and luminance
	if(!rgbaBits && !lb)
		return false;	//must have either rgba or luminance
	if(rgbaBits)
	{	//rgba
		if(rb+gb+bb == 0)
		{	//alpha only
			if(rs || gs || bs || as || ls)
				return false;	//wrong shifts (even alpha shift must be zero)
			if(ab != 8 || bpp != ab)
				return false;	//alpha size must be 8, bpp must match
		}
		else
		{	//rgba
			if(rgbaBits > bpp)
				return false;	//bpp must be greater than or equal to the sum of rgba bits
			if(!(bpp == 32 || bpp == 16 || bpp == 8))
				return false;	//only 1, 2, and 4 byte formats are supported for rgba
			
			unsigned int rm = bitsToMask((unsigned int)rb, (unsigned int)rs);
			unsigned int gm = bitsToMask((unsigned int)gb, (unsigned int)gs);
			unsigned int bm = bitsToMask((unsigned int)bb, (unsigned int)bs);
			unsigned int am = bitsToMask((unsigned int)ab, (unsigned int)as);
			if((rm & gm) || (rm & bm) || (rm & am) || (gm & bm) || (gm & am) || (bm & am))
				return false;	//channels overlap
		}
	}
	else
	{	//luminance
		if(rs || gs || bs || as || ls)
			return false;	//wrong shifts (even luminance shift must be zero)
		if(!(lb == 1 || lb == 8) || bpp != lb)
			return false;	//luminance size must be either 1 or 8, bpp must match
	}

	if(desc.format != -1)
	{
		if(!isValidImageFormat(desc.format))
			return false;	//invalid image format

		Descriptor d = formatToDescriptor(desc.format);
		if(d.redBits != rb || d.greenBits != gb || d.blueBits != bb || d.alphaBits != ab || d.luminanceBits != lb ||
		   d.redShift != rs || d.greenShift != gs || d.blueShift != bs || d.alphaShift != as || d.luminanceShift != ls ||
		   d.bitsPerPixel != bpp)
		   return false;	//if the descriptor has a VGImageFormat, it must match the bits, shifts, and bpp
	}

	if((unsigned int)desc.internalFormat & ~(Color::PREMULTIPLIED | Color::NONLINEAR | Color::LUMINANCE))
		return false;	//invalid internal format

	return true;
}

//==============================================================================================




//==============================================================================================

/*-------------------------------------------------------------------*//*!
* \brief	Constructs a blank image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Image::Image(const Color::Descriptor& desc, int width, int height, VGbitfield allowedQuality) :
	m_desc(desc),
	m_width(width),
	m_height(height),
	m_allowedQuality(allowedQuality),
	m_inUse(0),
	m_stride(0),
	m_data(NULL),
	m_bitOffset(0),
	m_referenceCount(0),
	m_ownsData(true),
	m_hasChildren(false),
	m_parent(NULL),
	m_parentOffsetX(0),
	m_parentOffsetY(0),
	m_mipmapsValid(false),
	m_mipmaps()
{
	RI_ASSERT(Color::isValidDescriptor(m_desc));
	RI_ASSERT(width > 0 && height > 0);
	
	if( m_desc.bitsPerPixel != 1 )
	{
		RI_ASSERT(m_desc.bitsPerPixel == 8 || m_desc.bitsPerPixel == 16 || m_desc.bitsPerPixel == 32);
		m_stride = m_width*m_desc.bitsPerPixel/8;
	}
	else
	{
		RI_ASSERT(m_desc.bitsPerPixel == 1);
		m_stride = (m_width+7)/8;
	}
	m_data = RI_NEW_ARRAY(RIuint8, m_stride*m_height);	//throws bad_alloc
	memset(m_data, 0, m_stride*m_height);	//clear image
}

/*-------------------------------------------------------------------*//*!
* \brief	Constructs an image that uses an external array for its data
*			storage.
* \param	
* \return	
* \note		this is meant for internal use to make blitting easier
*//*-------------------------------------------------------------------*/

Image::Image(const Color::Descriptor& desc, int width, int height, int stride, RIuint8* data) :
	m_desc(desc),
	m_width(width),
	m_height(height),
	m_allowedQuality(0),
	m_inUse(0),
	m_stride(stride),
	m_data(data),
	m_bitOffset(0),
	m_referenceCount(0),
	m_ownsData(false),
	m_hasChildren(false),
	m_parent(NULL),
	m_parentOffsetX(0),
	m_parentOffsetY(0),
	m_mipmapsValid(false),
	m_mipmaps()
{
	RI_ASSERT(Color::isValidDescriptor(m_desc));
	RI_ASSERT(width > 0 && height > 0);
	RI_ASSERT(data);
}

/*-------------------------------------------------------------------*//*!
* \brief	Construcs a child image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Image::Image(Image* parent, int x, int y, int width, int height) :
	m_desc(Color::formatToDescriptor(VG_sRGBA_8888)),	//dummy initialization, will be overwritten below (can't read from parent->m_desc before knowing the pointer is valid)
	m_width(width),
	m_height(height),
	m_allowedQuality(0),
	m_inUse(0),
	m_stride(0),
	m_data(NULL),
	m_bitOffset(0),
	m_referenceCount(0),
	m_ownsData(false),
	m_hasChildren(false),
	m_parent(parent),
	m_parentOffsetX(x),
	m_parentOffsetY(y),
	m_mipmapsValid(false),
	m_mipmaps()
{
	RI_ASSERT(parent);
	RI_ASSERT(x >= 0 && y >= 0 && width > 0 && height > 0);
	RI_ASSERT(RI_INT_ADDSATURATE(x,width) <= parent->m_width && RI_INT_ADDSATURATE(y,height) <= parent->m_height);	//child image must be contained in parent

	m_desc = parent->m_desc;
	RI_ASSERT(Color::isValidDescriptor(m_desc));
	m_allowedQuality = parent->m_allowedQuality;
	m_stride = parent->m_stride;

	if( m_desc.bitsPerPixel != 1 )
	{
		RI_ASSERT(m_desc.bitsPerPixel == 8 || m_desc.bitsPerPixel == 16 || m_desc.bitsPerPixel == 32);
		m_data = parent->m_data + y * m_stride + x * (m_desc.bitsPerPixel/8);
		m_bitOffset = 0;
	}
	else
	{
		RI_ASSERT(m_desc.bitsPerPixel == 1);
		m_data = parent->m_data + y * m_stride + (x/8);
		m_bitOffset = x&7;
	}

	//increase the reference and use count of the parent
	addInUse();
	parent->addInUse();
	parent->addReference();
	parent->m_hasChildren = true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Image destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Image::~Image()
{
	RI_ASSERT(m_referenceCount == 0);

	if(m_parent)
	{
		//decrease the reference and use count of the parent
		removeInUse();
		m_parent->removeInUse();
		if(!m_parent->removeReference())
			RI_DELETE(m_parent);
	}
	RI_ASSERT(m_inUse == 0);

	for(int i=0;i<m_mipmaps.size();i++)
	{
		if(!m_mipmaps[i]->removeReference())
			RI_DELETE(m_mipmaps[i]);
		else
		{
			RI_ASSERT(0);	//there can't be any other references to the mipmap levels
		}
	}
	m_mipmaps.clear();

	if(m_ownsData)
	{
		RI_ASSERT(!m_parent);		//can't have parent if owns the data
		RI_DELETE_ARRAY(m_data);	//delete image data if we own it
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns true if the two images share pixels.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Image::overlaps(const Image* src) const
{
	RI_ASSERT(src);

	const Image* dstancestor = this;
	int dstoffsetx = 0, dstoffsety = 0;
	for(;dstancestor->m_parent;dstancestor = dstancestor->m_parent)
	{
		dstoffsetx += dstancestor->m_parentOffsetX;
		dstoffsety += dstancestor->m_parentOffsetY;
	}

	const Image* srcancestor = src;
	int srcoffsetx = 0, srcoffsety = 0;
	for(;srcancestor->m_parent;srcancestor = srcancestor->m_parent)
	{
		srcoffsetx += srcancestor->m_parentOffsetX;
		srcoffsety += srcancestor->m_parentOffsetY;
	}
	if(dstancestor != srcancestor)
		return false;	//no common ancestor, images don't overlap

	//check if the image regions overlap in the common ancestor
	Rectangle r(dstoffsetx, dstoffsety, m_width, m_height);
	r.intersect(Rectangle(srcoffsetx, srcoffsety, src->m_width, src->m_height));
	if(!r.width || !r.height)
		return false;	//intersection is empty, images don't overlap	

	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Resizes an image. New pixels are set to the given color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::resize(int newWidth, int newHeight, const Color& newPixelColor)
{
	RI_ASSERT(newWidth > 0 && newHeight > 0);
	RI_ASSERT(!m_parent && m_ownsData && !m_hasChildren);	//disallow resizing if data is shared
	RI_ASSERT(m_bitOffset == 0);	//we don't have to worry about bitOffset in this function (this is always the original image, not a child)
	RI_ASSERT(m_referenceCount > 0);

	//destroy mipmaps
	for(int i=0;i<m_mipmaps.size();i++)
	{
		if(!m_mipmaps[i]->removeReference())
			RI_DELETE(m_mipmaps[i]);
		else
		{
			RI_ASSERT(0);	//there can't be any other references to the mipmap levels
		}
	}
	m_mipmaps.clear();
	m_mipmapsValid = false;
	
	int newStride;
	if( m_desc.bitsPerPixel != 1 )
	{
		RI_ASSERT(m_desc.bitsPerPixel == 8 || m_desc.bitsPerPixel == 16 || m_desc.bitsPerPixel == 32);
		newStride = newWidth*m_desc.bitsPerPixel/8;
	}
	else
	{
		RI_ASSERT(m_desc.bitsPerPixel == 1);
		newStride = (newWidth+7)/8;
	}

	RIuint8* newData = RI_NEW_ARRAY(RIuint8, newStride*newHeight);	//throws bad_alloc

	Color col = newPixelColor;
	col.clamp();
	col.convert(m_desc.internalFormat);
	unsigned int c = col.pack(m_desc);

	int w = RI_INT_MIN(m_width, newWidth);
	for(int j=0;j<newHeight;j++)
	{
		if(j >= m_height)
			w = 0;		//clear new scanlines
		RIuint8* d = newData + j * newStride;
		RIuint8* s = m_data + j * m_stride;
		switch(m_desc.bitsPerPixel)
		{
		case 32:
		{
			for(int i=0;i<w;i++)
			{
				*(RIuint32*)d = *(RIuint32*)s;	//copy old pixels
				d += 4; s += 4;
			}
			for(int i=w;i<newWidth;i++)
			{
				*(RIuint32*)d = (RIuint32)c;	//clear new pixels
				d += 4;
			}
			break;
		}

		case 16:
		{
			for(int i=0;i<w;i++)
			{
				*(RIuint16*)d = *(RIuint16*)s;	//copy old pixels
				d += 2; s += 2;
			}
			for(int i=w;i<newWidth;i++)
			{
				*(RIuint16*)d = (RIuint16)c;	//clear new pixels
				d += 2;
			}
			break;
		}

		case 8:
		{
			for(int i=0;i<w;i++)
				*d++ = *s++;	//copy old pixels
			for(int i=w;i<newWidth;i++)
				*d++ = (RIuint8)c;	//clear new pixels
			break;
		}

		default:
		{
			RI_ASSERT(m_desc.bitsPerPixel == 1);
			if( c )
				c = 0xff;
			int e = w>>3;	//number of full bytes
			for(int i=0;i<e;i++)
				*d++ = *s++;	//copy old pixels

			//copy end leftovers and clear the rest
			int numLeftoverBits = w - (e<<3);
			RI_ASSERT(numLeftoverBits >= 0 && numLeftoverBits < 8);
			if( numLeftoverBits )
			{
				unsigned int maskBits = ((1 << numLeftoverBits) - 1);
				unsigned int l = ((unsigned int)*s) & maskBits;
				if( c )
					l |= ~maskBits;
				*d++ = (RIuint8)l;
				e++;
			}

			for(int i=e;i<((newWidth+7)>>3);i++)
				*d++ = (RIuint8)c;	//clear new pixels
			break;
		}
		}
	}

	RI_DELETE_ARRAY(m_data);
	m_data = newData;
	m_width = newWidth;
	m_height = newHeight;
	m_stride = newStride;
}

/*-------------------------------------------------------------------*//*!
* \brief	Clears a rectangular portion of an image with the given clear color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::clear(const Color& clearColor, int x, int y, int w, int h)
{
	RI_ASSERT(m_data);
	RI_ASSERT(m_referenceCount > 0);

	//intersect clear region with image bounds
	Rectangle r(0,0,m_width,m_height);
	r.intersect(Rectangle(x,y,w,h));
	if(!r.width || !r.height)
		return;		//intersection is empty or one of the rectangles is invalid

	Color col = clearColor;
	col.clamp();
	col.convert(m_desc.internalFormat);

	for(int j=r.y;j<r.y + r.height;j++)
	{
		for(int i=r.x;i<r.x + r.width;i++)
		{
			writePixel(i, j, col);
		}
	}

	m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Blits a source region to destination. Source and destination
*			can overlap.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static RIfloat ditherChannel(RIfloat c, int bits, RIfloat m)
{
	RIfloat fc = c * (RIfloat)((1<<bits)-1);
	RIfloat ic = (RIfloat)floor(fc);
	if(fc - ic > m) ic += 1.0f;
	return RI_MIN(ic / (RIfloat)((1<<bits)-1), 1.0f);
}

void Image::blit(const Image& src, int sx, int sy, int dx, int dy, int w, int h, bool dither)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(w > 0 && h > 0);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	sx = RI_INT_MIN(RI_INT_MAX(sx, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	sy = RI_INT_MIN(RI_INT_MAX(sy, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	dx = RI_INT_MIN(RI_INT_MAX(dx, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	dy = RI_INT_MIN(RI_INT_MAX(dy, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	w = RI_INT_MIN(w, (int)(RI_INT32_MAX>>2));
	h = RI_INT_MIN(h, (int)(RI_INT32_MAX>>2));
	int srcsx = sx, srcex = sx + w, dstsx = dx, dstex = dx + w;
	if(srcsx < 0)
	{
		dstsx -= srcsx;
		srcsx = 0;
	}
	if(srcex > src.m_width)
	{
		dstex -= srcex - src.m_width;
		srcex = src.m_width;
	}
	if(dstsx < 0)
	{
		srcsx -= dstsx;
		dstsx = 0;
	}
	if(dstex > m_width)
	{
		srcex -= dstex - m_width;
		dstex = m_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src.m_width && dstex <= m_width);
	w = srcex - srcsx;
	RI_ASSERT(w == dstex - dstsx);
	if(w <= 0)
		return;	//zero area

	int srcsy = sy, srcey = sy + h, dstsy = dy, dstey = dy + h;
	if(srcsy < 0)
	{
		dstsy -= srcsy;
		srcsy = 0;
	}
	if(srcey > src.m_height)
	{
		dstey -= srcey - src.m_height;
		srcey = src.m_height;
	}
	if(dstsy < 0)
	{
		srcsy -= dstsy;
		dstsy = 0;
	}
	if(dstey > m_height)
	{
		srcey -= dstey - m_height;
		dstey = m_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src.m_height && dstey <= m_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

	Array<Color> tmp;
	tmp.resize(w*h);	//throws bad_alloc

	//copy source region to tmp
	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color c = src.readPixel(srcsx + i, srcsy + j);
			c.convert(m_desc.internalFormat);
			tmp[j*w+i] = c;
		}
	}

	int rbits = m_desc.redBits, gbits = m_desc.greenBits, bbits = m_desc.blueBits, abits = m_desc.alphaBits;
	if(m_desc.luminanceBits)
	{
		rbits = gbits = bbits = m_desc.luminanceBits;
		abits = 0;
	}

	//write tmp to destination region
	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color col = tmp[j*w+i];

			if(dither)
			{
				static const int matrix[16] = {
					0,  8,  2,  10,
					12, 4,  14, 6,
					3,  11, 1,  9,
					15, 7,  13, 5};
				int x = i & 3;
				int y = j & 3;
				RIfloat m = matrix[y*4+x] / 16.0f;

				if(rbits) col.r = ditherChannel(col.r, rbits, m);
				if(gbits) col.g = ditherChannel(col.g, gbits, m);
				if(bbits) col.b = ditherChannel(col.b, bbits, m);
				if(abits) col.a = ditherChannel(col.a, abits, m);
			}

			writePixel(dstsx + i, dstsy + j, col);
		}
	}
	m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies a mask operation to a rectangular portion of a mask image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::mask(const Image* src, VGMaskOperation operation, int x, int y, int w, int h)
{
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(w > 0 && h > 0);
	RI_ASSERT(m_referenceCount > 0);

	m_mipmapsValid = false;
	if(operation == VG_CLEAR_MASK)
	{
		clear(Color(0,0,0,0,Color::lRGBA), x, y, w, h);
		return;
	}
	if(operation == VG_FILL_MASK)
	{
		clear(Color(1,1,1,1,Color::lRGBA), x, y, w, h);
		return;
	}

	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(src->m_referenceCount > 0);

	//intersect destination region with source and destination image bounds
	x = RI_INT_MIN(RI_INT_MAX(x, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	y = RI_INT_MIN(RI_INT_MAX(y, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	w = RI_INT_MIN(w, (int)(RI_INT32_MAX>>2));
	h = RI_INT_MIN(h, (int)(RI_INT32_MAX>>2));

	int srcsx = 0, srcex = w, dstsx = x, dstex = x + w;
	if(srcex > src->m_width)
	{
		dstex -= srcex - src->m_width;
		srcex = src->m_width;
	}
	if(dstsx < 0)
	{
		srcsx -= dstsx;
		dstsx = 0;
	}
	if(dstex > m_width)
	{
		srcex -= dstex - m_width;
		dstex = m_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src->m_width && dstex <= m_width);
	w = srcex - srcsx;
	RI_ASSERT(w == dstex - dstsx);
	if(w <= 0)
		return;	//zero area

	int srcsy = 0, srcey = h, dstsy = y, dstey = y + h;
	if(srcey > src->m_height)
	{
		dstey -= srcey - src->m_height;
		srcey = src->m_height;
	}
	if(dstsy < 0)
	{
		srcsy -= dstsy;
		dstsy = 0;
	}
	if(dstey > m_height)
	{
		srcey -= dstey - m_height;
		dstey = m_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src->m_height && dstey <= m_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			RIfloat aprev = readMaskPixel(dstsx + i, dstsy + j);
			RIfloat amask = src->readMaskPixel(srcsx + i, srcsy + j);
			RIfloat anew = 0.0f;
			switch(operation)
			{
			case VG_SET_MASK:
				anew = amask;
				break;

			case VG_UNION_MASK:
				anew = 1.0f - (1.0f - amask)*(1.0f - aprev);
				break;

			case VG_INTERSECT_MASK:
				anew = amask * aprev;
				break;

			default:
				RI_ASSERT(operation == VG_SUBTRACT_MASK);
				anew = aprev * (1.0f - amask);
				break;
			}
			writeMaskPixel(dstsx + i, dstsy + j, anew);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns the color at pixel (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Color Image::readPixel(int x, int y) const
{
	RI_ASSERT(m_data);
	RI_ASSERT(x >= 0 && x < m_width);
	RI_ASSERT(y >= 0 && y < m_height);
	RI_ASSERT(m_referenceCount > 0);
       
	unsigned int p = 0;
	RIuint8* scanline = m_data + y * m_stride;
	switch(m_desc.bitsPerPixel)
	{
	case 32:
	{
		RIuint32* s = (((RIuint32*)scanline) + x);
		p = (unsigned int)*s;
		break;
	}

	case 16:
	{
		RIuint16* s = ((RIuint16*)scanline) + x;
		p = (unsigned int)*s;
		break;
	}

	case 8:
	{
		RIuint8* s = ((RIuint8*)scanline) + x;
		p = (unsigned int)*s;
		break;
	}

	default:
	{
		RI_ASSERT(m_desc.bitsPerPixel == 1);
		x += m_bitOffset;
		RIuint8* s = scanline + (x>>3);
		p = (((unsigned int)*s) >> (x&7)) & 1u;
		break;
	}
	}
	Color c;
	c.unpack(p, m_desc);
	return c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes the color to pixel (x,y). Internal color formats must
*			match.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::writePixel(int x, int y, const Color& c)
{
	RI_ASSERT(m_data);
	RI_ASSERT(x >= 0 && x < m_width);
	RI_ASSERT(y >= 0 && y < m_height);
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(c.getInternalFormat() == m_desc.internalFormat);

	unsigned int p = c.pack(m_desc);
	RIuint8* scanline = m_data + y * m_stride;
	switch(m_desc.bitsPerPixel)
	{
	case 32:
	{
		RIuint32* s = ((RIuint32*)scanline) + x;
		*s = (RIuint32)p;
		break;
	}

	case 16:
	{
		RIuint16* s = ((RIuint16*)scanline) + x;
		*s = (RIuint16)p;
		break;
	}

	case 8:
	{
		RIuint8* s = ((RIuint8*)scanline) + x;
		*s = (RIuint8)p;
		break;
	}

	default:
	{
		RI_ASSERT(m_desc.bitsPerPixel == 1);
		x += m_bitOffset;
		RIuint8* s = scanline + (x>>3);
		RIuint8 d = *s;
		d &= ~(1<<(x&7));
		d |= (RIuint8)(p<<(x&7));
		*s = d;
		break;
	}
	}
	m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes a filtered color to destination surface
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::writeFilteredPixel(int i, int j, const Color& color, VGbitfield channelMask)
{
	//section 3.4.4: before color space conversion, premultiplied colors are
	//clamped to alpha, and the color is converted to nonpremultiplied format
	//section 11.2: how to deal with channel mask
	//step 1
	Color f = color;
	f.clamp();			//vgColorMatrix and vgLookups can produce colors that exceed alpha or [0,1] range
	f.unpremultiply();

	//step 2: color space conversion
	f.convert((Color::InternalFormat)(m_desc.internalFormat & (Color::NONLINEAR | Color::LUMINANCE)));

	//step 3: read the destination color and convert it to nonpremultiplied
	Color d = readPixel(i,j);
	d.unpremultiply();
	RI_ASSERT(d.getInternalFormat() == f.getInternalFormat());

	//step 4: replace the destination channels specified by the channelMask
	if(channelMask & VG_RED)
		d.r = f.r;
	if(channelMask & VG_GREEN)
		d.g = f.g;
	if(channelMask & VG_BLUE)
		d.b = f.b;
	if(channelMask & VG_ALPHA)
		d.a = f.a;

	//step 5: if destination is premultiplied, convert to premultiplied format
	if(m_desc.internalFormat & Color::PREMULTIPLIED)
		d.premultiply();
	//write the color to destination
	writePixel(i,j,d);
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads the pixel (x,y) and converts it into an alpha mask value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

RIfloat Image::readMaskPixel(int x, int y) const
{
	RI_ASSERT(m_data);
	RI_ASSERT(x >= 0 && x < m_width);
	RI_ASSERT(y >= 0 && y < m_height);
	RI_ASSERT(m_referenceCount > 0);

	Color c = readPixel(x,y);
	if(m_desc.luminanceBits)
	{	//luminance
		return c.r;	//luminance/luma is read into the color channels
	}
	else
	{	//rgba
		if(m_desc.alphaBits)
			return c.a;
		return c.r;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes the alpha mask to pixel (x,y) of a VG_A_8 image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::writeMaskPixel(int x, int y, RIfloat m)
{
	RI_ASSERT(m_data);
	RI_ASSERT(x >= 0 && x < m_width);
	RI_ASSERT(y >= 0 && y < m_height);
	RI_ASSERT(m_desc.alphaBits == 8 && m_desc.redBits == 0 && m_desc.greenBits == 0 && m_desc.blueBits == 0 && m_desc.luminanceBits == 0 && m_desc.bitsPerPixel == 8);
	RI_ASSERT(m_referenceCount > 0);

	RIuint8* s = ((RIuint8*)(m_data + y * m_stride)) + x;
	*s = (RIuint8)colorToInt(m, 255);
	m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a texel (u,v) at the given mipmap level. Tiling modes and
*			color space conversion are applied. Outputs color in premultiplied
*			format.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Color Image::readTexel(int u, int v, int level, VGTilingMode tilingMode, const Color& tileFillColor) const
{
	const Image* image = this;
	if( level > 0 )
	{
		RI_ASSERT(level <= m_mipmaps.size());
		image = m_mipmaps[level-1];
	}
	RI_ASSERT(image);

	Color p;
	if(tilingMode == VG_TILE_FILL)
	{
		if(u < 0 || v < 0 || u >= image->m_width || v >= image->m_height)
			p = tileFillColor;
		else
			p = image->readPixel(u, v);
	}
	else if(tilingMode == VG_TILE_PAD)
	{
		u = RI_INT_MIN(RI_INT_MAX(u,0),image->m_width-1);
		v = RI_INT_MIN(RI_INT_MAX(v,0),image->m_height-1);
		p = image->readPixel(u, v);
	}
	else if(tilingMode == VG_TILE_REPEAT)
	{
		u = RI_INT_MOD(u, image->m_width);
		v = RI_INT_MOD(v, image->m_height);
		p = image->readPixel(u, v);
	}
	else
	{
		RI_ASSERT(tilingMode == VG_TILE_REFLECT);

		u = RI_INT_MOD(u, image->m_width*2);
		v = RI_INT_MOD(v, image->m_height*2);
		if( u >= image->m_width ) u = image->m_width*2-1 - u;
		if( v >= image->m_height ) v = image->m_height*2-1 - v;
		p = image->readPixel(u, v);
	}

	p.premultiply();
	return p;
}

/*-------------------------------------------------------------------*//*!
* \brief	Maps point (x,y) to an image and returns a filtered,
*			premultiplied color value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Color Image::resample(RIfloat x, RIfloat y, const Matrix3x3& surfaceToImage, CGInterpolationQuality quality, VGTilingMode tilingMode, const Color& tileFillColor)	//throws bad_alloc
{
	RI_ASSERT(m_referenceCount > 0);

	//VGbitfield aq = getAllowedQuality();
	//aq &= (VGbitfield)quality;

	Vector3 uvw(x,y,1.0f);
	uvw = surfaceToImage * uvw;
	RIfloat oow = 1.0f / uvw.z;
	uvw *= oow;

	if(quality== kCGInterpolationHigh)
	{	//EWA on mipmaps
		makeMipMaps();	//throws bad_alloc

		Color::InternalFormat procFormat = (Color::InternalFormat)(m_desc.internalFormat | Color::PREMULTIPLIED);

		RIfloat m_pixelFilterRadius = 1.25f;
		RIfloat m_resamplingFilterRadius = 1.25f;

		RIfloat Ux = (surfaceToImage[0][0] - uvw.x * surfaceToImage[2][0]) * oow * m_pixelFilterRadius;
		RIfloat Vx = (surfaceToImage[1][0] - uvw.y * surfaceToImage[2][0]) * oow * m_pixelFilterRadius;
		RIfloat Uy = (surfaceToImage[0][1] - uvw.x * surfaceToImage[2][1]) * oow * m_pixelFilterRadius;
		RIfloat Vy = (surfaceToImage[1][1] - uvw.y * surfaceToImage[2][1]) * oow * m_pixelFilterRadius;
		RIfloat U0 = uvw.x;
		RIfloat V0 = uvw.y;

		//calculate mip level
		int level = 0;
		RIfloat axis1sq = Ux*Ux + Vx*Vx;
		RIfloat axis2sq = Uy*Uy + Vy*Vy;
		RIfloat minorAxissq = RI_MIN(axis1sq,axis2sq);
		while(minorAxissq > 9.0f && level < m_mipmaps.size())	//half the minor axis must be at least three texels
		{
			level++;
			minorAxissq *= 0.25f;
		}

		RIfloat sx = 1.0f;
		RIfloat sy = 1.0f;
		if(level > 0)
		{
			sx = (RIfloat)m_mipmaps[level-1]->m_width / (RIfloat)m_width;
			sy = (RIfloat)m_mipmaps[level-1]->m_height / (RIfloat)m_height;
		}
		Ux *= sx;
		Vx *= sx;
		U0 *= sx;
		Uy *= sy;
		Vy *= sy;
		V0 *= sy;
		
		//clamp filter size so that filtering doesn't take excessive amount of time (clamping results in aliasing)
		RIfloat lim = 100.0f;
		axis1sq = Ux*Ux + Vx*Vx;
		axis2sq = Uy*Uy + Vy*Vy;
		if( axis1sq > lim*lim )
		{
			RIfloat s = lim / (RIfloat)sqrt(axis1sq);
			Ux *= s;
			Vx *= s;
		}
		if( axis2sq > lim*lim )
		{
			RIfloat s = lim / (RIfloat)sqrt(axis2sq);
			Uy *= s;
			Vy *= s;
		}
		
		
		//form elliptic filter by combining texel and pixel filters
		RIfloat A = Vx*Vx + Vy*Vy + 1.0f;
		RIfloat B = -2.0f*(Ux*Vx + Uy*Vy);
		RIfloat C = Ux*Ux + Uy*Uy + 1.0f;
		//scale by the user-defined size of the kernel
		A *= m_resamplingFilterRadius;
		B *= m_resamplingFilterRadius;
		C *= m_resamplingFilterRadius;
		
		//calculate bounding box in texture space
		RIfloat usize = (RIfloat)sqrt(C);
		RIfloat vsize = (RIfloat)sqrt(A);
		int u1 = (int)floor(U0 - usize + 0.5f);
		int u2 = (int)floor(U0 + usize + 0.5f);
		int v1 = (int)floor(V0 - vsize + 0.5f);
		int v2 = (int)floor(V0 + vsize + 0.5f);
		if( u1 == u2 || v1 == v2 )
			return Color(0,0,0,0,procFormat);

		//scale the filter so that Q = 1 at the cutoff radius
		RIfloat F = A*C - 0.25f * B*B;
		if( F <= 0.0f )
			return Color(0,0,0,0,procFormat);	//invalid filter shape due to numerical inaccuracies => return black
		RIfloat ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;
		
		//evaluate filter by using forward differences to calculate Q = A*U^2 + B*U*V + C*V^2
		Color color(0,0,0,0,procFormat);
		RIfloat sumweight = 0.0f;
		RIfloat DDQ = 2.0f * A;
		RIfloat U = (RIfloat)u1 - U0 + 0.5f;
		for(int v=v1;v<v2;v++)
		{
			RIfloat V = (RIfloat)v - V0 + 0.5f;
			RIfloat DQ = A*(2.0f*U+1.0f) + B*V;
			RIfloat Q = (C*V+B*U)*V + A*U*U;
			for(int u=u1;u<u2;u++)
			{
				if( Q >= 0.0f && Q < 1.0f )
				{	//Q = r^2, fit gaussian to the range [0,1]
					RIfloat weight = (RIfloat)exp(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
					color += weight * readTexel(u, v, level, tilingMode, tileFillColor);
					sumweight += weight;
				}
				Q += DQ;
				DQ += DDQ;
			}
		}
		if( sumweight == 0.0f )
			return Color(0,0,0,0,procFormat);
		RI_ASSERT(sumweight > 0.0f);
		sumweight = 1.0f / sumweight;
		return color * sumweight;
	}
	else if(quality== kCGInterpolationLow)
	{	//bilinear
		uvw.x -= 0.5f;
		uvw.y -= 0.5f;
		int u = (int)floor(uvw.x);
		int v = (int)floor(uvw.y);
		Color c00 = readTexel(u,v, 0, tilingMode, tileFillColor);
		Color c10 = readTexel(u+1,v, 0, tilingMode, tileFillColor);
		Color c01 = readTexel(u,v+1, 0, tilingMode, tileFillColor);
		Color c11 = readTexel(u+1,v+1, 0, tilingMode, tileFillColor);
		RIfloat fu = uvw.x - (RIfloat)u;
		RIfloat fv = uvw.y - (RIfloat)v;
		Color c0 = c00 * (1.0f - fu) + c10 * fu;
		Color c1 = c01 * (1.0f - fu) + c11 * fu;
		return c0 * (1.0f - fv) + c1 * fv;
	}
	else
	{	//point sampling
		return readTexel((int)floor(uvw.x), (int)floor(uvw.y), 0, tilingMode, tileFillColor);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generates mip maps for an image.
* \param	
* \return	
* \note		Downsampling is done in the input color space. We use a box
*			filter for downsampling.
*//*-------------------------------------------------------------------*/

void Image::makeMipMaps()
{
	RI_ASSERT(m_data);
	RI_ASSERT(m_referenceCount > 0);

	if(m_mipmapsValid)
		return;

	//delete existing mipmaps
	for(int i=0;i<m_mipmaps.size();i++)
	{
		if(!m_mipmaps[i]->removeReference())
			RI_DELETE(m_mipmaps[i]);
		else
		{
			RI_ASSERT(0);	//there can't be any other references to the mipmap levels
		}
	}
	m_mipmaps.clear();

	try
	{
		Color::InternalFormat procFormat = m_desc.internalFormat;
		procFormat = (Color::InternalFormat)(procFormat | Color::PREMULTIPLIED);	//premultiplied

		//generate mipmaps until width and height are one
		Image* prev = this;
		while( prev->m_width > 1 || prev->m_height > 1 )
		{
			int nextw = (int)ceil(prev->m_width*0.5f);
			int nexth = (int)ceil(prev->m_height*0.5f);
			RI_ASSERT(nextw >= 1 && nexth >= 1);
			RI_ASSERT(nextw < prev->m_width || nexth < prev->m_height);

			m_mipmaps.resize(m_mipmaps.size()+1);	//throws bad_alloc
			m_mipmaps[m_mipmaps.size()-1] = NULL;

			Image* next = RI_NEW(Image, (m_desc, nextw, nexth, m_allowedQuality));	//throws bad_alloc
			next->addReference();
			for(int j=0;j<next->m_height;j++)
			{
				for(int i=0;i<next->m_width;i++)
				{
					RIfloat u0 = (RIfloat)i / (RIfloat)next->m_width;
					RIfloat u1 = (RIfloat)(i+1) / (RIfloat)next->m_width;
					RIfloat v0 = (RIfloat)j / (RIfloat)next->m_height;
					RIfloat v1 = (RIfloat)(j+1) / (RIfloat)next->m_height;

					u0 *= prev->m_width;
					u1 *= prev->m_width;
					v0 *= prev->m_height;
					v1 *= prev->m_height;

					int su = (int)floor(u0);
					int eu = (int)ceil(u1);
					int sv = (int)floor(v0);
					int ev = (int)ceil(v1);

					Color c(0,0,0,0,procFormat);
					int samples = 0;
					for(int y=sv;y<ev;y++)
					{
						for(int x=su;x<eu;x++)
						{
							Color p = prev->readPixel(x, y);
							p.convert(procFormat);
							c += p;
							samples++;
						}
					}
					c *= (1.0f/samples);
					c.convert(m_desc.internalFormat);
					next->writePixel(i,j,c);
				}
			}
			m_mipmaps[m_mipmaps.size()-1] = next;
			prev = next;
		}
		RI_ASSERT(prev->m_width == 1 && prev->m_height == 1);
		m_mipmapsValid = true;
	}
	catch(std::bad_alloc)
	{
		//delete existing mipmaps
		for(int i=0;i<m_mipmaps.size();i++)
		{
			if(m_mipmaps[i])
			{
				if(!m_mipmaps[i]->removeReference())
					RI_DELETE(m_mipmaps[i]);
				else
				{
					RI_ASSERT(0);	//there can't be any other references to the mipmap levels
				}
			}
		}
		m_mipmaps.clear();
		m_mipmapsValid = false;
		throw;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies color matrix filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::colorMatrix(const Image& src, const RIfloat* matrix, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(matrix);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	Color::InternalFormat srcFormat = src.m_desc.internalFormat;
	Color::InternalFormat procFormat = (Color::InternalFormat)(srcFormat & ~Color::LUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (Color::InternalFormat)(procFormat & ~Color::NONLINEAR);
	else
		procFormat = (Color::InternalFormat)(procFormat | Color::NONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (Color::InternalFormat)(procFormat | Color::PREMULTIPLIED);
	else
		procFormat = (Color::InternalFormat)(procFormat & ~Color::PREMULTIPLIED);

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color s = src.readPixel(i,j);	//convert to RGBA [0,1]
			s.convert(procFormat);

			Color d(0,0,0,0,procFormat);
			d.r = matrix[0+4*0] * s.r + matrix[0+4*1] * s.g + matrix[0+4*2] * s.b + matrix[0+4*3] * s.a + matrix[0+4*4];
			d.g = matrix[1+4*0] * s.r + matrix[1+4*1] * s.g + matrix[1+4*2] * s.b + matrix[1+4*3] * s.a + matrix[1+4*4];
			d.b = matrix[2+4*0] * s.r + matrix[2+4*1] * s.g + matrix[2+4*2] * s.b + matrix[2+4*3] * s.a + matrix[2+4*4];
			d.a = matrix[3+4*0] * s.r + matrix[3+4*1] * s.g + matrix[3+4*2] * s.b + matrix[3+4*3] * s.a + matrix[3+4*4];

			writeFilteredPixel(i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a pixel from image with tiling mode applied.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static Color readTiledPixel(int x, int y, int w, int h, VGTilingMode tilingMode, const Array<Color>& image, const Color& edge)
{
	Color s;
	if(x < 0 || x >= w || y < 0 || y >= h)
	{	//apply tiling mode
		switch(tilingMode)
		{
		case VG_TILE_FILL:
			s = edge;
			break;
		case VG_TILE_PAD:
			x = RI_INT_MIN(RI_INT_MAX(x, 0), w-1);
			y = RI_INT_MIN(RI_INT_MAX(y, 0), h-1);
			RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
			s = image[y*w+x];
			break;
		case VG_TILE_REPEAT:
			x = RI_INT_MOD(x, w);
			y = RI_INT_MOD(y, h);
			RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
			s = image[y*w+x];
			break;
		default:
			RI_ASSERT(tilingMode == VG_TILE_REFLECT);
			x = RI_INT_MOD(x, w*2);
			y = RI_INT_MOD(y, h*2);
			if(x >= w) x = w*2-1-x;
			if(y >= h) y = h*2-1-y;
			RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
			s = image[y*w+x];
			break;
		}
	}
	else
	{
		RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
		s = image[y*w+x];
	}
	return s;
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns processing format for filtering.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static Color::InternalFormat getProcessingFormat(Color::InternalFormat srcFormat, bool filterFormatLinear, bool filterFormatPremultiplied)
{
	Color::InternalFormat procFormat = (Color::InternalFormat)(srcFormat & ~Color::LUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (Color::InternalFormat)(procFormat & ~Color::NONLINEAR);
	else
		procFormat = (Color::InternalFormat)(procFormat | Color::NONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (Color::InternalFormat)(procFormat | Color::PREMULTIPLIED);
	else
		procFormat = (Color::InternalFormat)(procFormat & ~Color::PREMULTIPLIED);
	return procFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::convolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(kernel && kernelWidth > 0 && kernelHeight > 0);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	Color::InternalFormat procFormat = getProcessingFormat(src.m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	Color edge = edgeFillColor;
	edge.clamp();
	edge.convert(procFormat);

	Array<Color> tmp;
	tmp.resize(src.m_width*src.m_height);	//throws bad_alloc

	//copy source region to tmp and do conversion
	for(int j=0;j<src.m_height;j++)
	{
		for(int i=0;i<src.m_width;i++)
		{
			Color s = src.readPixel(i, j);
			s.convert(procFormat);
			tmp[j*src.m_width+i] = s;
		}
	}

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color sum(0,0,0,0,procFormat);

			for(int kj=0;kj<kernelHeight;kj++)
			{
				for(int ki=0;ki<kernelWidth;ki++)
				{
					int x = i+ki-shiftX;
					int y = j+kj-shiftY;
					Color s = readTiledPixel(x, y, src.m_width, src.m_height, tilingMode, tmp, edge);

					int kx = kernelWidth-ki-1;
					int ky = kernelHeight-kj-1;
					RI_ASSERT(kx >= 0 && kx < kernelWidth && ky >= 0 && ky < kernelHeight);

					sum += (RIfloat)kernel[kx*kernelHeight+ky] * s;
				}
			}

			sum *= scale;
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			writeFilteredPixel(i, j, sum, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies separable convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::separableConvolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(kernelX && kernelY && kernelWidth > 0 && kernelHeight > 0);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	Color::InternalFormat procFormat = getProcessingFormat(src.m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	Color edge = edgeFillColor;
	edge.clamp();
	edge.convert(procFormat);

	Array<Color> tmp;
	tmp.resize(src.m_width*src.m_height);	//throws bad_alloc

	//copy source region to tmp and do conversion
	for(int j=0;j<src.m_height;j++)
	{
		for(int i=0;i<src.m_width;i++)
		{
			Color s = src.readPixel(i, j);
			s.convert(procFormat);
			tmp[j*src.m_width+i] = s;
		}
	}

	Array<Color> tmp2;
	tmp2.resize(w*src.m_height);	//throws bad_alloc
	for(int j=0;j<src.m_height;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color sum(0,0,0,0,procFormat);
			for(int ki=0;ki<kernelWidth;ki++)
			{
				int x = i+ki-shiftX;
				Color s = readTiledPixel(x, j, src.m_width, src.m_height, tilingMode, tmp, edge);

				int kx = kernelWidth-ki-1;
				RI_ASSERT(kx >= 0 && kx < kernelWidth);

				sum += (RIfloat)kernelX[kx] * s;
			}
			tmp2[j*w+i] = sum;
		}
	}

	if(tilingMode == VG_TILE_FILL)
	{	//convolve the edge color
		Color sum(0,0,0,0,procFormat);
		for(int ki=0;ki<kernelWidth;ki++)
		{
			sum += (RIfloat)kernelX[ki] * edge;
		}
		edge = sum;
	}

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color sum(0,0,0,0,procFormat);
			for(int kj=0;kj<kernelHeight;kj++)
			{
				int y = j+kj-shiftY;
				Color s = readTiledPixel(i, y, w, src.m_height, tilingMode, tmp2, edge);

				int ky = kernelHeight-kj-1;
				RI_ASSERT(ky >= 0 && ky < kernelHeight);

				sum += (RIfloat)kernelY[ky] * s;
			}

			sum *= scale;
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			writeFilteredPixel(i, j, sum, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies Gaussian blur filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::gaussianBlur(const Image& src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, const Color& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(stdDeviationX > 0.0f && stdDeviationY > 0.0f);
	RI_ASSERT(stdDeviationX <= RI_MAX_GAUSSIAN_STD_DEVIATION && stdDeviationY <= RI_MAX_GAUSSIAN_STD_DEVIATION);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	Color::InternalFormat procFormat = getProcessingFormat(src.m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	Color edge = edgeFillColor;
	edge.clamp();
	edge.convert(procFormat);

	Array<Color> tmp;
	tmp.resize(src.m_width*src.m_height);	//throws bad_alloc

	//copy source region to tmp and do conversion
	for(int j=0;j<src.m_height;j++)
	{
		for(int i=0;i<src.m_width;i++)
		{
			Color s = src.readPixel(i, j);
			s.convert(procFormat);
			tmp[j*src.m_width+i] = s;
		}
	}

	//find a size for the kernel
	RIfloat totalWeightX = stdDeviationX*(RIfloat)sqrt(2.0f*PI);
	RIfloat totalWeightY = stdDeviationY*(RIfloat)sqrt(2.0f*PI);
	const RIfloat tolerance = 0.99f;	//use a kernel that covers 99% of the total Gaussian support

	RIfloat expScaleX = -1.0f / (2.0f*stdDeviationX*stdDeviationX);
	RIfloat expScaleY = -1.0f / (2.0f*stdDeviationY*stdDeviationY);

	int kernelWidth = 0;
	RIfloat e = 0.0f;
	RIfloat sumX = 1.0f;	//the weight of the middle entry counted already
	do
	{
		kernelWidth++;
		e = (RIfloat)exp((RIfloat)(kernelWidth * kernelWidth) * expScaleX);
		sumX += e*2.0f;	//count left&right lobes
	}
	while(sumX < tolerance*totalWeightX);

	int kernelHeight = 0;
	e = 0.0f;
	RIfloat sumY = 1.0f;	//the weight of the middle entry counted already
	do
	{
		kernelHeight++;
		e = (RIfloat)exp((RIfloat)(kernelHeight * kernelHeight) * expScaleY);
		sumY += e*2.0f;	//count left&right lobes
	}
	while(sumY < tolerance*totalWeightY);

	//make a separable kernel
	Array<RIfloat> kernelX;
	kernelX.resize(kernelWidth*2+1);
	int shiftX = kernelWidth;
	RIfloat scaleX = 0.0f;
	for(int i=0;i<kernelX.size();i++)
	{
		int x = i-shiftX;
		kernelX[i] = (RIfloat)exp((RIfloat)x*(RIfloat)x * expScaleX);
		scaleX += kernelX[i];
	}
	scaleX = 1.0f / scaleX;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

	Array<RIfloat> kernelY;
	kernelY.resize(kernelHeight*2+1);
	int shiftY = kernelHeight;
	RIfloat scaleY = 0.0f;
	for(int i=0;i<kernelY.size();i++)
	{
		int y = i-shiftY;
		kernelY[i] = (RIfloat)exp((RIfloat)y*(RIfloat)y * expScaleY);
		scaleY += kernelY[i];
	}
	scaleY = 1.0f / scaleY;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

	Array<Color> tmp2;
	tmp2.resize(w*src.m_height);	//throws bad_alloc
	//horizontal pass
	for(int j=0;j<src.m_height;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color sum(0,0,0,0,procFormat);
			for(int ki=0;ki<kernelX.size();ki++)
			{
				int x = i+ki-shiftX;
				sum += kernelX[ki] * readTiledPixel(x, j, src.m_width, src.m_height, tilingMode, tmp, edge);
			}
			tmp2[j*w+i] = sum * scaleX;
		}
	}
	//vertical pass
	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color sum(0,0,0,0,procFormat);
			for(int kj=0;kj<kernelY.size();kj++)
			{
				int y = j+kj-shiftY;
				sum += kernelY[kj] * readTiledPixel(i, y, w, src.m_height, tilingMode, tmp2, edge);
			}
			writeFilteredPixel(i, j, sum * scaleY, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns lookup table format for lookup filters.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static Color::InternalFormat getLUTFormat(bool outputLinear, bool outputPremultiplied)
{
	Color::InternalFormat lutFormat = Color::lRGBA;
	if(outputLinear && outputPremultiplied)
		lutFormat = Color::lRGBA_PRE;
	else if(!outputLinear && !outputPremultiplied)
		lutFormat = Color::sRGBA;
	else if(!outputLinear && outputPremultiplied)
		lutFormat = Color::sRGBA_PRE;
	return lutFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies multi-channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::lookup(const Image& src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(redLUT && greenLUT && blueLUT && alphaLUT);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	Color::InternalFormat procFormat = getProcessingFormat(src.m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);
	Color::InternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color s = src.readPixel(i,j);	//convert to RGBA [0,1]
			s.convert(procFormat);

			Color d(0,0,0,0,lutFormat);
			d.r = intToColor(  redLUT[colorToInt(s.r, 255)], 255);
			d.g = intToColor(greenLUT[colorToInt(s.g, 255)], 255);
			d.b = intToColor( blueLUT[colorToInt(s.b, 255)], 255);
			d.a = intToColor(alphaLUT[colorToInt(s.a, 255)], 255);

			writeFilteredPixel(i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies single channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Image::lookupSingle(const Image& src, const RIuint32 * lookupTable, VGImageChannel sourceChannel, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask)
{
	RI_ASSERT(src.m_data);	//source exists
	RI_ASSERT(m_data);	//destination exists
	RI_ASSERT(lookupTable);
	RI_ASSERT(m_referenceCount > 0 && src.m_referenceCount > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(m_width, src.m_width);
	int h = RI_INT_MIN(m_height, src.m_height);
	RI_ASSERT(w > 0 && h > 0);

	if(src.m_desc.luminanceBits)
		sourceChannel = VG_RED;
	else if(src.m_desc.redBits + src.m_desc.greenBits + src.m_desc.blueBits == 0)
	{
		RI_ASSERT(src.m_desc.alphaBits);
		sourceChannel = VG_ALPHA;
	}

	Color::InternalFormat procFormat = getProcessingFormat(src.m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);
	Color::InternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

	for(int j=0;j<h;j++)
	{
		for(int i=0;i<w;i++)
		{
			Color s = src.readPixel(i,j);	//convert to RGBA [0,1]
			s.convert(procFormat);
			int e;
			switch(sourceChannel)
			{
			case VG_RED:
				e = colorToInt(s.r, 255);
				break;
			case VG_GREEN:
				e = colorToInt(s.g, 255);
				break;
			case VG_BLUE:
				e = colorToInt(s.b, 255);
				break;
			default:
				RI_ASSERT(sourceChannel == VG_ALPHA);
				e = colorToInt(s.a, 255);
				break;
			}

			RIuint32 l = ((const RIuint32*)lookupTable)[e];
			Color d(0,0,0,0,lutFormat);
			d.r = intToColor((l>>24), 255);
			d.g = intToColor((l>>16), 255);
			d.b = intToColor((l>> 8), 255);
			d.a = intToColor((l    ), 255);

			writeFilteredPixel(i, j, d, channelMask);
		}
	}
}

//==============================================================================================

}	//namespace OpenVGRI

//==============================================================================================
