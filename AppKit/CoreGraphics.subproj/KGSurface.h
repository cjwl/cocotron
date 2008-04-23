/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
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

#import "KGImage.h"

#import "VGmath.h"

typedef unsigned int	RIuint32;
typedef short			RIint16;
typedef unsigned short	RIuint16;
typedef unsigned int VGbitfield;

typedef enum {
  VG_TILE_FILL,
  VG_TILE_PAD,
  VG_TILE_REPEAT,
} VGTilingMode;

typedef enum {
  VG_DRAW_IMAGE_NORMAL                        = 0x1F00,
  VG_DRAW_IMAGE_MULTIPLY                      = 0x1F01,
  VG_DRAW_IMAGE_STENCIL                       = 0x1F02
} KGSurfaceMode;

typedef enum {
  VG_RED                                      = (1 << 3),
  VG_GREEN                                    = (1 << 2),
  VG_BLUE                                     = (1 << 1),
  VG_ALPHA                                    = (1 << 0)
} KGSurfaceChannel;

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
*//*-------------------------------------------------------------------*/


typedef struct VGColor {
	RIfloat		r;
	RIfloat		g;
	RIfloat		b;
	RIfloat		a;
	VGColorInternalFormat	m_format;
} VGColor;

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


static inline VGColor VGColorUnpremultiply(VGColor result){
   if(result.m_format & VGColorPREMULTIPLIED) {
    RIfloat ooa = (result.a != 0.0f) ? 1.0f/result.a : (RIfloat)0.0f;
    result.r *= ooa; result.g *= ooa; result.b *= ooa;
    result.m_format = (VGColorInternalFormat) (result.m_format & ~VGColorPREMULTIPLIED);
   }
   return result;
}

VGColor VGColorConvert(VGColor result,VGColorInternalFormat outputFormat);

static inline void convertSpan(KGRGBA *span,int length,VGColorInternalFormat fromFormat,VGColorInternalFormat toFormat){
   if(fromFormat!=toFormat){
    int i;
   
    for(i=0;i<length;i++)
     span[i]=KGRGBAFromColor(VGColorConvert(VGColorFromKGRGBA(span[i],fromFormat),toFormat));
   }
}


@class KGSurface;

typedef void (*KGSurfaceWriteSpan_KGRGBA)(KGSurface *self,int x,int y,KGRGBA *span,int length);

@interface KGSurface : KGImage {
   KGSurfaceWriteSpan_KGRGBA _writeSpan;
   
} 

KGSurface *KGSurfaceAlloc();
KGSurface *KGSurfaceInit(KGSurface *self,size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,KGColorSpace *colorSpace,CGBitmapInfo bitmapInfo,KGSurfaceFormat imageFormat);
//use data from a memory buffer. NOTE: data is not copied, so it is user's responsibility to make sure the data remains valid while the KGSurface is in use.
KGSurface *KGSurfaceInitWithBytes(KGSurface *self,size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,KGColorSpace *colorSpace,CGBitmapInfo bitmapInfo,KGSurfaceFormat imageFormat,RIuint8* data);

void KGSurfaceDealloc(KGSurface *self);

BOOL KGSurfaceIsValidFormat(int format);

void KGSurfaceResize(KGSurface *self,int newWidth, int newHeight, VGColor newPixelColor);

VGPixelDecode KGSurfaceParametersToPixelLayout(KGSurfaceFormat format,size_t *bitsPerPixel,VGColorInternalFormat *colorFormat);

void KGSurfaceClear(KGSurface *self,VGColor clearColor, int x, int y, int w, int h);
void KGSurfaceBlit(KGSurface *self,KGSurface * src, int sx, int sy, int dx, int dy, int w, int h, BOOL dither);
void KGSurfaceMask(KGSurface *self,KGSurface* src, VGMaskOperation operation, int x, int y, int w, int h);
VGColor inline KGSurfaceReadPixel(KGImage *self,int x, int y);
VGColorInternalFormat KGSurfaceReadPremultipliedSpan_ffff(KGSurface *self,int x,int y,KGRGBA *span,int length);

void inline KGSurfaceWritePixel(KGSurface *self,int x, int y, VGColor c);
void KGSurfaceWritePixelSpan(KGSurface *self,int x,int y,KGRGBA *span,int length,VGColorInternalFormat format);

void KGSurfaceWriteFilteredPixel(KGSurface *self,int x, int y, VGColor c, VGbitfield channelMask);

RIfloat KGSurfaceReadMaskPixel(KGSurface *self,int x, int y);		//can read any image format
void KGSurfaceReadMaskPixelSpanIntoCoverage(KGSurface *self,int x,int y,RIfloat *coverage,int length);

void KGSurfaceWriteMaskPixel(KGSurface *self,int x, int y, RIfloat m);	//can write only to VG_A_8


void KGSurfacePatternSpan(KGSurface *self,RIfloat x, RIfloat y, KGRGBA *span,int length,int colorFormat, Matrix3x3 surfaceToImage, CGPatternTiling distortion);

void KGSurfaceMakeMipMaps(KGImage *self);

void KGSurfaceColorMatrix(KGSurface *self,KGSurface * src, const RIfloat* matrix, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);
void KGSurfaceConvolve(KGSurface *self,KGSurface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);
void KGSurfaceSeparableConvolve(KGSurface *self,KGSurface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, RIfloat scale, RIfloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);
void KGSurfaceGaussianBlur(KGSurface *self,KGSurface * src, RIfloat stdDeviationX, RIfloat stdDeviationY, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);
void KGSurfaceLookup(KGSurface *self,KGSurface * src, const RIuint8 * redLUT, const RIuint8 * greenLUT, const RIuint8 * blueLUT, const RIuint8 * alphaLUT, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);
void KGSurfaceLookupSingle(KGSurface *self,KGSurface * src, const RIuint32 * lookupTable, KGSurfaceChannel sourceChannel, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask);

@end
