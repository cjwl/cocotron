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
 * \brief	VGColor and Image classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "riMath.h"

typedef unsigned int	RIuint32;
typedef short			RIint16;
typedef unsigned short	RIuint16;
typedef unsigned int VGbitfield;

typedef enum {
  VG_TILE_FILL                                = 0x1D00,
  VG_TILE_PAD                                 = 0x1D01,
  VG_TILE_REPEAT                              = 0x1D02,
  VG_TILE_REFLECT                             = 0x1D03
} VGTilingMode;

typedef enum {
  /* RGB{A,X} channel ordering */
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

  /* {A,X}RGB channel ordering */
  VG_sXRGB_8888                               =  0 | (1 << 6),
  VG_sARGB_8888                               =  1 | (1 << 6),
  VG_sARGB_8888_PRE                           =  2 | (1 << 6),
  VG_sARGB_1555                               =  4 | (1 << 6),
  VG_sARGB_4444                               =  5 | (1 << 6),
  VG_lXRGB_8888                               =  7 | (1 << 6),
  VG_lARGB_8888                               =  8 | (1 << 6),
  VG_lARGB_8888_PRE                           =  9 | (1 << 6),

  /* BGR{A,X} channel ordering */
  VG_sBGRX_8888                               =  0 | (1 << 7),
  VG_sBGRA_8888                               =  1 | (1 << 7),
  VG_sBGRA_8888_PRE                           =  2 | (1 << 7),
  VG_sBGR_565                                 =  3 | (1 << 7),
  VG_sBGRA_5551                               =  4 | (1 << 7),
  VG_sBGRA_4444                               =  5 | (1 << 7),
  VG_lBGRX_8888                               =  7 | (1 << 7),
  VG_lBGRA_8888                               =  8 | (1 << 7),
  VG_lBGRA_8888_PRE                           =  9 | (1 << 7),

  /* {A,X}BGR channel ordering */
  VG_sXBGR_8888                               =  0 | (1 << 6) | (1 << 7),
  VG_sABGR_8888                               =  1 | (1 << 6) | (1 << 7),
  VG_sABGR_8888_PRE                           =  2 | (1 << 6) | (1 << 7),
  VG_sABGR_1555                               =  4 | (1 << 6) | (1 << 7),
  VG_sABGR_4444                               =  5 | (1 << 6) | (1 << 7),
  VG_lXBGR_8888                               =  7 | (1 << 6) | (1 << 7),
  VG_lABGR_8888                               =  8 | (1 << 6) | (1 << 7),
  VG_lABGR_8888_PRE                           =  9 | (1 << 6) | (1 << 7)
} VGImageFormat;

typedef enum {
  VG_DRAW_IMAGE_NORMAL                        = 0x1F00,
  VG_DRAW_IMAGE_MULTIPLY                      = 0x1F01,
  VG_DRAW_IMAGE_STENCIL                       = 0x1F02
} VGImageMode;

typedef enum {
  VG_RED                                      = (1 << 3),
  VG_GREEN                                    = (1 << 2),
  VG_BLUE                                     = (1 << 1),
  VG_ALPHA                                    = (1 << 0)
} VGImageChannel;

typedef enum {
  VG_CLEAR_MASK                               = 0x1500,
  VG_FILL_MASK                                = 0x1501,
  VG_SET_MASK                                 = 0x1502,
  VG_UNION_MASK                               = 0x1503,
  VG_INTERSECT_MASK                           = 0x1504,
  VG_SUBTRACT_MASK                            = 0x1505
} VGMaskOperation;


typedef struct {
	int			x;
	int			y;
	int			width;
	int			height;
} KGIntRect;

static inline KGIntRect KGIntRectInit(int x,int y,int width,int height) {
   KGIntRect result={x,y,width,height};
   return result;
}

static inline KGIntRect KGIntRectIntersect(KGIntRect self,KGIntRect other) {
		if(self.width >= 0 && other.width >= 0 && self.height >= 0 && other.height >= 0)
		{
			int x1 = RI_INT_MIN(RI_INT_ADDSATURATE(self.x, self.width), RI_INT_ADDSATURATE(other.x, other.width));
			self.x = RI_INT_MAX(self.x, other.x);
			self.width = RI_INT_MAX(x1 - self.x, 0);

			int y1 = RI_INT_MIN(RI_INT_ADDSATURATE(self.y, self.height), RI_INT_ADDSATURATE(other.y, other.height));
			self.y = RI_INT_MAX(self.y, other.y);
			self.height = RI_INT_MAX(y1 - self.y, 0);
		}
		else
		{
			self.x = 0;
			self.y = 0;
			self.width = 0;
			self.height = 0;
		}
        return self;
}

template <class Item> class Array
{
public:
	Array() : m_array(NULL), m_size(0), m_allocated(0) {}	//throws bad_alloc
	~Array()
	{
		delete[] m_array;
	}

	//if more room is needed, reallocate, otherwise return
	void		reserve( int items )	//throws bad_alloc
	{
		RI_ASSERT( items >= 0 );
		if( items <= m_allocated )
			return;	//if there is room already, return

		RI_ASSERT( items > m_allocated );

		Item* newa = new Item[items];	//throws bad_alloc if runs out of memory
		for(int i=0;i<m_size;i++)
			newa[i] = m_array[i];
		delete[] m_array;
		m_array = newa;
		m_allocated = items;
		//doesn't change size
	}

	//reserve and change size
	void		resize( int items )	//throws bad_alloc
	{
		reserve( items );	//throws bad_alloc if runs out of memory
		m_size = items;
	}

	void		clear()
	{
		m_size = 0;
	}

	int			size() const				{ return m_size; }
	inline Item&		operator[](int i)			{ RI_ASSERT(i >= 0 && i < m_size); return m_array[i]; }
	const Item&	operator[](int i) const		{ RI_ASSERT(i >= 0 && i < m_size); return m_array[i]; }

// private
	Array(const Array& s);				//!< Not allowed.
	void operator=(const Array& s);		//!< Not allowed.

	Item*		m_array;
	int			m_size;
	int			m_allocated;
};


/*-------------------------------------------------------------------*//*!
* \brief	A class representing color for processing and converting it
*			to and from various surface formats.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

enum VGColorInternalFormat {
 VGColor_lRGBA			= 0,
 VGColor_sRGBA			= 1,
 VGColor_lRGBA_PRE		= 2,
 VGColor_sRGBA_PRE		= 3,
 VGColor_lLA				= 4,
 VGColor_sLA				= 5,
 VGColor_lLA_PRE			= 6,
 VGColor_sLA_PRE			= 7
};

struct VGColorDescriptor {
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
		VGColorInternalFormat	internalFormat;
		int				bitsPerPixel;
};
class VGColor
{
public:
	enum FormatBits
	{
		NONLINEAR		= (1<<0),
		PREMULTIPLIED	= (1<<1),
		LUMINANCE		= (1<<2)
	};


	inline VGColor() : r(0.0f), g(0.0f), b(0.0f), a(0.0f), m_format(VGColor_lRGBA)													{}
	inline VGColor(RIfloat cl, RIfloat ca, VGColorInternalFormat cs) : r(cl), g(cl), b(cl), a(ca), m_format(cs)							{ RI_ASSERT(cs == VGColor_lLA || cs == VGColor_sLA || cs == VGColor_lLA_PRE || cs == VGColor_sLA_PRE); }
	inline VGColor(RIfloat cr, RIfloat cg, RIfloat cb, RIfloat ca, VGColorInternalFormat cs) : r(cr), g(cg), b(cb), a(ca), m_format(cs)	{ RI_ASSERT(cs == VGColor_lRGBA || cs == VGColor_sRGBA || cs == VGColor_lRGBA_PRE || cs == VGColor_sRGBA_PRE || cs == VGColor_lLA || cs == VGColor_sLA || cs == VGColor_lLA_PRE || cs == VGColor_sLA_PRE); }
	inline VGColor(const VGColor& c) : r(c.r), g(c.g), b(c.b), a(c.a), m_format(c.m_format)									{}

//	inline void operator+=(const VGColor& c1)										{ RI_ASSERT(m_format == c1.getInternalFormat()); r += c1.r; g += c1.g; b += c1.b; a += c1.a; }
	inline void operator-=(const VGColor& c1)										{ RI_ASSERT(m_format == c1.getInternalFormat()); r -= c1.r; g -= c1.g; b -= c1.b; a -= c1.a; }

	void						set(RIfloat cl, RIfloat ca, VGColorInternalFormat cs)							{ RI_ASSERT(cs == VGColor_lLA || cs == VGColor_sLA || cs == VGColor_lLA_PRE || cs == VGColor_sLA_PRE); r = cl; g = cl; b = cl; a = ca; m_format = cs; }
	void						set(RIfloat cr, RIfloat cg, RIfloat cb, RIfloat ca, VGColorInternalFormat cs)	{ RI_ASSERT(cs == VGColor_lRGBA || cs == VGColor_sRGBA || cs == VGColor_lRGBA_PRE || cs == VGColor_sRGBA_PRE); r = cr; g = cg; b = cb; a = ca; m_format = cs; }
	void						unpack(unsigned int inputData, const VGColorDescriptor& inputDesc);
	unsigned int				pack(const VGColorDescriptor& outputDesc) const;
	inline VGColorInternalFormat	getInternalFormat() const							{ return m_format; }

	//clamps nonpremultiplied colors and alpha to [0,1] range, and premultiplied alpha to [0,1], colors to [0,a]
	void						clamp()												{ a = RI_CLAMP(a,0.0f,1.0f); RIfloat u = (m_format & PREMULTIPLIED) ? a : (RIfloat)1.0f; r = RI_CLAMP(r,0.0f,u); g = RI_CLAMP(g,0.0f,u); b = RI_CLAMP(b,0.0f,u); }
	void						convert(VGColorInternalFormat outputFormat);
	void						premultiply()										{ if(!(m_format & PREMULTIPLIED)) { r *= a; g *= a; b *= a; m_format = (VGColorInternalFormat)(m_format | PREMULTIPLIED); } }
	void						unpremultiply()										{ if(m_format & PREMULTIPLIED) { RIfloat ooa = (a != 0.0f) ? 1.0f/a : (RIfloat)0.0f; r *= ooa; g *= ooa; b *= ooa; m_format = (VGColorInternalFormat)(m_format & ~PREMULTIPLIED); } }

	static VGColorDescriptor			formatToDescriptor(VGImageFormat format);
	static bool					isValidDescriptor(const VGColorDescriptor& desc);

	RIfloat		r;
	RIfloat		g;
	RIfloat		b;
	RIfloat		a;
// private

	VGColorInternalFormat	m_format;
};

static inline VGColor VGColorMultiplyByFloat(VGColor c,RIfloat f){
   return VGColor(c.r*f, c.g*f, c.b*f, c.a*f, c.getInternalFormat());
}

static inline VGColor VGColorAdd(VGColor c0,VGColor c1){
   RI_ASSERT(c0.getInternalFormat() == c1.getInternalFormat());
   return VGColor(c0.r+c1.r, c0.g+c1.g, c0.b+c1.b, c0.a+c1.a, c0.getInternalFormat());
}

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
	Image(const VGColorDescriptor& desc, int width, int height);	//throws bad_alloc
	//use data from a memory buffer. NOTE: data is not copied, so it is user's responsibility to make sure the data remains valid while the Image is in use.
	Image(const VGColorDescriptor& desc, int width, int height, int stride, RIuint8* data);	//throws bad_alloc

	~Image();

	const VGColorDescriptor&	getDescriptor() const		{ return m_desc; }
	int					getWidth() const					{ return m_width; }
	int					getHeight() const					{ return m_height; }
	int					getStride() const					{ return m_stride; }
	void				addInUse()							{ m_inUse++; }
	void				removeInUse()						{ RI_ASSERT(m_inUse > 0); m_inUse--; }
	int					isInUse() const						{ return m_inUse; }
	RIuint8*			getData() const						{ return m_data; }
	void				addReference()						{ m_referenceCount++; }
	int					removeReference()					{ m_referenceCount--; RI_ASSERT(m_referenceCount >= 0); return m_referenceCount; }

	void				resize(int newWidth, int newHeight, const VGColor& newPixelColor);	//throws bad_alloc
	void				clear(const VGColor& clearColor, int x, int y, int w, int h);
	void				blit(const Image& src, int sx, int sy, int dx, int dy, int w, int h, bool dither);	//throws bad_alloc
	void				mask(const Image* src, VGMaskOperation operation, int x, int y, int w, int h);

	VGColor				readPixel(int x, int y) const;
	void				writePixel(int x, int y, const VGColor& c);
	void				writeFilteredPixel(int x, int y, const VGColor& c, VGbitfield channelMask);

	RIfloat				readMaskPixel(int x, int y) const;		//can read any image format
	void				writeMaskPixel(int x, int y, RIfloat m);	//can write only to VG_A_8

	VGColor				resample(RIfloat x, RIfloat y, const Matrix3x3& surfaceToImage, CGInterpolationQuality quality, VGTilingMode tilingMode, const VGColor& tileFillColor);	//throws bad_alloc
	void				makeMipMaps();	//throws bad_alloc

	void				colorMatrix(const Image& src, const RIfloat* matrix, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				convolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const VGColor& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				separableConvolve(const Image& src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, const VGColor& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				gaussianBlur(const Image& src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, const VGColor& edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				lookup(const Image& src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
	void				lookupSingle(const Image& src, const RIuint32 * lookupTable, VGImageChannel sourceChannel, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);

// private

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

	VGColor				readTexel(int u, int v, int level, VGTilingMode tilingMode, const VGColor& tileFillColor) const;

	VGColorDescriptor	m_desc;
	int					m_width;
	int					m_height;
	int					m_inUse;
	int					m_stride;
	RIuint8*			m_data;
	int					m_bitOffset;	//VG_lBW_1 only
	int					m_referenceCount;
	bool				m_ownsData;

	bool				m_mipmapsValid;
	Array<Image*>		m_mipmaps;
};

bool			isValidImageFormat(int format);
