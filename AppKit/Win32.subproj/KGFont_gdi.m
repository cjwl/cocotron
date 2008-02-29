#import "KGFont_gdi.h"
#import "KGContext_gdi.h"
#import "Win32Display.h"
#import "Win32Font.h"

@interface KGFont(KGFont_gdi)
@end

@implementation KGFont(KGFont_gdi)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([KGFont_gdi class],0,NULL);
}

@end

@implementation KGFont_gdi

#define MAXUNICHAR 0xFFFF

-(float)pointSize {
   if(!_useMacMetrics)
    return _size;
   else {
    if (_size <= 10.0)
       return _size;
    else if (_size < 20.0)
       return _size/(1.0 + 0.2*sqrtf(0.0390625*(_size - 10.0)));
    else
       return _size/1.125;
   }
}

-(HDC)deviceContextSelfSelected {
   KGContext_gdi *context=[[Win32Display currentDisplay] contextOnPrimaryScreen];
   
   [context deviceSelectFontWithName:[_name cString] pointSize:[self pointSize]];

   return [context dc];
}


static inline NSGlyph glyphForCharacter(CGGlyphRangeTable *table,unichar character){
   unsigned range=character>>8;
   unsigned index=character&0xFF;

   if(table->ranges[range]!=NULL)
    return table->ranges[range]->glyphs[index];

   return NSNullGlyph;
}

static inline CGGlyphMetrics *glyphInfoForGlyph(CGGlyphMetricsSet *infoSet,NSGlyph glyph){
   if(glyph<infoSet->numberOfGlyphs)
    return infoSet->info+glyph;

   return NULL;
}

-(void)fetchMetrics {
   HDC           dc=[self deviceContextSelfSelected];
   TEXTMETRIC    gdiMetrics;

   GetTextMetrics(dc,&gdiMetrics);

   _metrics.emsquare=1;
   _metrics.scale=1;
   _metrics.boundingRect.origin.x=0;
   _metrics.boundingRect.origin.y=0;
   _metrics.boundingRect.size.width=gdiMetrics.tmMaxCharWidth;
   _metrics.boundingRect.size.height=gdiMetrics.tmHeight;
   _metrics.ascender=gdiMetrics.tmAscent;
   _metrics.descender=-gdiMetrics.tmDescent;
   _metrics.italicAngle=0;
   _metrics.capHeight=0;
   _metrics.leading=0;
   _metrics.xHeight=0;
   _metrics.stemV=0;
   _metrics.stemH=0;
   _metrics.underlineThickness=_size/24.0;
   if(_metrics.underlineThickness<0)
    _metrics.underlineThickness=1;

   _metrics.underlinePosition=-(_metrics.underlineThickness*2);

   _metrics.isFixedPitch=(gdiMetrics.tmPitchAndFamily&TMPF_FIXED_PITCH)?NO:YES;

   if(!(gdiMetrics.tmPitchAndFamily&TMPF_TRUETYPE))
    return;
    
   int size=GetOutlineTextMetricsA(dc,0,NULL);
   
   _useMacMetrics=NO;
   
   if(size<=0)
    return;

   OUTLINETEXTMETRICA *ttMetrics=__builtin_alloca(size);

   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   if(!GetOutlineTextMetricsA(dc,size,ttMetrics))
    return;
    
/* P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed.
   A font with height of negative otmEMSquare will have precise metrics  */
   
   HFONT   fontHandle=[[[Win32Display currentDisplay] contextOnPrimaryScreen] fontHandle];
   LOGFONT logFont;
     
   GetObject(fontHandle,sizeof(logFont),&logFont);
   logFont.lfHeight=-ttMetrics->otmEMSquare;
   logFont.lfWidth=0;
     
   fontHandle=CreateFontIndirect(&logFont);
   SelectObject(dc,fontHandle);
   
   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   size=GetOutlineTextMetricsA(dc,size,ttMetrics);
   DeleteObject(fontHandle);
   if(size<=0)
    return;

   if(![_name isEqualToString:@"Marlett"])
    _useMacMetrics=YES;

   _metrics.emsquare=ttMetrics->otmEMSquare;
   if(_useMacMetrics)
    _metrics.scale=_size;
   else
    _metrics.scale=_size*96.0/72.0;

   _metrics.boundingRect.origin.x=ttMetrics->otmrcFontBox.left;
   _metrics.boundingRect.origin.y=ttMetrics->otmrcFontBox.bottom;
   _metrics.boundingRect.size.width=ttMetrics->otmrcFontBox.right-ttMetrics->otmrcFontBox.left;
   _metrics.boundingRect.size.height=ttMetrics->otmrcFontBox.top-ttMetrics->otmrcFontBox.bottom;

   
   if(_useMacMetrics){
    _metrics.ascender=ttMetrics->otmMacAscent;
    _metrics.descender=ttMetrics->otmMacDescent;
    _metrics.leading=ttMetrics->otmMacLineGap;
   }
   else {
    _metrics.ascender=ttMetrics->otmAscent;
    _metrics.descender=ttMetrics->otmDescent;
    _metrics.leading=ttMetrics->otmLineGap;
   }
 
   _metrics.italicAngle=ttMetrics->otmItalicAngle;
   _metrics.capHeight=ttMetrics->otmsCapEmHeight;
   _metrics.xHeight=ttMetrics->otmsXHeight;

   _metrics.underlineThickness=ttMetrics->otmsUnderscoreSize;
   if(_metrics.underlineThickness<0)
    _metrics.underlineThickness=1;
   _metrics.underlinePosition=ttMetrics->otmsUnderscorePosition;
}

-(void)loadGlyphRangeTable {
   HDC                dc=[self deviceContextSelfSelected];
   NSRange            range=NSMakeRange(0,MAXUNICHAR);
   unichar            characters[range.length];
   unsigned short     glyphs[range.length];
   unsigned           i;
   HANDLE             library=LoadLibrary("GDI32");
   FARPROC            getGlyphIndices=GetProcAddress(library,"GetGlyphIndicesW");

   for(i=0;i<range.length;i++)
    characters[i]=range.location+i;

// GetGlyphIndicesW is around twice as fast as GetCharacterPlacementW, but only available on Win2k/XP
   if(getGlyphIndices!=NULL)
    getGlyphIndices(dc,characters,range.length,glyphs,0);
   else {
    GCP_RESULTSW results;

    results.lStructSize=sizeof(GCP_RESULTS);
    results.lpOutString=NULL;
    results.lpOrder=NULL;
    results.lpDx=NULL;
    results.lpCaretPos=NULL;
    results.lpClass=NULL;
    results.lpGlyphs=glyphs;
    results.nGlyphs=range.length;
    results.nMaxFit=0;

    if(GetCharacterPlacementW(dc,characters,range.length,0,&results,0)==0)
     NSLog(@"GetCharacterPlacementW failed");
   }

   _glyphRangeTable->numberOfGlyphs=0;
   for(i=0;i<range.length;i++){
    unsigned short glyph=glyphs[i];
    unsigned range=i>>8;
    unsigned index=i&0xFF;

    if(glyph!=0){
     if(glyph>_glyphRangeTable->numberOfGlyphs)
      _glyphRangeTable->numberOfGlyphs=glyph;

     if(_glyphRangeTable->ranges[range]==NULL)
      _glyphRangeTable->ranges[range]=NSZoneCalloc(NULL,sizeof(CGGlyphRange),1);

     _glyphRangeTable->ranges[range]->glyphs[index]=glyph;
    }
   }
   _glyphRangeTable->numberOfGlyphs++;
   _glyphRangeTable->characters=NSZoneCalloc(NULL,sizeof(unichar),_glyphRangeTable->numberOfGlyphs);
   for(i=0;i<range.length;i++){
    unsigned short glyph=glyphs[i];
    
    _glyphRangeTable->characters[glyph]=range.location+i;
   }
}

-(void)fetchGlyphKerning {
   HDC         dc=[self deviceContextSelfSelected];
   int         i,numberOfPairs=GetKerningPairs(dc,0,NULL);
   KERNINGPAIR pairs[numberOfPairs];

   GetKerningPairsW(dc,numberOfPairs,pairs);

   for(i=0;i<numberOfPairs;i++){
    unichar previousCharacter=pairs[i].wFirst;
    unichar currentCharacter=pairs[i].wSecond;
    float   xoffset=pairs[i].iKernAmount;
    NSGlyph previous=glyphForCharacter(_glyphRangeTable,previousCharacter);
    NSGlyph current=glyphForCharacter(_glyphRangeTable,currentCharacter);

    if(pairs[i].iKernAmount==0)
     continue;

    if(current==NSNullGlyph)
     ;//NSLog(@"unable to generate kern pair 0x%04X 0x%04X %f",previousCharacter,currentCharacter,xoffset);
    else {
     CGGlyphMetrics *info=glyphInfoForGlyph(_glyphInfoSet,current);

     if(info==NULL)
      NSLog(@"no info for glyph %d",current);
     else {
      unsigned index=info->numberOfKerningOffsets;

      if(index==0)
       info->kerningOffsets=NSZoneMalloc([self zone],sizeof(CGKerningOffset));
      else
       info->kerningOffsets=NSZoneRealloc([self zone],info->kerningOffsets,
               sizeof(CGKerningOffset)*(index+1));

      info->kerningOffsets[index].previous=previous;
      info->kerningOffsets[index].xoffset=xoffset;
      info->numberOfKerningOffsets++;
     }
    }
   }
}

-(void)fetchAdvancementsForGlyph:(CGGlyph)glyph {
   HDC       dc=[self deviceContextSelfSelected];
   ABCFLOAT *abc;
   int       i,max;

   for(max=0;max<MAXUNICHAR;max++){
    NSGlyph check=glyphForCharacter(_glyphRangeTable,max);

    if(check==glyph)
     break;
   }

   if(max==MAXUNICHAR){
    CGGlyphMetrics *info=glyphInfoForGlyph(_glyphInfoSet,glyph);

    info->hasAdvancement=YES;
    info->advanceA=0;
    info->advanceB=0;
    info->advanceC=0;
    return;
   }

   max=((max/128)+1)*128;
   abc=__builtin_alloca(sizeof(ABCFLOAT)*max);
   if(!GetCharABCWidthsFloatW(dc,0,max-1,abc))
    NSLog(@"GetCharABCWidthsFloat failed");
   else {
    for(i=0;i<max;i++){
     NSGlyph      glyph=glyphForCharacter(_glyphRangeTable,i);
     CGGlyphMetrics *info=glyphInfoForGlyph(_glyphInfoSet,glyph);

     if(info==NULL)
      NSLog(@"no info for glyph %d",glyph);
     else {
      info->hasAdvancement=YES;
      info->advanceA=abc[i].abcfA;
      info->advanceB=abc[i].abcfB;
      info->advanceC=abc[i].abcfC;
     }
    }
   }
}

// not complete
-(void)appendCubicOutlinesToPath:(KGMutablePath *)path glyphs:(CGGlyph *)glyphs length:(unsigned)length {
   HDC dc=[self deviceContextSelfSelected];
   int size=GetOutlineTextMetricsA(dc,0,NULL);
    
   if(size<=0)
    return;

   OUTLINETEXTMETRICA *ttMetrics=__builtin_alloca(size);

   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   if(!GetOutlineTextMetricsA(dc,size,ttMetrics))
    return;
    
/* P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed.
   A font with height of negative otmEMSquare will have precise metrics  */
   
   HFONT   fontHandle=[[[Win32Display currentDisplay] contextOnPrimaryScreen] fontHandle];
   LOGFONT logFont;
     
   GetObject(fontHandle,sizeof(logFont),&logFont);
   logFont.lfHeight=-ttMetrics->otmEMSquare;
   logFont.lfWidth=0;
     
   fontHandle=CreateFontIndirect(&logFont);
   SelectObject(dc,fontHandle);
   DeleteObject(fontHandle);

   int i;
   for(i=0;i<length;i++){
    int          outlineSize=GetGlyphOutline(dc,glyphs[i],GGO_BEZIER|GGO_GLYPH_INDEX,NULL,0,NULL,NULL);
    GLYPHMETRICS glyphMetrics;
    void        *outline=__builtin_alloca(outlineSize);

    if(GetGlyphOutline(dc,glyphs[i],GGO_BEZIER|GGO_GLYPH_INDEX,&glyphMetrics,outlineSize,outline,NULL)==size){
    }
   }
   
}

@end
