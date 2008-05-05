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

#import "VGPath.h"
#import "VGmath.h"

	enum VertexFlags
	{
		START_SUBPATH			= (1<<0),
		END_SUBPATH				= (1<<1),
		START_SEGMENT			= (1<<2),
		END_SEGMENT				= (1<<3),
		CLOSE_SUBPATH			= (1<<4),
		IMPLICIT_CLOSE_SUBPATH	= (1<<5)
	};

#define RI_FLOAT_MAX FLT_MAX

static inline CGFloat inputFloat(CGFloat f) {
	//this function is used for all floating point input values
	if(RI_ISNAN(f)) return 0.0f;	//convert NaN to zero
	return RI_CLAMP(f, -RI_FLOAT_MAX, RI_FLOAT_MAX);	//clamp +-inf to +-CGFloat max
}

/*-------------------------------------------------------------------*//*!
* \brief	Form a reliable normalized average of the two unit input vectors.
*           The average always lies to the given direction from the first
*			vector.
* \param	u0, u1 Unit input vectors.
* \param	cw True if the average should be clockwise from u0, NO if
*              counterclockwise.
* \return	Average of the two input vectors.
* \note		
*//*-------------------------------------------------------------------*/

static CGPoint unitAverageWithDirection(CGPoint u0, CGPoint u1, BOOL cw)
{
	CGPoint u =Vector2MultiplyByFloat(Vector2Add(u0 , u1), 0.5f);
	CGPoint n0 = Vector2PerpendicularCCW(u0);

	if( Vector2Dot(u, u) > 0.25f )
	{	//the average is long enough and thus reliable
		if( Vector2Dot(n0, u1) < 0.0f )
			u = Vector2Negate(u);	//choose the larger angle
	}
	else
	{	// the average is too short, use the average of the normals to the vectors instead
		CGPoint n1 = Vector2PerpendicularCW(u1);
		u = Vector2MultiplyByFloat(Vector2Add(n0 , n1), 0.5f);
	}
	if( cw )
		u = Vector2Negate(u);

	return Vector2Normalize(u);
}

/*-------------------------------------------------------------------*//*!
* \brief	Form a reliable normalized average of the two unit input vectors.
*			The average lies on the side where the angle between the input
*			vectors is less than 180 degrees.
* \param	u0, u1 Unit input vectors.
* \return	Average of the two input vectors.
* \note		
*//*-------------------------------------------------------------------*/

static CGPoint unitAverage(CGPoint u0, CGPoint u1)
{
	CGPoint u =Vector2MultiplyByFloat(Vector2Add(u0 , u1), 0.5f);

	if( Vector2Dot(u, u) < 0.25f )
	{	// the average is unreliable, use the average of the normals to the vectors instead
		CGPoint n0 = Vector2PerpendicularCCW(u0);
		CGPoint n1 = Vector2PerpendicularCW(u1);
		u = Vector2MultiplyByFloat(Vector2Add(n0 , n1) , 0.5f);
		if( Vector2Dot(n1, u0) < 0.0f )
			u = Vector2Negate(u);
	}

	return Vector2Normalize(u);
}

/*-------------------------------------------------------------------*//*!
* \brief	Interpolate the given unit tangent vectors to the given
*			direction on a unit circle.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static CGPoint circularLerpWithDirection(CGPoint t0, CGPoint t1, CGFloat ratio, BOOL cw)
{
	CGPoint u0 = t0, u1 = t1;
	CGFloat l0 = 0.0f, l1 = 1.0f;
    int i;
	for(i=0;i<8;i++)
	{
		CGPoint n = unitAverageWithDirection(u0, u1, cw);
		CGFloat l = 0.5f * (l0 + l1);
		if( ratio < l )
		{
			u1 = n;
			l1 = l;
		}
		else
		{
			u0 = n;
			l0 = l;
		}
	}
	return u0;
}

/*-------------------------------------------------------------------*//*!
* \brief	Interpolate the given unit tangent vectors on a unit circle.
*			Smaller angle between the vectors is used.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static CGPoint circularLerp(CGPoint t0, CGPoint t1, CGFloat ratio)
{
	CGPoint u0 = t0, u1 = t1;
	CGFloat l0 = 0.0f, l1 = 1.0f;
    int i;
	for(i=0;i<8;i++)
	{
		CGPoint n = unitAverage(u0, u1);
		CGFloat l = 0.5f * (l0 + l1);
		if( ratio < l )
		{
			u1 = n;
			l1 = l;
		}
		else
		{
			u0 = n;
			l0 = l;
		}
	}
	return u0;
}

@implementation VGPath

static inline int VGPathGetNumCoordinates(VGPath *self){
   return self->_numberOfPoints;
}

VGPath *VGPathAlloc(){
   return (VGPath *)NSZoneCalloc(NULL,1,sizeof(VGPath));
}

VGPath *VGPathInit(VGPath *self,int segmentCapacityHint, int coordCapacityHint){
	self->m_userMinx=0.0f;
	self->m_userMiny=0.0f;
	self->m_userMaxx=0.0f;
	self->m_userMaxy=0.0f;
    self->_numberOfElements=0;
    self->_capacityOfElements=(segmentCapacityHint>0)?RI_INT_MIN(segmentCapacityHint,65536):2;
    self->_elements=NSZoneMalloc(NULL,self->_capacityOfElements*sizeof(unsigned char));
    self->_numberOfPoints=0;
    self->_capacityOfPoints=(coordCapacityHint>0)?RI_INT_MIN(coordCapacityHint, 65536):2;
    self->_points=NSZoneMalloc(NULL,self->_capacityOfPoints*sizeof(CGPoint));
    self->_vertexCount=0;
    self->_vertexCapacity=2;
    self->_vertices=NSZoneMalloc(NULL,self->_vertexCapacity*sizeof(Vertex));
    self->_segmentToVertexCapacity=2;
    self->_segmentToVertex=NSZoneMalloc(NULL,self->_segmentToVertexCapacity*sizeof(VertexIndex));
    return self;
}

/*-------------------------------------------------------------------*//*!
* \brief	VGPath destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathDealloc(VGPath *self){
   NSZoneFree(NULL,self->_elements);
   NSZoneFree(NULL,self->_points);
   NSZoneFree(NULL,self->_vertices);
   NSZoneFree(NULL,self->_segmentToVertex);
   NSZoneFree(NULL,self);
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a coordinate and applies scale and bias.
* \param	
* \return	
*//*-------------------------------------------------------------------*/

CGPoint VGPathGetCoordinate(VGPath *self,int i){
	RI_ASSERT(i >= 0 && i < self->_numberOfPoints);

    return self->_points[i];
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes a coordinate, subtracting bias and dividing out scale.
* \param	
* \return	
* \note		If the coordinates do not fit into path datatype range, they
*			will overflow silently.
*//*-------------------------------------------------------------------*/

void VGPathSetCoordinate(VGPath *self,int i, CGPoint c){
	RI_ASSERT(i >= 0);
    
    self->_points[i]=c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Given a path segment type, returns the number of coordinates
*			it uses.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int CGPathElementTypeToNumCoordinates(CGPathElementType segment){
	RI_ASSERT(((int)segment) >= 0 && ((int)segment) <= 4);
	static const int coords[13] = {1,1,2,3,0};
	return coords[(int)segment];
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the number of coordinates a segment sequence uses.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int VGPathCountNumCoordinates(const RIuint8* segments, int numSegments)
{
	RI_ASSERT(segments);
	RI_ASSERT(numSegments >= 0);

	int coordinates = 0;
    int i;
	for(i=0;i<numSegments;i++)
		coordinates += CGPathElementTypeToNumCoordinates((CGPathElementType)segments[i]);
	return coordinates;
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends user segments and data.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathAppendData(VGPath *self,const RIuint8* segments, int numSegments, const CGPoint* data){
	RI_ASSERT(numSegments > 0);
	RI_ASSERT(segments && data);

	//allocate new arrays
    RIuint8 *newSegments=NULL;
    int      newSegmentCapacity=self->_numberOfElements+numSegments;
    
    if(newSegmentCapacity>self->_capacityOfElements)
     newSegments=NSZoneMalloc(NULL,newSegmentCapacity*sizeof(unsigned char));
    
    CGPoint *newCoordinates=NULL;
    int      newCoordinateCount=VGPathCountNumCoordinates(segments,numSegments);
    int      newCoordinateCapacity=self->_numberOfPoints+newCoordinateCount;
    
    if(newCoordinateCapacity>self->_capacityOfPoints)
     newCoordinates=NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(CGPoint));
    
	//if we get here, the memory allocations have succeeded

	//copy old segments and append new ones
    int i;
    
    if(newSegments!=NULL){
     RIuint8 *tmp;

     for(i=0;i<self->_numberOfElements;i++)
      newSegments[i]=self->_elements[i];
      
     tmp=self->_elements;
     self->_elements=newSegments;
     self->_capacityOfElements=newSegmentCapacity;
     newSegments=tmp;
    }
    for(i=0;i<numSegments;i++)
     self->_elements[self->_numberOfElements++]=segments[i];
    
    if(newCoordinates!=NULL){
     CGPoint *tmp;

     for(i=0;i<self->_numberOfPoints;i++)
      newCoordinates[i]=self->_points[i];
      
     tmp=self->_points;
     self->_points=newCoordinates;
     self->_capacityOfPoints=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    for(i=0;i<newCoordinateCount;i++)
     self->_points[self->_numberOfPoints++]=CGPointMake(inputFloat(data[i].x),inputFloat(data[i].y));
     
	RI_ASSERT(self->_numberOfPoints == VGPathCountNumCoordinates(self->_elements,self->_numberOfElements));

    if(newSegments!=NULL)
     NSZoneFree(NULL,newSegments);
    if(newCoordinates!=NULL)
     NSZoneFree(NULL,newCoordinates);
     
	//clear tessellated path
	self-> _vertexCount=0;
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends a path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathAppend(VGPath *self,VGPath* srcPath){
	RI_ASSERT(srcPath);

	if(srcPath->_numberOfElements>0)
	{
		//allocate new arrays
        RIuint8 *newSegments=NULL;
        int      newSegmentCapacity=self->_numberOfElements+srcPath->_numberOfElements;
    
        if(newSegmentCapacity>self->_capacityOfElements)
            newSegments=NSZoneMalloc(NULL,newSegmentCapacity*sizeof(unsigned char));
    
        CGPoint *newCoordinates=NULL;
        int      newCoordinateCapacity=self->_numberOfPoints+VGPathGetNumCoordinates(srcPath);
    
        if(newCoordinateCapacity>self->_capacityOfPoints)
            newCoordinates=NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(CGPoint));

		//if we get here, the memory allocations have succeeded

		//copy old segments and append new ones
    int i;
    
    if(newSegments!=NULL){
     RIuint8 *tmp;

     for(i=0;i<self->_numberOfElements;i++)
      newSegments[i]=self->_elements[i];
      
     tmp=self->_elements;
     self->_elements=newSegments;
     self->_capacityOfElements=newSegmentCapacity;
     newSegments=tmp;
    }
    for(i=0;i<srcPath->_numberOfElements;i++)
     self->_elements[self->_numberOfElements++]=srcPath->_elements[i];
    
    if(newCoordinates!=NULL){
     CGPoint *tmp;

     for(i=0;i<self->_numberOfPoints;i++)
      newCoordinates[i]=self->_points[i];
      
     tmp=self->_points;
     self->_points=newCoordinates;
     self->_capacityOfPoints=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    for(i=0;i<VGPathGetNumCoordinates(srcPath);i++){
        VGPathSetCoordinate(self,self->_numberOfPoints++, VGPathGetCoordinate(srcPath,i));
     }
		RI_ASSERT(self->_numberOfPoints == VGPathCountNumCoordinates(self->_elements,self->_numberOfElements) );

    if(newSegments!=NULL)
     NSZoneFree(NULL,newSegments);
    if(newCoordinates!=NULL)
     NSZoneFree(NULL,newCoordinates);
	}

	//clear tessellated path
	self->_vertexCount=0;
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends a transformed copy of the source path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathTransform(VGPath *self,VGPath* srcPath, CGAffineTransform matrix){
	RI_ASSERT(srcPath);

	if(srcPath->_numberOfElements==0)
		return;

	//count the number of resulting coordinates
	int numSrcCoords = 0;
	int numDstCoords = 0;
    int i;
	for(i=0;i<srcPath->_numberOfElements;i++)
	{
		CGPathElementType segment = (CGPathElementType)srcPath->_elements[i];
		int coords = CGPathElementTypeToNumCoordinates(segment);
		numSrcCoords += coords;
		numDstCoords += coords;
	}

	//allocate new arrays
        RIuint8 *newSegments=NULL;
        int      newSegmentCapacity=self->_numberOfElements+srcPath->_numberOfElements;
    
        if(newSegmentCapacity>self->_capacityOfElements)
            newSegments=NSZoneMalloc(NULL,newSegmentCapacity*sizeof(RIuint8));
    
        CGPoint *newCoordinates=NULL;
        int      newCoordinateCapacity=self->_numberOfPoints+numDstCoords;
    
        if(newCoordinateCapacity>self->_capacityOfPoints)
            newCoordinates=NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(CGPoint));

	//if we get here, the memory allocations have succeeded

	//copy old segments
    if(newSegments!=NULL){
     RIuint8 *tmp;
          
     for(i=0;i<self->_numberOfElements;i++)
      newSegments[i]=self->_elements[i];
      
     tmp=self->_elements;
     self->_elements=newSegments;
     self->_capacityOfElements=newSegmentCapacity;
     newSegments=tmp;
    }

	//copy old data
    if(newCoordinates!=NULL){
     CGPoint *tmp;
     
     for(i=0;i<self->_numberOfPoints;i++)
      newCoordinates[i]=self->_points[i];
      
     tmp=self->_points;
     self->_points=newCoordinates;
     self->_capacityOfPoints=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    
	int srcCoord = 0;
	CGPoint s=CGPointMake(0,0);		//the beginning of the current subpath
	CGPoint o=CGPointMake(0,0);		//the last point of the previous segment
	for(i=0;i<srcPath->_numberOfElements;i++)
	{
		CGPathElementType segment = (CGPathElementType)srcPath->_elements[i];
		int coords = CGPathElementTypeToNumCoordinates(segment);

		switch(segment)
		{
		case kCGPathElementCloseSubpath:
		{
			RI_ASSERT(coords == 0);
			o = s;
			break;
		}

		case kCGPathElementMoveToPoint:
		{
			RI_ASSERT(coords == 1);
			CGPoint c=VGPathGetCoordinate(srcPath,srcCoord);
			CGPoint tc = Matrix3x3TransformVector2(matrix, c);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc);
			s = c;
			o = c;
			break;
		}

		case kCGPathElementAddLineToPoint:
		{
			RI_ASSERT(coords == 1);
			CGPoint c=VGPathGetCoordinate(srcPath,srcCoord);
			CGPoint tc = Matrix3x3TransformVector2(matrix, c);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc);
			o = c;
			break;
		}

		case kCGPathElementAddQuadCurveToPoint:
		{
			RI_ASSERT(coords == 2);
			CGPoint c0=VGPathGetCoordinate(srcPath,srcCoord);
			CGPoint c1=VGPathGetCoordinate(srcPath,srcCoord+1);
			CGPoint tc0 = Matrix3x3TransformVector2(matrix, c0);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc0);
			CGPoint tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc1);
			o = c1;
			break;
		}

		case kCGPathElementAddCurveToPoint:
		{
			RI_ASSERT(coords == 3);
			CGPoint c0=VGPathGetCoordinate(srcPath,srcCoord+0);
			CGPoint c1=VGPathGetCoordinate(srcPath,srcCoord+1);
			CGPoint c2=VGPathGetCoordinate(srcPath,srcCoord+2);
			CGPoint tc0 = Matrix3x3TransformVector2(matrix, c0);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc0);
			CGPoint tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc1);
			CGPoint tc2 = Matrix3x3TransformVector2(matrix, c2);
			VGPathSetCoordinate(self, self->_numberOfPoints++, tc2);
			o = c2;
			break;
		}

		}

		self->_elements[self->_numberOfElements++] = (RIuint8)segment;
		srcCoord += coords;
	}
	RI_ASSERT(srcCoord == numSrcCoords);

	RI_ASSERT(self->_numberOfPoints == VGPathCountNumCoordinates(self->_elements,self->_numberOfElements));

    if(newSegments!=NULL)
     NSZoneFree(NULL,newSegments);
    if(newCoordinates!=NULL)
     NSZoneFree(NULL,newCoordinates);

	//clear tessellated path
	self->_vertexCount=0;
}


/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path for filling and appends resulting edges
*			to a rasterizer.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathFill(VGPath *self,CGAffineTransform pathToSurface, KGRasterizer *rasterizer){

	VGPathTessellate(self);

//	try
	{
		CGPoint p0=CGPointMake(0,0), p1=CGPointMake(0,0);
        int     i;
		for(i=0;i<self->_vertexCount;i++)
		{
			p1 = Matrix3x3TransformVector2(pathToSurface, self->_vertices[i].userPosition);

			if(!(self->_vertices[i].flags & START_SEGMENT))
			{	//in the middle of a segment
				KGRasterizerAddEdge(rasterizer,p0, p1);
			}

			p0 = p1;
		}
	}
 #if 0
	catch(std::bad_alloc)
	{
		KGRasterizerClear(rasterizer);	//remove the unfinished path
		throw;
	}
#endif
}

/*-------------------------------------------------------------------*//*!
* \brief	Smoothly interpolates between two StrokeVertices. Positions
*			are interpolated linearly, while tangents are interpolated
*			on a unit circle. Stroking is implemented so that overlapping
*			geometry doesnt cancel itself when filled with nonzero rule.
*			The resulting polygons are closed.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathInterpolateStroke(CGAffineTransform pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, CGFloat strokeWidth)
{
	CGPoint ppccw = Matrix3x3TransformVector2(pathToSurface, v0.ccw);
	CGPoint ppcw = Matrix3x3TransformVector2(pathToSurface, v0.cw);
	CGPoint endccw = Matrix3x3TransformVector2(pathToSurface, v1.ccw);
	CGPoint endcw = Matrix3x3TransformVector2(pathToSurface, v1.cw);

	const CGFloat tessellationAngle = 5.0f;

	CGFloat angle = RI_RAD_TO_DEG((CGFloat)acos(RI_CLAMP(Vector2Dot(v0.t, v1.t), -1.0f, 1.0f))) / tessellationAngle;
	int samples = RI_INT_MAX((int)ceil(angle), 1);
	CGPoint prev = v0.p;
	CGPoint prevt = v0.t;
	CGPoint position = v0.p;
	CGPoint pnccw = ppccw;
	CGPoint pncw = ppcw;
    int     j;
	for(j=0;j<samples;j++)
	{
		CGFloat t = (CGFloat)(j+1) / (CGFloat)samples;
		position = Vector2Add(Vector2MultiplyByFloat(v0.p , (1.0f - t)) , Vector2MultiplyByFloat(v1.p ,t));
		CGPoint tangent = circularLerp(v0.t, v1.t, t);
		CGPoint n = Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCCW(tangent)) , strokeWidth * 0.5f);

		if(j == samples-1)
			position = v1.p;

		CGPoint npccw = Matrix3x3TransformVector2(pathToSurface, Vector2Add(prev, n));
		CGPoint npcw = Matrix3x3TransformVector2(pathToSurface, Vector2Subtract(prev, n));
		CGPoint nnccw = Matrix3x3TransformVector2(pathToSurface,Vector2Add(position,n));
		CGPoint nncw = Matrix3x3TransformVector2(pathToSurface, Vector2Subtract(position , n));

		KGRasterizerAddEdge(rasterizer,npccw, nnccw);
		KGRasterizerAddEdge(rasterizer,nnccw, nncw);
		KGRasterizerAddEdge(rasterizer,nncw, npcw);	
		KGRasterizerAddEdge(rasterizer,npcw, npccw);

		if(Vector2Dot(n,prevt) <= 0.0f)
		{
			KGRasterizerAddEdge(rasterizer,pnccw, npcw);
			KGRasterizerAddEdge(rasterizer,npcw, pncw);	
			KGRasterizerAddEdge(rasterizer,pncw, npccw);
			KGRasterizerAddEdge(rasterizer,npccw, pnccw);
		}
		else
		{
			KGRasterizerAddEdge(rasterizer,pnccw, npccw);
			KGRasterizerAddEdge(rasterizer,npccw, pncw);
			KGRasterizerAddEdge(rasterizer,pncw, npcw);	
			KGRasterizerAddEdge(rasterizer,npcw, pnccw);
		}

		ppccw = npccw;
		ppcw = npcw;
		pnccw = nnccw;
		pncw = nncw;
		prev = position;
		prevt = tangent;
	}

	//connect the last segment to the end coordinates
	CGPoint n = Vector2PerpendicularCCW(v1.t);
	if(Vector2Dot(n,prevt) <= 0.0f)
	{
		KGRasterizerAddEdge(rasterizer,pnccw, endcw);
		KGRasterizerAddEdge(rasterizer,endcw, pncw);
		KGRasterizerAddEdge(rasterizer,pncw, endccw);
		KGRasterizerAddEdge(rasterizer,endccw, pnccw);
	}
	else
	{
		KGRasterizerAddEdge(rasterizer,pnccw, endccw);
		KGRasterizerAddEdge(rasterizer,endccw, pncw);
		KGRasterizerAddEdge(rasterizer,pncw, endcw);
		KGRasterizerAddEdge(rasterizer,endcw, pnccw);
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generate edges for stroke caps. Resulting polygons are closed.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathDoCap(CGAffineTransform pathToSurface, KGRasterizer *rasterizer,StrokeVertex v, CGFloat strokeWidth, CGLineCap capStyle){
	CGPoint ccwt = Matrix3x3TransformVector2(pathToSurface, v.ccw);
	CGPoint cwt = Matrix3x3TransformVector2(pathToSurface, v.cw);

	switch(capStyle)
	{
	case kCGLineCapButt:
		break;

	case kCGLineCapRound:
	{
		const CGFloat tessellationAngle = 5.0f;

		CGFloat angle = 180.0f / tessellationAngle;

		int samples = (int)ceil(angle);
		CGFloat step = 1.0f / samples;
		CGFloat t = step;
		CGPoint u0 = Vector2Normalize(Vector2Subtract(v.ccw,v.p));
		CGPoint u1 = Vector2Normalize(Vector2Subtract(v.cw,v.p));
		CGPoint prev = ccwt;
		KGRasterizerAddEdge(rasterizer,cwt, ccwt);
        int j;
		for(j=1;j<samples;j++)
		{
			CGPoint next = Vector2Add(v.p , Vector2MultiplyByFloat(circularLerpWithDirection(u0, u1, t, YES) , strokeWidth * 0.5f));
			next = Matrix3x3TransformVector2(pathToSurface, next);

			KGRasterizerAddEdge(rasterizer,prev, next);
			prev = next;
			t += step;
		}
		KGRasterizerAddEdge(rasterizer,prev, cwt);
		break;
	}

	default:
	{
		RI_ASSERT(capStyle == kCGLineCapSquare);
		CGPoint t = v.t;
		t=Vector2Normalize(t);
		CGPoint ccws = Matrix3x3TransformVector2(pathToSurface, Vector2Add(v.ccw , Vector2MultiplyByFloat(t , strokeWidth * 0.5f)));
		CGPoint cws = Matrix3x3TransformVector2(pathToSurface, Vector2Add(v.cw , Vector2MultiplyByFloat(t , strokeWidth * 0.5f)));
		KGRasterizerAddEdge(rasterizer,cwt, ccwt);
		KGRasterizerAddEdge(rasterizer,ccwt, ccws);
		KGRasterizerAddEdge(rasterizer,ccws, cws);
		KGRasterizerAddEdge(rasterizer,cws, cwt);
		break;
	}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generate edges for stroke joins. Resulting polygons are closed.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathDoJoin(CGAffineTransform pathToSurface, KGRasterizer *rasterizer, StrokeVertex v0, StrokeVertex v1, CGFloat strokeWidth, CGLineJoin joinStyle, CGFloat miterLimit){
	CGPoint ccw0t = Matrix3x3TransformVector2(pathToSurface, v0.ccw);
	CGPoint cw0t = Matrix3x3TransformVector2(pathToSurface, v0.cw);
	CGPoint ccw1t = Matrix3x3TransformVector2(pathToSurface, v1.ccw);
	CGPoint cw1t = Matrix3x3TransformVector2(pathToSurface, v1.cw);
	CGPoint m0t = Matrix3x3TransformVector2(pathToSurface, v0.p);
	CGPoint m1t = Matrix3x3TransformVector2(pathToSurface, v1.p);

	CGPoint tccw = Vector2Subtract(v1.ccw,v0.ccw);
	CGPoint s, e, m, st, et;
	BOOL cw;

	if( Vector2Dot(tccw, v0.t) > 0.0f )
	{	//draw ccw miter (draw from point 0 to 1)
		s = ccw0t;
		e = ccw1t;
		st = v0.t;
		et = v1.t;
		m = v0.ccw;
		cw = NO;
		KGRasterizerAddEdge(rasterizer,m0t, ccw0t);
		KGRasterizerAddEdge(rasterizer,ccw1t, m1t);
		KGRasterizerAddEdge(rasterizer,m1t, m0t);
	}
	else
	{	//draw cw miter (draw from point 1 to 0)
		s = cw1t;
		e = cw0t;
		st = v1.t;
		et = v0.t;
		m = v0.cw;
		cw = YES;
		KGRasterizerAddEdge(rasterizer,cw0t, m0t);
		KGRasterizerAddEdge(rasterizer,m1t, cw1t);
		KGRasterizerAddEdge(rasterizer,m0t, m1t);
	}

	switch(joinStyle)
	{
	case kCGLineJoinMiter:
	{
		CGFloat theta = (CGFloat)acos(RI_CLAMP(Vector2Dot(v0.t, Vector2Negate(v1.t)), -1.0f, 1.0f));
		CGFloat miterLengthPerStrokeWidth = 1.0f / (CGFloat)sin(theta*0.5f);
		if( miterLengthPerStrokeWidth < miterLimit )
		{	//miter
			CGFloat l = (CGFloat)cos(theta*0.5f) * miterLengthPerStrokeWidth * (strokeWidth * 0.5f);
			l = RI_MIN(l, RI_FLOAT_MAX);	//force finite
			CGPoint c = Vector2Add(m , Vector2MultiplyByFloat(v0.t, l));
			c = Matrix3x3TransformVector2(pathToSurface, c);
			KGRasterizerAddEdge(rasterizer,s, c);
			KGRasterizerAddEdge(rasterizer,c, e);
		}
		else
		{	//bevel
			KGRasterizerAddEdge(rasterizer,s, e);
		}
		break;
	}

	case kCGLineJoinRound:
	{
		const CGFloat tessellationAngle = 5.0f;

		CGPoint prev = s;
		CGFloat angle = RI_RAD_TO_DEG((CGFloat)acos(RI_CLAMP(Vector2Dot(st, et), -1.0f, 1.0f))) / tessellationAngle;
		int samples = (int)ceil(angle);
		if( samples )
		{
			CGFloat step = 1.0f / samples;
			CGFloat t = step;
            int     j;
			for(j=1;j<samples;j++)
			{
				CGPoint position = Vector2Add(Vector2MultiplyByFloat(v0.p , (1.0f - t)) , Vector2MultiplyByFloat(v1.p , t));
				CGPoint tangent = circularLerpWithDirection(st, et, t, YES);

				CGPoint next = Vector2Add(position , Vector2MultiplyByFloat(Vector2Normalize(Vector2Perpendicular(tangent, cw)) , strokeWidth * 0.5f));
				next = Matrix3x3TransformVector2(pathToSurface, next);

				KGRasterizerAddEdge(rasterizer,prev, next);
				prev = next;
				t += step;
			}
		}
		KGRasterizerAddEdge(rasterizer,prev, e);
		break;
	}

	default:
		RI_ASSERT(joinStyle == kCGLineJoinBevel);
		if(!cw)
			KGRasterizerAddEdge(rasterizer,ccw0t, ccw1t);
		else
			KGRasterizerAddEdge(rasterizer,cw1t, cw0t);	
		break;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellate a path, apply stroking, dashing, caps and joins, and
*			append resulting edges to a rasterizer.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathStroke(VGPath *self,CGAffineTransform pathToSurface, KGRasterizer *rasterizer, const CGFloat* dashPattern,int dashPatternSize, CGFloat dashPhase, BOOL dashPhaseReset, CGFloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, CGFloat miterLimit){
	RI_ASSERT(strokeWidth >= 0.0f);
	RI_ASSERT(miterLimit >= 1.0f);

	VGPathTessellate(self);

	if(!self->_vertexCount)
		return;

	BOOL dashing = YES;

	if( dashPatternSize & 1 )
		dashPatternSize--;	//odd number of dash pattern entries, discard the last one
	CGFloat dashPatternLength = 0.0f;
    int     i;
	for(i=0;i<dashPatternSize;i++)
		dashPatternLength += RI_MAX(dashPattern[i], 0.0f);
	if(!dashPatternSize || dashPatternLength == 0.0f )
		dashing = NO;
	dashPatternLength = RI_MIN(dashPatternLength, RI_FLOAT_MAX);

	//walk along the path
	//stop at the next event which is either:
	//-path vertex
	//-dash stop
	//for robustness, decisions based on geometry are done only once.
	//inDash keeps track whether the last point was in dash or not

	//loop vertex events
//	try
	{
		CGFloat nextDash = 0.0f;
		int d = 0;
		BOOL inDash = YES;
		StrokeVertex v0=StrokeVertexInit(), v1=StrokeVertexInit(), vs=StrokeVertexInit();
        
		for(i=0;i<self->_vertexCount;i++)
		{
			//read the next vertex
			const Vertex v = self->_vertices[i];
			v1.p = v.userPosition;
			v1.t = v.userTangent;
			RI_ASSERT(!Vector2IsZero(v1.t));	//don't allow zero tangents
			v1.ccw = Vector2Add(v1.p , Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCCW(v1.t)) , strokeWidth * 0.5f));
			v1.cw = Vector2Add(v1.p , Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCW(v1.t)) , strokeWidth * 0.5f));
			v1.pathLength = v.pathLength;
			v1.flags = v.flags;
			v1.inDash = dashing ? inDash : YES;	//NOTE: for other than START_SEGMENT vertices inDash will be updated after dashing

			//process the vertex event
			if(v.flags & START_SEGMENT)
			{
				if(v.flags & START_SUBPATH)
				{
					if( dashing )
					{	//initialize dashing by finding which dash or gap the first point of the path lies in
						if(dashPhaseReset || i == 0)
						{
							d = 0;
							inDash = YES;
							nextDash = v1.pathLength - RI_MOD(dashPhase, dashPatternLength);
							for(;;)
							{
								CGFloat prevDash = nextDash;
								nextDash = prevDash + RI_MAX(dashPattern[d], 0.0f);
								if(nextDash >= v1.pathLength)
									break;

								if( d & 1 )
									inDash = YES;
								else
									inDash = NO;
								d = (d+1) % dashPatternSize;
							}
							v1.inDash = inDash;
							//the first point of the path lies between prevDash and nextDash
							//d in the index of the next dash stop
							//inDash is YES if the first point is in a dash
						}
					}
					vs = v1;	//save the subpath start point
				}
				else
				{
					if( v.flags & IMPLICIT_CLOSE_SUBPATH )
					{	//do caps for the start and end of the current subpath
						if( v0.inDash )
							VGPathDoCap(pathToSurface, rasterizer, v0, strokeWidth, capStyle);	//end cap
						if( vs.inDash )
						{
							StrokeVertex vi = vs;
							vi.t = Vector2Negate(vi.t);
							RI_SWAP(&vi.ccw.x, &vi.cw.x);
							RI_SWAP(&vi.ccw.y, &vi.cw.y);
							VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap
						}
					}
					else
					{	//join two segments
						RI_ASSERT(v0.inDash == v1.inDash);
						if( v0.inDash )
							VGPathDoJoin(pathToSurface, rasterizer, v0, v1, strokeWidth, joinStyle, miterLimit);
					}
				}
			}
			else
			{	//in the middle of a segment
				if( !(v.flags & IMPLICIT_CLOSE_SUBPATH) )
				{	//normal segment, do stroking
					if( dashing )
					{
						StrokeVertex prevDashVertex = v0;	//dashing of the segment starts from the previous vertex

						if(nextDash + 10000.0f * dashPatternLength < v1.pathLength)
                            NSLog(@"too many dashes");

						//loop dash events until the next vertex event
						//zero length dashes are handled as a special case since if they hit the vertex,
						//we want to include their starting point to this segment already in order to generate a join
						int numDashStops = 0;
						while(nextDash < v1.pathLength || (nextDash <= v1.pathLength && dashPattern[(d+1) % dashPatternSize] == 0.0f))
						{
							CGFloat edgeLength = v1.pathLength - v0.pathLength;
							CGFloat ratio = 0.0f;
							if(edgeLength > 0.0f)
								ratio = (nextDash - v0.pathLength) / edgeLength;
							StrokeVertex nextDashVertex=StrokeVertexInit();
							nextDashVertex.p = Vector2Add(Vector2MultiplyByFloat(v0.p , (1.0f - ratio)) , Vector2MultiplyByFloat(v1.p , ratio));
							nextDashVertex.t = circularLerp(v0.t, v1.t, ratio);
							nextDashVertex.ccw = Vector2Add(nextDashVertex.p , Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCCW(nextDashVertex.t)) , strokeWidth * 0.5f));
							nextDashVertex.cw = Vector2Add(nextDashVertex.p , Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCW(nextDashVertex.t)) , strokeWidth * 0.5f));

							if( inDash )
							{	//stroke from prevDashVertex -> nextDashVertex
								if( numDashStops )
								{	//prevDashVertex is not the start vertex of the segment, cap it (start vertex has already been joined or capped)
									StrokeVertex vi = prevDashVertex;
									vi.t = Vector2Negate(vi.t);
									RI_SWAP(&vi.ccw.x, &vi.cw.x);
									RI_SWAP(&vi.ccw.y, &vi.cw.y);
									VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);
								}
								VGPathInterpolateStroke(pathToSurface, rasterizer, prevDashVertex, nextDashVertex, strokeWidth);
								VGPathDoCap(pathToSurface, rasterizer, nextDashVertex, strokeWidth, capStyle);	//end cap
							}
							prevDashVertex = nextDashVertex;

							if( d & 1 )
							{	//dash starts
								RI_ASSERT(!inDash);
								inDash = YES;
							}
							else
							{	//dash ends
								RI_ASSERT(inDash);
								inDash = NO;
							}
							d = (d+1) % dashPatternSize;
							nextDash += RI_MAX(dashPattern[d], 0.0f);
							numDashStops++;
						}
						
						if( inDash )
						{	//stroke prevDashVertex -> v1
							if( numDashStops )
							{	//prevDashVertex is not the start vertex of the segment, cap it (start vertex has already been joined or capped)
								StrokeVertex vi = prevDashVertex;
								vi.t = Vector2Negate(vi.t);
								RI_SWAP(&vi.ccw.x, &vi.cw.x);
								RI_SWAP(&vi.ccw.y, &vi.cw.y);
								VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);
							}
							VGPathInterpolateStroke(pathToSurface, rasterizer, prevDashVertex, v1, strokeWidth);
							//no cap, leave path open
						}

						v1.inDash = inDash;	//update inDash status of the segment end point
					}
					else	//no dashing, just interpolate segment end points
						VGPathInterpolateStroke(pathToSurface, rasterizer, v0, v1, strokeWidth);
				}
			}

			if((v.flags & END_SEGMENT) && (v.flags & CLOSE_SUBPATH))
			{	//join start and end of the current subpath
				if( v1.inDash && vs.inDash )
					VGPathDoJoin(pathToSurface, rasterizer, v1, vs, strokeWidth, joinStyle, miterLimit);
				else
				{	//both start and end are not in dash, cap them
					if( v1.inDash )
						VGPathDoCap(pathToSurface, rasterizer, v1, strokeWidth, capStyle);	//end cap
					if( vs.inDash )
					{
						StrokeVertex vi = vs;
						vi.t = Vector2Negate(vi.t);
						RI_SWAP(&vi.ccw.x, &vi.cw.x);
						RI_SWAP(&vi.ccw.y, &vi.cw.y);
						VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap
					}
				}
			}

			v0 = v1;
		}
	}
 #if 0
	catch(std::bad_alloc)
	{
		KGRasterizerClear(rasterizer);	//remove the unfinished path
		throw;
	}
#endif
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and returns a position and a tangent on the path
*			given a distance along the path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathGetPointAlong(VGPath *self,int startIndex, int numSegments, CGFloat distance, CGPoint *p, CGPoint *t){
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= self->_numberOfElements && numSegments > 0);

	VGPathTessellate(self);

	RI_ASSERT(startIndex >= 0 && startIndex < self->_numberOfElements);
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= self->_numberOfElements);

	int startVertex = self->_segmentToVertex[startIndex].start;
	int endVertex = self->_segmentToVertex[startIndex + numSegments - 1].end;

	if(!self->_vertexCount || (startVertex == -1 && endVertex == -1))
	{	// no vertices in the tessellated path. The path is empty or consists only of zero-length segments.
		*p=CGPointMake(0,0);
		*t=CGPointMake(1,0);
		return;
	}
	if(startVertex == -1)
		startVertex = 0;

	RI_ASSERT(startVertex >= 0 && startVertex < self->_vertexCount);
	RI_ASSERT(endVertex >= 0 && endVertex < self->_vertexCount);

	distance += self->_vertices[startVertex].pathLength;	//map distance to the range of the whole path

	if(distance <= self->_vertices[startVertex].pathLength)
	{	//return the first point of the path
		*p = self->_vertices[startVertex].userPosition;
		*t = self->_vertices[startVertex].userTangent;
		return;
	}

	if(distance >= self->_vertices[endVertex].pathLength)
	{	//return the last point of the path
		*p = self->_vertices[endVertex].userPosition;
		*t = self->_vertices[endVertex].userTangent;
		return;
	}

	//search for the segment containing the distance
    int s;
	for(s=startIndex;s<startIndex+numSegments;s++)
	{
		int start = self->_segmentToVertex[s].start;
		int end = self->_segmentToVertex[s].end;
		if(start < 0)
			start = 0;
		if(end < 0)
			end = 0;
		RI_ASSERT(start >= 0 && start < self->_vertexCount);
		RI_ASSERT(end >= 0 && end < self->_vertexCount);

		if(distance >= self->_vertices[start].pathLength && distance < self->_vertices[end].pathLength)
		{	//segment contains the queried distance
            int i;
			for(i=start;i<end;i++)
			{
				Vertex v0 = self->_vertices[i];
				Vertex v1 = self->_vertices[i+1];
				if(distance >= v0.pathLength && distance < v1.pathLength)
				{	//segment found, interpolate linearly between its end points
					CGFloat edgeLength = v1.pathLength - v0.pathLength;
					RI_ASSERT(edgeLength > 0.0f);
					CGFloat r = (distance - v0.pathLength) / edgeLength;
					*p = Vector2Add(Vector2MultiplyByFloat(v0.userPosition , (1.0f - r)) , Vector2MultiplyByFloat(v1.userPosition , r));
					*t = Vector2Add(Vector2MultiplyByFloat(v0.userTangent,(1.0f - r))  , Vector2MultiplyByFloat(v1.userTangent,r));
					return;
				}
			}
		}
	}

	RI_ASSERT(0);	//point not found (should never get here)
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and computes its length.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

CGFloat getPathLength(VGPath *self,int startIndex, int numSegments){
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= self->_numberOfElements && numSegments > 0);

	VGPathTessellate(self);

	RI_ASSERT(startIndex >= 0 && startIndex < self->_numberOfElements);
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= self->_numberOfElements);

	int startVertex = self->_segmentToVertex[startIndex].start;
	int endVertex = self->_segmentToVertex[startIndex + numSegments - 1].end;

	if(!self->_vertexCount)
		return 0.0f;

	CGFloat startPathLength = 0.0f;
	if(startVertex >= 0)
	{
		RI_ASSERT(startVertex >= 0 && startVertex < self->_vertexCount);
		startPathLength = self->_vertices[startVertex].pathLength;
	}
	CGFloat endPathLength = 0.0f;
	if(endVertex >= 0)
	{
		RI_ASSERT(endVertex >= 0 && endVertex < self->_vertexCount);
		endPathLength = self->_vertices[endVertex].pathLength;
	}

	return endPathLength - startPathLength;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and computes its bounding box in user space.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathGetPathBounds(VGPath *self,CGFloat *minx, CGFloat *miny, CGFloat *maxx, CGFloat *maxy){
	VGPathTessellate(self);

	if(self->_vertexCount)
	{
		*minx = self->m_userMinx;
		*miny = self->m_userMiny;
		*maxx = self->m_userMaxx;
		*maxy = self->m_userMaxy;
	}
	else
	{
		*minx = *miny = 0;
		*maxx = *maxy = -1;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and computes its bounding box in surface space.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathGetPathTransformedBounds(VGPath *self,CGAffineTransform pathToSurface, CGFloat *minx, CGFloat *miny, CGFloat *maxx, CGFloat *maxy){

	VGPathTessellate(self);

	if(self->_vertexCount)
	{
		CGPoint p0=CGPointMake(self->m_userMinx, self->m_userMiny);
		CGPoint p1=CGPointMake(self->m_userMinx, self->m_userMaxy);
		CGPoint p2=CGPointMake(self->m_userMaxx, self->m_userMaxy);
		CGPoint p3=CGPointMake(self->m_userMaxx, self->m_userMiny);
		p0 = Matrix3x3TransformVector2(pathToSurface,p0);
		p1 = Matrix3x3TransformVector2(pathToSurface, p1);
		p2 = Matrix3x3TransformVector2(pathToSurface, p2);
		p3 = Matrix3x3TransformVector2(pathToSurface,p3);

		*minx = RI_MIN(RI_MIN(RI_MIN(p0.x, p1.x), p2.x), p3.x);
		*miny = RI_MIN(RI_MIN(RI_MIN(p0.y, p1.y), p2.y), p3.y);
		*maxx = RI_MAX(RI_MAX(RI_MAX(p0.x, p1.x), p2.x), p3.x);
		*maxy = RI_MAX(RI_MAX(RI_MAX(p0.y, p1.y), p2.y), p3.y);
	}
	else
	{
		*minx = *miny = 0;
		*maxx = *maxy = -1;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Adds a vertex to a tessellated path.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathAddVertex(VGPath *self,CGPoint p, CGPoint t, CGFloat pathLength, unsigned int flags){
	RI_ASSERT(!Vector2IsZero(t));

	Vertex v;
	v.pathLength = pathLength;
	v.userPosition = p;
	v.userTangent = t;
	v.flags = flags;
    
    if(self->_vertexCount+1>self->_vertexCapacity){
     self->_vertexCapacity*=2;
     self->_vertices=(Vertex *)NSZoneRealloc(NULL,self->_vertices,self->_vertexCapacity*sizeof(Vertex));
    }
    self->_vertices[self->_vertexCount++]=v;

	self->m_userMinx = RI_MIN(self->m_userMinx, v.userPosition.x);
	self->m_userMiny = RI_MIN(self->m_userMiny, v.userPosition.y);
	self->m_userMaxx = RI_MAX(self->m_userMaxx, v.userPosition.x);
	self->m_userMaxy = RI_MAX(self->m_userMaxy, v.userPosition.y);
}

/*-------------------------------------------------------------------*//*!
* \brief	Adds an edge to a tessellated path.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathAddEdge(VGPath *self,CGPoint p0, CGPoint p1, CGPoint t0, CGPoint t1, unsigned int startFlags, unsigned int endFlags){
	CGFloat pathLength = 0.0f;

	RI_ASSERT(!Vector2IsZero(t0) && !Vector2IsZero(t1));

	//segment midpoints are shared between edges
	if( startFlags & START_SEGMENT )
	{
		if(self->_vertexCount > 0)
			pathLength = self->_vertices[self->_vertexCount-1].pathLength;

		VGPathAddVertex(self,p0, t0, pathLength, startFlags);
	}

	//other than implicit close paths (caused by a MOVE_TO) add to path length
	if( !(endFlags & IMPLICIT_CLOSE_SUBPATH) )
	{
		//NOTE: with extremely large coordinates the floating point path length is infinite
		CGFloat l = Vector2Length(Vector2Subtract(p1,p0));
		pathLength = self->_vertices[self->_vertexCount-1].pathLength + l;
		pathLength = RI_MIN(pathLength, RI_FLOAT_MAX);
	}

	VGPathAddVertex(self,p1, t1, pathLength, endFlags);
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a close-path segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathAddEndPath(VGPath *self,CGPoint p0, CGPoint p1, BOOL subpathHasGeometry, unsigned int flags){
	if(!subpathHasGeometry)
	{	//single vertex
		CGPoint t=CGPointMake(1.0f,0.0f);
		VGPathAddEdge(self,p0, p1, t, t, START_SEGMENT | START_SUBPATH, END_SEGMENT | END_SUBPATH);
		VGPathAddEdge(self,p0, p1, Vector2Negate(t), Vector2Negate(t), IMPLICIT_CLOSE_SUBPATH | START_SEGMENT, IMPLICIT_CLOSE_SUBPATH | END_SEGMENT);
		return;
	}
	//the subpath contains segment commands that have generated geometry

	//add a close path segment to the start point of the subpath
	RI_ASSERT(self->_vertexCount > 0);
	self->_vertices[self->_vertexCount-1].flags |= END_SUBPATH;

	CGPoint t = Vector2Normalize(Vector2Subtract(p1,p0));
	if(Vector2IsZero(t))
		t = self->_vertices[self->_vertexCount-1].userTangent;	//if the segment is zero-length, use the tangent of the last segment end point so that proper join will be generated
	RI_ASSERT(!Vector2IsZero(t));

	VGPathAddEdge(self,p0, p1, t, t, flags | START_SEGMENT, flags | END_SEGMENT);
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a line-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

BOOL VGPathAddLineTo(VGPath *self,CGPoint p0, CGPoint p1, BOOL subpathHasGeometry){
	if(Vector2IsEqual(p0 ,p1))
		return NO;	//discard zero-length segments

	//compute end point tangents
	CGPoint t = Vector2Normalize(Vector2Subtract(p1,p0));
	RI_ASSERT(!Vector2IsZero(t));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;
	VGPathAddEdge(self,p0, p1, t, t, startFlags, END_SEGMENT);
	return YES;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a quad-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

/*
 Given a quadratic BŽzier curve with control points (x0, y0), (x1, y1), and (x2, y2), an identical cubic BŽzier curve may be formed using the control points (x0, y0), (x0 + 2*x1, y0 + 2*y1)/3, (x2 + 2*x1, y2 + 2*y1)/3, (x2, y2)
  */
  
BOOL VGPathAddQuadTo(VGPath *self,CGPoint p0, CGPoint p1, CGPoint p2, BOOL subpathHasGeometry){
	if(Vector2IsEqual(p0,p1) && Vector2IsEqual(p0,p2))
	{
		RI_ASSERT(Vector2IsEqual(p1,p2));
		return NO;	//discard zero-length segments
	}

	//compute end point tangents

	CGPoint incomingTangent = Vector2Normalize(Vector2Subtract(p1,p0));
	CGPoint outgoingTangent = Vector2Normalize(Vector2Subtract(p2,p1));
	if(Vector2IsEqual(p0,p1))
		incomingTangent = Vector2Normalize(Vector2Subtract(p2,p0));
	if(Vector2IsEqual(p1,p2))
		outgoingTangent = Vector2Normalize(Vector2Subtract(p2 ,p0));
	RI_ASSERT(!Vector2IsZero(incomingTangent) && !Vector2IsZero(outgoingTangent));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

	const int segments = 256;
	CGPoint pp = p0;
	CGPoint tp = incomingTangent;
	unsigned int prevFlags = startFlags;
    int i;
	for(i=1;i<segments;i++)
	{
		CGFloat t = (CGFloat)i / (CGFloat)segments;
		CGFloat u = 1.0f-t;
		CGPoint pn = Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,u*u) , Vector2MultiplyByFloat(p1,2.0f*t*u)),Vector2MultiplyByFloat(p2,t*t));
		CGPoint tn = Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,(-1.0f+t)), Vector2MultiplyByFloat(p1,(1.0f-2.0f*t))),Vector2MultiplyByFloat(p2,t));
		tn = Vector2Normalize(tn);
		if(Vector2IsZero(tn))
			tn = tp;

		VGPathAddEdge(self,pp, pn, tp, tn, prevFlags, 0);

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	VGPathAddEdge(self,pp, p2, tp, outgoingTangent, prevFlags, END_SEGMENT);
	return YES;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a cubic-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

// Bezier to lines from: Windows Graphics Programming by Feng Yuan
static void bezier(VGPath *self,double x1,double y1,double x2, double y2,double x3,double y3,double x4,double y4,unsigned *prevFlags,CGPoint *pp,CGPoint *tp){
   // Ax+By+C=0 is the line (x1,y1) (x4,y4);
   double A=y4-y1;
   double B=x1-x4;
   double C=y1*(x4-x1)-x1*(y4-y1);
   double AB=A*A+B*B;

   if((A*x2+B*y2+C)*(A*x2+B*y2+C)<AB && (A*x3+B*y3+C)*(A*x3+B*y3+C)<AB){
    CGPoint v0=CGPointMake(x1,y1);
    CGPoint v1=CGPointMake(x4,y4);
    CGPoint t = Vector2Normalize(Vector2Subtract(v1,v0));

    VGPathAddEdge(self,v0, v1, *tp, t, *prevFlags, 0);
    *prevFlags=0;
    *pp=v1;
    *tp=t;
    return;
   }
   else {
    double x12=x1+x2;
    double y12=y1+y2;
    double x23=x2+x3;
    double y23=y2+y3;
    double x34=x3+x4;
    double y34=y3+y4;
    double x1223=x12+x23;
    double y1223=y12+y23;
    double x2334=x23+x34;
    double y2334=y23+y34;
    double x=x1223+x2334;
    double y=y1223+y2334;

    bezier(self,x1,y1,x12/2,y12/2,x1223/4,y1223/4,x/8,y/8,prevFlags,pp,tp);
    bezier(self,x/8,y/8,x2334/4,y2334/4,x34/2,y34/2,x4,y4,prevFlags,pp,tp);
   }
}

BOOL VGPathAddCubicTo(VGPath *self,CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3, BOOL subpathHasGeometry){
	if(Vector2IsEqual(p0,p1) && Vector2IsEqual(p0,p2) && Vector2IsEqual(p0 ,p3))
	{
		RI_ASSERT(Vector2IsEqual(p1 , p2) && Vector2IsEqual(p1 , p3) && Vector2IsEqual(p2 , p3));
		return NO;	//discard zero-length segments
	}

	//compute end point tangents
	CGPoint incomingTangent = Vector2Normalize(Vector2Subtract(p1, p0));
	CGPoint outgoingTangent = Vector2Normalize(Vector2Subtract(p3, p2));
	if(Vector2IsEqual(p0 , p1))
	{
		incomingTangent = Vector2Normalize(Vector2Subtract(p2 ,p0));
		if(Vector2IsEqual(p1, p2))
			incomingTangent = Vector2Normalize(Vector2Subtract(p3,p0));
	}
	if(Vector2IsEqual(p2, p3))
	{
		outgoingTangent = Vector2Normalize(Vector2Subtract(p3 ,p1));
		if(Vector2IsEqual(p1, p2))
			outgoingTangent = Vector2Normalize(Vector2Subtract(p3,p0));
	}
	RI_ASSERT(!Vector2IsZero(incomingTangent) && !Vector2IsZero(outgoingTangent));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

#if 1
// This works, but does not take the CTM (i.e. scaling) into effect
	unsigned int prevFlags = startFlags;
	CGPoint pp = p0;
	CGPoint tp = incomingTangent;
    bezier(self,p0.x,p0.y,p1.x,p1.y,p2.x,p2.y,p3.x,p3.y,&prevFlags,&pp,&tp);
	VGPathAddEdge(self,pp, p3, tp, outgoingTangent, prevFlags, END_SEGMENT);
#else
	const int segments = 256;
	CGPoint pp = p0;
	CGPoint tp = incomingTangent;
	unsigned int prevFlags = startFlags;
    int i;
	for(i=1;i<segments;i++)
	{
		CGFloat t = (CGFloat)i / (CGFloat)segments;
		CGFloat u = 1.0f-t;
		CGPoint pn = Vector2Add(Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,u*u*u), Vector2MultiplyByFloat(p1,3.0f*t*u*u)) ,Vector2MultiplyByFloat(p2,3.0f*t*t*u)),Vector2MultiplyByFloat(p3,t*t*t));
		CGPoint tn = Vector2Add(Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,(-1.0f + 2.0f*t - t*t)) , Vector2MultiplyByFloat(p1,(1.0f - 4.0f*t + 3.0f*t*t))) , Vector2MultiplyByFloat(p2,(2.0f*t - 3.0f*t*t) )) ,Vector2MultiplyByFloat(p3,t*t));
		tn = Vector2Normalize(tn);
		if(Vector2IsZero(tn))
			tn = tp;

		VGPathAddEdge(self,pp, pn, tp, tn, prevFlags, 0);

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	VGPathAddEdge(self,pp, p3, tp, outgoingTangent, prevFlags, END_SEGMENT);
#endif
	return YES;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path.
* \param	
* \return	
* \note		tessellation output format: A list of vertices describing the
*			path tessellated into line segments and relevant aspects of the
*			input data. Each path segment has a start vertex, a number of
*			internal vertices (possibly zero), and an end vertex. The start
*			and end of segments and subpaths have been flagged, as well as
*			implicit and explicit close subpath segments.
*//*-------------------------------------------------------------------*/

void VGPathTessellate(VGPath *self){
	if( self->_vertexCount > 0 )
		return;	//already tessellated

	self->m_userMinx = RI_FLOAT_MAX;
	self->m_userMiny = RI_FLOAT_MAX;
	self->m_userMaxx = -RI_FLOAT_MAX;
	self->m_userMaxy = -RI_FLOAT_MAX;

//	try
	{
        if(self->_segmentToVertexCapacity<self->_numberOfElements){
         self->_segmentToVertexCapacity=self->_numberOfElements;
         self->_segmentToVertex=NSZoneMalloc(NULL,self->_segmentToVertexCapacity*sizeof(VertexIndex));
        }
        
		int coordIndex = 0;
		CGPoint s=CGPointMake(0,0);		//the beginning of the current subpath
		CGPoint o=CGPointMake(0,0);		//the last point of the previous segment
		CGPoint p=CGPointMake(0,0);		//the last internal control point of the previous segment, if the segment was a (regular or smooth) quadratic or cubic Bezier, or else the last point of the previous segment

		//tessellate the path segments
		coordIndex = 0;
		s=CGPointMake(0,0);
		o=CGPointMake(0,0);
		p=CGPointMake(0,0);
		BOOL subpathHasGeometry = NO;
		CGPathElementType prevSegment = kCGPathElementMoveToPoint;
        int i;
		for(i=0;i<self->_numberOfElements;i++)
		{
			CGPathElementType segment = (CGPathElementType)self->_elements[i];
			int coords = CGPathElementTypeToNumCoordinates(segment);
			self->_segmentToVertex[i].start = self->_vertexCount;

			switch(segment)
			{
			case kCGPathElementCloseSubpath:
			{
				RI_ASSERT(coords == 0);
				VGPathAddEndPath(self,o, s, subpathHasGeometry, CLOSE_SUBPATH);
				p = s;
				o = s;
				subpathHasGeometry = NO;
				break;
			}

			case kCGPathElementMoveToPoint:
			{
				RI_ASSERT(coords == 1);
				CGPoint c=VGPathGetCoordinate(self,coordIndex);
				if(prevSegment != kCGPathElementMoveToPoint && prevSegment != kCGPathElementCloseSubpath)
					VGPathAddEndPath(self,o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);
				s = c;
				p = c;
				o = c;
				subpathHasGeometry = NO;
				break;
			}

			case kCGPathElementAddLineToPoint:
			{
				RI_ASSERT(coords == 1);
				CGPoint c=VGPathGetCoordinate(self,coordIndex);
				if(VGPathAddLineTo(self,o, c, subpathHasGeometry))
					subpathHasGeometry = YES;
				p = c;
				o = c;
				break;
			}

			case kCGPathElementAddQuadCurveToPoint:
			{
				RI_ASSERT(coords == 2);
				CGPoint c0=VGPathGetCoordinate(self,coordIndex);
				CGPoint c1=VGPathGetCoordinate(self,coordIndex+1);
				if(VGPathAddQuadTo(self,o, c0, c1, subpathHasGeometry))
					subpathHasGeometry = YES;
				p = c0;
				o = c1;
				break;
			}

			case kCGPathElementAddCurveToPoint:
			{
				RI_ASSERT(coords == 3);
				CGPoint c0=VGPathGetCoordinate(self,coordIndex+0);
				CGPoint c1=VGPathGetCoordinate(self,coordIndex+1);
				CGPoint c2=VGPathGetCoordinate(self,coordIndex+2);
				if(VGPathAddCubicTo(self,o, c0, c1, c2, subpathHasGeometry))
					subpathHasGeometry = YES;
				p = c1;
				o = c2;
				break;
			}

			}

			if(self->_vertexCount > self->_segmentToVertex[i].start)
			{	//segment produced vertices
				self->_segmentToVertex[i].end = self->_vertexCount - 1;
			}
			else
			{	//segment didn't produce vertices (zero-length segment). Ignore it.
				self->_segmentToVertex[i].start = self->_segmentToVertex[i].end = self->_vertexCount-1;
			}
			prevSegment = segment;
			coordIndex += coords;
		}

		//add an implicit MOVE_TO to the end to close the last subpath.
		//if the subpath contained only zero-length segments, this produces the necessary geometry to get it stroked
		// and included in path bounds. The geometry won't be included in the pointAlongPath query.
		if(prevSegment != kCGPathElementMoveToPoint && prevSegment != kCGPathElementCloseSubpath)
			VGPathAddEndPath(self,o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);

#if 0 // DEBUG
		//check that the flags are correct
		int prev = -1;
		BOOL subpathStarted = NO;
		BOOL segmentStarted = NO;
		for(int i=0;i<self->_vertexCount;i++)
		{
			Vertex& v = self->_vertices[i];

			if(v.flags & START_SUBPATH)
			{
				RI_ASSERT(!subpathStarted);
				RI_ASSERT(v.flags & START_SEGMENT);
				RI_ASSERT(!(v.flags & END_SUBPATH));
				RI_ASSERT(!(v.flags & END_SEGMENT));
				RI_ASSERT(!(v.flags & CLOSE_SUBPATH));
				RI_ASSERT(!(v.flags & IMPLICIT_CLOSE_SUBPATH));
				subpathStarted = YES;
			}
			
			if(v.flags & START_SEGMENT)
			{
				RI_ASSERT(subpathStarted || (v.flags & CLOSE_SUBPATH) || (v.flags & IMPLICIT_CLOSE_SUBPATH));
				RI_ASSERT(!segmentStarted);
				RI_ASSERT(!(v.flags & END_SUBPATH));
				RI_ASSERT(!(v.flags & END_SEGMENT));
				segmentStarted = YES;
			}
			
			if( v.flags & CLOSE_SUBPATH )
			{
				RI_ASSERT(segmentStarted);
				RI_ASSERT(!subpathStarted);
				RI_ASSERT((v.flags & START_SEGMENT) || (v.flags & END_SEGMENT));
				RI_ASSERT(!(v.flags & IMPLICIT_CLOSE_SUBPATH));
				RI_ASSERT(!(v.flags & START_SUBPATH));
				RI_ASSERT(!(v.flags & END_SUBPATH));
			}
			if( v.flags & IMPLICIT_CLOSE_SUBPATH )
			{
				RI_ASSERT(segmentStarted);
				RI_ASSERT(!subpathStarted);
				RI_ASSERT((v.flags & START_SEGMENT) || (v.flags & END_SEGMENT));
				RI_ASSERT(!(v.flags & CLOSE_SUBPATH));
				RI_ASSERT(!(v.flags & START_SUBPATH));
				RI_ASSERT(!(v.flags & END_SUBPATH));
			}
			
			if( prev >= 0 )
			{
				RI_ASSERT(segmentStarted);
				RI_ASSERT(subpathStarted || ((self->_vertices[prev].flags & CLOSE_SUBPATH) && (self->_vertices[i].flags & CLOSE_SUBPATH)) ||
						  ((self->_vertices[prev].flags & IMPLICIT_CLOSE_SUBPATH) && (self->_vertices[i].flags & IMPLICIT_CLOSE_SUBPATH)));
			}

			prev = i;
			if(v.flags & END_SEGMENT)
			{
				RI_ASSERT(subpathStarted || (v.flags & CLOSE_SUBPATH) || (v.flags & IMPLICIT_CLOSE_SUBPATH));
				RI_ASSERT(segmentStarted);
				RI_ASSERT(!(v.flags & START_SUBPATH));
				RI_ASSERT(!(v.flags & START_SEGMENT));
				segmentStarted = NO;
				prev = -1;
			}
			
			if(v.flags & END_SUBPATH)
			{
				RI_ASSERT(subpathStarted);
				RI_ASSERT(v.flags & END_SEGMENT);
				RI_ASSERT(!(v.flags & START_SUBPATH));
				RI_ASSERT(!(v.flags & START_SEGMENT));
				RI_ASSERT(!(v.flags & CLOSE_SUBPATH));
				RI_ASSERT(!(v.flags & IMPLICIT_CLOSE_SUBPATH));
				subpathStarted = NO;
			}
		}
#endif	//RI_DEBUG
	}
#if 0
	catch(std::bad_alloc)
	{
		self->_vertexCount=0;
		throw;
	}
#endif
}

@end
