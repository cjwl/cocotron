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

#import "VGmath.h"
#import "KGSurface.h"

@class KGPaint;

typedef enum {
  VG_EVEN_ODD,
  VG_NON_ZERO
} VGFillRule;

#define MAX_SAMPLES 256

typedef struct {
   CGPoint		v0;
   CGPoint		v1;
   int         direction;
   CGPoint     normal;
   CGFloat     cnst;
   int         minscany;
   int         maxscany;
// These are init/modified during AET processing, should be broken out to save memory
   CGFloat     vdxwl;
   CGFloat     sxPre;
   CGFloat     exPre;
   CGFloat     bminx;
   CGFloat     bmaxx;
   int          minx;
   int          ceilMinX;
   int  		maxx;
   CGFloat     sidePre[MAX_SAMPLES];
} Edge;

typedef void (*KGRasterizeBlendSpan_RGBAffff)(KGRGBAffff *src,KGRGBAffff *dst,int length);

@interface KGRasterizer : NSObject {    
   KGSurface  *m_renderingSurface;
   KGSurface  *m_mask;
   KGPaint    *m_paint;
   KGRasterizeBlendSpan_RGBAffff _blendRGBAffff;


    int _vpx,_vpy,_vpwidth,_vpheight;
    
    int    _edgeCount;
    int    _edgeCapacity;
    Edge  *_edgePool;
    Edge **_edges;
    BOOL    _antialias;
    
	int     numSamples;
	CGFloat sumWeights;
	CGFloat fradius;		//max offset of the sampling points from a pixel center
    CGFloat samplesX[MAX_SAMPLES];
    CGFloat samplesY[MAX_SAMPLES];
    CGFloat samplesWeight[MAX_SAMPLES];
}

KGRasterizer *KGRasterizerAlloc();
KGRasterizer *KGRasterizerInit(KGRasterizer *self,KGSurface *renderingSurface);
void KGRasterizerDealloc(KGRasterizer *self);
void KGRasterizerSetViewport(KGRasterizer *self,int vpx,int vpy,int vpwidth,int vpheight);
void KGRasterizerClear(KGRasterizer *self);
void KGRasterizerAddEdge(KGRasterizer *self,const CGPoint v0, const CGPoint v1);
void KGRasterizerSetShouldAntialias(KGRasterizer *self,BOOL antialias);
void KGRasterizerFill(KGRasterizer *self,VGFillRule fillRule);

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode);
void KGRasterizeSetMask(KGRasterizer *self,KGSurface* mask);
void KGRasterizeSetPaint(KGRasterizer *self,KGPaint* paint);
//private
void KGRasterizeWriteCoverage(KGRasterizer *self,int x, int y,CGFloat *coverage,int length);

@end
