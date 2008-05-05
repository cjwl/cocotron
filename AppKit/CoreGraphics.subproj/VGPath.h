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
   CGPoint			userPosition;
   CGPoint			userTangent;
   CGFloat			pathLength;
   unsigned int	flags;
} Vertex;
    
typedef struct  {
   CGPoint			p;
   CGPoint			t;
   CGPoint			ccw;
   CGPoint			cw;
   CGFloat			pathLength;
   unsigned int	flags;
   BOOL			inDash;
} StrokeVertex;
    
static inline StrokeVertex StrokeVertexInit(){
   StrokeVertex result;
   
   result.p=CGPointMake(0,0);
   result.t=CGPointMake(0,0);
   result.ccw=CGPointMake(0,0);
   result.cw=CGPointMake(0,0);
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
    
	CGFloat				m_userMinx;
	CGFloat				m_userMiny;
	CGFloat				m_userMaxx;
	CGFloat				m_userMaxy;
}

VGPath *VGPathAlloc();
VGPath *VGPathInit(VGPath *self,int segmentCapacityHint, int coordCapacityHint);
void VGPathDealloc(VGPath *self);

void VGPathAppendData(VGPath *self,const RIuint8* segments, int numSegments, const CGPoint *data);	
void VGPathAppend(VGPath *self,VGPath* srcPath);	
void VGPathTransform(VGPath *self,VGPath* srcPath, CGAffineTransform matrix);	
	//returns YES if interpolation succeeds, NO if start and end paths are not compatible
void VGPathFill(VGPath *self,CGAffineTransform pathToSurface, KGRasterizer *rasterizer);	
void VGPathStroke(VGPath *self,CGAffineTransform pathToSurface, KGRasterizer *rasterizer, const CGFloat* dashPattern,int dashPatternSize, CGFloat dashPhase, BOOL dashPhaseReset, CGFloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, CGFloat miterLimit);	

void VGPathGetPointAlong(VGPath *self,int startIndex, int numSegments, CGFloat distance, CGPoint *p, CGPoint *t);	
CGFloat getPathLength(VGPath *self,int startIndex, int numSegments);	
void VGPathGetPathBounds(VGPath *self,CGFloat *minx, CGFloat *miny, CGFloat *maxx, CGFloat *maxy);	
void VGPathGetPathTransformedBounds(VGPath *self,CGAffineTransform pathToSurface, CGFloat *minx, CGFloat *miny, CGFloat *maxx, CGFloat *maxy);	

int CGPathElementTypeToNumCoordinates(CGPathElementType segment);
int VGPathCountNumCoordinates(const RIuint8* segments, int numSegments);

void VGPathAddVertex(VGPath *self,CGPoint p, CGPoint t, CGFloat pathLength, unsigned int flags);	
void VGPathAddEdge(VGPath *self,CGPoint p0, CGPoint p1, CGPoint t0, CGPoint t1, unsigned int startFlags, unsigned int endFlags);	

void VGPathAddEndPath(VGPath *self,CGPoint p0, CGPoint p1, BOOL subpathHasGeometry, unsigned int flags);	
BOOL VGPathAddLineTo(VGPath *self,CGPoint p0, CGPoint p1, BOOL subpathHasGeometry);	
BOOL VGPathAddQuadTo(VGPath *self,CGPoint p0, CGPoint p1, CGPoint p2, BOOL subpathHasGeometry);	
BOOL VGPathAddCubicTo(VGPath *self,CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3, BOOL subpathHasGeometry);	

void VGPathTessellate(VGPath *self);	

void VGPathInterpolateStroke(CGAffineTransform pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, CGFloat strokeWidth);	
void VGPathDoCap(CGAffineTransform pathToSurface, KGRasterizer *rasterizer,StrokeVertex v, CGFloat strokeWidth, CGLineCap capStyle);	
void VGPathDoJoin(CGAffineTransform pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, CGFloat strokeWidth, CGLineJoin joinStyle, CGFloat miterLimit);	

@end
