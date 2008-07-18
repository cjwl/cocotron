/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 * Copyright (c) 2008 Christopher J. W. Lloyd
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
#import <ApplicationServices/ApplicationServices.h>
#import "VGmath.h"

@class KGColorSpace,KGDataProvider;

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
} KGImageFormat;

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


typedef struct {
   CGFloat a;
   CGFloat r;
   CGFloat g;
   CGFloat b;
} KGRGBAffff;

static inline KGRGBAffff KGRGBAffffInit(CGFloat r,CGFloat g,CGFloat b,CGFloat a){
   KGRGBAffff result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline KGRGBAffff KGRGBAffffMultiplyByFloat(KGRGBAffff result,CGFloat value){
   result.r*=value;
   result.g*=value;
   result.b*=value;
   result.a*=value;
   return result;
}

static inline KGRGBAffff KGRGBAffffAdd(KGRGBAffff result,KGRGBAffff other){
   result.r+=other.r;
   result.g+=other.g;
   result.b+=other.b;
   result.a+=other.a;
   return result;
}

static inline KGRGBAffff KGRGBAffffSubtract(KGRGBAffff result,KGRGBAffff other){
   result.r-=other.r;
   result.g-=other.g;
   result.b-=other.b;
   result.a-=other.a;
   return result;
}

static inline KGRGBAffff KGRGBAffffPremultiply(KGRGBAffff result){
   result.r*=result.a;
   result.g*=result.a;
   result.b*=result.a;
   return result;
}
static inline KGRGBAffff KGRGBAffffClamp(KGRGBAffff result){
   result.r=RI_CLAMP(result.r,0.0f,1.0f);
   result.g=RI_CLAMP(result.g,0.0f,1.0f);
   result.b=RI_CLAMP(result.b,0.0f,1.0f);
   result.a=RI_CLAMP(result.a,0.0f,1.0f);
   return result;
}

static inline void KGRGBPremultiplySpan(KGRGBAffff *span,int length){
   int i;
      
   for(i=0;i<length;i++){
    span[i].r*=span[i].a;
    span[i].g*=span[i].a;
    span[i].b*=span[i].a; 
   }
}

typedef struct {
#ifdef __LITTLE_ENDIAN__
   uint8_t b;
   uint8_t g;
   uint8_t r;
   uint8_t a;
#endif
#ifdef __BIG_ENDIAN__
   uint8_t a;
   uint8_t r;
   uint8_t g;
   uint8_t b;
#endif
} KGRGBA8888;

static inline KGRGBA8888 KGRGBA8888Init(int r,int g,int b,int a){
   KGRGBA8888 result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline CGFloat CGFloatFromByte(uint8_t i){
	return (CGFloat)(i) / (CGFloat)0xFF;
}

static inline uint8_t CGByteFromFloat(CGFloat c){
	return RI_INT_MIN(RI_INT_MAX(RI_FLOOR_TO_INT(c * (CGFloat)0xFF + 0.5), 0), 0xFF);
}

static inline KGRGBA8888 KGRGBA8888FromKGRGBAffff(KGRGBAffff rgba){
   KGRGBA8888 result;
   result.r=CGByteFromFloat(rgba.r);
   result.g=CGByteFromFloat(rgba.g);
   result.b=CGByteFromFloat(rgba.b);
   result.a=CGByteFromFloat(rgba.a);
   return result;
}

#define COVERAGE_MULTIPLIER 256

static inline CGFloat zeroToOneFromCoverage(int coverage){
   return (CGFloat)coverage/(CGFloat)COVERAGE_MULTIPLIER;
}

static inline CGFloat coverageFromZeroToOne(CGFloat value){
   return value*COVERAGE_MULTIPLIER;
}

static inline int inverseCoverage(int coverage){
   return COVERAGE_MULTIPLIER-coverage;
}

static inline int multiplyByCoverage(int value,int coverage){
   return (value*coverage)/COVERAGE_MULTIPLIER;
}

static inline KGRGBA8888 KGRGBA8888MultiplyByCoverage(KGRGBA8888 result,int value){
   result.r=((int)result.r*value)/COVERAGE_MULTIPLIER;
   result.g=((int)result.g*value)/COVERAGE_MULTIPLIER;
   result.b=((int)result.b*value)/COVERAGE_MULTIPLIER;
   result.a=((int)result.a*value)/COVERAGE_MULTIPLIER;

   return result;
}

static inline KGRGBA8888 KGRGBA8888Add(KGRGBA8888 result,KGRGBA8888 other){
   result.r=MIN((int)result.r+(int)other.r,255);
   result.g=MIN((int)result.g+(int)other.g,255);
   result.b=MIN((int)result.b+(int)other.b,255);
   result.a=MIN((int)result.a+(int)other.a,255);
   return result;
}

@class KGImage;
 
typedef KGRGBA8888 *(*KGImageReadSpan_RGBA8888)(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
typedef KGRGBAffff *(*KGImageReadSpan_RGBAffff)(KGImage *self,int x,int y,KGRGBAffff *span,int length);
typedef uint8_t    *(*KGImageReadSpan_A8)(KGImage *self,int x,int y,uint8_t *span,int length);
typedef CGFloat    *(*KGImageReadSpan_Af)(KGImage *self,int x,int y,CGFloat *span,int length);

@interface KGImage : NSObject <NSCopying> {
   size_t _width;
   size_t _height;
   size_t _bitsPerComponent;
   size_t _bitsPerPixel;
   size_t _bytesPerRow;
   
   KGColorSpace          *_colorSpace;
   CGBitmapInfo           _bitmapInfo;
   KGDataProvider        *_provider;
   float                 *_decode;
   BOOL                   _interpolate;
   BOOL                   _isMask;
   CGColorRenderingIntent _renderingIntent;
   KGImage               *_mask;

   NSData              *_directData;
   const unsigned char *_directBytes;
   BOOL           _clampExternalPixels;
   VGColorInternalFormat _colorFormat;

   KGImageReadSpan_RGBA8888 _readRGBA8888;
   KGImageReadSpan_RGBAffff _readRGBAffff;
   KGImageReadSpan_A8 _readA8;
   KGImageReadSpan_Af _readAf;

   BOOL			     	m_mipmapsValid;
   int                 _mipmapsCount;
   int                 _mipmapsCapacity;
   struct KGSurface    **_mipmaps;
}

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo provider:(KGDataProvider *)provider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;

-initMaskWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate ;

-initWithJPEGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;
-initWithPNGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;

-(KGImage *)copyWithColorSpace:(KGColorSpace *)colorSpace;
-(KGImage *)childImageInRect:(CGRect)rect;

-(void)addMask:(KGImage *)mask;
-copyWithMask:(KGImage *)image;
-copyWithMaskingColors:(const CGFloat *)components;

-(size_t)width;
-(size_t)height;
-(size_t)bitsPerComponent;
-(size_t)bitsPerPixel;
-(size_t)bytesPerRow;
-(KGColorSpace *)colorSpace;
-(CGBitmapInfo)bitmapInfo;
-(KGDataProvider *)dataProvider;
-(const CGFloat *)decode;
-(BOOL)shouldInterpolate;
-(CGColorRenderingIntent)renderingIntent;
-(BOOL)isMask;
-(CGImageAlphaInfo)alphaInfo;

-(NSData *)directData;
-(void)releaseDirectDataIfPossible;

@end

VGPixelDecode KGImageParametersToPixelLayout(KGImageFormat format,size_t *bitsPerPixel,VGColorInternalFormat *colorFormat);

CGColorRenderingIntent KGImageRenderingIntentWithName(const char *name);
const char *KGImageNameWithIntent(CGColorRenderingIntent intent);

size_t KGImageGetWidth(KGImage *self);
size_t KGImageGetHeight(KGImage *self);

/* KGImage and KGSurface can read and write any image format provided functions are provided to translate to/from either KGRGBA8888 or KGRGBAffff spans. 

  The return value will be either NULL or a pointer to the image data if direct access is available for the given format. You must use the return value if it is not NULL. If the value is not NULL you don't do a write back. This is a big boost for native ARGB format as it avoids a copy out and a copy in.
  
  The nomenclature for the RGBA8888 functions is the bit sequencing in big endian
 */

uint8_t *KGImageRead_G8_to_A8(KGImage *self,int x,int y,uint8_t *alpha,int length);
CGFloat *KGImageRead_ANY_to_A8_to_Af(KGImage *self,int x,int y,CGFloat *alpha,int length);
uint8_t *KGImageRead_ANY_to_RGBA8888_to_A8(KGImage *self,int x,int y,uint8_t *alpha,int length);

KGRGBA8888 *KGImageRead_G8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_GA88_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_RGBA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_ABGR8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_BGRA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_XRGB8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_G3B5X1R5G2_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_RGBA4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_BARG4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_RGBA2222_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_CMYK8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBA8888 *KGImageRead_I8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);

KGRGBAffff *KGImageRead_ANY_to_RGBA8888_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);

KGRGBAffff *KGImageRead_RGBAffffLittle_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);
KGRGBAffff *KGImageRead_RGBAffffBig_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);

KGRGBA8888 *KGImageReadSpan_lRGBA8888_PRE(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
KGRGBAffff *KGImageReadSpan_lRGBAffff_PRE(KGImage *self,int x,int y,KGRGBAffff *span,int length);
uint8_t    *KGImageReadSpan_A8_MASK(KGImage *self,int x,int y,uint8_t *coverage,int length);
CGFloat    *KGImageReadSpan_Af_MASK(KGImage *self,int x,int y,CGFloat *coverage,int length);

void KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(KGImage *self,int u, int v, KGRGBA8888 *span,int length);
void KGImageReadTileSpanExtendEdge_lRGBAffff_PRE(KGImage *self,int u, int v, KGRGBAffff *span,int length);

void KGImageEWAOnMipmaps_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImageBicubic_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImageBicubic_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImageBilinear_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImageBilinear_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImagePointSampling_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImagePointSampling_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);

void KGImageReadPatternSpan_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y, KGRGBAffff *span,int length, CGAffineTransform surfaceToImage, CGPatternTiling distortion);
