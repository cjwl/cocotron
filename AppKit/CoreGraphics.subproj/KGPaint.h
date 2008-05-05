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

#import "KGSurface.h"

typedef enum {
  VG_PAINT_TYPE_COLOR,
  VG_PAINT_TYPE_LINEAR_GRADIENT,
  VG_PAINT_TYPE_RADIAL_GRADIENT,
  VG_PAINT_TYPE_PATTERN
} VGPaintType;

@class KGPaint;

typedef VGColorInternalFormat (*KGPaintReadSpan_RGBAffff)(KGPaint *self,int x,int y,KGRGBAffff *span,int length);

@interface KGPaint : NSObject {
@public
    KGPaintReadSpan_RGBAffff _readRGBAffff;
@protected
	VGPaintType				m_paintType;
    CGAffineTransform               m_surfaceToPaintMatrix;
}

KGPaint *KGPaintAlloc();
KGPaint *KGPaintInit(KGPaint *self);

void KGPaintSetSurfaceToPaintMatrix(KGPaint *self,CGAffineTransform surfaceToPaintMatrix);
void     KGPaintDealloc(KGPaint *self);

@end
