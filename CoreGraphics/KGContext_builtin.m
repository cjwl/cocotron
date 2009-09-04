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
#import "O2MutablePath.h"
#import "KGImage.h"
#import "O2Color.h"
#import "KGSurface.h"
#import "KGExceptions.h"
#import "KGGraphicsState.h"
#import "VGPath.h"
#import "KGPaint_image.h"
#import "KGPaint_color.h"
#import "KGPaint_axialGradient.h"
#import "KGPaint_radialGradient.h"
#import "KGBlending.h"
#import "KGShading.h"

#define MAX_SAMPLES     COVERAGE_MULTIPLIER

void O2DContextClipAndFillEdges(KGRasterizer *self,int fillRuleMask);

@implementation KGContext_builtin

static BOOL _isAvailable=NO;

+(void)initialize {
   _isAvailable=[[NSUserDefaults standardUserDefaults] boolForKey:@"CGEnableBuiltin"];
}

+(BOOL)canInitBitmap {
   return _isAvailable;
}

+(BOOL)canInitBackingWithContext:(KGContext *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   NSString *name=[deviceDictionary objectForKey:@"CGContext"];

   if(name==nil)
    return _isAvailable;
    
   if([name isEqual:@"Onyx"])
    return YES;
    
   return NO;
}

-(void)reallocateForSurface {
   size_t width=KGImageGetWidth(_surface);
   
    free(self->_winding);
    // +1 is so we can modify the the next winding value without a bounds check
    self->_winding=calloc((width*MAX_SAMPLES)+1,sizeof(int));
    free(self->_increase);
    self->_increase=malloc(width*sizeof(int));
    int i;
    for(i=0;i<width;i++)
     self->_increase[i]=INT_MAX;
}


-initWithSurface:(KGSurface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
        
   _clipContext=nil;
   _paint=[[KGPaint_color alloc] initWithGray:0 alpha:1];

   KGRasterizeSetBlendMode(self,kCGBlendModeNormal);

   _vpwidth=self->_vpheight=0;
   
   _edgeCount=0;
   _edgeCapacity=256;
   _edges=NSZoneMalloc(NULL,self->_edgeCapacity*sizeof(Edge *));
   _sortCache=NSZoneMalloc(NULL,(self->_edgeCapacity/2 + 1)*sizeof(Edge *));
   
   samplesX=NSZoneMalloc(NULL,MAX_SAMPLES*sizeof(CGFloat));

   KGRasterizerSetViewport(self,0,0,KGImageGetWidth(_surface),KGImageGetHeight(_surface));
   [self reallocateForSurface];
   return self;
}

-initWithSize:(CGSize)size context:(KGContext *)context {
   KGSurface *surface=[context createSurfaceWithWidth:size.width height:size.height];
   
   if(surface==nil){
    [self dealloc];
    return nil;
   }
   
   [self initWithSurface:surface flipped:NO];
   
   [surface release];
   
   return self;
}

-(void)dealloc {
   [_clipContext release];
   [_paint release];
   
   int i;
   for(i=0;i<_edgeCount;i++)
    NSZoneFree(NULL,_edges[i]);

   NSZoneFree(NULL,_edges);
   NSZoneFree(NULL,_sortCache);
   
   free(_winding);
   free(_increase);
   
   NSZoneFree(NULL,samplesX);
   
   [super dealloc];
}

-(KGSurface *)surface {
   return _surface;
}

-(void)setWidth:(size_t)width height:(size_t)height reallocateOnlyIfRequired:(BOOL)roir {
   [_surface setWidth:width height:height reallocateOnlyIfRequired:roir];
   [self reallocateForSurface];
   KGRasterizerSetViewport(self,0,0,KGImageGetWidth(_surface),KGImageGetHeight(_surface));
   CGAffineTransform flip={1,0,0,-1,0,[_surface height]};
   [[self currentState] setDeviceSpaceCTM:flip];
}

-(void)deviceClipReset {
   KGRasterizerSetViewport(self,0,0,KGImageGetWidth(_surface),KGImageGetHeight(_surface));
}

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   O2MutablePath *copy=[path mutableCopy];
    
   O2PathApplyTransform(copy,CGAffineTransformInvert([self currentState]->_userSpaceTransform));
   O2PathApplyTransform(copy,[self currentState]->_deviceSpaceTransform);
   CGRect rect=O2PathGetBoundingBox(copy);
   
   [copy release];
   
   _vpx=MAX(rect.origin.x,0);
   _vpwidth=MIN(KGImageGetWidth(_surface),CGRectGetMaxX(rect))-_vpx;
   _vpy=MAX(rect.origin.y,0);
   _vpheight=MIN(KGImageGetHeight(_surface),CGRectGetMaxY(rect))-_vpy;
}

static KGPaint *paintFromColor(O2Color *color){
   size_t    count=O2ColorGetNumberOfComponents(color);
   const float *components=O2ColorGetComponents(color);

   if(count==2)
    return [[KGPaint_color alloc] initWithGray:components[0]  alpha:components[1]];
   if(count==4)
    return [[KGPaint_color alloc] initWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
    
   return [[KGPaint_color alloc] initWithGray:0 alpha:1];
}

-(void)drawPath:(CGPathDrawingMode)drawingMode {
   KGGraphicsState *gState=[self currentState];
   
   KGRasterizeSetBlendMode(self,gState->_blendMode);

   KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

/* Path construction is affected by the CTM, and the stroke pen is affected by the CTM , this means path points and the stroke can be affected by different transforms as the CTM can change during path construction and before stroking. For example, creation of transformed shapes which are drawn using an untransformed pen. The current tesselator expects everything to be in user coordinates and it tesselates from there into device space, but the path points are already in base coordinates. So, path points are brought from base coordinates into the active coordinate space using an inverted transform and then everything is tesselated using the CTM into device space.  */
 
   CGAffineTransform userToSurfaceMatrix=gState->_deviceSpaceTransform;

   O2PathApplyTransform(_path,CGAffineTransformInvert(gState->_userSpaceTransform));
   VGPath *vgPath=[[VGPath alloc] initWithKGPath:_path];

   if(drawingMode!=kCGPathStroke){
    KGPaint *paint=paintFromColor(gState->_fillColor);
    O2DContextSetPaint(self,paint);
    [paint release];
    
    CGAffineTransform surfaceToPaintMatrix =userToSurfaceMatrix;//context->m_pathUserToSurface * context->m_fillPaintToUser;
    
    surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
     KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

     VGPathFill(vgPath,userToSurfaceMatrix,self);
                
     VGFillRuleMask fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
     O2DContextClipAndFillEdges(self,fillRule);
   }

   if(drawingMode>=kCGPathStroke){
    if(gState->_lineWidth > 0.0f){
     KGPaint *paint=paintFromColor(gState->_strokeColor);
     O2DContextSetPaint(self,paint);
     [paint release];
     
     CGAffineTransform surfaceToPaintMatrix=userToSurfaceMatrix;// = context->m_pathUserToSurface * context->m_strokePaintToUser;

     surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
      KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

      KGRasterizerClear(self);
                                 
      VGPathStroke(vgPath,userToSurfaceMatrix, self, gState->_dashLengths,gState->_dashLengthsCount, gState->_dashPhase, YES /* context->m_strokeDashPhaseReset ? YES : NO*/,
        gState->_lineWidth, gState->_lineCap,  gState->_lineJoin, RI_MAX(gState->_miterLimit, 1.0f));
      O2DContextClipAndFillEdges(self,VG_NON_ZERO);
    }
   }

   O2DContextSetPaint(self,nil);
   [vgPath release];
   KGRasterizerClear(self);
   O2PathReset(_path);
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
  // KGInvalidAbstractInvocation();
}

-(void)drawShading:(KGShading *)shading {
   KGGraphicsState *gState=[self currentState];
   KGPaint         *paint;

   KGRasterizeSetBlendMode(self,gState->_blendMode);
   KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

   if([shading isAxial]){
    paint=[[KGPaint_axialGradient alloc] initWithShading:shading deviceTransform:gState->_deviceSpaceTransform];
   }
   else {
    paint=[[KGPaint_radialGradient alloc] initWithShading:shading deviceTransform:gState->_deviceSpaceTransform];
   }
  

   O2DContextSetPaint(self,paint);
   [paint release];

/* FIXME: If either extend is off we need to generate the bounding shape and clip to it, the paint classes generate alpha=0 for out of extend which
   is a problem for some blending ops, copy in particular.
 */
 
   O2DContextAddEdge(self,CGPointMake(0,0), CGPointMake(0,KGImageGetHeight(_surface)));
   O2DContextAddEdge(self,CGPointMake(KGImageGetWidth(_surface),0), CGPointMake(KGImageGetWidth(_surface),KGImageGetHeight(_surface)));

   O2DContextClipAndFillEdges(self,VG_NON_ZERO);
   KGRasterizerClear(self);
}

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect {
   KGGraphicsState *gState=[self currentState];
   
CGAffineTransform xform=CGAffineTransformMakeTranslation(rect.origin.x,rect.origin.y);
xform=CGAffineTransformScale(xform,rect.size.width/(CGFloat)[image width],rect.size.height/(CGFloat)[image height]);
xform=CGAffineTransformConcat(xform,gState->_deviceSpaceTransform);

CGAffineTransform i2u=CGAffineTransformMakeTranslation(0,(int)[image height]);
i2u=CGAffineTransformScale(i2u,1,-1);

xform=CGAffineTransformConcat(i2u,xform);

        CGAffineTransform imageUserToSurface=xform;

 // FIX, adjustable
        CGAffineTransform fillPaintToUser=CGAffineTransformIdentity;
        
		//transform image corners into the surface space
		CGPoint p0=CGPointMake(0, 0);
		CGPoint p1=CGPointMake(0, (CGFloat)KGImageGetHeight(image));
		CGPoint p2=CGPointMake((CGFloat)KGImageGetWidth(image), (CGFloat)KGImageGetHeight(image));
		CGPoint p3=CGPointMake((CGFloat)KGImageGetWidth(image), 0);
		p0 = CGPointApplyAffineTransform(p0,imageUserToSurface);
		p1 = CGPointApplyAffineTransform(p1,imageUserToSurface);
		p2 = CGPointApplyAffineTransform(p2,imageUserToSurface);
		p3 = CGPointApplyAffineTransform(p3,imageUserToSurface);


       KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

        KGPaint *paint=paintFromColor(gState->_fillColor);
        CGInterpolationQuality iq;
        if(gState->_interpolationQuality==kCGInterpolationDefault)
            iq=kCGInterpolationLow;
        else
            iq=gState->_interpolationQuality;

        KGPaint *imagePaint=[[KGPaint_image alloc] initWithImage:image mode:VG_DRAW_IMAGE_NORMAL paint:paint interpolationQuality:iq];
        
        O2DContextSetPaint(self,imagePaint);

        
		KGRasterizeSetBlendMode(self,gState->_blendMode);

		CGAffineTransform surfaceToImageMatrix = imageUserToSurface;
		CGAffineTransform surfaceToPaintMatrix = CGAffineTransformConcat(imageUserToSurface,fillPaintToUser);
        
        surfaceToImageMatrix=CGAffineTransformInvert(surfaceToImageMatrix);
        surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(imagePaint,surfaceToImageMatrix);

			O2DContextAddEdge(self,p0, p1);
			O2DContextAddEdge(self,p1, p2);
			O2DContextAddEdge(self,p2, p3);
			O2DContextAddEdge(self,p3, p0);
			O2DContextClipAndFillEdges(self,VG_EVEN_ODD);

        O2DContextSetPaint(self,nil);
        [paint release];
        [imagePaint release];

   KGRasterizerClear(self);
}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
   //KGInvalidAbstractInvocation();
}



-(void)deviceClipToEvenOddPath:(O2Path *)path {
//   KGInvalidAbstractInvocation();
}

-(void)deviceClipToMask:(KGImage *)mask inRect:(CGRect)rect {
//   KGInvalidAbstractInvocation();
}

void KGRasterizerSetViewport(KGRasterizer *self,int x,int y,int width,int height) {
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
    self->_vpx=x;
    self->_vpy=y;
    self->_vpwidth=width;
    self->_vpheight=height;
}

void KGRasterizerClear(KGRasterizer *self) {
   int i;
   for(i=0;i<self->_edgeCount;i++)
    NSZoneFree(NULL,self->_edges[i]);
    
   self->_edgeCount=0;   
}

void O2DContextAddEdge(KGRasterizer *self,const CGPoint v0, const CGPoint v1) {

	if(v0.y == v1.y)
		return;	//skip horizontal edges (they don't affect rasterization since we scan horizontally)

    if(v0.y<self->_vpy && v1.y<self->_vpy)  // ignore below miny
     return;
    
    int MaxY=self->_vpy+self->_vpheight;
    
    if(v0.y>=MaxY && v1.y>=MaxY) // ignore above maxy
     return;
         
	Edge *edge=NSZoneMalloc(NULL,sizeof(Edge));
    if(self->_edgeCount+1>=self->_edgeCapacity){
     self->_edgeCapacity*=2;
     self->_edges=NSZoneRealloc(NULL,self->_edges,self->_edgeCapacity*sizeof(Edge *));
     self->_sortCache=NSZoneRealloc(NULL,self->_sortCache,(self->_edgeCapacity/2 + 1)*sizeof(Edge *));
    }
    self->_edges[self->_edgeCount]=edge;
    self->_edgeCount++;
    
    if(v0.y < v1.y){	//edge is going upward
        edge->v0 = v0;
        edge->v1 = v1;
        edge->direction = 1;
    }
    else {	//edge is going downward
        edge->v0 = v1;
        edge->v1 = v0;
        edge->direction = -1;
    }

    edge->next=NULL;
}

// Returns a radical inverse of a given integer for Hammersley point set.
static double radicalInverseBase2(unsigned int i)
{
	if( i == 0 )
		return 0.0;
	double p = 0.0;
	double f = 0.5f;
	double ff = f;
    unsigned int j;
	for(j=0;j<32;j++)
	{
		if( i & (1<<j) )
			p += f;
		f *= ff;
	}
	return p;
}

void KGRasterizerSetShouldAntialias(KGRasterizer *self,BOOL antialias,int quality) {
 
	//make a sampling pattern

   quality=RI_INT_CLAMP(quality,1,MAX_SAMPLES);
   
   self->alias=(!antialias || quality==1)?YES:NO;
   
#if 0
   {
    self->numSamples=1;
			self->samplesX[0] = 0.5;
			self->samplesInitialY = 0.5;
			self->samplesDeltaY = 0;
			self->samplesWeight = MAX_SAMPLES;
   }
   else
#endif   
   {
    int shift;
    int numberOfSamples=1;
        
    for(shift=0;numberOfSamples<quality;shift++)
     numberOfSamples<<=1;

        self->sampleSizeShift=shift;
		self->numSamples = numberOfSamples;
        int i;

		 self->samplesInitialY = ((CGFloat)(0.5f)) / (CGFloat)numberOfSamples;
		 self->samplesDeltaY = ((CGFloat)(1.0f)) / (CGFloat)numberOfSamples;
        for(i=0;i<numberOfSamples;i++){
	     self->samplesX[i] = (CGFloat)radicalInverseBase2(i);
         self->samplesWeight=MAX_SAMPLES/numberOfSamples;
        }
    }
}

static void KGApplyCoverageAndMaskToSpan_lRGBAffff_PRE(KGRGBAffff *dst,int icoverage,CGFloat *mask,KGRGBAffff *src,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBAffff r=src[i];
    KGRGBAffff d=dst[i];
    CGFloat coverage=zeroToOneFromCoverage(icoverage);
    CGFloat cov=mask[i]*coverage;
     
    dst[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
   }
}

static void KGApplyCoverageToSpan_lRGBAffff_PRE(KGRGBAffff *dst,int icoverage,KGRGBAffff *src,int length){
   int i;
   CGFloat coverage=zeroToOneFromCoverage(icoverage);
   
   for(i=0;i<length;i++){
    KGRGBAffff r=src[i];
    KGRGBAffff d=dst[i];
     
    dst[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , coverage) , KGRGBAffffMultiplyByFloat(d , (1.0f - coverage)));
   }
}
         
static void KGApplyCoverageAndMaskToSpan_lRGBA8888_PRE(KGRGBA8888 *dst,int icoverage,uint8_t *mask,KGRGBA8888 *src,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA8888 r=src[i];
    KGRGBA8888 d=dst[i];
    int cov=(mask[i]*icoverage)/255;
    int oneMinusCov=inverseCoverage(cov);
     
    dst[i]=KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(r , cov) , KGRGBA8888MultiplyByCoverage(d , oneMinusCov));
   }
}

void KGApplyCoverageToSpan_lRGBA8888_PRE(KGRGBA8888 *dst,int coverage,KGRGBA8888 *src,int length){
   int i;
   
   if(coverage==256){   
    for(i=0;i<length;i++,src++,dst++){    
     *dst=*src;
    }
   }
   else {
    int oneMinusCoverage=inverseCoverage(coverage);
   
    for(i=0;i<length;i++,src++,dst++){
     KGRGBA8888 r=*src;
     KGRGBA8888 d=*dst;
    
     *dst=KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(r , coverage) , KGRGBA8888MultiplyByCoverage(d , oneMinusCoverage));
    }
   }
}

void KGBlendSpanNormal_8888_coverage(KGRGBA8888 *src,KGRGBA8888 *dst,int coverage,int length){
// Passes Visual Test
   int i;
   
   if(coverage==256){
    for(i=0;i<length;i++,src++,dst++){
     KGRGBA8888 s=*src;
     KGRGBA8888 d=*dst;
     KGRGBA8888 r;
    
     if(s.a==255)
      r=*src;
     else {
      unsigned char sa=255-s.a;

      r.r=RI_INT_MIN((int)s.r+alphaMultiply(d.r,sa),255);
      r.g=RI_INT_MIN((int)s.g+alphaMultiply(d.g,sa),255);
      r.b=RI_INT_MIN((int)s.b+alphaMultiply(d.b,sa),255);
      r.a=RI_INT_MIN((int)s.a+alphaMultiply(d.a,sa),255);
     }
     *dst=r;
    }
   }
   else {
    int oneMinusCoverage=inverseCoverage(coverage);

    for(i=0;i<length;i++,src++,dst++){
     KGRGBA8888 s=*src;
     KGRGBA8888 d=*dst;
     KGRGBA8888 r;
     unsigned char sa=255-s.a;
     
     r.r=RI_INT_MIN((int)s.r+alphaMultiply(d.r,sa),255);
     r.r=multiplyByCoverage(r.r,coverage);
     d.r=(d.r*oneMinusCoverage)/256;
     r.r=RI_INT_MIN((int)r.r+(int)d.r,255);
    
     r.g=RI_INT_MIN((int)s.g+alphaMultiply(d.g,sa),255);
     r.g=multiplyByCoverage(r.g,coverage);
     d.g=(d.g*oneMinusCoverage)/256;
     r.g=RI_INT_MIN((int)r.g+(int)d.g,255);
    
     r.b=RI_INT_MIN((int)s.b+alphaMultiply(d.b,sa),255);
     r.b=multiplyByCoverage(r.b,coverage);
     d.b=(d.b*oneMinusCoverage)/256;
     r.b=RI_INT_MIN((int)r.b+(int)d.b,255);
    
     r.a=RI_INT_MIN((int)s.a+alphaMultiply(d.a,sa),255);
     r.a=multiplyByCoverage(r.a,coverage);
     d.a=(d.a*oneMinusCoverage)/256;
     r.a=RI_INT_MIN((int)r.a+(int)d.a,255);
    
     *dst=r;
    }
   }
}

static void KGBlendSpanCopy_8888_coverage(KGRGBA8888 *src,KGRGBA8888 *dst,int coverage,int length){
// Passes Visual Test
   int i;

   if(coverage==256){
    for(i=0;i<length;i++)
     *dst++=*src++;
   }
   else {
    int oneMinusCoverage=256-coverage;

    for(i=0;i<length;i++,src++,dst++){
     KGRGBA8888 d=*dst;
     KGRGBA8888 r=*src;
    
     r.r=multiplyByCoverage(r.r,coverage);
     d.r=(d.r*oneMinusCoverage)/256;
     r.r=RI_INT_MIN((int)r.r+(int)d.r,255);
    
     r.g=multiplyByCoverage(r.g,coverage);
     d.g=(d.g*oneMinusCoverage)/256;
     r.g=RI_INT_MIN((int)r.g+(int)d.g,255);
    
     r.b=multiplyByCoverage(r.b,coverage);
     d.b=(d.b*oneMinusCoverage)/256;
     r.b=RI_INT_MIN((int)r.b+(int)d.b,255);
    
     r.a=multiplyByCoverage(r.a,coverage);
     d.a=(d.a*oneMinusCoverage)/256;
     r.a=RI_INT_MIN((int)r.a+(int)d.a,255);
     
     *dst=r;
    }
   }
}

static inline void KGRasterizeWriteCoverageSpan8888_Normal(KGSurface *surface,KGSurface *mask,KGPaint *paint,int x, int y,int coverage,int length,KGBlendSpan_RGBA8888 blendFunction) {
    KGRGBA8888 *dst=__builtin_alloca(length*sizeof(KGRGBA8888));
    KGRGBA8888 *direct=surface->_read_lRGBA8888_PRE(surface,x,y,dst,length);
   
    if(direct!=NULL)
     dst=direct;
     
    KGRGBA8888 src[length];
    KGPaintReadSpan_lRGBA8888_PRE(paint,x,y,src,length);

    KGBlendSpanNormal_8888_coverage(src,dst,coverage,length);
    // FIXME: doesnt handle mask if present

    if(direct==NULL){
  	//write result to the destination surface
     KGSurfaceWriteSpan_lRGBA8888_PRE(surface,x,y,dst,length);
    }
}


static inline void KGRasterizeWriteCoverageSpan8888_Copy(KGSurface *surface,KGSurface *mask,KGPaint *paint,int x, int y,int coverage,int length,KGBlendSpan_RGBA8888 blendFunction) {
    KGRGBA8888 *dst=__builtin_alloca(length*sizeof(KGRGBA8888));
    KGRGBA8888 *direct=surface->_read_lRGBA8888_PRE(surface,x,y,dst,length);
   
    if(direct!=NULL)
     dst=direct;
     
    KGRGBA8888 src[length];
    KGPaintReadSpan_lRGBA8888_PRE(paint,x,y,src,length);

    KGBlendSpanCopy_8888_coverage(src,dst,coverage,length);
    // FIXME: doesnt handle mask if present

    if(direct==NULL){
  	//write result to the destination surface
     KGSurfaceWriteSpan_lRGBA8888_PRE(surface,x,y,dst,length);
    }
}

static inline void KGRasterizeWriteCoverageSpan8888(KGSurface *surface,KGSurface *mask,KGPaint *paint,int x, int y,int coverage,int length,KGBlendSpan_RGBA8888 blendFunction) {
   KGRGBA8888 *dst=__builtin_alloca(length*sizeof(KGRGBA8888));
   KGRGBA8888 *direct=surface->_read_lRGBA8888_PRE(surface,x,y,dst,length);
   
   if(direct!=NULL)
    dst=direct;
     
   KGRGBA8888 src[length];
   KGPaintReadSpan_lRGBA8888_PRE(paint,x,y,src,length);

   blendFunction(src,dst,length);
    
   //apply masking
   if(mask==NULL)
    KGApplyCoverageToSpan_lRGBA8888_PRE(dst,coverage,src,length);
   else {
    uint8_t maskSpan[length];
     
    KGImageReadSpan_A8_MASK(mask,x,y,maskSpan,length);
    KGApplyCoverageAndMaskToSpan_lRGBA8888_PRE(dst,coverage,maskSpan,src,length);
   }

   if(direct==NULL){
  //write result to the destination surface
    KGSurfaceWriteSpan_lRGBA8888_PRE(surface,x,y,dst,length);
   }
}

static inline void KGRasterizeWriteCoverageSpanffff(KGSurface *surface,KGSurface *mask,KGPaint *paint,int x, int y,int coverage,int length,KGBlendSpan_RGBAffff blendFunction) {
    KGRGBAffff *dst=__builtin_alloca(length*sizeof(KGRGBAffff));
    KGRGBAffff *direct=KGImageReadSpan_lRGBAffff_PRE(surface,x,y,dst,length);

    if(direct!=NULL)
     dst=direct;

    KGRGBAffff src[length];
    KGPaintReadSpan_lRGBAffff_PRE(paint,x,y,src,length);
    
    blendFunction(src,dst,length);
    
	//apply masking
	if(mask==NULL)
     KGApplyCoverageToSpan_lRGBAffff_PRE(dst,coverage,src,length);
    else {
     CGFloat maskSpan[length];
     
     KGImageReadSpan_Af_MASK(mask,x,y,maskSpan,length);
     KGApplyCoverageAndMaskToSpan_lRGBAffff_PRE(dst,coverage,maskSpan,src,length);
    }
    
    if(direct==NULL){
  	//write result to the destination surface
     KGSurfaceWriteSpan_lRGBAffff_PRE(surface,x,y,dst,length);
    }
}

static inline void sortEdgesByMinY(Edge **edges,int count,Edge **B){
  int h, i, j, k, l, m, n = count;
  Edge  *A;

  for (h = 1; h < n; h += h)
  {
     for (m = n - 1 - h; m >= 0; m -= h + h)
     {
        l = m - h + 1;
        if (l < 0)
           l = 0;

        for (i = 0, j = l; j <= m; i++, j++)
           B[i] = edges[j];

        for (i = 0, k = l; k < j && j <= m + h; k++)
        {
           A = edges[j];
           if (A->v0.y>B[i]->v0.y)
              edges[k] = B[i++];
           else
           {
              edges[k] = A;
              j++;
           }
        }

        while (k < j)
           edges[k++] = B[i++];
     }
  }
}

static inline void initEdgeForAET(KGRasterizer *self,Edge *edge,int scany){
   //compute edge min and max x-coordinates for this scanline
   
   CGPoint vd = Vector2Subtract(edge->v1,edge->v0);
   CGFloat wl = 1.0f /vd.y;
   edge->vdxwl=vd.x*wl;

   if(edge->v0.x<edge->v1.x){
    edge->isVertical=0;
    edge->bminx=edge->v0.x;
    edge->bmaxx=edge->v1.x;
   }
   else {
    edge->isVertical=(edge->v0.x==edge->v1.x)?1:0;
    edge->bminx=edge->v1.x;
    edge->bmaxx=edge->v0.x;
   }
       
   edge->sxPre = edge->v0.x-(edge->v0.y*edge->vdxwl);
   edge->exPre=edge->sxPre;
   edge->sxPre+=(scany-1)*edge->vdxwl;
   edge->exPre+=(scany+1)*edge->vdxwl;

   CGFloat autosx = RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex  = RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
      
   edge->minx = MAX(self->_vpx,minx);
   edge->samples=NSZoneMalloc(NULL,sizeof(CGFloat)*self->numSamples);
   
   CGFloat *pre=edge->samples;
   int      i,numberOfSamples=self->numSamples;
   CGFloat  sampleY=self->samplesInitialY;
   CGFloat  deltaY=self->samplesDeltaY;
   CGFloat *samplesX=self->samplesX;
       
   CGFloat  normalX=edge->v0.y-edge->v1.y;
   CGFloat  normalY=edge->v0.x-edge->v1.x;
   CGFloat min=0,max=0;
       
   for(i=0;i<numberOfSamples;sampleY+=deltaY,samplesX++,i++){
    CGFloat value=sampleY*normalY-*samplesX*normalX;
        
    *pre++ = value;
        
    if(i==0)
     min=max=value;
    else {
     min=MIN(min,value);
     max=MAX(max,value);
    }
   }
   edge->minSample=min;
   edge->maxSample=max;
}

static inline void incrementEdgeForAET(Edge *edge,int vpx){
   edge->sxPre+= edge->vdxwl;
   edge->exPre+= edge->vdxwl;
   
   CGFloat autosx=RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex=RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
      
   edge->minx = MAX(vpx,minx);
}

static inline void removeEdgeFromAET(Edge *edge){
   NSZoneFree(NULL,edge->samples);
}

typedef struct CoverageNode {
   struct CoverageNode *next;
   int scanx;
   int coverage;
   int length;
} CoverageNode;

void O2DContextFillEdgesOnSurface(KGRasterizer *self,KGSurface *surface,KGImage *mask,KGPaint *paint,int fillRuleMask) {
   int    edgeCount=self->_edgeCount;
   Edge **edges=self->_edges;
      
   CoverageNode *freeCoverage=NULL;
   CoverageNode *currentCoverage=NULL;
   
   sortEdgesByMinY(edges,edgeCount,self->_sortCache);

   int ylimit=self->_vpy+self->_vpheight;
   int xlimit=self->_vpx+self->_vpwidth;

   Edge *activeRoot=NULL;
   int nextAvailableEdge=0;

   int scany;

   int *winding=self->_winding;
   int  numberOfSamples=self->numSamples;
   int  shiftNumberOfSamples=self->sampleSizeShift;
   int  totalActiveEdges=0;
   int  totalActiveVerticalEdgesFullCoverage=0;
   
   for(scany=self->_vpy;scany<ylimit;scany++){
    Edge *edge,*previous=NULL;
    int   unchangedActiveEdges=1;
    
    // increment and remove edges out of range
    for(edge=activeRoot;edge!=NULL;edge=edge->next){
     if(edge->v1.y>scany){
      incrementEdgeForAET(edge,self->_vpx);
      previous=edge;
      
      if(edge->isVertical){
       if(edge->v0.y<scany && edge->v1.y>=(scany+1)){
        if(!edge->isFullCoverage){
         edge->isFullCoverage=1;
         unchangedActiveEdges=0;
         totalActiveVerticalEdgesFullCoverage++;
        }
       }
       else {
        if(edge->isFullCoverage){
         edge->isFullCoverage=0;
         unchangedActiveEdges=0;
         totalActiveVerticalEdgesFullCoverage--;
        }
       }
      }
     }
     else {
      unchangedActiveEdges=0;
      
      totalActiveEdges--;
      if(edge->isVertical && edge->isFullCoverage)
       totalActiveVerticalEdgesFullCoverage--;
      
      removeEdgeFromAET(edge);
      if(previous==NULL)
       activeRoot=edge->next;
      else
       previous->next=edge->next;
     }
    }

     // load more available edges
    for(;nextAvailableEdge<edgeCount;nextAvailableEdge++){
     edge=edges[nextAvailableEdge];
        
     if(edge->v0.y>=(scany+1))
      break;
     
     unchangedActiveEdges=0;
     edge->next=activeRoot;
     activeRoot=edge;
     initEdgeForAET(self,edge,scany);
     totalActiveEdges++;
     
     if(edge->isVertical){
      if(edge->v0.y<scany && edge->v1.y>=(scany+1)){
       edge->isFullCoverage=1;
       totalActiveVerticalEdgesFullCoverage++;
      }
      else {
       edge->isFullCoverage=0;
      }
     }
    }

    if(unchangedActiveEdges){
     if(activeRoot==NULL && nextAvailableEdge==edgeCount)
      break;
      
     if(totalActiveVerticalEdgesFullCoverage==totalActiveEdges){
      CoverageNode *node;
      
      for(node=currentCoverage;node!=NULL;node=node->next)
       self->_writeCoverageFunction(surface,mask,paint,node->scanx,scany,node->coverage,node->length,self->_blendFunction);
       
      continue;
     }
    }
    
    int minx=xlimit,maxx=0;
    int *increase;

    for(edge=activeRoot;edge!=NULL;edge=edge->next){
     if(edge->minx>=xlimit){
      maxx=MAX(maxx,xlimit);
      continue;
     }

     CGFloat  deltaY=self->samplesDeltaY;
     CGFloat  scanFloatY=scany+self->samplesInitialY;
     CGFloat  v0y=edge->v0.y;
     CGFloat  v1y=edge->v1.y;

     int      belowY=0;
     int      aboveY;
       
     for(;scanFloatY<v0y && belowY<numberOfSamples;scanFloatY+=deltaY)
      belowY++;

     if(scany+1<v1y)
      aboveY=numberOfSamples;
     else {
      aboveY=belowY;
      for(;scanFloatY<v1y && aboveY<numberOfSamples;scanFloatY+=deltaY)
       aboveY++;
     }
      
      // it is possible for the edge to be inside the scanline a tiny bit and below/above first/last sample, skip it
     if(aboveY-belowY==0)
      continue;

     int direction=edge->direction;
     int scanx=edge->minx;
       
     minx=MIN(minx,scanx);

     CGFloat normalX=edge->v0.y-edge->v1.y;
     CGFloat normalY=edge->v0.x-edge->v1.x;
     CGFloat pcxnormal=(scanx-edge->v0.x)*normalX-(scany-edge->v0.y)*normalY;
        
     int *windptr=winding+(scanx<<shiftNumberOfSamples);
     increase=self->_increase;
            
     CGFloat *pre=edge->samples;
            
     for(;;pcxnormal+=normalX,windptr+=numberOfSamples){
      /*
        Some edges do have pcxnormal>edge->maxSample when the normalX is less than zero
        we should be able to eliminate that condition prior to the loop to avoid an iteration.
        
        For now they just end up in the general loop
       */
       
      if(increase[scanx]==INT_MAX)
       increase[scanx]=0;
                       
      if(pcxnormal<=edge->minSample){
        windptr[belowY]+=direction;
                                   
        if(aboveY!=numberOfSamples)
         windptr[aboveY]-=direction;
        else if(belowY==0){
         increase[scanx]+=direction;
         break;
        }
       }
       else {
        int idx=belowY;

         while(idx<aboveY){
          if(pcxnormal<=pre[idx]){
           windptr[idx]+=direction;
           windptr[idx+1]-=direction;
          }
                         
          idx++;
         }
          
        if(aboveY==numberOfSamples){
         // if we overwrote past the last value, undo it, this is cheaper than not writing it
         if(pcxnormal<=pre[idx-1])
          windptr[idx]+=direction;
        }
       }

      scanx++;
      if(scanx==xlimit)
       break;
     }

     maxx=MAX(maxx,scanx);

    }        
    minx=MAX(self->_vpx,minx);
    maxx=MIN(xlimit,maxx+1);
        
    increase=self->_increase;
    int *maxAdvance=increase+maxx;

    increase+=minx;
    for(;increase<maxAdvance;increase++)               
     if(*increase!=INT_MAX){
      break;
     }
         
 	int accum=0;

    int *windptr=winding+((increase-self->_increase)<<shiftNumberOfSamples);
    int *windend=windptr+numberOfSamples;
    
    CoverageNode *node;
    for(node=currentCoverage;node!=NULL;){
     CoverageNode *next=node->next;
     node->next=freeCoverage;
     freeCoverage=node;
     node=next;
    }
    currentCoverage=NULL;    

    for(;increase<maxAdvance;){
     int total=accum;
     int coverage=0;

     if(fillRuleMask==1){
      do{       
       total+=*windptr;
       
       coverage+=(total&0x01);

       *windptr++=0;
      }while(windptr<windend);
     }
     else {
      do{
       total+=*windptr;
       
       coverage+=total?1:0;

       *windptr++=0;
      }while(windptr<windend);
     }

     int *advance=increase+1;
     for(;advance<maxAdvance;advance++)
      if(*advance!=INT_MAX){
       break;
      }

	 if(coverage>0){

      if(self->alias)
       coverage=256;
      else
       coverage*=self->samplesWeight;
      
      int scanx=increase-self->_increase;
      
      CoverageNode *node;
      
      if(freeCoverage==NULL)
       node=NSZoneMalloc(NULL,sizeof(CoverageNode));
      else {
       node=freeCoverage;
       freeCoverage=freeCoverage->next;
      }
      node->next=currentCoverage;
      currentCoverage=node;
      node->scanx=scanx;
      node->coverage=coverage;
      node->length=(advance-increase);
     }
     
     windend+=(advance-increase)<<shiftNumberOfSamples;
     windptr=windend-numberOfSamples;

     accum+=*increase;
     *increase=INT_MAX;
     increase=advance;
    }
    
    for(node=currentCoverage;node!=NULL;node=node->next)
     self->_writeCoverageFunction(surface,mask,paint,node->scanx,scany,node->coverage,node->length,self->_blendFunction);

   }
      
   for(;activeRoot!=NULL;activeRoot=activeRoot->next)
    removeEdgeFromAET(activeRoot);

   CoverageNode *node,*next;
   for(node=freeCoverage;node!=NULL;node=next){
    next=node->next;
    NSZoneFree(NULL,node);
   }
   for(node=currentCoverage;node!=NULL;node=next){
    next=node->next;
    NSZoneFree(NULL,node);    
   }
}

void O2DContextClipAndFillEdges(KGRasterizer *self,int fillRuleMask){
   KGImage *mask=(self->_clipContext!=nil)?self->_clipContext->_surface:nil;
   
   O2DContextFillEdgesOnSurface(self,self->_surface,mask,self->_paint,fillRuleMask);
}

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode) {
   RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
   
   self->_blend_lRGBA8888_PRE=NULL;
   self->_writeCoverage_lRGBA8888_PRE=NULL;
   
   switch(blendMode){
   
    case kCGBlendModeNormal:
     self->_blend_lRGBA8888_PRE=KGBlendSpanNormal_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanNormal_ffff;
     self->_writeCoverage_lRGBA8888_PRE=KGRasterizeWriteCoverageSpan8888_Normal;
     break;
     
	case kCGBlendModeMultiply:
     self->_blend_lRGBAffff_PRE=KGBlendSpanMultiply_ffff;
     break;
     
	case kCGBlendModeScreen:
     self->_blend_lRGBAffff_PRE=KGBlendSpanScreen_ffff;
	 break;

	case kCGBlendModeOverlay:
     self->_blend_lRGBAffff_PRE=KGBlendSpanOverlay_ffff;
     break;
        
	case kCGBlendModeDarken:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDarken_ffff;
     break;

	case kCGBlendModeLighten:
     self->_blend_lRGBAffff_PRE=KGBlendSpanLighten_ffff;
     break;

	case kCGBlendModeColorDodge:
     self->_blend_lRGBAffff_PRE=KGBlendSpanColorDodge_ffff;
     break;
        
	case kCGBlendModeColorBurn:
     self->_blend_lRGBAffff_PRE=KGBlendSpanColorBurn_ffff;
     break;
        
	case kCGBlendModeHardLight:
     self->_blend_lRGBAffff_PRE=KGBlendSpanHardLight_ffff;
     break;
        
	case kCGBlendModeSoftLight:
     self->_blend_lRGBAffff_PRE=KGBlendSpanSoftLight_ffff;
     break;
        
	case kCGBlendModeDifference:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDifference_ffff;
     break;
        
	case kCGBlendModeExclusion:
     self->_blend_lRGBAffff_PRE=KGBlendSpanExclusion_ffff;
     break;
        
	case kCGBlendModeHue:
     self->_blend_lRGBAffff_PRE=KGBlendSpanHue_ffff;
     break; 
        
	case kCGBlendModeSaturation:
     self->_blend_lRGBAffff_PRE=KGBlendSpanSaturation_ffff;
     break;
        
	case kCGBlendModeColor:
     self->_blend_lRGBAffff_PRE=KGBlendSpanColor_ffff;
     break;
        
	case kCGBlendModeLuminosity:
     self->_blend_lRGBAffff_PRE=KGBlendSpanLuminosity_ffff;
     break;
        
	case kCGBlendModeClear:
     self->_blend_lRGBA8888_PRE=KGBlendSpanClear_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanClear_ffff;
     break;

	case kCGBlendModeCopy:
     self->_blend_lRGBA8888_PRE=KGBlendSpanCopy_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanCopy_ffff;
     self->_writeCoverage_lRGBA8888_PRE=KGRasterizeWriteCoverageSpan8888_Copy;
     break;

	case kCGBlendModeSourceIn:
     self->_blend_lRGBA8888_PRE=KGBlendSpanSourceIn_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanSourceIn_ffff;
     break;

	case kCGBlendModeSourceOut:
     self->_blend_lRGBAffff_PRE=KGBlendSpanSourceOut_ffff;
     break;

	case kCGBlendModeSourceAtop:
     self->_blend_lRGBAffff_PRE=KGBlendSpanSourceAtop_ffff;
     break;

	case kCGBlendModeDestinationOver:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDestinationOver_ffff;
     break;

	case kCGBlendModeDestinationIn:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDestinationIn_ffff;
     break;

	case kCGBlendModeDestinationOut:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDestinationOut_ffff;
     break;

	case kCGBlendModeDestinationAtop:
     self->_blend_lRGBAffff_PRE=KGBlendSpanDestinationAtop_ffff;
     break;

	case kCGBlendModeXOR:
     self->_blend_lRGBA8888_PRE=KGBlendSpanXOR_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanXOR_ffff;
     break;

	case kCGBlendModePlusDarker:
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusDarker_ffff;
     break;

	case kCGBlendModePlusLighter:
     self->_blend_lRGBA8888_PRE=KGBlendSpanPlusLighter_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusLighter_ffff;
     break;
   }

   if(self->_writeCoverage_lRGBA8888_PRE!=NULL){
    self->_blendFunction=NULL;
    self->_writeCoverageFunction=self->_writeCoverage_lRGBA8888_PRE;
   }
   else {
    if(self->_blend_lRGBA8888_PRE!=NULL){
     self->_blendFunction=self->_blend_lRGBA8888_PRE;
     self->_writeCoverageFunction=KGRasterizeWriteCoverageSpan8888;
    }
    else {
     self->_blendFunction=self->_blend_lRGBAffff_PRE;
     self->_writeCoverageFunction=KGRasterizeWriteCoverageSpanffff;
    }
   }
}

void O2DContextSetPaint(KGRasterizer *self, KGPaint* paint) {
   paint=[paint retain];
   [self->_paint release];
   self->_paint=paint;
   
}


@end
