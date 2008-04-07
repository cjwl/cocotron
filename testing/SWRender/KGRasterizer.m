/*------------------------------------------------------------------------
 *
 * OpenVG 1.0.1 Reference Implementation
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
 *//**
 * \file
 * \brief	Implementation of polygon rasterizer.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "KGRasterizer.h"

#define RI_MAX_EDGES					262144

KGRasterizer *KGRasterizerAlloc(){
   return (KGRasterizer *)NSZoneCalloc(NULL,1,sizeof(KGRasterizer));
}

KGRasterizer *KGRasterizerInit(KGRasterizer *self) {
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

/*-------------------------------------------------------------------*//*!
* \brief	Removes all appended edges.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGRasterizerClear(KGRasterizer *self) {
   self->_edgeCount=0;   
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends an edge to the rasterizer.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGRasterizerAddEdge(KGRasterizer *self,const Vector2 v0, const Vector2 v1) {	//throws bad_alloc
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
    edge->normal=Vector2Make(edge->v0.y - edge->v1.y, edge->v1.x - edge->v0.x);	//edge normal
    edge->cnst = Vector2Dot(edge->v0, edge->normal);	//distance of v0 from the origin along the edge normal
    edge->minscany=floorf(edge->v0.y-self->fradius);
    edge->maxscany=ceilf(edge->v1.y+self->fradius);
    Vector2 vd = Vector2Subtract(edge->v1,edge->v0);
    RIfloat wl = 1.0f /vd.y;
    edge->vdxwl=vd.x*wl;
    edge->sxPre = edge->v0.x  - vd.x *edge->v0.y* wl;
    edge->exPre = edge->v0.x  - vd.x *edge->v0.y* wl;
    edge->minx=edge->maxx=0;
    
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns a radical inverse of a given integer for Hammersley
*			point set.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

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
	 self->fradius = 0.0f;		//max offset of the sampling points from a pixel center

	if(!antialias){
		self->numSamples = 1;
		self->samples[0].x = 0.0f;
		self->samples[0].y = 0.0f;
		self->samples[0].weight = 1.0f;
		self->fradius = 0.0f;
		self->sumWeights = 1.0f;
	}
    else  {
    #if 1
		//box filter of diameter 1.0f, 8-queen sampling pattern
		self->numSamples = 8;
		self->samples[0].x = 3;
		self->samples[1].x = 7;
		self->samples[2].x = 0;
		self->samples[3].x = 2;
		self->samples[4].x = 5;
		self->samples[5].x = 1;
		self->samples[6].x = 6;
		self->samples[7].x = 4;
        int i;
		for(i=0;i<self->numSamples;i++)
		{
			self->samples[i].x = (self->samples[i].x + 0.5f) / (RIfloat)self->numSamples - 0.5f;
			self->samples[i].y = ((RIfloat)i + 0.5f) / (RIfloat)self->numSamples - 0.5f;
			self->samples[i].weight = 1.0f / (RIfloat)self->numSamples;
			self->sumWeights += self->samples[i].weight;
		}
		self->fradius = 0.5f;
    #else
        // The Quartz AA filter is different than this,  16 is better than 8 but more expensive
        // FIX, 8 actually generates some bad rendering
		self->numSamples = 8;
		self->fradius = .75;
        int i;
        
		for(i=0;i<self->numSamples;i++)
		{	//Gaussian filter, implemented using Hammersley point set for sample point locations
			RIfloat x = (RIfloat)radicalInverseBase2(i);
			RIfloat y = ((RIfloat)i + 0.5f) / (RIfloat)self->numSamples;
			RI_ASSERT(x >= 0.0f && x < 1.0f);
			RI_ASSERT(y >= 0.0f && y < 1.0f);

			//map unit square to unit circle
			RIfloat r = (RIfloat)sqrt(x) * self->fradius;
			x = r * (RIfloat)sin(y*2.0f*M_PI);
			y = r * (RIfloat)cos(y*2.0f*M_PI);
			self->samples[i].weight = (RIfloat)exp(-0.5f * RI_SQR(r/self->fradius));

			RI_ASSERT(x >= -1.5f && x <= 1.5f && y >= -1.5f && y <= 1.5f);	//the specification restricts the filter radius to be less than or equal to 1.5
			
			self->samples[i].x = x;
			self->samples[i].y = y;
            
			self->sumWeights += self->samples[i].weight;
		}
     #endif
	}

}

/*-------------------------------------------------------------------*//*!
* \brief	Calls KGPixelPipe::pixelPipe for each pixel with coverage greater
*			than zero.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

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

static void initEdgeForAET(Edge *edge,RIfloat cminy,RIfloat cmaxy,RIfloat fradius,int xlimit){
   //compute edge min and max x-coordinates for this scanline
    RIfloat bminx = RI_MIN(edge->v0.x, edge->v1.x);
    RIfloat bmaxx = RI_MAX(edge->v0.x, edge->v1.x);
   RIfloat sx = edge->sxPre+ edge->vdxwl*cminy;
   RIfloat ex = edge->exPre+ edge->vdxwl*cmaxy;
   sx = RI_CLAMP(sx, bminx, bmaxx);
   ex = RI_CLAMP(ex, bminx, bmaxx); 
   RIfloat minx=       RI_MIN(sx,ex)-fradius-0.5f;
   
   edge->minx = minx;
// FIX, we may not need this field
   edge->ceilMinX=RI_INT_MIN(xlimit,ceil(minx));
   //0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
   edge->maxx = RI_MAX(sx,ex)+fradius+0.5f+0.01f;
}

static void incrementEdgeForAET(Edge *edge,RIfloat cminy,RIfloat cmaxy,RIfloat fradius,int xlimit){
   initEdgeForAET(edge,cminy,cmaxy,fradius,xlimit);
//   edge->minx += edge->vdxwl;
//   edge->maxx += edge->vdxwl;
}

void KGRasterizerFill(KGRasterizer *self,VGFillRule fillRule, KGPixelPipe *pixelPipe) 
{
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
    Edge **edges=NSZoneMalloc(NULL,edgeCount*sizeof(Edge *));
    Edge **sortTmp=NSZoneMalloc(NULL,(edgeCount/2 + 1) * sizeof(Edge *));
    
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
    
    int     scany;
    int     activeCount=0;
    int     activeCapacity=1024;
    Edge  **activeEdges=NSZoneMalloc(NULL,activeCapacity*sizeof(Edge *));
    RIfloat cminy = (RIfloat)miny - self->fradius + 0.5f;
    RIfloat cmaxy = (RIfloat)miny + self->fradius + 0.5f;

	for(scany=miny;scany<ylimit;scany++,cminy+=1.0,cmaxy+=1.0){
     
     int removeNulls=0;
     
     // remove edges out of range, load empty slot with an available edge
     for(i=0;i<activeCount;i++){
      Edge *check=activeEdges[i];
      
      if(check->maxscany>=scany)
       incrementEdgeForAET(check,cminy,cmaxy,self->fradius,xlimit);
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
      
     scanlineSort(activeEdges,activeCount,sortTmp);

        int     s;
      
      float sidePre[activeCount][self->numSamples];
      RIfloat pcy=scany+0.5f; // pixel center
      for(i=0;i<activeCount;i++){
 	    Edge *edge = activeEdges[i];
        
        for(s=0;s<self->numSamples;s++){
           RIfloat spy = pcy+self->samples[s].y;
          if(spy >= edge->v0.y && spy < edge->v1.y)
           sidePre[i][s] = -(spy*edge->normal.y - edge->cnst + self->samples[s].x*edge->normal.x)-0.5f*edge->normal.x;
         else
           sidePre[i][s]=-LONG_MAX; // arbitrary large number
        }
      }

		//fill the scanline
        int scanx;
        int winding[self->numSamples];
        int nextEdge=0;
        int lastBestWinding=0;
        int rightOfLastEdge=NO;
        
		for(scanx=RI_INT_MAX(self->_vpx,activeEdges[0]->minx);nextEdge<activeCount && scanx<xlimit;){            			
            
            if(!rightOfLastEdge){
             for(s=self->numSamples;--s>=0;)
              winding[s]=lastBestWinding;
                        
             rightOfLastEdge=YES;
            }
            
            for(i=nextEdge;i<activeCount;i++){
             Edge   *edge=activeEdges[i];
             RIfloat minx=edge->minx;

             if(scanx<minx)
              break;
             else {
              int     direction=edge->direction;
              RIfloat *pre=sidePre[i];
              RIfloat  pcxnormal=scanx*edge->normal.x;
              
              s=self->numSamples;
              while(--s>=0){  
                
               if(pcxnormal > pre[s])
                rightOfLastEdge=NO;
               else {
	 		    winding[s] += direction;
 	 		    rightOfLastEdge&=YES;
               }
	 	      }

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
            

		   RIfloat coverage = 0.0f;
           s=self->numSamples;
           while(--s>=0)                  
            if( winding[s] & fillRuleMask )
			 coverage += self->samples[s].weight;
            
		   if(coverage > 0.0f){
             coverage /= self->sumWeights;

             KGPixelPipeWriteCoverageSpan(pixelPipe,scanx,scany,(nextx-scanx),coverage);
           }
            
		   scanx = nextx;             
        }

	}
    
    NSZoneFree(NULL,activeEdges);
    NSZoneFree(NULL,edges);
}

