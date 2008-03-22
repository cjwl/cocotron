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
#import "VGPath.h"
#import "riMath.h"

typedef float CGFloat;

@implementation KGRender_baseline

-(void)buildImage {
   VGColorDescriptor descriptor=VGColor::formatToDescriptor(VG_lRGBA_8888_PRE);
   
   _image=new Image(descriptor,_pixelsWide,_pixelsHigh,_pixelsWide*4,(RIuint8 *)_data);
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
   VGPath *vgPath=( VGPath *)info;
   CGPoint *points=element->points;
   
   unsigned pointIndex=0;
   
   switch(element->type){

    case kCGPathElementMoveToPoint:{
      RIuint8 segment[1]={VG_MOVE_TO};
      RIfloat coords[2];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
       
      vgPath->appendData(segment,1,coords);
     }
     break;
       
    case kCGPathElementAddLineToPoint:{
      RIuint8 segment[1]={VG_LINE_TO};
      RIfloat coords[2];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
        
      vgPath->appendData(segment,1,coords);
     }
     break;

    case kCGPathElementAddCurveToPoint:{
      RIuint8 segment[1]={VG_CUBIC_TO};
      RIfloat coords[6];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
      coords[2]=points[pointIndex].x;
      coords[3]=points[pointIndex++].y;
      coords[4]=points[pointIndex].x;
      coords[5]=points[pointIndex++].y;
        
      vgPath->appendData(segment,1,coords);
     }
     break;

    case kCGPathElementAddQuadCurveToPoint:{
      RIuint8 segment[1]={VG_QUAD_TO};
      RIfloat coords[4];
       
      coords[0]=points[pointIndex].x;
      coords[1]=points[pointIndex++].y;
      coords[2]=points[pointIndex].x;
      coords[3]=points[pointIndex++].y;

      vgPath->appendData(segment,1,coords);
     }
     break;

    case kCGPathElementCloseSubpath:{
      RIuint8 segment[1]={VG_CLOSE_PATH};
      RIfloat coords[1];
       
      vgPath->appendData(segment,1,coords);
     }
     break;
   }
}

-(VGPath *)buildDeviceSpacePath:(CGPathRef)path {
   
   VGPath *vgPath=new VGPath(1,0,1,1);
   
   CGPathApply(path,vgPath,applyPath);

   return vgPath;
}

static KGPaint *paintFromColor(CGColorRef color){
   KGPaint *result=KGPaintInit(KGPaintAlloc());
   int    count=CGColorGetNumberOfComponents(color);
   const float *components=CGColorGetComponents(color);

   if(count==2)
    result->m_inputPaintColor.set(components[0],components[0],components[0],components[1],VGColor_sRGBA);
   if(count==4)
    result->m_inputPaintColor.set(components[0],components[1],components[2],components[3],VGColor_sRGBA);

   result->m_paintColor = result->m_inputPaintColor;
   result->m_paintColor.clamp();
   result->m_paintColor.premultiply();
   return result;
}

-(void)drawPath:(CGPathRef)path drawingMode:(CGPathDrawingMode)drawingMode blendMode:(CGBlendMode)blendMode interpolationQuality:(CGInterpolationQuality)interpolationQuality fillColor:(CGColorRef)fillColor strokeColor:(CGColorRef)strokeColor 
lineWidth:(float)lineWidth lineCap:(CGLineCap)lineCap lineJoin:(CGLineJoin)lineJoin miterLimit:(float)miterLimit dashPhase:(float)dashPhase dashLengthsCount:(unsigned)dashLengthsCount dashLengths:(float *)dashLengths transform:(CGAffineTransform)xform antialias:(BOOL)antialias {
   VGPath *vgPath=[self buildDeviceSpacePath:path];

   KGPixelPipe *pixelPipe=KGPixelPipeInit(KGPixelPipeAlloc());
   KGRasterizer *rasterizer=KGRasterizerInit(KGRasterizerAlloc());

   KGPixelPipeSetRenderingSurface(pixelPipe,_image);

	try
	{
//		KGPixelPipeSetMask(context->m_masking ? context->getMask() : NULL);
   		KGPixelPipeSetBlendMode(pixelPipe,blendMode);
//		KGPixelPipeSetTileFillColor(context->m_tileFillColor);
        if(interpolationQuality==kCGInterpolationDefault)
            KGPixelPipeSetImageQuality(pixelPipe,kCGInterpolationHigh);
        else
            KGPixelPipeSetImageQuality(pixelPipe,interpolationQuality);

       KGRasterizerSetViewport(rasterizer,0,0,_image->getWidth(),_image->getHeight());
       
       KGRasterizerSetShouldAntialias(rasterizer,antialias);
       
CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_pixelsHigh);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(xform,u2d);

		Matrix3x3 userToSurfaceMatrix=Matrix3x3(xform);// context->m_pathUserToSurface;
		userToSurfaceMatrix[2].set(0,0,1);		//force affinity

		if(drawingMode!=kCGPathStroke)
		{
			KGPixelPipeSetPaint(pixelPipe,paintFromColor(fillColor));

			Matrix3x3 surfaceToPaintMatrix =Matrix3x3(xform);//context->m_pathUserToSurface * context->m_fillPaintToUser;
			if(surfaceToPaintMatrix.invert())
			{
				surfaceToPaintMatrix[2].set(0,0,1);		//force affinity
				KGPixelPipeSetSurfaceToPaintMatrix(pixelPipe,surfaceToPaintMatrix);

				vgPath->fill(userToSurfaceMatrix,rasterizer);	//throws bad_alloc
                
                VGFillRule fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
				KGRasterizerFill(rasterizer,fillRule, pixelPipe);	//throws bad_alloc
			}
		}

		if(drawingMode>=kCGPathStroke){
         if(lineWidth > 0.0f){
			KGPixelPipeSetPaint(pixelPipe,paintFromColor(strokeColor));

			Matrix3x3 surfaceToPaintMatrix=Matrix3x3(xform);// = context->m_pathUserToSurface * context->m_strokePaintToUser;
			if(surfaceToPaintMatrix.invert())
			{
				surfaceToPaintMatrix[2].set(0,0,1);		//force affinity
				KGPixelPipeSetSurfaceToPaintMatrix(pixelPipe,surfaceToPaintMatrix);

				KGRasterizerClear(rasterizer);
                                 
				vgPath->stroke(userToSurfaceMatrix, rasterizer, dashLengths,dashLengthsCount, dashPhase, true /* context->m_strokeDashPhaseReset ? true : false*/,
									  lineWidth, lineCap,  lineJoin, RI_MAX(miterLimit, 1.0f));	//throws bad_alloc
				KGRasterizerFill(rasterizer,VG_NON_ZERO,pixelPipe);	//throws bad_alloc
			}
		 }
        }
	}
	catch(std::bad_alloc)
	{
      NSLog(@"C++ exception, out of memory");
	}
   KGRasterizerDealloc(rasterizer);
   KGPixelPipeDealloc(pixelPipe);
}

-(void)drawBitmapImageRep:(NSBitmapImageRep *)imageRep antialias:(BOOL)antialias interpolationQuality:(CGInterpolationQuality)interpolationQuality blendMode:(CGBlendMode)blendMode fillColor:(CGColorRef)fillColor transform:(CGAffineTransform)xform {
	Image* img;

   VGColorDescriptor descriptor=VGColor::formatToDescriptor(VG_lRGBA_8888);
   img=new Image(descriptor,[imageRep pixelsWide],[imageRep pixelsHigh],[imageRep bytesPerRow],(RIuint8 *)[imageRep bitmapData]);
   img->addReference();

	try
	{
    CGAffineTransform i2u=CGAffineTransformMakeTranslation(0,[imageRep pixelsHigh]);
i2u=CGAffineTransformScale(i2u,1,-1);

CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_pixelsHigh);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(i2u,xform);
xform=CGAffineTransformConcat(xform,u2d);
        Matrix3x3 imageUserToSurface=Matrix3x3(xform);

 // FIX, adjustable
        Matrix3x3 fillPaintToUser=Matrix3x3();
        
		//transform image corners into the surface space
		Vector3 p0(0, 0);
		Vector3 p1(0, (CGFloat)img->getHeight());
		Vector3 p2((CGFloat)img->getWidth(), (CGFloat)img->getHeight());
		Vector3 p3((CGFloat)img->getWidth(), 0);
		p0 = imageUserToSurface * p0;
		p1 = imageUserToSurface * p1;
		p2 = imageUserToSurface * p2;
		p3 = imageUserToSurface * p3;
		if(p0.z <= 0.0f || p1.z <= 0.0f || p2.z <= 0.0f || p3.z <= 0.0f)
		{
			return;
		}
		//projection
		p0=Vector3MultiplyByFloat(p0,1.0f/p0.z);
		p1=Vector3MultiplyByFloat(p1,1.0f/p1.z);
		p2=Vector3MultiplyByFloat(p2,1.0f/p2.z);
		p3=Vector3MultiplyByFloat(p3,1.0f/p3.z);

        KGRasterizer *rasterizer=KGRasterizerInit(KGRasterizerAlloc());

        KGRasterizerSetViewport(rasterizer,0, 0, _image->getWidth(), _image->getHeight());
        KGRasterizerSetShouldAntialias(rasterizer,antialias);

        KGPixelPipe *pixelPipe=KGPixelPipeInit(KGPixelPipeAlloc());
		// KGPixelPipeSetTileFillColor(context->m_tileFillColor);
        KGPixelPipeSetPaint(pixelPipe,paintFromColor(fillColor));
        if(interpolationQuality==kCGInterpolationDefault)
            KGPixelPipeSetImageQuality(pixelPipe,kCGInterpolationHigh);
        else
            KGPixelPipeSetImageQuality(pixelPipe,interpolationQuality);

		KGPixelPipeSetBlendMode(pixelPipe,blendMode);

		//set up rendering surface and mask buffer
        KGPixelPipeSetRenderingSurface(pixelPipe,_image);

//		KGPixelPipeSetMask(context->m_masking ? context->getMask() : NULL);

		Matrix3x3 surfaceToImageMatrix = imageUserToSurface;
		Matrix3x3 surfaceToPaintMatrix = imageUserToSurface * fillPaintToUser;
		if(surfaceToImageMatrix.invert() && surfaceToPaintMatrix.invert())
		{
			VGImageMode imode = VG_DRAW_IMAGE_NORMAL;
			if(!surfaceToPaintMatrix.isAffine())
				imode = VG_DRAW_IMAGE_NORMAL;	//if paint matrix is not affine, always use normal image mode
			KGPixelPipeSetImage(pixelPipe,img, imode);
			KGPixelPipeSetSurfaceToPaintMatrix(pixelPipe,surfaceToPaintMatrix);
			KGPixelPipeSetSurfaceToImageMatrix(pixelPipe,surfaceToImageMatrix);

			KGRasterizerAddEdge(rasterizer,Vector2(p0.x,p0.y), Vector2(p1.x,p1.y));	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,Vector2(p1.x,p1.y), Vector2(p2.x,p2.y));	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,Vector2(p2.x,p2.y), Vector2(p3.x,p3.y));	//throws bad_alloc
			KGRasterizerAddEdge(rasterizer,Vector2(p3.x,p3.y), Vector2(p0.x,p0.y));	//throws bad_alloc
			KGRasterizerFill(rasterizer,VG_EVEN_ODD, pixelPipe);	//throws bad_alloc
		}
   KGRasterizerDealloc(rasterizer);
   KGPixelPipeDealloc(pixelPipe);
	}
	catch(std::bad_alloc)
	{
     NSLog(@"out of memory %s %d",__FILE__,__LINE__);
	}
}

@end
