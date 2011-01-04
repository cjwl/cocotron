/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "O2Context_builtin_gdi.h"
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2Surface_DIBSection.h>
#import "O2DeviceContext_gdi.h"
#import <Onyx2D/O2Font_gdi.h>
#if 0
#import <Onyx2D/O2Font_freetype.h>
#endif
#import <Onyx2D/O2ClipState.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2Color.h>
#import <Onyx2D/O2Paint_color.h>
#import <Onyx2D/Win32Font.h>

@implementation O2Context_builtin_gdi

+(BOOL)canInitBitmap {
   return YES;
}

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   /* FIX: we need to also override initWithBytes:... and create an O2Surface_DIBSection for the pixel format.
      Right now we just ignore GDI stuff if we get a surface which can't handle it.
    */
   if([[self surface] isKindOfClass:[O2Surface_DIBSection class]])
    _dc=[[(O2Surface_DIBSection *)[self surface] deviceContext] dc];
   _gdiFont=nil;
   _glyphCacheCount=0;
   _glyphCache=NULL;
   return self;
}

-(void)dealloc {
   [_gdiFont release];
   O2PaintRelease(self->_textFillPaint);
   
   int i;
   
   for(i=0;i<_glyphCacheCount;i++)
    if(_glyphCache[i]!=NULL)
     O2GlyphStencilDealloc(_glyphCache[i]);
   if(_glyphCache!=NULL)
    NSZoneFree(NULL,_glyphCache);
   [_scratchContext release];
   [_scratchFont release];
   
   [super dealloc];
}

-(HDC)dc {
   return _dc;
}

-(O2DeviceContext_gdi *)deviceContext {
   if(_dc==NULL)
    return nil;
    
   return [(O2Surface_DIBSection *)[self surface] deviceContext];
}

-(void)clipToState:(O2ClipState *)clipState {
   [super clipToState:clipState];
   
   if(_dc==NULL)
    return;
    
   O2GState *gState=O2ContextCurrentGState(self);
   NSArray  *phases=[O2GStateClipState(gState) clipPhases];
   int       i,count=[phases count];
   
    O2DeviceContextClipReset_gdi(_dc);
   
   for(i=0;i<count;i++){
    O2ClipPhase *phase=[phases objectAtIndex:i];
    O2Path      *path;
    
    switch(O2ClipPhasePhaseType(phase)){
    
     case O2ClipPhaseNonZeroPath:
      path=O2ClipPhaseObject(phase);
   
      O2DeviceContextClipToNonZeroPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      break;
      
     case O2ClipPhaseEOPath:
      path=O2ClipPhaseObject(phase);

      O2DeviceContextClipToEvenOddPath_gdi(_dc,path,O2AffineTransformIdentity,O2AffineTransformIdentity);
      break;
      
     case O2ClipPhaseMask:
      break;
}

   }
}

#if 0
static O2Paint *paintFromColor(O2ColorRef color){
   O2ColorRef   rgbColor=O2ColorConvertToDeviceRGB(color);
   const float *components=O2ColorGetComponents(rgbColor);
   CGFloat r,g,b,a;
   
   r=components[0];
   g=components[1];
   b=components[2];
   a=components[3];
   
   O2ColorRelease(rgbColor);
   
   return [[O2Paint_color alloc] initWithRed:r green:g blue:b alpha:a surfaceToPaintTransform:O2AffineTransformIdentity];
}
#endif

static inline unsigned testDivideBy255(unsigned t){
// t/255
// From Imaging Compositing Fundamentals, Technical Memo 4 by Alvy Ray Smith, Aug 15, 1995
// Faster and more accurate in that it rounds instead of truncates   
   t = t + 0x80;
   t= ( ( ( (t)>>8 ) + (t) )>>8 );
   
   return t;
}

static inline uint32_t testAlphaMultiply(uint32_t c,uint32_t a){
   return testDivideBy255(c*a);
}

static inline O2argb8u testO2argb8uMultiplyByMask8u(O2argb8u result,uint32_t value){
   result.r=testAlphaMultiply(result.r,value);
   result.g=testAlphaMultiply(result.g,value);
   result.b=testAlphaMultiply(result.b,value);
   result.a=testAlphaMultiply(result.a,value);
   
   return result;
}

static void applyCoverageToSpan_lRGBA8888_PRE(O2argb8u *dst,uint8_t *coverageSpan,O2argb8u *src,int length){
   int i;
   
   for(i=0;i<length;i++,src++,dst++){
    uint32_t coverage=coverageSpan[i];
    uint32_t oneMinusCoverage=255-coverage;
    O2argb8u r=*src;
    O2argb8u d=*dst;
    
    *dst=O2argb8uAdd(testO2argb8uMultiplyByMask8u(r , coverage) , testO2argb8uMultiplyByMask8u(d , oneMinusCoverage));
   }
}

static void drawGray8Stencil(O2Context_builtin_gdi *self,O2Surface *surface,CGFloat fpx,CGFloat fpy,O2Paint *paint,uint8_t *coverage,size_t bytesPerRow,size_t width,size_t height,int left,int top){
   int x=lroundf(fpx)+left;
   int y=lroundf(fpy)-top;
   int            row;
   O2argb8u      *dstBuffer=__builtin_alloca(width*sizeof(O2argb8u));
   O2argb8u      *srcBuffer=__builtin_alloca(width*sizeof(O2argb8u));
   int            maxy=self->_vpy+self->_vpheight;
   int            coverageX=0,coverageWidth=width;
   
   if(y+height<self->_vpy)
    return;

   if(x<self->_vpx){
    coverageX=self->_vpx-x;
    coverageWidth-=coverageX;
    x=self->_vpx;
   }
   
   if(x+coverageWidth>self->_vpx+self->_vpwidth){
    coverageWidth=(self->_vpx+self->_vpwidth)-x;
   }
   
   if(coverageWidth<=0)
    return;
            
   for(row=0;row<height && y<self->_vpy;row++,y++)
    coverage+=bytesPerRow;
       
   for(;row<height && y<maxy;row++,y++){
    int       length=coverageWidth;
    O2argb8u *dst=dstBuffer;
    O2argb8u *src=srcBuffer;
    
    O2argb8u *direct=surface->_read_argb8u(surface,x,y,dst,length);

    if(direct!=NULL)
     dst=direct;

    coverage+=coverageX;

    while(YES){
     int chunk=O2PaintReadSpan_argb8u_PRE(paint,x,y,src,length);
      
     if(chunk<0)
      chunk=-chunk;
     else {
      self->_blend_argb8u_PRE(src,dst,chunk);
      
      applyCoverageToSpan_lRGBA8888_PRE(dst,coverage,src,chunk);

      if(direct==NULL)
       O2SurfaceWriteSpan_argb8u_PRE(surface,x,y,dst,chunk);
     }
     coverage+=chunk;

     length-=chunk;     
     x+=chunk;
     src+=chunk;
     dst+=chunk;

     if(length==0)
      break;
    }
    
    coverage+=(bytesPerRow-coverageWidth-coverageX);
    x-=coverageWidth;
   }
    
}

#if 0
static void drawFreeTypeBitmap(O2Context_builtin_gdi *self,O2Surface *surface,O2GlyphStencilRef stencil,CGFloat fpx,CGFloat fpy,O2Paint *paint){
   drawGray8Stencil(self,surface,fpx,fpy,paint,O2GlyphStencilGetCoverage(stencil),O2GlyphStencilGetWidth(stencil),O2GlyphStencilGetWidth(stencil),O2GlyphStencilGetHeight(stencil),O2GlyphStencilGetLeft(stencil),O2GlyphStencilGetTop(stencil));
}
#endif

static inline O2GlyphStencilRef stencilForGlyphIndex(O2Context_builtin_gdi *self,O2Glyph glyph){
   if(glyph<self->_glyphCacheCount)
    return self->_glyphCache[glyph];
   
   return NULL;
}

static inline void cacheStencilForGlyphIndex(O2Context_builtin_gdi *self,O2Glyph glyph,O2GlyphStencilRef stencil){    
   if(glyph>=self->_glyphCacheCount){
    size_t count=self->_glyphCacheCount;
    
    if(self->_glyphCacheCount==0)
     self->_glyphCacheCount=32;
 
    while(glyph>=self->_glyphCacheCount)
     self->_glyphCacheCount*=2;

    self->_glyphCache=NSZoneRealloc(NULL,self->_glyphCache,sizeof(O2GlyphStencilRef)*self->_glyphCacheCount);
    
    for(;count<self->_glyphCacheCount;count++)
     self->_glyphCache[count]=NULL;
   }
   self->_glyphCache[glyph]=stencil;
}

static inline void purgeGlyphCache(O2Context_builtin_gdi *self){
   int i;
   
   for(i=0;i<self->_glyphCacheCount;i++){
    O2GlyphStencilDealloc(self->_glyphCache[i]);
    self->_glyphCache[i]=NULL;
   }
}


-(void)showGlyphs:(const O2Glyph *)glyphs advances:(const O2Size *)advances count:(unsigned)count {
   O2GState         *gState=O2ContextCurrentGState(self);
   O2Font           *font=O2GStateFont(gState);
   O2AffineTransform Trm=O2ContextGetTextRenderingMatrix(self);
   NSPoint           point=O2PointApplyAffineTransform(NSMakePoint(0,0),Trm);
   O2Size            fontSize=O2SizeApplyAffineTransform(O2SizeMake(0,O2GStatePointSize(gState)),Trm);
   int               i;
   O2Size            defaultAdvances[count];
   
   O2ContextGetDefaultAdvances(self,glyphs,defaultAdvances,count);
      
   if(O2FontGetPlatformType(font)==O2FontPlatformTypeGDI){
#if 0
#if 1
    if(gState->_fillColorIsDirty){
     O2PaintRelease(self->_textFillPaint);
     self->_textFillPaint=paintFromColor(gState->_fillColor);
     gState->_fillColorIsDirty=NO;
    }

// This is just to get the blend mode function setup right    
    O2ContextSetupPaintAndBlendMode(self,self->_textFillPaint,gState->_blendMode);
    O2ContextSetPaint(self,nil);
    
   if(gState->_fontIsDirty){
    O2GStateClearFontIsDirty(gState);
     [self->_gdiFont release];
     self->_gdiFont=[(O2Font_gdi *)font createGDIFontSelectedInDC:self->_dc pointSize:ABS(fontSize.height)];
     [self->_scratchFont release];
     self->_scratchFont=nil;
     
     TEXTMETRIC    gdiMetrics;
     GetTextMetrics(self->_dc,&gdiMetrics);
     _gdiDescent=gdiMetrics.tmDescent;
   }
   
    SIZE extent;

    if(!GetTextExtentExPointI(self->_dc,glyphs,count,0,NULL,NULL,&extent))
     extent=(SIZE){0,0};

    // one pixel margin on right
    extent.cx++;
   
    if((extent.cx>self->_scratchWidth) || (extent.cy>self->_scratchHeight)){
     [self->_scratchFont release];
     self->_scratchFont=nil;
     [self->_scratchContext release];
   
// for some reason the dib section is not working unless it is a power of 2? or even? or multiple of four? I dunno, this works, odd numbers werent working??
     self->_scratchWidth=16;
     while(self->_scratchWidth<extent.cx)
      self->_scratchWidth*=2;
   
     self->_scratchHeight=MAX(extent.cy,self->_scratchHeight);
     self->_scratchContext=[[O2DeviceContext_gdiDIBSection alloc] initGray8WithWidth:self->_scratchWidth height:self->_scratchHeight deviceContext:nil];
     self->_scratchDC=[self->_scratchContext dc];
     SetTextColor(self->_scratchDC,RGB(255,255,255));
     SetTextAlign(self->_scratchDC,TA_TOP|TA_LEFT);
     self->_scratchBitmap=[self->_scratchContext bitmapBytes];
     }

     if(self->_scratchFont==nil)
      self->_scratchFont=[(O2Font_gdi *)font createGDIFontSelectedInDC:self->_scratchDC pointSize:ABS(fontSize.height)];

     uint8_t *erase=self->_scratchBitmap;
     int r,c;
     for(r=0;r<extent.cy;r++){
      for(c=0;c<extent.cx;c++)
       erase[c]=0x00;
      erase+=self->_scratchWidth;
     }
     
     ExtTextOutW(self->_scratchDC,0,0,ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);
    drawGray8Stencil(self,self->_surface,point.x,point.y,self->_textFillPaint,self->_scratchBitmap,self->_scratchWidth,extent.cx,extent.cy,0,extent.cy-_gdiDescent);

#else
    if(gState->_fillColorIsDirty){
     O2PaintRelease(self->_textFillPaint);
     self->_textFillPaint=paintFromColor(gState->_fillColor);
     gState->_fillColorIsDirty=NO;
    }

    if(gState->_fontIsDirty){
     O2GStateClearFontIsDirty(gState);
     [self->_gdiFont release];
     self->_gdiFont=[(O2Font_gdi *)font createGDIFontSelectedInDC:self->_dc pointSize:ABS(fontSize.height)];
     [self->_scratchFont release];
     self->_scratchFont=nil;
     purgeGlyphCache(self);
     
     TEXTMETRIC    gdiMetrics;
     GetTextMetrics(self->_dc,&gdiMetrics);
     _gdiDescent=gdiMetrics.tmDescent;
    }
       
    for(i=0;i<count;i++){
     O2GlyphStencilRef stencil=stencilForGlyphIndex(self,glyphs[i]);
     
     if(stencil==NULL){
      SIZE extent;
      
      if(!GetTextExtentExPointI(self->_dc,glyphs+i,1,0,NULL,NULL,&extent))
       extent=(SIZE){0,0};
            
      if((extent.cx>self->_scratchWidth) || (extent.cy>self->_scratchHeight)){
       [self->_scratchFont release];
       self->_scratchFont=nil;
       [self->_scratchContext release];

// for some reason the dib section is not working unless it is a power of 2? or even? or multiple of four? I dunno, this works, odd numbers werent working??
       self->_scratchWidth=16;
       while(self->_scratchWidth<extent.cx)
        self->_scratchWidth*=2;

       self->_scratchHeight=MAX(extent.cy,self->_scratchHeight);
       self->_scratchContext=[[O2DeviceContext_gdiDIBSection alloc] initGray8WithWidth:self->_scratchWidth height:self->_scratchHeight deviceContext:nil];
       self->_scratchDC=[self->_scratchContext dc];
       SetTextColor(self->_scratchDC,RGB(255,255,255));
       SetTextAlign(self->_scratchDC,TA_TOP|TA_LEFT);
       self->_scratchBitmap=[self->_scratchContext bitmapBytes];
      }

      if(self->_scratchFont==nil)
       self->_scratchFont=[(O2Font_gdi *)font createGDIFontSelectedInDC:self->_scratchDC pointSize:ABS(fontSize.height)];

      uint8_t *erase=self->_scratchBitmap;
      int r,c;
      for(r=0;r<extent.cy;r++){
       for(c=0;c<extent.cx;c++)
        erase[c]=0x44;
       erase+=self->_scratchWidth;
      }
      
      ExtTextOutW(self->_scratchDC,0,0,ETO_GLYPH_INDEX,NULL,(void *)glyphs+i,1,NULL);

      stencil=O2GlyphStencilCreate(extent.cx,extent.cy,self->_scratchBitmap,self->_scratchWidth,0,extent.cy-_gdiDescent);
      cacheStencilForGlyphIndex(self,glyphs[i],stencil);
     }
     
     drawFreeTypeBitmap(self,self->_surface,stencil,point.x,point.y,self->_textFillPaint);

     if(advances!=NULL)
      point.x+=O2SizeApplyAffineTransform(advances[i],self->_textMatrix).width;
     else {
      point.x+=O2SizeApplyAffineTransform(defaultAdvances[i],self->_textMatrix).width;
     }
    }
#endif
#else
    if(gState->_fontIsDirty){
     O2GStateClearFontIsDirty(gState);
     [self->_gdiFont release];
     self->_gdiFont=[(O2Font_gdi *)font createGDIFontSelectedInDC:self->_dc pointSize:ABS(fontSize.height)];
    }
   
    SetTextColor(self->_dc,COLORREFFromColor(O2ContextFillColor(self)));

    INT dx[count];
    
    if(advances!=NULL){
   for(i=0;i<count;i++)
      dx[i]=lroundf(O2SizeApplyAffineTransform(advances[i],Trm).width);
    }
    
    ExtTextOutW(self->_dc,lroundf(point.x),lroundf(point.y),ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,(advances!=NULL)?dx:NULL);
#endif
   }
   else if(O2FontGetPlatformType(font)==O2FontPlatformTypeFreeType){
#if 0
    O2Font_freetype *ftFont=(O2Font_freetype *)font;
    FT_Face          face=O2FontFreeTypeFace(ftFont);
      
    if(gState->_fillColorIsDirty){
     O2PaintRelease(self->_textFillPaint);
     self->_textFillPaint=paintFromColor(gState->_fillColor);
     gState->_fillColorIsDirty=NO;
}

    if(gState->_fontIsDirty){
     O2GStateClearFontIsDirty(gState);
     purgeGlyphCache(self);
    }   

    int        i;
    FT_Error   ftError;
   
    if(face==NULL){
     NSLog(@"face is NULL");
     return;
    }

    FT_GlyphSlot slot=face->glyph;

    if((ftError=FT_Set_Char_Size(face,0,ABS(fontSize.height)*64,72.0,72.0))!=0){
     NSLog(@"FT_Set_Char_Size returned %d",ftError);
     return;
    }
    
    for(i=0;i<count;i++){
     O2GlyphStencilRef stencil=stencilForGlyphIndex(self,glyphs[i]);
     
     if(stencil==NULL){
      ftError=FT_Load_Glyph(face,glyphs[i],FT_LOAD_NO_HINTING|FT_LOAD_NO_BITMAP);
      if(ftError){
       NSLog(@"FT_Load_Glyph(glyph=%d) error",glyphs[i]);
       continue; 
      }
      
      ftError=FT_Render_Glyph(face->glyph,FT_RENDER_MODE_NORMAL);
      if(ftError){
       NSLog(@"FT_Render_Glyph(glyph=%d) error",glyphs[i]);
       continue;
      }
      stencil=O2GlyphStencilCreate(slot->bitmap.width,slot->bitmap.rows,slot->bitmap.buffer,slot->bitmap.width,slot->bitmap_left,slot->bitmap_top);
      cacheStencilForGlyphIndex(self,glyphs[i],stencil);
     }
     
     drawFreeTypeBitmap(self,self->_surface,stencil,point.x,point.y,self->_textFillPaint);

     if(advances!=NULL)
      point.x+=O2SizeApplyAffineTransform(advances[i],Trm).width;
     else {
      point.x+=O2SizeApplyAffineTransform(defaultAdvances[i],Trm).width;
    //  point.x+=slot->advance.x >> 6;
     }
    }
#endif
   }
   
   const O2Size *useAdvances;
   
   if(advances!=NULL)
    useAdvances=advances;
   else
    useAdvances=defaultAdvances;
   
   O2ContextConcatAdvancesToTextMatrix(self,useAdvances,count);
}

@end
