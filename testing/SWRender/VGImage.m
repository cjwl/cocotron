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
 * \brief	Implementation of VGColor and VGImage functions.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "VGImage.h"
#import "KGRasterizer.h"

#define RI_MAX_GAUSSIAN_STD_DEVIATION	128.0f

bool VGImageIsValidFormat(int f)
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

static inline RIfloat intToColor(unsigned int i, unsigned int maxi)
{
	return (RIfloat)(i & maxi) / (RIfloat)maxi;
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from packed integer in a given format to a VGColor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor VGColorUnpack(unsigned int inputData,VGColorDescriptor inputDesc) {
   VGColor result;
   
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

	result.m_format = inputDesc.internalFormat;
	if(lb)
	{	//luminance
		result.r = result.g = result.b = intToColor(inputData >> ls, (1<<lb)-1);
		result.a = 1.0f;
	}
	else
	{	//rgba
		result.r = rb ? intToColor(inputData >> rs, (1<<rb)-1) : (RIfloat)1.0f;
		result.g = gb ? intToColor(inputData >> gs, (1<<gb)-1) : (RIfloat)1.0f;
		result.b = bb ? intToColor(inputData >> bs, (1<<bb)-1) : (RIfloat)1.0f;
		result.a = ab ? intToColor(inputData >> as, (1<<ab)-1) : (RIfloat)1.0f;

		if(result.m_format & VGColorPREMULTIPLIED)
		{	//clamp premultiplied color to alpha to enforce consistency
			result.r = RI_MIN(result.r, result.a);
			result.g = RI_MIN(result.g, result.a);
			result.b = RI_MIN(result.b, result.a);
		}
	}
    return result;
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from VGColor to a packed integer in a given format.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

unsigned int VGColorPack(VGColor color,VGColorDescriptor outputDesc) {
	RI_ASSERT(color.r >= 0.0f && color.r <= 1.0f);
	RI_ASSERT(color.g >= 0.0f && color.g <= 1.0f);
	RI_ASSERT(color.b >= 0.0f && color.b <= 1.0f);
	RI_ASSERT(color.a >= 0.0f && color.a <= 1.0f);

	RI_ASSERT(!(color.m_format & VGColorPREMULTIPLIED) || (color.r <= color.a && color.g <= color.a && color.b <= color.a));	//premultiplied colors must have color channels less than or equal to alpha
	RI_ASSERT((color.m_format & VGColorLUMINANCE && color.r == color.g && color.r == color.b) || !(color.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

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
		RI_ASSERT(color.m_format & VGColorLUMINANCE);
		return colorToInt(color.r, (1<<lb)-1) << ls;
	}
	else
	{	//rgb
		RI_ASSERT(!(color.m_format & VGColorLUMINANCE));
		unsigned int cr = rb ? colorToInt(color.r, (1<<rb)-1) : 0;
		unsigned int cg = gb ? colorToInt(color.g, (1<<gb)-1) : 0;
		unsigned int cb = bb ? colorToInt(color.b, (1<<bb)-1) : 0;
		unsigned int ca = ab ? colorToInt(color.a, (1<<ab)-1) : 0;
		return (cr << rs) | (cg << gs) | (cb << bs) | (ca << as);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Converts from the current internal format to another.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

// Can't use 'gamma' ?
static RIfloat dogamma(RIfloat c)
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

VGColor VGColorConvert(VGColor result,VGColorInternalFormat outputFormat){
	RI_ASSERT(result.r >= 0.0f && result.r <= 1.0f);
	RI_ASSERT(result.g >= 0.0f && result.g <= 1.0f);
	RI_ASSERT(result.b >= 0.0f && result.b <= 1.0f);
	RI_ASSERT(result.a >= 0.0f && result.a <= 1.0f);
	RI_ASSERT((result.m_format & VGColorLUMINANCE && result.r == result.g && result.r == result.b) || !(result.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

	if( result.m_format == outputFormat )
		return result;

	if(result.m_format & VGColorPREMULTIPLIED)
	{	//unpremultiply
		RI_ASSERT(result.r <= result.a);
		RI_ASSERT(result.g <= result.a);
		RI_ASSERT(result.b <= result.a);
		RIfloat ooa = (result.a != 0.0f) ? 1.0f / result.a : (RIfloat)0.0f;
		result.r *= ooa;
		result.g *= ooa;
		result.b *= ooa;
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
	unsigned int conversion = (result.m_format & (VGColorNONLINEAR | VGColorLUMINANCE)) | ((outputFormat & (VGColorNONLINEAR | VGColorLUMINANCE)) << shift);

	switch(conversion)
	{
	case VGColor_lRGBA | (VGColor_sRGBA << shift): result.r = dogamma(result.r); result.g = dogamma(result.g); result.b = dogamma(result.b); break;							//1
	case VGColor_lRGBA | (VGColor_lLA << shift)  : result.r = result.g = result.b = lRGBtoL(result.r, result.g, result.b); break;										//3
	case VGColor_lRGBA | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(lRGBtoL(result.r, result.g, result.b)); break;								//3,5
	case VGColor_sRGBA | (VGColor_lRGBA << shift): result.r = invgamma(result.r); result.g = invgamma(result.g); result.b = invgamma(result.b); break;				//2
	case VGColor_sRGBA | (VGColor_lLA << shift)  : result.r = result.g = result.b = lRGBtoL(invgamma(result.r), invgamma(result.g), invgamma(result.b)); break;		//2,3
	case VGColor_sRGBA | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(lRGBtoL(invgamma(result.r), invgamma(result.g), invgamma(result.b))); break;//2,3,5
	case VGColor_lLA   | (VGColor_lRGBA << shift): break;																	//4
	case VGColor_lLA   | (VGColor_sRGBA << shift): result.r = result.g = result.b = dogamma(result.r); break;												//4,1
	case VGColor_lLA   | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(result.r); break;												//5
	case VGColor_sLA   | (VGColor_lRGBA << shift): result.r = result.g = result.b = invgamma(result.r); break;											//7,2
	case VGColor_sLA   | (VGColor_sRGBA << shift): break;																	//7
	case VGColor_sLA   | (VGColor_lLA << shift)  : result.r = result.g = result.b = invgamma(result.r); break;											//6
	default: RI_ASSERT((result.m_format & (VGColorLUMINANCE | VGColorNONLINEAR)) == (outputFormat & (VGColorLUMINANCE | VGColorNONLINEAR))); break;	//nop
	}

	if(outputFormat & VGColorPREMULTIPLIED)
	{	//premultiply
		result.r *= result.a;
		result.g *= result.a;
		result.b *= result.a;
		RI_ASSERT(result.r <= result.a);
		RI_ASSERT(result.g <= result.a);
		RI_ASSERT(result.b <= result.a);
	}
	result.m_format = outputFormat;
    return result;
}

/*-------------------------------------------------------------------*//*!
* \brief	Creates a pixel format descriptor out of VGImageFormat
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColorDescriptor VGColorFormatToDescriptor(VGImageFormat format)
{
	VGColorDescriptor desc;
	memset(&desc, 0, sizeof(VGColorDescriptor));
	RI_ASSERT(VGImageIsValidFormat(format));

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

	static const VGColorInternalFormat internalFormats[13] = {VGColor_sRGBA, VGColor_sRGBA, VGColor_sRGBA_PRE, VGColor_sRGBA, VGColor_sRGBA, VGColor_sRGBA, VGColor_sLA, VGColor_lRGBA, VGColor_lRGBA, VGColor_lRGBA_PRE, VGColor_lLA, VGColor_lRGBA, VGColor_lLA};

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

bool VGColorIsValidDescriptor(VGColorDescriptor desc)
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
		if(!VGImageIsValidFormat(desc.format))
			return false;	//invalid image format

		VGColorDescriptor d = VGColorFormatToDescriptor(desc.format);
		if(d.redBits != rb || d.greenBits != gb || d.blueBits != bb || d.alphaBits != ab || d.luminanceBits != lb ||
		   d.redShift != rs || d.greenShift != gs || d.blueShift != bs || d.alphaShift != as || d.luminanceShift != ls ||
		   d.bitsPerPixel != bpp)
		   return false;	//if the descriptor has a VGImageFormat, it must match the bits, shifts, and bpp
	}

	if((unsigned int)desc.internalFormat & ~(VGColorPREMULTIPLIED | VGColorNONLINEAR | VGColorLUMINANCE))
		return false;	//invalid internal format

	return true;
}

//==============================================================================================




//==============================================================================================

VGImage *VGImageAlloc() {
   return (VGImage *)NSZoneCalloc(NULL,1,sizeof(VGImage));
}

/*-------------------------------------------------------------------*//*!
* \brief	Constructs a blank image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGImage *VGImageInit(VGImage *self,VGColorDescriptor desc, int width, int height){	//throws bad_alloc
	self->m_desc=desc;
	self->m_width=width;
	self->m_height=height;
	self->m_stride=0;
	self->m_data=NULL;
	self->m_bitOffset=0;
	self->m_ownsData=true;
	self->m_mipmapsValid=false;

	RI_ASSERT(VGColorIsValidDescriptor(self->m_desc));
	RI_ASSERT(width > 0 && height > 0);
	
	if( self->m_desc.bitsPerPixel != 1 )
	{
		RI_ASSERT(self->m_desc.bitsPerPixel == 8 || self->m_desc.bitsPerPixel == 16 || self->m_desc.bitsPerPixel == 32);
		self->m_stride = self->m_width*self->m_desc.bitsPerPixel/8;
	}
	else
	{
		RI_ASSERT(self->m_desc.bitsPerPixel == 1);
		self->m_stride = (self->m_width+7)/8;
	}
	self->m_data = NSZoneMalloc(NULL,self->m_stride*self->m_height*sizeof(RIuint8));
	memset(self->m_data, 0, self->m_stride*self->m_height);	//clear image
    self->_mipmapsCount=0;
    self->_mipmapsCapacity=2;
    self->_mipmaps=(VGImage **)NSZoneMalloc(NULL,self->_mipmapsCapacity*sizeof(VGImage *));
    return self;
}

/*-------------------------------------------------------------------*//*!
* \brief	Constructs an image that uses an external array for its data
*			storage.
* \param	
* \return	
* \note		this is meant for internal use to make blitting easier
*//*-------------------------------------------------------------------*/

VGImage *VGImageInitWithBytes(VGImage *self,VGColorDescriptor desc, int width, int height, int stride, RIuint8* data) {	//throws bad_alloc
	self->m_desc=desc;
	self->m_width=width;
	self->m_height=height;
	self->m_stride=stride;
	self->m_data=data;
	self->m_bitOffset=0;
	self->m_ownsData=false;
	self->m_mipmapsValid=false;
	RI_ASSERT(VGColorIsValidDescriptor(self->m_desc));
	RI_ASSERT(width > 0 && height > 0);
	RI_ASSERT(data);
    self->_mipmapsCount=0;
    self->_mipmapsCapacity=2;
    self->_mipmaps=(VGImage **)NSZoneMalloc(NULL,self->_mipmapsCapacity*sizeof(VGImage *));
    return self;
}

/*-------------------------------------------------------------------*//*!
* \brief	VGImage destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageDealloc(VGImage *self) {
    int i;
    
	for(i=0;i<self->_mipmapsCount;i++){
			VGImageDealloc(self->_mipmaps[i]);
	}
	self->_mipmapsCount=0;

	if(self->m_ownsData)
	{
		NSZoneFree(NULL,self->m_data);	//delete image data if we own it
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Resizes an image. New pixels are set to the given color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageResize(VGImage *self,int newWidth, int newHeight, VGColor newPixelColor){
	RI_ASSERT(newWidth > 0 && newHeight > 0);
	RI_ASSERT(self->m_bitOffset == 0);	//we don't have to worry about bitOffset in this function (this is always the original image, not a child)

	//destroy mipmaps
    int i;
	for(i=0;i<self->_mipmapsCount;i++)
	{
			VGImageDealloc(self->_mipmaps[i]);
	}
	self->_mipmapsCount=0;
	self->m_mipmapsValid = false;
	
	int newStride;
	if( self->m_desc.bitsPerPixel != 1 )
	{
		RI_ASSERT(self->m_desc.bitsPerPixel == 8 || self->m_desc.bitsPerPixel == 16 || self->m_desc.bitsPerPixel == 32);
		newStride = newWidth*self->m_desc.bitsPerPixel/8;
	}
	else
	{
		RI_ASSERT(self->m_desc.bitsPerPixel == 1);
		newStride = (newWidth+7)/8;
	}

	RIuint8* newData = NSZoneMalloc(NULL,sizeof(RIuint8)*newStride*newHeight);

	VGColor col = newPixelColor;
	col=VGColorClamp(col);
	col=VGColorConvert(col,self->m_desc.internalFormat);
	unsigned int c = VGColorPack(col,self->m_desc);

	int w = RI_INT_MIN(self->m_width, newWidth);
    int j;
	for(j=0;j<newHeight;j++)
	{
		if(j >= self->m_height)
			w = 0;		//clear new scanlines
		RIuint8* d = newData + j * newStride;
		RIuint8* s = self->m_data + j * self->m_stride;
		switch(self->m_desc.bitsPerPixel)
		{
		case 32:
		{
			for(i=0;i<w;i++)
			{
				*(RIuint32*)d = *(RIuint32*)s;	//copy old pixels
				d += 4; s += 4;
			}
			for(i=w;i<newWidth;i++)
			{
				*(RIuint32*)d = (RIuint32)c;	//clear new pixels
				d += 4;
			}
			break;
		}

		case 16:
		{
			for(i=0;i<w;i++)
			{
				*(RIuint16*)d = *(RIuint16*)s;	//copy old pixels
				d += 2; s += 2;
			}
			for(i=w;i<newWidth;i++)
			{
				*(RIuint16*)d = (RIuint16)c;	//clear new pixels
				d += 2;
			}
			break;
		}

		case 8:
		{
			for(i=0;i<w;i++)
				*d++ = *s++;	//copy old pixels
			for(i=w;i<newWidth;i++)
				*d++ = (RIuint8)c;	//clear new pixels
			break;
		}

		default:
		{
			RI_ASSERT(self->m_desc.bitsPerPixel == 1);
			if( c )
				c = 0xff;
			int e = w>>3;	//number of full bytes
			for(i=0;i<e;i++)
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

			for(i=e;i<((newWidth+7)>>3);i++)
				*d++ = (RIuint8)c;	//clear new pixels
			break;
		}
		}
	}

	NSZoneFree(NULL,self->m_data);
	self->m_data = newData;
	self->m_width = newWidth;
	self->m_height = newHeight;
	self->m_stride = newStride;
}

/*-------------------------------------------------------------------*//*!
* \brief	Clears a rectangular portion of an image with the given clear color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageClear(VGImage *self,VGColor clearColor, int x, int y, int w, int h){
	RI_ASSERT(self->m_data);

	//intersect clear region with image bounds
	KGIntRect r=KGIntRectInit(0,0,self->m_width,self->m_height);
	r=KGIntRectIntersect(r,KGIntRectInit(x,y,w,h));
	if(!r.width || !r.height)
		return;		//intersection is empty or one of the rectangles is invalid

	VGColor col = clearColor;
	col=VGColorClamp(col);
	col=VGColorConvert(col,self->m_desc.internalFormat);

    int j;
	for(j=r.y;j<r.y + r.height;j++)
	{
        int i;
		for(i=r.x;i<r.x + r.width;i++)
		{
			VGImageWritePixel(self,i, j, col);
		}
	}

	self->m_mipmapsValid = false;
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

void VGImageBlit(VGImage *self,VGImage * src, int sx, int sy, int dx, int dy, int w, int h, bool dither) {
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(w > 0 && h > 0);

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
	if(dstex > self->m_width)
	{
		srcex -= dstex - self->m_width;
		dstex = self->m_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src->m_width && dstex <= self->m_width);
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
	if(dstey > self->m_height)
	{
		srcey -= dstey - self->m_height;
		dstey = self->m_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src->m_height && dstey <= self->m_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,w*h*sizeof(VGColor));

	//copy source region to tmp
    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor c = VGImageReadPixel(src,srcsx + i, srcsy + j);
			c=VGColorConvert(c,self->m_desc.internalFormat);
			tmp[j*w+i] = c;
		}
	}

	int rbits = self->m_desc.redBits, gbits = self->m_desc.greenBits, bbits = self->m_desc.blueBits, abits = self->m_desc.alphaBits;
	if(self->m_desc.luminanceBits)
	{
		rbits = gbits = bbits = self->m_desc.luminanceBits;
		abits = 0;
	}

	//write tmp to destination region
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor col = tmp[j*w+i];

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

			VGImageWritePixel(self,dstsx + i, dstsy + j, col);
		}
	}
    NSZoneFree(NULL,tmp);
	self->m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies a mask operation to a rectangular portion of a mask image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageMask(VGImage *self,VGImage* src, VGMaskOperation operation, int x, int y, int w, int h) {
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(w > 0 && h > 0);

	self->m_mipmapsValid = false;
	if(operation == VG_CLEAR_MASK)
	{
		VGImageClear(self,VGColorRGBA(0,0,0,0,VGColor_lRGBA), x, y, w, h);
		return;
	}
	if(operation == VG_FILL_MASK)
	{
		VGImageClear(self,VGColorRGBA(1,1,1,1,VGColor_lRGBA), x, y, w, h);
		return;
	}

	RI_ASSERT(src->m_data);	//source exists

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
	if(dstex > self->m_width)
	{
		srcex -= dstex - self->m_width;
		dstex = self->m_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src->m_width && dstex <= self->m_width);
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
	if(dstey > self->m_height)
	{
		srcey -= dstey - self->m_height;
		dstey = self->m_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src->m_height && dstey <= self->m_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			RIfloat aprev = VGImageReadMaskPixel(self,dstsx + i, dstsy + j);
			RIfloat amask = VGImageReadMaskPixel(src,srcsx + i, srcsy + j);
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
			VGImageWriteMaskPixel(self,dstsx + i, dstsy + j, anew);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns the color at pixel (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor VGImageReadPixel(VGImage *self,int x, int y) {
	RI_ASSERT(self->m_data);
	RI_ASSERT(x >= 0 && x < self->m_width);
	RI_ASSERT(y >= 0 && y < self->m_height);
       
	unsigned int p = 0;
	RIuint8* scanline = self->m_data + y * self->m_stride;
	switch(self->m_desc.bitsPerPixel)
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
		RI_ASSERT(self->m_desc.bitsPerPixel == 1);
		x += self->m_bitOffset;
		RIuint8* s = scanline + (x>>3);
		p = (((unsigned int)*s) >> (x&7)) & 1u;
		break;
	}
	}
	return VGColorUnpack(p, self->m_desc);
 }

/*-------------------------------------------------------------------*//*!
* \brief	Writes the color to pixel (x,y). Internal color formats must
*			match.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageWritePixel(VGImage *self,int x, int y, VGColor c) {
	RI_ASSERT(self->m_data);
	RI_ASSERT(x >= 0 && x < self->m_width);
	RI_ASSERT(y >= 0 && y < self->m_height);
	RI_ASSERT(c.m_format == self->m_desc.internalFormat);

	unsigned int p = VGColorPack(c,self->m_desc);
	RIuint8* scanline = self->m_data + y * self->m_stride;
	switch(self->m_desc.bitsPerPixel)
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
		RI_ASSERT(self->m_desc.bitsPerPixel == 1);
		x += self->m_bitOffset;
		RIuint8* s = scanline + (x>>3);
		RIuint8 d = *s;
		d &= ~(1<<(x&7));
		d |= (RIuint8)(p<<(x&7));
		*s = d;
		break;
	}
	}
	self->m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes a filtered color to destination surface
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageWriteFilteredPixel(VGImage *self,int i, int j, VGColor color, VGbitfield channelMask) {
	//section 3.4.4: before color space conversion, premultiplied colors are
	//clamped to alpha, and the color is converted to nonpremultiplied format
	//section 11.2: how to deal with channel mask
	//step 1
	VGColor f = color;
	f=VGColorClamp(f);			//vgColorMatrix and vgLookups can produce colors that exceed alpha or [0,1] range
	f=VGColorUnpremultiply(f);

	//step 2: color space conversion
	f=VGColorConvert(f,(VGColorInternalFormat)(self->m_desc.internalFormat & (VGColorNONLINEAR | VGColorLUMINANCE)));

	//step 3: read the destination color and convert it to nonpremultiplied
	VGColor d = VGImageReadPixel(self,i,j);
	d=VGColorUnpremultiply(d);
	RI_ASSERT(d.m_format == f.m_format);

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
	if(self->m_desc.internalFormat & VGColorPREMULTIPLIED)
		d=VGColorPremultiply(d);
	//write the color to destination
	VGImageWritePixel(self,i,j,d);
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads the pixel (x,y) and converts it into an alpha mask value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

RIfloat VGImageReadMaskPixel(VGImage *self,int x, int y){
	RI_ASSERT(self->m_data);
	RI_ASSERT(x >= 0 && x < self->m_width);
	RI_ASSERT(y >= 0 && y < self->m_height);

	VGColor c = VGImageReadPixel(self,x,y);
	if(self->m_desc.luminanceBits)
	{	//luminance
		return c.r;	//luminance/luma is read into the color channels
	}
	else
	{	//rgba
		if(self->m_desc.alphaBits)
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

void VGImageWriteMaskPixel(VGImage *self,int x, int y, RIfloat m)	//can write only to VG_A_8
{
	RI_ASSERT(self->m_data);
	RI_ASSERT(x >= 0 && x < self->m_width);
	RI_ASSERT(y >= 0 && y < self->m_height);
	RI_ASSERT(self->m_desc.alphaBits == 8 && self->m_desc.redBits == 0 && self->m_desc.greenBits == 0 && self->m_desc.blueBits == 0 && self->m_desc.luminanceBits == 0 && self->m_desc.bitsPerPixel == 8);

	RIuint8* s = ((RIuint8*)(self->m_data + y * self->m_stride)) + x;
	*s = (RIuint8)colorToInt(m, 255);
	self->m_mipmapsValid = false;
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a texel (u,v) at the given mipmap level. Tiling modes and
*			color space conversion are applied. Outputs color in premultiplied
*			format.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor VGImageReadTexel(VGImage *self,int u, int v, int level, VGTilingMode tilingMode, VGColor tileFillColor){
	VGImage* image = self;
	if( level > 0 )
	{
		RI_ASSERT(level <= self->_mipmapsCount);
		image = self->_mipmaps[level-1];
	}
	RI_ASSERT(image);

	VGColor p=VGColorZero();
	if(tilingMode == VG_TILE_FILL)
	{
		if(u < 0 || v < 0 || u >= image->m_width || v >= image->m_height)
			p = tileFillColor;
		else
			p = VGImageReadPixel(image,u, v);
	}
	else if(tilingMode == VG_TILE_PAD)
	{
		u = RI_INT_MIN(RI_INT_MAX(u,0),image->m_width-1);
		v = RI_INT_MIN(RI_INT_MAX(v,0),image->m_height-1);
		p = VGImageReadPixel(image,u, v);
	}
	else if(tilingMode == VG_TILE_REPEAT)
	{
		u = RI_INT_MOD(u, image->m_width);
		v = RI_INT_MOD(v, image->m_height);
		p = VGImageReadPixel(image,u, v);
	}
	else
	{
		RI_ASSERT(tilingMode == VG_TILE_REFLECT);

		u = RI_INT_MOD(u, image->m_width*2);
		v = RI_INT_MOD(v, image->m_height*2);
		if( u >= image->m_width ) u = image->m_width*2-1 - u;
		if( v >= image->m_height ) v = image->m_height*2-1 - v;
		p = VGImageReadPixel(image,u, v);
	}

	p=VGColorPremultiply(p);

	return p;
}

/*-------------------------------------------------------------------*//*!
* \brief	Maps point (x,y) to an image and returns a filtered,
*			premultiplied color value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor VGImageResample(VGImage *self,RIfloat x, RIfloat y, Matrix3x3 surfaceToImage, CGInterpolationQuality quality, VGTilingMode tilingMode, VGColor tileFillColor)	//throws bad_alloc
{
	Vector3 uvw=Vector3Make(x,y,1);
	uvw = Matrix3x3MultiplyVector3(surfaceToImage ,uvw);
	RIfloat oow = 1.0f / uvw.z;
	uvw=Vector3MultiplyByFloat(uvw,oow);

	if(quality== kCGInterpolationHigh)
	{	//EWA on mipmaps
		VGImageMakeMipMaps(self);	//throws bad_alloc

		VGColorInternalFormat procFormat = (VGColorInternalFormat)(self->m_desc.internalFormat | VGColorPREMULTIPLIED);

		RIfloat m_pixelFilterRadius = 1.25f;
		RIfloat m_resamplingFilterRadius = 1.25f;

		RIfloat Ux = (surfaceToImage.matrix[0][0] - uvw.x * surfaceToImage.matrix[2][0]) * oow * m_pixelFilterRadius;
		RIfloat Vx = (surfaceToImage.matrix[1][0] - uvw.y * surfaceToImage.matrix[2][0]) * oow * m_pixelFilterRadius;
		RIfloat Uy = (surfaceToImage.matrix[0][1] - uvw.x * surfaceToImage.matrix[2][1]) * oow * m_pixelFilterRadius;
		RIfloat Vy = (surfaceToImage.matrix[1][1] - uvw.y * surfaceToImage.matrix[2][1]) * oow * m_pixelFilterRadius;
		RIfloat U0 = uvw.x;
		RIfloat V0 = uvw.y;

		//calculate mip level
		int level = 0;
		RIfloat axis1sq = Ux*Ux + Vx*Vx;
		RIfloat axis2sq = Uy*Uy + Vy*Vy;
		RIfloat minorAxissq = RI_MIN(axis1sq,axis2sq);
		while(minorAxissq > 9.0f && level < self->_mipmapsCount)	//half the minor axis must be at least three texels
		{
			level++;
			minorAxissq *= 0.25f;
		}

		RIfloat sx = 1.0f;
		RIfloat sy = 1.0f;
		if(level > 0)
		{
			sx = (RIfloat)self->_mipmaps[level-1]->m_width / (RIfloat)self->m_width;
			sy = (RIfloat)self->_mipmaps[level-1]->m_height / (RIfloat)self->m_height;
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
			return VGColorRGBA(0,0,0,0,procFormat);

		//scale the filter so that Q = 1 at the cutoff radius
		RIfloat F = A*C - 0.25f * B*B;
		if( F <= 0.0f )
			return VGColorRGBA(0,0,0,0,procFormat);	//invalid filter shape due to numerical inaccuracies => return black
		RIfloat ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;
		
		//evaluate filter by using forward differences to calculate Q = A*U^2 + B*U*V + C*V^2
		VGColor color=VGColorRGBA(0,0,0,0,procFormat);
		RIfloat sumweight = 0.0f;
		RIfloat DDQ = 2.0f * A;
		RIfloat U = (RIfloat)u1 - U0 + 0.5f;
        int v;
		for(v=v1;v<v2;v++)
		{
			RIfloat V = (RIfloat)v - V0 + 0.5f;
			RIfloat DQ = A*(2.0f*U+1.0f) + B*V;
			RIfloat Q = (C*V+B*U)*V + A*U*U;
            int u;
			for(u=u1;u<u2;u++)
			{
				if( Q >= 0.0f && Q < 1.0f )
				{	//Q = r^2, fit gaussian to the range [0,1]
					RIfloat weight = (RIfloat)exp(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
					color=VGColorAdd(color,  VGColorMultiplyByFloat(VGImageReadTexel(self,u, v, level, tilingMode, tileFillColor),weight));
					sumweight += weight;
				}
				Q += DQ;
				DQ += DDQ;
			}
		}
		if( sumweight == 0.0f )
			return VGColorRGBA(0,0,0,0,procFormat);
		RI_ASSERT(sumweight > 0.0f);
		sumweight = 1.0f / sumweight;
		return VGColorMultiplyByFloat(color,sumweight);
	}
	else if(quality== kCGInterpolationLow)
	{	//bilinear
		uvw.x -= 0.5f;
		uvw.y -= 0.5f;
		int u = (int)floor(uvw.x);
		int v = (int)floor(uvw.y);
		VGColor c00 = VGImageReadTexel(self,u,v, 0, tilingMode, tileFillColor);
		VGColor c10 = VGImageReadTexel(self,u+1,v, 0, tilingMode, tileFillColor);
		VGColor c01 = VGImageReadTexel(self,u,v+1, 0, tilingMode, tileFillColor);
		VGColor c11 = VGImageReadTexel(self,u+1,v+1, 0, tilingMode, tileFillColor);
		RIfloat fu = uvw.x - (RIfloat)u;
		RIfloat fv = uvw.y - (RIfloat)v;
		VGColor c0 = VGColorAdd(VGColorMultiplyByFloat(c00,(1.0f - fu)),VGColorMultiplyByFloat(c10,fu));
		VGColor c1 = VGColorAdd(VGColorMultiplyByFloat(c01,(1.0f - fu)),VGColorMultiplyByFloat(c11,fu));
		return VGColorAdd(VGColorMultiplyByFloat(c0,(1.0f - fv)),VGColorMultiplyByFloat(c1, fv));
	}
	else
	{	//point sampling
		return VGImageReadTexel(self,(int)floor(uvw.x), (int)floor(uvw.y), 0, tilingMode, tileFillColor);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generates mip maps for an image.
* \param	
* \return	
* \note		Downsampling is done in the input color space. We use a box
*			filter for downsampling.
*//*-------------------------------------------------------------------*/

void VGImageMakeMipMaps(VGImage *self) {
	RI_ASSERT(self->m_data);

	if(self->m_mipmapsValid)
		return;

	//delete existing mipmaps
    int i;
	for(i=0;i<self->_mipmapsCount;i++)
	{
			VGImageDealloc(self->_mipmaps[i]);
	}
	self->_mipmapsCount=0;

//	try
	{
		VGColorInternalFormat procFormat = self->m_desc.internalFormat;
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);	//premultiplied

		//generate mipmaps until width and height are one
		VGImage* prev = self;
		while( prev->m_width > 1 || prev->m_height > 1 )
		{
			int nextw = (int)ceil(prev->m_width*0.5f);
			int nexth = (int)ceil(prev->m_height*0.5f);
			RI_ASSERT(nextw >= 1 && nexth >= 1);
			RI_ASSERT(nextw < prev->m_width || nexth < prev->m_height);

            if(self->_mipmapsCount+1>self->_mipmapsCapacity){
             self->_mipmapsCapacity*=2;
             self->_mipmaps=(VGImage **)NSZoneRealloc(NULL,self->_mipmaps,sizeof(VGImage *)*self->_mipmapsCapacity);
            }
            self->_mipmapsCount++;
			self->_mipmaps[self->_mipmapsCount-1] = NULL;

			VGImage* next =  VGImageInit(VGImageAlloc(),self->m_desc, nextw, nexth);	//throws bad_alloc
            int j;
			for(j=0;j<next->m_height;j++)
			{
				for(i=0;i<next->m_width;i++)
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

					VGColor c=VGColorRGBA(0,0,0,0,procFormat);
					int samples = 0;
                    int y;
					for(y=sv;y<ev;y++)
					{
                        int x;
						for(x=su;x<eu;x++)
						{
							VGColor p = VGImageReadPixel(prev,x, y);
							p=VGColorConvert(p,procFormat);
							c=VGColorAdd(c, p);
							samples++;
						}
					}
					c=VGColorMultiplyByFloat(c,(1.0f/samples));
					c=VGColorConvert(c,self->m_desc.internalFormat);
					VGImageWritePixel(next,i,j,c);
				}
			}
			self->_mipmaps[self->_mipmapsCount-1] = next;
			prev = next;
		}
		RI_ASSERT(prev->m_width == 1 && prev->m_height == 1);
		self->m_mipmapsValid = true;
	}
#if 0
	catch(std::bad_alloc)
	{
		//delete existing mipmaps
		for(int i=0;i<self->_mipmapsCount;i++)
		{
			if(self->_mipmaps[i])
			{
					VGImageDealloc(self->_mipmaps[i]);
			}
		}
		self->_mipmapsCount=0;
		self->m_mipmapsValid = false;
		throw;
	}
#endif
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies color matrix filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageColorMatrix(VGImage *self,VGImage * src, const RIfloat* matrix, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(matrix);

	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat srcFormat = src->m_desc.internalFormat;
	VGColorInternalFormat procFormat = (VGColorInternalFormat)(srcFormat & ~VGColorLUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorNONLINEAR);
	else
		procFormat = (VGColorInternalFormat)(procFormat | VGColorNONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);
	else
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorPREMULTIPLIED);

    int j,i;
	for(j=0;j<h;j++)
	{
		for(i=0;i<w;i++)
		{
			VGColor s = VGImageReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,procFormat);
			d.r = matrix[0+4*0] * s.r + matrix[0+4*1] * s.g + matrix[0+4*2] * s.b + matrix[0+4*3] * s.a + matrix[0+4*4];
			d.g = matrix[1+4*0] * s.r + matrix[1+4*1] * s.g + matrix[1+4*2] * s.b + matrix[1+4*3] * s.a + matrix[1+4*4];
			d.b = matrix[2+4*0] * s.r + matrix[2+4*1] * s.g + matrix[2+4*2] * s.b + matrix[2+4*3] * s.a + matrix[2+4*4];
			d.a = matrix[3+4*0] * s.r + matrix[3+4*1] * s.g + matrix[3+4*2] * s.b + matrix[3+4*3] * s.a + matrix[3+4*4];

			VGImageWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a pixel from image with tiling mode applied.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColor readTiledPixel(int x, int y, int w, int h, VGTilingMode tilingMode,VGColor *image, VGColor edge)
{
	VGColor s=VGColorZero();
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

static VGColorInternalFormat getProcessingFormat(VGColorInternalFormat srcFormat, bool filterFormatLinear, bool filterFormatPremultiplied)
{
	VGColorInternalFormat procFormat = (VGColorInternalFormat)(srcFormat & ~VGColorLUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorNONLINEAR);
	else
		procFormat = (VGColorInternalFormat)(procFormat | VGColorNONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);
	else
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorPREMULTIPLIED);
	return procFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageConvolve(VGImage *self,VGImage * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(kernel && kernelWidth > 0 && kernelHeight > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	VGColor edge = edgeFillColor;
	edge=VGColorClamp(edge);
	edge=VGColorConvert(edge,procFormat);

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,src->m_width*src->m_height*sizeof(VGColor));

	//copy source region to tmp and do conversion
    int j;
	for(j=0;j<src->m_height;j++)
	{
        int i;
		for(i=0;i<src->m_width;i++)
		{
			VGColor s = VGImageReadPixel(src,i, j);
			s=VGColorConvert(s,procFormat);
			tmp[j*src->m_width+i] = s;
		}
	}

	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int kj;
			for(kj=0;kj<kernelHeight;kj++)
			{
                int ki;
				for(ki=0;ki<kernelWidth;ki++)
				{
					int x = i+ki-shiftX;
					int y = j+kj-shiftY;
					VGColor s = readTiledPixel(x, y, src->m_width, src->m_height, tilingMode, tmp, edge);

					int kx = kernelWidth-ki-1;
					int ky = kernelHeight-kj-1;
					RI_ASSERT(kx >= 0 && kx < kernelWidth && ky >= 0 && ky < kernelHeight);

					sum=VGColorAdd(sum, VGColorMultiplyByFloat(s,(RIfloat)kernel[kx*kernelHeight+ky]));
				}
			}

			sum=VGColorMultiplyByFloat(sum ,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			VGImageWriteFilteredPixel(self,i, j, sum, channelMask);
		}
	}
    NSZoneFree(NULL,tmp);
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies separable convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageSeparableConvolve(VGImage *self,VGImage * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(kernelX && kernelY && kernelWidth > 0 && kernelHeight > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	VGColor edge = edgeFillColor;
	edge=VGColorClamp(edge);
	edge=VGColorConvert(edge,procFormat);

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,src->m_width*src->m_height*sizeof(VGColor));

	//copy source region to tmp and do conversion
    int j;
	for(j=0;j<src->m_height;j++)
	{
        int i;
		for(i=0;i<src->m_width;i++)
		{
			VGColor s = VGImageReadPixel(src,i, j);
			s=VGColorConvert(s,procFormat);
			tmp[j*src->m_width+i] = s;
		}
	}

	VGColor *tmp2=(VGColor *)NSZoneMalloc(NULL,w*src->m_height*sizeof(VGColor));

	for(j=0;j<src->m_height;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int ki;
            
			for(ki=0;ki<kernelWidth;ki++)
			{
				int x = i+ki-shiftX;
				VGColor s = readTiledPixel(x, j, src->m_width, src->m_height, tilingMode, tmp, edge);

				int kx = kernelWidth-ki-1;
				RI_ASSERT(kx >= 0 && kx < kernelWidth);

				sum=VGColorAdd(sum , VGColorMultiplyByFloat(s,(RIfloat)kernelX[kx])) ;
			}
			tmp2[j*w+i] = sum;
		}
	}

	if(tilingMode == VG_TILE_FILL)
	{	//convolve the edge color
		VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
        int ki;
		for(ki=0;ki<kernelWidth;ki++)
		{
			sum=VGColorAdd(sum, VGColorMultiplyByFloat(edge, (RIfloat)kernelX[ki]));
		}
		edge = sum;
	}

	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int kj;
			for(kj=0;kj<kernelHeight;kj++)
			{
				int y = j+kj-shiftY;
				VGColor s = readTiledPixel(i, y, w, src->m_height, tilingMode, tmp2, edge);

				int ky = kernelHeight-kj-1;
				RI_ASSERT(ky >= 0 && ky < kernelHeight);

				sum=VGColorAdd(sum, VGColorMultiplyByFloat(s, (RIfloat)kernelY[ky]));
			}

			sum=VGColorMultiplyByFloat(sum,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			VGImageWriteFilteredPixel(self,i, j, sum, channelMask);
		}
	}
    NSZoneFree(NULL,tmp);
    NSZoneFree(NULL,tmp2);
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies Gaussian blur filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageGaussianBlur(VGImage *self,VGImage * src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask){
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(stdDeviationX > 0.0f && stdDeviationY > 0.0f);
	RI_ASSERT(stdDeviationX <= RI_MAX_GAUSSIAN_STD_DEVIATION && stdDeviationY <= RI_MAX_GAUSSIAN_STD_DEVIATION);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);

	VGColor edge = edgeFillColor;
	edge=VGColorClamp(edge);
	edge=VGColorConvert(edge,procFormat);

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,src->m_width*src->m_height*sizeof(VGColor));

	//copy source region to tmp and do conversion
    int j;
	for(j=0;j<src->m_height;j++)
	{
        int i;
		for(i=0;i<src->m_width;i++)
		{
			VGColor s = VGImageReadPixel(src,i, j);
			s=VGColorConvert(s,procFormat);
			tmp[j*src->m_width+i] = s;
		}
	}

	//find a size for the kernel
	RIfloat totalWeightX = stdDeviationX*(RIfloat)sqrt(2.0f*M_PI);
	RIfloat totalWeightY = stdDeviationY*(RIfloat)sqrt(2.0f*M_PI);
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
    int kernelXSize=kernelWidth*2+1;
	RIfloat kernelX[kernelXSize];
	int shiftX = kernelWidth;
	RIfloat scaleX = 0.0f;
    int i;
	for(i=0;i<kernelXSize;i++)
	{
		int x = i-shiftX;
		kernelX[i] = (RIfloat)exp((RIfloat)x*(RIfloat)x * expScaleX);
		scaleX += kernelX[i];
	}
	scaleX = 1.0f / scaleX;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

    int kernelYSize=kernelHeight*2+1;
	RIfloat kernelY[kernelYSize];
	int shiftY = kernelHeight;
	RIfloat scaleY = 0.0f;
	for(i=0;i<kernelYSize;i++)
	{
		int y = i-shiftY;
		kernelY[i] = (RIfloat)exp((RIfloat)y*(RIfloat)y * expScaleY);
		scaleY += kernelY[i];
	}
	scaleY = 1.0f / scaleY;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

	VGColor *tmp2=(VGColor *)NSZoneMalloc(NULL,w*src->m_height*sizeof(VGColor));

	//horizontal pass
	for(j=0;j<src->m_height;j++)
	{
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int ki;
			for(ki=0;ki<kernelXSize;ki++)
			{
				int x = i+ki-shiftX;
				sum=VGColorAdd(sum, VGColorMultiplyByFloat(readTiledPixel(x, j, src->m_width, src->m_height, tilingMode, tmp, edge),kernelX[ki]));
			}
			tmp2[j*w+i] = VGColorMultiplyByFloat(sum, scaleX);
		}
	}
	//vertical pass
	for(j=0;j<h;j++)
	{
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int kj;
			for(kj=0;kj<kernelYSize;kj++)
			{
				int y = j+kj-shiftY;
				sum=VGColorAdd(sum,  VGColorMultiplyByFloat(readTiledPixel(i, y, w, src->m_height, tilingMode, tmp2, edge), kernelY[kj]));
			}
			VGImageWriteFilteredPixel(self,i, j, VGColorMultiplyByFloat(sum, scaleY), channelMask);
		}
	}
    NSZoneFree(NULL,tmp);
    NSZoneFree(NULL,tmp2);
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns lookup table format for lookup filters.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColorInternalFormat getLUTFormat(bool outputLinear, bool outputPremultiplied)
{
	VGColorInternalFormat lutFormat = VGColor_lRGBA;
	if(outputLinear && outputPremultiplied)
		lutFormat = VGColor_lRGBA_PRE;
	else if(!outputLinear && !outputPremultiplied)
		lutFormat = VGColor_sRGBA;
	else if(!outputLinear && outputPremultiplied)
		lutFormat = VGColor_sRGBA_PRE;
	return lutFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies multi-channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageLookup(VGImage *self,VGImage * src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask){
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(redLUT && greenLUT && blueLUT && alphaLUT);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);
	VGColorInternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor s = VGImageReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = intToColor(  redLUT[colorToInt(s.r, 255)], 255);
			d.g = intToColor(greenLUT[colorToInt(s.g, 255)], 255);
			d.b = intToColor( blueLUT[colorToInt(s.b, 255)], 255);
			d.a = intToColor(alphaLUT[colorToInt(s.a, 255)], 255);

			VGImageWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies single channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGImageLookupSingle(VGImage *self,VGImage * src, const RIuint32 * lookupTable, VGImageChannel sourceChannel, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask){
	RI_ASSERT(src->m_data);	//source exists
	RI_ASSERT(self->m_data);	//destination exists
	RI_ASSERT(lookupTable);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->m_width, src->m_width);
	int h = RI_INT_MIN(self->m_height, src->m_height);
	RI_ASSERT(w > 0 && h > 0);

	if(src->m_desc.luminanceBits)
		sourceChannel = VG_RED;
	else if(src->m_desc.redBits + src->m_desc.greenBits + src->m_desc.blueBits == 0)
	{
		RI_ASSERT(src->m_desc.alphaBits);
		sourceChannel = VG_ALPHA;
	}

	VGColorInternalFormat procFormat = getProcessingFormat(src->m_desc.internalFormat, filterFormatLinear, filterFormatPremultiplied);
	VGColorInternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor s = VGImageReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);
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
			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = intToColor((l>>24), 255);
			d.g = intToColor((l>>16), 255);
			d.b = intToColor((l>> 8), 255);
			d.a = intToColor((l    ), 255);

			VGImageWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}
