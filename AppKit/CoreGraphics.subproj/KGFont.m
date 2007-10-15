#import <AppKit/KGFont.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/KGPDFDictionary.h>

@implementation KGFont

static inline CGGlyph glyphForCharacter(KGFont *self,unichar character){
   CGGlyphRangeTable *table=self->_glyphRangeTable;
   unsigned           range=character>>8;
   unsigned           index=character&0xFF;

   if(table->ranges[range]!=NULL)
    return table->ranges[range]->glyphs[index];

   return NSNullGlyph;
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
   [[NSDisplay currentDisplay] loadGlyphRangeTable:_glyphRangeTable fontName:_name range:NSMakeRange(0,0xFFFF)];

   _glyphRangeTableLoaded=YES;
   _glyphInfoSet->numberOfGlyphs=_glyphRangeTable->numberOfGlyphs;
}

-(void)fetchGlyphInfo {
   _glyphInfoSet->info=NSZoneCalloc([self zone],sizeof(CGGlyphMetrics),_glyphInfoSet->numberOfGlyphs);
   [[NSDisplay currentDisplay] fetchGlyphKerningForFontWithName:_name pointSize:_size glyphRanges:self->_glyphRangeTable infoSet:self->_glyphInfoSet];
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
    [[NSDisplay currentDisplay] fetchAdvancementsForFontWithName:self->_name pointSize:self->_size glyphRanges:self->_glyphRangeTable infoSet:self->_glyphInfoSet forGlyph:glyph];
   }

   return info;
}

-initWithName:(NSString *)name size:(float)size {
   _name=[name copy];
   _size=size;
   
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

   if(previous==NSNullGlyph){
    if(currentInfo!=NULL){
    }
   }
   else {
    if(previousInfo!=NULL)
     result.x+=previousInfo->advanceA+previousInfo->advanceB+previousInfo->advanceC;

    if(current==NSNullGlyph){
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

-(unsigned)getGlyphs:(CGGlyph *)glyphs forCharacters:(unichar *)characters length:(unsigned)length {
   int i;

   fetchAllGlyphRangesIfNeeded(self);
   for(i=0;i<length;i++)
    glyphs[i]=glyphForCharacter(self,characters[i]);

   return length;
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

-(KGPDFObject *)pdfObjectInContext:(KGPDFContext *)context {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

   [result setNameForKey:"Type" value:"Font"];
   [result setNameForKey:"Subtype" value:"TrueType"];
   [result setNameForKey:"BaseFont" value:[_name cString]];
   [result setIntegerForKey:"FirstChar" value:0];
   [result setIntegerForKey:"FirstChar" value:255];
   
   return result;
}

@end
