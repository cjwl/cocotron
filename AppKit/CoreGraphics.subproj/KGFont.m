#import <AppKit/KGFont.h>
#import "KGPDFArray.h"
#import <AppKit/KGPDFDictionary.h>
#import "KGPDFContext.h"
#import <Foundation/NSRaise.h>

@implementation KGFont

static inline CGGlyph glyphForCharacter(KGFont *self,unichar character){
   CGGlyphRangeTable *table=self->_glyphRangeTable;
   unsigned           range=character>>8;
   unsigned           index=character&0xFF;

   if(table->ranges[range]!=NULL)
    return table->ranges[range]->glyphs[index];

   return CGNullGlyph;
}

static inline unichar characterForGlyph(KGFont *self,CGGlyph glyph){
   if(glyph<self->_glyphRangeTable->numberOfGlyphs)
    return self->_glyphRangeTable->characters[glyph];
   
   return 0;
}

static inline CGGlyphMetrics *glyphInfoForGlyph(KGFont *self,CGGlyph glyph){
   if(glyph<self->_glyphInfoSet->numberOfGlyphs)
    return self->_glyphInfoSet->info+glyph;

   return NULL;
}

#define MAXUNICHAR 0xFFFF

-(void)fetchSharedGlyphRangeTable {
   static NSMapTable    *nameToGlyphRanges=NULL;
   CGGlyphRangeTable    *result;

   if(nameToGlyphRanges==NULL)
    nameToGlyphRanges=NSCreateMapTable(NSObjectMapKeyCallBacks,NSNonOwnedPointerMapValueCallBacks,0);

   result=NSMapGet(nameToGlyphRanges,_name);

   if(result==NULL){
    result=NSZoneCalloc(NULL,sizeof(CGGlyphRangeTable),1);
    NSMapInsert(nameToGlyphRanges,_name,result);
   }

   _glyphRangeTable=result;
}

-(void)fetchGlyphRanges {
   [self loadGlyphRangeTable];

   _glyphRangeTableLoaded=YES;
   _glyphInfoSet->numberOfGlyphs=_glyphRangeTable->numberOfGlyphs;
}

-(void)fetchGlyphInfo {
   _glyphInfoSet->info=NSZoneCalloc([self zone],sizeof(CGGlyphMetrics),_glyphInfoSet->numberOfGlyphs);
   [self fetchGlyphKerning];
   
}

static inline void fetchAllGlyphRangesIfNeeded(KGFont *self){
   if(!self->_glyphRangeTableLoaded)
    [self fetchGlyphRanges];
}

static inline CGGlyphMetrics *fetchGlyphInfoIfNeeded(KGFont *self,CGGlyph glyph){
   fetchAllGlyphRangesIfNeeded(self);
   if(self->_glyphInfoSet->info==NULL)
    [self fetchGlyphInfo];

   return glyphInfoForGlyph(self,glyph);
}

static inline CGGlyphMetrics *fetchGlyphAdvancementIfNeeded(KGFont *self,CGGlyph glyph){
   CGGlyphMetrics *info=fetchGlyphInfoIfNeeded(self,glyph);

   if(info==NULL)
    return info;

   if(!info->hasAdvancement){
    [self fetchAdvancementsForGlyph:glyph];
   }

   return info;
}

-initWithName:(NSString *)name size:(float)size {
   _name=[name copy];
   _size=size;
   [self fetchMetrics];
   _glyphRangeTable=NULL;
   [self fetchSharedGlyphRangeTable];
   _glyphInfoSet=NSZoneMalloc([self zone],sizeof(CGGlyphMetricsSet));
   _glyphInfoSet->numberOfGlyphs=0;
   _glyphInfoSet->info=NULL;
   return self;
}

-(void)dealloc {
   [_name release];
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

-(NSString *)name {
   return _name;
}

-(float)pointSize {
   return _size;
}

-(float)nominalSize {
   return _size;
}

-(NSRect)boundingRect {
   NSRect result=_metrics.boundingRect;
   
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

-(float)underlineThickness {
   return _metrics.underlineThickness/_metrics.emsquare*_metrics.scale;
}

-(float)underlinePosition {
   return _metrics.underlinePosition/_metrics.emsquare*_metrics.scale;
}

-(BOOL)isFixedPitch {
   return _metrics.isFixedPitch;
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

-(BOOL)glyphIsEncoded:(CGGlyph)glyph {
   CGGlyphMetrics *info=fetchGlyphInfoIfNeeded(self,glyph);

   return (info!=NULL)?YES:NO;
}

-(NSSize)advancementForGlyph:(CGGlyph)glyph {
   NSSize       result=NSMakeSize(0,0);
   CGGlyphMetrics *info=fetchGlyphAdvancementIfNeeded(self,glyph);

   if(info==NULL){
    NSLog(@"no info for glyph %d",glyph);
    return result;
   }

   result.width+=info->advanceA+info->advanceB+info->advanceC;

   return result;
}

-(NSSize)maximumAdvancement {
   NSSize max=NSZeroSize;
   int    glyph;

   fetchAllGlyphRangesIfNeeded(self);

   for(glyph=0;glyph<self->_glyphInfoSet->numberOfGlyphs;glyph++){
    NSSize advance=[self advancementForGlyph:glyph];

    max.width=MAX(max.width,advance.width);
    max.height=MAX(max.height,advance.height);
   }

   return max;
}

-(NSPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp {
   CGGlyphMetrics *previousInfo;
   CGGlyphMetrics *currentInfo;
   NSPoint      result=NSMakePoint(0,0);

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

// FIX, lame, this needs to do encoding properly
-(void)getBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length {
   unichar  characters[length];
   unsigned i;
   
   [self getCharacters:characters forGlyphs:glyphs length:length];
   for(i=0;i<length;i++)
    if(characters[i]<0xFF)
     bytes[i]=characters[i];
    else
     bytes[i]=' ';
}

// FIX, lame, this needs to do encoding properly
-(void)getGlyphs:(CGGlyph *)glyphs forBytes:(const unsigned char *)bytes length:(unsigned)length {
   unichar characters[length];
   int     i;
   
   for(i=0;i<length;i++)
    characters[i]=bytes[i];
   
   [self getGlyphs:glyphs forCharacters:characters length:length];
}

-(void)getAdvancements:(NSSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
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

-(NSSize)advancementForNominalGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   NSSize result=NSMakeSize(0,0);
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

-(KGPDFArray *)_pdfWidths {
   KGPDFArray   *result=[KGPDFArray pdfArray];
   unsigned char bytes[256];
   CGGlyph       glyphs[256];
   NSSize        advancements[256];
   int           i;
   
   for(i=0;i<256;i++)
    bytes[i]=i;
    
   [self getGlyphs:glyphs forBytes:bytes length:256];
   [self getAdvancements:advancements forGlyphs:glyphs count:256];

// FIX, probably not entirely accurate, you can get precise widths out of the TrueType data
   for(i=0;i<255;i++){
    KGPDFReal width=(advancements[i].width/_size)*1000;
    
    [result addNumber:width];
   }
   
   return result;
}

-(const char *)pdfFontName {
// lame
   return [[[_name componentsSeparatedByString:@" "] componentsJoinedByString:@","] cString];
}

-(KGPDFDictionary *)_pdfFontDescriptor {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

   [result setNameForKey:"Type" value:"FontDescriptor"];
   [result setNameForKey:"FontName" value:[self pdfFontName]];
   [result setIntegerForKey:"Flags" value:32];
   
   KGPDFReal bbox[4];
   
   bbox[0]=_metrics.boundingRect.origin.x;
   bbox[1]=_metrics.boundingRect.origin.y;
   bbox[2]=_metrics.boundingRect.size.width;
   bbox[3]=_metrics.boundingRect.size.height;
   [result setObjectForKey:"FontBBox" value:[KGPDFArray pdfArrayWithNumbers:bbox count:4]];
   [result setIntegerForKey:"ItalicAngle" value:_metrics.italicAngle];
   [result setIntegerForKey:"Ascent" value:_metrics.ascender];
   [result setIntegerForKey:"Descent" value:_metrics.descender];
   [result setIntegerForKey:"CapHeight" value:_metrics.capHeight];
   [result setIntegerForKey:"StemV" value:_metrics.stemV];
   [result setIntegerForKey:"StemH" value:_metrics.stemH];
   
   return result;
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFObject *reference=[context referenceForFontWithName:_name size:_size];
   
   if(reference==nil){
    KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

    [result setNameForKey:"Type" value:"Font"];
    [result setNameForKey:"Subtype" value:"TrueType"];
    [result setNameForKey:"BaseFont" value:[self pdfFontName]];
    [result setIntegerForKey:"FirstChar" value:0];
    [result setIntegerForKey:"LastChar" value:255];
    [result setObjectForKey:"Widths" value:[context encodeIndirectPDFObject:[self _pdfWidths]]];
    [result setObjectForKey:"FontDescriptor" value:[context encodeIndirectPDFObject:[self _pdfFontDescriptor]]];

    [result setNameForKey:"Encoding" value:"WinAnsiEncoding"];

    reference=[context encodeIndirectPDFObject:result];
    [context setReference:reference forFontWithName:_name size:_size];
   }
   
   return reference;
}

-(void)fetchMetrics {
   NSInvalidAbstractInvocation();
}

-(void)loadGlyphRangeTable {
   NSInvalidAbstractInvocation();
}

-(void)fetchGlyphKerning {
   NSInvalidAbstractInvocation();
}

-(void)fetchAdvancementsForGlyph:(CGGlyph)glyph {
   NSInvalidAbstractInvocation();
}

-(void)appendCubicOutlinesToPath:(KGMutablePath *)path glyphs:(CGGlyph *)glyphs length:(unsigned)length {
   NSInvalidAbstractInvocation();
}

@end
