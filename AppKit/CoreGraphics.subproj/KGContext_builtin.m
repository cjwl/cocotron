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

#define RI_MAX_EDGES					262144

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
  
   KGSurface *surface=KGSurfaceInitWithBytes(KGSurfaceAlloc(),_width,_height,bitsPerComponent,bitsPerPixel,bytesPerRow,colorSpace,bitmapInfo,VG_lRGBA_8888_PRE,_bytes);
   KGRasterizerInit(self,surface);

   KGRasterizerSetViewport(self,KGImageGetWidth(m_renderingSurface),KGImageGetHeight(m_renderingSurface));
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
   		KGRasterizeSetBlendMode(self,gState->_blendMode);
//		KGRasterizeSetTileFillColor(context->m_tileFillColor);


       KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias);

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
                
                VGFillRule fillRule=(drawingMode==kCGPathFill || drawingMode==kCGPathFillStroke)?VG_NON_ZERO:VG_EVEN_ODD;
                
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


        KGRasterizerSetShouldAntialias(self,gState->_shouldAntialias);

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

-(void)deviceSelectFontWithName:(const char *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
//   KGInvalidAbstractInvocation();
}

KGRasterizer *KGRasterizerInit(KGRasterizer *self,KGSurface *renderingSurface) {
	self->m_renderingSurface = renderingSurface;
	self->m_mask=NULL;
	self->m_paint=NULL;
    KGRasterizeSetBlendMode(self,kCGBlendModeNormal);

   self->_vpwidth=self->_vpheight=0;
   
   self->_edgeCount=0;
   self->_edgeCapacity=256;
   self->_edgePool=NSZoneMalloc(NULL,self->_edgeCapacity*sizeof(Edge));

   return self;
}

void KGRasterizerDealloc(KGRasterizer *self) {
   NSZoneFree(NULL,self->_edgePool);
   NSZoneFree(NULL,self);
}

void KGRasterizerSetViewport(KGRasterizer *self,int vpwidth,int vpheight) {
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
    self->_vpwidth=vpwidth;
    self->_vpheight=vpheight;
}

void KGRasterizerClear(KGRasterizer *self) {
   self->_edgeCount=0;   
}

void KGRasterizerAddEdge(KGRasterizer *self,const CGPoint v0, const CGPoint v1) {
	if(v0.y == v1.y)
		return;	//skip horizontal edges (they don't affect rasterization since we scan horizontally)

    if(v0.y<self->_vpy && v1.y<self->_vpy)
     return;
    
    int MaxY=self->_vpy+self->_vpheight;
    
    if(v0.y>=MaxY && v1.y>=MaxY)
     return;
          
	if( self->_edgeCount >= RI_MAX_EDGES )
     NSLog(@"too many edges");

	Edge *edge;
    if(self->_edgeCount+1>=self->_edgeCapacity){
     self->_edgeCapacity*=2;
     self->_edgePool=NSZoneRealloc(NULL,self->_edgePool,self->_edgeCapacity*sizeof(Edge));
    }
    edge=self->_edgePool+self->_edgeCount;
    self->_edgeCount++;
    
    if(v0.y < v1.y)
    {	//edge is going upward
        edge->v0 = v0;
        edge->v1 = v1;
        edge->direction = 1;
    }
    else
    {	//edge is going downward
        edge->v0 = v1;
        edge->v1 = v0;
        edge->direction = -1;
    }
    edge->normal=CGPointMake(edge->v0.y - edge->v1.y, edge->v1.x - edge->v0.x);	//edge normal
    edge->cnst = Vector2Dot(edge->v0, edge->normal);	//distance of v0 from the origin along the edge normal
    edge->minscany=RI_FLOOR_TO_INT(edge->v0.y-self->fradius);
    edge->maxscany=ceil(edge->v1.y+self->fradius);
    
}

// Returns a radical inverse of a given integer for Hammersley point set.
static double radicalInverseBase2(unsigned int i)
{
	if( i == 0 )
		return 0.0;
	double p = 0.0;
	double f = 0.5;
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

void KGRasterizerSetShouldAntialias(KGRasterizer *self,BOOL antialias) {
	//make a sampling pattern
    self->sumWeights = 0.0f;

   if(!antialias){
    self->numSamples=1;
    self->fradius=0.6;
    self->sumWeights=1;
			self->samplesX[0] = 0;
			self->samplesY[0] = 0;
			self->samplesWeight[0] = 1;
   }
   else {
/*
   The exact specifications of the Quartz AA filter are unknown. We want something very close in quality.
   
   Visual comparisons indicate the Quartz filter quality is at least the quality of a 64 sample one.
   32 samples appears too low regardless of the function. More samples with an inferior weighting function
   doesn't help and is more expensive.
      
   Visual comparisons indicate the Quartz filter radius is not large, 0.75 is too big and results
   in extra pixels being drawn which Quartz does not generate. 0.6 is extremely close if not identical using
   any reasonable weighting.

 */
        // The Quartz AA filter is different than this
		self->numSamples = 64;
		self->fradius = 0.6;
        int i;
        
		for(i=0;i<self->numSamples;i++)
		{	//Gaussian filter, implemented using Hammersley point set for sample point locations
			CGFloat x = (CGFloat)radicalInverseBase2(i);
			CGFloat y = ((CGFloat)i + 0.5f) / (CGFloat)self->numSamples;
			RI_ASSERT(x >= 0.0f && x < 1.0f);
			RI_ASSERT(y >= 0.0f && y < 1.0f);

			//map unit square to unit circle
			CGFloat r = (CGFloat)sqrt(x) * self->fradius;
			x = r * (CGFloat)sin(y*2.0f*M_PI);
			y = r * (CGFloat)cos(y*2.0f*M_PI);
//			self->samplesWeight[i] = (CGFloat)exp(-0.5*RI_SQR(r));
			self->samplesWeight[i] = (CGFloat)exp(-0.5*RI_SQR(r/self->fradius));
			RI_ASSERT(x >= -1.5f && x <= 1.5f && y >= -1.5f && y <= 1.5f);	//the specification restricts the filter radius to be less than or equal to 1.5
			
			self->samplesX[i] = x;
			self->samplesY[i] = y;
            
			self->sumWeights += self->samplesWeight[i];
		}

    }
}

static void sortEdgesByMinY(Edge **edges,int count,Edge **B){
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

static void initEdgeForAET(Edge *edge,CGFloat cminy,CGFloat cmaxy,CGFloat fradius,int xlimit){
   //compute edge min and max x-coordinates for this scanline
   
   CGPoint vd = Vector2Subtract(edge->v1,edge->v0);
   CGFloat wl = 1.0f /vd.y;
   edge->vdxwl=vd.x*wl;

   edge->bminx = RI_MIN(edge->v0.x, edge->v1.x);
   edge->bmaxx = RI_MAX(edge->v0.x, edge->v1.x);

   edge->sxPre = (edge->v0.x  - edge->v0.y* edge->vdxwl)+ edge->vdxwl*cminy;
   edge->exPre = (edge->v0.x  - edge->v0.y* edge->vdxwl)+ edge->vdxwl*cmaxy;
   CGFloat autosx = RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex  = RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
   CGFloat maxx=RI_MAX(autosx,autoex);
   
   minx-=fradius+0.5f;
   //0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
   maxx+=fradius+0.5f+0.01f;
   
   edge->minx = minx;
// FIX, we may not need this field
   edge->ceilMinX=RI_INT_MIN(xlimit,ceil(minx));
   edge->maxx = maxx;
}

static void incrementEdgeForAET(Edge *edge,CGFloat cminy,CGFloat cmaxy,CGFloat fradius,int xlimit){
   edge->sxPre+= edge->vdxwl;
   edge->exPre+= edge->vdxwl;
   
   CGFloat autosx = RI_CLAMP(edge->sxPre, edge->bminx, edge->bmaxx);
   CGFloat autoex  = RI_CLAMP(edge->exPre, edge->bminx, edge->bmaxx); 
   CGFloat minx=RI_MIN(autosx,autoex);
   CGFloat maxx=RI_MAX(autosx,autoex);
   
   minx-=fradius+0.5f;
   //0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
   maxx+=fradius+0.5f+0.01f;
   
   edge->minx = minx;
// FIX, we may not need this field
   edge->ceilMinX=RI_INT_MIN(xlimit,ceil(minx));
   edge->maxx = maxx;
}

void KGRasterizerFill(KGRasterizer *self,VGFillRule fillRule) {
	RI_ASSERT(fillRule == VG_EVEN_ODD || fillRule == VG_NON_ZERO);

	//proceed scanline by scanline
	//keep track of edges that can intersect the pixel filters of the current scanline (Active Edge Table)
	//until all pixels of the scanline have been processed
	//  for all sampling points of the current pixel
	//    determine the winding number using edge functions
	//    add filter weight to coverage
	//  divide coverage by the number of samples
	//  determine a run of pixels with constant coverage
	//  call fill callback for each pixel of the run

	int fillRuleMask = (fillRule == VG_NON_ZERO)?-1:1;
    
    int ylimit=self->_vpheight;
    int xlimit=self->_vpwidth;

    int    edgeCount=self->_edgeCount;
    Edge **edges=NSZoneMalloc(NULL,(edgeCount+(edgeCount/2 + 1))*sizeof(Edge *));
    Edge **sortTmp=edges+edgeCount;
    
    int i;
    int nextAvailableEdge=0;
    
    for(i=0;i<edgeCount;i++)
     edges[i]=self->_edgePool+i;
     
    sortEdgesByMinY(edges,edgeCount,sortTmp);
    
    for(nextAvailableEdge=0;nextAvailableEdge<edgeCount;nextAvailableEdge++){
     Edge *check=edges[nextAvailableEdge];
     
     if(check->maxscany>=self->_vpy)
      break;
    }
    
    int     activeCount=0;
    int     activeCapacity=512;
    Edge  **activeEdges=NSZoneMalloc(NULL,activeCapacity*sizeof(Edge *));
    CGFloat cminy = (CGFloat)0 - self->fradius + 0.5f;
    CGFloat cmaxy = (CGFloat)0 + self->fradius + 0.5f;
    int     scany;

        int     coverageCapacity=32;
        int     coverageCount=0;
        int     coverageX[coverageCapacity];
        int     coverageY[coverageCapacity];
        int     coverageLength[coverageCapacity];
        CGFloat coverageValue[coverageCapacity];
                
	for(scany=0;scany<ylimit;scany++,cminy+=1.0,cmaxy+=1.0){
     
     CGFloat pcy=scany+0.5f; // pixel center
     int removeNulls=0;
     
     // remove edges out of range, load empty slot with an available edge
     for(i=0;i<activeCount;i++){
      Edge *check=activeEdges[i];
      
      if(check->maxscany>=scany){
       incrementEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
      }
      else {
       activeEdges[i]=NULL;
       removeNulls++;
       
       if(nextAvailableEdge<edgeCount){
        Edge *check=edges[nextAvailableEdge];
        
        if(check->minscany<=scany){
         initEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
         activeEdges[i]=check;
         nextAvailableEdge++;
         removeNulls--;
        }
       }
      }
     }
     
     if(removeNulls){
      // remove any excess edges
      for(i=activeCount;removeNulls && --i>=0;){
       if(activeEdges[i]==NULL){
        int r;
       
        for(r=i;r<activeCount-1;r++)
         activeEdges[r]=activeEdges[r+1];
         
        activeCount--;
        removeNulls--;
       }
      }
     }
     else {
      // load more available edges
      for(;nextAvailableEdge<edgeCount;nextAvailableEdge++){
       Edge *check=edges[nextAvailableEdge];
        
       if(check->minscany>scany)
        break;
        
       if(activeCount>=activeCapacity){
        activeCapacity*=2;
        activeEdges=NSZoneRealloc(NULL,activeEdges,activeCapacity*sizeof(Edge *));
       }
       initEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
       activeEdges[activeCount++]=check;
      }
     }
     
     if(activeCount==0)
      continue;
      
        int     s;

		//fill the scanline
        int scanx;

        int winding[xlimit][self->numSamples];
        int increase[xlimit];
        
        for(scanx=0;scanx<xlimit;scanx++){
         increase[scanx]=0;
         for(s=0;s<self->numSamples;s++)
          winding[scanx][s]=0;
        }
          
        for(i=0;i<activeCount;i++){
         Edge   *edge=activeEdges[i];
         CGFloat sidePre[self->numSamples];
         
         for(s=0;s<self->numSamples;s++){
          CGFloat spy = pcy+self->samplesY[s];
          if(spy >= edge->v0.y && spy < edge->v1.y)
           sidePre[s] = -(spy*edge->normal.y + self->samplesX[s]*edge->normal.x)-0.5f*edge->normal.x;
          else
           sidePre[s]=-INT_MAX;
         }

         for(scanx=MAX(0,edge->minx);scanx<xlimit;scanx++){
          int      direction=edge->direction;
          CGFloat *pre=sidePre;
          CGFloat *preEnd=pre+self->numSamples;
          int     *windptr=winding[scanx];
          CGFloat  pcxnormal=scanx*edge->normal.x-edge->cnst;
          int      rightOfEdge=0;
          
          do{
           if(pcxnormal<=*pre){
            *windptr+=direction;
            rightOfEdge++;
           }
           windptr++;
           pre++;
          }while(pre<preEnd);
          
          if(rightOfEdge==self->numSamples){
           increase[scanx]+=direction;
           break;
          }
         }
        }        
        
        int accum=0;
        
		for(scanx=0;scanx<xlimit;scanx++){                       			                   
 		 CGFloat coverage = 0.0f;
         s=self->numSamples;
         while(--s>=0)                  
          if(( winding[scanx][s]+accum) & fillRuleMask )
		    coverage += self->samplesWeight[s];
            
		 if(coverage > 0.0f){
          coverage /= self->sumWeights;
             
          coverageX[coverageCount]=scanx;
          coverageY[coverageCount]=scany;
          coverageValue[coverageCount]=coverage;
          coverageLength[coverageCount]=1;
          coverageCount++;

          if(coverageCount>=coverageCapacity){
           self->_writeCoverageSpans(self,coverageX,coverageY,coverageValue,coverageLength,coverageCount);
           coverageCount=0;
          }

         }
         accum+=increase[scanx];
        }
	}
    
    if(coverageCount>0)
     self->_writeCoverageSpans(self,coverageX,coverageY,coverageValue,coverageLength,coverageCount);
    
    NSZoneFree(NULL,activeEdges);
    NSZoneFree(NULL,edges);
}

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode) {
   RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
    
   self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBAffff;

   switch(blendMode){
   
    case kCGBlendModeNormal:
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
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
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
     self->_blend_lRGBA8888_PRE=KGBlendSpanClear_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanClear_ffff;
     break;

	case kCGBlendModeCopy:
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
     self->_blend_lRGBA8888_PRE=KGBlendSpanCopy_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanCopy_ffff;
     break;

	case kCGBlendModeSourceIn:
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
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
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
     self->_blend_lRGBA8888_PRE=KGBlendSpanXOR_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanXOR_ffff;
     break;

	case kCGBlendModePlusDarker:
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusDarker_ffff;
     break;

	case kCGBlendModePlusLighter:
     self->_writeCoverageSpans=KGRasterizeWriteCoverageSpans_RGBA8888;
     self->_blend_lRGBA8888_PRE=KGBlendSpanPlusLighter_8888;
     self->_blend_lRGBAffff_PRE=KGBlendSpanPlusLighter_ffff;
     break;
   }
}

void KGRasterizeSetMask(KGRasterizer *self,KGSurface* mask) {
	self->m_mask = mask;
}

void KGRasterizeSetPaint(KGRasterizer *self, KGPaint* paint) {
	self->m_paint = paint;
	if(!self->m_paint)
		self->m_paint = [[KGPaint_color alloc] initWithGray:0 alpha:1];
}


static void KGApplyCoverageAndMaskToSpan_lRGBAffff_PRE(KGRGBAffff *dst,CGFloat coverage,CGFloat *mask,KGRGBAffff *result,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBAffff r=result[i];
    KGRGBAffff d=dst[i];
    CGFloat cov=mask[i]*coverage;
     
    result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
   }
}

static void KGApplyCoverageToSpan_lRGBAffff_PRE(KGRGBAffff *dst,CGFloat coverage,KGRGBAffff *result,int length){
   int i;
   for(i=0;i<length;i++){
    KGRGBAffff r=result[i];
    KGRGBAffff d=dst[i];
     
    result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , coverage) , KGRGBAffffMultiplyByFloat(d , (1.0f - coverage)));
   }
}
         
void KGRasterizeWriteCoverageSpans_RGBAffff(KGRasterizer *self,int *xptr, int *yptr,CGFloat *coverageptr,int *lengthsptr,int count) {
   int i;
   
   for(i=0;i<count;i++){
    int x=xptr[i];
    int y=yptr[i];
    CGFloat coverage=coverageptr[i];
    int length=lengthsptr[i];
         
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
    KGSurfaceWriteSpan_lRGBAffff_PRE(self->m_renderingSurface,x,y,src,length);
   }
}

static void KGApplyCoverageAndMaskToSpan_lRGBA8888_PRE(KGRGBA8888 *dst,CGFloat coveragef,uint8_t *mask,KGRGBA8888 *result,int length){
   int i;
   
   for(i=0;i<length;i++){
    KGRGBA8888 r=result[i];
    KGRGBA8888 d=dst[i];
    CGFloat cov=(mask[i]*coveragef)*255;
    CGFloat oneMinusCov=(1.0-cov)*255;
     
    result[i]=KGRGBA8888Add(KGRGBA8888MultiplyByCoverageByte(r , cov) , KGRGBA8888MultiplyByCoverageByte(d , oneMinusCov));
   }
}

static void KGApplyCoverageToSpan_lRGBA8888_PRE(KGRGBA8888 *dst,CGFloat coveragef,KGRGBA8888 *result,int length){
   int i;
   int coverage=coveragef*255;
   int oneMinusCoverage=(1.0f - coveragef)*255;
   
   for(i=0;i<length;i++){
    KGRGBA8888 r=result[i];
    KGRGBA8888 d=dst[i];
    
    result[i]=KGRGBA8888Add(KGRGBA8888MultiplyByCoverageByte(r , coverage) , KGRGBA8888MultiplyByCoverageByte(d , oneMinusCoverage));
   }
}
         
void KGRasterizeWriteCoverageSpans_RGBA8888(KGRasterizer *self,int *xptr, int *yptr,CGFloat *coverageptr,int *lengthsptr,int count) {
   int i;
   
   for(i=0;i<count;i++){
    int x=xptr[i];
    int y=yptr[i];
    CGFloat coverage=coverageptr[i];
    int length=lengthsptr[i];
         
    KGRGBA8888 dst[length];
    KGImageReadSpan_lRGBA8888_PRE(self->m_renderingSurface,x,y,dst,length);

    KGRGBA8888 src[length];
    KGPaintReadSpan_lRGBA8888_PRE(self->m_paint,x,y,src,length);
    
    self->_blend_lRGBA8888_PRE(src,dst,length);
    
	//apply masking
	if(!self->m_mask)
     KGApplyCoverageToSpan_lRGBA8888_PRE(dst,coverage,src,length);
    else {
     uint8_t maskSpan[length];
     
     KGImageReadSpan_A8_MASK(self->m_mask,x,y,maskSpan,length);
     KGApplyCoverageAndMaskToSpan_lRGBA8888_PRE(dst,coverage,maskSpan,src,length);
    }
        
	//write result to the destination surface
    KGSurfaceWriteSpan_lRGBA8888_PRE(self->m_renderingSurface,x,y,src,length);
   }
}

@end
