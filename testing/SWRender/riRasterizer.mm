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
 * \brief	Implementation of polygon rasterizer.
 * \note	
 *//*-------------------------------------------------------------------*/

#include "riRasterizer.h"

//==============================================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Rasterizer constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Rasterizer::Rasterizer() :
	m_edges(),
	m_scissorEdges(),
	m_scissor(false)
{}

/*-------------------------------------------------------------------*//*!
* \brief	Rasterizer destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Rasterizer::~Rasterizer()
{
}

/*-------------------------------------------------------------------*//*!
* \brief	Removes all appended edges.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::clear()
{
	m_edges.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends an edge to the rasterizer.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::addEdge(const Vector2& v0, const Vector2& v1)
{
	if( m_edges.size() >= RI_MAX_EDGES )
		throw std::bad_alloc();	//throw an out of memory error if there are too many edges

	if(v0.y == v1.y)
		return;	//skip horizontal edges (they don't affect rasterization since we scan horizontally)

	Edge e;
	e.v0 = v0;
	e.v1 = v1;
	m_edges.push_back(e);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets scissor rectangles.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::setScissor(const Array<Rectangle>& scissors)
{
	m_scissor = true;
	try
	{
		m_scissorEdges.clear();
		for(int i=0;i<scissors.size();i++)
		{
			if(scissors[i].width > 0 && scissors[i].height > 0)
			{
				ScissorEdge e;
				e.miny = scissors[i].y;
				e.maxy = RI_INT_ADDSATURATE(scissors[i].y, scissors[i].height);

				e.x = scissors[i].x;
				e.direction = 1;
				m_scissorEdges.push_back(e);	//throws bad_alloc
				e.x = RI_INT_ADDSATURATE(scissors[i].x, scissors[i].width);
				e.direction = -1;
				m_scissorEdges.push_back(e);	//throws bad_alloc
			}
		}
	}
	catch(std::bad_alloc)
	{
		m_scissorEdges.clear();
		throw;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns a radical inverse of a given integer for Hammersley
*			point set.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static double radicalInverseBase2(unsigned int i)
{
	if( i == 0 )
		return 0.0;
	double p = 0.0;
	double f = 0.5;
	double ff = f;
	for(unsigned int j=0;j<32;j++)
	{
		if( i & (1<<j) )
			p += f;
		f *= ff;
	}
	return p;
}

/*-------------------------------------------------------------------*//*!
* \brief	Calls PixelPipe::pixelPipe for each pixel with coverage greater
*			than zero.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::fill(int vpx, int vpy, int vpwidth, int vpheight, VGFillRule fillRule, VGRenderingQuality renderingQuality, const PixelPipe& pixelPipe) const
{
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
	RI_ASSERT(vpx + vpwidth >= vpx && vpy + vpheight >= vpy);
	RI_ASSERT(fillRule == VG_EVEN_ODD || fillRule == VG_NON_ZERO);
	RI_ASSERT(renderingQuality == VG_RENDERING_QUALITY_NONANTIALIASED ||
			  renderingQuality == VG_RENDERING_QUALITY_FASTER ||
			  renderingQuality == VG_RENDERING_QUALITY_BETTER);

	if(m_scissor && !m_scissorEdges.size())
		return;	//scissoring is on, but there are no scissor rectangles => nothing is visible

	//proceed scanline by scanline
	//keep track of edges that can intersect the pixel filters of the current scanline (Active Edge Table)
	//until all pixels of the scanline have been processed
	//  for all sampling points of the current pixel
	//    determine the winding number using edge functions
	//    add filter weight to coverage
	//  divide coverage by the number of samples
	//  determine a run of pixels with constant coverage
	//  call fill callback for each pixel of the run

	int fillRuleMask = 1;
	if(fillRule == VG_NON_ZERO)
		fillRuleMask = -1;

	//make a sampling pattern
	Sample samples[32];
	int numSamples;
	RIfloat sumWeights = 0.0f;
	RIfloat fradius = 0.0f;		//max offset of the sampling points from a pixel center
	bool reflect = false;
	if(renderingQuality == VG_RENDERING_QUALITY_NONANTIALIASED)
	{
		numSamples = 1;
		samples[0].x = 0.0f;
		samples[0].y = 0.0f;
		samples[0].weight = 1.0f;
		fradius = 0.0f;
		sumWeights = 1.0f;
	}
	else if(renderingQuality == VG_RENDERING_QUALITY_FASTER)
	{	//box filter of diameter 1.0f, 8-queen sampling pattern
		numSamples = 8;
		samples[0].x = 3;
		samples[1].x = 7;
		samples[2].x = 0;
		samples[3].x = 2;
		samples[4].x = 5;
		samples[5].x = 1;
		samples[6].x = 6;
		samples[7].x = 4;
		for(int i=0;i<numSamples;i++)
		{
			samples[i].x = (samples[i].x + 0.5f) / (RIfloat)numSamples - 0.5f;
			samples[i].y = ((RIfloat)i + 0.5f) / (RIfloat)numSamples - 0.5f;
			samples[i].weight = 1.0f / (RIfloat)numSamples;
			sumWeights += samples[i].weight;
		}
		fradius = 0.5f;
	}
	else
	{
		RI_ASSERT(renderingQuality == VG_RENDERING_QUALITY_BETTER);
		numSamples = 32;
		fradius = 0.75f;
		for(int i=0;i<numSamples;i++)
		{	//Gaussian filter, implemented using Hammersley point set for sample point locations
			RIfloat x = (RIfloat)radicalInverseBase2(i);
			RIfloat y = ((RIfloat)i + 0.5f) / (RIfloat)numSamples;
			RI_ASSERT(x >= 0.0f && x < 1.0f);
			RI_ASSERT(y >= 0.0f && y < 1.0f);

			//map unit square to unit circle
			RIfloat r = (RIfloat)sqrt(x) * fradius;
			x = r * (RIfloat)sin(y*2.0f*PI);
			y = r * (RIfloat)cos(y*2.0f*PI);
			samples[i].weight = (RIfloat)exp(-0.5f * RI_SQR(r/fradius));

			RI_ASSERT(x >= -1.5f && x <= 1.5f && y >= -1.5f && y <= 1.5f);	//the specification restricts the filter radius to be less than or equal to 1.5
			
			samples[i].x = x;
			samples[i].y = y;
			sumWeights += samples[i].weight;
		}
	}

	//fill the screen
	Array<ActiveEdge> aet;
	Array<ScissorEdge> scissorAet;
	for(int j=vpy;j<vpy+vpheight;j++)
	{
		//gather scissor edges intersecting this scanline
		scissorAet.clear();
		if( m_scissor )
		{
			for(int e=0;e<m_scissorEdges.size();e++)
			{
				const ScissorEdge& se = m_scissorEdges[e];
				if(j >= se.miny && j < se.maxy)
					scissorAet.push_back(m_scissorEdges[e]);	//throws bad_alloc
			}
			if(!scissorAet.size())
				continue;	//scissoring is on, but there are no scissor rectangles on this scanline
		}

		//simple AET: scan through all the edges and pick the ones intersecting this scanline
		aet.clear();
		for(int e=0;e<m_edges.size();e++)
		{
			RIfloat cminy = (RIfloat)j - fradius + 0.5f;
			RIfloat cmaxy = (RIfloat)j + fradius + 0.5f;
			const Edge& ed = m_edges[e];
			RI_ASSERT(ed.v0.y != ed.v1.y);	//horizontal edges should have been dropped already

			ActiveEdge ae;
			if(ed.v0.y < ed.v1.y)
			{	//edge is going upward
				ae.v0 = ed.v0;
				ae.v1 = ed.v1;
				ae.direction = 1;
			}
			else
			{	//edge is going downward
				ae.v0 = ed.v1;
				ae.v1 = ed.v0;
				ae.direction = -1;
			}

			if(cmaxy >= ae.v0.y && cminy < ae.v1.y)
			{
				ae.n.set(ae.v0.y - ae.v1.y, ae.v1.x - ae.v0.x);	//edge normal
				ae.cnst = dot(ae.v0, ae.n);	//distance of v0 from the origin along the edge normal
				
				//compute edge min and max x-coordinates for this scanline
				Vector2 vd = ae.v1 - ae.v0;
				RIfloat wl = 1.0f / vd.y;
				RIfloat sx = ae.v0.x + vd.x * (cminy - ae.v0.y) * wl;
				RIfloat ex = ae.v0.x + vd.x * (cmaxy - ae.v0.y) * wl;
				RIfloat bminx = RI_MIN(ae.v0.x, ae.v1.x);
				RIfloat bmaxx = RI_MAX(ae.v0.x, ae.v1.x);
				sx = RI_CLAMP(sx, bminx, bmaxx);
				ex = RI_CLAMP(ex, bminx, bmaxx);
				ae.minx = RI_MIN(sx,ex);
				ae.maxx = RI_MAX(sx,ex);
				aet.push_back(ae);	//throws bad_alloc
			}
		}
		if(!aet.size())
			continue;	//no edges on the whole scanline, skip it

		//sort AET by edge minx
		for(int e=0;e<aet.size()-1;e++)
		{
			for(int f=e+1;f<aet.size();f++)
			{
				if(aet[e].minx > aet[f].minx)
				{
					ActiveEdge tmp = aet[e];
					aet[e] = aet[f];
					aet[f] = tmp;
				}
			}
		}
		
		//sort scissor AET by edge x
		for(int e=0;e<scissorAet.size()-1;e++)
		{
			for(int f=e+1;f<scissorAet.size();f++)
			{
				if(scissorAet[e].x > scissorAet[f].x)
				{
					ScissorEdge tmp = scissorAet[e];
					scissorAet[e] = scissorAet[f];
					scissorAet[f] = tmp;
				}
			}
		}

		//fill the scanline
		int scissorWinding = m_scissor ? 0 : 1;	//if scissoring is off, winding is always 1
		int scissorIndex = 0;
		int aes = 0;
		int aen = 0;
		for(int i=vpx;i<vpx+vpwidth;)
		{
			Vector2 pc(i + 0.5f, j + 0.5f);		//pixel center
			
			//find edges that intersect or are to the left of the pixel antialiasing filter
			while(aes < aet.size() && pc.x + fradius >= aet[aes].minx)
				aes++;
			//edges [0,aes[ may have an effect on winding, and need to be evaluated while sampling

			//compute coverage
			RIfloat coverage = 0.0f;
			for(int s=0;s<numSamples;s++)
			{
				Vector2 sp = pc;	//sampling point
				if(reflect && (i&1))
					sp.x -= samples[s].x;
				else
					sp.x += samples[s].x;
				if(reflect && (j&1))
					sp.y -= samples[s].y;
				else
					sp.y += samples[s].y;

				//compute winding number by evaluating the edge functions of edges to the left of the sampling point
				int winding = 0;
				for(int e=0;e<aes;e++)
				{
					if(sp.y >= aet[e].v0.y && sp.y < aet[e].v1.y)
					{	//evaluate edge function to determine on which side of the edge the sampling point lies
						RIfloat side = dot(sp, aet[e].n) - aet[e].cnst;
						if(side <= 0.0f)	//implicit tie breaking: a sampling point on an opening edge is in, on a closing edge it's out
							winding += aet[e].direction;
					}
				}
				if( winding & fillRuleMask )
					coverage += samples[s].weight;
			}

			//constant coverage optimization:
			//scan AET from left to right and skip all the edges that are completely to the left of the pixel filter.
			//since AET is sorted by minx, the edge we stop at is the leftmost of the edges we haven't passed yet.
			//if that edge is to the right of this pixel, coverage is constant between this pixel and the start of the edge.
			while(aen < aet.size() && aet[aen].maxx < pc.x - fradius - 0.01f)	//0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
				aen++;

			int endSpan = vpx + vpwidth;	//endSpan is the first pixel NOT part of the span
			if(aen < aet.size())
				endSpan = RI_INT_MAX(i+1, RI_INT_MIN(endSpan, (int)ceil(aet[aen].minx - fradius - 0.5f)));

			coverage /= sumWeights;
			RI_ASSERT(coverage >= 0.0f && coverage <= 1.0f);

			//fill a run of pixels with constant coverage
			if(coverage > 0.0f)
			{
				for(;i<endSpan;i++)
				{
					//update scissor winding number
					while(scissorIndex < scissorAet.size() && scissorAet[scissorIndex].x <= i)
						scissorWinding += scissorAet[scissorIndex++].direction;
					RI_ASSERT(scissorWinding >= 0);

					if(scissorWinding)
						pixelPipe.pixelPipe(i, j, coverage);
				}
			}
			i = endSpan;
		}
	}
}

//=======================================================================

}	//namespace OpenVGRI
