#ifndef __RIRASTERIZER_H
#define __RIRASTERIZER_H

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
 * \brief	Rasterizer class.
 * \note	
 *//*-------------------------------------------------------------------*/

#ifndef __RIMATH_H
#include "riMath.h"
#endif

#ifndef __RIARRAY_H
#include "riArray.h"
#endif

#ifndef __RIPIXELPIPE_H
#include "riPixelPipe.h"
#endif

//=======================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Converts a set of edges to coverage values for each pixel and
*			calls PixelPipe::pixelPipe for painting a pixel.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Rasterizer
{
public:
	Rasterizer();	//throws bad_alloc
	~Rasterizer();

	void		setScissor(const Array<Rectangle>& scissors);	//throws bad_alloc

	void		clear();
	void		addEdge(const Vector2& v0, const Vector2& v1);	//throws bad_alloc

	void		fill(int vpx, int vpy, int vpwidth, int vpheight, VGFillRule fillRule, VGRenderingQuality renderingQuality, const PixelPipe& pixelPipe) const;	//throws bad_alloc
private:
	Rasterizer(const Rasterizer&);						//!< Not allowed.
	const Rasterizer& operator=(const Rasterizer&);		//!< Not allowed.

	struct Edge
	{
		Edge() : v0(), v1() {}
		Vector2		v0;
		Vector2		v1;
	};

	struct ScissorEdge
	{
		ScissorEdge() : x(0), miny(0), maxy(0), direction(0) {}
		int			x;
		int			miny;
		int			maxy;
		int			direction;		//1 start, -1 end
	};

	struct ActiveEdge
	{
		ActiveEdge() : v0(), v1(), direction(0), minx(0.0f), maxx(0.0f), n(), cnst(0.0f) {}
		Vector2		v0;
		Vector2		v1;
		int			direction;		//-1 down, 1 up
		RIfloat		minx;			//for the current scanline
		RIfloat		maxx;			//for the current scanline
		Vector2		n;
		RIfloat		cnst;
	};

	struct Sample
	{
		Sample() : x(0.0f), y(0.0f), weight(0.0f) {}
		RIfloat		x;
		RIfloat		y;
		RIfloat		weight;
	};

	Array<Edge>			m_edges;
	Array<ScissorEdge>	m_scissorEdges;
	bool				m_scissor;
};

//=======================================================================

}	//namespace OpenVGRI

//=======================================================================

#endif /* __RIRASTERIZER_H */
