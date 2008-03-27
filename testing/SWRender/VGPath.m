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
 * \brief	Implementation of VGPath functions.
 * \note	
 *//*-------------------------------------------------------------------*/

#warning verify inital state of Vertex, Strokevertex
#warning verify pointers arent assigned false or 0

#import "VGPath.h"
#import "riMath.h"

	enum VertexFlags
	{
		START_SUBPATH			= (1<<0),
		END_SUBPATH				= (1<<1),
		START_SEGMENT			= (1<<2),
		END_SEGMENT				= (1<<3),
		CLOSE_SUBPATH			= (1<<4),
		IMPLICIT_CLOSE_SUBPATH	= (1<<5)
	};


/* maximum mantissa is 23 */
#define RI_MANTISSA_BITS 23

/* maximum exponent is 8 */
#define RI_EXPONENT_BITS 8

typedef union
{
	float	f;
	unsigned	i;
} RIfloatInt;

inline float	getFloatMax()
{
	RIfloatInt v;
	v.i = (((1<<(RI_EXPONENT_BITS-1))-1+127) << 23) | (((1<<RI_MANTISSA_BITS)-1) << (23-RI_MANTISSA_BITS));
	return v.f;
}
#define RI_FLOAT_MAX  getFloatMax()

static inline RIfloat inputFloat(RIfloat f) {
	//this function is used for all floating point input values
	if(RI_ISNAN(f)) return 0.0f;	//convert NaN to zero
	return RI_CLAMP(f, -RI_FLOAT_MAX, RI_FLOAT_MAX);	//clamp +-inf to +-RIfloat max
}

/*-------------------------------------------------------------------*//*!
* \brief	Form a reliable normalized average of the two unit input vectors.
*           The average always lies to the given direction from the first
*			vector.
* \param	u0, u1 Unit input vectors.
* \param	cw True if the average should be clockwise from u0, false if
*              counterclockwise.
* \return	Average of the two input vectors.
* \note		
*//*-------------------------------------------------------------------*/

static Vector2 unitAverageWithDirection(Vector2 u0, Vector2 u1, bool cw)
{
	Vector2 u =Vector2MultiplyByFloat(Vector2Add(u0 , u1), 0.5f);
	Vector2 n0 = Vector2PerpendicularCCW(u0);

	if( Vector2Dot(u, u) > 0.25f )
	{	//the average is long enough and thus reliable
		if( Vector2Dot(n0, u1) < 0.0f )
			u = Vector2Negate(u);	//choose the larger angle
	}
	else
	{	// the average is too short, use the average of the normals to the vectors instead
		Vector2 n1 = Vector2PerpendicularCW(u1);
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

static Vector2 unitAverage(Vector2 u0, Vector2 u1)
{
	Vector2 u =Vector2MultiplyByFloat(Vector2Add(u0 , u1), 0.5f);

	if( Vector2Dot(u, u) < 0.25f )
	{	// the average is unreliable, use the average of the normals to the vectors instead
		Vector2 n0 = Vector2PerpendicularCCW(u0);
		Vector2 n1 = Vector2PerpendicularCW(u1);
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

static Vector2 circularLerpWithDirection(Vector2 t0, Vector2 t1, RIfloat ratio, bool cw)
{
	Vector2 u0 = t0, u1 = t1;
	RIfloat l0 = 0.0f, l1 = 1.0f;
    int i;
	for(i=0;i<8;i++)
	{
		Vector2 n = unitAverageWithDirection(u0, u1, cw);
		RIfloat l = 0.5f * (l0 + l1);
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

static Vector2 circularLerp(Vector2 t0, Vector2 t1, RIfloat ratio)
{
	Vector2 u0 = t0, u1 = t1;
	RIfloat l0 = 0.0f, l1 = 1.0f;
    int i;
	for(i=0;i<8;i++)
	{
		Vector2 n = unitAverage(u0, u1);
		RIfloat l = 0.5f * (l0 + l1);
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
* \brief	VGPath constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGPath *VGPathAlloc(){
   return (VGPath *)NSZoneCalloc(NULL,1,sizeof(VGPath));
}

VGPath *VGPathInit(VGPath *self,int segmentCapacityHint, int coordCapacityHint){
	self->m_userMinx=0.0f;
	self->m_userMiny=0.0f;
	self->m_userMaxx=0.0f;
	self->m_userMaxy=0.0f;
    self->_segmentCount=0;
    self->_segmentCapacity=(segmentCapacityHint>0)?RI_INT_MIN(segmentCapacityHint,65536):2;
    self->_segments=(RIuint8 *)NSZoneMalloc(NULL,self->_segmentCapacity*sizeof(RIuint8));
    self->_coordinateCount=0;
    self->_coordinateCapacity=(coordCapacityHint>0)?RI_INT_MIN(coordCapacityHint, 65536):2;
    self->_coordinates=(RIfloat *)NSZoneMalloc(NULL,self->_coordinateCapacity*sizeof(RIfloat));
    self->_vertexCount=0;
    self->_vertexCapacity=2;
    self->_vertices=(Vertex *)NSZoneMalloc(NULL,self->_vertexCapacity*sizeof(Vertex));
    self->_segmentToVertexCount=0;
    self->_segmentToVertexCapacity=2;
    self->_segmentToVertex=(VertexIndex *)NSZoneMalloc(NULL,self->_segmentToVertexCapacity*sizeof(VertexIndex));
    return self;
}

/*-------------------------------------------------------------------*//*!
* \brief	VGPath destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathDealloc(VGPath *self){
   NSZoneFree(NULL,self->_segments);
   NSZoneFree(NULL,self->_coordinates);
   NSZoneFree(NULL,self->_vertices);
   NSZoneFree(NULL,self->_segmentToVertex);
   NSZoneFree(NULL,self);
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a coordinate and applies scale and bias.
* \param	
* \return	
*//*-------------------------------------------------------------------*/

RIfloat VGPathGetCoordinate(VGPath *self,int i)
{
	RI_ASSERT(i >= 0 && i < self->_coordinateCount);

    return self->_coordinates[i];
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes a coordinate, subtracting bias and dividing out scale.
* \param	
* \return	
* \note		If the coordinates do not fit into path datatype range, they
*			will overflow silently.
*//*-------------------------------------------------------------------*/

void VGPathSetCoordinate(VGPath *self,int i, RIfloat c){
	RI_ASSERT(i >= 0);
    
    self->_coordinates[i]=c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Given a path segment type, returns the number of coordinates
*			it uses.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int VGPathSegmentToNumCoordinates(VGPathSegment segment){
	RI_ASSERT(((int)segment) >= 0 && ((int)segment) <= 6);
	static const int coords[13] = {0,2,2,4,6,2,4};
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
		coordinates += VGPathSegmentToNumCoordinates((VGPathSegment)segments[i]);
	return coordinates;
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends user segments and data.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void VGPathAppendData(VGPath *self,const RIuint8* segments, int numSegments, const RIfloat* data){
	RI_ASSERT(numSegments > 0);
	RI_ASSERT(segments && data);

	//allocate new arrays
    RIuint8 *newSegments=NULL;
    int      newSegmentCapacity=self->_segmentCount+numSegments;
    
    if(newSegmentCapacity>self->_segmentCapacity)
     newSegments=(RIuint8 *)NSZoneMalloc(NULL,newSegmentCapacity*sizeof(RIuint8));
    
    RIfloat *newCoordinates=NULL;
    int      newCoordinateCount=VGPathCountNumCoordinates(segments,numSegments);
    int      newCoordinateCapacity=self->_coordinateCount+newCoordinateCount;
    
    if(newCoordinateCapacity>self->_coordinateCapacity)
     newCoordinates=(RIfloat *)NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(RIfloat));
    
	//if we get here, the memory allocations have succeeded

	//copy old segments and append new ones
    int i;
    
    if(newSegments!=NULL){
     RIuint8 *tmp;

     for(i=0;i<self->_segmentCount;i++)
      newSegments[i]=self->_segments[i];
      
     tmp=self->_segments;
     self->_segments=newSegments;
     self->_segmentCapacity=newSegmentCapacity;
     newSegments=tmp;
    }
    for(i=0;i<numSegments;i++)
     self->_segments[self->_segmentCount++]=segments[i];
    
    if(newCoordinates!=NULL){
     RIfloat *tmp;

     for(i=0;i<self->_coordinateCount;i++)
      newCoordinates[i]=self->_coordinates[i];
      
     tmp=self->_coordinates;
     self->_coordinates=newCoordinates;
     self->_coordinateCapacity=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    for(i=0;i<newCoordinateCount;i++)
     self->_coordinates[self->_coordinateCount++]=inputFloat(data[i]);
     
	RI_ASSERT(self->_coordinateCount == VGPathCountNumCoordinates(self->_segments,self->_segmentCount));

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

	if(srcPath->_segmentCount)
	{
		//allocate new arrays
        RIuint8 *newSegments=NULL;
        int      newSegmentCapacity=self->_segmentCount+srcPath->_segmentCount;
    
        if(newSegmentCapacity>self->_segmentCapacity)
            newSegments=(RIuint8 *)NSZoneMalloc(NULL,newSegmentCapacity*sizeof(RIuint8));
    
        RIfloat *newCoordinates=NULL;
        int      newCoordinateCapacity=self->_coordinateCount+VGPathGetNumCoordinates(srcPath);
    
        if(newCoordinateCapacity>self->_coordinateCapacity)
            newCoordinates=(RIfloat *)NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(RIfloat));

		//if we get here, the memory allocations have succeeded

		//copy old segments and append new ones
    int i;
    
    if(newSegments!=NULL){
     RIuint8 *tmp;

     for(i=0;i<self->_segmentCount;i++)
      newSegments[i]=self->_segments[i];
      
     tmp=self->_segments;
     self->_segments=newSegments;
     self->_segmentCapacity=newSegmentCapacity;
     newSegments=tmp;
    }
    for(i=0;i<srcPath->_segmentCount;i++)
     self->_segments[self->_segmentCount++]=srcPath->_segments[i];
    
    if(newCoordinates!=NULL){
     RIfloat *tmp;

     for(i=0;i<self->_coordinateCount;i++)
      newCoordinates[i]=self->_coordinates[i];
      
     tmp=self->_coordinates;
     self->_coordinates=newCoordinates;
     self->_coordinateCapacity=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    for(i=0;i<VGPathGetNumCoordinates(srcPath);i++){
        VGPathSetCoordinate(self,self->_coordinateCount++, VGPathGetCoordinate(srcPath,i));
     }
		RI_ASSERT(self->_coordinateCount == VGPathCountNumCoordinates(self->_segments,self->_segmentCount) );

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

void VGPathTransform(VGPath *self,VGPath* srcPath, Matrix3x3 matrix){
	RI_ASSERT(srcPath);
	RI_ASSERT(Matrix3x3IsAffine(matrix));

	if(!srcPath->_segmentCount)
		return;

	//count the number of resulting coordinates
	int numSrcCoords = 0;
	int numDstCoords = 0;
    int i;
	for(i=0;i<srcPath->_segmentCount;i++)
	{
		VGPathSegment segment = (VGPathSegment)srcPath->_segments[i];
		int coords = VGPathSegmentToNumCoordinates(segment);
		numSrcCoords += coords;
		numDstCoords += coords;
	}

	//allocate new arrays
        RIuint8 *newSegments=NULL;
        int      newSegmentCapacity=self->_segmentCount+srcPath->_segmentCount;
    
        if(newSegmentCapacity>self->_segmentCapacity)
            newSegments=(RIuint8 *)NSZoneMalloc(NULL,newSegmentCapacity*sizeof(RIuint8));
    
        RIfloat *newCoordinates=NULL;
        int      newCoordinateCapacity=self->_coordinateCount+numDstCoords;
    
        if(newCoordinateCapacity>self->_coordinateCapacity)
            newCoordinates=(RIfloat *)NSZoneMalloc(NULL,newCoordinateCapacity*sizeof(RIfloat));

	//if we get here, the memory allocations have succeeded

	//copy old segments
    if(newSegments!=NULL){
     RIuint8 *tmp;
          
     for(i=0;i<self->_segmentCount;i++)
      newSegments[i]=self->_segments[i];
      
     tmp=self->_segments;
     self->_segments=newSegments;
     self->_segmentCapacity=newSegmentCapacity;
     newSegments=tmp;
    }

	//copy old data
    if(newCoordinates!=NULL){
     RIfloat *tmp;
     
     for(i=0;i<self->_coordinateCount;i++)
      newCoordinates[i]=self->_coordinates[i];
      
     tmp=self->_coordinates;
     self->_coordinates=newCoordinates;
     self->_coordinateCapacity=newCoordinateCapacity;
     newCoordinates=tmp;
    }
    
	int srcCoord = 0;
	Vector2 s=Vector2Make(0,0);		//the beginning of the current subpath
	Vector2 o=Vector2Make(0,0);		//the last point of the previous segment
	for(i=0;i<srcPath->_segmentCount;i++)
	{
		VGPathSegment segment = (VGPathSegment)srcPath->_segments[i];
		int coords = VGPathSegmentToNumCoordinates(segment);

		switch(segment)
		{
		case VG_CLOSE_PATH:
		{
			RI_ASSERT(coords == 0);
			o = s;
			break;
		}

		case VG_MOVE_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 tc = Matrix3x3TransformVector2(matrix, c);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc.y);
			s = c;
			o = c;
			break;
		}

		case VG_LINE_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 tc = Matrix3x3TransformVector2(matrix, c);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc.y);
			o = c;
			break;
		}

		case VG_QUAD_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c0=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 c1=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+2), VGPathGetCoordinate(srcPath,srcCoord+3));
			Vector2 tc0 = Matrix3x3TransformVector2(matrix, c0);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc0.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc0.y);
			Vector2 tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.y);
			o = c1;
			break;
		}

		case VG_CUBIC_TO:
		{
			RI_ASSERT(coords == 6);
			Vector2 c0=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 c1=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+2), VGPathGetCoordinate(srcPath,srcCoord+3));
			Vector2 c2=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+4), VGPathGetCoordinate(srcPath,srcCoord+5));
			Vector2 tc0 = Matrix3x3TransformVector2(matrix, c0);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc0.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc0.y);
			Vector2 tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.y);
			Vector2 tc2 = Matrix3x3TransformVector2(matrix, c2);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc2.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc2.y);
			o = c2;
			break;
		}

		case VG_SQUAD_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c1=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.y);
			o = c1;
			break;
		}

		case VG_SCUBIC_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c1=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+0), VGPathGetCoordinate(srcPath,srcCoord+1));
			Vector2 c2=Vector2Make(VGPathGetCoordinate(srcPath,srcCoord+2), VGPathGetCoordinate(srcPath,srcCoord+3));
			Vector2 tc1 = Matrix3x3TransformVector2(matrix, c1);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc1.y);
			Vector2 tc2 = Matrix3x3TransformVector2(matrix, c2);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc2.x);
			VGPathSetCoordinate(self, self->_coordinateCount++, tc2.y);
			o = c2;
			break;
		}

		}

		self->_segments[self->_segmentCount++] = (RIuint8)segment;
		srcCoord += coords;
	}
	RI_ASSERT(srcCoord == numSrcCoords);

	RI_ASSERT(self->_coordinateCount == VGPathCountNumCoordinates(self->_segments,self->_segmentCount));

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

void VGPathFill(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer){
	RI_ASSERT(Matrix3x3IsAffine(pathToSurface));

	VGPathTessellate(self);	//throws bad_alloc

//	try
	{
		Vector2 p0=Vector2Make(0,0), p1=Vector2Make(0,0);
        int     i;
		for(i=0;i<self->_vertexCount;i++)
		{
			p1 = Matrix3x3TransformVector2(pathToSurface, self->_vertices[i].userPosition);

			if(!(self->_vertices[i].flags & START_SEGMENT))
			{	//in the middle of a segment
				KGRasterizerAddEdge(rasterizer,p0, p1);	//throws bad_alloc
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

void VGPathInterpolateStroke(Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v0,StrokeVertex v1, RIfloat strokeWidth)
{
	Vector2 ppccw = Matrix3x3TransformVector2(pathToSurface, v0.ccw);
	Vector2 ppcw = Matrix3x3TransformVector2(pathToSurface, v0.cw);
	Vector2 endccw = Matrix3x3TransformVector2(pathToSurface, v1.ccw);
	Vector2 endcw = Matrix3x3TransformVector2(pathToSurface, v1.cw);

	const RIfloat tessellationAngle = 5.0f;

	RIfloat angle = RI_RAD_TO_DEG((RIfloat)acos(RI_CLAMP(Vector2Dot(v0.t, v1.t), -1.0f, 1.0f))) / tessellationAngle;
	int samples = RI_INT_MAX((int)ceil(angle), 1);
	Vector2 prev = v0.p;
	Vector2 prevt = v0.t;
	Vector2 position = v0.p;
	Vector2 pnccw = ppccw;
	Vector2 pncw = ppcw;
    int     j;
	for(j=0;j<samples;j++)
	{
		RIfloat t = (RIfloat)(j+1) / (RIfloat)samples;
		position = Vector2Add(Vector2MultiplyByFloat(v0.p , (1.0f - t)) , Vector2MultiplyByFloat(v1.p ,t));
		Vector2 tangent = circularLerp(v0.t, v1.t, t);
		Vector2 n = Vector2MultiplyByFloat(Vector2Normalize(Vector2PerpendicularCCW(tangent)) , strokeWidth * 0.5f);

		if(j == samples-1)
			position = v1.p;

		Vector2 npccw = Matrix3x3TransformVector2(pathToSurface, Vector2Add(prev, n));
		Vector2 npcw = Matrix3x3TransformVector2(pathToSurface, Vector2Subtract(prev, n));
		Vector2 nnccw = Matrix3x3TransformVector2(pathToSurface,Vector2Add(position,n));
		Vector2 nncw = Matrix3x3TransformVector2(pathToSurface, Vector2Subtract(position , n));

		KGRasterizerAddEdge(rasterizer,npccw, nnccw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,nnccw, nncw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,nncw, npcw);		//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,npcw, npccw);	//throws bad_alloc

		if(Vector2Dot(n,prevt) <= 0.0f)
		{
			KGRasterizerAddEdge(rasterizer,pnccw, npcw);	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,npcw, pncw);		//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,pncw, npccw);	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,npccw, pnccw);	//throws bad_alloc
		}
		else
		{
			KGRasterizerAddEdge(rasterizer,pnccw, npccw);	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,npccw, pncw);	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,pncw, npcw);		//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,npcw, pnccw);	//throws bad_alloc
		}

		ppccw = npccw;
		ppcw = npcw;
		pnccw = nnccw;
		pncw = nncw;
		prev = position;
		prevt = tangent;
	}

	//connect the last segment to the end coordinates
	Vector2 n = Vector2PerpendicularCCW(v1.t);
	if(Vector2Dot(n,prevt) <= 0.0f)
	{
		KGRasterizerAddEdge(rasterizer,pnccw, endcw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,endcw, pncw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,pncw, endccw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,endccw, pnccw);	//throws bad_alloc
	}
	else
	{
		KGRasterizerAddEdge(rasterizer,pnccw, endccw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,endccw, pncw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,pncw, endcw);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,endcw, pnccw);	//throws bad_alloc
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generate edges for stroke caps. Resulting polygons are closed.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathDoCap(Matrix3x3 pathToSurface, KGRasterizer *rasterizer,StrokeVertex v, RIfloat strokeWidth, CGLineCap capStyle){
	Vector2 ccwt = Matrix3x3TransformVector2(pathToSurface, v.ccw);
	Vector2 cwt = Matrix3x3TransformVector2(pathToSurface, v.cw);

	switch(capStyle)
	{
	case kCGLineCapButt:
		break;

	case kCGLineCapRound:
	{
		const RIfloat tessellationAngle = 5.0f;

		RIfloat angle = 180.0f / tessellationAngle;

		int samples = (int)ceil(angle);
		RIfloat step = 1.0f / samples;
		RIfloat t = step;
		Vector2 u0 = Vector2Normalize(Vector2Subtract(v.ccw,v.p));
		Vector2 u1 = Vector2Normalize(Vector2Subtract(v.cw,v.p));
		Vector2 prev = ccwt;
		KGRasterizerAddEdge(rasterizer,cwt, ccwt);	//throws bad_alloc
        int j;
		for(j=1;j<samples;j++)
		{
			Vector2 next = Vector2Add(v.p , Vector2MultiplyByFloat(circularLerpWithDirection(u0, u1, t, true) , strokeWidth * 0.5f));
			next = Matrix3x3TransformVector2(pathToSurface, next);

			KGRasterizerAddEdge(rasterizer,prev, next);	//throws bad_alloc
			prev = next;
			t += step;
		}
		KGRasterizerAddEdge(rasterizer,prev, cwt);	//throws bad_alloc
		break;
	}

	default:
	{
		RI_ASSERT(capStyle == kCGLineCapSquare);
		Vector2 t = v.t;
		t=Vector2Normalize(t);
		Vector2 ccws = Matrix3x3TransformVector2(pathToSurface, Vector2Add(v.ccw , Vector2MultiplyByFloat(t , strokeWidth * 0.5f)));
		Vector2 cws = Matrix3x3TransformVector2(pathToSurface, Vector2Add(v.cw , Vector2MultiplyByFloat(t , strokeWidth * 0.5f)));
		KGRasterizerAddEdge(rasterizer,cwt, ccwt);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,ccwt, ccws);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,ccws, cws);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,cws, cwt);	//throws bad_alloc
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

void VGPathDoJoin(Matrix3x3 pathToSurface, KGRasterizer *rasterizer, StrokeVertex v0, StrokeVertex v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit){
	Vector2 ccw0t = Matrix3x3TransformVector2(pathToSurface, v0.ccw);
	Vector2 cw0t = Matrix3x3TransformVector2(pathToSurface, v0.cw);
	Vector2 ccw1t = Matrix3x3TransformVector2(pathToSurface, v1.ccw);
	Vector2 cw1t = Matrix3x3TransformVector2(pathToSurface, v1.cw);
	Vector2 m0t = Matrix3x3TransformVector2(pathToSurface, v0.p);
	Vector2 m1t = Matrix3x3TransformVector2(pathToSurface, v1.p);

	Vector2 tccw = Vector2Subtract(v1.ccw,v0.ccw);
	Vector2 s, e, m, st, et;
	bool cw;

	if( Vector2Dot(tccw, v0.t) > 0.0f )
	{	//draw ccw miter (draw from point 0 to 1)
		s = ccw0t;
		e = ccw1t;
		st = v0.t;
		et = v1.t;
		m = v0.ccw;
		cw = false;
		KGRasterizerAddEdge(rasterizer,m0t, ccw0t);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,ccw1t, m1t);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,m1t, m0t);	//throws bad_alloc
	}
	else
	{	//draw cw miter (draw from point 1 to 0)
		s = cw1t;
		e = cw0t;
		st = v1.t;
		et = v0.t;
		m = v0.cw;
		cw = true;
		KGRasterizerAddEdge(rasterizer,cw0t, m0t);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,m1t, cw1t);	//throws bad_alloc
		KGRasterizerAddEdge(rasterizer,m0t, m1t);	//throws bad_alloc
	}

	switch(joinStyle)
	{
	case kCGLineJoinMiter:
	{
		RIfloat theta = (RIfloat)acos(RI_CLAMP(Vector2Dot(v0.t, Vector2Negate(v1.t)), -1.0f, 1.0f));
		RIfloat miterLengthPerStrokeWidth = 1.0f / (RIfloat)sin(theta*0.5f);
		if( miterLengthPerStrokeWidth < miterLimit )
		{	//miter
			RIfloat l = (RIfloat)cos(theta*0.5f) * miterLengthPerStrokeWidth * (strokeWidth * 0.5f);
			l = RI_MIN(l, RI_FLOAT_MAX);	//force finite
			Vector2 c = Vector2Add(m , Vector2MultiplyByFloat(v0.t, l));
			c = Matrix3x3TransformVector2(pathToSurface, c);
			KGRasterizerAddEdge(rasterizer,s, c);	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,c, e);	//throws bad_alloc
		}
		else
		{	//bevel
			KGRasterizerAddEdge(rasterizer,s, e);	//throws bad_alloc
		}
		break;
	}

	case kCGLineJoinRound:
	{
		const RIfloat tessellationAngle = 5.0f;

		Vector2 prev = s;
		RIfloat angle = RI_RAD_TO_DEG((RIfloat)acos(RI_CLAMP(Vector2Dot(st, et), -1.0f, 1.0f))) / tessellationAngle;
		int samples = (int)ceil(angle);
		if( samples )
		{
			RIfloat step = 1.0f / samples;
			RIfloat t = step;
            int     j;
			for(j=1;j<samples;j++)
			{
				Vector2 position = Vector2Add(Vector2MultiplyByFloat(v0.p , (1.0f - t)) , Vector2MultiplyByFloat(v1.p , t));
				Vector2 tangent = circularLerpWithDirection(st, et, t, true);

				Vector2 next = Vector2Add(position , Vector2MultiplyByFloat(Vector2Normalize(Vector2Perpendicular(tangent, cw)) , strokeWidth * 0.5f));
				next = Matrix3x3TransformVector2(pathToSurface, next);

				KGRasterizerAddEdge(rasterizer,prev, next);	//throws bad_alloc
				prev = next;
				t += step;
			}
		}
		KGRasterizerAddEdge(rasterizer,prev, e);	//throws bad_alloc
		break;
	}

	default:
		RI_ASSERT(joinStyle == kCGLineJoinBevel);
		if(!cw)
			KGRasterizerAddEdge(rasterizer,ccw0t, ccw1t);	//throws bad_alloc
		else
			KGRasterizerAddEdge(rasterizer,cw1t, cw0t);		//throws bad_alloc
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

void VGPathStroke(VGPath *self,Matrix3x3 pathToSurface, KGRasterizer *rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, bool dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit){
	RI_ASSERT(Matrix3x3IsAffine(pathToSurface));
	RI_ASSERT(strokeWidth >= 0.0f);
	RI_ASSERT(miterLimit >= 1.0f);

	VGPathTessellate(self);	//throws bad_alloc

	if(!self->_vertexCount)
		return;

	bool dashing = true;

	if( dashPatternSize & 1 )
		dashPatternSize--;	//odd number of dash pattern entries, discard the last one
	RIfloat dashPatternLength = 0.0f;
    int     i;
	for(i=0;i<dashPatternSize;i++)
		dashPatternLength += RI_MAX(dashPattern[i], 0.0f);
	if(!dashPatternSize || dashPatternLength == 0.0f )
		dashing = false;
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
		RIfloat nextDash = 0.0f;
		int d = 0;
		bool inDash = true;
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
			v1.inDash = dashing ? inDash : true;	//NOTE: for other than START_SEGMENT vertices inDash will be updated after dashing

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
							inDash = true;
							nextDash = v1.pathLength - RI_MOD(dashPhase, dashPatternLength);
							for(;;)
							{
								RIfloat prevDash = nextDash;
								nextDash = prevDash + RI_MAX(dashPattern[d], 0.0f);
								if(nextDash >= v1.pathLength)
									break;

								if( d & 1 )
									inDash = true;
								else
									inDash = false;
								d = (d+1) % dashPatternSize;
							}
							v1.inDash = inDash;
							//the first point of the path lies between prevDash and nextDash
							//d in the index of the next dash stop
							//inDash is true if the first point is in a dash
						}
					}
					vs = v1;	//save the subpath start point
				}
				else
				{
					if( v.flags & IMPLICIT_CLOSE_SUBPATH )
					{	//do caps for the start and end of the current subpath
						if( v0.inDash )
							VGPathDoCap(pathToSurface, rasterizer, v0, strokeWidth, capStyle);	//end cap	//throws bad_alloc
						if( vs.inDash )
						{
							StrokeVertex vi = vs;
							vi.t = Vector2Negate(vi.t);
							RI_SWAP(&vi.ccw.x, &vi.cw.x);
							RI_SWAP(&vi.ccw.y, &vi.cw.y);
							VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap	//throws bad_alloc
						}
					}
					else
					{	//join two segments
						RI_ASSERT(v0.inDash == v1.inDash);
						if( v0.inDash )
							VGPathDoJoin(pathToSurface, rasterizer, v0, v1, strokeWidth, joinStyle, miterLimit);	//throws bad_alloc
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
							RIfloat edgeLength = v1.pathLength - v0.pathLength;
							RIfloat ratio = 0.0f;
							if(edgeLength > 0.0f)
								ratio = (nextDash - v0.pathLength) / edgeLength;
							StrokeVertex nextDashVertex;
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
									VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//throws bad_alloc
								}
								VGPathInterpolateStroke(pathToSurface, rasterizer, prevDashVertex, nextDashVertex, strokeWidth);	//throws bad_alloc
								VGPathDoCap(pathToSurface, rasterizer, nextDashVertex, strokeWidth, capStyle);	//end cap	//throws bad_alloc
							}
							prevDashVertex = nextDashVertex;

							if( d & 1 )
							{	//dash starts
								RI_ASSERT(!inDash);
								inDash = true;
							}
							else
							{	//dash ends
								RI_ASSERT(inDash);
								inDash = false;
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
								VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//throws bad_alloc
							}
							VGPathInterpolateStroke(pathToSurface, rasterizer, prevDashVertex, v1, strokeWidth);	//throws bad_alloc
							//no cap, leave path open
						}

						v1.inDash = inDash;	//update inDash status of the segment end point
					}
					else	//no dashing, just interpolate segment end points
						VGPathInterpolateStroke(pathToSurface, rasterizer, v0, v1, strokeWidth);	//throws bad_alloc
				}
			}

			if((v.flags & END_SEGMENT) && (v.flags & CLOSE_SUBPATH))
			{	//join start and end of the current subpath
				if( v1.inDash && vs.inDash )
					VGPathDoJoin(pathToSurface, rasterizer, v1, vs, strokeWidth, joinStyle, miterLimit);	//throws bad_alloc
				else
				{	//both start and end are not in dash, cap them
					if( v1.inDash )
						VGPathDoCap(pathToSurface, rasterizer, v1, strokeWidth, capStyle);	//end cap	//throws bad_alloc
					if( vs.inDash )
					{
						StrokeVertex vi = vs;
						vi.t = Vector2Negate(vi.t);
						RI_SWAP(&vi.ccw.x, &vi.cw.x);
						RI_SWAP(&vi.ccw.y, &vi.cw.y);
						VGPathDoCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap	//throws bad_alloc
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

void VGPathGetPointAlong(VGPath *self,int startIndex, int numSegments, RIfloat distance, Vector2 *p, Vector2 *t){
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= self->_segmentCount && numSegments > 0);

	VGPathTessellate(self);	//throws bad_alloc

	RI_ASSERT(startIndex >= 0 && startIndex < self->_segmentToVertexCount);
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= self->_segmentToVertexCount);

	int startVertex = self->_segmentToVertex[startIndex].start;
	int endVertex = self->_segmentToVertex[startIndex + numSegments - 1].end;

	if(!self->_vertexCount || (startVertex == -1 && endVertex == -1))
	{	// no vertices in the tessellated path. The path is empty or consists only of zero-length segments.
		*p=Vector2Make(0,0);
		*t=Vector2Make(1,0);
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
					RIfloat edgeLength = v1.pathLength - v0.pathLength;
					RI_ASSERT(edgeLength > 0.0f);
					RIfloat r = (distance - v0.pathLength) / edgeLength;
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

RIfloat getPathLength(VGPath *self,int startIndex, int numSegments){
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= self->_segmentCount && numSegments > 0);

	VGPathTessellate(self);	//throws bad_alloc

	RI_ASSERT(startIndex >= 0 && startIndex < self->_segmentToVertexCount);
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= self->_segmentToVertexCount);

	int startVertex = self->_segmentToVertex[startIndex].start;
	int endVertex = self->_segmentToVertex[startIndex + numSegments - 1].end;

	if(!self->_vertexCount)
		return 0.0f;

	RIfloat startPathLength = 0.0f;
	if(startVertex >= 0)
	{
		RI_ASSERT(startVertex >= 0 && startVertex < self->_vertexCount);
		startPathLength = self->_vertices[startVertex].pathLength;
	}
	RIfloat endPathLength = 0.0f;
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

void VGPathGetPathBounds(VGPath *self,RIfloat *minx, RIfloat *miny, RIfloat *maxx, RIfloat *maxy){
	VGPathTessellate(self);	//throws bad_alloc

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

void VGPathGetPathTransformedBounds(VGPath *self,Matrix3x3 pathToSurface, RIfloat *minx, RIfloat *miny, RIfloat *maxx, RIfloat *maxy){
	RI_ASSERT(Matrix3x3IsAffine(pathToSurface));

	VGPathTessellate(self);	//throws bad_alloc

	if(self->_vertexCount)
	{
		Vector3 p0=Vector3Make(self->m_userMinx, self->m_userMiny,1);
		Vector3 p1=Vector3Make(self->m_userMinx, self->m_userMaxy,1);
		Vector3 p2=Vector3Make(self->m_userMaxx, self->m_userMaxy,1);
		Vector3 p3=Vector3Make(self->m_userMaxx, self->m_userMiny,1);
		p0 = Matrix3x3MultiplyVector3(pathToSurface,p0);
		p1 = Matrix3x3MultiplyVector3(pathToSurface, p1);
		p2 = Matrix3x3MultiplyVector3(pathToSurface, p2);
		p3 = Matrix3x3MultiplyVector3(pathToSurface,p3);

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

void VGPathAddVertex(VGPath *self,Vector2 p, Vector2 t, RIfloat pathLength, unsigned int flags){
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

void VGPathAddEdge(VGPath *self,Vector2 p0, Vector2 p1, Vector2 t0, Vector2 t1, unsigned int startFlags, unsigned int endFlags){
	RIfloat pathLength = 0.0f;

	RI_ASSERT(!Vector2IsZero(t0) && !Vector2IsZero(t1));

	//segment midpoints are shared between edges
	if( startFlags & START_SEGMENT )
	{
		if(self->_vertexCount > 0)
			pathLength = self->_vertices[self->_vertexCount-1].pathLength;

		VGPathAddVertex(self,p0, t0, pathLength, startFlags);	//throws bad_alloc
	}

	//other than implicit close paths (caused by a MOVE_TO) add to path length
	if( !(endFlags & IMPLICIT_CLOSE_SUBPATH) )
	{
		//NOTE: with extremely large coordinates the floating point path length is infinite
		RIfloat l = Vector2Length(Vector2Subtract(p1,p0));
		pathLength = self->_vertices[self->_vertexCount-1].pathLength + l;
		pathLength = RI_MIN(pathLength, RI_FLOAT_MAX);
	}

	VGPathAddVertex(self,p1, t1, pathLength, endFlags);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a close-path segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void VGPathAddEndPath(VGPath *self,Vector2 p0, Vector2 p1, bool subpathHasGeometry, unsigned int flags){
	if(!subpathHasGeometry)
	{	//single vertex
		Vector2 t=Vector2Make(1.0f,0.0f);
		VGPathAddEdge(self,p0, p1, t, t, START_SEGMENT | START_SUBPATH, END_SEGMENT | END_SUBPATH);	//throws bad_alloc
		VGPathAddEdge(self,p0, p1, Vector2Negate(t), Vector2Negate(t), IMPLICIT_CLOSE_SUBPATH | START_SEGMENT, IMPLICIT_CLOSE_SUBPATH | END_SEGMENT);	//throws bad_alloc
		return;
	}
	//the subpath contains segment commands that have generated geometry

	//add a close path segment to the start point of the subpath
	RI_ASSERT(self->_vertexCount > 0);
	self->_vertices[self->_vertexCount-1].flags |= END_SUBPATH;

	Vector2 t = Vector2Normalize(Vector2Subtract(p1,p0));
	if(Vector2IsZero(t))
		t = self->_vertices[self->_vertexCount-1].userTangent;	//if the segment is zero-length, use the tangent of the last segment end point so that proper join will be generated
	RI_ASSERT(!Vector2IsZero(t));

	VGPathAddEdge(self,p0, p1, t, t, flags | START_SEGMENT, flags | END_SEGMENT);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a line-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool VGPathAddLineTo(VGPath *self,Vector2 p0, Vector2 p1, bool subpathHasGeometry){
	if(Vector2IsEqual(p0 ,p1))
		return false;	//discard zero-length segments

	//compute end point tangents
	Vector2 t = Vector2Normalize(Vector2Subtract(p1,p0));
	RI_ASSERT(!Vector2IsZero(t));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;
	VGPathAddEdge(self,p0, p1, t, t, startFlags, END_SEGMENT);	//throws bad_alloc
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a quad-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool VGPathAddQuadTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, bool subpathHasGeometry){
	if(Vector2IsEqual(p0,p1) && Vector2IsEqual(p0,p2))
	{
		RI_ASSERT(Vector2IsEqual(p1,p2));
		return false;	//discard zero-length segments
	}

	//compute end point tangents

	Vector2 incomingTangent = Vector2Normalize(Vector2Subtract(p1,p0));
	Vector2 outgoingTangent = Vector2Normalize(Vector2Subtract(p2,p1));
	if(Vector2IsEqual(p0,p1))
		incomingTangent = Vector2Normalize(Vector2Subtract(p2,p0));
	if(Vector2IsEqual(p1,p2))
		outgoingTangent = Vector2Normalize(Vector2Subtract(p2 ,p0));
	RI_ASSERT(!Vector2IsZero(incomingTangent) && !Vector2IsZero(outgoingTangent));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

	const int segments = 256;
	Vector2 pp = p0;
	Vector2 tp = incomingTangent;
	unsigned int prevFlags = startFlags;
    int i;
	for(i=1;i<segments;i++)
	{
		RIfloat t = (RIfloat)i / (RIfloat)segments;
		RIfloat u = 1.0f-t;
		Vector2 pn = Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,u*u) , Vector2MultiplyByFloat(p1,2.0f*t*u)),Vector2MultiplyByFloat(p2,t*t));
		Vector2 tn = Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,(-1.0f+t)), Vector2MultiplyByFloat(p1,(1.0f-2.0f*t))),Vector2MultiplyByFloat(p2,t));
		tn = Vector2Normalize(tn);
		if(Vector2IsZero(tn))
			tn = tp;

		VGPathAddEdge(self,pp, pn, tp, tn, prevFlags, 0);	//throws bad_alloc

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	VGPathAddEdge(self,pp, p2, tp, outgoingTangent, prevFlags, END_SEGMENT);	//throws bad_alloc
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a cubic-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool VGPathAddCubicTo(VGPath *self,Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, bool subpathHasGeometry){
	if(Vector2IsEqual(p0,p1) && Vector2IsEqual(p0,p2) && Vector2IsEqual(p0 ,p3))
	{
		RI_ASSERT(Vector2IsEqual(p1 , p2) && Vector2IsEqual(p1 , p3) && Vector2IsEqual(p2 , p3));
		return false;	//discard zero-length segments
	}

	//compute end point tangents
	Vector2 incomingTangent = Vector2Normalize(Vector2Subtract(p1, p0));
	Vector2 outgoingTangent = Vector2Normalize(Vector2Subtract(p3, p2));
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

	const int segments = 256;
	Vector2 pp = p0;
	Vector2 tp = incomingTangent;
	unsigned int prevFlags = startFlags;
    int i;
	for(i=1;i<segments;i++)
	{
		RIfloat t = (RIfloat)i / (RIfloat)segments;
		RIfloat u = 1.0f-t;
		Vector2 pn = Vector2Add(Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,u*u*u), Vector2MultiplyByFloat(p1,3.0f*t*u*u)) ,Vector2MultiplyByFloat(p2,3.0f*t*t*u)),Vector2MultiplyByFloat(p3,t*t*t));
		Vector2 tn = Vector2Add(Vector2Add(Vector2Add(Vector2MultiplyByFloat(p0,(-1.0f + 2.0f*t - t*t)) , Vector2MultiplyByFloat(p1,(1.0f - 4.0f*t + 3.0f*t*t))) , Vector2MultiplyByFloat(p2,(2.0f*t - 3.0f*t*t) )) ,Vector2MultiplyByFloat(p3,t*t));
		tn = Vector2Normalize(tn);
		if(Vector2IsZero(tn))
			tn = tp;

		VGPathAddEdge(self,pp, pn, tp, tn, prevFlags, 0);	//throws bad_alloc

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	VGPathAddEdge(self,pp, p3, tp, outgoingTangent, prevFlags, END_SEGMENT);	//throws bad_alloc
	return true;
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
        if(self->_segmentToVertexCapacity<self->_segmentCount){
         self->_segmentToVertexCapacity=self->_segmentCount;
         self->_segmentToVertex=(VertexIndex *)NSZoneMalloc(NULL,self->_segmentToVertexCapacity*sizeof(VertexIndex));
        }
        
		int coordIndex = 0;
		Vector2 s=Vector2Make(0,0);		//the beginning of the current subpath
		Vector2 o=Vector2Make(0,0);		//the last point of the previous segment
		Vector2 p=Vector2Make(0,0);		//the last internal control point of the previous segment, if the segment was a (regular or smooth) quadratic or cubic Bezier, or else the last point of the previous segment

		//tessellate the path segments
		coordIndex = 0;
		s=Vector2Make(0,0);
		o=Vector2Make(0,0);
		p=Vector2Make(0,0);
		bool subpathHasGeometry = false;
		VGPathSegment prevSegment = VG_MOVE_TO;
        int i;
		for(i=0;i<self->_segmentCount;i++)
		{
			VGPathSegment segment = (VGPathSegment)self->_segments[i];
			int coords = VGPathSegmentToNumCoordinates(segment);
			self->_segmentToVertex[i].start = self->_vertexCount;

			switch(segment)
			{
			case VG_CLOSE_PATH:
			{
				RI_ASSERT(coords == 0);
				VGPathAddEndPath(self,o, s, subpathHasGeometry, CLOSE_SUBPATH);
				p = s;
				o = s;
				subpathHasGeometry = false;
				break;
			}

			case VG_MOVE_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				if(prevSegment != VG_MOVE_TO && prevSegment != VG_CLOSE_PATH)
					VGPathAddEndPath(self,o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);
				s = c;
				p = c;
				o = c;
				subpathHasGeometry = false;
				break;
			}

			case VG_LINE_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				if(VGPathAddLineTo(self,o, c, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c;
				o = c;
				break;
			}

			case VG_QUAD_TO:
			{
				RI_ASSERT(coords == 4);
				Vector2 c0=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				Vector2 c1=Vector2Make(VGPathGetCoordinate(self,coordIndex+2), VGPathGetCoordinate(self,coordIndex+3));
				if(VGPathAddQuadTo(self,o, c0, c1, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c0;
				o = c1;
				break;
			}

			case VG_SQUAD_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c0 = Vector2Subtract(Vector2MultiplyByFloat(o,2.0f) , p);
				Vector2 c1=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				if(VGPathAddQuadTo(self,o, c0, c1, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c0;
				o = c1;
				break;
			}

			case VG_CUBIC_TO:
			{
				RI_ASSERT(coords == 6);
				Vector2 c0=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				Vector2 c1=Vector2Make(VGPathGetCoordinate(self,coordIndex+2), VGPathGetCoordinate(self,coordIndex+3));
				Vector2 c2=Vector2Make(VGPathGetCoordinate(self,coordIndex+4), VGPathGetCoordinate(self,coordIndex+5));
				if(VGPathAddCubicTo(self,o, c0, c1, c2, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c1;
				o = c2;
				break;
			}

			case VG_SCUBIC_TO:
			{
				RI_ASSERT(coords == 4);
				Vector2 c0 = Vector2Subtract(Vector2MultiplyByFloat(o,2.0f) , p);
				Vector2 c1=Vector2Make(VGPathGetCoordinate(self,coordIndex+0), VGPathGetCoordinate(self,coordIndex+1));
				Vector2 c2=Vector2Make(VGPathGetCoordinate(self,coordIndex+2), VGPathGetCoordinate(self,coordIndex+3));
				if(VGPathAddCubicTo(self,o, c0, c1, c2, subpathHasGeometry))
					subpathHasGeometry = true;
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
		if(prevSegment != VG_MOVE_TO && prevSegment != VG_CLOSE_PATH)
			VGPathAddEndPath(self,o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);

#if 0 // DEBUG
		//check that the flags are correct
		int prev = -1;
		bool subpathStarted = false;
		bool segmentStarted = false;
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
				subpathStarted = true;
			}
			
			if(v.flags & START_SEGMENT)
			{
				RI_ASSERT(subpathStarted || (v.flags & CLOSE_SUBPATH) || (v.flags & IMPLICIT_CLOSE_SUBPATH));
				RI_ASSERT(!segmentStarted);
				RI_ASSERT(!(v.flags & END_SUBPATH));
				RI_ASSERT(!(v.flags & END_SEGMENT));
				segmentStarted = true;
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
				segmentStarted = false;
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
				subpathStarted = false;
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
