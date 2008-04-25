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
 *//**
 * \file
 * \brief	Implementation of KGPaint and pixel pipe functionality.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "KGPixelPipe.h"
#import "KGBlending.h"
#import "KGSurface.h"

KGPaint *KGPaintAlloc() {
   return (KGPaint *)NSZoneCalloc(NULL,1,sizeof(KGPaint));
}

KGPaint *KGPaintInit(KGPaint *self) {
	self->m_paintType=VG_PAINT_TYPE_COLOR;
	self->m_paintColor=VGColorRGBA(0,0,0,1,VGColor_lRGBA_PRE);
	self->m_inputPaintColor=VGColorRGBA(0,0,0,1,VGColor_lRGBA);
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
	self->m_pattern=NULL;

	GradientStop gs;
	gs.offset = 0.0f;
	gs.color=VGColorRGBA(0,0,0,1,VGColor_sRGBA);
	self->m_colorRampStops[0]=gs;
    
	gs.offset = 1.0f;
	gs.color=VGColorRGBA(1,1,1,1,VGColor_sRGBA);
	self->m_colorRampStops[1]=gs;
    return self;
}

void     KGPaintDealloc(KGPaint *self) {
	if(self->m_pattern)
	{
			KGSurfaceDealloc(self->m_pattern);
	}
}

@implementation KGPixelPipe

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
	self->m_surfaceToPaintMatrix=Matrix3x3Identity();
	self->m_surfaceToImageMatrix=Matrix3x3Identity();
    return self;
}

void KGPixelPipeDealloc(KGPixelPipe *self) {
   NSZoneFree(NULL,self);
}

void KGPixelPipeSetRenderingSurface(KGPixelPipe *self,KGSurface *renderingSurface) {
	RI_ASSERT(renderingSurface);
	self->m_renderingSurface = renderingSurface;
}

void KGPixelPipeSetBlendMode(KGPixelPipe *self,CGBlendMode blendMode) {
	RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
	self->m_blendMode = blendMode;
}

void KGPixelPipeSetMask(KGPixelPipe *self,KGSurface* mask) {
	self->m_mask = mask;
}

void KGPixelPipeSetImage(KGPixelPipe *self,KGImage *image, KGSurfaceMode imageMode) {
	RI_ASSERT(imageMode == VG_DRAW_IMAGE_NORMAL || imageMode == VG_DRAW_IMAGE_MULTIPLY || imageMode == VG_DRAW_IMAGE_STENCIL);
	self->m_image = image;
	self->m_imageMode = imageMode;
}

void KGPixelPipeSetSurfaceToPaintMatrix(KGPixelPipe *self,Matrix3x3 surfaceToPaintMatrix) {
	self->m_surfaceToPaintMatrix = surfaceToPaintMatrix;
}

void KGPixelPipeSetSurfaceToImageMatrix(KGPixelPipe *self,Matrix3x3 surfaceToImageMatrix) {
	self->m_surfaceToImageMatrix = surfaceToImageMatrix;
}

void KGPixelPipeSetImageQuality(KGPixelPipe *self,CGInterpolationQuality imageQuality) {
	RI_ASSERT(imageQuality == kCGInterpolationNone || imageQuality == kCGInterpolationLow || imageQuality == kCGInterpolationHigh);
	self->m_imageQuality = imageQuality;
}

void KGPixelPipeSetPaint(KGPixelPipe *self, KGPaint* paint) {
	self->m_paint = paint;
	if(!self->m_paint)
		self->m_paint = self->m_defaultPaint;
}

void KGPixelPipeLinearGradient(KGPixelPipe *self,RIfloat *g, RIfloat *rho, RIfloat x, RIfloat y) {
	RI_ASSERT(self->m_paint);
	Vector2 u = Vector2Subtract(self->m_paint->m_linearGradientPoint1 , self->m_paint->m_linearGradientPoint0);
	RIfloat usq = Vector2Dot(u,u);
	if( usq <= 0.0f )
	{	//points are equal, gradient is always 1.0f
		*g = 1.0f;
		*rho = 0.0f;
		return;
	}
	RIfloat oou = 1.0f / usq;

	Vector2 p=Vector2Make(x, y);
	p = Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p);
	p = Vector2Subtract(p,self->m_paint->m_linearGradientPoint0);
	RI_ASSERT(usq >= 0.0f);
	*g = Vector2Dot(p, u) * oou;
	RIfloat dgdx = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][0] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][0];
	RIfloat dgdy = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][1] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][1];
	*rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	RI_ASSERT(*rho >= 0.0f);
}

void KGPixelPipeRadialGradient(KGPixelPipe *self,RIfloat *g, RIfloat *rho, RIfloat x, RIfloat y) {
	RI_ASSERT(self->m_paint);
	if( self->m_paint->m_radialGradientRadius <= 0.0f )
	{
		*g = 1.0f;
		*rho = 0.0f;
		return;
	}

	RIfloat r = self->m_paint->m_radialGradientRadius;
	Vector2 c = self->m_paint->m_radialGradientCenter;
	Vector2 f = self->m_paint->m_radialGradientFocalPoint;
	Vector2 gx=Vector2Make(self->m_surfaceToPaintMatrix.matrix[0][0], self->m_surfaceToPaintMatrix.matrix[1][0]);
	Vector2 gy=Vector2Make(self->m_surfaceToPaintMatrix.matrix[0][1],self->m_surfaceToPaintMatrix.matrix[1][1]);

	Vector2 fp = Vector2Subtract(f,c);

	//clamp the focal point inside the gradient circle
	RIfloat fpLen = Vector2Length(fp);
	if( fpLen > 0.999f * r )
		fp = Vector2MultiplyByFloat(fp, (0.999f * r / fpLen));

	RIfloat D = -1.0f / (Vector2Dot(fp,fp) - r*r);
	Vector2 p=Vector2Make(x, y);
	p = Vector2Subtract(Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p), c);
	Vector2 d = Vector2Subtract(p,fp);
	RIfloat s = (RIfloat)sqrt(r*r*Vector2Dot(d,d) - RI_SQR(p.x*fp.y - p.y*fp.x));
	*g = (Vector2Dot(fp,d) + s) * D;
	if(RI_ISNAN(*g))
		*g = 0.0f;
	RIfloat dgdx = D*Vector2Dot(fp,gx) + (r*r*Vector2Dot(d,gx) - (gx.x*fp.y - gx.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	RIfloat dgdy = D*Vector2Dot(fp,gy) + (r*r*Vector2Dot(d,gy) - (gy.x*fp.y - gy.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	*rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	if(RI_ISNAN(*rho))
		*rho = 0.0f;
	RI_ASSERT(*rho >= 0.0f);
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
        int i;
		for(i=0;i<self->m_paint->m_colorRampStopsCount-1;i++)
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

static inline VGColor linearGradientColorAt(KGPixelPipe *self,int x,int y){
   VGColor result;
   
   RIfloat g, rho;
   KGPixelPipeLinearGradient(self,&g, &rho, x+0.5f, y+0.5f);
   result = KGPixelPipeColorRamp(self,g, rho);
   RI_ASSERT((result.m_format == VGColor_sRGBA && !self->m_paint->m_colorRampPremultiplied) || (result.m_format == VGColor_sRGBA_PRE && self->m_paint->m_colorRampPremultiplied));

   return VGColorPremultiply(result);
}

static inline VGColor radialGradientColorAt(KGPixelPipe *self,int x,int y){
   VGColor result;
   
   RIfloat g, rho;
   KGPixelPipeRadialGradient(self,&g, &rho, x+0.5f, y+0.5f);
   result = KGPixelPipeColorRamp(self,g, rho);
   RI_ASSERT((result.m_format == VGColor_sRGBA && !self->m_paint->m_colorRampPremultiplied) || (result.m_format == VGColor_sRGBA_PRE && self->m_paint->m_colorRampPremultiplied));

   return VGColorPremultiply(result);
}

static void KGPixelPipeReadPremultipliedConstantSourceSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,int format){
   KGRGBAffff  rgba=KGRGBAffffFromColor(VGColorConvert(self->m_paint->m_paintColor,format));
   int i;
   
   for(i=0;i<length;i++)
    span[i]=rgba;
}

static void KGPixelPipeReadPremultipliedLinearGradientSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,int format){
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=linearGradientColorAt(self,x,y);
    span[i]=KGRGBAffffFromColor(VGColorConvert(s,format));
   }
}

static void KGPixelPipeReadPremultipliedRadialGradientSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,int format){
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=radialGradientColorAt(self,x,y);
    span[i]=KGRGBAffffFromColor(VGColorConvert(s,format));
   }
}

static void KGPixelPipeReadPremultipliedPatternSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,int format){
   if(self->m_paint->m_pattern==NULL)
    KGPixelPipeReadPremultipliedConstantSourceSpan(self,x,y,span,length,format);
   else {
    KGSurfacePatternSpan(self->m_paint->m_pattern,x, y,span,length,format, self->m_surfaceToPaintMatrix, kCGPatternTilingConstantSpacing);
   }
   
}

static void KGPixelPipeReadPremultipliedImageNormalSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,VGColorInternalFormat format){
   VGColorInternalFormat spanFormat;
   
   if(self->m_imageQuality== kCGInterpolationHigh){
    spanFormat=KGImageResample_EWAOnMipmaps(self->m_image,x,y,span,length,self->m_surfaceToImageMatrix);
    // spanFormat=KGImageResample_Bicubic(self->m_image,x,y,span,length,self->m_surfaceToImageMatrix);
   }
   else if(self->m_imageQuality== kCGInterpolationLow)
    spanFormat=KGImageResample_Bilinear(self->m_image,x,y,span,length,self->m_surfaceToImageMatrix);
   else
    spanFormat=KGImageResample_PointSampling(self->m_image,x,y,span,length,self->m_surfaceToImageMatrix);
  
   if(!(spanFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    spanFormat|=VGColorPREMULTIPLIED;
   }
   convertSpan(span,length,spanFormat,format);
}

static void KGPixelPipeReadPremultipliedSourceSpan(KGPixelPipe *self,int x,int y,KGRGBAffff *span,int length,int format){
   int i;
   
   RI_ASSERT(self->m_paint);
   switch(self->m_paint->m_paintType){
	case VG_PAINT_TYPE_COLOR:
        KGPixelPipeReadPremultipliedConstantSourceSpan(self,x,y,span,length,format);
		break;

	case VG_PAINT_TYPE_LINEAR_GRADIENT:
        KGPixelPipeReadPremultipliedLinearGradientSpan(self,x,y,span,length,format);
		break;

	case VG_PAINT_TYPE_RADIAL_GRADIENT:
        KGPixelPipeReadPremultipliedRadialGradientSpan(self,x,y,span,length,format);
		break;

	case VG_PAINT_TYPE_PATTERN:
        KGPixelPipeReadPremultipliedPatternSpan(self,x,y,span,length,format);
		break;
   }

   if(self->m_image!=NULL){
    if(self->m_imageMode==VG_DRAW_IMAGE_NORMAL){
     KGPixelPipeReadPremultipliedImageNormalSpan(self,x,y,span,length,format);
    }
    else {
     KGRGBAffff imageSpan[length];
     
     KGPixelPipeReadPremultipliedImageNormalSpan(self,x,y,imageSpan,length,self->m_image->_colorFormat|VGColorPREMULTIPLIED);
     
   for(i=0;i<length;i++,x++){
	//evaluate paint
	VGColor s=VGColorFromKGRGBA_ffff(span[i],format);
    VGColor im=VGColorFromKGRGBA_ffff(imageSpan[i],self->m_image->_colorFormat);
    
	//apply image (vgDrawImage only)
	//1. paint: convert paint to dst space
	//2. image: convert image to dst space
	//3. paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst
	//4. paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply

		RI_ASSERT((s.m_format & VGColorLUMINANCE && s.r == s.g && s.r == s.b) || !(s.m_format & VGColorLUMINANCE));	//if luminance, r=g=b
		RI_ASSERT((im.m_format & VGColorLUMINANCE && im.r == im.g && im.r == im.b) || !(im.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

		switch(self->m_imageMode)
		{

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
			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;
			s=VGColorConvert(s,format);	//convert resulting color to destination color space
			break;
		case VG_DRAW_IMAGE_STENCIL:
{
 // FIX
 // This needs to be changed to a nonpremultplied form. This is the only case which used ar, ag, ab premultiplied values for source.

	RIfloat ar = s.a, ag = s.a, ab = s.a;
			//the result will be in paint color space.
			//dst == RGB && image == RGB: RGB*RGB
			//dst == RGB && image == L  : RGB*LLL
			//dst == L   && image == RGB: L*(0.2126 R + 0.7152 G + 0.0722 B)
			//dst == L   && image == L  : L*L
			RI_ASSERT(self->m_imageMode == VG_DRAW_IMAGE_STENCIL);
			if(format & VGColorLUMINANCE && !(im.m_format & VGColorLUMINANCE))
			{
				im.r = im.g = im.b = RI_MIN(0.2126f*im.r + 0.7152f*im.g + 0.0722f*im.b, im.a);
			}
			RI_ASSERT(Matrix3x3IsAffine(self->m_surfaceToPaintMatrix));
			//s and im are both in premultiplied format. Each image channel acts as an alpha channel.
			s=VGColorConvert(s,format);	//convert paint color to destination space already here, since convert cannot deal with per channel alphas used in this mode.
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

	RI_ASSERT(s.r >= 0.0f && s.r <= s.a && s.r <= ar);
	RI_ASSERT(s.g >= 0.0f && s.g <= s.a && s.g <= ag);
	RI_ASSERT(s.b >= 0.0f && s.b <= s.a && s.b <= ab);
}
			break;
		}

    span[i]=KGRGBAffffFromColor(s);
   }
   }
   }
   
      
}


static void KGBlendSpanWithMode_ffff(KGRGBAffff *src,KGRGBAffff *dst,int length,CGBlendMode blendMode){
   switch(blendMode){
   
    case kCGBlendModeNormal:
     KGBlendSpanNormal_ffff(src,dst,length);
     break;
     
	case kCGBlendModeMultiply:
     KGBlendSpanMultiply_ffff(src,dst,length);
     break;
     
	case kCGBlendModeScreen:
     KGBlendSpanScreen_ffff(src,dst,length);
	 break;

	case kCGBlendModeOverlay:
     KGBlendSpanOverlay_ffff(src,dst,length);
     break;
        
	case kCGBlendModeDarken:
     KGBlendSpanDarken_ffff(src,dst,length);
     break;

	case kCGBlendModeLighten:
     KGBlendSpanLighten_ffff(src,dst,length);
     break;

	case kCGBlendModeColorDodge:
     KGBlendSpanColorDodge_ffff(src,dst,length);
     break;
        
	case kCGBlendModeColorBurn:
     KGBlendSpanColorBurn_ffff(src,dst,length);
     break;
        
	case kCGBlendModeHardLight:
     KGBlendSpanHardLight_ffff(src,dst,length);
     break;
        
	case kCGBlendModeSoftLight:
     KGBlendSpanSoftLight_ffff(src,dst,length);
     break;
        
	case kCGBlendModeDifference:
     KGBlendSpanDifference_ffff(src,dst,length);
     break;
        
	case kCGBlendModeExclusion:
     KGBlendSpanExclusion_ffff(src,dst,length);
     break;
        
	case kCGBlendModeHue:
     KGBlendSpanHue_ffff(src,dst,length);
     break; 
        
	case kCGBlendModeSaturation:
     KGBlendSpanSaturation_ffff(src,dst,length);
     break;
        
	case kCGBlendModeColor:
     KGBlendSpanColor_ffff(src,dst,length);
     break;
        
	case kCGBlendModeLuminosity:
     KGBlendSpanLuminosity_ffff(src,dst,length);
     break;
        
	case kCGBlendModeClear:
     KGBlendSpanClear_ffff(src,dst,length);
     break;

	case kCGBlendModeCopy:
     KGBlendSpanCopy_ffff(src,dst,length);
     break;

	case kCGBlendModeSourceIn:
     KGBlendSpanSourceIn_ffff(src,dst,length);
     break;

	case kCGBlendModeSourceOut:
     KGBlendSpanSourceOut_ffff(src,dst,length);
     break;

	case kCGBlendModeSourceAtop:
     KGBlendSpanSourceAtop_ffff(src,dst,length);
     break;

	case kCGBlendModeDestinationOver:
     KGBlendSpanDestinationOver_ffff(src,dst,length);
     break;

	case kCGBlendModeDestinationIn:
     KGBlendSpanDestinationIn_ffff(src,dst,length);
     break;

	case kCGBlendModeDestinationOut:
     KGBlendSpanDestinationOut_ffff(src,dst,length);
     break;

	case kCGBlendModeDestinationAtop:
     KGBlendSpanDestinationAtop_ffff(src,dst,length);
     break;

	case kCGBlendModeXOR:
     KGBlendSpanXOR_ffff(src,dst,length);
     break;

	case kCGBlendModePlusDarker:
     KGBlendSpanPlusDarker_ffff(src,dst,length);
     break;

	case kCGBlendModePlusLighter:
     KGBlendSpanPlusLighter_ffff(src,dst,length);
     break;
   }
}

static inline KGRGBAffff KGRGBAffffConvert(KGRGBAffff rgba,int fromFormat,int toFormat){
   VGColor color=VGColorFromKGRGBA_ffff(rgba,fromFormat);
   
   color=VGColorConvert(color,toFormat);
   
   return KGRGBAffffFromColor(color);
}

static VGColorInternalFormat KGApplyCoverageToSpan(KGRGBAffff *dst,RIfloat *coverage,KGRGBAffff *result,int length,VGColorInternalFormat dFormat){
   //apply antialiasing in linear color space
   VGColorInternalFormat aaFormat = (dFormat & VGColorLUMINANCE) ? VGColor_lLA_PRE : VGColor_lRGBA_PRE;
   int i;
   
   if(aaFormat!=dFormat){
    for(i=0;i<length;i++){
     KGRGBAffff r=result[i];
     KGRGBAffff d=dst[i];
     RIfloat cov=coverage[i];

     r=KGRGBAffffConvert(r,dFormat,aaFormat);
     d=KGRGBAffffConvert(d,dFormat,aaFormat);
   
     result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
    }
    return aaFormat;
   }
   else {
    for(i=0;i<length;i++){
     KGRGBAffff r=result[i];
     KGRGBAffff d=dst[i];
     RIfloat cov=coverage[i];
     
     result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
    }
    
    return dFormat;
   }
   
}

void KGPixelPipeWriteCoverage(KGPixelPipe *self,int x, int y,RIfloat *coverage,int length)  {
	RI_ASSERT(self->m_renderingSurface);

	//apply masking
	if(self->m_mask)
     KGSurfaceReadMaskPixelSpanIntoCoverage(self->m_mask,x,y,coverage,length);
// This optimization may not make sense in the bulk computations
//	if(coverage[0..length] == 0.0f)
//		return;

	//read destination color
    KGRGBAffff d[length];
    VGColorInternalFormat dFormat=KGSurfaceReadPremultipliedSpan_ffff(self->m_renderingSurface,x,y,d,length);

    KGRGBAffff src[length];
    KGPixelPipeReadPremultipliedSourceSpan(self,x,y,src,length,dFormat);
    
    KGBlendSpanWithMode_ffff(src,d,length,self->m_blendMode);
    VGColorInternalFormat resultFormat;
    
    resultFormat=KGApplyCoverageToSpan(d,coverage,src,length,dFormat);
    
	//write result to the destination surface
    KGSurfaceWritePixelSpan(self->m_renderingSurface,x,y,src,length,resultFormat);
}

@end
