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
#import "KGGraphicsState.h"
#import "VGPath.h"
#import "KGPaint_image.h"
#import "KGPaint_color.h"
#import "KGPaint_axialGradient.h"
#import "KGPaint_radialGradient.h"
#import "KGBlending.h"
#import "KGShading.h"

#define MAX_SAMPLES     COVERAGE_MULTIPLIER

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
    self->_winding=calloc((width*MAX_SAMPLES),sizeof(int));
    free(self->_increase);
    self->_increase=malloc(width*sizeof(int));
    int i;
    for(i=0;i<width;i++)
     self->_increase[i]=INT_MAX;
}


-initWithSurface:(KGSurface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
        
   m_mask=NULL;
   m_paint=[[KGPaint_color alloc] initWithGray:0 alpha:1];

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
   [m_mask release];
   [m_paint release];
   
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

-(void)deviceClipToNonZeroPath:(KGPath *)path {
   KGMutablePath *copy=[path mutableCopy];
    
   [copy applyTransform:CGAffineTransformInvert([self currentState]->_userSpaceTransform)];
   [copy applyTransform:[self currentState]->_deviceSpaceTransform];
   CGRect rect=[copy boundingBox];
   
   [copy release];
   
   _vpx=MAX(rect.origin.x,0);
   _vpwidth=MIN(KGImageGetWidth(_surface),CGRectGetMaxX(rect))-_vpx;
   _vpy=MAX(rect.origin.y,0);
   _vpheight=MIN(KGImageGetHeight(_surface),CGRectGetMaxY(rect))-_vpy;
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
   KGGraphicsState *gState=[self currentState];
   
//		KGRasterizeSetMask(context->m_masking ? context->getMask() : NULL);
   		KGRasterizeSetBlendMode(self,gState->_blendMode);
//		KGRasterizeSetTileFillColor(context->m_tileFillColor);

       KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

/* Path construction is affected by the CTM, and the stroke pen is affected by the CTM , this means path points and the stroke can be affected by different transforms as the CTM can change during path construction and before stroking. For example, creation of transformed shapes which are drawn using an untransformed pen. The current tesselator expects everything to be in user coordinates and it tesselates from there into device space, but the path points are already in base coordinates. So, path points are brought from base coordinates into the active coordinate space using an inverted transform and then everything is tesselated using the CTM into device space.  */
 
   CGAffineTransform userToSurfaceMatrix=gState->_deviceSpaceTransform;

   [_path applyTransform:CGAffineTransformInvert(gState->_userSpaceTransform)];
   VGPath *vgPath=[[VGPath alloc] initWithKGPath:_path];

   if(drawingMode!=kCGPathStroke){
    KGPaint *paint=paintFromColor(gState->_fillColor);
    KGRasterizeSetPaint(self,paint);
    [paint release];
    
    CGAffineTransform surfaceToPaintMatrix =userToSurfaceMatrix;//context->m_pathUserToSurface * context->m_fillPaintToUser;
    
    surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
     KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

     VGPathFill(vgPath,userToSurfaceMatrix,self);
                
     VGFillRuleMask fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
     KGRasterizerFill(self,fillRule);
   }

   if(drawingMode>=kCGPathStroke){
    if(gState->_lineWidth > 0.0f){
     KGPaint *paint=paintFromColor(gState->_strokeColor);
     KGRasterizeSetPaint(self,paint);
     [paint release];
     
     CGAffineTransform surfaceToPaintMatrix=userToSurfaceMatrix;// = context->m_pathUserToSurface * context->m_strokePaintToUser;

     surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
      KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

      KGRasterizerClear(self);
                                 
      VGPathStroke(vgPath,userToSurfaceMatrix, self, gState->_dashLengths,gState->_dashLengthsCount, gState->_dashPhase, YES /* context->m_strokeDashPhaseReset ? YES : NO*/,
        gState->_lineWidth, gState->_lineCap,  gState->_lineJoin, RI_MAX(gState->_miterLimit, 1.0f));
      KGRasterizerFill(self,VG_NON_ZERO);
    }
   }

   KGRasterizeSetPaint(self,nil);
   [vgPath release];
   KGRasterizerClear(self);
   [_path reset];
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
  

   KGRasterizeSetPaint(self,paint);
   [paint release];

/* FIXME: If either extend is off we need to generate the bounding shape and clip to it, the paint classes generate alpha=0 for out of extend which
   is a problem for some blending ops, copy in particular.
 */
 
   KGRasterizerAddEdge(self,CGPointMake(0,0), CGPointMake(0,KGImageGetHeight(_surface)));
   KGRasterizerAddEdge(self,CGPointMake(KGImageGetWidth(_surface),0), CGPointMake(KGImageGetWidth(_surface),KGImageGetHeight(_surface)));

   KGRasterizerFill(self,VG_NON_ZERO);
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

		// KGRasterizeSetTileFillColor(context->m_tileFillColor);
        KGPaint *paint=paintFromColor(gState->_fillColor);
        CGInterpolationQuality iq;
        if(gState->_interpolationQuality==kCGInterpolationDefault)
            iq=kCGInterpolationLow;
        else
            iq=gState->_interpolationQuality;

        KGPaint *imagePaint=[[KGPaint_image alloc] initWithImage:image mode:VG_DRAW_IMAGE_NORMAL paint:paint interpolationQuality:iq];
        
        KGRasterizeSetPaint(self,imagePaint);

        
		KGRasterizeSetBlendMode(self,gState->_blendMode);

//		KGRasterizeSetMask(context->m_masking ? context->getMask() : NULL);

		CGAffineTransform surfaceToImageMatrix = imageUserToSurface;
		CGAffineTransform surfaceToPaintMatrix = CGAffineTransformConcat(imageUserToSurface,fillPaintToUser);
        
        surfaceToImageMatrix=CGAffineTransformInvert(surfaceToImageMatrix);
        surfaceToPaintMatrix=CGAffineTransformInvert(surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(imagePaint,surfaceToImageMatrix);

			KGRasterizerAddEdge(self,p0, p1);
			KGRasterizerAddEdge(self,p1, p2);
			KGRasterizerAddEdge(self,p2, p3);
			KGRasterizerAddEdge(self,p3, p0);
			KGRasterizerFill(self,VG_EVEN_ODD);

        KGRasterizeSetPaint(self,nil);
        [paint release];
        [imagePaint release];

   KGRasterizerClear(self);
}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
   //KGInvalidAbstractInvocation();
}



-(void)deviceClipToEvenOddPath:(KGPath *)path {
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

void KGRasterizerAddEdge(KGRasterizer *self,const CGPoint v0, const CGPoint v1) {

	if(v0.y == v1.y)
		return;	//skip horizontal edges (they don't affect rasterization since we scan horizontally)

    if((v0.y+0.5f)<self->_vpy && (v1.y+0.5f)<self->_vpy)  // ignore below miny
     return;
    
    int MaxY=self->_vpy+self->_vpheight;
    
    if((v0.y-0.5f)>=MaxY && (v1.y-0.5f)>=MaxY) // ignore above maxy
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
    edge->normal=CGPointMake(edge->v0.y-edge->v1.y , edge->v0.x-edge->v1.x);	//edge normal

    edge->cnst = Vector2Dot(edge->v0, CGPointMake(edge->normal.x,-edge->normal.y));	//distance of v0 from the origin along the edge normal
    edge->minscany=RI_FLOOR_TO_INT(edge->v0.y-0.5f);
    edge->maxscany=ceil(edge->v1.y+0.5f);
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
/*
   At this point I am pretty convinced Apple is using a box filter
   The sampling pattern is different than this
 */
        self->sampleSizeShift=shift;
		self->numSamples = numberOfSamples;
        int i;

		 self->samplesInitialY = ((CGFloat)(0.5f)) / (CGFloat)numberOfSamples;
		 self->samplesDeltaY = ((CGFloat)(1)) / (CGFloat)numberOfSamples;
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
           if (A->minscany>B[i]->minscany)
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

   edge->bminx = RI_MIN(edge->v0.x, edge->v1.x);
   edge->bmaxx = RI_MAX(edge->v0.x, edge->v1.x);

   edge->sxPre = (edge->v0.x  - edge->v0.y* edge->vdxwl)+ edge->vdxwl*(scany-1);
   edge->exPre = (edge->v0.x  - edge->v0.y* edge->vdxwl)+ edge->vdxwl*(scany+1);
   CGFloat autosx = RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex  = RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
   CGFloat maxx=RI_MAX(autosx,autoex);
   
   minx-=0.5f+0.5f;
   //0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
   maxx+=0.5f+0.5f+0.01f;
   
   edge->minx = minx;
   edge->maxx = maxx;
   edge->samples=NSZoneMalloc(NULL,sizeof(CGFloat)*self->numSamples);
   
   
       CGFloat *pre=edge->samples;
       int      i,numberOfSamples=self->numSamples;
       CGFloat  sampleY=self->samplesInitialY;
       CGFloat  sampleDeltaY=self->samplesDeltaY;
       CGFloat *samplesX=self->samplesX;
       
       CGFloat  normalX=edge->v0.y-edge->v1.y;
       CGFloat  normalY=edge->v0.x-edge->v1.x;
       CGFloat cnst=edge->v0.x*normalX-edge->v0.y*normalY;
       CGFloat min=0,max=0;
       
       for(i=0;i<numberOfSamples;sampleY+=sampleDeltaY,samplesX++,i++){
        CGFloat value=sampleY*normalY-*samplesX*normalX+cnst;
        
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

static inline void incrementEdgeForAET(Edge *edge){
   edge->sxPre+= edge->vdxwl;
   edge->exPre+= edge->vdxwl;
   
   CGFloat autosx = RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex  = RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
   CGFloat maxx=RI_MAX(autosx,autoex);
   
   minx-=0.5f+0.5f;
   //0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
   maxx+=0.5f+0.5f+0.01f;
   
   edge->minx = minx;
   edge->maxx = maxx;
}

static inline void removeEdgeFromAET(Edge *edge){
   NSZoneFree(NULL,edge->samples);
}

void KGRasterizerFill(KGRasterizer *self,int fillRuleMask) {    
    int    edgeCount=self->_edgeCount;
    Edge **edges=self->_edges;

    int ylimit=self->_vpy+self->_vpheight;
    int xlimit=self->_vpx+self->_vpwidth;
    
    int nextAvailableEdge=0;
         
    sortEdgesByMinY(edges,edgeCount,self->_sortCache);
        
    Edge   *activeRoot=NULL;
    
    int     scany;

   int *winding=self->_winding;
   int *increase=self->_increase;
   int  numberOfSamples=self->numSamples;
   int  shiftNumberOfSamples=self->sampleSizeShift;
   
   for(scany=self->_vpy;scany<ylimit;scany++){
     Edge *edge,*previous=NULL;

     // load more available edges
     for(;nextAvailableEdge<edgeCount;nextAvailableEdge++){
      edge=edges[nextAvailableEdge];
        
      if(edge->minscany>scany)
       break;
      
      edge->next=activeRoot;
      activeRoot=edge;
      initEdgeForAET(self,edge,scany);
     }

     int minx=xlimit,maxx=0;
     
     for(edge=activeRoot;edge!=NULL;edge=edge->next){
      if(edge->minx>=xlimit){
       minx=MIN(minx,edge->minx);
       maxx=MAX(maxx,xlimit);
      }
      else {
       CGFloat *pre=edge->samples;
       CGFloat *preEnd=pre+numberOfSamples;
       CGFloat  sampleY=self->samplesInitialY;
       CGFloat  sampleDeltaY=self->samplesDeltaY;
       CGFloat  v0y=edge->v0.y-scany;
       CGFloat  v1y=edge->v1.y-scany;
       
       CGFloat  normalX=edge->v0.y-edge->v1.y;
       CGFloat  normalY=edge->v0.x-edge->v1.x;

       int      belowY=0;
       int      aboveY;
       
       for(;sampleY<v0y && pre<preEnd;sampleY+=sampleDeltaY){
        pre++;
        belowY++;
       }
       if(sampleY+sampleDeltaY*(preEnd-pre)<v1y)
        pre=preEnd;
       else
        for(;sampleY<v1y && pre<preEnd;sampleY+=sampleDeltaY)
         pre++;
        
       aboveY=preEnd-pre;

       preEnd-=aboveY;
      
       int direction=edge->direction;
      

        if(belowY+aboveY<numberOfSamples){
         int scanx=MAX(0,edge->minx);
         minx=MIN(minx,edge->minx);

         CGFloat pcxnormal=scanx*normalX-scany*normalY;
        
         int *windptr=winding+(scanx<<shiftNumberOfSamples);
         
         windptr+=belowY;
         
         for(;scanx<xlimit;scanx++,pcxnormal+=normalX){
          int *windend=windptr+numberOfSamples-(belowY+aboveY);

          pre=edge->samples+belowY;
          if(pcxnormal<=edge->minSample){
          
           while(windptr<windend)
            *windptr+++=direction;

           if(increase[scanx]==INT_MAX)
            increase[scanx]=0;

           if(belowY+aboveY==0){      
            increase[scanx]+=direction;
            break;
           }
          }
          else if(pcxnormal>edge->maxSample && scanx>edge->maxx){
           break;
          }
          else {
           while(windptr<windend){
            if(pcxnormal<=*pre)
             *windptr+=direction;
             
            pre++;
            windptr++;
           }
           
           if(increase[scanx]==INT_MAX)
            increase[scanx]=0;
          }

          windptr+=aboveY+belowY;
         }
        
         maxx=MAX(maxx,scanx);
        }
       }

// increment and remove edges out of range
      if(edge->maxscany>=scany){
       incrementEdgeForAET(edge);
       previous=edge;
      }
      else {
       removeEdgeFromAET(edge);
       if(previous==NULL)
        activeRoot=edge->next;
       else
        previous->next=edge->next;
      }
     }        
    minx=MAX(self->_vpx,minx);
    maxx=MIN(xlimit,maxx+1);
    
    int scanx;
    
    for(scanx=minx;scanx<maxx;scanx++)               
     if(increase[scanx]!=INT_MAX){
      break;
     }
         
    int weight=self->samplesWeight;
    
 	int accum=0,coverage=0;
    int *maxAdvance=increase+maxx;

    for(;scanx<maxx;){
     int *windptr=winding+(scanx<<shiftNumberOfSamples);
     int *windend=windptr+numberOfSamples;
     
     for(;windptr<windend;) {
      if((*windptr+accum)&fillRuleMask)
       coverage+=weight;
       
      *windptr++=0;
     }
      
     accum+=increase[scanx];
     increase[scanx]=INT_MAX;
     
     int *advance=increase+scanx+1;
     for(;advance<maxAdvance;advance++)
      if(*advance!=INT_MAX){
       break;
      }

	 if(coverage>0){
      if(self->alias)
       coverage=256;
       
      self->_writeCoverageFunction(self->_surface,self->m_mask,self->m_paint,scanx,scany,coverage,(advance-(increase+scanx)),self->_blendFunction);
      coverage=0;
     }
     
     scanx=advance-increase;
    }
   }
   
   for(;activeRoot!=NULL;activeRoot=activeRoot->next)
    removeEdgeFromAET(activeRoot);
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

void KGRasterizeSetMask(KGRasterizer *self,KGSurface* mask) {
	self->m_mask = mask;
}

void KGRasterizeSetPaint(KGRasterizer *self, KGPaint* paint) {
   paint=[paint retain];
   [self->m_paint release];
   self->m_paint=paint;
   
}


@end
