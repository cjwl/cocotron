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
 *-------------------------------------------------------------------*/

#import <Foundation/NSObject.h>

#import "VGmath.h"

typedef unsigned int	RIuint32;
typedef short			RIint16;
typedef unsigned short	RIuint16;
typedef unsigned int VGbitfield;

typedef enum {
  VG_TILE_FILL                                = 0x1D00,
  VG_TILE_PAD                                 = 0x1D01,
  VG_TILE_REPEAT                              = 0x1D02,
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
			int xmin = RI_INT_MIN(RI_INT_ADDSATURATE(self.x, self.width), RI_INT_ADDSATURATE(other.x, other.width));
			self.x = RI_INT_MAX(self.x, other.x);
			self.width = RI_INT_MAX(xmin - self.x, 0);

			int ymin = RI_INT_MIN(RI_INT_ADDSATURATE(self.y, self.height), RI_INT_ADDSATURATE(other.y, other.height));
			self.y = RI_INT_MAX(self.y, other.y);
			self.height = RI_INT_MAX(ymin - self.y, 0);
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

/*-------------------------------------------------------------------*//*!
* \brief	A class representing color for processing and converting it
*			to and from various surface formats.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

enum {
 VGColorNONLINEAR		= (1<<0),
 VGColorPREMULTIPLIED	= (1<<1),
 VGColorLUMINANCE		= (1<<2)
};

typedef enum {
 VGColor_lRGBA			= 0,
 VGColor_sRGBA			= VGColorNONLINEAR,
 VGColor_lRGBA_PRE		= VGColorPREMULTIPLIED,
 VGColor_sRGBA_PRE		= VGColorPREMULTIPLIED|VGColorNONLINEAR,
 VGColor_lLA            = VGColorLUMINANCE,
 VGColor_sLA			= VGColorLUMINANCE|VGColorNONLINEAR,
 VGColor_lLA_PRE		= VGColorLUMINANCE|VGColorPREMULTIPLIED,
 VGColor_sLA_PRE        = VGColorLUMINANCE|VGColorPREMULTIPLIED|VGColorNONLINEAR
} VGColorInternalFormat;


typedef struct VGColor {
	RIfloat		r;
	RIfloat		g;
	RIfloat		b;
	RIfloat		a;
	VGColorInternalFormat	m_format;
} VGColor;

typedef struct KGRGBA {
   RIfloat r;
   RIfloat g;
   RIfloat b;
   RIfloat a;
} KGRGBA;

static inline KGRGBA KGRGBAInit(RIfloat r,RIfloat g,RIfloat b,RIfloat a){
   KGRGBA result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline VGColor VGColorFromKGRGBA(KGRGBA rgba,VGColorInternalFormat format){
   VGColor result;
   
   result.r=rgba.r;
   result.g=rgba.g;
   result.b=rgba.b;
   result.a=rgba.a;
   result.m_format=format;
   
   return result;
}

static inline KGRGBA KGRGBAFromColor(VGColor color){
   KGRGBA result;
   result.r=color.r;
   result.g=color.g;
   result.b=color.b;
   result.a=color.a;
   return result;
}

static inline KGRGBA KGRGBAMultiplyByFloat(KGRGBA result,RIfloat value){
   result.r*=value;
   result.g*=value;
   result.b*=value;
   result.a*=value;
   return result;
}

static inline KGRGBA KGRGBAAdd(KGRGBA result,KGRGBA other){
   result.r+=other.r;
   result.g+=other.g;
   result.b+=other.b;
   result.a+=other.a;
   return result;
}

static inline VGColor VGColorZero(){
   VGColor result;
   
   result.r=0;
   result.g=0;
   result.b=0;
   result.a=0;
   result.m_format=VGColor_lRGBA;
   
   return result;
}

static inline VGColor VGColorRGBA(RIfloat cr, RIfloat cg, RIfloat cb, RIfloat ca, VGColorInternalFormat cs){
   VGColor result;
   
   RI_ASSERT(cs == VGColor_lRGBA || cs == VGColor_sRGBA || cs == VGColor_lRGBA_PRE || cs == VGColor_sRGBA_PRE || cs == VGColor_lLA || cs == VGColor_sLA || cs == VGColor_lLA_PRE || cs == VGColor_sLA_PRE);
   
   result.r=cr;
   result.g=cg;
   result.b=cb;
   result.a=ca;
   result.m_format=cs;
   return result;
}

static inline VGColor VGColorMultiplyByFloat(VGColor c,RIfloat f){
   return VGColorRGBA(c.r*f, c.g*f, c.b*f, c.a*f, c.m_format);
}

static inline VGColor VGColorAdd(VGColor c0,VGColor c1){
   RI_ASSERT(c0.m_format == c1.m_format);
   return VGColorRGBA(c0.r+c1.r, c0.g+c1.g, c0.b+c1.b, c0.a+c1.a, c0.m_format);
}

static inline VGColor VGColorSubtract(VGColor result,VGColor c1){
   RI_ASSERT(result.m_format == c1.m_format);
   result.r -= c1.r;
   result.g -= c1.g;
   result.b -= c1.b;
   result.a -= c1.a;
   return result;
}

//clamps nonpremultiplied colors and alpha to [0,1] range, and premultiplied alpha to [0,1], colors to [0,a]
static inline VGColor VGColorClamp(VGColor result){
   result.a = RI_CLAMP(result.a,0.0f,1.0f);
   RIfloat u = (result.m_format & VGColorPREMULTIPLIED) ? result.a : (RIfloat)1.0f;
   result.r = RI_CLAMP(result.r,0.0f,u);
   result.g = RI_CLAMP(result.g,0.0f,u);
   result.b = RI_CLAMP(result.b,0.0f,u);
   return result;
}

static inline VGColor VGColorPremultiply(VGColor result){
   if(!(result.m_format & VGColorPREMULTIPLIED)) {
     result.r *= result.a; result.g *= result.a; result.b *= result.a; result.m_format = (VGColorInternalFormat)(result.m_format | VGColorPREMULTIPLIED);
    }
    return result;
}

static inline KGRGBA KGRGBAPremultiply(KGRGBA result){
   result.r *= result.a;
   result.g *= result.a;
   result.b *= result.a; 
   return result;
}

static inline VGColor VGColorUnpremultiply(VGColor result){
   if(result.m_format & VGColorPREMULTIPLIED) {
    RIfloat ooa = (result.a != 0.0f) ? 1.0f/result.a : (RIfloat)0.0f;
    result.r *= ooa; result.g *= ooa; result.b *= ooa;
    result.m_format = (VGColorInternalFormat) (result.m_format & ~VGColorPREMULTIPLIED);
   }
   return result;
}

VGColor VGColorConvert(VGColor result,VGColorInternalFormat outputFormat);

typedef struct  {
   int redBits;
   int redShift;
   int greenBits;
   int greenShift;
   int blueBits;
   int blueShift;
   int alphaBits;
   int alphaShift;
   int luminanceBits;
   int luminanceShift;
} VGPixelDecode;

@class VGImage;

typedef void (*VGImageReadSpan_KGRGBA)(VGImage *self,int x,int y,KGRGBA *span,int length);
typedef void (*VGImageWriteSpan_KGRGBA)(VGImage *self,int x,int y,KGRGBA *span,int length);
typedef void (*VGImageReadTexelTileSpan)(VGImage *self,int u, int v, KGRGBA *span,int length,int level, KGRGBA tileFillColor);

@interface VGImage : NSObject {
   size_t       _width;
   size_t       _height;
   size_t       _bitsPerComponent;
   size_t       _bitsPerPixel;
   size_t       _bytesPerRow;
   NSString    *_colorSpaceName;
   CGBitmapInfo _bitmapInfo;
   
   VGImageReadSpan_KGRGBA  _readSpan;
   VGImageWriteSpan_KGRGBA _writeSpan;
   
   VGImageFormat         _imageFormat;
   VGColorInternalFormat _colorFormat;
    
	VGPixelDecode	m_desc;
	RIuint8*			m_data;
	bool				m_ownsData;
    bool                _clampExternalPixels;
	bool				m_mipmapsValid;
    int                 _mipmapsCount;
    int                 _mipmapsCapacity;
    struct VGImage    **_mipmaps;
} 

VGImage *VGImageAlloc();
VGImage *VGImageInit(VGImage *self,size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,NSString *colorSpaceName,CGBitmapInfo bitmapInfo,VGImageFormat imageFormat);	//throws bad_alloc
//use data from a memory buffer. NOTE: data is not copied, so it is user's responsibility to make sure the data remains valid while the VGImage is in use.
VGImage *VGImageInitWithBytes(VGImage *self,size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,NSString *colorSpaceName,CGBitmapInfo bitmapInfo,VGImageFormat imageFormat,RIuint8* data);	//throws bad_alloc

void VGImageDealloc(VGImage *self);

bool VGImageIsValidFormat(int format);

int VGImageGetWidth(VGImage *image);

int VGImageGetHeight(VGImage *image);

void VGImageResize(VGImage *self,int newWidth, int newHeight, VGColor newPixelColor);

void VGImageClear(VGImage *self,VGColor clearColor, int x, int y, int w, int h);
void VGImageBlit(VGImage *self,VGImage * src, int sx, int sy, int dx, int dy, int w, int h, bool dither);
void VGImageMask(VGImage *self,VGImage* src, VGMaskOperation operation, int x, int y, int w, int h);
VGColor inline VGImageReadPixel(VGImage *self,int x, int y);
VGColorInternalFormat VGImageReadPremultipliedPixelSpan(VGImage *self,int x,int y,KGRGBA *span,int length);

void inline VGImageWritePixel(VGImage *self,int x, int y, VGColor c);
void VGImageWritePixelSpan(VGImage *self,int x,int y,KGRGBA *span,int length,VGColorInternalFormat format);

void VGImageWriteFilteredPixel(VGImage *self,int x, int y, VGColor c, VGbitfield channelMask);

RIfloat VGImageReadMaskPixel(VGImage *self,int x, int y);		//can read any image format
void VGImageReadMaskPixelSpanIntoCoverage(VGImage *self,int x,int y,RIfloat *coverage,int length);

void VGImageWriteMaskPixel(VGImage *self,int x, int y, RIfloat m);	//can write only to VG_A_8

VGImageReadTexelTileSpan VGImageTexelTilingFunctionForMode(VGTilingMode tilingMode);
void VGImageResampleSpan(VGImage *self,RIfloat x, RIfloat y, KGRGBA *span,int length,int colorFormat, Matrix3x3 surfaceToImage, CGInterpolationQuality quality, VGImageReadTexelTileSpan tilingFunction, VGColor tileFillColor);

void VGImageMakeMipMaps(VGImage *self);

void VGImageColorMatrix(VGImage *self,VGImage * src, const RIfloat* matrix, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
void VGImageConvolve(VGImage *self,VGImage * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
void VGImageSeparableConvolve(VGImage *self,VGImage * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
void VGImageGaussianBlur(VGImage *self,VGImage * src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, VGColor edgeFillColor, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
void VGImageLookup(VGImage *self,VGImage * src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);
void VGImageLookupSingle(VGImage *self,VGImage * src, const RIuint32 * lookupTable, VGImageChannel sourceChannel, bool outputLinear, bool outputPremultiplied, bool filterFormatLinear, bool filterFormatPremultiplied, VGbitfield channelMask);

@end
