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
#import "KGRasterizer.h"
#import "KGPath.h"

typedef struct {
   Vector2			userPosition;
   Vector2			userTangent;
   RIfloat			pathLength;
   unsigned int	flags;
} Vertex;
    
typedef struct  {
   Vector2			p;
   Vector2			t;
   Vector2			ccw;
   Vector2			cw;
   RIfloat			pathLength;
   unsigned int	flags;
   BOOL			inDash;
} StrokeVertex;
    
static inline StrokeVertex StrokeVertexInit(){
   StrokeVertex result;
   
   result.p=Vector2Make(0,0);
   result.t=Vector2Make(0,0);
   result.ccw=Vector2Make(0,0);
   result.cw=Vector2Make(0,0);
   result.pathLength=0;
   result.flags=0;
   result.inDash=NO;
        
   return result;
}
    
	//data produced by tessellation
typedef struct {
   int		start;
   int		end;
} VertexIndex;

@interface VGPath : KGPath {
    int      _capacityOfElements;
    int      _capacityOfPoints;
    
    int     _vertexCount;
    int     _vertexCapacity;
    Vertex *_vertices;
    
    int     _segmentToVertexCapacity;
    VertexIndex *_segmentToVertex;
    
	RIfloat				m_userMinx;
	RIfloat				m_userMiny;
	RIfloat				m_userMaxx;
	RIfloat				m_userMaxy;
}

VGPath *VGPathAlloc();
VGPath *VGPathInit(VGPath *self,int segmentCapacityHint, int coordCapacityHint);
void VGPathDealloc(VGPath *self);

void VGPathAppendData(VGPath *self,const RIuint8* segments, int numSegments, const CGPoint *data);	
void VGPathAppend(VGPath *self,VGPath* srcPath);	
void VGPathTransform(VGPath *self,VGPath* srcPath, Matrix3x3 matrix);	
	//returns YES if interpolation succeeds, NO if start and end paths are not compatible
void VGPathFill(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer);	
void VGPathStroke(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, BOOL dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit);	

void VGPathGetPointAlong(VGPath *self,int startIndex, int numSegments, RIfloat distance, Vector2 *p, Vector2 *t);	
RIfloat getPathLength(VGPath *self,int startIndex, int numSegments);	
void VGPathGetPathBounds(VGPath *self,RIfloat *minx, RIfloat *miny, RIfloat *maxx, RIfloat *maxy);	
void VGPathGetPathTransformedBounds(VGPath *self,Matrix3x3 pathToSurface, RIfloat *minx, RIfloat *miny, RIfloat *maxx, RIfloat *maxy);	

int CGPathElementTypeToNumCoordinates(CGPathElementType segment);
int VGPathCountNumCoordinates(const RIuint8* segments, int numSegments);

void VGPathAddVertex(VGPath *self,Vector2 p, Vector2 t, RIfloat pathLength, unsigned int flags);	
void VGPathAddEdge(VGPath *self,Vector2 p0, Vector2 p1, Vector2 t0, Vector2 t1, unsigned int startFlags, unsigned int endFlags);	

void VGPathAddEndPath(VGPath *self,Vector2 p0, Vector2 p1, BOOL subpathHasGeometry, unsigned int flags);	
BOOL VGPathAddLineTo(VGPath *self,Vector2 p0, Vector2 p1, BOOL subpathHasGeometry);	
BOOL VGPathAddQuadTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, BOOL subpathHasGeometry);	
BOOL VGPathAddCubicTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, BOOL subpathHasGeometry);	

void VGPathTessellate(VGPath *self);	

void VGPathInterpolateStroke(Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, RIfloat strokeWidth);	
void VGPathDoCap(Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v, RIfloat strokeWidth, CGLineCap capStyle);	
void VGPathDoJoin(Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit);	

@end
