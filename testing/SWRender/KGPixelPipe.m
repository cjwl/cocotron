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
			VGImageDealloc(self->m_pattern);
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
	self->m_tileFillColor=VGColorRGBA(0,0,0,0,VGColor_lRGBA);
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

void KGPixelPipeSetMask(KGPixelPipe *self,VGImage* mask) {
	self->m_mask = mask;
}

void KGPixelPipeSetImage(KGPixelPipe *self,VGImage* image, VGImageMode imageMode) {
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

void KGPixelPipeSetTileFillColor(KGPixelPipe *self,VGColor c) {
	self->m_tileFillColor = c;
	self->m_tileFillColor=VGColorClamp(self->m_tileFillColor);
}

void KGPixelPipeSetPaint(KGPixelPipe *self, KGPaint* paint) {
	self->m_paint = paint;
	if(!self->m_paint)
		self->m_paint = self->m_defaultPaint;
	if(self->m_paint->m_pattern)
		self->m_tileFillColor=VGColorConvert(self->m_tileFillColor,self->m_paint->m_pattern->_colorFormat);
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




static inline float colorFromTemp(float c,float q,float p){
    if(6.0*c<1)
     c=p+(q-p)*6.0*c;
    else if(2.0*c<1)
     c=q;
    else if(3.0*c<2)
     c=p+(q-p)*((2.0/3.0)-c)*6.0;
    else
     c=p;
    return c;
}

static inline void HSLToRGB(float hue,float saturation,float luminance,float *redp,float *greenp,float *bluep) {
   float red=luminance,green=luminance,blue=luminance;

   if(saturation!=0){
    float p,q;

    if(luminance<0.5)
     q=luminance*(1+saturation);
    else
     q=luminance+saturation-(luminance*saturation);
    p=2*luminance-q;
    
    red=hue+1.0/3.0;
    if(red<0)
     red+=1.0;
    green=hue;
    if(green<0)
     green+=1.0;
    blue=hue-1.0/3.0;
    if(blue<0)
     blue+=1.0;
    
    red=colorFromTemp(red,q,p);
    green=colorFromTemp(green,q,p);
    blue=colorFromTemp(blue,q,p);
   }

   *redp=red;
   *greenp=green;
   *bluep=blue;
}

static inline void RGBToHSL(float r,float g,float b,float *huep,float *saturationp,float *luminancep) {
   float hue=0,saturation=0,luminance,min,max;

   max=MAX(r,MAX(g,b));
   min=MIN(r,MIN(g,b));
   if(max==min)
    hue=0;
   else if(max==r && g>=b)
    hue=60*((g-b)/(max-min));
   else if(max==r && g<b)
    hue=60*((g-b)/(max-min))+360;
   else if(max==g)
    hue=60*((b-r)/(max-min))+120;
   else if(max==b)
    hue=60*((r-g)/(max-min))+240;
    
   luminance=(max+min)/2.0;
   if(max==min)
    saturation=0;
   else if(luminance<=0.5)
    saturation=(max-min)/(max+min);
   else
    saturation=(max-min)/(2-(max+min));
    
   if(huep!=NULL)
    *huep=fmod(hue,360)/360.0;
   if(saturationp!=NULL)
    *saturationp=saturation;
   if(luminancep!=NULL)
    *luminancep=luminance;
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

static void KGPixelPipeReadPremultipliedConstantSourceSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
   KGRGBA  rgba=KGRGBAFromColor(VGColorConvert(self->m_paint->m_paintColor,format));
   int i;
   
   for(i=0;i<length;i++)
    span[i]=rgba;
}

static void KGPixelPipeReadPremultipliedLinearGradientSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=linearGradientColorAt(self,x,y);
    span[i]=KGRGBAFromColor(VGColorConvert(s,format));
   }
}

static void KGPixelPipeReadPremultipliedRadialGradientSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=radialGradientColorAt(self,x,y);
    span[i]=KGRGBAFromColor(VGColorConvert(s,format));
   }
}

static void KGPixelPipeReadPremultipliedPatternSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
   if(self->m_paint->m_pattern==NULL)
    KGPixelPipeReadPremultipliedConstantSourceSpan(self,x,y,span,length,format);
   else {
    VGImageReadTexelTileSpan tilingFunction=VGImageTexelTilingFunctionForMode(self->m_paint->m_patternTilingMode);
    
    VGImageResampleSpan(self->m_paint->m_pattern,x, y,span,length,format, self->m_surfaceToPaintMatrix, self->m_imageQuality, tilingFunction, self->m_tileFillColor);
   }
   
}

static void KGPixelPipeReadPremultipliedImageNormalSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
   VGImageReadTexelTileSpan tilingFunction=VGImageTexelTilingFunctionForMode(VG_TILE_PAD);
   VGImageResampleSpan(self->m_image,x, y,span,length,format, self->m_surfaceToImageMatrix, self->m_imageQuality, tilingFunction, VGColorRGBA(0,0,0,0,self->m_image->_colorFormat));
}

static void KGPixelPipeReadPremultipliedSourceSpan(KGPixelPipe *self,int x,int y,KGRGBA *span,int length,int format){
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
     KGRGBA imageSpan[length];
     
     KGPixelPipeReadPremultipliedImageNormalSpan(self,x,y,imageSpan,length,self->m_image->_colorFormat);
     
   for(i=0;i<length;i++,x++){
	//evaluate paint
	VGColor s=VGColorFromKGRGBA(span[i],format);
    VGColor im=VGColorFromKGRGBA(imageSpan[i],self->m_image->_colorFormat);
    
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
 // This needs to be changed to a nonpremultplied form. This is the only case which uses ar, ag, ab premultiplied values for source.

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

    span[i]=KGRGBAFromColor(s);
   }
   }
   }
   
      
}

static void KGBlendSpan_Normal(KGRGBA *src,KGRGBA *dst,int length){
// Passes Visual Test
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r + d.r * (1.0f - s.a);
    r.g = s.g + d.g * (1.0f - s.a);
    r.b = s.b + d.b * (1.0f - s.a);
    r.a = s.a + d.a * (1.0f - s.a);
    
    src[i]=r;
   }
}

static void KGBlendSpan_Multiply(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;

    r.r = s.r * (1.0f - d.a + d.r) + d.r * (1.0f - s.a);
    r.g = s.g * (1.0f - d.a + d.g) + d.g * (1.0f - s.a);
    r.b = s.b * (1.0f - d.a + d.b) + d.b * (1.0f - s.a);
    r.a = s.a + d.a * (1.0f - s.a);
    
    src[i]=r;
   }
}

static void KGBlendSpan_Screen(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r + d.r - s.r*d.r;
    r.g = s.g + d.g - s.g*d.g;
    r.b = s.b + d.b - s.b*d.b;
    r.a = s.a + d.a * (1.0f - s.a);

    src[i]=r;
   }
}

static void KGBlendSpan_Overlay(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    RIfloat max=RI_MAX(s.r,RI_MAX(s.g,s.b));
    RIfloat min=RI_MIN(s.r,RI_MIN(s.g,s.b));
    RIfloat lum=(max+min)/2*(1.0-d.a);
    if(lum<=0.5)
     r.r = s.r * (1.0f - d.a + d.r) + d.r * (1.0f - s.a);
    else
     r.r = s.r + d.r - s.r*d.r;

    if(lum<=0.5)
     r.g = s.g * (1.0f - d.a + d.g) + d.g * (1.0f - s.a);
    else
     r.g = s.g + d.g - s.g*d.g;
        
    if(lum<=0.5)
     r.b = s.b * (1.0f - d.a + d.b) + d.b * (1.0f - s.a);
    else
     r.b = s.b + d.b - s.b*d.b;

    r.a = s.a + d.a * (1.0f - s.a);

    src[i]=r;
   }
}
static void KGBlendSpan_Darken(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = RI_MIN(s.r + d.r * (1.0f - s.a), d.r + s.r * (1.0f - d.a));
    r.g = RI_MIN(s.g + d.g * (1.0f - s.a), d.g + s.g * (1.0f - d.a));
    r.b = RI_MIN(s.b + d.b * (1.0f - s.a), d.b + s.b * (1.0f - d.a));
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_Lighten(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = RI_MAX(s.r + d.r * (1.0f - s.a), d.r + s.r * (1.0f - d.a));
    r.g = RI_MAX(s.g + d.g * (1.0f - s.a), d.g + s.g * (1.0f - d.a));
    r.b = RI_MAX(s.b + d.b * (1.0f - s.a), d.b + s.b * (1.0f - d.a));
    //although the statement below is equivalent to r.a = s.a + d.a * (1.0f - s.a)
    //in practice there can be a very slight difference because
    //of the max operation in the blending formula that may cause color to exceed alpha.
    //Because of this, we compute the result both ways and return the maximum.
    r.a = RI_MAX(s.a + d.a * (1.0f - s.a), d.a + s.a * (1.0f - d.a));
    src[i]=r;
   }
}
static void KGBlendSpan_ColorDodge(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r=(s.r==1)?1:RI_MIN(1,d.r/(1.0-s.r));
    r.g=(s.g==1)?1:RI_MIN(1,d.g/(1.0-s.g));
    r.b=(s.b==1)?1:RI_MIN(1,d.b/(1.0-s.b));
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_ColorBurn(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;

    r.r=(s.r==0)?0:1.0-RI_MIN(1.0,(1.0-d.r)/s.r);
    r.g=(s.g==0)?0:1.0-RI_MIN(1.0,(1.0-d.g)/s.g);
    r.b=(s.b==0)?0:1.0-RI_MIN(1.0,(1.0-d.b)/s.b);
    r.a=(s.a==0)?0:1.0-RI_MIN(1.0,(1.0-d.a)/s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_HardLight(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    //KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r=d;
    
    src[i]=r;
   }
}
static void KGBlendSpan_SoftLight(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    //KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r=d;
    
    src[i]=r;
   }
}
static void KGBlendSpan_Difference(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r=s.r+d.r-2*(RI_MIN(s.r*d.a,d.r*s.a));
    r.g=s.g+d.g-2*(RI_MIN(s.g*d.a,d.g*s.a));
    r.b=s.b+d.b-2*(RI_MIN(s.b*d.a,d.b*s.a));
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_Exclusion(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = (s.r * d.a + d.r * s.a - 2 * s.r * d.r) + s.r * (1 - d.a) + d.r * (1 - s.a);
    r.g = (s.g * d.a + d.g * s.a - 2 * s.g * d.r) + s.g * (1 - d.a) + d.g * (1 - s.a);
    r.b = (s.b * d.a + d.b * s.a - 2 * s.b * d.r) + s.b * (1 - d.a) + d.b * (1 - s.a);
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_Hue(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    RIfloat sh,ss,sl;
    RIfloat dh,ds,dl;
        
    RGBToHSL(s.r,s.g,s.b,&sh,&ss,&sl);
    RGBToHSL(d.r,d.g,d.b,&dh,&ds,&dl);
    HSLToRGB(sh,ds,dl,&r.r,&r.g,&r.b);
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_Saturation(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    RIfloat sh,ss,sl;
    RIfloat dh,ds,dl;
        
    RGBToHSL(s.r,s.g,s.b,&sh,&ss,&sl);
    RGBToHSL(d.r,d.g,d.b,&dh,&ds,&dl);
    HSLToRGB(dh,ss,dl,&r.r,&r.g,&r.b);
    r.a = s.a + d.a * (1.0f - s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_Color(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    //KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r=d;
    
    src[i]=r;
   }
}
static void KGBlendSpan_Luminosity(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    //KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r=d;
    
    src[i]=r;
   }
}
static void KGBlendSpan_Clear(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA r;
    
        r.r=0;
        r.g=0;
        r.b=0;
        r.a=0;

    src[i]=r;
   }
}
static void KGBlendSpan_Copy(KGRGBA *src,KGRGBA *dst,int length){
   // do nothing src already contains values
}

static void KGBlendSpan_SourceIn(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r * d.a;
    r.g = s.g * d.a;
    r.b = s.b * d.a;
    r.a = s.a * d.a;
    src[i]=r;
   }
}
static void KGBlendSpan_SourceOut(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r *(1.0- d.a);
    r.g = s.g * (1.0- d.a);
    r.b = s.b * (1.0- d.a);
    r.a = s.a * (1.0- d.a);
    src[i]=r;
   }
}
static void KGBlendSpan_SourceAtop(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r*d.a+d.r*(1.0-s.a);
    r.g = s.g*d.a+d.g*(1.0-s.a);
    r.b = s.b*d.a+d.b*(1.0-s.a);
    r.a = s.a*d.a+d.a*(1.0-s.a);
    src[i]=r;
   }
}
static void KGBlendSpan_DestinationOver(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = s.r * (1.0f - d.a) + d.r;
    r.g = s.g * (1.0f - d.a) + d.g;
    r.b = s.b * (1.0f - d.a) + d.b;
    r.a = s.a * (1.0f - d.a) + d.a;

    src[i]=r;
   }
}
static void KGBlendSpan_DestinationIn(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = d.r * s.a;
    r.g = d.g * s.a;
    r.b = d.b * s.a;
    r.a = d.a * s.a;
    
    src[i]=r;
   }
}
static void KGBlendSpan_DestinationOut(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = d.r *(1.0- s.a);
    r.g = d.g * (1.0- s.a);
    r.b = d.b * (1.0- s.a);
    r.a = d.a * (1.0- s.a);

    src[i]=r;
   }
}
static void KGBlendSpan_DestinationAtop(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r=s.r*(1.0-d.a)+d.r*s.a;
    r.g=s.g*(1.0-d.a)+d.g*s.a;
    r.b=s.b*(1.0-d.a)+d.b*s.a;
    r.a=s.a*(1.0-d.a)+d.a*s.a;
    
    src[i]=r;
   }
}
static void KGBlendSpan_XOR(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r=s.r*(1.0-d.a)+d.r*(1.0-s.a);
    r.g=s.g*(1.0-d.a)+d.g*(1.0-s.a);
    r.b=s.b*(1.0-d.a)+d.b*(1.0-s.a);
    r.a=s.a*(1.0-d.a)+d.a*(1.0-s.a);
    
    src[i]=r;
   }
}
static void KGBlendSpan_PlusDarker(KGRGBA *src,KGRGBA *dst,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
#if 0
// Doc.s say:  R = MAX(0, (1 - D) + (1 - S)). No workie.
    r.r=RI_MAX(0,(1-d.r)+(1-s.r));
    r.g=RI_MAX(0,(1-d.g)+(1-s.g));
    r.b=RI_MAX(0,(1-d.b)+(1-s.b));
    r.a=RI_MAX(0,(1-d.a)+(1-s.a));
#else
    r.r=RI_MIN(1.0,(1-d.r)+(1-s.r));
    r.g=RI_MIN(1.0,(1-d.g)+(1-s.g));
    r.b=RI_MIN(1.0,(1-d.b)+(1-s.b));
    r.a = s.a ;
//        r.a=RI_MIN(1.0,(1-d.a)+(1-s.a));
#endif
    src[i]=r;
   }
}

static void KGBlendSpan_PlusLighter(KGRGBA *src,KGRGBA *dst,int length){
// Doc.s say: R = MIN(1, S + D). That works
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA s=src[i];
    KGRGBA d=dst[i];
    KGRGBA r;
    
    r.r = RI_MIN(s.r + d.r, 1.0f);
    r.g = RI_MIN(s.g + d.g, 1.0f);
    r.b = RI_MIN(s.b + d.b, 1.0f);
    r.a = RI_MIN(s.a + d.a, 1.0f);

    src[i]=r;
   }
}

static void KGBlendSpanWithMode(KGRGBA *src,KGRGBA *dst,int length,CGBlendMode blendMode){
   switch(blendMode){
   
    case kCGBlendModeNormal:
     KGBlendSpan_Normal(src,dst,length);
     break;
     
	case kCGBlendModeMultiply: // Passes Visual Test
     KGBlendSpan_Multiply(src,dst,length);
     break;
     
	case kCGBlendModeScreen: // Passes Visual Test
     KGBlendSpan_Screen(src,dst,length);
	 break;

	case kCGBlendModeOverlay:// broken
     KGBlendSpan_Overlay(src,dst,length);
     break;
        
	case kCGBlendModeDarken: // Passes Visual Test
     KGBlendSpan_Darken(src,dst,length);
     break;

	case kCGBlendModeLighten: // Passes Visual Test
     KGBlendSpan_Lighten(src,dst,length);
     break;

	case kCGBlendModeColorDodge:
     KGBlendSpan_ColorDodge(src,dst,length);
     break;
        
	case kCGBlendModeColorBurn:
     KGBlendSpan_ColorBurn(src,dst,length);
     break;
        
	case kCGBlendModeHardLight:
     KGBlendSpan_HardLight(src,dst,length);
     break;
        
	case kCGBlendModeSoftLight:
     KGBlendSpan_SoftLight(src,dst,length);
     break;
        
	case kCGBlendModeDifference: // Passes Visual Test
     KGBlendSpan_Difference(src,dst,length);
     break;
        
	case kCGBlendModeExclusion:
     KGBlendSpan_Exclusion(src,dst,length);
     break;
        
	case kCGBlendModeHue:
     KGBlendSpan_Hue(src,dst,length);
     break; 
        
	case kCGBlendModeSaturation:
     KGBlendSpan_Saturation(src,dst,length);
     break;
        
	case kCGBlendModeColor:
     KGBlendSpan_Color(src,dst,length);
     break;
        
	case kCGBlendModeLuminosity:
     KGBlendSpan_Luminosity(src,dst,length);
     break;
        
	case kCGBlendModeClear: // Passes Visual Test, duh
     KGBlendSpan_Clear(src,dst,length);
     break;

	case kCGBlendModeCopy: // Passes Visual Test
     KGBlendSpan_Copy(src,dst,length);
     break;

	case kCGBlendModeSourceIn: // Passes Visual Test
     KGBlendSpan_SourceIn(src,dst,length);
     break;

	case kCGBlendModeSourceOut: // Passes Visual Test
     KGBlendSpan_SourceOut(src,dst,length);
     break;

	case kCGBlendModeSourceAtop: // Passes Visual Test
     KGBlendSpan_SourceAtop(src,dst,length);
     break;

	case kCGBlendModeDestinationOver: // Passes Visual Test
     KGBlendSpan_DestinationOver(src,dst,length);
     break;

	case kCGBlendModeDestinationIn: // Passes Visual Test
     KGBlendSpan_DestinationIn(src,dst,length);
     break;

	case kCGBlendModeDestinationOut: // Passes Visual Test
     KGBlendSpan_DestinationOut(src,dst,length);
     break;

	case kCGBlendModeDestinationAtop: // Passes Visual Test
     KGBlendSpan_DestinationAtop(src,dst,length);
     break;

	case kCGBlendModeXOR: // Passes Visual Test
     KGBlendSpan_XOR(src,dst,length);
     break;

	case kCGBlendModePlusDarker:
     KGBlendSpan_PlusDarker(src,dst,length);
     break;

	case kCGBlendModePlusLighter: // Passes Visual Test
     KGBlendSpan_PlusLighter(src,dst,length);
     break;
   }
}

static inline KGRGBA KGRGBAConvert(KGRGBA rgba,int fromFormat,int toFormat){
   VGColor color=VGColorFromKGRGBA(rgba,fromFormat);
   
   color=VGColorConvert(color,toFormat);
   
   return KGRGBAFromColor(color);
}

static VGColorInternalFormat KGApplyCoverageToSpan(KGRGBA *dst,RIfloat *coverage,KGRGBA *result,int length,VGColorInternalFormat dFormat){
   //apply antialiasing in linear color space
   VGColorInternalFormat aaFormat = (dFormat & VGColorLUMINANCE) ? VGColor_lLA_PRE : VGColor_lRGBA_PRE;
   int i;
   
   if(aaFormat!=dFormat){
    for(i=0;i<length;i++){
     KGRGBA r=result[i];
     KGRGBA d=dst[i];
     RIfloat cov=coverage[i];

     r=KGRGBAConvert(r,dFormat,aaFormat);
     d=KGRGBAConvert(d,dFormat,aaFormat);
   
     result[i]=KGRGBAAdd(KGRGBAMultiplyByFloat(r , cov) , KGRGBAMultiplyByFloat(d , (1.0f - cov)));
    }
    return aaFormat;
   }
   else {
    for(i=0;i<length;i++){
     KGRGBA r=result[i];
     KGRGBA d=dst[i];
     RIfloat cov=coverage[i];
     
     result[i]=KGRGBAAdd(KGRGBAMultiplyByFloat(r , cov) , KGRGBAMultiplyByFloat(d , (1.0f - cov)));
    }
    
    return dFormat;
   }
   
}

void KGPixelPipeWriteCoverage(KGPixelPipe *self,int x, int y,RIfloat *coverage,int length)  {
	RI_ASSERT(self->m_renderingSurface);

	//apply masking
	if(self->m_mask)
     VGImageReadMaskPixelSpanIntoCoverage(self->m_mask,x,y,coverage,length);
// This optimization may not make sense in the bulk computations
//	if(coverage[0..length] == 0.0f)
//		return;

	//read destination color
    KGRGBA d[length];
    VGColorInternalFormat dFormat=VGImageReadPremultipliedPixelSpan(self->m_renderingSurface,x,y,d,length);

    KGRGBA src[length];
    KGPixelPipeReadPremultipliedSourceSpan(self,x,y,src,length,dFormat);
    
    KGBlendSpanWithMode(src,d,length,self->m_blendMode);
    VGColorInternalFormat resultFormat;
    
    resultFormat=KGApplyCoverageToSpan(d,coverage,src,length,dFormat);
    
	//write result to the destination surface
    VGImageWritePixelSpan(self->m_renderingSurface,x,y,src,length,resultFormat);
}
