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

#import "KGBitmapContext.h"
#import "VGmath.h"
#import "KGSurface.h"

@class KGPaint;

typedef enum {
// These are winding masks, do not change value
  VG_EVEN_ODD=1,
  VG_NON_ZERO=-1
} VGFillRuleMask;

typedef struct Edge {
   CGPoint		v0;
   CGPoint		v1;
   int         direction;
   CGPoint     normal;
   CGFloat     cnst;
   int         minscany;
   int         maxscany;
// These are init/modified during AET processing, should be broken out to save memory
   struct Edge *next;
   CGFloat      vdxwl;
   CGFloat      sxPre;
   CGFloat      exPre;
   CGFloat      bminx;
   CGFloat      bmaxx;
   int          minx;
   int          maxx;
   CGFloat     *samples;
   CGFloat      minSample;
   CGFloat      maxSample;
} Edge;

typedef void (*KGBlendSpan_RGBA8888)(KGRGBA8888 *src,KGRGBA8888 *dst,int length);
typedef void (*KGBlendSpan_RGBAffff)(KGRGBAffff *src,KGRGBAffff *dst,int length);
typedef void (*KGWriteCoverage_RGBA8888)(KGSurface *surface,KGSurface *mask,KGPaint *paint,int x, int y,int coverage,int length,KGBlendSpan_RGBA8888 blendFunction);

@class KGSurface,KGContext_builtin;

#define KGRasterizer KGContext_builtin

@interface KGContext_builtin : KGBitmapContext {

   KGPaint           *_paint;
   KGContext_builtin *_clipContext;
   
   KGBlendSpan_RGBA8888     _blend_lRGBA8888_PRE;
   KGBlendSpan_RGBAffff     _blend_lRGBAffff_PRE;
   KGWriteCoverage_RGBA8888 _writeCoverage_lRGBA8888_PRE;
   void               (*_blendFunction)();
   void               (*_writeCoverageFunction)();
   
    int _vpx,_vpy,_vpwidth,_vpheight;
    
    int    _edgeCount;
    int    _edgeCapacity;
    Edge **_edges;
    Edge **_sortCache;
    
    int *_winding;
    int *_increase;
    
    int     sampleSizeShift;
	int     numSamples;
    int     samplesWeight;
    CGFloat *samplesX;
    CGFloat  samplesInitialY;
    CGFloat  samplesDeltaY;
    int alias;
}

-(void)setWidth:(size_t)width height:(size_t)height reallocateOnlyIfRequired:(BOOL)roir;

void KGRasterizerDealloc(KGRasterizer *self);
void KGRasterizerSetViewport(KGRasterizer *self,int x,int y,int vpwidth,int vpheight);
void KGRasterizerClear(KGRasterizer *self);
void O2DContextAddEdge(KGRasterizer *self,const CGPoint v0, const CGPoint v1);
void KGRasterizerSetShouldAntialias(KGRasterizer *self,BOOL antialias,int quality);
void KGRasterizerFill(KGRasterizer *self,int fillRule);

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode);
void KGRasterizeSetMask(KGRasterizer *self,KGSurface* mask);
void O2DContextSetPaint(KGRasterizer *self,KGPaint* paint);

void KGBlendSpanNormal_8888_coverage(KGRGBA8888 *src,KGRGBA8888 *dst,int coverage,int length);

@end
