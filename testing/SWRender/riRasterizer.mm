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

#include "riRasterizer.h"

//==============================================================================================

namespace OpenVGRI
{

/*-------------------------------------------------------------------*//*!
* \brief	Rasterizer constructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Rasterizer::Rasterizer()
{
   _vpx=_vpy=_vpwidth=_vpheight=0;
   
   _edgeCount=0;
   _edgeCapacity=256;
   _edges=(Edge *)NSZoneMalloc(NULL,_edgeCapacity*sizeof(Edge));
}

/*-------------------------------------------------------------------*//*!
* \brief	Rasterizer destructor.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

Rasterizer::~Rasterizer()
{
}

void        Rasterizer::setViewport(int vpx,int vpy,int vpwidth,int vpheight) {
	RI_ASSERT(vpwidth >= 0 && vpheight >= 0);
	RI_ASSERT(vpx + vpwidth >= vpx && vpy + vpheight >= vpy);
    _vpx=vpx;
    _vpy=vpy;
    _vpwidth=vpwidth;
    _vpheight=vpheight;
}


/*-------------------------------------------------------------------*//*!
* \brief	Removes all appended edges.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::clear()
{
   _edgeCount=0;
}

/*-------------------------------------------------------------------*//*!
* \brief	Appends an edge to the rasterizer.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void Rasterizer::addEdge(const Vector2& v0, const Vector2& v1)
{
	if( _edgeCount >= RI_MAX_EDGES )
		throw std::bad_alloc();	//throw an out of memory error if there are too many edges

	if(v0.y == v1.y)
		return;	//skip horizontal edges (they don't affect rasterization since we scan horizontally)

	Edge e;
    
    if(v0.y < v1.y)
    {	//edge is going upward
        e.v0 = v0;
        e.v1 = v1;
        e.direction = 1;
    }
    else
    {	//edge is going downward
        e.v0 = v1;
        e.v1 = v0;
        e.direction = -1;
    }
    e.normal.set(e.v0.y - e.v1.y, e.v1.x - e.v0.x);	//edge normal
    e.cnst = dot(e.v0, e.normal);	//distance of v0 from the origin along the edge normal
    
    if(_edgeCount+1>=_edgeCapacity){
     _edgeCapacity*=2;
     _edges=(Edge *)NSZoneRealloc(NULL,_edges,_edgeCapacity*sizeof(Edge));
    }
    _edges[_edgeCount++]=e;
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
	for(unsigned int j=0;j<32;j++)
	{
		if( i & (1<<j) )
			p += f;
		f *= ff;
	}
	return p;
}

void Rasterizer::setShouldAntialias(BOOL antialias) {

	//make a sampling pattern
    sumWeights = 0.0f;
	 fradius = 0.0f;		//max offset of the sampling points from a pixel center

	if(!antialias){
		numSamples = 1;
		samples[0].x = 0.0f;
		samples[0].y = 0.0f;
		samples[0].weight = 1.0f;
		fradius = 0.0f;
		sumWeights = 1.0f;
	}
    else  { 
        /* This is close to the Quartz AA filter, Quartz appears to be more linear but more likely to cut off */
        // There doesn't seem to be much noticeable difference between 8 and 16 samples using this
        
		numSamples = 8;
		fradius = .75;
		for(int i=0;i<numSamples;i++)
		{	//Gaussian filter, implemented using Hammersley point set for sample point locations
			RIfloat x = (RIfloat)radicalInverseBase2(i);
			RIfloat y = ((RIfloat)i + 0.5f) / (RIfloat)numSamples;
			RI_ASSERT(x >= 0.0f && x < 1.0f);
			RI_ASSERT(y >= 0.0f && y < 1.0f);

			//map unit square to unit circle
			RIfloat r = (RIfloat)sqrt(x) * fradius;
			x = r * (RIfloat)sin(y*2.0f*PI);
			y = r * (RIfloat)cos(y*2.0f*PI);
			samples[i].weight = (RIfloat)exp(-0.5f * RI_SQR(r/fradius));

			RI_ASSERT(x >= -1.5f && x <= 1.5f && y >= -1.5f && y <= 1.5f);	//the specification restricts the filter radius to be less than or equal to 1.5
			
			samples[i].x = x;
			samples[i].y = y;
			sumWeights += samples[i].weight;
		}
	}

}


/*-------------------------------------------------------------------*//*!
* \brief	Calls PixelPipe::pixelPipe for each pixel with coverage greater
*			than zero.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

struct ActiveEdge {
   Vector2		v0;
   Vector2		v1;
   int			direction;		//-1 down, 1 up
   RIfloat		minx;			//for the current scanline
   RIfloat		maxx;			//for the current scanline
   Vector2		n;
   RIfloat		cnst;
};

typedef struct {
   int _count;
   int _capacity;
   ActiveEdge *_activeEdges;
} ActiveEdgeTable;

static inline void activeEdgeTableInit(ActiveEdgeTable *aet){
   aet->_count=0;
   aet->_capacity=512;
   aet->_activeEdges=(ActiveEdge *)NSZoneMalloc(NULL,aet->_capacity*sizeof(ActiveEdge));
}

static inline void activeEdgeTableFree(ActiveEdgeTable *aet){
   NSZoneFree(NULL,aet->_activeEdges);
}

static inline int activeEdgeTableCount(ActiveEdgeTable *aet){
   return aet->_count;
}

static inline void activeEdgeTableReset(ActiveEdgeTable *aet){
   aet->_count=0;
}

static inline ActiveEdge *activeEdgeTableAt(ActiveEdgeTable *aet,int index){
   RI_ASSERT(index<aet->_count);
   
   return aet->_activeEdges+index;
}

static inline void activeEdgeTableAdd(ActiveEdgeTable *aet,ActiveEdge edge){
   if(aet->_count+1>=aet->_capacity){
    aet->_capacity*=2;
    aet->_activeEdges=(ActiveEdge *)NSZoneRealloc(NULL,aet->_activeEdges,aet->_capacity*sizeof(ActiveEdge));
   }

   aet->_activeEdges[aet->_count++]=edge;
}

static inline void activeEdgeTableSort(ActiveEdgeTable *aet,int start,int end){
    if (start < end) { 
      ActiveEdge pivot=aet->_activeEdges[end];
      int i = start; 
      int j = end; 
      while (i != j) { 
        if (aet->_activeEdges[i].minx < pivot.minx) { 
          i++; 
        } 
        else { 
          aet->_activeEdges[j] = aet->_activeEdges[i]; 
          aet->_activeEdges[i] = aet->_activeEdges[j-1]; 
          j--; 
        } 
      } 
      aet->_activeEdges[j] = pivot; 
      activeEdgeTableSort(aet, start, j-1); 
      activeEdgeTableSort(aet, j+1, end); 
    } 
}

void Rasterizer::sortEdgeTable(int start,int end) const{
    if (start < end) { 
      Edge pivot=_edges[end];
      int i = start; 
      int j = end; 
      while (i != j) { 
        if (_edges[i].v0.y < pivot.v0.y || (_edges[i].v0.y==pivot.v0.y && _edges[i].v1.y<pivot.v1.y)) { 
          i ++; 
        } 
        else { 
          _edges[j] = _edges[i]; 
          _edges[i] = _edges[j-1]; 
          j --; 
        } 
      } 
      _edges[j] = pivot; 
      sortEdgeTable( start, j-1); 
      sortEdgeTable( j+1, end); 
    } 
}

void Rasterizer::fill(VGFillRule fillRule, const PixelPipe& pixelPipe) 
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

	int fillRuleMask = 1;
	if(fillRule == VG_NON_ZERO)
		fillRuleMask = -1;

	//fill the screen
	ActiveEdgeTable aet;

    activeEdgeTableInit(&aet);
    
    sortEdgeTable(0,_edgeCount-1);
    
    int miny=_vpy;
    int maxy=_vpy+_vpheight;

    if(_edgeCount>0){
     int lowesty=floorf(_edges[0].v0.y-fradius+0.5f);
     
     if(lowesty>miny){
      miny=lowesty;
     }
    }
    
    int startAtEdge=0;
    
	for(int j=miny;j<maxy;j++)
	{
        RIfloat cminy = (RIfloat)j - fradius + 0.5f;
		RIfloat cmaxy = (RIfloat)j + fradius + 0.5f;
        
		//simple AET: scan through all the edges and pick the ones intersecting this scanline
        activeEdgeTableReset(&aet);
        BOOL gotActiveEdge=NO;
        
		for(int e=startAtEdge;e<_edgeCount;e++) {
			const Edge ed = _edges[e];

			if(cmaxy >= ed.v0.y && cminy < ed.v1.y){
                if(!gotActiveEdge){
                 gotActiveEdge=YES;
                 startAtEdge=e;
                }
			    ActiveEdge ae;
            
                ae.v0=ed.v0;
                ae.v1=ed.v1;
                ae.direction=ed.direction;
                ae.n=ed.normal;
                ae.cnst=ed.cnst;
                
				//compute edge min and max x-coordinates for this scanline
				Vector2 vd = ae.v1 - ae.v0;
				RIfloat wl = 1.0f / vd.y;
				RIfloat bminx = RI_MIN(ae.v0.x, ae.v1.x);
				RIfloat bmaxx = RI_MAX(ae.v0.x, ae.v1.x);
				RIfloat sx = ae.v0.x + vd.x * (cminy - ae.v0.y) * wl;
				RIfloat ex = ae.v0.x + vd.x * (cmaxy - ae.v0.y) * wl;
				sx = RI_CLAMP(sx, bminx, bmaxx);
				ex = RI_CLAMP(ex, bminx, bmaxx);
				ae.minx = RI_MIN(sx,ex);
				ae.maxx = RI_MAX(sx,ex);
                activeEdgeTableAdd(&aet,ae);
			}
            else if(ed.v0.y>cmaxy)
             break;
		}

		if(!activeEdgeTableCount(&aet))
			continue;	//no edges on the whole scanline, skip it

        activeEdgeTableSort(&aet,0,activeEdgeTableCount(&aet)-1);
        
		//fill the scanline
		int aes = 0;
		int aen = 0;
		for(int i=_vpx;i<_vpx+_vpwidth;)
		{
			Vector2 pc(i + 0.5f, j + 0.5f);		//pixel center
			
			//find edges that intersect or are to the left of the pixel antialiasing filter
			while(aes < activeEdgeTableCount(&aet) && pc.x + fradius >= activeEdgeTableAt(&aet,aes)->minx)
				aes++;
			//edges [0,aes] may have an effect on winding, and need to be evaluated while sampling

			//compute coverage
			RIfloat coverage = 0.0f;
			for(int s=0;s<numSamples;s++){
				Vector2 sp = pc;	//sampling point
			    sp.x += samples[s].x;
                sp.y += samples[s].y;

				//compute winding number by evaluating the edge functions of edges to the left of the sampling point
				int winding = 0;
				for(int e=0;e<aes;e++){
                
					if(sp.y >= activeEdgeTableAt(&aet,e)->v0.y && sp.y < activeEdgeTableAt(&aet,e)->v1.y){
                    	//evaluate edge function to determine on which side of the edge the sampling point lies
						RIfloat side = dot(sp, activeEdgeTableAt(&aet,e)->n) - activeEdgeTableAt(&aet,e)->cnst;
						if(side <= 0.0f)	//implicit tie breaking: a sampling point on an opening edge is in, on a closing edge it's out
							winding += activeEdgeTableAt(&aet,e)->direction;
					}
				}
				if( winding & fillRuleMask )
					coverage += samples[s].weight;
			}

			//constant coverage optimization:
			//scan AET from left to right and skip all the edges that are completely to the left of the pixel filter.
			//since AET is sorted by minx, the edge we stop at is the leftmost of the edges we haven't passed yet.
			//if that edge is to the right of this pixel, coverage is constant between this pixel and the start of the edge.
			while(aen < activeEdgeTableCount(&aet) && activeEdgeTableAt(&aet,aen)->maxx < pc.x - fradius - 0.01f)	//0.01 is a safety region to prevent too aggressive optimization due to numerical inaccuracy
				aen++;

			int endSpan = _vpx + _vpwidth;	//endSpan is the first pixel NOT part of the span
			if(aen < activeEdgeTableCount(&aet))
				endSpan = RI_INT_MAX(i+1, RI_INT_MIN(endSpan, (int)ceil(activeEdgeTableAt(&aet,aen)->minx - fradius - 0.5f)));

			coverage /= sumWeights;

			//fill a run of pixels with constant coverage
			if(coverage > 0.0f)
			{
				for(;i<endSpan;i++)
				{
						pixelPipe.pixelPipe(i, j, coverage);
				}
			}

			i = endSpan;
		}
	}

    activeEdgeTableFree(&aet);
}

//=======================================================================

}	//namespace OpenVGRI
