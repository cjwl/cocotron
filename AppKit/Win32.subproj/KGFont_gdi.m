#import "KGFont_gdi.h"
#import <windows.h>

@implementation KGFont(GDI)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([KGFont_gdi class],0,NULL);
}

@end

@implementation KGFont_gdi

-initWithFontName:(NSString *)name {
   HDC   dc=GetDC(NULL);
   HFONT dummy=CreateFont(0,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,DEFAULT_PITCH|FF_DONTCARE,[name cString]);
   TEXTMETRIC    gdiMetrics;

   _name=[name copy];
   SelectObject(dc,dummy);
   GetTextMetrics(dc,&gdiMetrics);

// default values if not truetype or truetype queries fail
   _unitsPerEm=1;
   _ascent=gdiMetrics.tmAscent;
   _descent=-gdiMetrics.tmDescent;
   _leading=0;
   _capHeight=0;
   _xHeight=0;
   _italicAngle=0;
   _stemV=0;
   _bbox.origin.x=0;
   _bbox.origin.y=0;
   _bbox.size.width=gdiMetrics.tmMaxCharWidth;
   _bbox.size.height=gdiMetrics.tmHeight;
   
   if(gdiMetrics.tmPitchAndFamily&TMPF_TRUETYPE){
    int                 size=GetOutlineTextMetricsA(dc,0,NULL);
    OUTLINETEXTMETRICA *ttMetrics=__builtin_alloca(size);

    ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
    if(GetOutlineTextMetricsA(dc,size,ttMetrics)){
     LOGFONT logFont;
   
/* P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed.
   A font with height of negative otmEMSquare will have precise metrics  */

     GetObject(dummy,sizeof(logFont),&logFont);
     logFont.lfHeight=-ttMetrics->otmEMSquare;
     logFont.lfWidth=0;
     
     HFONT fontHandle=CreateFontIndirect(&logFont);
     SelectObject(dc,fontHandle);

     ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
     size=GetOutlineTextMetricsA(dc,size,ttMetrics);
   
     DeleteObject(dummy);
     ReleaseDC(NULL,dc);
     if(size!=0){
      _unitsPerEm=ttMetrics->otmEMSquare;
      if([name isEqualToString:@"Marlett"]){
       _ascent=ttMetrics->otmAscent;
       _descent=ttMetrics->otmDescent;
       _leading=ttMetrics->otmLineGap;
      }
      else {
       _ascent=ttMetrics->otmMacAscent;
       _descent=ttMetrics->otmMacDescent;
       _leading=ttMetrics->otmMacLineGap;
      }

      _capHeight=ttMetrics->otmsCapEmHeight;
      _xHeight=ttMetrics->otmsXHeight;
      _italicAngle=ttMetrics->otmItalicAngle;
      _stemV=0;
      _bbox.origin.x=ttMetrics->otmrcFontBox.left;
      _bbox.origin.y=ttMetrics->otmrcFontBox.bottom;
      _bbox.size.width=ttMetrics->otmrcFontBox.right-ttMetrics->otmrcFontBox.left;
      _bbox.size.height=ttMetrics->otmrcFontBox.top-ttMetrics->otmrcFontBox.bottom;
     }
    }
   }
   
   return self;
}

-(CGGlyph)glyphWithGlyphName:(NSString *)name {
   return 0;
}

-(NSString *)copyGlyphNameForGlyph:(CGGlyph)glyph {
   return nil;
}

-(NSData *)copyTableForTag:(uint32_t)tag {
   return nil;
}

@end
