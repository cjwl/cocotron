#import "KTFont_gdi.h"
#import "KGContext_gdi.h"
#import "Win32Display.h"
#import "Win32Font.h"
#import <AppKit/KGMutablePath.h>

#define MAXUNICHAR 0xFFFF

@interface KTFont(KTFont_gdi)
@end

@implementation KTFont(KTFont_gdi)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([KTFont_gdi class],0,NULL);
}

@end

@implementation KTFont_gdi

static inline CGGlyph glyphForCharacter(KTFont_gdi *self,unichar character){
   CGGlyphRangeTable *table=self->_glyphRangeTable;
   unsigned           range=character>>8;
   unsigned           index=character&0xFF;

   if(table->ranges[range]!=NULL)
    return table->ranges[range]->glyphs[index];

   return CGNullGlyph;
}

static inline unichar characterForGlyph(KTFont_gdi *self,CGGlyph glyph){
   if(glyph<self->_glyphRangeTable->numberOfGlyphs)
    return self->_glyphRangeTable->characters[glyph];
   
   return 0;
}

static inline CGGlyphMetrics *glyphInfoForGlyph(KTFont_gdi *self,CGGlyph glyph){
   if(glyph<self->_glyphInfoSet->numberOfGlyphs)
    return self->_glyphInfoSet->info+glyph;

   return NULL;
}

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

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc {
   int        height=([self pointSize]*GetDeviceCaps(dc,LOGPIXELSY))/72.0;
   Win32Font *result=[[Win32Font alloc] initWithName:[self name] size:NSMakeSize(0,height) antialias:NO];
   
   SelectObject(dc,[result fontHandle]);
   return result;
}

-(BOOL)fetchSharedGlyphRangeTable {
   static NSMapTable    *nameToGlyphRanges=NULL;
   CGGlyphRangeTable    *shared;
   BOOL                  result=YES;
   
   if(nameToGlyphRanges==NULL)
    nameToGlyphRanges=NSCreateMapTable(NSObjectMapKeyCallBacks,NSNonOwnedPointerMapValueCallBacks,0);

   shared=NSMapGet(nameToGlyphRanges,[self name]);

   if(shared==NULL){
    result=NO;
    shared=NSZoneCalloc(NULL,sizeof(CGGlyphRangeTable),1);
    NSMapInsert(nameToGlyphRanges,[self name],shared);
   }

   _glyphRangeTable=shared;
   
   return result;
}

-(void)loadGlyphRangeTable {
   if([self fetchSharedGlyphRangeTable])
    return;

   HDC                dc=GetDC(NULL);
   Win32Font         *gdiFont=[self createGDIFontSelectedInDC:dc];
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
   ReleaseDC(NULL,dc);
   [gdiFont release];
   
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

-(void)fetchGlyphRanges {
   [self loadGlyphRangeTable];
   _glyphInfoSet->numberOfGlyphs=_glyphRangeTable->numberOfGlyphs;
}

-(void)fetchGlyphKerning {
   HDC         dc=GetDC(NULL);
   Win32Font  *gdiFont=[self createGDIFontSelectedInDC:dc];
   int         i,numberOfPairs=GetKerningPairs(dc,0,NULL);
   KERNINGPAIR pairs[numberOfPairs];

   GetKerningPairsW(dc,numberOfPairs,pairs);
   ReleaseDC(NULL,dc);
   [gdiFont release];
   
   for(i=0;i<numberOfPairs;i++){
    unichar previousCharacter=pairs[i].wFirst;
    unichar currentCharacter=pairs[i].wSecond;
    float   xoffset=pairs[i].iKernAmount;
    NSGlyph previous=glyphForCharacter(self,previousCharacter);
    NSGlyph current=glyphForCharacter(self,currentCharacter);

    if(pairs[i].iKernAmount==0)
     continue;

    if(current==NSNullGlyph)
     ;//NSLog(@"unable to generate kern pair 0x%04X 0x%04X %f",previousCharacter,currentCharacter,xoffset);
    else {
     CGGlyphMetrics *info=glyphInfoForGlyph(self,current);

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

-(void)fetchGlyphInfo {
   _glyphInfoSet->info=NSZoneCalloc([self zone],sizeof(CGGlyphMetrics),_glyphInfoSet->numberOfGlyphs);
   [self fetchGlyphKerning];
   
}

static inline void fetchAllGlyphRangesIfNeeded(KTFont_gdi *self){
   if(self->_glyphRangeTable==NULL)
    [self fetchGlyphRanges];
}

static inline CGGlyphMetrics *fetchGlyphInfoIfNeeded(KTFont_gdi *self,CGGlyph glyph){
   fetchAllGlyphRangesIfNeeded(self);
   if(self->_glyphInfoSet->info==NULL)
    [self fetchGlyphInfo];

   return glyphInfoForGlyph(self,glyph);
}

-(void)fetchAdvancementsForGlyph:(CGGlyph)glyph {
   HDC        dc=GetDC(NULL);
   Win32Font *gdiFont=[self createGDIFontSelectedInDC:dc];
   ABCFLOAT *abc;
   int       i,max;

   for(max=0;max<MAXUNICHAR;max++){
    NSGlyph check=glyphForCharacter(self,max);

    if(check==glyph)
     break;
   }

   if(max==MAXUNICHAR){
    CGGlyphMetrics *info=glyphInfoForGlyph(self,glyph);

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
     NSGlyph      glyph=glyphForCharacter(self,i);
     CGGlyphMetrics *info=glyphInfoForGlyph(self,glyph);

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
   ReleaseDC(NULL,dc);
   [gdiFont release];
}

static inline CGGlyphMetrics *fetchGlyphAdvancementIfNeeded(KTFont_gdi *self,CGGlyph glyph){
   CGGlyphMetrics *info=fetchGlyphInfoIfNeeded(self,glyph);

   if(info==NULL)
    return info;

   if(!info->hasAdvancement){
    [self fetchAdvancementsForGlyph:glyph];
   }

   return info;
}

-(void)fetchMetrics {
   HDC           dc=GetDC(NULL);
   Win32Font    *gdiFont=[self createGDIFontSelectedInDC:dc];
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

   if(!(gdiMetrics.tmPitchAndFamily&TMPF_TRUETYPE)){
    ReleaseDC(NULL,dc);
    [gdiFont release];
    return;
   }
    
   int size=GetOutlineTextMetricsA(dc,0,NULL);
   
   _useMacMetrics=NO;
   
   if(size<=0){
    ReleaseDC(NULL,dc);
    [gdiFont release];
    return;
   }

   OUTLINETEXTMETRICA *ttMetrics=__builtin_alloca(size);

   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   if(!GetOutlineTextMetricsA(dc,size,ttMetrics)){
    ReleaseDC(NULL,dc);
    [gdiFont release];
    return;
   }
       
/* P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed.
   A font with height of negative otmEMSquare will have precise metrics  */
   
   LOGFONT logFont;
   
   GetObject([gdiFont fontHandle],sizeof(logFont),&logFont);
   logFont.lfHeight=-ttMetrics->otmEMSquare;
   logFont.lfWidth=0;
     
   HFONT fontHandle=CreateFontIndirect(&logFont);
   SelectObject(dc,fontHandle);
   
   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   size=GetOutlineTextMetricsA(dc,size,ttMetrics);
   DeleteObject(fontHandle);
   ReleaseDC(NULL,dc);
   [gdiFont release];
   
   if(size<=0){
    return;
   }

   if(![[self name] isEqualToString:@"Marlett"])
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

-initWithFont:(KGFont *)font size:(CGFloat)size {
   [super initWithFont:font size:size];
   [self fetchMetrics];
   _glyphRangeTable=NULL;
   _glyphInfoSet=NSZoneMalloc([self zone],sizeof(CGGlyphMetricsSet));
   _glyphInfoSet->numberOfGlyphs=0;
   _glyphInfoSet->info=NULL;
   return self;
}

-(void)dealloc {
   _glyphRangeTable=NULL;

   if(_glyphInfoSet!=NULL){
    if(_glyphInfoSet->info!=NULL){
     unsigned i;

     for(i=0;i<_glyphInfoSet->numberOfGlyphs;i++){
      if(_glyphInfoSet->info[i].kerningOffsets!=NULL)
       NSZoneFree([self zone],_glyphInfoSet->info[i].kerningOffsets);
     }
     NSZoneFree([self zone],_glyphInfoSet->info);
    }

    NSZoneFree([self zone],_glyphInfoSet);
   }

   [super dealloc];
}

-(CGRect)boundingRect {
   CGRect result=_metrics.boundingRect;
   
   result.origin.x/=_metrics.emsquare*_metrics.scale;
   result.origin.y/=_metrics.emsquare*_metrics.scale;
   result.size.width/=_metrics.emsquare*_metrics.scale;
   result.size.height/=_metrics.emsquare*_metrics.scale;
   
   return result;
}

-(float)ascender {
   return _metrics.ascender/_metrics.emsquare*_metrics.scale;
}

-(float)descender {
   return _metrics.descender/_metrics.emsquare*_metrics.scale;
}

-(float)leading {
   return _metrics.leading/_metrics.emsquare*_metrics.scale;
}

-(float)stemV {
   return _metrics.stemV;
}

-(float)stemH {
   return _metrics.stemH;
}

-(float)underlineThickness {
   return _metrics.underlineThickness/_metrics.emsquare*_metrics.scale;
}

-(float)underlinePosition {
   return _metrics.underlinePosition/_metrics.emsquare*_metrics.scale;
}

-(float)italicAngle {
   return _metrics.italicAngle;
}

-(float)xHeight {
   return _metrics.xHeight/_metrics.emsquare*_metrics.scale;
}

-(float)capHeight {
   return _metrics.capHeight/_metrics.emsquare*_metrics.scale;
}

-(unsigned)numberOfGlyphs {
   return _glyphInfoSet->numberOfGlyphs;
}

-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp {
   CGGlyphMetrics *previousInfo;
   CGGlyphMetrics *currentInfo;
   CGPoint      result=CGPointMake(0,0);

   previousInfo=fetchGlyphAdvancementIfNeeded(self,previous);
   currentInfo=fetchGlyphAdvancementIfNeeded(self,current);

   *isNominalp=YES;

   if(previous==CGNullGlyph){
    if(currentInfo!=NULL){
    }
   }
   else {
    if(previousInfo!=NULL)
     result.x+=previousInfo->advanceA+previousInfo->advanceB+previousInfo->advanceC;

    if(current==CGNullGlyph){
    }
    else if(currentInfo!=NULL){
     int i;

     for(i=0;i<currentInfo->numberOfKerningOffsets;i++){
      if(currentInfo->kerningOffsets[i].previous==previous){
       result.x+=currentInfo->kerningOffsets[i].xoffset;
       *isNominalp=NO;
       break;
      }
     }
    }
   }

   return result;
}

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length {
   int i;

   fetchAllGlyphRangesIfNeeded(self);
   for(i=0;i<length;i++)
    glyphs[i]=glyphForCharacter(self,characters[i]);
}

-(void)getCharacters:(unichar *)characters forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length {
   int i;

   fetchAllGlyphRangesIfNeeded(self);
   for(i=0;i<length;i++)
    characters[i]=characterForGlyph(self,glyphs[i]);
}

-(void)getAdvancements:(CGSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   int i;
   
   for(i=0;i<count;i++){
    CGGlyphMetrics *info=fetchGlyphAdvancementIfNeeded(self,glyphs[i]);

    if(info==NULL){
     NSLog(@"no info for glyph %d",glyphs[i]);
     advancements[i].width=0;
     advancements[i].height=0;
    }
    else {
     advancements[i].width=info->advanceA+info->advanceB+info->advanceC;
     advancements[i].height=0;
    }
   }
}

-(CGSize)advancementForNominalGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   CGSize result=CGSizeMake(0,0);
   int i;
   
   for(i=0;i<count;i++){
    CGGlyphMetrics *info=fetchGlyphAdvancementIfNeeded(self,glyphs[i]);

    if(info==NULL)
     NSLog(@"no info for glyph %d",glyphs[i]);
    else {
     result.width+=info->advanceA+info->advanceB+info->advanceC;
     result.height+=0;
    }
   }
   
   return result;
}


// not complete
-(KGPath *)createPathForGlyph:(CGGlyph)glyph transform:(CGAffineTransform *)xform {
   KGMutablePath *result=[[KGMutablePath alloc] init];
   HDC        dc=GetDC(NULL);
   Win32Font *gdiFont=[self createGDIFontSelectedInDC:dc];
   int        size=GetOutlineTextMetricsA(dc,0,NULL);
    
   if(size<=0){
    ReleaseDC(NULL,dc);
    [gdiFont release];
    return result;
   }

   OUTLINETEXTMETRICA *ttMetrics=__builtin_alloca(size);

   ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICA);
   if(!GetOutlineTextMetricsA(dc,size,ttMetrics))
    return result;
    
/* P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed.
   A font with height of negative otmEMSquare will have precise metrics  */
   
   LOGFONT logFont;
     
   GetObject([gdiFont fontHandle],sizeof(logFont),&logFont);
   logFont.lfHeight=-ttMetrics->otmEMSquare;
   logFont.lfWidth=0;
     
   HFONT fontHandle=CreateFontIndirect(&logFont);
   SelectObject(dc,fontHandle);
   DeleteObject(fontHandle);

   int          outlineSize=GetGlyphOutline(dc,glyph,GGO_BEZIER|GGO_GLYPH_INDEX,NULL,0,NULL,NULL);
   GLYPHMETRICS glyphMetrics;
   void        *outline=__builtin_alloca(outlineSize);

   if(GetGlyphOutline(dc,glyph,GGO_BEZIER|GGO_GLYPH_INDEX,&glyphMetrics,outlineSize,outline,NULL)==size){
   }

   ReleaseDC(NULL,dc);
   [gdiFont release];
   
   return result;
}

@end
