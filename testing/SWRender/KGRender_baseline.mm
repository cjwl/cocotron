/*
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
 */
 
#import "KGRender_baseline.h"
#import "riPath.h"

@implementation KGRender_baseline

-(void)buildImage {
   OpenVGRI::Color::Descriptor descriptor=OpenVGRI::Color::formatToDescriptor(VG_lRGBA_8888_PRE);
   
   _image=new OpenVGRI::Image(descriptor,_pixelsWide,_pixelsHigh,_pixelsWide*4,(OpenVGRI::RIuint8 *)_data);
   _image->addReference();
}

-init {
   [super init];
   [self buildImage];
   return self;
}

-(void)setSize:(NSSize)size {
   [super setSize:size];
   [self buildImage];
}

static void applyPath(void *info,const CGPathElement *element) {
   OpenVGRI::Path *vgPath=( OpenVGRI::Path *)info;
   CGPoint *points=element->points;
   
   unsigned pointIndex=0;
   
   switch(element->type){

    case kCGPathElementMoveToPoint:{
      VGubyte segment[1]={VG_MOVE_TO};
      VGfloat coords[2];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
       
      vgPath->appendData(segment,1,(OpenVGRI::RIuint8*)coords);
     }
     break;
       
    case kCGPathElementAddLineToPoint:{
      VGubyte segment[1]={VG_LINE_TO};
      VGfloat coords[2];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
        
      vgPath->appendData(segment,1,(OpenVGRI::RIuint8*)coords);
     }
     break;

    case kCGPathElementAddCurveToPoint:{
      VGubyte segment[1]={VG_CUBIC_TO};
      VGfloat coords[6];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
      coords[2]=points[pointIndex].x;
      coords[3]=points[pointIndex++].y;
      coords[4]=points[pointIndex].x;
      coords[5]=points[pointIndex++].y;
        
      vgPath->appendData(segment,1,(OpenVGRI::RIuint8*)coords);
     }
     break;

    case kCGPathElementAddQuadCurveToPoint:{
      VGubyte segment[1]={VG_QUAD_TO};
      VGfloat coords[4];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
      coords[2]=points[pointIndex].x;
      coords[3]=points[pointIndex++].y;

      vgPath->appendData(segment,1,(OpenVGRI::RIuint8*)coords);
     }
     break;

    case kCGPathElementCloseSubpath:{
      VGubyte segment[1]={VG_CLOSE_PATH};
      VGfloat coords[1];
       
      vgPath->appendData(segment,1,(OpenVGRI::RIuint8*)coords);
     }
     break;
   }
}

-(OpenVGRI::Path *)buildDeviceSpacePath:(CGPathRef)path {
   
   OpenVGRI::Path *vgPath=
   new OpenVGRI::Path(VG_PATH_FORMAT_STANDARD,1,0,1,1);
   vgPath->addReference();
   
   CGPathApply(path,vgPath,applyPath);

   return vgPath;
}

static OpenVGRI::Paint *paintFromColor(CGColorRef color){
   OpenVGRI::Paint *result=new OpenVGRI::Paint();
   int    count=CGColorGetNumberOfComponents(color);
   const float *components=CGColorGetComponents(color);

   if(count==2)
    result->m_inputPaintColor.set(components[0],components[0],components[0],components[1],OpenVGRI::Color::sRGBA);
   if(count==4)
    result->m_inputPaintColor.set(components[0],components[1],components[2],components[3],OpenVGRI::Color::sRGBA);

   result->m_paintColor = result->m_inputPaintColor;
   result->m_paintColor.clamp();
   result->m_paintColor.premultiply();
   return result;
}

-(void)drawPath:(CGPathRef)path drawingMode:(CGPathDrawingMode)drawingMode blendMode:(CGBlendMode)blendMode interpolationQuality:(CGInterpolationQuality)interpolationQuality fillColor:(CGColorRef)fillColor strokeColor:(CGColorRef)strokeColor 
lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform {
   OpenVGRI::Path *vgPath=[self buildDeviceSpacePath:path];

   OpenVGRI::PixelPipe pixelPipe;
   OpenVGRI::Rasterizer rasterizer;

   pixelPipe.setRenderingSurface(_image);

	try
	{
//		if(context->m_scissoring)
//			_rasterizer.setScissor(context->m_scissor);	//throws bad_alloc

//		pixelPipe.setMask(context->m_masking ? context->getMask() : NULL);
   		pixelPipe.setBlendMode(blendMode);
//		pixelPipe.setTileFillColor(context->m_tileFillColor);
        if(interpolationQuality==kCGInterpolationDefault)
            pixelPipe.setImageQuality(kCGInterpolationHigh);
        else
            pixelPipe.setImageQuality(interpolationQuality);

CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_pixelsHigh);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(xform,u2d);

		OpenVGRI::Matrix3x3 userToSurfaceMatrix=OpenVGRI::Matrix3x3(xform);// context->m_pathUserToSurface;
		userToSurfaceMatrix[2].set(0,0,1);		//force affinity

		if(drawingMode!=kCGPathStroke)
		{
			pixelPipe.setPaint(paintFromColor(fillColor));

			OpenVGRI::Matrix3x3 surfaceToPaintMatrix =OpenVGRI::Matrix3x3(xform);//context->m_pathUserToSurface * context->m_fillPaintToUser;
			if(surfaceToPaintMatrix.invert())
			{
				surfaceToPaintMatrix[2].set(0,0,1);		//force affinity
				pixelPipe.setSurfaceToPaintMatrix(surfaceToPaintMatrix);

				vgPath->fill(userToSurfaceMatrix,rasterizer);	//throws bad_alloc
                
                VGFillRule fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
				rasterizer.fill(0, 0, _image->getWidth(), _image->getHeight(), fillRule, VG_RENDERING_QUALITY_BETTER, pixelPipe);	//throws bad_alloc
			}
		}

		if(drawingMode>=kCGPathStroke){
         if(lineWidth > 0.0f){
			pixelPipe.setPaint(paintFromColor(strokeColor));

			OpenVGRI::Matrix3x3 surfaceToPaintMatrix=OpenVGRI::Matrix3x3(xform);// = context->m_pathUserToSurface * context->m_strokePaintToUser;
			if(surfaceToPaintMatrix.invert())
			{
				surfaceToPaintMatrix[2].set(0,0,1);		//force affinity
				pixelPipe.setSurfaceToPaintMatrix(surfaceToPaintMatrix);

				rasterizer.clear();
                                 
				vgPath->stroke(userToSurfaceMatrix, rasterizer, dashLengths,dashLengthsCount, dashPhase, true /* context->m_strokeDashPhaseReset ? true : false*/,
									  lineWidth, lineCap,  lineJoin, OpenVGRI::RI_MAX(miterLimit, 1.0f));	//throws bad_alloc
				rasterizer.fill(0, 0, _image->getWidth(), _image->getHeight(), VG_NON_ZERO, VG_RENDERING_QUALITY_BETTER,pixelPipe);	//throws bad_alloc
			}
		 }
        }
	}
	catch(std::bad_alloc)
	{
      NSLog(@"C++ exception, out of memory");
	}

}

@end
