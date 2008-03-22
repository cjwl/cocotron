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
 * \brief	KGRasterizer class.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "riMath.h"
#import "KGPixelPipe.h"

/*-------------------------------------------------------------------*//*!
* \brief	Converts a set of edges to coverage values for each pixel and
*			calls KGPixelPipe::pixelPipe for painting a pixel.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

typedef enum {
  VG_EVEN_ODD                                 = 0x1900,
  VG_NON_ZERO                                 = 0x1901
} VGFillRule;

struct Edge {
   Vector2		v0;
   Vector2		v1;
   int         direction;
   Vector2     normal;
   RIfloat     cnst;
};

struct Sample {
   RIfloat		x;
   RIfloat		y;
   RIfloat		weight;
};

typedef struct {    
    int _vpx,_vpy,_vpwidth,_vpheight;
    
    int          _edgeCount;
    int          _edgeCapacity;
    struct Edge *_edges;

	Sample samples[32];
	int numSamples;
	RIfloat sumWeights ;
	RIfloat fradius ;		//max offset of the sampling points from a pixel center
	bool reflect ;
} KGRasterizer;

KGRasterizer *KGRasterizerAlloc();
KGRasterizer *KGRasterizerInit(KGRasterizer *self);
void KGRasterizerDealloc(KGRasterizer *self);
void KGRasterizerSetViewport(KGRasterizer *self,int vpx,int vpy,int vpwidth,int vpheight);
void KGRasterizerClear(KGRasterizer *self);
void KGRasterizerAddEdge(KGRasterizer *self,const Vector2 v0, const Vector2 v1);	//throws bad_alloc
void KGRasterizerSetShouldAntialias(KGRasterizer *self,BOOL antialias);
void KGRasterizerFill(KGRasterizer *self,VGFillRule fillRule, KGPixelPipe *pixelPipe);

