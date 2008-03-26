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
	//data produced by tessellation
	struct VertexIndex
	{
		int		start;
		int		end;
	};

typedef struct {
	//input data
	RIfloat				m_scale;
	RIfloat				m_bias;
    
    int      _segmentCount;
    int      _segmentCapacity;
    RIuint8 *_segments;
    
    int      _coordinateCount;
    int      _coordinateCapacity;
    RIfloat *_coordinates;
    
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
} VGPath;

VGPath *VGPathAlloc();
VGPath *VGPathInit(VGPath *self,int segmentCapacityHint, int coordCapacityHint);
void VGPathDealloc(VGPath *self);

static inline int VGPathGetNumCoordinates(VGPath *self){
   return self->_coordinateCount;
}

void VGPathAppendData(VGPath *self,const RIuint8* segments, int numSegments, const RIfloat* data);	//throws bad_alloc
void VGPathAppend(VGPath *self,const VGPath* srcPath);	//throws bad_alloc
void VGPathTransform(VGPath *self,const VGPath* srcPath, Matrix3x3 matrix);	//throws bad_alloc
	//returns true if interpolation succeeds, false if start and end paths are not compatible
void VGPathFill(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer);	//throws bad_alloc
void VGPathStroke(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, bool dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit);	//throws bad_alloc

void VGPathGetPointAlong(VGPath *self,int startIndex, int numSegments, RIfloat distance, Vector2& p, Vector2& t);	//throws bad_alloc
RIfloat getPathLength(VGPath *self,int startIndex, int numSegments);	//throws bad_alloc
void VGPathGetPathBounds(VGPath *self,RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc
void VGPathGetPathTransformedBounds(VGPath *self,Matrix3x3 pathToSurface, RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy);	//throws bad_alloc

int VGPathSegmentToNumCoordinates(VGPathSegment segment);
int VGPathCountNumCoordinates(const RIuint8* segments, int numSegments);

RIfloat VGPathGetCoordinate(VGPath *self,int i);
void VGPathSetCoordinate(VGPath *self,int i, RIfloat c);

void VGPathAddVertex(VGPath *self,Vector2 p, Vector2 t, RIfloat pathLength, unsigned int flags);	//throws bad_alloc
void VGPathAddEdge(VGPath *self,Vector2 p0, Vector2 p1, Vector2 t0, Vector2 t1, unsigned int startFlags, unsigned int endFlags);	//throws bad_alloc

void VGPathAddEndPath(VGPath *self,Vector2 p0, Vector2 p1, bool subpathHasGeometry, unsigned int flags);	//throws bad_alloc
bool VGPathAddLineTo(VGPath *self,Vector2 p0, Vector2 p1, bool subpathHasGeometry);	//throws bad_alloc
bool VGPathAddQuadTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, bool subpathHasGeometry);	//throws bad_alloc
bool VGPathAddCubicTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, bool subpathHasGeometry);	//throws bad_alloc
bool VGPathAddArcTo(VGPath *self,Vector2 p0, RIfloat rh, RIfloat rv, RIfloat rot, Vector2 p1, VGPathSegment segment, bool subpathHasGeometry);	//throws bad_alloc

void VGPathTessellate(VGPath *self);	//throws bad_alloc

void VGPathInterpolateStroke(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, RIfloat strokeWidth);	//throws bad_alloc
void VGPathDoCap(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const StrokeVertex& v, RIfloat strokeWidth, CGLineCap capStyle);	//throws bad_alloc
void VGPathDoJoin(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit);	//throws bad_alloc
