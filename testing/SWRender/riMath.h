#ifndef __RIMATH_H
#define __RIMATH_H

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
 * \brief	Math functions, Vector and Matrix classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#ifndef __RIDEFS_H
#include "riDefs.h"
#endif

#import <ApplicationServices/ApplicationServices.h>

#include <math.h>

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

RI_INLINE int		RI_ISNAN(float a)
{
	RIfloatInt p;
	p.f = a;
	unsigned int exponent = (p.i>>23) & 0xff;
	unsigned int mantissa = p.i & 0x7fffff;
	if(exponent == 255 && mantissa)
		return 1;
	return 0;
}

typedef float RIfloat;

#define	PI						3.141592654f

RI_INLINE RIfloat	RI_MAX(RIfloat a, RIfloat b)				{ return (a > b) ? a : b; }
RI_INLINE RIfloat	RI_MIN(RIfloat a, RIfloat b)				{ return (a < b) ? a : b; }
RI_INLINE RIfloat	RI_CLAMP(RIfloat a, RIfloat l, RIfloat h)	{ if(RI_ISNAN(a)) return l; RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }
RI_INLINE void		RI_SWAP(RIfloat &a, RIfloat &b)				{ RIfloat tmp = a; a = b; b = tmp; }
RI_INLINE RIfloat	RI_ABS(RIfloat a)							{ return (a < 0.0f) ? -a : a; }
RI_INLINE RIfloat	RI_SQR(RIfloat a)							{ return a * a; }
RI_INLINE RIfloat	RI_DEG_TO_RAD(RIfloat a)					{ return a * PI / 180.0f; }
RI_INLINE RIfloat	RI_RAD_TO_DEG(RIfloat a)					{ return a * 180.0f/ PI; }
RI_INLINE RIfloat	RI_MOD(RIfloat a, RIfloat b)				{ if(RI_ISNAN(a) || RI_ISNAN(b)) return 0.0f; RI_ASSERT(b >= 0.0f); if(b == 0.0f) return 0.0f; RIfloat f = (RIfloat)fmod(a, b); if(f < 0.0f) f += b; RI_ASSERT(f >= 0.0f && f <= b); return f; }

RI_INLINE int		RI_INT_MAX(int a, int b)			{ return (a > b) ? a : b; }
RI_INLINE int		RI_INT_MIN(int a, int b)			{ return (a < b) ? a : b; }
RI_INLINE void		RI_INT_SWAP(int &a, int &b)			{ int tmp = a; a = b; b = tmp; }
RI_INLINE int		RI_INT_MOD(int a, int b)			{ RI_ASSERT(b >= 0); if(!b) return 0; int i = a % b; if(i < 0) i += b; RI_ASSERT(i >= 0 && i < b); return i; }
RI_INLINE int		RI_INT_ADDSATURATE(int a, int b)	{ RI_ASSERT(b >= 0); int r = a + b; return (r >= a) ? r : RI_INT32_MAX; }

class Matrix3x3;
class Vector2;
class Vector3;

//==============================================================================================

//MatrixRxC, R = number of rows, C = number of columns
//indexing: matrix[row][column]
//Matrix3x3 inline functions cannot be inside the class because Vector3 is not defined yet when Matrix3x3 is defined

class Matrix3x3
{
public:
	RI_INLINE					Matrix3x3		();						//initialized to identity
	RI_INLINE					Matrix3x3		( const Matrix3x3& m );
	RI_INLINE					Matrix3x3		( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 );
    RI_INLINE                   Matrix3x3       (CGAffineTransform transform);
	RI_INLINE					~Matrix3x3		();
	RI_INLINE Matrix3x3&		operator=		( const Matrix3x3& m );
	RI_INLINE Vector3&			operator[]		( int i );				//returns a row vector
	RI_INLINE const Vector3&	operator[]		( int i ) const;
	RI_INLINE void				set				( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 );
	RI_INLINE const Vector3		getRow			( int i ) const;
	RI_INLINE const Vector3		getColumn		( int i ) const;
	RI_INLINE void				setRow			( int i, const Vector3& v );
	RI_INLINE void				setColumn		( int i, const Vector3& v );
	RI_INLINE void				operator*=		( const Matrix3x3& m );
	RI_INLINE void				operator*=		( RIfloat f );
	RI_INLINE void				operator+=		( const Matrix3x3& m );
	RI_INLINE void				operator-=		( const Matrix3x3& m );
	RI_INLINE const Matrix3x3	operator-		() const;
	RI_INLINE void				identity		();
	RI_INLINE void				transpose		();
	bool						invert			();	//if the matrix is singular, returns false and leaves it unmodified
	RI_INLINE RIfloat				det				() const;
	RI_INLINE bool				isAffine		() const;

private:
	RIfloat						matrix[3][3];
};

//==============================================================================================

class Vector2
{
public:
	RI_INLINE					Vector2			() : x(0.0f), y(0.0f)					{}
	RI_INLINE					Vector2			( const Vector2& v ) : x(v.x), y(v.y)	{}
	RI_INLINE					Vector2			( RIfloat fx, RIfloat fy ) : x(fx), y(fy)	{}
	RI_INLINE					~Vector2		()								{}
	RI_INLINE void				operator+=		( const Vector2& v )			{ x += v.x; y += v.y; }
	RI_INLINE const Vector2		operator-		() const						{ return Vector2(-x,-y); }
	RI_INLINE void				set				( RIfloat fx, RIfloat fy )			{ x = fx; y = fy; }
	RI_INLINE RIfloat			length			() const						{ return (RIfloat)sqrt((double)x*(double)x+(double)y*(double)y); }
	RI_INLINE bool				normalize		()								{ double l = (double)x*(double)x+(double)y*(double)y; if( l == 0.0 ) return false; l = 1.0 / sqrt(l); x = (RIfloat)((double)x * l); y = (RIfloat)((double)y * l); return true; }
	RI_INLINE void				operator*=		( RIfloat f )						{ x *= f; y *= f; }
	RI_INLINE void				operator-=		( const Vector2& v )			{ x -= v.x; y -= v.y; }

	RIfloat						x,y;
};

//==============================================================================================

class Vector3
{
public:
	RI_INLINE					Vector3			() : x(0.0f), y(0.0f), z(0.0f)							{}
	RI_INLINE					Vector3			( const Vector3& v ) : x(v.x), y(v.y), z(v.z)			{}
	RI_INLINE					Vector3			( RIfloat fx, RIfloat fy, RIfloat fz ) : x(fx), y(fy), z(fz)	{}
	RI_INLINE					~Vector3		()								{}
	RI_INLINE const RIfloat&	operator[]		( int i ) const					{ RI_ASSERT(i>=0&&i<3); return (&x)[i]; }
	RI_INLINE RIfloat&			operator[]		( int i )						{ RI_ASSERT(i>=0&&i<3); return (&x)[i]; }
	RI_INLINE void				set				( RIfloat fx, RIfloat fy, RIfloat fz ){ x = fx; y = fy; z = fz; }
	RI_INLINE void				operator*=		( RIfloat f )						{ x *= f; y *= f; z *= f; }
#if 0
unused
	RI_INLINE Vector3&			operator=		( const Vector3& v )			{ x = v.x; y = v.y; z = v.z; return *this; }
	RI_INLINE void				operator+=		( const Vector3& v )			{ x += v.x; y += v.y; z += v.z; }
	RI_INLINE void				operator-=		( const Vector3& v )			{ x -= v.x; y -= v.y; z -= v.z; }
	RI_INLINE const Vector3		operator-		() const						{ return Vector3(-x,-y,-z); }
	//if the vector is zero, returns false and leaves it unmodified
	RI_INLINE bool				normalize		()								{ double l = (double)x*(double)x+(double)y*(double)y+(double)z*(double)z; if( l == 0.0 ) return false; l = 1.0 / sqrt(l); x = (RIfloat)((double)x * l); y = (RIfloat)((double)y * l); z = (RIfloat)((double)z * l); return true; }
	RI_INLINE RIfloat			length			() const						{ return (RIfloat)sqrt((double)x*(double)x+(double)y*(double)y+(double)z*(double)z); }
	RI_INLINE void				scale			( const Vector3& v )			{ x *= v.x; y *= v.y; z *= v.z; }	//component-wise scale
	RI_INLINE void				negate			()								{ x = -x; y = -y; z = -z; }
#endif

	RIfloat						x,y,z;
};

//==============================================================================================

//Vector2 global functions
RI_INLINE bool			operator==	( const Vector2& v1, const Vector2& v2 )	{ return (v1.x == v2.x) && (v1.y == v2.y); }
RI_INLINE bool			operator!=	( const Vector2& v1, const Vector2& v2 )	{ return (v1.x != v2.x) || (v1.y != v2.y); }
RI_INLINE bool			isEqual		( const Vector2& v1, const Vector2& v2, RIfloat epsilon )	{ return RI_SQR(v2.x-v1.x) + RI_SQR(v2.y-v1.y) <= epsilon*epsilon; }
RI_INLINE bool			isZero		( const Vector2& v )						{ return (v.x == 0.0f) && (v.y == 0.0f); }
RI_INLINE const Vector2	operator*	( RIfloat f, const Vector2& v )				{ return Vector2(v.x*f,v.y*f); }
RI_INLINE const Vector2	operator*	( const Vector2& v, RIfloat f )				{ return Vector2(v.x*f,v.y*f); }
RI_INLINE const Vector2	operator+	( const Vector2& v1, const Vector2& v2 )	{ return Vector2(v1.x+v2.x, v1.y+v2.y); }
RI_INLINE const Vector2	operator-	( const Vector2& v1, const Vector2& v2 )	{ return Vector2(v1.x-v2.x, v1.y-v2.y); }
RI_INLINE RIfloat		dot			( const Vector2& v1, const Vector2& v2 )	{ return v1.x*v2.x+v1.y*v2.y; }
//if v is a zero vector, returns a zero vector
RI_INLINE const Vector2	normalize	( const Vector2& v )						{ double l = (double)v.x*(double)v.x+(double)v.y*(double)v.y; if( l != 0.0 ) l = 1.0 / sqrt(l); return Vector2((RIfloat)((double)v.x * l), (RIfloat)((double)v.y * l)); }
//if onThis is a zero vector, returns a zero vector
RI_INLINE const Vector2	project		( const Vector2& v, const Vector2& onThis ) { RIfloat l = dot(onThis,onThis); if( l != 0.0f ) l = dot(v, onThis)/l; return onThis * l; }
RI_INLINE const Vector2	lerp		( const Vector2& v1, const Vector2& v2, RIfloat ratio )	{ return v1 + ratio * (v2 - v1); }
RI_INLINE const Vector2	scale		( const Vector2& v1, const Vector2& v2 )	{ return Vector2(v1.x*v2.x, v1.y*v2.y); }
//matrix * column vector. The input vector2 is implicitly expanded to (x,y,1)
RI_INLINE const Vector2 affineTransform( const Matrix3x3& m, const Vector2& v )	{ RI_ASSERT(m.isAffine()); return Vector2(v.x * m[0][0] + v.y * m[0][1] + m[0][2], v.x * m[1][0] + v.y * m[1][1] + m[1][2]); }
//matrix * column vector. The input vector2 is implicitly expanded to (x,y,0)
RI_INLINE const Vector2 affineTangentTransform(const Matrix3x3& m, const Vector2& v)	{ RI_ASSERT(m.isAffine()); return Vector2(v.x * m[0][0] + v.y * m[0][1], v.x * m[1][0] + v.y * m[1][1]); }
RI_INLINE const Vector2 perpendicularCW(const Vector2& v)						{ return Vector2(v.y, -v.x); }
RI_INLINE const Vector2 perpendicularCCW(const Vector2& v)						{ return Vector2(-v.y, v.x); }
RI_INLINE const Vector2 perpendicular(const Vector2& v, bool cw)				{ if(cw) return Vector2(v.y, -v.x); return Vector2(-v.y, v.x); }

//==============================================================================================

//Vector3 global functions
RI_INLINE bool			operator==	( const Vector3& v1, const Vector3& v2 )	{ return (v1.x == v2.x) && (v1.y == v2.y) && (v1.z == v2.z); }
RI_INLINE bool			operator!=	( const Vector3& v1, const Vector3& v2 )	{ return (v1.x != v2.x) || (v1.y != v2.y) || (v1.z != v2.z); }
RI_INLINE bool			isEqual		( const Vector3& v1, const Vector3& v2, RIfloat epsilon )	{ return RI_SQR(v2.x-v1.x) + RI_SQR(v2.y-v1.y) + RI_SQR(v2.z-v1.z) <= epsilon*epsilon; }
RI_INLINE const Vector3	operator*	( RIfloat f, const Vector3& v )				{ return Vector3(v.x*f,v.y*f,v.z*f); }
RI_INLINE const Vector3	operator*	( const Vector3& v, RIfloat f )				{ return Vector3(v.x*f,v.y*f,v.z*f); }
RI_INLINE const Vector3	operator+	( const Vector3& v1, const Vector3& v2 )	{ return Vector3(v1.x+v2.x, v1.y+v2.y, v1.z+v2.z); }
RI_INLINE const Vector3	operator-	( const Vector3& v1, const Vector3& v2 )	{ return Vector3(v1.x-v2.x, v1.y-v2.y, v1.z-v2.z); }
RI_INLINE RIfloat		dot			( const Vector3& v1, const Vector3& v2 )	{ return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z; }
RI_INLINE const Vector3	cross		( const Vector3& v1, const Vector3& v2 )	{ return Vector3( v1.y*v2.z-v1.z*v2.y, v1.z*v2.x-v1.x*v2.z, v1.x*v2.y-v1.y*v2.x ); }
//if v is a zero vector, returns a zero vector
RI_INLINE const Vector3	normalize	( const Vector3& v )						{ double l = (double)v.x*(double)v.x+(double)v.y*(double)v.y+(double)v.z*(double)v.z; if( l != 0.0 ) l = 1.0 / sqrt(l); return Vector3((RIfloat)((double)v.x * l), (RIfloat)((double)v.y * l), (RIfloat)((double)v.z * l)); }
RI_INLINE const Vector3	lerp		( const Vector3& v1, const Vector3& v2, RIfloat ratio )	{ return v1 + ratio * (v2 - v1); }
RI_INLINE const Vector3	scale		( const Vector3& v1, const Vector3& v2 )	{ return Vector3(v1.x*v2.x, v1.y*v2.y, v1.z*v2.z); }

//==============================================================================================

//matrix * column vector
RI_INLINE const Vector3	operator*	( const Matrix3x3& m, const Vector3& v)		{ return Vector3( v.x*m[0][0]+v.y*m[0][1]+v.z*m[0][2], v.x*m[1][0]+v.y*m[1][1]+v.z*m[1][2], v.x*m[2][0]+v.y*m[2][1]+v.z*m[2][2] ); }

//==============================================================================================

//Matrix3x3 global functions
RI_INLINE bool				operator==	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) if( m1[i][j] != m2[i][j] ) return false; return true; }
RI_INLINE bool				operator!=	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ return !(m1 == m2); }
RI_INLINE const Matrix3x3	operator*	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t; for(int i=0;i<3;i++) for(int j=0;j<3;j++) t[i][j] = m1[i][0] * m2[0][j] + m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j]; return t; }
RI_INLINE const Matrix3x3	operator*	( RIfloat f, const Matrix3x3& m )					{ Matrix3x3 t(m); t *= f; return t; }
RI_INLINE const Matrix3x3	operator*	( const Matrix3x3& m, RIfloat f )					{ Matrix3x3 t(m); t *= f; return t; }
RI_INLINE const Matrix3x3	operator+	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t(m1); t += m2; return t; }
RI_INLINE const Matrix3x3	operator-	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t(m1); t -= m2; return t; }
RI_INLINE const Matrix3x3	transpose	( const Matrix3x3& m )							{ Matrix3x3 t(m); t.transpose(); return t; }
// if the matrix is singular, returns it unmodified
RI_INLINE const Matrix3x3	invert		( const Matrix3x3& m )							{ Matrix3x3 t(m); t.invert(); return t; }

//==============================================================================================

//Matrix3x3 inline functions (cannot be inside the class because Vector3 is not defined yet when Matrix3x3 is defined)
RI_INLINE					Matrix3x3::Matrix3x3	()									{ identity(); }
RI_INLINE					Matrix3x3::Matrix3x3	( const Matrix3x3& m )				{ *this = m; }
RI_INLINE					Matrix3x3::Matrix3x3	( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 )	{ set(m00,m01,m02,m10,m11,m12,m20,m21,m22); }
RI_INLINE                   Matrix3x3::Matrix3x3       (CGAffineTransform transform) {
   matrix[0][0]=transform.a;
   matrix[0][1]=transform.c;
   matrix[0][2]=transform.tx;
   matrix[1][0]=transform.b;
   matrix[1][1]=transform.d;
   matrix[1][2]=transform.ty;
   matrix[2][0]=0;
   matrix[2][1]=0;
   matrix[2][2]=1;
}

RI_INLINE					Matrix3x3::~Matrix3x3	()									{}
RI_INLINE Matrix3x3&		Matrix3x3::operator=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] = m.matrix[i][j]; return *this; }
RI_INLINE Vector3&			Matrix3x3::operator[]	( int i )							{ RI_ASSERT(i>=0&&i<3); return (Vector3&)matrix[i][0]; }
RI_INLINE const Vector3&	Matrix3x3::operator[]	( int i ) const						{ RI_ASSERT(i>=0&&i<3); return (const Vector3&)matrix[i][0]; }
RI_INLINE void				Matrix3x3::set			( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 ) { matrix[0][0] = m00; matrix[0][1] = m01; matrix[0][2] = m02; matrix[1][0] = m10; matrix[1][1] = m11; matrix[1][2] = m12; matrix[2][0] = m20; matrix[2][1] = m21; matrix[2][2] = m22; }
RI_INLINE const Vector3		Matrix3x3::getRow		( int i ) const						{ RI_ASSERT(i>=0&&i<3); return Vector3(matrix[i][0], matrix[i][1], matrix[i][2]); }
RI_INLINE const Vector3		Matrix3x3::getColumn	( int i ) const						{ RI_ASSERT(i>=0&&i<3); return Vector3(matrix[0][i], matrix[1][i], matrix[2][i]); }
RI_INLINE void				Matrix3x3::setRow		( int i, const Vector3& v )			{ RI_ASSERT(i>=0&&i<3); matrix[i][0] = v.x; matrix[i][1] = v.y; matrix[i][2] = v.z; }
RI_INLINE void				Matrix3x3::setColumn	( int i, const Vector3& v )			{ RI_ASSERT(i>=0&&i<3); matrix[0][i] = v.x; matrix[1][i] = v.y; matrix[2][i] = v.z; }
RI_INLINE void				Matrix3x3::operator*=	( const Matrix3x3& m )				{ *this = *this * m; }
RI_INLINE void				Matrix3x3::operator*=	( RIfloat f )							{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] *= f; }
RI_INLINE void				Matrix3x3::operator+=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] += m.matrix[i][j]; }
RI_INLINE void				Matrix3x3::operator-=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] -= m.matrix[i][j]; }
RI_INLINE const Matrix3x3	Matrix3x3::operator-	() const							{ return Matrix3x3( -matrix[0][0],-matrix[0][1],-matrix[0][2], -matrix[1][0],-matrix[1][1],-matrix[1][2], -matrix[2][0],-matrix[2][1],-matrix[2][2]); }
RI_INLINE void				Matrix3x3::identity		()									{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] = (i == j) ? 1.0f : 0.0f; }
RI_INLINE void				Matrix3x3::transpose	()									{ RI_SWAP(matrix[1][0], matrix[0][1]); RI_SWAP(matrix[2][0], matrix[0][2]); RI_SWAP(matrix[2][1], matrix[1][2]); }
RI_INLINE RIfloat			Matrix3x3::det			() const							{ return matrix[0][0] * (matrix[1][1]*matrix[2][2] - matrix[2][1]*matrix[1][2]) + matrix[0][1] * (matrix[2][0]*matrix[1][2] - matrix[1][0]*matrix[2][2]) + matrix[0][2] * (matrix[1][0]*matrix[2][1] - matrix[2][0]*matrix[1][1]); }
RI_INLINE bool				Matrix3x3::isAffine		() const							{ if(matrix[2][0] == 0.0f && matrix[2][1] == 0.0f && matrix[2][2] == 1.0f) return true; return false; }

//==============================================================================================

}	//namespace OpenVGRI

#endif /* __RIMATH_H */
