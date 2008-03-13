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
#import "riMath.h"

typedef float CGFloat;

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
lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform antialias:(BOOL)antialias {
   OpenVGRI::Path *vgPath=[self buildDeviceSpacePath:path];

   OpenVGRI::PixelPipe pixelPipe;
   OpenVGRI::Rasterizer rasterizer;

   pixelPipe.setRenderingSurface(_image);

	try
	{
//		pixelPipe.setMask(context->m_masking ? context->getMask() : NULL);
   		pixelPipe.setBlendMode(blendMode);
//		pixelPipe.setTileFillColor(context->m_tileFillColor);
        if(interpolationQuality==kCGInterpolationDefault)
            pixelPipe.setImageQuality(kCGInterpolationHigh);
        else
            pixelPipe.setImageQuality(interpolationQuality);

       rasterizer.setViewport(0,0,_image->getWidth(),_image->getHeight());
       
       rasterizer.setShouldAntialias(antialias);
       
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
                
				rasterizer.fill(fillRule, pixelPipe);	//throws bad_alloc
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
				rasterizer.fill(VG_NON_ZERO,pixelPipe);	//throws bad_alloc
			}
		 }
        }
	}
	catch(std::bad_alloc)
	{
      NSLog(@"C++ exception, out of memory");
	}

}

-(void)drawBitmapImageRep:(NSBitmapImageRep *)imageRep antialias:(BOOL)antialias interpolationQuality:(CGInterpolationQuality)interpolationQuality blendMode:(CGBlendMode)blendMode fillColor:(CGColorRef)fillColor transform:(CGAffineTransform)xform {
	OpenVGRI::Image* img;

   OpenVGRI::Color::Descriptor descriptor=OpenVGRI::Color::formatToDescriptor(VG_lRGBA_8888);
   img=new OpenVGRI::Image(descriptor,[imageRep pixelsWide],[imageRep pixelsHigh],[imageRep bytesPerRow],(OpenVGRI::RIuint8 *)[imageRep bitmapData]);
   img->addReference();

	try
	{
    CGAffineTransform i2u=CGAffineTransformMakeTranslation(0,[imageRep pixelsHigh]);
i2u=CGAffineTransformScale(i2u,1,-1);

CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_pixelsHigh);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(i2u,xform);
xform=CGAffineTransformConcat(xform,u2d);
        OpenVGRI::Matrix3x3 imageUserToSurface=OpenVGRI::Matrix3x3(xform);

 // FIX, adjustable
        OpenVGRI::Matrix3x3 fillPaintToUser=OpenVGRI::Matrix3x3();
        
		//transform image corners into the surface space
		OpenVGRI::Vector3 p0(0, 0, 1);
		OpenVGRI::Vector3 p1(0, (CGFloat)img->getHeight(), 1);
		OpenVGRI::Vector3 p2((CGFloat)img->getWidth(), (CGFloat)img->getHeight(), 1);
		OpenVGRI::Vector3 p3((CGFloat)img->getWidth(), 0, 1);
		p0 = imageUserToSurface * p0;
		p1 = imageUserToSurface * p1;
		p2 = imageUserToSurface * p2;
		p3 = imageUserToSurface * p3;
		if(p0.z <= 0.0f || p1.z <= 0.0f || p2.z <= 0.0f || p3.z <= 0.0f)
		{
			return;
		}
		//projection
		p0 *= 1.0f/p0.z;
		p1 *= 1.0f/p1.z;
		p2 *= 1.0f/p2.z;
		p3 *= 1.0f/p3.z;

		OpenVGRI::Rasterizer rasterizer;

        rasterizer.setViewport(0, 0, _image->getWidth(), _image->getHeight());
        rasterizer.setShouldAntialias(antialias);

		OpenVGRI::PixelPipe pixelPipe;
		// pixelPipe.setTileFillColor(context->m_tileFillColor);
        pixelPipe.setPaint(paintFromColor(fillColor));
        if(interpolationQuality==kCGInterpolationDefault)
            pixelPipe.setImageQuality(kCGInterpolationHigh);
        else
            pixelPipe.setImageQuality(interpolationQuality);

		pixelPipe.setBlendMode(blendMode);

		//set up rendering surface and mask buffer
        pixelPipe.setRenderingSurface(_image);

//		pixelPipe.setMask(context->m_masking ? context->getMask() : NULL);

		OpenVGRI::Matrix3x3 surfaceToImageMatrix = imageUserToSurface;
		OpenVGRI::Matrix3x3 surfaceToPaintMatrix = imageUserToSurface * fillPaintToUser;
		if(surfaceToImageMatrix.invert() && surfaceToPaintMatrix.invert())
		{
			VGImageMode imode = VG_DRAW_IMAGE_NORMAL;
			if(!surfaceToPaintMatrix.isAffine())
				imode = VG_DRAW_IMAGE_NORMAL;	//if paint matrix is not affine, always use normal image mode
			pixelPipe.setImage(img, imode);
			pixelPipe.setSurfaceToPaintMatrix(surfaceToPaintMatrix);
			pixelPipe.setSurfaceToImageMatrix(surfaceToImageMatrix);

			rasterizer.addEdge(OpenVGRI::Vector2(p0.x,p0.y), OpenVGRI::Vector2(p1.x,p1.y));	//throws bad_alloc
			rasterizer.addEdge(OpenVGRI::Vector2(p1.x,p1.y), OpenVGRI::Vector2(p2.x,p2.y));	//throws bad_alloc
			rasterizer.addEdge(OpenVGRI::Vector2(p2.x,p2.y), OpenVGRI::Vector2(p3.x,p3.y));	//throws bad_alloc
			rasterizer.addEdge(OpenVGRI::Vector2(p3.x,p3.y), OpenVGRI::Vector2(p0.x,p0.y));	//throws bad_alloc
			rasterizer.fill(VG_EVEN_ODD, pixelPipe);	//throws bad_alloc
		}
	}
	catch(std::bad_alloc)
	{
     NSLog(@"out of memory %s %d",__FILE__,__LINE__);
	}
}

@end
