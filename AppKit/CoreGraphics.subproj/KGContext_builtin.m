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
#import "KGBlending.h"

#define MAX_SAMPLES     COVERAGE_MULTIPLIER

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
  
   KGSurface *surface=KGSurfaceInitWithBytes([KGSurface alloc],_width,_height,bitsPerComponent,bitsPerPixel,bytesPerRow,colorSpace,bitmapInfo,VG_lRGBA_8888_PRE,_bytes);
   KGRasterizerInit(self,surface);

   KGRasterizerSetViewport(self,KGImageGetWidth(m_renderingSurface),KGImageGetHeight(m_renderingSurface));
   return self;
}

-(void)setWidth:(size_t)width height:(size_t)height reallocateOnlyIfRequired:(BOOL)roir {
  _width=width;
  _height=height;
  [m_renderingSurface setWidth:width height:height reallocateOnlyIfRequired:roir];
  KGRasterizerSetViewport(self,KGImageGetWidth(m_renderingSurface),KGImageGetHeight(m_renderingSurface));
}

-(void *)bytes {
   return m_renderingSurface->_bytes;
}

-(size_t)bytesPerRow {
   return m_renderingSurface->_bytesPerRow;
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
   		KGRasterizeSetBlendMode(self,gState->_blendMode);
//		KGRasterizeSetTileFillColor(context->m_tileFillColor);


       KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

//CGAffineTransform xform=CGAffineTransformIdentity;//gState->_userSpaceTransform;
CGAffineTransform xform=gState->_userSpaceTransform;
CGAffineTransform u2d=CGAffineTransformMakeTranslation(0,_height);
u2d=CGAffineTransformScale(u2d,1,-1);
xform=CGAffineTransformConcat(xform,u2d);

		CGAffineTransform userToSurfaceMatrix=xform;// context->m_pathUserToSurface;


		if(drawingMode!=kCGPathStroke)
		{
            KGPaint *paint=paintFromColor(gState->_fillColor);
			KGRasterizeSetPaint(self,paint);

			CGAffineTransform surfaceToPaintMatrix =xform;//context->m_pathUserToSurface * context->m_fillPaintToUser;
			if(CGAffineTransformInplaceInvert(&surfaceToPaintMatrix))
			{
				KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

				VGPathFill(vgPath,userToSurfaceMatrix,self);
                
                VGFillRuleMask fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
				KGRasterizerFill(self,fillRule);
			}
		}

		if(drawingMode>=kCGPathStroke){
         if(gState->_lineWidth > 0.0f){
            KGPaint *paint=paintFromColor(gState->_strokeColor);
			KGRasterizeSetPaint(self,paint);

			CGAffineTransform surfaceToPaintMatrix=xform;// = context->m_pathUserToSurface * context->m_strokePaintToUser;
			if(CGAffineTransformInplaceInvert(&surfaceToPaintMatrix))
			{
				KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);

				KGRasterizerClear(self);
                                 
				VGPathStroke(vgPath,userToSurfaceMatrix, self, gState->_dashLengths,gState->_dashLengthsCount, gState->_dashPhase, YES /* context->m_strokeDashPhaseReset ? YES : NO*/,
									  gState->_lineWidth, gState->_lineCap,  gState->_lineJoin, RI_MAX(gState->_miterLimit, 1.0f));
				KGRasterizerFill(self,VG_NON_ZERO);
			}
		 }
        }

   KGRasterizerClear(self);
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
xform=CGAffineTransformTranslate(xform,rect.origin.x,rect.origin.y);
xform=CGAffineTransformScale(xform,rect.size.width/(CGFloat)[image width],rect.size.height/(CGFloat)[image height]);


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
		p0 = CGAffineTransformTransformVector2(imageUserToSurface , p0);
		p1 = CGAffineTransformTransformVector2(imageUserToSurface , p1);
		p2 = CGAffineTransformTransformVector2(imageUserToSurface , p2);
		p3 = CGAffineTransformTransformVector2(imageUserToSurface , p3);


       KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias,gState->_antialiasingQuality);

		// KGRasterizeSetTileFillColor(context->m_tileFillColor);
        KGPaint *paint=paintFromColor(gState->_fillColor);
        CGInterpolationQuality iq;
        if(gState->_interpolationQuality==kCGInterpolationDefault)
            iq=kCGInterpolationHigh;
        else
            iq=gState->_interpolationQuality;

        KGPaint *imagePaint=[[KGPaint_image alloc] initWithImage:image mode:VG_DRAW_IMAGE_NORMAL paint:paint interpolationQuality:iq];
        
        KGRasterizeSetPaint(self,imagePaint);

		KGRasterizeSetBlendMode(self,gState->_blendMode);

//		KGRasterizeSetMask(context->m_masking ? context->getMask() : NULL);

		CGAffineTransform surfaceToImageMatrix = imageUserToSurface;
		CGAffineTransform surfaceToPaintMatrix = CGAffineTransformConcat(imageUserToSurface,fillPaintToUser);
		if(CGAffineTransformInplaceInvert(&surfaceToImageMatrix) && CGAffineTransformInplaceInvert(&surfaceToPaintMatrix))
		{
			KGPaintSetSurfaceToPaintMatrix(paint,surfaceToPaintMatrix);
			KGPaintSetSurfaceToPaintMatrix(imagePaint,surfaceToImageMatrix);

			KGRasterizerAddEdge(self,CGPointMake(p0.x,p0.y), CGPointMake(p1.x,p1.y));
			KGRasterizerAddEdge(self,CGPointMake(p1.x,p1.y), CGPointMake(p2.x,p2.y));
			KGRasterizerAddEdge(self,CGPointMake(p2.x,p2.y), CGPointMake(p3.x,p3.y));
			KGRasterizerAddEdge(self,CGPointMake(p3.x,p3.y), CGPointMake(p0.x,p0.y));
			KGRasterizerFill(self,VG_EVEN_ODD);
        KGRasterizeSetPaint(self,nil);
		}
   KGRasterizerClear(self);

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

-(void)deviceSelectFontWithName:(NSString *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
//   KGInvalidAbstractInvocation();
}

KGRasterizer *KGRasterizerInit(KGRasterizer *self,KGSurface *renderingSurface) {
	self->m_renderingSurface = [renderingSurface retain];
	self->m_mask=NULL;
	self->m_paint=NULL;
    KGRasterizeSetBlendMode(self,kCGBlendModeNormal);

   self->_vpwidth=self->_vpheight=0;
   
   self->_edgeCount=0;
   self->_edgeCapacity=256;
   self->_edges=NSZoneMalloc(NULL,self->_edgeCapacity*sizeof(Edge *));
   self->_sortCache=NSZoneMalloc(NULL,(self->_edgeCapacity/2 + 1)*sizeof(Edge *));
   
   self->samplesX=NSZoneMalloc(NULL,MAX_SAMPLES*sizeof(CGFloat));
   self->samplesY=NSZoneMalloc(NULL,MAX_SAMPLES*sizeof(CGFloat));
   
   return self;
}

void KGRasterizerDealloc(KGRasterizer *self) {
   int i;
   for(i=0;i<self->_edgeCount;i++)
    NSZoneFree(NULL,self->_edges[i]);

   NSZoneFree(NULL,self->_edges);
   NSZoneFree(NULL,self->_sortCache);
   NSZoneFree(NULL,self);
}

void KGRasterizerSetViewport(KGRasterizer *self,int vpwidth,int vpheight) {
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
    self->_vpwidth=vpwidth;
    self->_vpheight=vpheight;
    free(self->_winding);
    self->_winding=malloc((vpwidth*MAX_SAMPLES)*sizeof(int));
    free(self->_increase);
    self->_increase=malloc(vpwidth*sizeof(int));
    free(self->_xIndexSet);
    self->_xIndexSet=malloc(vpwidth*sizeof(int));
    int i;
    for(i=0;i<vpwidth;i++)
     self->_xIndexSet[i]=-1;
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
    edge->normal=CGPointMake(edge->v0.y-edge->v1.y , edge->v1.x - edge->v0.x);	//edge normal
    edge->cnst = Vector2Dot(edge->v0, edge->normal);	//distance of v0 from the origin along the edge normal
    edge->normal.y=-edge->normal.y;
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
/* RULES:
    - samplesY must be in ascending order
 */
 
	//make a sampling pattern

   quality=RI_INT_CLAMP(quality,1,MAX_SAMPLES);
   
   if(!antialias || quality==1){
    self->numSamples=1;
			self->samplesX[0] = 0;
			self->samplesY[0] = 0.5f;
			self->samplesWeight = MAX_SAMPLES;
   }
   else {
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

        for(i=0;i<numberOfSamples;i++){
	     self->samplesX[i] = (CGFloat)radicalInverseBase2(i)-0.5f;
		 self->samplesY[i] = ((CGFloat)(i+0.5f)) / (CGFloat)numberOfSamples-0.5f;
         self->samplesWeight=MAX_SAMPLES/numberOfSamples;
        }
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

static inline void initEdgeForAET(Edge *edge,int scany){
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

static void KGApplyCoverageToSpan_lRGBA8888_PRE(KGRGBA8888 *dst,int coverage,KGRGBA8888 *src,int length){
   int i;
   int oneMinusCoverage=inverseCoverage(coverage);
   
   for(i=0;i<length;i++,src++,dst++){
    KGRGBA8888 r=*src;
    KGRGBA8888 d=*dst;
    
    *dst=KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(r , coverage) , KGRGBA8888MultiplyByCoverage(d , oneMinusCoverage));
   }
}

static void KGBlendSpanNormal_8888_coverage(KGRGBA8888 *src,KGRGBA8888 *dst,int coverage,int length){
// Passes Visual Test
   int i;
   int oneMinusCoverage=inverseCoverage(coverage);

   for(i=0;i<length;i++,src++,dst++){
    KGRGBA8888 s=*src;
    KGRGBA8888 d=*dst;
    KGRGBA8888 r;
    
    r.r=RI_INT_MIN((int)s.r+((int)d.r*(255-s.a))/255,255);
    r.r=multiplyByCoverage(r.r,coverage);
    d.r=(d.r*oneMinusCoverage)/256;
    r.r=RI_INT_MIN((int)r.r+(int)d.r,255);
    
    r.g=RI_INT_MIN((int)s.g+((int)d.g*(255-s.a))/255,255);
    r.g=multiplyByCoverage(r.g,coverage);
    d.g=(d.g*oneMinusCoverage)/256;
    r.g=RI_INT_MIN((int)r.g+(int)d.g,255);
    
    r.b=RI_INT_MIN((int)s.b+((int)d.b*(255-s.a))/255,255);
    r.b=multiplyByCoverage(r.b,coverage);
    d.b=(d.b*oneMinusCoverage)/256;
    r.b=RI_INT_MIN((int)r.b+(int)d.b,255);
    
    r.a=RI_INT_MIN((int)s.a+((int)d.a*(255-s.a))/255,255);
    r.a=multiplyByCoverage(r.a,coverage);
    d.a=(d.a*oneMinusCoverage)/256;
    r.a=RI_INT_MIN((int)r.a+(int)d.a,255);
    
    *dst=r;
   }
}

static void KGBlendSpanCopy_8888_coverage(KGRGBA8888 *src,KGRGBA8888 *dst,int coverage,int length){
// Passes Visual Test
   int i;
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

static inline void KGRasterizeWriteCoverageSpan(KGRasterizer *self,int x, int y,int coverage,int length) {
   if(self->_useRGBA8888){
    KGRGBA8888 dst[length];
    KGImageReadSpan_lRGBA8888_PRE(self->m_renderingSurface,x,y,dst,length);

    KGRGBA8888 src[length];
    KGPaintReadSpan_lRGBA8888_PRE(self->m_paint,x,y,src,length);

    switch(self->_blendMode){
    
     case kCGBlendModeNormal:
      KGBlendSpanNormal_8888_coverage(src,dst,coverage,length);
      break;

     case kCGBlendModeCopy:
      KGBlendSpanCopy_8888_coverage(src,dst,coverage,length);
      break;

     default:
      self->_blend_lRGBA8888_PRE(src,dst,length);
    
	  //apply masking
	  if(!self->m_mask)
       KGApplyCoverageToSpan_lRGBA8888_PRE(dst,coverage,src,length);
      else {
       uint8_t maskSpan[length];
     
       KGImageReadSpan_A8_MASK(self->m_mask,x,y,maskSpan,length);
       KGApplyCoverageAndMaskToSpan_lRGBA8888_PRE(dst,coverage,maskSpan,src,length);
      }
      break;
    }
       
	//write result to the destination surface
    KGSurfaceWriteSpan_lRGBA8888_PRE(self->m_renderingSurface,x,y,dst,length);
   }
   else {
    KGRGBAffff dst[length];
    KGImageReadSpan_lRGBAffff_PRE(self->m_renderingSurface,x,y,dst,length);

    KGRGBAffff src[length];
    KGPaintReadSpan_lRGBAffff_PRE(self->m_paint,x,y,src,length);
    
    self->_blend_lRGBAffff_PRE(src,dst,length);
    
	//apply masking
	if(!self->m_mask)
     KGApplyCoverageToSpan_lRGBAffff_PRE(dst,coverage,src,length);
    else {
     CGFloat maskSpan[length];
     
     KGImageReadSpan_Af_MASK(self->m_mask,x,y,maskSpan,length);
     KGApplyCoverageAndMaskToSpan_lRGBAffff_PRE(dst,coverage,maskSpan,src,length);
    }
        
	//write result to the destination surface
    KGSurfaceWriteSpan_lRGBAffff_PRE(self->m_renderingSurface,x,y,dst,length);
   }
}

void KGRasterizerFill(KGRasterizer *self,VGFillRuleMask fillRuleMask) {    
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
   int *xIndexSet=self->_xIndexSet;
   int  numberOfSamples=self->numSamples;
   int  shiftNumberOfSamples=self->sampleSizeShift;
   CGFloat  sidePre[numberOfSamples];
   CGFloat *preEnd=sidePre+numberOfSamples;
   
   for(scany=self->_vpy;scany<ylimit;scany++){
     Edge *edge,*previous=NULL;

     // load more available edges
     for(;nextAvailableEdge<edgeCount;nextAvailableEdge++){
      edge=edges[nextAvailableEdge];
        
      if(edge->minscany>scany)
       break;
      
      edge->next=activeRoot;
      activeRoot=edge;
      initEdgeForAET(edge,scany);
     }

     int accum=0;
     int minx=xlimit,maxx=0;
     int nextXIndex=0;
     int scanx;
     for(edge=activeRoot;edge!=NULL;edge=edge->next){
      CGFloat *pre=sidePre;
      CGFloat *samplesY=self->samplesY;
      CGFloat *samplesX=self->samplesX;
      CGFloat  pcy=scany+0.5f;
      CGFloat  v0y=edge->v0.y-pcy;
      CGFloat  v1y=edge->v1.y-pcy;
      CGFloat  normalX=edge->normal.x;
      CGFloat  normalY=edge->normal.y;
      int      deltaStart=0;
      int      deltaEnd=0;
      
      for(;*samplesY<v0y && pre<preEnd;samplesY++,samplesX++){
       pre++;
       deltaStart++;
      }
      for(;*samplesY<v1y && pre<preEnd;samplesY++,samplesX++)
       *pre++ = (*samplesY*normalY-*samplesX*normalX);
      for(;pre<preEnd;){
       pre++;
       deltaEnd++;
      }
      
      int direction=edge->direction;
      
       minx=MIN(minx,edge->minx);

       scanx=MAX(0,edge->minx);
       CGFloat pcxnormal=scanx*normalX+0.5f*normalX-(pcy*normalY)-edge->cnst;
       
       for(;scanx<xlimit;scanx++,pcxnormal+=normalX){
        int xIndex=xIndexSet[scanx];
        int *windptr;       
        int leftOfEdge=deltaStart+deltaEnd;

        if(xIndex==-1){
         xIndex=nextXIndex++;
         xIndexSet[scanx]=xIndex;
         
         pre=sidePre;
         windptr=winding+(xIndex<<shiftNumberOfSamples);
         int k;
         for(k=0;k<deltaStart;k++,pre++)
          *windptr++=0;
          
         while(pre<(preEnd-deltaEnd)){
          if(*pre>=pcxnormal)
           *windptr=direction;
          else {
           *windptr=0;
           leftOfEdge++;
          }
         
          windptr++;
          pre++;
         }
         for(k=0;k<deltaEnd;k++)
          *windptr++=0;
          
         increase[xIndex]=0;
        }
        else {
         pre=sidePre+deltaStart;
         windptr=winding+(xIndex<<shiftNumberOfSamples)+deltaStart;

         while(pre<(preEnd-deltaEnd)){
          if(*pre>=pcxnormal)
           *windptr+=direction;
          else 
           leftOfEdge++;

          windptr++;
          pre++;
         }
         
        }
        
        if(leftOfEdge==0){
         increase[xIndex]+=direction;
         break;
        }
                 
        if(leftOfEdge==numberOfSamples && scanx>edge->maxx)
         break;
       }
       maxx=MAX(maxx,scanx);

// increment and remove edges out of range
      if(edge->maxscany>=scany){
       incrementEdgeForAET(edge);
       previous=edge;
      }
      else {
       if(previous==NULL)
        activeRoot=edge->next;
       else
        previous->next=edge->next;
      }
      }        
    minx=MAX(0,minx);
    maxx=MIN(xlimit,maxx+1);
        
    int xIndex=-1;
    
    for(scanx=minx;scanx<maxx;)               
     if((xIndex=xIndexSet[scanx])!=-1){
      xIndexSet[scanx]=-1;
      break;
     }
     
    if(xIndex==-1)
     continue;
    
    int weight=self->samplesWeight;
    
 	int coverage=0;
    
    for(scanx=minx;scanx<maxx;){
     int *windptr=winding+(xIndex<<shiftNumberOfSamples);
       
     int s=numberOfSamples;
     do {      
      if((*windptr+++accum) & fillRuleMask)
	   coverage +=weight;
     }while(--s>0);
      
     accum+=increase[xIndex];
     
     int advance;
     for(advance=scanx+1;advance<maxx;advance++)
      if((xIndex=xIndexSet[advance])!=-1){
       xIndexSet[advance]=-1;
       break;
      }

	 if(coverage>0){
      KGRasterizeWriteCoverageSpan(self,scanx,scany,coverage,(advance-scanx));
      coverage=0;
     }
     
     scanx=advance;
    }
   }
}

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode) {
   RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
   
   self->_blendMode=blendMode;
   self->_useRGBA8888=NO;
   
   switch(blendMode){
   
    case kCGBlendModeNormal:
     self->_useRGBA8888=YES;
     self->_blend_lRGBA8888_PRE=KGBlendSpanNormal_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanNormal_ffff;
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
     self->_useRGBA8888=YES;
     self->_blend_lRGBA8888_PRE=KGBlendSpanClear_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanClear_ffff;
     break;

	case kCGBlendModeCopy:
     self->_useRGBA8888=YES;
     self->_blend_lRGBA8888_PRE=KGBlendSpanCopy_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanCopy_ffff;
     break;

	case kCGBlendModeSourceIn:
     self->_useRGBA8888=YES;
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
     self->_useRGBA8888=YES;
     self->_blend_lRGBA8888_PRE=KGBlendSpanXOR_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanXOR_ffff;
     break;

	case kCGBlendModePlusDarker:
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusDarker_ffff;
     break;

	case kCGBlendModePlusLighter:
     self->_useRGBA8888=YES;
     self->_blend_lRGBA8888_PRE=KGBlendSpanPlusLighter_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusLighter_ffff;
     break;
   }
}

void KGRasterizeSetMask(KGRasterizer *self,KGSurface* mask) {
	self->m_mask = mask;
}

void KGRasterizeSetPaint(KGRasterizer *self, KGPaint* paint) {
   paint=[paint retain];
   [self->m_paint release];
   self->m_paint=paint;
   
	if(!self->m_paint)
		self->m_paint = [[KGPaint_color alloc] initWithGray:0 alpha:1];
}


@end
