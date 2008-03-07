#ifndef __RIPATH_H
#define __RIPATH_H

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
 * \brief	Path class.
 * \note	
 *//*-------------------------------------------------------------------*/

#ifndef _OPENVG_H
#include "openvg.h"
#endif

#ifndef __RIMATH_H
#include "riMath.h"
#endif

#ifndef __RIARRAY_H
#include "riArray.h"
#endif

#ifndef __RIRASTERIZER_H
#include "riRasterizer.h"
#endif

//==============================================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Storage and operations for VGPath.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

class Path
{
public:
	Path(VGint format, RIfloat scale, RIfloat bias, int segmentCapacityHint, int coordCapacityHint);	//throws bad_alloc
	~Path();

	VGint				getFormat() const						{ return m_format; }
	RIfloat				getScale() const						{ return m_scale; }
	RIfloat				getBias() const							{ return m_bias; }
	VGbitfield			getCapabilities() const					{ return m_capabilities; }
	void				setCapabilities(VGbitfield caps)		{ m_capabilities = caps; }
	int					getNumSegments() const					{ return m_segments.size(); }
	int					getNumCoordinates() const				{ return m_data.size() / getBytesPerCoordinate(); }
	void				addReference()							{ m_referenceCount++; }
	int					removeReference()						{ m_referenceCount--; RI_ASSERT(m_referenceCount >= 0); return m_referenceCount; }

	void				clear(VGbitfield capabilities);
	void				appendData(const RIuint8* segments, int numSegments, const RIuint8* data);	//throws bad_alloc
	void				append(const Path* srcPath);	//throws bad_alloc
	void				modifyCoords(int startIndex, int numSegments, const RIuint8* data);
	void				transform(const Path* srcPath, const Matrix3x3& matrix);	//throws bad_alloc
	//returns true if interpolation succeeds, false if start and end paths are not compatible
	bool				interpolate(const Path* startPath, const Path* endPath, RIfloat amount);	//throws bad_alloc
	void				fill(const Matrix3x3& pathToSurface, Rasterizer& rasterizer);	//throws bad_alloc
	void				stroke(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, bool dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit);	//throws bad_alloc

	void				getPointAlong(int startIndex, int numSegments, RIfloat distance, Vector2& p, Vector2& t);	//throws bad_alloc
	RIfloat				getPathLength(int startIndex, int numSegments);	//throws bad_alloc
	void				getPathBounds(RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc
	void				getPathTransformedBounds(const Matrix3x3& pathToSurface, RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc

private:
	enum VertexFlags
	{
		START_SUBPATH			= (1<<0),
		END_SUBPATH				= (1<<1),
		START_SEGMENT			= (1<<2),
		END_SEGMENT				= (1<<3),
		CLOSE_SUBPATH			= (1<<4),
		IMPLICIT_CLOSE_SUBPATH	= (1<<5)
	};
	struct Vertex
	{
		Vertex() : userPosition(), userTangent(), pathLength(0.0f), flags(0) {}
		Vector2			userPosition;
		Vector2			userTangent;
		RIfloat			pathLength;
		unsigned int	flags;
	};
	struct StrokeVertex
	{
		StrokeVertex() : p(), t(), ccw(), cw(), pathLength(0.0f), flags(0), inDash(false) {}
		Vector2			p;
		Vector2			t;
		Vector2			ccw;
		Vector2			cw;
		RIfloat			pathLength;
		unsigned int	flags;
		bool			inDash;
	};

	Path(const Path&);						//!< Not allowed.
	const Path& operator=(const Path&);		//!< Not allowed.

	static VGPathSegment getPathSegment(RIuint8 data)				{ return (VGPathSegment)(data & 0x1e); }
	static VGPathAbsRel	getPathAbsRel(RIuint8 data)					{ return (VGPathAbsRel)(data & 0x1); }
	static int			segmentToNumCoordinates(VGPathSegment segment);
	static int			countNumCoordinates(const RIuint8* segments, int numSegments);
	static int			getBytesPerCoordinate();

	static void			setCoordinate(Array<RIuint8>& data, RIfloat scale, RIfloat bias, int i, RIfloat c);

	RIfloat				getCoordinate(int i) const;
	void				setCoordinate(int i, RIfloat c)				{ setCoordinate(m_data, m_scale, m_bias, i, c); }

	void				addVertex(const Vector2& p, const Vector2& t, RIfloat pathLength, unsigned int flags);	//throws bad_alloc
	void				addEdge(const Vector2& p0, const Vector2& p1, const Vector2& t0, const Vector2& t1, unsigned int startFlags, unsigned int endFlags);	//throws bad_alloc

	void				addEndPath(const Vector2& p0, const Vector2& p1, bool subpathHasGeometry, unsigned int flags);	//throws bad_alloc
	bool				addLineTo(const Vector2& p0, const Vector2& p1, bool subpathHasGeometry);	//throws bad_alloc
	bool				addQuadTo(const Vector2& p0, const Vector2& p1, const Vector2& p2, bool subpathHasGeometry);	//throws bad_alloc
	bool				addCubicTo(const Vector2& p0, const Vector2& p1, const Vector2& p2, const Vector2& p3, bool subpathHasGeometry);	//throws bad_alloc
	bool				addArcTo(const Vector2& p0, RIfloat rh, RIfloat rv, RIfloat rot, const Vector2& p1, VGPathSegment segment, bool subpathHasGeometry);	//throws bad_alloc

	void				tessellate();	//throws bad_alloc

	void				normalizeForInterpolation(const Path* srcPath);	//throws bad_alloc

	void				interpolateStroke(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth) const;	//throws bad_alloc
	void				doCap(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v, RIfloat strokeWidth, CGLineCap capStyle) const;	//throws bad_alloc
	void				doJoin(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit) const;	//throws bad_alloc

	//input data
	VGint				m_format;
	RIfloat				m_scale;
	RIfloat				m_bias;
	VGbitfield			m_capabilities;
	int					m_referenceCount;
	Array<RIuint8>		m_segments;
	Array<RIuint8>		m_data;

	//data produced by tessellation
	struct VertexIndex
	{
		int		start;
		int		end;
	};
	Array<Vertex>		m_vertices;
	Array<VertexIndex>	m_segmentToVertex;
	RIfloat				m_userMinx;
	RIfloat				m_userMiny;
	RIfloat				m_userMaxx;
	RIfloat				m_userMaxy;
};

//==============================================================================================

}	//namespace OpenVGRI

//==============================================================================================

#endif /* __RIPATH_H */
