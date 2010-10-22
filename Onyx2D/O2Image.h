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
#import <Onyx2D/O2Geometry.h>
#import <Onyx2D/O2AffineTransform.h>

@class O2Image;

typedef O2Image *O2ImageRef;

@class O2ColorSpace,O2DataProvider;

#define kO2BitmapAlphaInfoMask 0x1F

typedef enum {
   kO2ImageAlphaNone,
   kO2ImageAlphaPremultipliedLast,
   kO2ImageAlphaPremultipliedFirst,
   kO2ImageAlphaLast,
   kO2ImageAlphaFirst,
   kO2ImageAlphaNoneSkipLast,
   kO2ImageAlphaNoneSkipFirst,
} O2ImageAlphaInfo;

enum {
   kO2BitmapFloatComponents=0x100,
};

#define kO2BitmapByteOrderMask 0x7000

enum {
   kO2BitmapByteOrderDefault=0,
   kO2BitmapByteOrder16Little=0x1000,
   kO2BitmapByteOrder32Little=0x2000,
   kO2BitmapByteOrder16Big=0x3000,
   kO2BitmapByteOrder32Big=0x4000,
   
#ifdef __BIG_ENDIAN__
   kO2BitmapByteOrder16Host=kO2BitmapByteOrder16Big,
   kO2BitmapByteOrder32Host=kO2BitmapByteOrder32Big,
#endif

#ifdef __LITTLE_ENDIAN__
   kO2BitmapByteOrder16Host=kO2BitmapByteOrder16Little,
   kO2BitmapByteOrder32Host=kO2BitmapByteOrder32Little,
#endif
};

typedef unsigned O2BitmapInfo;

#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2Pattern.h>
#import <Onyx2D/O2DataProvider.h>
#import <Onyx2D/VGmath.h>

typedef float O2Float32;

typedef struct {
   O2Float32 a;
   O2Float32 r;
   O2Float32 g;
   O2Float32 b;
} O2argb32f;

static inline O2argb32f O2argb32fInit(O2Float r,O2Float g,O2Float b,O2Float a){
   O2argb32f result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline O2argb32f O2argb32fMultiplyByFloat(O2argb32f result,O2Float value){
   result.r*=value;
   result.g*=value;
   result.b*=value;
   result.a*=value;
   return result;
}

static inline O2argb32f O2argb32fAdd(O2argb32f result,O2argb32f other){
   result.r+=other.r;
   result.g+=other.g;
   result.b+=other.b;
   result.a+=other.a;
   return result;
}

static inline O2argb32f O2argb32fSubtract(O2argb32f result,O2argb32f other){
   result.r-=other.r;
   result.g-=other.g;
   result.b-=other.b;
   result.a-=other.a;
   return result;
}

static inline O2argb32f O2argb32fPremultiply(O2argb32f result){
   result.r*=result.a;
   result.g*=result.a;
   result.b*=result.a;
   return result;
}
static inline O2argb32f O2argb32fClamp(O2argb32f result){
   result.r=RI_CLAMP(result.r,0.0f,1.0f);
   result.g=RI_CLAMP(result.g,0.0f,1.0f);
   result.b=RI_CLAMP(result.b,0.0f,1.0f);
   result.a=RI_CLAMP(result.a,0.0f,1.0f);
   return result;
}


typedef struct {
   uint8_t a;
   uint8_t r;
   uint8_t g;
   uint8_t b;
} O2ARGB32Big;

typedef struct {
   uint8_t r;
   uint8_t g;
   uint8_t b;
   uint8_t a;
} O2RGBA32Big;

typedef struct {
   uint8_t b;
   uint8_t g;
   uint8_t r;
   uint8_t a;
} O2ARGB32Little;

#ifdef __LITTLE_ENDIAN__
typedef O2ARGB32Little O2argb8u;
#endif
#ifdef __BIG_ENDIAN__
typedef O2ARGB32Big O2argb8u;
#endif

static inline O2argb8u O2argb8uInit(uint8_t r,uint8_t g,uint8_t b,uint8_t a){
   O2argb8u result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline O2Float O2Float32FromByte(uint8_t i){
	return (O2Float)(i) / (O2Float)0xFF;
}

static inline uint8_t O2ByteFromFloat(O2Float c){
	return RI_INT_MIN(RI_INT_MAX(RI_FLOOR_TO_INT(c * (O2Float)0xFF + 0.5f), 0), 0xFF);
}

static inline O2argb8u O2argb8uFromO2argb32f(O2argb32f rgba){
   O2argb8u result;
   result.r=O2ByteFromFloat(rgba.r);
   result.g=O2ByteFromFloat(rgba.g);
   result.b=O2ByteFromFloat(rgba.b);
   result.a=O2ByteFromFloat(rgba.a);
   return result;
}

#define COVERAGE_MULTIPLIER 256
#define COVERAGE_MULTIPLIER_FLOAT 256.0f

static inline O2Float zeroToOneFromCoverage(unsigned coverage){
   return (O2Float)coverage/(O2Float)COVERAGE_MULTIPLIER;
}

static inline uint32_t coverageFromZeroToOne(O2Float value){
   return value*COVERAGE_MULTIPLIER_FLOAT;
}

static inline uint32_t inverseCoverage(uint32_t coverage){
   return COVERAGE_MULTIPLIER-coverage;
}

static inline uint32_t multiplyByCoverage(uint32_t value,uint32_t coverage){
   return (value*coverage)/COVERAGE_MULTIPLIER;
}

static inline unsigned divideBy255(unsigned t){
// t/255
// From Imaging Compositing Fundamentals, Technical Memo 4 by Alvy Ray Smith, Aug 15, 1995
// Faster and more accurate in that it rounds instead of truncates   
   t = t + 0x80;
   t= ( ( ( (t)>>8 ) + (t) )>>8 );
   
   return t;
}

static inline uint32_t alphaMultiply(uint32_t c,uint32_t a){
   return divideBy255(c*a);
}

static inline O2argb8u O2argb8uMultiplyByCoverageNoBypass(O2argb8u result,unsigned value){
   result.r=multiplyByCoverage(result.r,value);
   result.g=multiplyByCoverage(result.g,value);
   result.b=multiplyByCoverage(result.b,value);
   result.a=multiplyByCoverage(result.a,value);

   return result;
   }

static inline O2argb8u O2argb8uMultiplyByCoverage(O2argb8u result,unsigned value){
   if(value!=COVERAGE_MULTIPLIER)
    result=O2argb8uMultiplyByCoverageNoBypass(result,value);

   return result;
}

static inline O2argb8u O2argb8uMultiplyByCoverageAdd(O2argb8u left,uint32_t leftCoverage,O2argb8u right,uint32_t rightCoverage){
// O2argb8uAdd(O2argb8uMultiplyByCoverage(left,leftCoverage),O2argb8uMultiplyByCoverage(right,rightCoverage));
#if 0
   if(rightCoverage==COVERAGE_MULTIPLIER)
    return right;
   if(leftCoverage==COVERAGE_MULTIPLIER)
    return left;
#endif

   uint32_t srb=*(uint32_t *)&left;
   uint32_t sag=srb>>8;
   
   sag&=0x00FF00FF;
   srb&=0x00FF00FF;
   sag=((sag*leftCoverage)>>8)&0x00FF00FF;
   srb=((srb*leftCoverage)>>8)&0x00FF00FF;

   uint32_t drb=*(uint32_t *)&right;
   uint32_t dag=drb>>8;
    
   dag&=0x00FF00FF;
   drb&=0x00FF00FF;
        
   dag=((dag*rightCoverage)>>8)&0x00FF00FF;
   drb=((drb*rightCoverage)>>8)&0x00FF00FF;
   
   uint32_t r;
   
   sag+=dag;
   r=RI_INT_MIN(sag,0x00FF0000)<<8;
   r|=RI_INT_MIN(sag&0xFFFF,255)<<8;
   srb+=drb;
   r|=RI_INT_MIN(srb,0x00FF0000);
   r|=RI_INT_MIN(srb&0xFFFF,255);

   return *(O2argb8u *)&r;
}

static inline O2argb8u O2argb8uAdd(O2argb8u result,O2argb8u other){
   result.r=RI_INT_MIN((unsigned)result.r+(unsigned)other.r,255);
   result.g=RI_INT_MIN((unsigned)result.g+(unsigned)other.g,255);
   result.b=RI_INT_MIN((unsigned)result.b+(unsigned)other.b,255);
   result.a=RI_INT_MIN((unsigned)result.a+(unsigned)other.a,255);
   return result;
}


typedef O2argb8u *(*O2ImageReadSpan_argb8u)(O2Image *self,int x,int y,O2argb8u *span,int length);
typedef O2argb32f *(*O2ImageReadSpan_argb32f)(O2Image *self,int x,int y,O2argb32f *span,int length);
typedef uint8_t    *(*O2ImageReadSpan_A8)(O2Image *self,int x,int y,uint8_t *span,int length);
typedef O2Float    *(*O2ImageReadSpan_Af)(O2Image *self,int x,int y,O2Float *span,int length);

@interface O2Image : NSObject <NSCopying> {
   size_t _width;
   size_t _height;
   size_t _bitsPerComponent;
   size_t _bitsPerPixel;
   size_t _bytesPerRow;
   
   O2ColorSpaceRef        _colorSpace;
   O2BitmapInfo           _bitmapInfo;
   O2DataProvider        *_provider;
   O2Float               *_decode;
   BOOL                   _interpolate;
   BOOL                   _isMask;
   O2ColorRenderingIntent _renderingIntent;
   O2Image               *_mask;

   NSData              *_directData;
   const unsigned char *_directBytes;
   unsigned             _directLength;
   
   BOOL           _clampExternalPixels;

@public
   O2ImageReadSpan_argb8u _read_argb8u_PRE;
   O2ImageReadSpan_argb32f _read_largb32f_PRE;
   O2ImageReadSpan_A8 _readA8;
   O2ImageReadSpan_Af _readAf;
}

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(O2BitmapInfo)bitmapInfo provider:(O2DataProvider *)provider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent;

-initMaskWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow provider:(O2DataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate ;

-initWithJPEGDataProvider:(O2DataProvider *)jpegProvider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent;
-initWithPNGDataProvider:(O2DataProvider *)jpegProvider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent;

-(O2Image *)copyWithColorSpace:(O2ColorSpaceRef)colorSpace;
-(O2Image *)childImageInRect:(O2Rect)rect;

-(void)addMask:(O2Image *)mask;
-copyWithMask:(O2Image *)image;
-copyWithMaskingColors:(const O2Float *)components;

O2ImageRef O2ImageCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,O2ColorSpaceRef colorSpace,O2BitmapInfo bitmapInfo,O2DataProviderRef dataProvider,const O2Float *decode,BOOL shouldInterpolate,O2ColorRenderingIntent renderingIntent);
O2ImageRef O2ImageMaskCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,O2DataProviderRef dataProvider,const O2Float *decode,BOOL shouldInterpolate);
O2ImageRef O2ImageCreateCopy(O2ImageRef image);
O2ImageRef O2ImageCreateCopyWithColorSpace(O2ImageRef self,O2ColorSpaceRef colorSpace);
O2ImageRef O2ImageCreateWithJPEGDataProvider(O2DataProviderRef jpegProvider,const O2Float *decode,BOOL interpolate,O2ColorRenderingIntent renderingIntent);
O2ImageRef O2ImageCreateWithPNGDataProvider(O2DataProviderRef pngProvider,const O2Float *decode,BOOL interpolate,O2ColorRenderingIntent renderingIntent);

O2ImageRef O2ImageCreateWithImageInRect(O2ImageRef self,O2Rect rect);
O2ImageRef O2ImageCreateWithMask(O2ImageRef self,O2ImageRef mask);
O2ImageRef O2ImageCreateWithMaskingColors(O2ImageRef self,const O2Float *components);

O2ImageRef O2ImageRetain(O2ImageRef self);
void O2ImageRelease(O2ImageRef self);
BOOL O2ImageIsMask(O2ImageRef self);

size_t O2ImageGetWidth(O2ImageRef self);
size_t O2ImageGetHeight(O2ImageRef self);

size_t O2ImageGetBitsPerComponent(O2ImageRef self);
size_t O2ImageGetBitsPerPixel(O2ImageRef self);
size_t O2ImageGetBytesPerRow(O2ImageRef self);
O2ColorSpaceRef O2ImageGetColorSpace(O2ImageRef self);

O2ImageAlphaInfo O2ImageGetAlphaInfo(O2ImageRef self);
O2DataProviderRef O2ImageGetDataProvider(O2ImageRef self);
const O2Float *O2ImageGetDecode(O2ImageRef self);
BOOL O2ImageGetShouldInterpolate(O2ImageRef self);
O2ColorRenderingIntent O2ImageGetRenderingIntent(O2ImageRef self);
O2BitmapInfo O2ImageGetBitmapInfo(O2ImageRef self);


-(NSData *)directData;
-(const void *)directBytes;
-(void)releaseDirectDataIfPossible;

@end

O2ColorRenderingIntent O2ImageRenderingIntentWithName(const char *name);
const char *O2ImageNameWithIntent(O2ColorRenderingIntent intent);


/* O2Image and O2Surface can read and write any image format provided functions are provided to translate to/from either O2argb8u or O2argb32f spans.

  The return value will be either NULL or a pointer to the image data if direct access is available for the given format. You must use the return value if it is not NULL. If the value is not NULL you don't do a write back. This is a big boost for native ARGB format as it avoids a copy out and a copy in.
  
  The nomenclature for the argb8u functions is the bit sequencing in big endian
 */

uint8_t *O2ImageRead_G8_to_A8(O2Image *self,int x,int y,uint8_t *alpha,int length);
O2Float *O2ImageRead_ANY_to_A8_to_Af(O2Image *self,int x,int y,O2Float *alpha,int length);
uint8_t *O2ImageRead_ANY_to_argb8u_to_A8(O2Image *self,int x,int y,uint8_t *alpha,int length);

O2argb8u *O2ImageRead_G8_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_GA88_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_RGBA8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_ABGR8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_BGRA8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_RGB888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_BGRX8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_XRGB8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_G3B5X1R5G2_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_RGBA4444_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_BARG4444_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_RGBA2222_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_CMYK8888_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);
O2argb8u *O2ImageRead_I8_to_argb8u(O2Image *self,int x,int y,O2argb8u *span,int length);

O2argb32f *O2ImageRead_ANY_to_argb8u_to_argb32f(O2Image *self,int x,int y,O2argb32f *span,int length);

O2argb32f *O2ImageRead_argb32fLittle_to_argb32f(O2Image *self,int x,int y,O2argb32f *span,int length);
O2argb32f *O2ImageRead_argb32fBig_to_argb32f(O2Image *self,int x,int y,O2argb32f *span,int length);

O2argb32f *O2ImageReadSpan_largb32f_PRE(O2Image *self,int x,int y,O2argb32f *span,int length);
uint8_t    *O2ImageReadSpan_A8_MASK(O2Image *self,int x,int y,uint8_t *coverage,int length);
O2Float    *O2ImageReadSpan_Af_MASK(O2Image *self,int x,int y,O2Float *coverage,int length);

void O2ImageReadTileSpanExtendEdge_largb32f_PRE(O2Image *self,int u, int v, O2argb32f *span,int length);

void O2ImageEWAOnMipmaps_largb32f_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage);
void O2ImageBicubic_largb8u_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage);
void O2ImageBicubic_largb32f_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage);
void O2ImageBilinear_largb8u_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage);
void O2ImageBilinear_largb32f_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage);
void O2ImagePointSampling_largb8u_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage);
void O2ImagePointSampling_largb32f_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage);
void O2ImageBilinearFloatTranslate_largb8u_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage);
void O2ImageIntegerTranslate_largb8u_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage);

void O2ImageReadPatternSpan_largb8u_PRE(O2Image *self,O2Float x, O2Float y, O2argb8u *span,int length, O2AffineTransform surfaceToImage, O2PatternTiling distortion);
void O2ImageReadPatternSpan_largb32f_PRE(O2Image *self,O2Float x, O2Float y, O2argb32f *span,int length, O2AffineTransform surfaceToImage, O2PatternTiling distortion);
