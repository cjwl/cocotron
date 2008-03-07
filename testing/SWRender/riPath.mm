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
 * \brief	Implementation of Path functions.
 * \note	
 *//*-------------------------------------------------------------------*/

#include "riPath.h"
#include "riMath.h"

//==============================================================================================


//==============================================================================================


namespace OpenVGRI
{

static VGfloat inputFloat(VGfloat f)
{
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

static const Vector2 unitAverage(const Vector2& u0, const Vector2& u1, bool cw)
{
	Vector2 u = 0.5f * (u0 + u1);
	Vector2 n0 = perpendicularCCW(u0);

	if( dot(u, u) > 0.25f )
	{	//the average is long enough and thus reliable
		if( dot(n0, u1) < 0.0f )
			u = -u;	//choose the larger angle
	}
	else
	{	// the average is too short, use the average of the normals to the vectors instead
		Vector2 n1 = perpendicularCW(u1);
		u = 0.5f * (n0 + n1);
	}
	if( cw )
		u = -u;

	return normalize(u);
}

/*-------------------------------------------------------------------*//*!
* \brief	Form a reliable normalized average of the two unit input vectors.
*			The average lies on the side where the angle between the input
*			vectors is less than 180 degrees.
* \param	u0, u1 Unit input vectors.
* \return	Average of the two input vectors.
* \note		
*//*-------------------------------------------------------------------*/

static const Vector2 unitAverage(const Vector2& u0, const Vector2& u1)
{
	Vector2 u = 0.5f * (u0 + u1);

	if( dot(u, u) < 0.25f )
	{	// the average is unreliable, use the average of the normals to the vectors instead
		Vector2 n0 = perpendicularCCW(u0);
		Vector2 n1 = perpendicularCW(u1);
		u = 0.5f * (n0 + n1);
		if( dot(n1, u0) < 0.0f )
			u = -u;
	}

	return normalize(u);
}

/*-------------------------------------------------------------------*//*!
* \brief	Interpolate the given unit tangent vectors to the given
*			direction on a unit circle.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static const Vector2 circularLerp(const Vector2& t0, const Vector2& t1, RIfloat ratio, bool cw)
{
	Vector2 u0 = t0, u1 = t1;
	RIfloat l0 = 0.0f, l1 = 1.0f;
	for(int i=0;i<8;i++)
	{
		Vector2 n = unitAverage(u0, u1, cw);
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

static const Vector2 circularLerp(const Vector2& t0, const Vector2& t1, RIfloat ratio)
{
	Vector2 u0 = t0, u1 = t1;
	RIfloat l0 = 0.0f, l1 = 1.0f;
	for(int i=0;i<8;i++)
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
* \brief	Path constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Path::Path(VGint format, RIfloat scale, RIfloat bias, int segmentCapacityHint, int coordCapacityHint) :
	m_format(format),
	m_scale(scale),
	m_bias(bias),
	m_referenceCount(0),
	m_segments(),
	m_data(),
	m_vertices(),
	m_segmentToVertex(),
	m_userMinx(0.0f),
	m_userMiny(0.0f),
	m_userMaxx(0.0f),
	m_userMaxy(0.0f)
{
	RI_ASSERT(format == VG_PATH_FORMAT_STANDARD);
	if(segmentCapacityHint > 0)
		m_segments.reserve(RI_INT_MIN(segmentCapacityHint, 65536));
	if(coordCapacityHint > 0)
		m_data.reserve(RI_INT_MIN(coordCapacityHint, 65536) * getBytesPerCoordinate());
}

/*-------------------------------------------------------------------*//*!
* \brief	Path destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Path::~Path()
{
	RI_ASSERT(m_referenceCount == 0);
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a coordinate and applies scale and bias.
* \param	
* \return	
*//*-------------------------------------------------------------------*/

RIfloat Path::getCoordinate(int i) const
{
	RI_ASSERT(i >= 0 && i < m_data.size() / getBytesPerCoordinate());
	RI_ASSERT(m_scale != 0.0f);

	const RIuint8* ptr = &m_data[0];

    return (RIfloat)(((const RIfloat32*)ptr)[i]) * m_scale + m_bias;
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes a coordinate, subtracting bias and dividing out scale.
* \param	
* \return	
* \note		If the coordinates do not fit into path datatype range, they
*			will overflow silently.
*//*-------------------------------------------------------------------*/

void Path::setCoordinate(Array<RIuint8>& data, RIfloat scale, RIfloat bias, int i, RIfloat c)
{
	RI_ASSERT(i >= 0 && i < data.size()/getBytesPerCoordinate());
	RI_ASSERT(scale != 0.0f);

	c -= bias;
	c /= scale;

	RIuint8* ptr = &data[0];

		((RIfloat32*)ptr)[i] = (RIfloat32)c;

}

/*-------------------------------------------------------------------*//*!
* \brief	Given a datatype, returns the number of bytes per coordinate.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int Path::getBytesPerCoordinate()
{
	return 4;
}

/*-------------------------------------------------------------------*//*!
* \brief	Given a path segment type, returns the number of coordinates
*			it uses.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int Path::segmentToNumCoordinates(VGPathSegment segment)
{
	RI_ASSERT(((int)segment >> 1) >= 0 && ((int)segment >> 1) <= 12);
	static const int coords[13] = {0,2,2,1,1,4,6,2,4,5,5,5,5};
	return coords[(int)segment >> 1];
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the number of coordinates a segment sequence uses.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

int Path::countNumCoordinates(const RIuint8* segments, int numSegments)
{
	RI_ASSERT(segments);
	RI_ASSERT(numSegments >= 0);

	int coordinates = 0;
	for(int i=0;i<numSegments;i++)
		coordinates += segmentToNumCoordinates(getPathSegment(segments[i]));
	return coordinates;
}

/*-------------------------------------------------------------------*//*!
* \brief	Clears path segments and data, and resets capabilities.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::clear(VGbitfield capabilities)
{
	m_segments.clear();
	m_data.clear();

	//clear tessellated path
	m_vertices.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends user segments and data.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::appendData(const RIuint8* segments, int numSegments, const RIuint8* data)
{
	RI_ASSERT(numSegments > 0);
	RI_ASSERT(segments && data);
	RI_ASSERT(m_referenceCount > 0);

	//allocate new arrays
	int oldSegmentsSize = m_segments.size();
	int newSegmentsSize = oldSegmentsSize + numSegments;
	Array<RIuint8> newSegments;
	newSegments.resize(newSegmentsSize);	//throws bad_alloc

	int newCoords = countNumCoordinates(segments, numSegments);
	int bytesPerCoordinate = getBytesPerCoordinate();
	int newDataSize = m_data.size() + newCoords * bytesPerCoordinate;
	Array<RIuint8> newData;
	newData.resize(newDataSize);	//throws bad_alloc
	//if we get here, the memory allocations have succeeded

	//copy old segments and append new ones
	if(m_segments.size())
		memcpy(&newSegments[0], &m_segments[0], m_segments.size());
	memcpy(&newSegments[0] + m_segments.size(), segments, numSegments);

	//copy old data and append new ones
	if(newData.size())
	{
		if(m_data.size())
			memcpy(&newData[0], &m_data[0], m_data.size());

			RIfloat32* d = (RIfloat32*)(&newData[0] + m_data.size());
			const RIfloat32* s = (const RIfloat32*)data;
			for(int i=0;i<newCoords;i++)
				*d++ = (RIfloat32)inputFloat(*s++);

	}

	RI_ASSERT(newData.size() == countNumCoordinates(&newSegments[0],newSegments.size()) * getBytesPerCoordinate());

	//replace old arrays
	m_segments.swap(newSegments);
	m_data.swap(newData);

	int c = 0;
	for(int i=0;i<m_segments.size();i++)
	{
		VGPathSegment segment = getPathSegment(m_segments[i]);
		int coords = segmentToNumCoordinates(segment);
		c += coords;
	}

	//clear tessellated path
	m_vertices.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends a path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::append(const Path* srcPath)
{
	RI_ASSERT(srcPath);
	RI_ASSERT(m_referenceCount > 0 && srcPath->m_referenceCount > 0);

	if(srcPath->m_segments.size())
	{
		//allocate new arrays
		int newSegmentsSize = m_segments.size() + srcPath->m_segments.size();
		Array<RIuint8> newSegments;
		newSegments.resize(newSegmentsSize);	//throws bad_alloc

		int newDataSize = m_data.size() + srcPath->getNumCoordinates() * getBytesPerCoordinate();
		Array<RIuint8> newData;
		newData.resize(newDataSize);	//throws bad_alloc
		//if we get here, the memory allocations have succeeded

		//copy old segments and append new ones
		if(m_segments.size())
			memcpy(&newSegments[0], &m_segments[0], m_segments.size());
		if(srcPath->m_segments.size())
			memcpy(&newSegments[0] + m_segments.size(), &srcPath->m_segments[0], srcPath->m_segments.size());

		//copy old data and append new ones
		if(m_data.size())
			memcpy(&newData[0], &m_data[0], m_data.size());
		for(int i=0;i<srcPath->getNumCoordinates();i++)
			setCoordinate(newData, m_scale, m_bias, i + getNumCoordinates(), srcPath->getCoordinate(i));

		RI_ASSERT(newData.size() == countNumCoordinates(&newSegments[0],newSegments.size()) * getBytesPerCoordinate());

		//replace old arrays
		m_segments.swap(newSegments);
		m_data.swap(newData);
	}

	//clear tessellated path
	m_vertices.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Modifies existing coordinate data.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::modifyCoords(int startIndex, int numSegments, const RIuint8* data)
{
	RI_ASSERT(numSegments > 0);
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= m_segments.size());
	RI_ASSERT(data);
	RI_ASSERT(m_referenceCount > 0);

	int startCoord = countNumCoordinates(&m_segments[0], startIndex);
	int numCoords = countNumCoordinates(&m_segments[startIndex], numSegments);
	if(!numCoords)
		return;
	int bytesPerCoordinate = getBytesPerCoordinate();
	RIuint8* dst = &m_data[startCoord * bytesPerCoordinate];

		RIfloat32* d = (RIfloat32*)dst;
		const RIfloat32* s = (const RIfloat32*)data;
		for(int i=0;i<numCoords;i++)
			*d++ = (RIfloat32)inputFloat(*s++);


	//clear tessellated path
	m_vertices.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends a transformed copy of the source path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::transform(const Path* srcPath, const Matrix3x3& matrix)
{
	RI_ASSERT(srcPath);
	RI_ASSERT(m_referenceCount > 0 && srcPath->m_referenceCount > 0);
	RI_ASSERT(matrix.isAffine());

	if(!srcPath->m_segments.size())
		return;

	//count the number of resulting coordinates
	int numSrcCoords = 0;
	int numDstCoords = 0;
	for(int i=0;i<srcPath->m_segments.size();i++)
	{
		VGPathSegment segment = getPathSegment(srcPath->m_segments[i]);
		int coords = segmentToNumCoordinates(segment);
		numSrcCoords += coords;
		if(segment == VG_HLINE_TO || segment == VG_VLINE_TO)
			coords = 2;	//convert hline and vline to lines
		numDstCoords += coords;
	}

	//allocate new arrays
	Array<RIuint8> newSegments;
	newSegments.resize(m_segments.size() + srcPath->m_segments.size());	//throws bad_alloc
	Array<RIuint8> newData;
	newData.resize(m_data.size() + numDstCoords * getBytesPerCoordinate());	//throws bad_alloc
	//if we get here, the memory allocations have succeeded

	//copy old segments
	if(m_segments.size())
		memcpy(&newSegments[0], &m_segments[0], m_segments.size());

	//copy old data
	if(m_data.size())
		memcpy(&newData[0], &m_data[0], m_data.size());

	int srcCoord = 0;
	int dstCoord = getNumCoordinates();
	Vector2 s(0,0);		//the beginning of the current subpath
	Vector2 o(0,0);		//the last point of the previous segment
	for(int i=0;i<srcPath->m_segments.size();i++)
	{
		VGPathSegment segment = getPathSegment(srcPath->m_segments[i]);
		VGPathAbsRel absRel = getPathAbsRel(srcPath->m_segments[i]);
		int coords = segmentToNumCoordinates(segment);

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
			Vector2 c(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c += o;
			Vector2 tc = affineTransform(matrix, c);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.y);
			s = c;
			o = c;
			break;
		}

		case VG_LINE_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c += o;
			Vector2 tc = affineTransform(matrix, c);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.y);
			o = c;
			break;
		}

		case VG_HLINE_TO:
		{
			RI_ASSERT(coords == 1);
			Vector2 c(srcPath->getCoordinate(srcCoord+0), o.y);
			if(absRel == VG_RELATIVE)
				c.x += o.x;
			Vector2 tc = affineTransform(matrix, c);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.y);
			o = c;
			segment = VG_LINE_TO;
			break;
		}

		case VG_VLINE_TO:
		{
			RI_ASSERT(coords == 1);
			Vector2 c(o.x, srcPath->getCoordinate(srcCoord+0));
			if(absRel == VG_RELATIVE)
				c.y += o.y;
			Vector2 tc = affineTransform(matrix, c);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.y);
			o = c;
			segment = VG_LINE_TO;
			break;
		}

		case VG_QUAD_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c0(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c1(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			if(absRel == VG_RELATIVE)
			{
				c0 += o;
				c1 += o;
			}
			Vector2 tc0 = affineTransform(matrix, c0);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc0.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc0.y);
			Vector2 tc1 = affineTransform(matrix, c1);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.y);
			o = c1;
			break;
		}

		case VG_CUBIC_TO:
		{
			RI_ASSERT(coords == 6);
			Vector2 c0(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c1(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			Vector2 c2(srcPath->getCoordinate(srcCoord+4), srcPath->getCoordinate(srcCoord+5));
			if(absRel == VG_RELATIVE)
			{
				c0 += o;
				c1 += o;
				c2 += o;
			}
			Vector2 tc0 = affineTransform(matrix, c0);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc0.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc0.y);
			Vector2 tc1 = affineTransform(matrix, c1);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.y);
			Vector2 tc2 = affineTransform(matrix, c2);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc2.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc2.y);
			o = c2;
			break;
		}

		case VG_SQUAD_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c1(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c1 += o;
			Vector2 tc1 = affineTransform(matrix, c1);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.y);
			o = c1;
			break;
		}

		case VG_SCUBIC_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c1(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c2(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			if(absRel == VG_RELATIVE)
			{
				c1 += o;
				c2 += o;
			}
			Vector2 tc1 = affineTransform(matrix, c1);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc1.y);
			Vector2 tc2 = affineTransform(matrix, c2);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc2.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc2.y);
			o = c2;
			break;
		}

		default:
		{
			RI_ASSERT(segment == VG_SCCWARC_TO || segment == VG_SCWARC_TO ||
					  segment == VG_LCCWARC_TO || segment == VG_LCWARC_TO);
			RI_ASSERT(coords == 5);
			RIfloat rh = srcPath->getCoordinate(srcCoord+0);
			RIfloat rv = srcPath->getCoordinate(srcCoord+1);
			RIfloat rot = srcPath->getCoordinate(srcCoord+2);
			Vector2 c(srcPath->getCoordinate(srcCoord+3), srcPath->getCoordinate(srcCoord+4));
			if(absRel == VG_RELATIVE)
				c += o;

			rot = RI_DEG_TO_RAD(rot);
			Matrix3x3 u((RIfloat)cos(rot)*rh, -(RIfloat)sin(rot)*rv,  0,
						(RIfloat)sin(rot)*rh,  (RIfloat)cos(rot)*rv,  0,
						0,                   0,                   1);
			u = matrix * u;
			u[2].set(0,0,1);		//force affinity
			//u maps from the unit circle to transformed ellipse

			//compute new rh, rv and rot
			Vector2	p(u[0][0], u[1][0]);
			Vector2	q(u[1][1], -u[0][1]);
			bool swapped = false;
			if(dot(p,p) < dot(q,q))
			{
				RI_SWAP(p.x,q.x);
				RI_SWAP(p.y,q.y);
				swapped = true;
			}
			Vector2 h = (p+q) * 0.5f;
			Vector2 hp = (p-q) * 0.5f;
			RIfloat hlen = h.length();
			RIfloat hplen = hp.length();
			rh = hlen + hplen;
			rv = hlen - hplen;
			h = hplen * h + hlen * hp;
			hlen = dot(h,h);
			if(hlen == 0.0f)
				rot = 0.0f;
			else
			{
				h.normalize();
				rot = (RIfloat)acos(h.x);
				if(h.y < 0.0f)
					rot = 2.0f*PI - rot;
			}
			if(swapped)
				rot += PI*0.5f;

			setCoordinate(newData, m_scale, m_bias, dstCoord++, rh);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, rv);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, RI_RAD_TO_DEG(rot));
			Vector2 tc = affineTransform(matrix, c);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.x);
			setCoordinate(newData, m_scale, m_bias, dstCoord++, tc.y);
			o = c;
			break;
		}
		}

		newSegments[m_segments.size() + i] = (RIuint8)(segment | VG_ABSOLUTE);
		srcCoord += coords;
	}
	RI_ASSERT(srcCoord == numSrcCoords);
	RI_ASSERT(dstCoord == getNumCoordinates() + numDstCoords);

	RI_ASSERT(newData.size() == countNumCoordinates(&newSegments[0],newSegments.size()) * getBytesPerCoordinate());

	//replace old arrays
	m_segments.swap(newSegments);
	m_data.swap(newData);

	//clear tessellated path
	m_vertices.clear();
}

/*-------------------------------------------------------------------*//*!
* \brief	Normalizes a path for interpolation.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::normalizeForInterpolation(const Path* srcPath)
{
	RI_ASSERT(srcPath);
	RI_ASSERT(srcPath != this);
	RI_ASSERT(srcPath->m_referenceCount > 0);

	//count the number of resulting coordinates
	int numSrcCoords = 0;
	int numDstCoords = 0;
	for(int i=0;i<srcPath->m_segments.size();i++)
	{
		VGPathSegment segment = getPathSegment(srcPath->m_segments[i]);
		int coords = segmentToNumCoordinates(segment);
		numSrcCoords += coords;
		switch(segment)
		{
		case VG_CLOSE_PATH:
		case VG_MOVE_TO:
		case VG_LINE_TO:
			break;

		case VG_HLINE_TO:
		case VG_VLINE_TO:
			coords = 2;
			break;

		case VG_QUAD_TO:
		case VG_CUBIC_TO:
		case VG_SQUAD_TO:
		case VG_SCUBIC_TO:
			coords = 6;
			break;

		default:
			RI_ASSERT(segment == VG_SCCWARC_TO || segment == VG_SCWARC_TO ||
					  segment == VG_LCCWARC_TO || segment == VG_LCWARC_TO);
			break;
		}
		numDstCoords += coords;
	}

	m_segments.resize(srcPath->m_segments.size());	//throws bad_alloc
	m_data.resize(numDstCoords * getBytesPerCoordinate());	//throws bad_alloc

	int srcCoord = 0;
	int dstCoord = 0;
	Vector2 s(0,0);		//the beginning of the current subpath
	Vector2 o(0,0);		//the last point of the previous segment

	// the last internal control point of the previous segment, if the
	//segment was a (regular or smooth) quadratic or cubic
	//Bezier, or else the last point of the previous segment
	Vector2 p(0,0);		
	for(int i=0;i<srcPath->m_segments.size();i++)
	{
		VGPathSegment segment = getPathSegment(srcPath->m_segments[i]);
		VGPathAbsRel absRel = getPathAbsRel(srcPath->m_segments[i]);
		int coords = segmentToNumCoordinates(segment);

		switch(segment)
		{
		case VG_CLOSE_PATH:
		{
			RI_ASSERT(coords == 0);
			p = s;
			o = s;
			break;
		}

		case VG_MOVE_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c += o;
			setCoordinate(dstCoord++, c.x);
			setCoordinate(dstCoord++, c.y);
			s = c;
			p = c;
			o = c;
			break;
		}

		case VG_LINE_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c += o;
			setCoordinate(dstCoord++, c.x);
			setCoordinate(dstCoord++, c.y);
			p = c;
			o = c;
			break;
		}

		case VG_HLINE_TO:
		{
			RI_ASSERT(coords == 1);
			Vector2 c(srcPath->getCoordinate(srcCoord+0), o.y);
			if(absRel == VG_RELATIVE)
				c.x += o.x;
			setCoordinate(dstCoord++, c.x);
			setCoordinate(dstCoord++, c.y);
			p = c;
			o = c;
			segment = VG_LINE_TO;
			break;
		}

		case VG_VLINE_TO:
		{
			RI_ASSERT(coords == 1);
			Vector2 c(o.x, srcPath->getCoordinate(srcCoord+0));
			if(absRel == VG_RELATIVE)
				c.y += o.y;
			setCoordinate(dstCoord++, c.x);
			setCoordinate(dstCoord++, c.y);
			p = c;
			o = c;
			segment = VG_LINE_TO;
			break;
		}

		case VG_QUAD_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c0(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c1(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			if(absRel == VG_RELATIVE)
			{
				c0 += o;
				c1 += o;
			}
			Vector2 d0 = (1.0f/3.0f) * (o + 2.0f * c0);
			Vector2 d1 = (1.0f/3.0f) * (c1 + 2.0f * c0);
			setCoordinate(dstCoord++, d0.x);
			setCoordinate(dstCoord++, d0.y);
			setCoordinate(dstCoord++, d1.x);
			setCoordinate(dstCoord++, d1.y);
			setCoordinate(dstCoord++, c1.x);
			setCoordinate(dstCoord++, c1.y);
			p = c0;
			o = c1;
			segment = VG_CUBIC_TO;
			break;
		}

		case VG_CUBIC_TO:
		{
			RI_ASSERT(coords == 6);
			Vector2 c0(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c1(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			Vector2 c2(srcPath->getCoordinate(srcCoord+4), srcPath->getCoordinate(srcCoord+5));
			if(absRel == VG_RELATIVE)
			{
				c0 += o;
				c1 += o;
				c2 += o;
			}
			setCoordinate(dstCoord++, c0.x);
			setCoordinate(dstCoord++, c0.y);
			setCoordinate(dstCoord++, c1.x);
			setCoordinate(dstCoord++, c1.y);
			setCoordinate(dstCoord++, c2.x);
			setCoordinate(dstCoord++, c2.y);
			p = c1;
			o = c2;
			break;
		}

		case VG_SQUAD_TO:
		{
			RI_ASSERT(coords == 2);
			Vector2 c0 = 2.0f * o - p;
			Vector2 c1(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			if(absRel == VG_RELATIVE)
				c1 += o;
			Vector2 d0 = (1.0f/3.0f) * (o + 2.0f * c0);
			Vector2 d1 = (1.0f/3.0f) * (c1 + 2.0f * c0);
			setCoordinate(dstCoord++, d0.x);
			setCoordinate(dstCoord++, d0.y);
			setCoordinate(dstCoord++, d1.x);
			setCoordinate(dstCoord++, d1.y);
			setCoordinate(dstCoord++, c1.x);
			setCoordinate(dstCoord++, c1.y);
			p = c0;
			o = c1;
			segment = VG_CUBIC_TO;
			break;
		}

		case VG_SCUBIC_TO:
		{
			RI_ASSERT(coords == 4);
			Vector2 c0 = 2.0f * o - p;
			Vector2 c1(srcPath->getCoordinate(srcCoord+0), srcPath->getCoordinate(srcCoord+1));
			Vector2 c2(srcPath->getCoordinate(srcCoord+2), srcPath->getCoordinate(srcCoord+3));
			if(absRel == VG_RELATIVE)
			{
				c1 += o;
				c2 += o;
			}
			setCoordinate(dstCoord++, c0.x);
			setCoordinate(dstCoord++, c0.y);
			setCoordinate(dstCoord++, c1.x);
			setCoordinate(dstCoord++, c1.y);
			setCoordinate(dstCoord++, c2.x);
			setCoordinate(dstCoord++, c2.y);
			p = c1;
			o = c2;
			segment = VG_CUBIC_TO;
			break;
		}

		default:
		{
			RI_ASSERT(segment == VG_SCCWARC_TO || segment == VG_SCWARC_TO ||
					  segment == VG_LCCWARC_TO || segment == VG_LCWARC_TO);
			RI_ASSERT(coords == 5);
			RIfloat rh = srcPath->getCoordinate(srcCoord+0);
			RIfloat rv = srcPath->getCoordinate(srcCoord+1);
			RIfloat rot = srcPath->getCoordinate(srcCoord+2);
			Vector2 c(srcPath->getCoordinate(srcCoord+3), srcPath->getCoordinate(srcCoord+4));
			if(absRel == VG_RELATIVE)
				c += o;
			setCoordinate(dstCoord++, rh);
			setCoordinate(dstCoord++, rv);
			setCoordinate(dstCoord++, rot);
			setCoordinate(dstCoord++, c.x);
			setCoordinate(dstCoord++, c.y);
			p = c;
			o = c;
			break;
		}
		}

		m_segments[i] = (RIuint8)(segment | VG_ABSOLUTE);
		srcCoord += coords;
	}
	RI_ASSERT(srcCoord == numSrcCoords);
	RI_ASSERT(dstCoord == numDstCoords);
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends a linearly interpolated copy of the two source paths.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

bool Path::interpolate(const Path* startPath, const Path* endPath, RIfloat amount)
{
	RI_ASSERT(startPath && endPath);
	RI_ASSERT(m_referenceCount > 0 && startPath->m_referenceCount > 0 && endPath->m_referenceCount > 0);

	if(!startPath->m_segments.size() || startPath->m_segments.size() != endPath->m_segments.size())
		return false;	//start and end paths are incompatible or zero length

	Path start(VG_PATH_FORMAT_STANDARD, 1.0f, 0.0f, 0, 0);
	start.normalizeForInterpolation(startPath);	//throws bad_alloc

	Path end(VG_PATH_FORMAT_STANDARD, 1.0f, 0.0f, 0, 0);
	end.normalizeForInterpolation(endPath);	//throws bad_alloc

	//check that start and end paths are compatible
	if(start.m_data.size() != end.m_data.size() || start.m_segments.size() != end.m_segments.size())
		return false;	//start and end paths are incompatible

	//allocate new arrays
	Array<RIuint8> newSegments;
	newSegments.resize(m_segments.size() + start.m_segments.size());	//throws bad_alloc
	Array<RIuint8> newData;
	newData.resize(m_data.size() + start.m_data.size() * getBytesPerCoordinate() / getBytesPerCoordinate());	//throws bad_alloc
	//if we get here, the memory allocations have succeeded

	//copy old segments
	if(m_segments.size())
		memcpy(&newSegments[0], &m_segments[0], m_segments.size());

	//copy old data
	if(m_data.size())
		memcpy(&newData[0], &m_data[0], m_data.size());

	//copy segments
	for(int i=0;i<start.m_segments.size();i++)
	{
		VGPathSegment s = getPathSegment(start.m_segments[i]);
		VGPathSegment e = getPathSegment(end.m_segments[i]);

		if(s == VG_SCCWARC_TO || s == VG_SCWARC_TO || s == VG_LCCWARC_TO || s == VG_LCWARC_TO)
		{
			if(e != VG_SCCWARC_TO && e != VG_SCWARC_TO && e != VG_LCCWARC_TO && e != VG_LCWARC_TO)
				return false;	//start and end paths are incompatible
			if(amount < 0.5f)
				newSegments[m_segments.size() + i] = start.m_segments[i];
			else
				newSegments[m_segments.size() + i] = end.m_segments[i];
		}
		else
		{
			if(s != e)
				return false;	//start and end paths are incompatible
			newSegments[m_segments.size() + i] = start.m_segments[i];
		}
	}

	//interpolate data
	int oldNumCoords = getNumCoordinates();
	for(int i=0;i<start.getNumCoordinates();i++)
		setCoordinate(newData, m_scale, m_bias, oldNumCoords + i, start.getCoordinate(i) * (1.0f - amount) + end.getCoordinate(i) * amount);

	RI_ASSERT(newData.size() == countNumCoordinates(&newSegments[0],newSegments.size()) * getBytesPerCoordinate());

	//replace old arrays
	m_segments.swap(newSegments);
	m_data.swap(newData);

	//clear tessellated path
	m_vertices.clear();

	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path for filling and appends resulting edges
*			to a rasterizer.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::fill(const Matrix3x3& pathToSurface, Rasterizer& rasterizer)
{
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(pathToSurface.isAffine());

	tessellate();	//throws bad_alloc

	try
	{
		Vector2 p0(0,0), p1(0,0);
		for(int i=0;i<m_vertices.size();i++)
		{
			p1 = affineTransform(pathToSurface, m_vertices[i].userPosition);

			if(!(m_vertices[i].flags & START_SEGMENT))
			{	//in the middle of a segment
				rasterizer.addEdge(p0, p1);	//throws bad_alloc
			}

			p0 = p1;
		}
	}
	catch(std::bad_alloc)
	{
		rasterizer.clear();	//remove the unfinished path
		throw;
	}
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

void Path::interpolateStroke(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth) const
{
	Vector2 ppccw = affineTransform(pathToSurface, v0.ccw);
	Vector2 ppcw = affineTransform(pathToSurface, v0.cw);
	Vector2 endccw = affineTransform(pathToSurface, v1.ccw);
	Vector2 endcw = affineTransform(pathToSurface, v1.cw);

	const RIfloat tessellationAngle = 5.0f;

	RIfloat angle = RI_RAD_TO_DEG((RIfloat)acos(RI_CLAMP(dot(v0.t, v1.t), -1.0f, 1.0f))) / tessellationAngle;
	int samples = RI_INT_MAX((int)ceil(angle), 1);
	Vector2 prev = v0.p;
	Vector2 prevt = v0.t;
	Vector2 position = v0.p;
	Vector2 pnccw = ppccw;
	Vector2 pncw = ppcw;
	for(int j=0;j<samples;j++)
	{
		RIfloat t = (RIfloat)(j+1) / (RIfloat)samples;
		position = v0.p * (1.0f - t) + v1.p * t;
		Vector2 tangent = circularLerp(v0.t, v1.t, t);
		Vector2 n = normalize(perpendicularCCW(tangent)) * strokeWidth * 0.5f;

		if(j == samples-1)
			position = v1.p;

		Vector2 npccw = affineTransform(pathToSurface, prev + n);
		Vector2 npcw = affineTransform(pathToSurface, prev - n);
		Vector2 nnccw = affineTransform(pathToSurface, position + n);
		Vector2 nncw = affineTransform(pathToSurface, position - n);

		rasterizer.addEdge(npccw, nnccw);	//throws bad_alloc
		rasterizer.addEdge(nnccw, nncw);	//throws bad_alloc
		rasterizer.addEdge(nncw, npcw);		//throws bad_alloc
		rasterizer.addEdge(npcw, npccw);	//throws bad_alloc

		if(dot(n,prevt) <= 0.0f)
		{
			rasterizer.addEdge(pnccw, npcw);	//throws bad_alloc
			rasterizer.addEdge(npcw, pncw);		//throws bad_alloc
			rasterizer.addEdge(pncw, npccw);	//throws bad_alloc
			rasterizer.addEdge(npccw, pnccw);	//throws bad_alloc
		}
		else
		{
			rasterizer.addEdge(pnccw, npccw);	//throws bad_alloc
			rasterizer.addEdge(npccw, pncw);	//throws bad_alloc
			rasterizer.addEdge(pncw, npcw);		//throws bad_alloc
			rasterizer.addEdge(npcw, pnccw);	//throws bad_alloc
		}

		ppccw = npccw;
		ppcw = npcw;
		pnccw = nnccw;
		pncw = nncw;
		prev = position;
		prevt = tangent;
	}

	//connect the last segment to the end coordinates
	Vector2 n = perpendicularCCW(v1.t);
	if(dot(n,prevt) <= 0.0f)
	{
		rasterizer.addEdge(pnccw, endcw);	//throws bad_alloc
		rasterizer.addEdge(endcw, pncw);	//throws bad_alloc
		rasterizer.addEdge(pncw, endccw);	//throws bad_alloc
		rasterizer.addEdge(endccw, pnccw);	//throws bad_alloc
	}
	else
	{
		rasterizer.addEdge(pnccw, endccw);	//throws bad_alloc
		rasterizer.addEdge(endccw, pncw);	//throws bad_alloc
		rasterizer.addEdge(pncw, endcw);	//throws bad_alloc
		rasterizer.addEdge(endcw, pnccw);	//throws bad_alloc
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Generate edges for stroke caps. Resulting polygons are closed.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::doCap(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v, RIfloat strokeWidth, CGLineCap capStyle) const
{
	Vector2 ccwt = affineTransform(pathToSurface, v.ccw);
	Vector2 cwt = affineTransform(pathToSurface, v.cw);

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
		Vector2 u0 = normalize(v.ccw - v.p);
		Vector2 u1 = normalize(v.cw - v.p);
		Vector2 prev = ccwt;
		rasterizer.addEdge(cwt, ccwt);	//throws bad_alloc
		for(int j=1;j<samples;j++)
		{
			Vector2 next = v.p + circularLerp(u0, u1, t, true) * strokeWidth * 0.5f;
			next = affineTransform(pathToSurface, next);

			rasterizer.addEdge(prev, next);	//throws bad_alloc
			prev = next;
			t += step;
		}
		rasterizer.addEdge(prev, cwt);	//throws bad_alloc
		break;
	}

	default:
	{
		RI_ASSERT(capStyle == kCGLineCapSquare);
		Vector2 t = v.t;
		t.normalize();
		Vector2 ccws = affineTransform(pathToSurface, v.ccw + t * strokeWidth * 0.5f);
		Vector2 cws = affineTransform(pathToSurface, v.cw + t * strokeWidth * 0.5f);
		rasterizer.addEdge(cwt, ccwt);	//throws bad_alloc
		rasterizer.addEdge(ccwt, ccws);	//throws bad_alloc
		rasterizer.addEdge(ccws, cws);	//throws bad_alloc
		rasterizer.addEdge(cws, cwt);	//throws bad_alloc
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

void Path::doJoin(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const StrokeVertex& v0, const StrokeVertex& v1, RIfloat strokeWidth, CGLineJoin joinStyle, RIfloat miterLimit) const
{
	Vector2 ccw0t = affineTransform(pathToSurface, v0.ccw);
	Vector2 cw0t = affineTransform(pathToSurface, v0.cw);
	Vector2 ccw1t = affineTransform(pathToSurface, v1.ccw);
	Vector2 cw1t = affineTransform(pathToSurface, v1.cw);
	Vector2 m0t = affineTransform(pathToSurface, v0.p);
	Vector2 m1t = affineTransform(pathToSurface, v1.p);

	Vector2 tccw = v1.ccw - v0.ccw;
	Vector2 s, e, m, st, et;
	bool cw;

	if( dot(tccw, v0.t) > 0.0f )
	{	//draw ccw miter (draw from point 0 to 1)
		s = ccw0t;
		e = ccw1t;
		st = v0.t;
		et = v1.t;
		m = v0.ccw;
		cw = false;
		rasterizer.addEdge(m0t, ccw0t);	//throws bad_alloc
		rasterizer.addEdge(ccw1t, m1t);	//throws bad_alloc
		rasterizer.addEdge(m1t, m0t);	//throws bad_alloc
	}
	else
	{	//draw cw miter (draw from point 1 to 0)
		s = cw1t;
		e = cw0t;
		st = v1.t;
		et = v0.t;
		m = v0.cw;
		cw = true;
		rasterizer.addEdge(cw0t, m0t);	//throws bad_alloc
		rasterizer.addEdge(m1t, cw1t);	//throws bad_alloc
		rasterizer.addEdge(m0t, m1t);	//throws bad_alloc
	}

	switch(joinStyle)
	{
	case kCGLineJoinMiter:
	{
		RIfloat theta = (RIfloat)acos(RI_CLAMP(dot(v0.t, -v1.t), -1.0f, 1.0f));
		RIfloat miterLengthPerStrokeWidth = 1.0f / (RIfloat)sin(theta*0.5f);
		if( miterLengthPerStrokeWidth < miterLimit )
		{	//miter
			RIfloat l = (RIfloat)cos(theta*0.5f) * miterLengthPerStrokeWidth * (strokeWidth * 0.5f);
			l = RI_MIN(l, RI_FLOAT_MAX);	//force finite
			Vector2 c = m + v0.t * l;
			c = affineTransform(pathToSurface, c);
			rasterizer.addEdge(s, c);	//throws bad_alloc
			rasterizer.addEdge(c, e);	//throws bad_alloc
		}
		else
		{	//bevel
			rasterizer.addEdge(s, e);	//throws bad_alloc
		}
		break;
	}

	case kCGLineJoinRound:
	{
		const RIfloat tessellationAngle = 5.0f;

		Vector2 prev = s;
		RIfloat angle = RI_RAD_TO_DEG((RIfloat)acos(RI_CLAMP(dot(st, et), -1.0f, 1.0f))) / tessellationAngle;
		int samples = (int)ceil(angle);
		if( samples )
		{
			RIfloat step = 1.0f / samples;
			RIfloat t = step;
			for(int j=1;j<samples;j++)
			{
				Vector2 position = v0.p * (1.0f - t) + v1.p * t;
				Vector2 tangent = circularLerp(st, et, t, true);

				Vector2 next = position + normalize(perpendicular(tangent, cw)) * strokeWidth * 0.5f;
				next = affineTransform(pathToSurface, next);

				rasterizer.addEdge(prev, next);	//throws bad_alloc
				prev = next;
				t += step;
			}
		}
		rasterizer.addEdge(prev, e);	//throws bad_alloc
		break;
	}

	default:
		RI_ASSERT(joinStyle == kCGLineJoinBevel);
		if(!cw)
			rasterizer.addEdge(ccw0t, ccw1t);	//throws bad_alloc
		else
			rasterizer.addEdge(cw1t, cw0t);		//throws bad_alloc
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

void Path::stroke(const Matrix3x3& pathToSurface, Rasterizer& rasterizer, const RIfloat* dashPattern,int dashPatternSize, RIfloat dashPhase, bool dashPhaseReset, RIfloat strokeWidth, CGLineCap capStyle, CGLineJoin joinStyle, RIfloat miterLimit)
{
	RI_ASSERT(pathToSurface.isAffine());
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(strokeWidth >= 0.0f);
	RI_ASSERT(miterLimit >= 1.0f);

	tessellate();	//throws bad_alloc

	if(!m_vertices.size())
		return;

	bool dashing = true;

	if( dashPatternSize & 1 )
		dashPatternSize--;	//odd number of dash pattern entries, discard the last one
	RIfloat dashPatternLength = 0.0f;
	for(int i=0;i<dashPatternSize;i++)
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
	try
	{
		RIfloat nextDash = 0.0f;
		int d = 0;
		bool inDash = true;
		StrokeVertex v0, v1, vs;
		for(int i=0;i<m_vertices.size();i++)
		{
			//read the next vertex
			Vertex& v = m_vertices[i];
			v1.p = v.userPosition;
			v1.t = v.userTangent;
			RI_ASSERT(!isZero(v1.t));	//don't allow zero tangents
			v1.ccw = v1.p + normalize(perpendicularCCW(v1.t)) * strokeWidth * 0.5f;
			v1.cw = v1.p + normalize(perpendicularCW(v1.t)) * strokeWidth * 0.5f;
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
							doCap(pathToSurface, rasterizer, v0, strokeWidth, capStyle);	//end cap	//throws bad_alloc
						if( vs.inDash )
						{
							StrokeVertex vi = vs;
							vi.t = -vi.t;
							RI_SWAP(vi.ccw.x, vi.cw.x);
							RI_SWAP(vi.ccw.y, vi.cw.y);
							doCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap	//throws bad_alloc
						}
					}
					else
					{	//join two segments
						RI_ASSERT(v0.inDash == v1.inDash);
						if( v0.inDash )
							doJoin(pathToSurface, rasterizer, v0, v1, strokeWidth, joinStyle, miterLimit);	//throws bad_alloc
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
							throw std::bad_alloc();		//too many dashes, throw bad_alloc

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
							nextDashVertex.p = v0.p * (1.0f - ratio) + v1.p * ratio;
							nextDashVertex.t = circularLerp(v0.t, v1.t, ratio);
							nextDashVertex.ccw = nextDashVertex.p + normalize(perpendicularCCW(nextDashVertex.t)) * strokeWidth * 0.5f;
							nextDashVertex.cw = nextDashVertex.p + normalize(perpendicularCW(nextDashVertex.t)) * strokeWidth * 0.5f;

							if( inDash )
							{	//stroke from prevDashVertex -> nextDashVertex
								if( numDashStops )
								{	//prevDashVertex is not the start vertex of the segment, cap it (start vertex has already been joined or capped)
									StrokeVertex vi = prevDashVertex;
									vi.t = -vi.t;
									RI_SWAP(vi.ccw.x, vi.cw.x);
									RI_SWAP(vi.ccw.y, vi.cw.y);
									doCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//throws bad_alloc
								}
								interpolateStroke(pathToSurface, rasterizer, prevDashVertex, nextDashVertex, strokeWidth);	//throws bad_alloc
								doCap(pathToSurface, rasterizer, nextDashVertex, strokeWidth, capStyle);	//end cap	//throws bad_alloc
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
								vi.t = -vi.t;
								RI_SWAP(vi.ccw.x, vi.cw.x);
								RI_SWAP(vi.ccw.y, vi.cw.y);
								doCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//throws bad_alloc
							}
							interpolateStroke(pathToSurface, rasterizer, prevDashVertex, v1, strokeWidth);	//throws bad_alloc
							//no cap, leave path open
						}

						v1.inDash = inDash;	//update inDash status of the segment end point
					}
					else	//no dashing, just interpolate segment end points
						interpolateStroke(pathToSurface, rasterizer, v0, v1, strokeWidth);	//throws bad_alloc
				}
			}

			if((v.flags & END_SEGMENT) && (v.flags & CLOSE_SUBPATH))
			{	//join start and end of the current subpath
				if( v1.inDash && vs.inDash )
					doJoin(pathToSurface, rasterizer, v1, vs, strokeWidth, joinStyle, miterLimit);	//throws bad_alloc
				else
				{	//both start and end are not in dash, cap them
					if( v1.inDash )
						doCap(pathToSurface, rasterizer, v1, strokeWidth, capStyle);	//end cap	//throws bad_alloc
					if( vs.inDash )
					{
						StrokeVertex vi = vs;
						vi.t = -vi.t;
						RI_SWAP(vi.ccw.x, vi.cw.x);
						RI_SWAP(vi.ccw.y, vi.cw.y);
						doCap(pathToSurface, rasterizer, vi, strokeWidth, capStyle);	//start cap	//throws bad_alloc
					}
				}
			}

			v0 = v1;
		}
	}
	catch(std::bad_alloc)
	{
		rasterizer.clear();	//remove the unfinished path
		throw;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and returns a position and a tangent on the path
*			given a distance along the path.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::getPointAlong(int startIndex, int numSegments, RIfloat distance, Vector2& p, Vector2& t)
{
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= m_segments.size() && numSegments > 0);

	tessellate();	//throws bad_alloc

	RI_ASSERT(startIndex >= 0 && startIndex < m_segmentToVertex.size());
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= m_segmentToVertex.size());

	int startVertex = m_segmentToVertex[startIndex].start;
	int endVertex = m_segmentToVertex[startIndex + numSegments - 1].end;

	if(!m_vertices.size() || (startVertex == -1 && endVertex == -1))
	{	// no vertices in the tessellated path. The path is empty or consists only of zero-length segments.
		p.set(0,0);
		t.set(1,0);
		return;
	}
	if(startVertex == -1)
		startVertex = 0;

	RI_ASSERT(startVertex >= 0 && startVertex < m_vertices.size());
	RI_ASSERT(endVertex >= 0 && endVertex < m_vertices.size());

	distance += m_vertices[startVertex].pathLength;	//map distance to the range of the whole path

	if(distance <= m_vertices[startVertex].pathLength)
	{	//return the first point of the path
		p = m_vertices[startVertex].userPosition;
		t = m_vertices[startVertex].userTangent;
		return;
	}

	if(distance >= m_vertices[endVertex].pathLength)
	{	//return the last point of the path
		p = m_vertices[endVertex].userPosition;
		t = m_vertices[endVertex].userTangent;
		return;
	}

	//search for the segment containing the distance
	for(int s=startIndex;s<startIndex+numSegments;s++)
	{
		int start = m_segmentToVertex[s].start;
		int end = m_segmentToVertex[s].end;
		if(start < 0)
			start = 0;
		if(end < 0)
			end = 0;
		RI_ASSERT(start >= 0 && start < m_vertices.size());
		RI_ASSERT(end >= 0 && end < m_vertices.size());

		if(distance >= m_vertices[start].pathLength && distance < m_vertices[end].pathLength)
		{	//segment contains the queried distance
			for(int i=start;i<end;i++)
			{
				const Vertex& v0 = m_vertices[i];
				const Vertex& v1 = m_vertices[i+1];
				if(distance >= v0.pathLength && distance < v1.pathLength)
				{	//segment found, interpolate linearly between its end points
					RIfloat edgeLength = v1.pathLength - v0.pathLength;
					RI_ASSERT(edgeLength > 0.0f);
					RIfloat r = (distance - v0.pathLength) / edgeLength;
					p = (1.0f - r) * v0.userPosition + r * v1.userPosition;
					t = (1.0f - r) * v0.userTangent + r * v1.userTangent;
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

RIfloat Path::getPathLength(int startIndex, int numSegments)
{
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(startIndex >= 0 && startIndex + numSegments <= m_segments.size() && numSegments > 0);

	tessellate();	//throws bad_alloc

	RI_ASSERT(startIndex >= 0 && startIndex < m_segmentToVertex.size());
	RI_ASSERT(startIndex + numSegments >= 0 && startIndex + numSegments <= m_segmentToVertex.size());

	int startVertex = m_segmentToVertex[startIndex].start;
	int endVertex = m_segmentToVertex[startIndex + numSegments - 1].end;

	if(!m_vertices.size())
		return 0.0f;

	RIfloat startPathLength = 0.0f;
	if(startVertex >= 0)
	{
		RI_ASSERT(startVertex >= 0 && startVertex < m_vertices.size());
		startPathLength = m_vertices[startVertex].pathLength;
	}
	RIfloat endPathLength = 0.0f;
	if(endVertex >= 0)
	{
		RI_ASSERT(endVertex >= 0 && endVertex < m_vertices.size());
		endPathLength = m_vertices[endVertex].pathLength;
	}

	return endPathLength - startPathLength;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and computes its bounding box in user space.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::getPathBounds(RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy)
{
	RI_ASSERT(m_referenceCount > 0);

	tessellate();	//throws bad_alloc

	if(m_vertices.size())
	{
		minx = m_userMinx;
		miny = m_userMiny;
		maxx = m_userMaxx;
		maxy = m_userMaxy;
	}
	else
	{
		minx = miny = 0;
		maxx = maxy = -1;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a path, and computes its bounding box in surface space.
* \param	
* \return	
* \note		if runs out of memory, throws bad_alloc and leaves the path as it was
*//*-------------------------------------------------------------------*/

void Path::getPathTransformedBounds(const Matrix3x3& pathToSurface, RIfloat& minx, RIfloat& miny, RIfloat& maxx, RIfloat& maxy)
{
	RI_ASSERT(m_referenceCount > 0);
	RI_ASSERT(pathToSurface.isAffine());

	tessellate();	//throws bad_alloc

	if(m_vertices.size())
	{
		Vector3 p0(m_userMinx, m_userMiny, 1.0f);
		Vector3 p1(m_userMinx, m_userMaxy, 1.0f);
		Vector3 p2(m_userMaxx, m_userMaxy, 1.0f);
		Vector3 p3(m_userMaxx, m_userMiny, 1.0f);
		p0 = pathToSurface * p0;
		p1 = pathToSurface * p1;
		p2 = pathToSurface * p2;
		p3 = pathToSurface * p3;

		minx = RI_MIN(RI_MIN(RI_MIN(p0.x, p1.x), p2.x), p3.x);
		miny = RI_MIN(RI_MIN(RI_MIN(p0.y, p1.y), p2.y), p3.y);
		maxx = RI_MAX(RI_MAX(RI_MAX(p0.x, p1.x), p2.x), p3.x);
		maxy = RI_MAX(RI_MAX(RI_MAX(p0.y, p1.y), p2.y), p3.y);
	}
	else
	{
		minx = miny = 0;
		maxx = maxy = -1;
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Adds a vertex to a tessellated path.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::addVertex(const Vector2& p, const Vector2& t, RIfloat pathLength, unsigned int flags)
{
	RI_ASSERT(!isZero(t));

	Vertex v;
	v.pathLength = pathLength;
	v.userPosition = p;
	v.userTangent = t;
	v.flags = flags;
	m_vertices.push_back(v);	//throws bad_alloc

	m_userMinx = RI_MIN(m_userMinx, v.userPosition.x);
	m_userMiny = RI_MIN(m_userMiny, v.userPosition.y);
	m_userMaxx = RI_MAX(m_userMaxx, v.userPosition.x);
	m_userMaxy = RI_MAX(m_userMaxy, v.userPosition.y);
}

/*-------------------------------------------------------------------*//*!
* \brief	Adds an edge to a tessellated path.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::addEdge(const Vector2& p0, const Vector2& p1, const Vector2& t0, const Vector2& t1, unsigned int startFlags, unsigned int endFlags)
{
	Vertex v;
	RIfloat pathLength = 0.0f;

	RI_ASSERT(!isZero(t0) && !isZero(t1));

	//segment midpoints are shared between edges
	if( startFlags & START_SEGMENT )
	{
		if(m_vertices.size() > 0)
			pathLength = m_vertices[m_vertices.size()-1].pathLength;

		addVertex(p0, t0, pathLength, startFlags);	//throws bad_alloc
	}

	//other than implicit close paths (caused by a MOVE_TO) add to path length
	if( !(endFlags & IMPLICIT_CLOSE_SUBPATH) )
	{
		//NOTE: with extremely large coordinates the floating point path length is infinite
		RIfloat l = (p1 - p0).length();
		pathLength = m_vertices[m_vertices.size()-1].pathLength + l;
		pathLength = RI_MIN(pathLength, RI_FLOAT_MAX);
	}

	addVertex(p1, t1, pathLength, endFlags);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a close-path segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Path::addEndPath(const Vector2& p0, const Vector2& p1, bool subpathHasGeometry, unsigned int flags)
{
	if(!subpathHasGeometry)
	{	//single vertex
		Vector2 t(1.0f,0.0f);
		addEdge(p0, p1, t, t, START_SEGMENT | START_SUBPATH, END_SEGMENT | END_SUBPATH);	//throws bad_alloc
		addEdge(p0, p1, -t, -t, IMPLICIT_CLOSE_SUBPATH | START_SEGMENT, IMPLICIT_CLOSE_SUBPATH | END_SEGMENT);	//throws bad_alloc
		return;
	}
	//the subpath contains segment commands that have generated geometry

	//add a close path segment to the start point of the subpath
	RI_ASSERT(m_vertices.size() > 0);
	m_vertices[m_vertices.size()-1].flags |= END_SUBPATH;

	Vector2 t = normalize(p1 - p0);
	if(isZero(t))
		t = m_vertices[m_vertices.size()-1].userTangent;	//if the segment is zero-length, use the tangent of the last segment end point so that proper join will be generated
	RI_ASSERT(!isZero(t));

	addEdge(p0, p1, t, t, flags | START_SEGMENT, flags | END_SEGMENT);	//throws bad_alloc
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a line-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Path::addLineTo(const Vector2& p0, const Vector2& p1, bool subpathHasGeometry)
{
	if(p0 == p1)
		return false;	//discard zero-length segments

	//compute end point tangents
	Vector2 t = normalize(p1 - p0);
	RI_ASSERT(!isZero(t));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;
	addEdge(p0, p1, t, t, startFlags, END_SEGMENT);	//throws bad_alloc
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a quad-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Path::addQuadTo(const Vector2& p0, const Vector2& p1, const Vector2& p2, bool subpathHasGeometry)
{
	if(p0 == p1 && p0 == p2)
	{
		RI_ASSERT(p1 == p2);
		return false;	//discard zero-length segments
	}

	//compute end point tangents

	Vector2 incomingTangent = normalize(p1 - p0);
	Vector2 outgoingTangent = normalize(p2 - p1);
	if(p0 == p1)
		incomingTangent = normalize(p2 - p0);
	if(p1 == p2)
		outgoingTangent = normalize(p2 - p0);
	RI_ASSERT(!isZero(incomingTangent) && !isZero(outgoingTangent));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

	const int segments = 256;
	Vector2 pp = p0;
	Vector2 tp = incomingTangent;
	unsigned int prevFlags = startFlags;
	for(int i=1;i<segments;i++)
	{
		RIfloat t = (RIfloat)i / (RIfloat)segments;
		RIfloat u = 1.0f-t;
		Vector2 pn = u*u * p0 + 2.0f*t*u * p1 + t*t * p2;
		Vector2 tn = (-1.0f+t) * p0 + (1.0f-2.0f*t) * p1 + t * p2;
		tn = normalize(tn);
		if(isZero(tn))
			tn = tp;

		addEdge(pp, pn, tp, tn, prevFlags, 0);	//throws bad_alloc

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	addEdge(pp, p2, tp, outgoingTangent, prevFlags, END_SEGMENT);	//throws bad_alloc
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates a cubic-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Path::addCubicTo(const Vector2& p0, const Vector2& p1, const Vector2& p2, const Vector2& p3, bool subpathHasGeometry)
{
	if(p0 == p1 && p0 == p2 && p0 == p3)
	{
		RI_ASSERT(p1 == p2 && p1 == p3 && p2 == p3);
		return false;	//discard zero-length segments
	}

	//compute end point tangents
	Vector2 incomingTangent = normalize(p1 - p0);
	Vector2 outgoingTangent = normalize(p3 - p2);
	if(p0 == p1)
	{
		incomingTangent = normalize(p2 - p0);
		if(p1 == p2)
			incomingTangent = normalize(p3 - p0);
	}
	if(p2 == p3)
	{
		outgoingTangent = normalize(p3 - p1);
		if(p1 == p2)
			outgoingTangent = normalize(p3 - p0);
	}
	RI_ASSERT(!isZero(incomingTangent) && !isZero(outgoingTangent));

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

	const int segments = 256;
	Vector2 pp = p0;
	Vector2 tp = incomingTangent;
	unsigned int prevFlags = startFlags;
	for(int i=1;i<segments;i++)
	{
		RIfloat t = (RIfloat)i / (RIfloat)segments;
		RIfloat u = 1.0f-t;
		Vector2 pn = u*u*u * p0 + 3.0f*t*u*u * p1 + 3.0f*t*t*u * p2 + t*t*t * p3;
		Vector2 tn = (-1.0f + 2.0f*t - t*t) * p0 + (1.0f - 4.0f*t + 3.0f*t*t) * p1 + (2.0f*t - 3.0f*t*t) * p2 + t*t * p3;
		tn = normalize(tn);
		if(isZero(tn))
			tn = tp;

		addEdge(pp, pn, tp, tn, prevFlags, 0);	//throws bad_alloc

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	addEdge(pp, p3, tp, outgoingTangent, prevFlags, END_SEGMENT);	//throws bad_alloc
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Finds an ellipse center and transformation from the unit circle to
*			that ellipse.
* \param	rh Length of the horizontal axis
*			rv Length of the vertical axis
*			rot Rotation angle
*			p0,p1 User space end points of the arc
*			c0,c1 (Return value) Unit circle space center points of the two ellipses
*			u0,u1 (Return value) Unit circle space end points of the arc
*			unitCircleToEllipse (Return value) A matrix mapping from unit circle space to user space
* \return	true if ellipse exists, false if doesn't
* \note		
*//*-------------------------------------------------------------------*/

static bool findEllipses(RIfloat rh, RIfloat rv, RIfloat rot, const Vector2& p0, const Vector2& p1, VGPathSegment segment, Vector2& c0, Vector2& c1, Vector2& u0, Vector2& u1, Matrix3x3& unitCircleToEllipse, bool& cw)
{
	rh = RI_ABS(rh);
	rv = RI_ABS(rv);
	if(rh == 0.0f || rv == 0.0f || p0 == p1)
		return false;	//degenerate ellipse

	rot = RI_DEG_TO_RAD(rot);
	unitCircleToEllipse.set((RIfloat)cos(rot)*rh, -(RIfloat)sin(rot)*rv,  0,
							(RIfloat)sin(rot)*rh,  (RIfloat)cos(rot)*rv,  0,
							0,                   0,                   1);
	Matrix3x3 ellipseToUnitCircle = invert(unitCircleToEllipse);
	//force affinity
	ellipseToUnitCircle[2][0] = 0.0f;
	ellipseToUnitCircle[2][1] = 0.0f;
	ellipseToUnitCircle[2][2] = 1.0f;

	// Transform p0 and p1 into unit space
	u0 = affineTransform(ellipseToUnitCircle, p0);
	u1 = affineTransform(ellipseToUnitCircle, p1);

	Vector2 m = 0.5f * (u0 + u1);
	Vector2 d = u0 - u1;

	RIfloat lsq = (RIfloat)dot(d,d);
	if(lsq <= 0.0f)
		return false;	//the points are coincident

	RIfloat disc = (1.0f / lsq) - 0.25f;
	if(disc < 0.0f)
	{	//the points are too far apart for a solution to exist, scale the axes so that there is a solution
		RIfloat l = (RIfloat)sqrt(lsq);
		rh *= 0.5f * l;
		rv *= 0.5f * l;

		//redo the computation with scaled axes
		unitCircleToEllipse.set((RIfloat)cos(rot)*rh, -(RIfloat)sin(rot)*rv,  0,
								(RIfloat)sin(rot)*rh,  (RIfloat)cos(rot)*rv,  0,
								0,                   0,                   1);
		ellipseToUnitCircle = invert(unitCircleToEllipse);
		//force affinity
		ellipseToUnitCircle[2][0] = 0.0f;
		ellipseToUnitCircle[2][1] = 0.0f;
		ellipseToUnitCircle[2][2] = 1.0f;

		// Transform p0 and p1 into unit space
		u0 = affineTransform(ellipseToUnitCircle, p0);
		u1 = affineTransform(ellipseToUnitCircle, p1);

		// Solve for intersecting unit circles
		d = u0 - u1;
		m = 0.5f * (u0 + u1);

		lsq = dot(d,d);
		if(lsq <= 0.0f)
			return false;	//the points are coincident

		disc = RI_MAX(0.0f, 1.0f / lsq - 0.25f);
	}

	if(u0 == u1)
		return false;

	Vector2 sd = d * (RIfloat)sqrt(disc);
	Vector2 sp = perpendicularCW(sd);
	c0 = m + sp;
	c1 = m - sp;

	//choose the center point and direction
	Vector2 cp = c0;
	if(segment == VG_SCWARC_TO || segment == VG_LCCWARC_TO)
		cp = c1;
	cw = false;
	if(segment == VG_SCWARC_TO || segment == VG_LCWARC_TO)
		cw = true;

	//move the unit circle origin to the chosen center point
	u0 -= cp;
	u1 -= cp;

	if(u0 == u1 || isZero(u0) || isZero(u1))
		return false;

	//transform back to the original coordinate space
	cp = affineTransform(unitCircleToEllipse, cp);
	unitCircleToEllipse[0][2] = cp.x;
	unitCircleToEllipse[1][2] = cp.y;
	return true;
}

/*-------------------------------------------------------------------*//*!
* \brief	Tessellates an arc-to segment.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Path::addArcTo(const Vector2& p0, RIfloat rh, RIfloat rv, RIfloat rot, const Vector2& p1, VGPathSegment segment, bool subpathHasGeometry)
{
	if(p0 == p1)
		return false;	//discard zero-length segments

	Vector2 c0, c1, u0, u1;
	Matrix3x3 unitCircleToEllipse;
	bool cw;

	unsigned int startFlags = START_SEGMENT;
	if(!subpathHasGeometry)
		startFlags |= START_SUBPATH;

	if(!findEllipses(rh, rv, rot, p0, p1, segment, c0, c1, u0, u1, unitCircleToEllipse, cw))
	{	//ellipses don't exist, add line instead
		Vector2 t = normalize(p1 - p0);
		RI_ASSERT(!isZero(t));
		addEdge(p0, p1, t, t, startFlags, END_SEGMENT);	//throws bad_alloc
		return true;
	}

	//compute end point tangents
	Vector2 incomingTangent = perpendicular(u0, cw);
	incomingTangent = affineTangentTransform(unitCircleToEllipse, incomingTangent);
	incomingTangent = normalize(incomingTangent);
	Vector2 outgoingTangent = perpendicular(u1, cw);
	outgoingTangent = affineTangentTransform(unitCircleToEllipse, outgoingTangent);
	outgoingTangent = normalize(outgoingTangent);
	RI_ASSERT(!isZero(incomingTangent) && !isZero(outgoingTangent));

	const int segments = 256;
	Vector2 pp = p0;
	Vector2 tp = incomingTangent;
	unsigned int prevFlags = startFlags;
	for(int i=1;i<segments;i++)
	{
		RIfloat t = (RIfloat)i / (RIfloat)segments;
		Vector2 pn = circularLerp(u0, u1, t, cw);
		Vector2 tn = perpendicular(pn, cw);
		tn = affineTangentTransform(unitCircleToEllipse, tn);
		pn = affineTransform(unitCircleToEllipse, pn);
		tn = normalize(tn);
		if(isZero(tn))
			tn = tp;

		addEdge(pp, pn, tp, tn, prevFlags, 0);	//throws bad_alloc

		pp = pn;
		tp = tn;
		prevFlags = 0;
	}
	addEdge(pp, p1, tp, outgoingTangent, prevFlags, END_SEGMENT);	//throws bad_alloc
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

void Path::tessellate()
{
	if( m_vertices.size() > 0 )
		return;	//already tessellated

	m_userMinx = RI_FLOAT_MAX;
	m_userMiny = RI_FLOAT_MAX;
	m_userMaxx = -RI_FLOAT_MAX;
	m_userMaxy = -RI_FLOAT_MAX;

	try
	{
		m_segmentToVertex.resize(m_segments.size());

		int coordIndex = 0;
		Vector2 s(0,0);		//the beginning of the current subpath
		Vector2 o(0,0);		//the last point of the previous segment
		Vector2 p(0,0);		//the last internal control point of the previous segment, if the segment was a (regular or smooth) quadratic or cubic Bezier, or else the last point of the previous segment

		//tessellate the path segments
		coordIndex = 0;
		s.set(0,0);
		o.set(0,0);
		p.set(0,0);
		bool subpathHasGeometry = false;
		VGPathSegment prevSegment = VG_MOVE_TO;
		for(int i=0;i<m_segments.size();i++)
		{
			VGPathSegment segment = getPathSegment(m_segments[i]);
			VGPathAbsRel absRel = getPathAbsRel(m_segments[i]);
			int coords = segmentToNumCoordinates(segment);
			m_segmentToVertex[i].start = m_vertices.size();

			switch(segment)
			{
			case VG_CLOSE_PATH:
			{
				RI_ASSERT(coords == 0);
				addEndPath(o, s, subpathHasGeometry, CLOSE_SUBPATH);
				p = s;
				o = s;
				subpathHasGeometry = false;
				break;
			}

			case VG_MOVE_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				if(absRel == VG_RELATIVE)
					c += o;
				if(prevSegment != VG_MOVE_TO && prevSegment != VG_CLOSE_PATH)
					addEndPath(o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);
				s = c;
				p = c;
				o = c;
				subpathHasGeometry = false;
				break;
			}

			case VG_LINE_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				if(absRel == VG_RELATIVE)
					c += o;
				if(addLineTo(o, c, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c;
				o = c;
				break;
			}

			case VG_HLINE_TO:
			{
				RI_ASSERT(coords == 1);
				Vector2 c(getCoordinate(coordIndex+0), o.y);
				if(absRel == VG_RELATIVE)
					c.x += o.x;
				if(addLineTo(o, c, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c;
				o = c;
				break;
			}

			case VG_VLINE_TO:
			{
				RI_ASSERT(coords == 1);
				Vector2 c(o.x, getCoordinate(coordIndex+0));
				if(absRel == VG_RELATIVE)
					c.y += o.y;
				if(addLineTo(o, c, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c;
				o = c;
				break;
			}

			case VG_QUAD_TO:
			{
				RI_ASSERT(coords == 4);
				Vector2 c0(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				Vector2 c1(getCoordinate(coordIndex+2), getCoordinate(coordIndex+3));
				if(absRel == VG_RELATIVE)
				{
					c0 += o;
					c1 += o;
				}
				if(addQuadTo(o, c0, c1, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c0;
				o = c1;
				break;
			}

			case VG_SQUAD_TO:
			{
				RI_ASSERT(coords == 2);
				Vector2 c0 = 2.0f * o - p;
				Vector2 c1(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				if(absRel == VG_RELATIVE)
					c1 += o;
				if(addQuadTo(o, c0, c1, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c0;
				o = c1;
				break;
			}

			case VG_CUBIC_TO:
			{
				RI_ASSERT(coords == 6);
				Vector2 c0(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				Vector2 c1(getCoordinate(coordIndex+2), getCoordinate(coordIndex+3));
				Vector2 c2(getCoordinate(coordIndex+4), getCoordinate(coordIndex+5));
				if(absRel == VG_RELATIVE)
				{
					c0 += o;
					c1 += o;
					c2 += o;
				}
				if(addCubicTo(o, c0, c1, c2, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c1;
				o = c2;
				break;
			}

			case VG_SCUBIC_TO:
			{
				RI_ASSERT(coords == 4);
				Vector2 c0 = 2.0f * o - p;
				Vector2 c1(getCoordinate(coordIndex+0), getCoordinate(coordIndex+1));
				Vector2 c2(getCoordinate(coordIndex+2), getCoordinate(coordIndex+3));
				if(absRel == VG_RELATIVE)
				{
					c1 += o;
					c2 += o;
				}
				if(addCubicTo(o, c0, c1, c2, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c1;
				o = c2;
				break;
			}

			default:
			{
				RI_ASSERT(segment == VG_SCCWARC_TO || segment == VG_SCWARC_TO ||
						  segment == VG_LCCWARC_TO || segment == VG_LCWARC_TO);
				RI_ASSERT(coords == 5);
				RIfloat rh = getCoordinate(coordIndex+0);
				RIfloat rv = getCoordinate(coordIndex+1);
				RIfloat rot = getCoordinate(coordIndex+2);
				Vector2 c(getCoordinate(coordIndex+3), getCoordinate(coordIndex+4));
				if(absRel == VG_RELATIVE)
					c += o;
				if(addArcTo(o, rh, rv, rot, c, segment, subpathHasGeometry))
					subpathHasGeometry = true;
				p = c;
				o = c;
				break;
			}
			}

			if(m_vertices.size() > m_segmentToVertex[i].start)
			{	//segment produced vertices
				m_segmentToVertex[i].end = m_vertices.size() - 1;
			}
			else
			{	//segment didn't produce vertices (zero-length segment). Ignore it.
				m_segmentToVertex[i].start = m_segmentToVertex[i].end = m_vertices.size()-1;
			}
			prevSegment = segment;
			coordIndex += coords;
		}

		//add an implicit MOVE_TO to the end to close the last subpath.
		//if the subpath contained only zero-length segments, this produces the necessary geometry to get it stroked
		// and included in path bounds. The geometry won't be included in the pointAlongPath query.
		if(prevSegment != VG_MOVE_TO && prevSegment != VG_CLOSE_PATH)
			addEndPath(o, s, subpathHasGeometry, IMPLICIT_CLOSE_SUBPATH);

		//check that the flags are correct
#ifdef RI_DEBUG
		int prev = -1;
		bool subpathStarted = false;
		bool segmentStarted = false;
		for(int i=0;i<m_vertices.size();i++)
		{
			Vertex& v = m_vertices[i];

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
				RI_ASSERT(subpathStarted || ((m_vertices[prev].flags & CLOSE_SUBPATH) && (m_vertices[i].flags & CLOSE_SUBPATH)) ||
						  ((m_vertices[prev].flags & IMPLICIT_CLOSE_SUBPATH) && (m_vertices[i].flags & IMPLICIT_CLOSE_SUBPATH)));
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
	catch(std::bad_alloc)
	{
		m_vertices.clear();
		throw;
	}
}

//==============================================================================================

}		//namespace OpenVGRI

//==============================================================================================
