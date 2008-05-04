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
#import "KGPaint_ramp.h"
@implementation KGPaint_ramp

-init {
   [super init];
	self->m_colorRampSpreadMode=VG_COLOR_RAMP_SPREAD_PAD;
    self->m_colorRampStopsCount=2;
    self->m_colorRampStopsCapacity=2;
	self->m_colorRampStops=(GradientStop *)NSZoneCalloc(NULL,self->m_colorRampStopsCapacity,sizeof(GradientStop));
	self->m_colorRampPremultiplied=YES;


	GradientStop gs;
	gs.offset = 0.0f;
	gs.color=VGColorRGBA(0,0,0,1,VGColor_sRGBA);
	self->m_colorRampStops[0]=gs;
    
	gs.offset = 1.0f;
	gs.color=VGColorRGBA(1,1,1,1,VGColor_sRGBA);
	self->m_colorRampStops[1]=gs;
   return self;
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

VGColor KGPaintIntegrateColorRamp(KGPaint_ramp *self,RIfloat gmin, RIfloat gmax) {
	RI_ASSERT(gmin <= gmax);
	RI_ASSERT(gmin >= 0.0f && gmin <= 1.0f);
	RI_ASSERT(gmax >= 0.0f && gmax <= 1.0f);
	RI_ASSERT(self->m_colorRampStopsCount >= 2);	//there are at least two stops

	VGColor c=VGColorRGBA(0,0,0,0,self->m_colorRampPremultiplied ? VGColor_sRGBA_PRE : VGColor_sRGBA);
	if(gmin == 1.0f || gmax == 0.0f)
		return c;

	int i=0;
	for(;i<self->m_colorRampStopsCount-1;i++)
	{
		if(gmin >= self->m_colorRampStops[i].offset && gmin < self->m_colorRampStops[i+1].offset)
		{
			RIfloat s = self->m_colorRampStops[i].offset;
			RIfloat e = self->m_colorRampStops[i+1].offset;
			RI_ASSERT(s < e);
			RIfloat g = (gmin - s) / (e - s);

			VGColor sc = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i, self->m_colorRampPremultiplied);
			VGColor ec = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i+1, self->m_colorRampPremultiplied);
			VGColor rc = VGColorAdd(VGColorMultiplyByFloat(sc, (1.0f-g)),VGColorMultiplyByFloat(ec , g));

			//subtract the average color from the start of the stop to gmin
			c=VGColorSubtract(c,VGColorMultiplyByFloat(VGColorAdd(sc,rc) , 0.5f*(gmin - s)));
			break;
		}
	}

	for(;i<self->m_colorRampStopsCount-1;i++)
	{
		RIfloat s = self->m_colorRampStops[i].offset;
		RIfloat e = self->m_colorRampStops[i+1].offset;
		RI_ASSERT(s <= e);

		VGColor sc = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i, self->m_colorRampPremultiplied);
		VGColor ec = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i+1, self->m_colorRampPremultiplied);

		//average of the stop
		c=VGColorAdd(c , VGColorMultiplyByFloat(VGColorAdd(sc , ec), 0.5f*(e-s)));

		if(gmax >= self->m_colorRampStops[i].offset && gmax < self->m_colorRampStops[i+1].offset)
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

VGColor KGPaintColorRamp(KGPaint_ramp *self,RIfloat gradient, RIfloat rho) 
{
	RI_ASSERT(self);
	RI_ASSERT(rho >= 0.0f);

	VGColor c=VGColorRGBA(0,0,0,0,self->m_colorRampPremultiplied ? VGColor_sRGBA_PRE : VGColor_sRGBA);
	VGColor avg=VGColorZero();

	if(rho == 0.0f)
	{	//filter size is zero or gradient is degenerate
		switch(self->m_colorRampSpreadMode)
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
			RI_ASSERT(self->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
			gradient = gradient - (RIfloat)floor(gradient);
			break;
		}
		RI_ASSERT(gradient >= 0.0f && gradient <= 1.0f);
        int i;
		for(i=0;i<self->m_colorRampStopsCount-1;i++)
		{
			if(gradient >= self->m_colorRampStops[i].offset && gradient < self->m_colorRampStops[i+1].offset)
			{
				RIfloat s = self->m_colorRampStops[i].offset;
				RIfloat e = self->m_colorRampStops[i+1].offset;
				RI_ASSERT(s < e);
				RIfloat g = RI_CLAMP((gradient - s) / (e - s), 0.0f, 1.0f);	//clamp needed due to numerical inaccuracies

				VGColor sc = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i, self->m_colorRampPremultiplied);
				VGColor ec = readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, i+1, self->m_colorRampPremultiplied);
				return VGColorAdd(VGColorMultiplyByFloat(sc , (1.0f-g)) , VGColorMultiplyByFloat(ec , g));	//return interpolated value
			}
		}
		return readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, self->m_colorRampStopsCount-1, self->m_colorRampPremultiplied);
	}

	RIfloat gmin = gradient - rho*0.5f;			//filter starting from the gradient point (if starts earlier, radial gradient center will be an average of the first and the last stop, which doesn't look good)
	RIfloat gmax = gradient + rho*0.5f;

	switch(self->m_colorRampSpreadMode)
	{
	case VG_COLOR_RAMP_SPREAD_PAD:
	{
		if(gmin < 0.0f)
			c=VGColorAdd(c,VGColorMultiplyByFloat(readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, 0, self->m_colorRampPremultiplied), (RI_MIN(gmax, 0.0f) - gmin)));
		if(gmax > 1.0f)
			c=VGColorAdd(c,VGColorMultiplyByFloat(readStopColor(self->m_colorRampStops,self->m_colorRampStopsCount, self->m_colorRampStopsCount-1, self->m_colorRampPremultiplied) , (gmax - RI_MAX(gmin, 1.0f))));
		gmin = RI_CLAMP(gmin, 0.0f, 1.0f);
		gmax = RI_CLAMP(gmax, 0.0f, 1.0f);
		c=VGColorAdd(c, KGPaintIntegrateColorRamp(self,gmin, gmax));
		c=VGColorMultiplyByFloat(c , 1.0f/rho);
		c=VGColorClamp(c);	//clamp needed due to numerical inaccuracies
		return c;
	}

	case VG_COLOR_RAMP_SPREAD_REFLECT:
	{
		avg = KGPaintIntegrateColorRamp(self,0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = VGColorMultiplyByFloat(avg , (gmaxi + 1.0f - gmini));		//full ramps

		//subtract beginning
		if(((int)gmini) & 1)
			c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,RI_CLAMP(1.0f - (gmin - gmini), 0.0f, 1.0f), 1.0f));
		else
			c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f)));

		//subtract end
		if(((int)gmaxi) & 1)
			c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,0.0f, RI_CLAMP(1.0f - (gmax - gmaxi), 0.0f, 1.0f)));
		else
			c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f));
		break;
	}

	default:
	{
		RI_ASSERT(self->m_colorRampSpreadMode == VG_COLOR_RAMP_SPREAD_REPEAT);
		avg = KGPaintIntegrateColorRamp(self,0.0f, 1.0f);
		RIfloat gmini = (RIfloat)floor(gmin);
		RIfloat gmaxi = (RIfloat)floor(gmax);
		c = VGColorMultiplyByFloat(avg , (gmaxi + 1.0f - gmini));		//full ramps
		c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,0.0f, RI_CLAMP(gmin - gmini, 0.0f, 1.0f)));	//subtract beginning
		c=VGColorSubtract(c,KGPaintIntegrateColorRamp(self,RI_CLAMP(gmax - gmaxi, 0.0f, 1.0f), 1.0f));	//subtract end
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


@end
