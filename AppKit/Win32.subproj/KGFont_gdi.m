#import "KGFont_gdi.h"
#import "KGRenderingContext_gdi.h"
#import "Win32Display.h"

@interface KGFont(KGFont_gdi)
@end

@implementation KGFont(KGFont_gdi)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([KGFont_gdi class],0,NULL);
}

@end

@implementation KGFont_gdi

#define MAXUNICHAR 0xFFFF

-(HDC)deviceContext {
   KGRenderingContext_gdi *rc=[[Win32Display currentDisplay] renderingContextOnPrimaryScreen];
   
   [rc selectFontWithName:[_name cString] pointSize:_size];

   return [rc dc];
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
   HDC           dc=[self deviceContext];
   TEXTMETRIC    gdiMetrics;

   GetTextMetrics(dc,&gdiMetrics);

   _metrics.boundingRect.origin.x=0;
   _metrics.boundingRect.origin.y=0;
   _metrics.boundingRect.size.width=gdiMetrics.tmMaxCharWidth;
   _metrics.boundingRect.size.height=gdiMetrics.tmHeight;

   _metrics.ascender=gdiMetrics.tmAscent;
   _metrics.descender=-gdiMetrics.tmDescent;

   _metrics.underlineThickness=_size/24;
   if(_metrics.underlineThickness<0)
    _metrics.underlineThickness=1;

   _metrics.underlinePosition=-(_metrics.underlineThickness*2);

   _metrics.isFixedPitch=(gdiMetrics.tmPitchAndFamily&TMPF_FIXED_PITCH)?NO:YES;
}

-(void)loadGlyphRangeTable {
   HDC                dc=[self deviceContext];
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
   HDC         dc=[self deviceContext];
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
   HDC       dc=[self deviceContext];
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

@end
