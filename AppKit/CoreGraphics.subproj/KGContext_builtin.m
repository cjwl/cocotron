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
#import "KGContext_builtin.h"
#import "KGMutablePath.h"
#import "KGImage.h"
#import "KGColor.h"
#import "KGSurface.h"
#import "KGExceptions.h"
#import "KGRasterizer.h"
#import "KGGraphicsState.h"
#import "VGPath.h"
#import "KGPaint_image.h"
#import "KGPaint_color.h"

@implementation KGContext_builtin

BOOL _isAvailable=NO;

+(void)initialize {
   _isAvailable=[[NSUserDefaults standardUserDefaults] boolForKey:@"CGEnableBuiltin"];
}

+(BOOL)isAvailable {
   return _isAvailable;
}

+(BOOL)canInitBitmap {
   return YES;
}

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo {
   if([super initWithBytes:bytes width:width height:height bitsPerComponent:bitsPerComponent bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo]==nil)
    return nil;

   size_t bitsPerPixel=bitsPerComponent*[colorSpace numberOfComponents];
   switch(_bitmapInfo&kCGBitmapAlphaInfoMask){
   
    case kCGImageAlphaNone:
     break;
     
    case kCGImageAlphaPremultipliedLast:
     bitsPerPixel+=_bitsPerComponent;
     break;

    case kCGImageAlphaPremultipliedFirst:
     bitsPerPixel+=_bitsPerComponent;
     break;

    case kCGImageAlphaLast:
     bitsPerPixel+=_bitsPerComponent;
     break;

    case kCGImageAlphaFirst:
     bitsPerPixel+=_bitsPerComponent;
     break;

    case kCGImageAlphaNoneSkipLast:
     break;

    case kCGImageAlphaNoneSkipFirst:
     break;
   }
  
   _surface=KGSurfaceInitWithBytes(KGSurfaceAlloc(),_width,_height,bitsPerComponent,bitsPerPixel,bytesPerRow,colorSpace,bitmapInfo,VG_lRGBA_8888_PRE,_bytes);
   _rasterizer=KGRasterizerInit(KGRasterizerAlloc(),_surface);

   KGRasterizerSetViewport(_rasterizer,0,0,KGImageGetWidth(_surface),KGImageGetHeight(_surface));
   return self;
}

static void applyPath(void *info,const CGPathElement *element) {
   VGPath *vgPath=( VGPath *)info;
   CGPoint *points=element->points;
      
   switch(element->type){

    case kCGPathElementMoveToPoint:{
      RIuint8 segment[1]={kCGPathElementMoveToPoint};
       
       
      VGPathAppendData(vgPath,segment,1,points);
     }
     break;
       
    case kCGPathElementAddLineToPoint:{
      RIuint8 segment[1]={kCGPathElementAddLineToPoint};
        
      VGPathAppendData(vgPath,segment,1,points);
     }
     break;

    case kCGPathElementAddCurveToPoint:{
      RIuint8 segment[1]={kCGPathElementAddCurveToPoint};
        
      VGPathAppendData(vgPath,segment,1,points);
     }
     break;

    case kCGPathElementAddQuadCurveToPoint:{
      RIuint8 segment[1]={kCGPathElementAddQuadCurveToPoint};

      VGPathAppendData(vgPath,segment,1,points);
     }
     break;

    case kCGPathElementCloseSubpath:{
      RIuint8 segment[1]={kCGPathElementCloseSubpath};
       
      VGPathAppendData(vgPath,segment,1,points);
     }
     break;
   }
}

-(VGPath *)buildDeviceSpacePath:(KGPath *)path {
   
   VGPath *vgPath=VGPathInit(VGPathAlloc(),1,1);
   
   [path applyWithInfo:vgPath function:applyPath];

   return vgPath;
}

static KGPaint *paintFromColor(KGColor *color){
   int    count=[color numberOfComponents];
   const float *components=[color components];

   if(count==2)
    return [[KGPaint_color alloc] initWithGray:components[0]  alpha:components[1]];
   if(count==4)
    return [[KGPaint_color alloc] initWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
    
   return [[KGPaint_color alloc] initWithGray:0 alpha:1];
}

-(void)drawPath:(CGPathDrawingMode)drawingMode {
   VGPath *vgPath=[self buildDeviceSpacePath:_path];
   KGGraphicsState *gState=[self currentState];
   
//		KGRasterizeSetMask(context->m_masking ? context->getMask() : NULL);
   		KGRasterizeSetBlendMode(_rasterizer,gState->_blendMode);
//		KGRasterizeSetTileFillColor(context->m_tileFillColor);


       KGRasterizerSetShouldAntialias(_rasterizer,gState->_shouldAntialias);

//CGAffineTransform xform=CGAffineTransformIdentity;//gState->_userSpaceTransform;
CGAffineTransform xform=gState->_userSpaceTransform;
CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_height);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(xform,u2d);

		CGAffineTransform userToSurfaceMatrix=xform;// context->m_pathUserToSurface;


		if(drawingMode!=kCGPathStroke)
		{
            KGPaint *paint=paintFromColor(gState->_fillColor);
			KGRasterizeSetPaint(_rasterizer,paint);

			CGAffineTransform surfaceToPaintMatrix =xform;//context->m_pathUserToSurface * context->m_fillPaintToUser;
			if(Matrix3x3InplaceInvert(&surfaceToPaintMatrix))
			{
				KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

				VGPathFill(vgPath,userToSurfaceMatrix,_rasterizer);
                
                VGFillRule fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
				KGRasterizerFill(_rasterizer,fillRule);
			}
		}

		if(drawingMode>=kCGPathStroke){
         if(gState->_lineWidth > 0.0f){
            KGPaint *paint=paintFromColor(gState->_strokeColor);
			KGRasterizeSetPaint(_rasterizer,paint);

			CGAffineTransform surfaceToPaintMatrix=xform;// = context->m_pathUserToSurface * context->m_strokePaintToUser;
			if(Matrix3x3InplaceInvert(&surfaceToPaintMatrix))
			{
				KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

				KGRasterizerClear(_rasterizer);
                                 
				VGPathStroke(vgPath,userToSurfaceMatrix, _rasterizer, gState->_dashLengths,gState->_dashLengthsCount, gState->_dashPhase, YES /* context->m_strokeDashPhaseReset ? YES : NO*/,
									  gState->_lineWidth, gState->_lineCap,  gState->_lineJoin, RI_MAX(gState->_miterLimit, 1.0f));
				KGRasterizerFill(_rasterizer,VG_NON_ZERO);
			}
		 }
        }

   KGRasterizerClear(_rasterizer);
   [_path reset];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
  // KGInvalidAbstractInvocation();
}

-(void)drawShading:(KGShading *)shading {


   //KGInvalidAbstractInvocation();
}

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect {
   KGGraphicsState *gState=[self currentState];
   
    CGAffineTransform i2u=CGAffineTransformMakeTranslation(0,[image height]);
i2u=CGAffineTransformScale(i2u,1,-1);

CGAffineTransform xform=gState->_userSpaceTransform;
CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_height);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(i2u,xform);
xform=CGAffineTransformConcat(xform,u2d);
        CGAffineTransform imageUserToSurface=xform;

 // FIX, adjustable
        CGAffineTransform fillPaintToUser=CGAffineTransformIdentity;
        
		//transform image corners into the surface space
		CGPoint p0=CGPointMake(0, 0);
		CGPoint p1=CGPointMake(0, (CGFloat)KGImageGetHeight(image));
		CGPoint p2=CGPointMake((CGFloat)KGImageGetWidth(image), (CGFloat)KGImageGetHeight(image));
		CGPoint p3=CGPointMake((CGFloat)KGImageGetWidth(image), 0);
		p0 = Matrix3x3TransformVector2(imageUserToSurface , p0);
		p1 = Matrix3x3TransformVector2(imageUserToSurface , p1);
		p2 = Matrix3x3TransformVector2(imageUserToSurface , p2);
		p3 = Matrix3x3TransformVector2(imageUserToSurface , p3);


        KGRasterizerSetShouldAntialias(_rasterizer,gState->_shouldAntialias);

		// KGRasterizeSetTileFillColor(context->m_tileFillColor);
        KGPaint *paint=paintFromColor(gState->_fillColor);
        CGInterpolationQuality iq;
        if(gState->_interpolationQuality==kCGInterpolationDefault)
            iq=kCGInterpolationHigh;
        else
            iq=gState->_interpolationQuality;

        KGPaint *imagePaint=[[KGPaint_image alloc] initWithImage:image mode:VG_DRAW_IMAGE_NORMAL paint:paint interpolationQuality:iq];
        
        KGRasterizeSetPaint(_rasterizer,imagePaint);

		KGRasterizeSetBlendMode(_rasterizer,gState->_blendMode);

//		KGRasterizeSetMask(context->m_masking ? context->getMask() : NULL);

		CGAffineTransform surfaceToImageMatrix = imageUserToSurface;
		CGAffineTransform surfaceToPaintMatrix = CGAffineTransformConcat(imageUserToSurface,fillPaintToUser);
		if(Matrix3x3InplaceInvert(&surfaceToImageMatrix) && Matrix3x3InplaceInvert(&surfaceToPaintMatrix))
		{
			KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(imagePaint,surfaceToImageMatrix);

			KGRasterizerAddEdge(_rasterizer,CGPointMake(p0.x,p0.y), CGPointMake(p1.x,p1.y));
			KGRasterizerAddEdge(_rasterizer,CGPointMake(p1.x,p1.y), CGPointMake(p2.x,p2.y));
			KGRasterizerAddEdge(_rasterizer,CGPointMake(p2.x,p2.y), CGPointMake(p3.x,p3.y));
			KGRasterizerAddEdge(_rasterizer,CGPointMake(p3.x,p3.y), CGPointMake(p0.x,p0.y));
			KGRasterizerFill(_rasterizer,VG_EVEN_ODD);
        KGRasterizeSetPaint(_rasterizer,nil);
		}
   KGRasterizerClear(_rasterizer);

}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
   //KGInvalidAbstractInvocation();
}


-(void)deviceClipReset {
//   KGInvalidAbstractInvocation();
}

-(void)deviceClipToNonZeroPath:(KGPath *)path {
//   KGInvalidAbstractInvocation();
}

-(void)deviceClipToEvenOddPath:(KGPath *)path {
//   KGInvalidAbstractInvocation();
}

-(void)deviceClipToMask:(KGImage *)mask inRect:(CGRect)rect {
//   KGInvalidAbstractInvocation();
}

-(void)deviceSelectFontWithName:(const char *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
//   KGInvalidAbstractInvocation();
}

@end
