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
 * \brief	KGPaint and KGPixelPipe classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "riMath.h"
#import "VGImage.h"

typedef enum {
  VG_PAINT_TYPE_COLOR                         = 0x1B00,
  VG_PAINT_TYPE_LINEAR_GRADIENT               = 0x1B01,
  VG_PAINT_TYPE_RADIAL_GRADIENT               = 0x1B02,
  VG_PAINT_TYPE_PATTERN                       = 0x1B03
} VGPaintType;

typedef enum {
  VG_COLOR_RAMP_SPREAD_PAD                    = 0x1C00,
  VG_COLOR_RAMP_SPREAD_REPEAT                 = 0x1C01,
  VG_COLOR_RAMP_SPREAD_REFLECT                = 0x1C02
} VGColorRampSpreadMode;


struct GradientStop {
   RIfloat		offset;
   VGColor		color;
};

typedef struct {
	VGPaintType				m_paintType;
	VGColor					m_paintColor;
	VGColor					m_inputPaintColor;
	VGColorRampSpreadMode	m_colorRampSpreadMode;
    int                     m_colorRampStopsCount;
    int                     m_colorRampStopsCapacity;
	GradientStop	       *m_colorRampStops;
	BOOL				    m_colorRampPremultiplied;
	Vector2					m_linearGradientPoint0;
	Vector2					m_linearGradientPoint1;
	Vector2					m_radialGradientCenter;
	Vector2					m_radialGradientFocalPoint;
	RIfloat					m_radialGradientRadius;
	VGTilingMode			m_patternTilingMode;
	VGImage*					m_pattern;

} KGPaint;

KGPaint *KGPaintAlloc();
KGPaint *KGPaintInit(KGPaint *self);
void     KGPaintDealloc(KGPaint *self);

/*-------------------------------------------------------------------*//*!
* \brief	Encapsulates all information needed for painting a pixel.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/
	
typedef struct {
   VGImage*                 m_renderingSurface;
   VGImage*           m_mask;
   VGImage*                 m_image;
   KGPaint*           m_paint;
   KGPaint                 * m_defaultPaint;
   CGBlendMode            m_blendMode;
   VGImageMode            m_imageMode;
   CGInterpolationQuality m_imageQuality;
   VGColor                  m_tileFillColor;
   Matrix3x3              m_surfaceToPaintMatrix;
   Matrix3x3              m_surfaceToImageMatrix;
} KGPixelPipe;

KGPixelPipe *KGPixelPipeAlloc();
KGPixelPipe *KGPixelPipeInit(KGPixelPipe *self);
void KGPixelPipeDealloc(KGPixelPipe *self);
void KGPixelPipeSetRenderingSurface(KGPixelPipe *self,VGImage *renderingSurface);
void KGPixelPipeSetBlendMode(KGPixelPipe *self,CGBlendMode blendMode);
void KGPixelPipeSetMask(KGPixelPipe *self,VGImage* mask);
void KGPixelPipeSetImage(KGPixelPipe *self,VGImage* image, VGImageMode imageMode);
void KGPixelPipeSetSurfaceToPaintMatrix(KGPixelPipe *self,Matrix3x3 surfaceToPaintMatrix);
void KGPixelPipeSetSurfaceToImageMatrix(KGPixelPipe *self,Matrix3x3 surfaceToImageMatrix);
void KGPixelPipeSetImageQuality(KGPixelPipe *self,CGInterpolationQuality imageQuality);
void KGPixelPipeSetTileFillColor(KGPixelPipe *self,VGColor c);
void KGPixelPipeSetPaint(KGPixelPipe *self,KGPaint* paint);
//private
void KGPixelPipeLinearGradient(KGPixelPipe *self,RIfloat& g, RIfloat& rho, RIfloat x, RIfloat y);
void KGPixelPipeRadialGradient(KGPixelPipe *self,RIfloat &g, RIfloat &rho, RIfloat x, RIfloat y);
VGColor KGPixelPipeIntegrateColorRamp(KGPixelPipe *self,RIfloat gmin, RIfloat gmax);
VGColor KGPixelPipeColorRamp(KGPixelPipe *self,RIfloat gradient, RIfloat rho);
void KGPixelPipeWriteCoverage(KGPixelPipe *self,int x, int y, RIfloat coverage);
