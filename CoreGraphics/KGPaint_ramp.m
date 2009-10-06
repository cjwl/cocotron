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
#import "KGShading.h"
#import "O2ColorSpace.h"
#import "KGFunction.h"

@implementation O2Paint_ramp

static inline void GrayAToRGBA(float *input,float *output){
   output[0]=input[0];
   output[1]=input[0];
   output[2]=input[0];
   output[3]=input[1];
}

static inline void RGBAToRGBA(float *input,float *output){
   output[0]=input[0];
   output[1]=input[1];
   output[2]=input[2];
   output[3]=input[3];
}

static inline void CMYKAToRGBA(float *input,float *output){
   float white=1-input[3];
   
   output[0]=(input[0]>white)?0:white-input[0];
   output[1]=(input[1]>white)?0:white-input[1];
   output[2]=(input[2]>white)?0:white-input[2];
   output[3]=input[4];
}

-initWithShading:(KGShading *)shading deviceTransform:(CGAffineTransform)deviceTransform numberOfSamples:(int)numberOfSamples {
   m_surfaceToPaintMatrix=CGAffineTransformInvert(deviceTransform);
   
   _startPoint=[shading startPoint];
   _endPoint=[shading endPoint];
   _extendStart=[shading extendStart];
   _extendEnd=[shading extendEnd];
   
   O2Function      *function=[shading function];
   O2ColorSpace    *colorSpace=[shading colorSpace];
   O2ColorSpaceType colorSpaceType=[colorSpace type];
   float            output[[colorSpace numberOfComponents]+1];
   void           (*outputToRGBA)(float *,float *);
   float            rgba[4];

   switch(colorSpaceType){

    case O2ColorSpaceDeviceGray:
     outputToRGBA=GrayAToRGBA;
     break;
     
    case O2ColorSpaceDeviceRGB:
    case O2ColorSpacePlatformRGB:
     outputToRGBA=RGBAToRGBA;
     break;
     
    case O2ColorSpaceDeviceCMYK:
     outputToRGBA=CMYKAToRGBA;
     break;
     
    default:
     NSLog(@"shading can't deal with colorspace %@",colorSpace);
     return nil;
   }

   _numberOfColorStops=numberOfSamples;
   
   _colorStops=NSZoneMalloc(NULL,_numberOfColorStops*sizeof(GradientStop));
   int i;
   for(i=0;i<_numberOfColorStops;i++){
    _colorStops[i].offset=(CGFloat)i/(CGFloat)(_numberOfColorStops-1);

// FIXME: This assumes range=0..1, we need to map this to the functions range

    O2FunctionEvaluate(function,_colorStops[i].offset,output);
    outputToRGBA(output,rgba);
    
    _colorStops[i].color=KGRGBAffffPremultiply(KGRGBAffffInit(rgba[0],rgba[1],rgba[2],rgba[3]));
   }

   return self;
}

-(void)dealloc {
   if(_colorStops!=NULL)
    NSZoneFree(NULL,_colorStops);
   
   [super dealloc];
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns the average color within an offset range in the color ramp.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static KGRGBAffff readStopColor(GradientStop *colorRampStops,int colorRampStopsCount, int i)
{
	RI_ASSERT(i >= 0 && i < colorRampStopsCount);
	return  colorRampStops[i].color;
}

KGRGBAffff O2PaintIntegrateColorRamp(O2Paint_ramp *self,CGFloat gmin, CGFloat gmax) { 
	RI_ASSERT(gmin <= gmax);
	RI_ASSERT(gmin >= 0.0f && gmin <= 1.0f);
	RI_ASSERT(gmax >= 0.0f && gmax <= 1.0f);
	RI_ASSERT(self->_numberOfColorStops >= 2);	//there are at least two stops

	KGRGBAffff c=KGRGBAffffInit(0,0,0,0);
	if(gmin == 1.0f || gmax == 0.0f)
		return c;

	int i=floor(gmin*(self->_numberOfColorStops-1));
	for(;i<self->_numberOfColorStops-1;i++)
	{
		if(gmin >= self->_colorStops[i].offset && gmin < self->_colorStops[i+1].offset)
		{
			CGFloat s = self->_colorStops[i].offset;
			CGFloat e = self->_colorStops[i+1].offset;
			RI_ASSERT(s < e);
			CGFloat g = (gmin - s) / (e - s);

			KGRGBAffff sc = readStopColor(self->_colorStops,self->_numberOfColorStops, i);
			KGRGBAffff ec = readStopColor(self->_colorStops,self->_numberOfColorStops, i+1);
			KGRGBAffff rc = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(sc, (1.0f-g)),KGRGBAffffMultiplyByFloat(ec , g));

			//subtract the average color from the start of the stop to gmin
			c=KGRGBAffffSubtract(c,KGRGBAffffMultiplyByFloat(KGRGBAffffAdd(sc,rc) , 0.5f*(gmin - s)));
			break;
		}
	}

	for(;i<self->_numberOfColorStops-1;i++)
	{
		CGFloat s = self->_colorStops[i].offset;
		CGFloat e = self->_colorStops[i+1].offset;
		RI_ASSERT(s <= e);

		KGRGBAffff sc = readStopColor(self->_colorStops,self->_numberOfColorStops, i);
		KGRGBAffff ec = readStopColor(self->_colorStops,self->_numberOfColorStops, i+1);

		//average of the stop
		c=KGRGBAffffAdd(c , KGRGBAffffMultiplyByFloat(KGRGBAffffAdd(sc , ec), 0.5f*(e-s)));

		if(gmax >= self->_colorStops[i].offset && gmax < self->_colorStops[i+1].offset)
		{
			CGFloat g = (gmax - s) / (e - s);
			KGRGBAffff rc = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(sc , (1.0f-g)),KGRGBAffffMultiplyByFloat( ec , g));

			//subtract the average color from gmax to the end of the stop
			c=KGRGBAffffSubtract(c,KGRGBAffffMultiplyByFloat(KGRGBAffffAdd(rc , ec) , 0.5f*(e - gmax)));
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

KGRGBAffff O2PaintColorRamp(O2Paint_ramp *self,CGFloat gradient, CGFloat rho,int *skip)  {
	RI_ASSERT(self);
	RI_ASSERT(rho >= 0.0f);

	KGRGBAffff c=KGRGBAffffInit(0,0,0,0);

	if(rho == 0.0f)
	{	//filter size is zero or gradient is degenerate

			gradient = RI_CLAMP(gradient, 0.0f, 1.0f);

        int i;
		for(i=0;i<self->_numberOfColorStops-1;i++)
		{
			if(gradient >= self->_colorStops[i].offset && gradient < self->_colorStops[i+1].offset)
			{
				CGFloat s = self->_colorStops[i].offset;
				CGFloat e = self->_colorStops[i+1].offset;
				RI_ASSERT(s < e);
				CGFloat g = RI_CLAMP((gradient - s) / (e - s), 0.0f, 1.0f);	//clamp needed due to numerical inaccuracies

				KGRGBAffff sc = readStopColor(self->_colorStops,self->_numberOfColorStops, i);
				KGRGBAffff ec = readStopColor(self->_colorStops,self->_numberOfColorStops, i+1);
				return KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(sc , (1.0f-g)) , KGRGBAffffMultiplyByFloat(ec , g));	//return interpolated value
			}
		}
		return readStopColor(self->_colorStops,self->_numberOfColorStops, self->_numberOfColorStops-1);
	}

	CGFloat gmin = gradient - rho*0.5f;			//filter starting from the gradient point (if starts earlier, radial gradient center will be an average of the first and the last stop, which doesn't look good)
	CGFloat gmax = gradient + rho*0.5f;

    if(gmin<0.0f){
     *skip=0;
    }
    if(gmax>1.0f){
     *skip=0;
    }
		if(gmin < 0.0f)
			c=KGRGBAffffAdd(c,KGRGBAffffMultiplyByFloat(readStopColor(self->_colorStops,self->_numberOfColorStops, 0), (RI_MIN(gmax, 0.0f) - gmin)));
		if(gmax > 1.0f)
			c=KGRGBAffffAdd(c,KGRGBAffffMultiplyByFloat(readStopColor(self->_colorStops,self->_numberOfColorStops, self->_numberOfColorStops-1) , (gmax - RI_MAX(gmin, 1.0f))));
		gmin = RI_CLAMP(gmin, 0.0f, 1.0f);
		gmax = RI_CLAMP(gmax, 0.0f, 1.0f);
		c=KGRGBAffffAdd(c, O2PaintIntegrateColorRamp(self,gmin, gmax));
		c=KGRGBAffffMultiplyByFloat(c , 1.0f/rho);
		c=KGRGBAffffClamp(c);	//clamp needed due to numerical inaccuracies
		return c;

}


@end
