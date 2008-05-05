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
 
#import "KGRasterizer.h"
#import "KGPaint_color.h"
#import "KGSurface.h"
#import "KGBlending.h"

#define RI_MAX_EDGES					262144

@implementation KGRasterizer

KGRasterizer *KGRasterizerAlloc(){
   return (KGRasterizer *)NSZoneCalloc(NULL,1,sizeof(KGRasterizer));
}

KGRasterizer *KGRasterizerInit(KGRasterizer *self,KGSurface *renderingSurface) {
	self->m_renderingSurface = renderingSurface;
	self->m_mask=NULL;
	self->m_paint=NULL;
    self->_blendRGBAffff=KGBlendSpanNormal_ffff;

   self->_vpx=self->_vpy=self->_vpwidth=self->_vpheight=0;
   
   self->_edgeCount=0;
   self->_edgeCapacity=256;
   self->_edgePool=NSZoneMalloc(NULL,self->_edgeCapacity*sizeof(Edge));

   return self;
}

void KGRasterizerDealloc(KGRasterizer *self) {
   NSZoneFree(NULL,self->_edgePool);
   NSZoneFree(NULL,self);
}

void KGRasterizerSetViewport(KGRasterizer *self,int vpx,int vpy,int vpwidth,int vpheight) {
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
	RI_ASSERT(vpx + vpwidth >= vpx && vpy + vpheight >= vpy);
    self->_vpx=vpx;
    self->_vpy=vpy;
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
   self->_antialias=antialias;
	//make a sampling pattern
    self->sumWeights = 0.0f;

   if(NO && !self->_antialias){
    self->numSamples=1;
    self->fradius=0.6;
    self->sumWeights=1;
			self->samples[0].x = 0;
			self->samples[0].y = 0;
			self->samples[0].weight = 1;
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
        // 8, 16 also work, but all of them generate misdrawing with the classic test & stroking, this might be a fill bug
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
			self->samples[i].weight = (CGFloat)exp(-0.5*RI_SQR(r));
//			self->samples[i].weight = (CGFloat)exp(-0.5*RI_SQR(r/self->fradius));
			RI_ASSERT(x >= -1.5f && x <= 1.5f && y >= -1.5f && y <= 1.5f);	//the specification restricts the filter radius to be less than or equal to 1.5
			
			self->samples[i].x = x;
			self->samples[i].y = y;
            
			self->sumWeights += self->samples[i].weight;
		}

    }
}

static void scanlineSort(Edge **edges,int count,Edge **B){
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
           if (A->minx>B[i]->minx)
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

static void initEdgeSidePre(Edge *edge,Sample *samples,int numSamples,CGFloat pcy){
   CGFloat *sidePre=edge->sidePre;
   int s;
        
   for(s=0;s<numSamples;s++){
    CGFloat spy = pcy+samples[s].y;
    if(spy >= edge->v0.y && spy < edge->v1.y)
     sidePre[s] = -(spy*edge->normal.y - edge->cnst + samples[s].x*edge->normal.x)-0.5f*edge->normal.x;
    else
     sidePre[s]=-LONG_MAX; // arbitrary large number
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

/*
  
  Aliased Drawing
  
  Apple's aliased drawing appears to use the same scanline fill as the anti-aliased drawing, the difference
  being that when the coverage value is greater than 0 it is promoted to 1. This makes for more filled out
  shapes, we do that here and it matchs much better than the 1 sample filter. As the quality of the AA filter
  is improved, it matches Apple's drawing more closely for both AA and non-AA. Thin lines have the largest
  amount of error, there are probably scan conversion adjustments being made in Apple's.
  
  Edge Clipping
  
  We can easily clip edges which fall below or above the viewport and do that. Edges which are outside the x
  values of the viewport must be clipped more carefully as they affect winding on minx and coverage on maxx,
  we don't do that here yet. Apple clearly does it as performance goes up when most of the edges are
  outside minx/maxx. The more edges you can keep out of the AET the better.

 */
 
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
    
    int miny=self->_vpy;
    int ylimit=self->_vpy+self->_vpheight;
    int xlimit=self->_vpx+self->_vpwidth;

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
    CGFloat cminy = (CGFloat)miny - self->fradius + 0.5f;
    CGFloat cmaxy = (CGFloat)miny + self->fradius + 0.5f;
    int     scany;

	for(scany=miny;scany<ylimit;scany++,cminy+=1.0,cmaxy+=1.0){
     
     CGFloat pcy=scany+0.5f; // pixel center
     int removeNulls=0;
     
     // remove edges out of range, load empty slot with an available edge
     for(i=0;i<activeCount;i++){
      Edge *check=activeEdges[i];
      
      if(check->maxscany>=scany){
       incrementEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
       initEdgeSidePre(check,self->samples,self->numSamples,pcy);
      }
      else {
       activeEdges[i]=NULL;
       removeNulls++;
       
       if(nextAvailableEdge<edgeCount){
        Edge *check=edges[nextAvailableEdge];
        
        if(check->minscany<=scany){
         initEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
       initEdgeSidePre(check,self->samples,self->numSamples,pcy);
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
       initEdgeSidePre(check,self->samples,self->numSamples,pcy);
       activeEdges[activeCount++]=check;
      }
     }
     
     if(activeCount==0)
      continue;
      
     scanlineSort(activeEdges,activeCount,sortTmp);

        int     s;

		//fill the scanline
        int scanx;
        int winding[self->numSamples];
        int nextEdge=0;
        int lastBestWinding=0;
        int rightOfLastEdge=NO;
        int spanCapacity=256;
        int spanCount=0,spanX=-1;
        CGFloat span[spanCapacity];
        
		for(scanx=RI_INT_MAX(self->_vpx,activeEdges[0]->minx);nextEdge<activeCount && scanx<xlimit;){            			
            
            if(!rightOfLastEdge){
             for(s=self->numSamples;--s>=0;)
              winding[s]=lastBestWinding;
                        
             rightOfLastEdge=YES;
            }
            
            for(i=nextEdge;i<activeCount;i++){
             Edge   *edge=activeEdges[i];
             CGFloat minx=edge->minx;

             if(scanx<minx)
              break;
             else {
              int      direction=edge->direction;
              CGFloat *pre=edge->sidePre;
              int     *windptr=winding;
              CGFloat  pcxnormal=scanx*edge->normal.x;
              int      rightOfThisEdge=0;
              
              for(s=0;s<self->numSamples;s++,windptr++){
               if(pcxnormal<=*pre++) {
                *windptr+=direction;
 	 		    rightOfThisEdge+=direction;
               }
              }

              rightOfLastEdge&=(ABS(rightOfThisEdge)==self->numSamples)?YES:NO;
              if(rightOfLastEdge){
               rightOfLastEdge=YES;
               nextEdge=i+1;
               lastBestWinding=winding[0];
              }

             }
		   }

		   int nextx = xlimit;
           
           for(i=nextEdge;i<activeCount;i++){
            Edge   *edge=activeEdges[i];

            if(scanx<=edge->maxx){
			 nextx=RI_INT_MAX(scanx+1,edge->ceilMinX);
             break;
            }
           }
            
		   CGFloat coverage = 0.0f;
           s=self->numSamples;
           while(--s>=0)                  
            if( winding[s] & fillRuleMask )
			 coverage += self->samples[s].weight;
            
		   if(coverage > 0.0f){
             coverage /= self->sumWeights;

             if(!self->_antialias)
               coverage=1;

             if(spanCount==0)
              spanX=scanx;
             else if(scanx!=(spanX+spanCount)){
              KGRasterizeWriteCoverage(self,spanX,scany,span,spanCount);
              spanCount=0;
              spanX=scanx;
             }
             
             for(i=0;i<(nextx-scanx);i++){
             
              if(spanCount>=spanCapacity){
               KGRasterizeWriteCoverage(self,spanX,scany,span,spanCount);
               spanCount=0;
               spanX=scanx+i;
              }
              span[spanCount++]=coverage;
             }
           }
            
		   scanx = nextx;             
        }
        
        if(spanCount>0){
         KGRasterizeWriteCoverage(self,spanX,scany,span,spanCount);
         spanCount=0;
        }
	}
    
    NSZoneFree(NULL,activeEdges);
    NSZoneFree(NULL,edges);
}

void KGRasterizeSetBlendMode(KGRasterizer *self,CGBlendMode blendMode) {
   RI_ASSERT(blendMode >= kCGBlendModeNormal && blendMode <= kCGBlendModePlusLighter);
    
   switch(blendMode){
   
    case kCGBlendModeNormal:
     self->_blendRGBAffff=KGBlendSpanNormal_ffff;
     break;
     
	case kCGBlendModeMultiply:
     self->_blendRGBAffff=KGBlendSpanMultiply_ffff;
     break;
     
	case kCGBlendModeScreen:
     self->_blendRGBAffff=KGBlendSpanScreen_ffff;
	 break;

	case kCGBlendModeOverlay:
     self->_blendRGBAffff=KGBlendSpanOverlay_ffff;
     break;
        
	case kCGBlendModeDarken:
     self->_blendRGBAffff=KGBlendSpanDarken_ffff;
     break;

	case kCGBlendModeLighten:
     self->_blendRGBAffff=KGBlendSpanLighten_ffff;
     break;

	case kCGBlendModeColorDodge:
     self->_blendRGBAffff=KGBlendSpanColorDodge_ffff;
     break;
        
	case kCGBlendModeColorBurn:
     self->_blendRGBAffff=KGBlendSpanColorBurn_ffff;
     break;
        
	case kCGBlendModeHardLight:
     self->_blendRGBAffff=KGBlendSpanHardLight_ffff;
     break;
        
	case kCGBlendModeSoftLight:
     self->_blendRGBAffff=KGBlendSpanSoftLight_ffff;
     break;
        
	case kCGBlendModeDifference:
     self->_blendRGBAffff=KGBlendSpanDifference_ffff;
     break;
        
	case kCGBlendModeExclusion:
     self->_blendRGBAffff=KGBlendSpanExclusion_ffff;
     break;
        
	case kCGBlendModeHue:
     self->_blendRGBAffff=KGBlendSpanHue_ffff;
     break; 
        
	case kCGBlendModeSaturation:
     self->_blendRGBAffff=KGBlendSpanSaturation_ffff;
     break;
        
	case kCGBlendModeColor:
     self->_blendRGBAffff=KGBlendSpanColor_ffff;
     break;
        
	case kCGBlendModeLuminosity:
     self->_blendRGBAffff=KGBlendSpanLuminosity_ffff;
     break;
        
	case kCGBlendModeClear:
     self->_blendRGBAffff=KGBlendSpanClear_ffff;
     break;

	case kCGBlendModeCopy:
     self->_blendRGBAffff=KGBlendSpanCopy_ffff;
     break;

	case kCGBlendModeSourceIn:
     self->_blendRGBAffff=KGBlendSpanSourceIn_ffff;
     break;

	case kCGBlendModeSourceOut:
     self->_blendRGBAffff=KGBlendSpanSourceOut_ffff;
     break;

	case kCGBlendModeSourceAtop:
     self->_blendRGBAffff=KGBlendSpanSourceAtop_ffff;
     break;

	case kCGBlendModeDestinationOver:
     self->_blendRGBAffff=KGBlendSpanDestinationOver_ffff;
     break;

	case kCGBlendModeDestinationIn:
     self->_blendRGBAffff=KGBlendSpanDestinationIn_ffff;
     break;

	case kCGBlendModeDestinationOut:
     self->_blendRGBAffff=KGBlendSpanDestinationOut_ffff;
     break;

	case kCGBlendModeDestinationAtop:
     self->_blendRGBAffff=KGBlendSpanDestinationAtop_ffff;
     break;

	case kCGBlendModeXOR:
     self->_blendRGBAffff=KGBlendSpanXOR_ffff;
     break;

	case kCGBlendModePlusDarker:
     self->_blendRGBAffff=KGBlendSpanPlusDarker_ffff;
     break;

	case kCGBlendModePlusLighter:
     self->_blendRGBAffff=KGBlendSpanPlusLighter_ffff;
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


static inline KGRGBAffff KGRGBAffffConvert(KGRGBAffff rgba,int fromFormat,int toFormat){
   VGColor color=VGColorFromKGRGBA_ffff(rgba,fromFormat);
   
   color=VGColorConvert(color,toFormat);
   
   return KGRGBAffffFromColor(color);
}

static VGColorInternalFormat KGApplyCoverageToSpan(KGRGBAffff *dst,CGFloat *coverage,KGRGBAffff *result,int length,VGColorInternalFormat dFormat){
   //apply antialiasing in linear color space
   VGColorInternalFormat aaFormat = (dFormat & VGColorLUMINANCE) ? VGColor_lLA_PRE : VGColor_lRGBA_PRE;
   int i;
   
   if(aaFormat!=dFormat){
    for(i=0;i<length;i++){
     KGRGBAffff r=result[i];
     KGRGBAffff d=dst[i];
     CGFloat cov=coverage[i];

     r=KGRGBAffffConvert(r,dFormat,aaFormat);
     d=KGRGBAffffConvert(d,dFormat,aaFormat);
   
     result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
    }
    return aaFormat;
   }
   else {
    for(i=0;i<length;i++){
     KGRGBAffff r=result[i];
     KGRGBAffff d=dst[i];
     CGFloat cov=coverage[i];
     
     result[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(r , cov) , KGRGBAffffMultiplyByFloat(d , (1.0f - cov)));
    }
    
    return dFormat;
   }
   
}

void KGRasterizeWriteCoverage(KGRasterizer *self,int x, int y,CGFloat *coverage,int length)  {
	RI_ASSERT(self->m_renderingSurface);

	//apply masking
	if(self->m_mask)
     KGSurfaceReadMaskPixelSpanIntoCoverage(self->m_mask,x,y,coverage,length);
// This optimization may not make sense in the bulk computations
//	if(coverage[0..length] == 0.0f)
//		return;

	//read destination color
    KGRGBAffff d[length];
    VGColorInternalFormat dFormat=KGSurfaceReadPremultipliedSpan_ffff(self->m_renderingSurface,x,y,d,length);

    KGRGBAffff src[length];
    VGColorInternalFormat srcFormat=self->m_paint->_readRGBAffff(self->m_paint,x,y,src,length);

   if(!(srcFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(src,length);
    srcFormat|=VGColorPREMULTIPLIED;
   }
   convertSpan(src,length,srcFormat,dFormat);      
    
    self->_blendRGBAffff(src,d,length);
    VGColorInternalFormat resultFormat;
    
    resultFormat=KGApplyCoverageToSpan(d,coverage,src,length,dFormat);
    
	//write result to the destination surface
    KGSurfaceWritePixelSpan(self->m_renderingSurface,x,y,src,length,resultFormat);
}

@end
