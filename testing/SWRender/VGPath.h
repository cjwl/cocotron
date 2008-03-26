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
 *-------------------------------------------------------------------*/

#import "riMath.h"
#import "KGRasterizer.h"

typedef enum {
  VG_CLOSE_PATH                               = ( 0 << 1),
  VG_MOVE_TO                                  = ( 1 << 1),
  VG_LINE_TO                                  = ( 2 << 1),
  VG_HLINE_TO                                 = ( 3 << 1),
  VG_VLINE_TO                                 = ( 4 << 1),
  VG_QUAD_TO                                  = ( 5 << 1),
  VG_CUBIC_TO                                 = ( 6 << 1),
  VG_SQUAD_TO                                 = ( 7 << 1),
  VG_SCUBIC_TO                                = ( 8 << 1),
  VG_SCCWARC_TO                               = ( 9 << 1),
  VG_SCWARC_TO                                = (10 << 1),
  VG_LCCWARC_TO                               = (11 << 1),
  VG_LCWARC_TO                                = (12 << 1)
} VGPathSegment;

class VGPath
{
public:
	VGPath(RIfloat scale, RIfloat bias, int segmentCapacityHint, int coordCapacityHint);	//throws bad_alloc
	~VGPath();

	int					getNumCoordinates() const				{ return _coordinateCount; }

	void				appendData(const RIuint8* segments, int numSegments, const RIfloat* data);	//throws bad_alloc
	void				append(const VGPath* srcPath);	//throws bad_alloc
	void				transform(const VGPath* srcPath, Matrix3x3 matrix);	//throws bad_alloc
	//returns true if interpolation succeeds, false if start and end paths are not compatible
	void				fill(Matrix3x3 pathToSurface, KGRasterizer *rasterizer);	//throws bad_alloc
	void				stroke(Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, bool dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit);	//throws bad_alloc

	void				getPointAlong(int startIndex, int numSegments, RIfloat distance, Vector2& p, Vector2& t);	//throws bad_alloc
	RIfloat				getPathLength(int startIndex, int numSegments);	//throws bad_alloc
	void				getPathBounds(RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc
	void				getPathTransformedBounds(Matrix3x3 pathToSurface, RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc

//private
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

	static int			segmentToNumCoordinates(VGPathSegment segment);
	static int			countNumCoordinates(const RIuint8* segments, int numSegments);

	static void			setCoordinate(RIfloat *data, RIfloat scale, RIfloat bias, int i, RIfloat c);

	RIfloat				getCoordinate(int i) const;
	void				setCoordinate(int i, RIfloat c)				{ setCoordinate(_coordinates, m_scale, m_bias, i, c); }

	void				addVertex(Vector2 p, Vector2 t, RIfloat pathLength, unsigned int flags);	//throws bad_alloc
	void				addEdge(Vector2 p0, Vector2 p1, Vector2 t0, Vector2 t1, unsigned int startFlags, unsigned int endFlags);	//throws bad_alloc

	void				addEndPath(Vector2 p0, Vector2 p1, bool subpathHasGeometry, unsigned int flags);	//throws bad_alloc
	bool				addLineTo(Vector2 p0, Vector2 p1, bool subpathHasGeometry);	//throws bad_alloc
	bool				addQuadTo(Vector2 p0, Vector2 p1, Vector2 p2, bool subpathHasGeometry);	//throws bad_alloc
	bool				addCubicTo(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, bool subpathHasGeometry);	//throws bad_alloc
	bool				addArcTo(Vector2 p0, RIfloat rh, RIfloat rv, RIfloat rot, Vector2 p1, VGPathSegment segment, bool subpathHasGeometry);	//throws bad_alloc

	void				tessellate();	//throws bad_alloc

	void				interpolateStroke(Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth) const;	//throws bad_alloc
	void				doCap(Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const StrokeVertex& v, RIfloat strokeWidth, CGLineCap capStyle) const;	//throws bad_alloc
	void				doJoin(Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit) const;	//throws bad_alloc

	//input data
	RIfloat				m_scale;
	RIfloat				m_bias;
    
    int      _segmentCount;
    int      _segmentCapacity;
    RIuint8 *_segments;
    
    int      _coordinateCount;
    int      _coordinateCapacity;
    RIfloat *_coordinates;
    
	//data produced by tessellation
	struct VertexIndex
	{
		int		start;
		int		end;
	};
    int     _vertexCount;
    int     _vertexCapacity;
    Vertex *_vertices;
    
    int     _segmentToVertexCount;
    int     _segmentToVertexCapacity;
    VertexIndex *_segmentToVertex;
    
	RIfloat				m_userMinx;
	RIfloat				m_userMiny;
	RIfloat				m_userMaxx;
	RIfloat				m_userMaxy;
};
