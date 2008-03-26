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
 * \brief	Implementation of KGPaint and pixel pipe functionality.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "KGPixelPipe.h"

KGPaint *KGPaintAlloc() {
   return (KGPaint *)NSZoneCalloc(NULL,1,sizeof(KGPaint));
}

KGPaint *KGPaintInit(KGPaint *self) {
	self->m_paintType=VG_PAINT_TYPE_COLOR;
	self->m_paintColor=VGColorRGBA(0,0,0,1,VGColor_sRGBA_PRE);
	self->m_inputPaintColor=VGColorRGBA(0,0,0,1,VGColor_sRGBA);
	self->m_colorRampSpreadMode=VG_COLOR_RAMP_SPREAD_PAD;
    self->m_colorRampStopsCount=2;
    self->m_colorRampStopsCapacity=2;
	self->m_colorRampStops=(GradientStop *)NSZoneCalloc(NULL,self->m_colorRampStopsCapacity,sizeof(GradientStop));
	self->m_colorRampPremultiplied=YES;
	self->m_linearGradientPoint0=Vector2Make(0,0);
	self->m_linearGradientPoint1=Vector2Make(1,0);
	self->m_radialGradientCenter=Vector2Make(0,0);
	self->m_radialGradientFocalPoint=Vector2Make(0,0);
	self->m_radialGradientRadius=1.0f;
	self->m_patternTilingMode=VG_TILE_FILL;
	self->m_pattern=NULL;

	GradientStop gs;
	gs.offset = 0.0f;
	gs.color=VGColorRGBA(0,0,0,1,VGColor_sRGBA);
	self->m_colorRampStops[0]=gs;
    
	gs.offset = 1.0f;
	gs.color=VGColorRGBA(1,1,1,1,VGColor_sRGBA);
	self->m_colorRampStops[1]=gs;	//throws bad_alloc
    return self;
}

void     KGPaintDealloc(KGPaint *self) {
	if(self->m_pattern)
	{
			delete self->m_pattern;
	}
}

KGPixelPipe *KGPixelPipeAlloc() {
   return (KGPixelPipe *)NSZoneCalloc(NULL,1,sizeof(KGPixelPipe));
}

KGPixelPipe *KGPixelPipeInit(KGPixelPipe *self) {
	self->m_renderingSurface=NULL;
	self->m_mask=NULL;
	self->m_image=NULL;
	self->m_paint=NULL;
	self->m_defaultPaint=KGPaintInit(KGPaintAlloc());
	self->m_blendMode=kCGBlendModeNormal;
	self->m_imageMode=VG_DRAW_IMAGE_NORMAL;
	self->m_imageQuality=kCGInterpolationLow;
	self->m_tileFillColor=VGColorRGBA(0,0,0,0,VGColor_sRGBA);
	self->m_surfaceToPaintMatrix=Matrix3x3Identity();
	self->m_surfaceToImageMatrix=Matrix3x3Identity();
    return self;
}

void KGPixelPipeDealloc(KGPixelPipe *self) {
   NSZoneFree(NULL,self);
}

void KGPixelPipeSetRenderingSurface(KGPixelPipe *self,VGImage *renderingSurface) {
	RI_ASSERT(renderingSurface);
	self->m_renderingSurface = renderingSurface;
}

void KGPixelPipeSetBlendMode(KGPixelPipe *self,CGBlendMode blendMode) {
	RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
	self->m_blendMode = blendMode;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the mask image. NULL disables masking.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetMask(KGPixelPipe *self,VGImage* mask) {
	self->m_mask = mask;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the image to be drawn. NULL disables image drawing.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetImage(KGPixelPipe *self,VGImage* image, VGImageMode imageMode) {
	RI_ASSERT(imageMode == VG_DRAW_IMAGE_NORMAL || imageMode == VG_DRAW_IMAGE_MULTIPLY || imageMode == VG_DRAW_IMAGE_STENCIL);
	self->m_image = image;
	self->m_imageMode = imageMode;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the surface-to-paint matrix.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetSurfaceToPaintMatrix(KGPixelPipe *self,Matrix3x3 surfaceToPaintMatrix) {
	self->m_surfaceToPaintMatrix = surfaceToPaintMatrix;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets the surface-to-image matrix.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetSurfaceToImageMatrix(KGPixelPipe *self,Matrix3x3 surfaceToImageMatrix) {
	self->m_surfaceToImageMatrix = surfaceToImageMatrix;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets image quality.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetImageQuality(KGPixelPipe *self,CGInterpolationQuality imageQuality) {
	RI_ASSERT(imageQuality == kCGInterpolationNone || imageQuality == kCGInterpolationLow || imageQuality == kCGInterpolationHigh);
	self->m_imageQuality = imageQuality;
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets fill color for VG_TILE_FILL tiling mode (pattern only).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetTileFillColor(KGPixelPipe *self,VGColor c) {
	self->m_tileFillColor = c;
	self->m_tileFillColor=VGColorClamp(self->m_tileFillColor);
}

/*-------------------------------------------------------------------*//*!
* \brief	Sets paint.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeSetPaint(KGPixelPipe *self, KGPaint* paint) {
	self->m_paint = paint;
	if(!self->m_paint)
		self->m_paint = self->m_defaultPaint;
	if(self->m_paint->m_pattern)
		self->m_tileFillColor=VGColorConvert(self->m_tileFillColor,VGImageColorDescriptor(self->m_paint->m_pattern).internalFormat);
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the linear gradient function at (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeLinearGradient(KGPixelPipe *self,RIfloat& g, RIfloat& rho, RIfloat x, RIfloat y) {
	RI_ASSERT(self->m_paint);
	Vector2 u = self->m_paint->m_linearGradientPoint1 - self->m_paint->m_linearGradientPoint0;
	RIfloat usq = Vector2Dot(u,u);
	if( usq <= 0.0f )
	{	//points are equal, gradient is always 1.0f
		g = 1.0f;
		rho = 0.0f;
		return;
	}
	RIfloat oou = 1.0f / usq;

	Vector2 p=Vector2Make(x, y);
	p = Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p);
	p = p-self->m_paint->m_linearGradientPoint0;
	RI_ASSERT(usq >= 0.0f);
	g = Vector2Dot(p, u) * oou;
	RIfloat dgdx = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][0] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][0];
	RIfloat dgdy = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][1] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][1];
	rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	RI_ASSERT(rho >= 0.0f);
}

/*-------------------------------------------------------------------*//*!
* \brief	Computes the radial gradient function at (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGPixelPipeRadialGradient(KGPixelPipe *self,RIfloat &g, RIfloat &rho, RIfloat x, RIfloat y) {
	RI_ASSERT(self->m_paint);
	if( self->m_paint->m_radialGradientRadius <= 0.0f )
	{
		g = 1.0f;
		rho = 0.0f;
		return;
	}

	RIfloat r = self->m_paint->m_radialGradientRadius;
	Vector2 c = self->m_paint->m_radialGradientCenter;
	Vector2 f = self->m_paint->m_radialGradientFocalPoint;
	Vector2 gx=Vector2Make(self->m_surfaceToPaintMatrix.matrix[0][0], self->m_surfaceToPaintMatrix.matrix[1][0]);
	Vector2 gy=Vector2Make(self->m_surfaceToPaintMatrix.matrix[0][1],self->m_surfaceToPaintMatrix.matrix[1][1]);

	Vector2 fp = f - c;

	//clamp the focal point inside the gradient circle
	RIfloat fpLen = Vector2Length(fp);
	if( fpLen > 0.999f * r )
		fp = fp * (0.999f * r / fpLen);

	RIfloat D = -1.0f / (Vector2Dot(fp,fp) - r*r);
	Vector2 p=Vector2Make(x, y);
	p = Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p) - c;
	Vector2 d = p - fp;
	RIfloat s = (RIfloat)sqrt(r*r*Vector2Dot(d,d) - RI_SQR(p.x*fp.y - p.y*fp.x));
	g = (Vector2Dot(fp,d) + s) * D;
	if(RI_ISNAN(g))
		g = 0.0f;
	RIfloat dgdx = D*Vector2Dot(fp,gx) + (r*r*Vector2Dot(d,gx) - (gx.x*fp.y - gx.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	RIfloat dgdy = D*Vector2Dot(fp,gy) + (r*r*Vector2Dot(d,gy) - (gy.x*fp.y - gy.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	if(RI_ISNAN(rho))
		rho = 0.0f;
	RI_ASSERT(rho >= 0.0f);
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns the average color within an offset range in the color ramp.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColor readStopColor(GradientStop *colorRampStops,int colorRampStopsCount, int i, BOOL colorRampPremultiplied)
{
	RI_ASSERT(i >= 0 && i < colorRampStopsCount);
	VGColor c = colorRampStops[i].color;
	RI_ASSERT(c.m_format == VGColor_sRGBA);
	if(colorRampPremultiplied)
		c=VGColorPremultiply(c);

	return c;
}

VGColor KGPixelPipeIntegrateColorRamp(KGPixelPipe *self,RIfloat gmin, RIfloat gmax) {
	RI_ASSERT(gmin <= gmax);
	RI_ASSERT(gmin >= 0.0f && gmin <= 1.0f);
	RI_ASSERT(gmax >= 0.0f && gmax <= 1.0f);
	RI_ASSERT(self->m_paint->m_colorRampStopsCount >= 2);	//there are at least two stops

	VGColor c=VGColorRGBA(0,0,0,0,self->m_paint->m_colorRampPremultiplied ? VGColor_sRGBA_PRE : VGColor_sRGBA);
	if(gmin == 1.0f || gmax == 0.0f)
		return c;

	int i=0;
	for(;i<self->m_paint->m_colorRampStopsCount-1;i++)
	{
		if(gmin >= self->m_paint->m_colorRampStops[i].offset && gmin < self->m_paint->m_colorRampStops[i+1].offset)
		{
			RIfloat s = self->m_paint->m_colorRampStops[i].offset;
			RIfloat e = self->m_paint->m_colorRampStops[i+1].offset;
			RI_ASSERT(s < e);
			RIfloat g = (gmin - s) / (e - s);

			VGColor sc = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i, self->m_paint->m_colorRampPremultiplied);
			VGColor ec = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i+1, self->m_paint->m_colorRampPremultiplied);
			VGColor rc = VGColorAdd(VGColorMultiplyByFloat(sc, (1.0f-g)),VGColorMultiplyByFloat(ec , g));

			//subtract the average color from the start of the stop to gmin
			c=VGColorSubtract(c,VGColorMultiplyByFloat(VGColorAdd(sc,rc) , 0.5f*(gmin - s)));
			break;
		}
	}

	for(;i<self->m_paint->m_colorRampStopsCount-1;i++)
	{
		RIfloat s = self->m_paint->m_colorRampStops[i].offset;
		RIfloat e = self->m_paint->m_colorRampStops[i+1].offset;
		RI_ASSERT(s <= e);

		VGColor sc = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i, self->m_paint->m_colorRampPremultiplied);
		VGColor ec = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i+1, self->m_paint->m_colorRampPremultiplied);

		//average of the stop
		c=VGColorAdd(c , VGColorMultiplyByFloat(VGColorAdd(sc , ec), 0.5f*(e-s)));

		if(gmax >= self->m_paint->m_colorRampStops[i].offset && gmax < self->m_paint->m_colorRampStops[i+1].offset)
		{
			RIfloat g = (gmax - s) / (e - s);
			VGColor rc = VGColorAdd(VGColorMultiplyByFloat(sc , (1.0f-g)),VGColorMultiplyByFloat( ec , g));

			//subtract the average color from gmax to the end of the stop
			c=VGColorSubtract(c,VGColorMultiplyByFloat(VGColorAdd(rc , ec) , 0.5f*(e - gmax)));
			break;
		}
	}
	return c;
}

/*-------------------------------------------------------------------*//*!
* \brief	Maps a gradient function value to a color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor KGPixelPipeColorRamp(KGPixelPipe *self,RIfloat gradient, RIfloat rho) 
{
	RI_ASSERT(self->m_paint);
	RI_ASSERT(rho >= 0.0f);

	VGColor c=VGColorRGBA(0,0,0,0,self->m_paint->m_colorRampPremultiplied ? VGColor_sRGBA_PRE : VGColor_sRGBA);
	VGColor avg=VGColorZero();

	if(rho == 0.0f)
	{	//filter size is zero or gradient is degenerate
		switch(self->m_paint->m_colorRampSpreadMode)
		{
		case VG_COLOR_RAMP_SPREAD_PAD:
			gradient = RI_CLAMP(gradient, 0.0f, 1.0f);
			break;
		case VG_COLOR_RAMP_SPREAD_REFLECT:
		{
			RIfloat g = RI_MOD(gradient, 2.0f);
			gradient = (g < 1.0f) ? g : 2.0f - g;
			break;
		}
		default:
			RI_ASSERT(self->m_paint->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
			gradient = gradient - (RIfloat)floor(gradient);
			break;
		}
		RI_ASSERT(gradient >= 0.0f && gradient <= 1.0f);

		for(int i=0;i<self->m_paint->m_colorRampStopsCount-1;i++)
		{
			if(gradient >= self->m_paint->m_colorRampStops[i].offset && gradient < self->m_paint->m_colorRampStops[i+1].offset)
			{
				RIfloat s = self->m_paint->m_colorRampStops[i].offset;
				RIfloat e = self->m_paint->m_colorRampStops[i+1].offset;
				RI_ASSERT(s < e);
				RIfloat g = RI_CLAMP((gradient - s) / (e - s), 0.0f, 1.0f);	//clamp needed due to numerical inaccuracies

				VGColor sc = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i, self->m_paint->m_colorRampPremultiplied);
				VGColor ec = readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, i+1, self->m_paint->m_colorRampPremultiplied);
				return VGColorAdd(VGColorMultiplyByFloat(sc , (1.0f-g)) , VGColorMultiplyByFloat(ec , g));	//return interpolated value
			}
		}
		return readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, self->m_paint->m_colorRampStopsCount-1, self->m_paint->m_colorRampPremultiplied);
	}

	RIfloat gmin = gradient - rho*0.5f;			//filter starting from the gradient point (if starts earlier, radial gradient center will be an average of the first and the last stop, which doesn't look good)
	RIfloat gmax = gradient + rho*0.5f;

	switch(self->m_paint->m_colorRampSpreadMode)
	{
	case VG_COLOR_RAMP_SPREAD_PAD:
	{
		if(gmin < 0.0f)
			c=VGColorAdd(c,VGColorMultiplyByFloat(readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, 0, self->m_paint->m_colorRampPremultiplied), (RI_MIN(gmax, 0.0f) - gmin)));
		if(gmax > 1.0f)
			c=VGColorAdd(c,VGColorMultiplyByFloat(readStopColor(self->m_paint->m_colorRampStops,self->m_paint->m_colorRampStopsCount, self->m_paint->m_colorRampStopsCount-1, self->m_paint->m_colorRampPremultiplied) , (gmax - RI_MAX(gmin, 1.0f))));
		gmin = RI_CLAMP(gmin, 0.0f, 1.0f);
		gmax = RI_CLAMP(gmax, 0.0f, 1.0f);
		c=VGColorAdd(c, KGPixelPipeIntegrateColorRamp(self,gmin, gmax));
		c=VGColorMultiplyByFloat(c , 1.0f/rho);
		c=VGColorClamp(c);	//clamp needed due to numerical inaccuracies
		return c;
	}

	case VG_COLOR_RAMP_SPREAD_REFLECT:
	{
		avg = KGPixelPipeIntegrateColorRamp(self,0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = VGColorMultiplyByFloat(avg , (gmaxi + 1.0f - gmini));		//full ramps

		//subtract beginning
		if(((int)gmini) & 1)
			c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,RI_CLAMP(1.0f - (gmin - gmini), 0.0f, 1.0f), 1.0f));
		else
			c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f)));

		//subtract end
		if(((int)gmaxi) & 1)
			c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,0.0f, RI_CLAMP(1.0f - (gmax - gmaxi), 0.0f, 1.0f)));
		else
			c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f));
		break;
	}

	default:
	{
		RI_ASSERT(self->m_paint->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
		avg = KGPixelPipeIntegrateColorRamp(self,0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = VGColorMultiplyByFloat(avg , (gmaxi + 1.0f - gmini));		//full ramps
		c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f)));	//subtract beginning
		c=VGColorSubtract(c,KGPixelPipeIntegrateColorRamp(self,RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f));	//subtract end
		break;
	}
	}

	//divide color by the length of the range
	c=VGColorMultiplyByFloat(c, 1.0f / rho);
	c=VGColorClamp(c); //clamp needed due to numerical inaccuracies

	//hide aliasing by fading to the average color
	const RIfloat fadeStart = 0.5f;
	const RIfloat fadeMultiplier = 2.0f;	//the larger, the earlier fade to average is done

	if(rho < fadeStart)
		return c;

	RIfloat ratio = RI_MIN((rho - fadeStart) * fadeMultiplier, 1.0f);
	return VGColorAdd(VGColorMultiplyByFloat(avg , ratio) , VGColorMultiplyByFloat(c , (1.0f - ratio)));
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies paint, image drawing, masking and blending at pixel (x,y).
* \param	
* \return	
* \note		premultiplied blending formulas
			//src
			a = asrc
			r = rsrc
			//src over
			a = asrc + adst * (1-asrc)
			r = rsrc + rdst * (1-asrc)
			//dst over
			a = asrc * (1-adst) + adst
			r = rsrc * (1-adst) + adst
			//src in
			a = asrc * adst
			r = rsrc * adst
			//dst in
			a = adst * asrc
			r = rdst * asrc
			//multiply
			a = asrc + adst * (1-asrc)
			r = rsrc * (1-adst) + rdst * (1-asrc) + rsrc * rdst
			//screen
			a = asrc + adst * (1-asrc)
			r = rsrc + rdst - rsrc * rdst
			//darken
			a = asrc + adst * (1-asrc)
			r = MIN(rsrc + rdst * (1-asrc), rdst + rsrc * (1-adst))
			//lighten
			a = asrc + adst * (1-asrc)
			r = MAX(rsrc + rdst * (1-asrc), rdst + rsrc * (1-adst))
			//additive
			a = MIN(asrc+adst,1)
			r = rsrc + rdst
*//*-------------------------------------------------------------------*/

void KGPixelPipeWriteCoverage(KGPixelPipe *self,int x, int y, RIfloat coverage) 
{
	RI_ASSERT(self->m_renderingSurface);

	//apply masking
	RIfloat cov = coverage;
	if(self->m_mask)
		cov *= VGImageReadMaskPixel(self->m_mask,x, y);
	if(cov == 0.0f)
		return;

	//evaluate paint
	VGColor s=VGColorZero();
	RI_ASSERT(self->m_paint);
	switch(self->m_paint->m_paintType)
	{
	case VG_PAINT_TYPE_COLOR:
		s = self->m_paint->m_paintColor;
		break;

	case VG_PAINT_TYPE_LINEAR_GRADIENT:
	{
		RIfloat g, rho;
		KGPixelPipeLinearGradient(self,g, rho, x+0.5f, y+0.5f);
		s = KGPixelPipeColorRamp(self,g, rho);
		RI_ASSERT((s.m_format == VGColor_sRGBA && !self->m_paint->m_colorRampPremultiplied) || (s.m_format == VGColor_sRGBA_PRE && self->m_paint->m_colorRampPremultiplied));
		s=VGColorPremultiply(s);
		break;
	}

	case VG_PAINT_TYPE_RADIAL_GRADIENT:
	{
		RIfloat g, rho;
		KGPixelPipeRadialGradient(self,g, rho, x+0.5f, y+0.5f);
		s = KGPixelPipeColorRamp(self,g, rho);
		RI_ASSERT((s.m_format == VGColor_sRGBA && !self->m_paint->m_colorRampPremultiplied) || (s.m_format == VGColor_sRGBA_PRE && self->m_paint->m_colorRampPremultiplied));
		s=VGColorPremultiply(s);
		break;
	}

	default:
		RI_ASSERT(self->m_paint->m_paintType == VG_PAINT_TYPE_PATTERN);
		if(self->m_paint->m_pattern)
			s = VGImageResample(self->m_paint->m_pattern,x+0.5f, y+0.5f, self->m_surfaceToPaintMatrix, self->m_imageQuality, self->m_paint->m_patternTilingMode, self->m_tileFillColor);
		else
			s = self->m_paint->m_paintColor;
		break;
	}

	//read destination color
	VGColor d = VGImageReadPixel(self->m_renderingSurface,x, y);
	d=VGColorPremultiply(d);
	RI_ASSERT(d.m_format == VGColor_lRGBA_PRE || d.m_format == VGColor_sRGBA_PRE || d.m_format == VGColor_lLA_PRE || d.m_format == VGColor_sLA_PRE);

	//apply image (vgDrawImage only)
	//1. paint: convert paint to dst space
	//2. image: convert image to dst space
	//3. paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst
	//4. paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply
	RIfloat ar = s.a, ag = s.a, ab = s.a;
	if(self->m_image)
	{
		VGColor im = VGImageResample(self->m_image,x+0.5f, y+0.5f, self->m_surfaceToImageMatrix, self->m_imageQuality, VG_TILE_PAD, VGColorRGBA(0,0,0,0,VGImageColorDescriptor(self->m_image).internalFormat));
		RI_ASSERT((s.m_format & VGColorLUMINANCE && s.r == s.g && s.r == s.b) || !(s.m_format & VGColorLUMINANCE));	//if luminance, r=g=b
		RI_ASSERT((im.m_format & VGColorLUMINANCE && im.r == im.g && im.r == im.b) || !(im.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

		switch(self->m_imageMode)
		{
		case VG_DRAW_IMAGE_NORMAL:
			s = im;
			ar = im.a;
			ag = im.a;
			ab = im.a;
			s=VGColorConvert(s,d.m_format);	//convert image color to destination color space
			break;
		case VG_DRAW_IMAGE_MULTIPLY:
			//the result will be in image color space. If the number of channels in image and paint
			// colors differ, convert to the number of channels in the image color.
			//paint == RGB && image == RGB: RGB*RGB
			//paint == RGB && image == L  : (0.2126 R + 0.7152 G + 0.0722 B)*L
			//paint == L   && image == RGB: LLL*RGB
			//paint == L   && image == L  : L*L
			if(!(s.m_format & VGColorLUMINANCE) && im.m_format & VGColorLUMINANCE)
			{
				s.r = s.g = s.b = RI_MIN(0.2126f*s.r + 0.7152f*s.g + 0.0722f*s.b, s.a);
			}
 			RI_ASSERT(Matrix3x3IsAffine(self->m_surfaceToPaintMatrix));
			ar *= im.a;
			ag *= im.a;
			ab *= im.a;
			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;
			s=VGColorConvert(s,d.m_format);	//convert resulting color to destination color space
			break;
		default:
			//the result will be in paint color space.
			//dst == RGB && image == RGB: RGB*RGB
			//dst == RGB && image == L  : RGB*LLL
			//dst == L   && image == RGB: L*(0.2126 R + 0.7152 G + 0.0722 B)
			//dst == L   && image == L  : L*L
			RI_ASSERT(self->m_imageMode == VG_DRAW_IMAGE_STENCIL);
			if(d.m_format & VGColorLUMINANCE && !(im.m_format & VGColorLUMINANCE))
			{
				im.r = im.g = im.b = RI_MIN(0.2126f*im.r + 0.7152f*im.g + 0.0722f*im.b, im.a);
			}
			RI_ASSERT(Matrix3x3IsAffine(self->m_surfaceToPaintMatrix));
			//s and im are both in premultiplied format. Each image channel acts as an alpha channel.
			s=VGColorConvert(s,d.m_format);	//convert paint color to destination space already here, since convert cannot deal with per channel alphas used in this mode.
			s.r *= im.r;
			s.g *= im.g;
			s.b *= im.b;
			s.a *= im.a;
			ar *= im.r;
			ag *= im.g;
			ab *= im.b;
			//in nonpremultiplied form the result is
			// s.rgb = paint.a * paint.rgb * image.a * image.rgb
			// s.a = paint.a * image.a
			// argb = paint.a * image.a * image.rgb
			break;
		}
	}
	else s=VGColorConvert(s,d.m_format);	//convert paint color to destination color space

	RI_ASSERT(s.m_format == VGColor_lRGBA_PRE || s.m_format == VGColor_sRGBA_PRE || s.m_format == VGColor_lLA_PRE || s.m_format == VGColor_sLA_PRE);

	//apply blending in the premultiplied format
	VGColor r=VGColorRGBA(0,0,0,0,d.m_format);
	RI_ASSERT(s.a >= 0.0f && s.a <= 1.0f);
	RI_ASSERT(s.r >= 0.0f && s.r <= s.a && s.r <= ar);
	RI_ASSERT(s.g >= 0.0f && s.g <= s.a && s.g <= ag);
	RI_ASSERT(s.b >= 0.0f && s.b <= s.a && s.b <= ab);
	RI_ASSERT(d.a >= 0.0f && d.a <= 1.0f);
	RI_ASSERT(d.r >= 0.0f && d.r <= d.a);
	RI_ASSERT(d.g >= 0.0f && d.g <= d.a);
	RI_ASSERT(d.b >= 0.0f && d.b <= d.a);
	switch(self->m_blendMode)
	{
	case kCGBlendModeNormal:
		r.r = s.r + d.r * (1.0f - ar);
		r.g = s.g + d.g * (1.0f - ag);
		r.b = s.b + d.b * (1.0f - ab);
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeMultiply:
		r.r = s.r * (1.0f - d.a + d.r) + d.r * (1.0f - ar);
		r.g = s.g * (1.0f - d.a + d.g) + d.g * (1.0f - ag);
		r.b = s.b * (1.0f - d.a + d.b) + d.b * (1.0f - ab);
		r.a = s.a + d.a * (1.0f - s.a);
		break;
        
	case kCGBlendModeScreen:
		r.r = s.r + d.r * (1.0f - s.r);
		r.g = s.g + d.g * (1.0f - s.g);
		r.b = s.b + d.b * (1.0f - s.b);
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeOverlay:
        r.r=(2*d.r<d.a)?(2*s.r*d.r+s.r*(1-d.a)+d.r*(1-s.a)):(s.r*d.r-2*(d.a-d.r)*(s.a-s.r)+s.r*(1-d.a)+d.r*(1-s.a));
        r.g=(2*d.g<d.a)?(2*s.g*d.g+s.g*(1-d.a)+d.g*(1-s.a)):(s.g*d.g-2*(d.a-d.g)*(s.a-s.g)+s.g*(1-d.a)+d.g*(1-s.a));
        r.b=(2*d.b<d.a)?(2*s.b*d.b+s.b*(1-d.a)+d.b*(1-s.a)):(s.b*d.b-2*(d.a-d.b)*(s.a-s.b)+s.b*(1-d.a)+d.b*(1-s.a));
        r.a=(2*d.a<d.a)?(2*s.a*d.a+s.a*(1-d.a)+d.a*(1-s.a)):(s.a*d.a-2*(d.a-d.a)*(s.a-s.a)+s.a*(1-d.a)+d.a*(1-s.a));
        break;
        
	case kCGBlendModeDarken:
		r.r = RI_MIN(s.r + d.r * (1.0f - ar), d.r + s.r * (1.0f - d.a));
		r.g = RI_MIN(s.g + d.g * (1.0f - ag), d.g + s.g * (1.0f - d.a));
		r.b = RI_MIN(s.b + d.b * (1.0f - ab), d.b + s.b * (1.0f - d.a));
		r.a = s.a + d.a * (1.0f - s.a);
		break;

	case kCGBlendModeLighten:
		r.r = RI_MAX(s.r + d.r * (1.0f - ar), d.r + s.r * (1.0f - d.a));
		r.g = RI_MAX(s.g + d.g * (1.0f - ag), d.g + s.g * (1.0f - d.a));
		r.b = RI_MAX(s.b + d.b * (1.0f - ab), d.b + s.b * (1.0f - d.a));
		//although the statement below is equivalent to r.a = s.a + d.a * (1.0f - s.a)
		//in practice there can be a very slight difference because
		//of the max operation in the blending formula that may cause color to exceed alpha.
		//Because of this, we compute the result both ways and return the maximum.
		r.a = RI_MAX(s.a + d.a * (1.0f - s.a), d.a + s.a * (1.0f - d.a));
		break;

	case kCGBlendModeColorDodge:
        r.r=(s.r==1)?1:RI_MIN(1,d.r/(1.0-s.r));
        r.g=(s.g==1)?1:RI_MIN(1,d.g/(1.0-s.g));
        r.b=(s.b==1)?1:RI_MIN(1,d.b/(1.0-s.b));
        r.a=(s.a==1)?1:RI_MIN(1,d.a/(1.0-s.a));
        break;
        
	case kCGBlendModeColorBurn:
        r.r=(s.r==0)?0:1.0-RI_MIN(1.0,(1.0-d.r)/s.r);
        r.g=(s.g==0)?0:1.0-RI_MIN(1.0,(1.0-d.g)/s.g);
        r.b=(s.b==0)?0:1.0-RI_MIN(1.0,(1.0-d.b)/s.b);
        r.a=(s.a==0)?0:1.0-RI_MIN(1.0,(1.0-d.a)/s.a);
        break;
        
	case kCGBlendModeHardLight:
        break;
        
	case kCGBlendModeSoftLight:
        break;
        
	case kCGBlendModeDifference:
        r.r=RI_ABS(d.r-s.r);
        r.g=RI_ABS(d.g-s.g);
        r.b=RI_ABS(d.b-s.b);
        r.a=RI_ABS(d.a-s.a);
        break;
        
	case kCGBlendModeExclusion:
        r.r=d.r+s.r-2.0*d.r*s.r;
        r.g=d.g+s.g-2.0*d.g*s.g;
        r.b=d.b+s.b-2.0*d.b*s.b;
        r.a=d.a+s.a-2.0*d.a*s.a;
        break;
        
	case kCGBlendModeHue:
        break;
        
	case kCGBlendModeSaturation:
        break;
        
	case kCGBlendModeColor:
        break;
        
	case kCGBlendModeLuminosity:
        break;
        
	case kCGBlendModeClear:
        r.r=0;
        r.g=0;
        r.b=0;
        r.a=0;
        break;

	case kCGBlendModeCopy:
		r = s;
		break;

	case kCGBlendModeSourceIn:
		r.r = s.r * d.a;
		r.g = s.g * d.a;
		r.b = s.b * d.a;
		r.a = s.a * d.a;
		break;

	case kCGBlendModeSourceOut:
		r.r = s.r *(1.0- d.a);
		r.g = s.g * (1.0- d.a);
		r.b = s.b * (1.0- d.a);
		r.a = s.a * (1.0- d.a);
        break;

	case kCGBlendModeSourceAtop:
		r.r = s.r*d.a+d.r*(1.0-ar);
		r.g = s.g*d.a+d.g*(1.0-ag);
		r.b = s.b*d.a+d.b*(1.0-ab);
		r.a = s.a*d.a+d.a*(1.0-s.a);
        break;

	case kCGBlendModeDestinationOver:
		r.r = s.r * (1.0f - d.a) + d.r;
		r.g = s.g * (1.0f - d.a) + d.g;
		r.b = s.b * (1.0f - d.a) + d.b;
		r.a = s.a * (1.0f - d.a) + d.a;
		break;

	case kCGBlendModeDestinationIn:
		r.r = d.r * ar;
		r.g = d.g * ag;
		r.b = d.b * ab;
		r.a = d.a * s.a;
		break;


	case kCGBlendModeDestinationOut:
		r.r = d.r *(1.0- ar);
		r.g = d.g * (1.0- ag);
		r.b = d.b * (1.0- ab);
		r.a = d.a * (1.0- s.a);
        break;

	case kCGBlendModeDestinationAtop:
        r.r=ar*(1.0-d.a)+d.r*s.a;
        r.g=ag*(1.0-d.a)+d.g*s.a;
        r.b=ab*(1.0-d.a)+d.b*s.a;
        r.a=s.a*(1.0-d.a)+d.a*s.a;
        break;

	case kCGBlendModeXOR:
        r.r=ar*(1.0-d.a)+d.r*(1.0-s.a);
        r.g=ag*(1.0-d.a)+d.g*(1.0-s.a);
        r.b=ab*(1.0-d.a)+d.b*(1.0-s.a);
        r.a=s.a*(1.0-d.a)+d.a*(1.0-s.a);
        break;

	case kCGBlendModePlusDarker:
        r.r=RI_MAX(0,(1.0-d.r)+(1-s.r));
        r.g=RI_MAX(0,(1.0-d.g)+(1-s.g));
        r.b=RI_MAX(0,(1.0-d.b)+(1-s.b));
        r.a=RI_MAX(0,(1.0-d.a)+(1-s.a));
        r.r=RI_MIN(1,r.r);
        r.g=RI_MIN(1,r.g);
        r.b=RI_MIN(1,r.b);
        r.a=RI_MIN(1,r.a);
        break;

	case kCGBlendModePlusLighter:
		r.r = RI_MIN(s.r + d.r, 1.0f);
		r.g = RI_MIN(s.g + d.g, 1.0f);
		r.b = RI_MIN(s.b + d.b, 1.0f);
		r.a = RI_MIN(s.a + d.a, 1.0f);
		break;
	}

	//apply antialiasing in linear color space
	VGColorInternalFormat aaFormat = (d.m_format & VGColorLUMINANCE) ? VGColor_lLA_PRE : VGColor_lRGBA_PRE;
	r=VGColorConvert(r,aaFormat);
	d=VGColorConvert(d,aaFormat);
	r = VGColorAdd(VGColorMultiplyByFloat(r , cov) , VGColorMultiplyByFloat(d , (1.0f - cov)));

	//write result to the destination surface
	r=VGColorConvert(r,VGImageColorDescriptor(self->m_renderingSurface).internalFormat);
	VGImageWritePixel(self->m_renderingSurface,x, y, r);
}


