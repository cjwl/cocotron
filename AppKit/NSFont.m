/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSFont.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/CoreGraphics.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

FOUNDATION_EXPORT char *NSUnicodeToSymbol(const unichar *characters,unsigned length,
  BOOL lossy,unsigned *resultLength,NSZone *zone);


@implementation NSFont

static inline NSGlyph glyphForCharacter(NSFont *self,unichar character){
   NSGlyphRangeTable *table=self->_glyphRangeTable;
   unsigned           range=character>>8;
   unsigned           index=character&0xFF;

   if(table->ranges[range]!=NULL)
    return table->ranges[range]->glyphs[index];

   return NSNullGlyph;
}

static inline NSGlyphMetrics *glyphInfoForGlyph(NSFont *self,NSGlyph glyph){
   if(glyph<self->_glyphInfoSet->numberOfGlyphs)
    return self->_glyphInfoSet->info+glyph;

   return NULL;
}

#define MAXUNICHAR 0xFFFF

-(void)fetchSharedGlyphRangeTable {
   static NSMapTable    *nameToGlyphRanges=NULL;
   NSGlyphRangeTable    *result;

   if(nameToGlyphRanges==NULL)
    nameToGlyphRanges=NSCreateMapTable(NSObjectMapKeyCallBacks,NSNonOwnedPointerMapValueCallBacks,0);

   result=NSMapGet(nameToGlyphRanges,_name);

   if(result==NULL){
    result=NSZoneCalloc(NULL,sizeof(NSGlyphRangeTable),1);
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
   _glyphInfoSet->info=NSZoneCalloc([self zone],sizeof(NSGlyphMetrics),_glyphInfoSet->numberOfGlyphs);
   [[NSDisplay currentDisplay] fetchGlyphKerningForFontWithName:_name pointSize:_pointSize glyphRanges:self->_glyphRangeTable infoSet:self->_glyphInfoSet];
}

static inline void fetchAllGlyphRangesIfNeeded(NSFont *self){
   if(!self->_glyphRangeTableLoaded)
    [self fetchGlyphRanges];
}

static inline NSGlyphMetrics *fetchGlyphInfoIfNeeded(NSFont *self,NSGlyph glyph){
   fetchAllGlyphRangesIfNeeded(self);
   if(self->_glyphInfoSet->info==NULL)
    [self fetchGlyphInfo];

   return glyphInfoForGlyph(self,glyph);
}

static inline NSGlyphMetrics *fetchGlyphAdvancementIfNeeded(NSFont *self,NSGlyph glyph){
   NSGlyphMetrics *info=fetchGlyphInfoIfNeeded(self,glyph);

   if(info==NULL)
    return info;

   if(!info->hasAdvancement){
    [[NSDisplay currentDisplay] fetchAdvancementsForFontWithName:self->_name pointSize:self->_pointSize glyphRanges:self->_glyphRangeTable infoSet:self->_glyphInfoSet forGlyph:glyph];
   }

   return info;
}


-(void)fetchMetrics {
   NSFontMetrics metrics;

   [[NSDisplay currentDisplay] metricsForFontWithName:[_name cString] pointSize:_pointSize metrics:&metrics];

   _boundingRect=metrics.boundingRect;

   _underlineThickness=metrics.underlineThickness;
   _underlinePosition=metrics.underlinePosition;

   _ascender=metrics.ascender;
   _descender=metrics.descender;
   _isFixedPitch=metrics.isFixedPitch;

   _glyphRangeTable=NULL;
   [self fetchSharedGlyphRangeTable];
   _glyphInfoSet=NSZoneMalloc([self zone],sizeof(NSGlyphMetricsSet));
   _glyphInfoSet->numberOfGlyphs=0;
   _glyphInfoSet->info=NULL;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [coder encodeObject:_name forKey:@"NSFont name"];
   [coder encodeFloat:_pointSize forKey:@"NSFont pointSize"];
}

-(NSString *)_translateNibFontName:(NSString *)name {

   if([name isEqual:@"Helvetica"])
    return @"Arial";
   if([name isEqual:@"Helvetica-Bold"])
    return @"Arial Bold";
   if([name isEqual:@"Helvetica-Oblique"])
    return @"Arial Italic";
   if([name isEqual:@"Helvetica-BoldOblique"])
    return @"Arial Bold Italic";

   if([name isEqual:@"Times-Roman"])
    return @"Times New Roman";
   if([name isEqual:@"Ohlfs"])
    return @"Courier New";
   if([name isEqual:@"Courier"])
    return @"Courier New";

   if([name isEqual:@"Symbol"])
    return name;

   return name;
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    NSString          *name=[self _translateNibFontName:[keyed decodeObjectForKey:@"NSName"]];
    float              size=[keyed decodeFloatForKey:@"NSSize"];
    int                flags=[keyed decodeIntForKey:@"NSfFlags"]; // ?
    
    [self dealloc];
    
    return [[NSFont fontWithName:name size:size] retain];
   }
   else {
    NSString *name=[coder decodeObjectForKey:@"NSFont name"];
    float     size=[coder decodeFloatForKey:@"NSFont pointSize"];

    [self dealloc];

    return [[NSFont fontWithName:name size:size] retain];
   }
   return nil;
}


-initWithName:(NSString *)name size:(float)size {
   _name=[name copy];
   _pointSize=size;
   _matrix[0]=_pointSize;
   _matrix[1]=0;
   _matrix[2]=0;
   _matrix[3]=_pointSize;
   _matrix[4]=0;
   _matrix[5]=0;

   if([_name isEqualToString:@"Symbol"])
    _encoding=NSSymbolStringEncoding;
   else
    _encoding=NSUnicodeStringEncoding;

   [self fetchMetrics];

   [[NSDisplay currentDisplay] addFontToCache:self];

   return self;
}

-(void)dealloc {
//NSLog(@"dealloc'ing font %@ %f",_name,_pointSize);

   [[NSDisplay currentDisplay] removeFontFromCache:self];

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

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

+(NSFont *)fontWithName:(NSString *)name size:(float)size {
   NSFont *result;

   if(name==nil)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] name==nil",self,SELNAME(_cmd)];

   result=[[NSDisplay currentDisplay] cachedFontWithName:name size:size];

   if(result==nil)
    result=[[[NSFont alloc] initWithName:name size:size] autorelease];

   return result;
}

+(NSFont *)fontWithName:(NSString *)name matrix:(const float *)matrix {
   return [self fontWithName:name size:matrix[0]];
}

+(NSFont *)systemFontOfSize:(float)size {
   return [self messageFontOfSize:size];
}

+(NSFont *)messageFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)userFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)userFixedPitchFontOfSize:(float)size {
   return [NSFont fontWithName:@"Courier New" size:(size==0)?12.0:size];
}

+(NSFont *)boldSystemFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial Bold" size:(size==0)?12.0:size];
}

+(NSFont *)menuFontOfSize:(float)size {
   float     pointSize=0;
   NSString *name=[[NSDisplay currentDisplay] menuFontNameAndSize:&pointSize];

   return [NSFont fontWithName:name size:(size==0)?pointSize:size];
}

// nb check
+(NSFont *)toolTipFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ %@ %f>",isa,_name,_pointSize];
}

-(float)pointSize {
   return _pointSize;
}

-(NSString *)fontName {
   return _name;
}

-(const float *)matrix {
   return _matrix;
}

-(NSRect)boundingRectForFont {
   return _boundingRect;
}

-(unsigned)numberOfGlyphs {
   return _glyphInfoSet->numberOfGlyphs;
}

-(BOOL)glyphIsEncoded:(NSGlyph)glyph {
   NSGlyphMetrics *info=fetchGlyphInfoIfNeeded(self,glyph);

   return (info!=NULL)?YES:NO;
}

-(NSSize)advancementForGlyph:(NSGlyph)glyph {
   NSSize       result=NSMakeSize(0,0);
   NSGlyphMetrics *info=fetchGlyphAdvancementIfNeeded(self,glyph);

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

-(NSFont *)screenFont {
//   NSUnimplementedMethod();
   return self;
}

-(float)underlinePosition {
   return _underlinePosition;
}

-(float)underlineThickness {
   return _underlineThickness;
}

-(float)ascender {
   return _ascender;
}

-(float)descender {
   return _descender;
}

-(float)defaultLineHeightForFont {
   return _ascender+-_descender;
}

-(BOOL)isFixedPitch {
   return _isFixedPitch;
}

-(void)set {
   CGContextSelectFont(NSCurrentGraphicsPort(),[_name cString],_pointSize, kCGEncodingFontSpecific);
}

-(NSStringEncoding)mostCompatibleStringEncoding {
   return _encoding;
}

-(NSMultibyteGlyphPacking)glyphPacking {
   return NSCoreGraphicsGlyphPacking;
}

-(NSPoint)positionOfGlyph:(NSGlyph)current precededByGlyph:(NSGlyph)previous isNominal:(BOOL *)isNominalp {
   NSGlyphMetrics *previousInfo;
   NSGlyphMetrics *currentInfo;
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

-(unsigned)getGlyphs:(NSGlyph *)glyphs forCharacters:(unichar *)characters length:(unsigned)length {
   int i;

   fetchAllGlyphRangesIfNeeded(self);

   if(_encoding==NSUnicodeStringEncoding){
    for(i=0;i<length;i++){
     unichar check=characters[i];

     if(check=='\n' || check=='\t')
      glyphs[i]=NSControlGlyph;
     else
      glyphs[i]=glyphForCharacter(self,check);
    }
   }
   else if(_encoding==NSSymbolStringEncoding){
    char *symbols=NSUnicodeToSymbol(characters,length,YES,&length,NULL);

    for(i=0;i<length;i++){
     char check=symbols[i];

     if(check=='\n' || check=='\t')
      glyphs[i]=NSControlGlyph;
     else
      glyphs[i]=glyphForCharacter(self,check);
    }

    NSZoneFree(NULL,symbols);
   }
   else {
    NSLog(@"unknown font encoding %d",_encoding);
   }

   return length;
}


@end

int NSConvertGlyphsToPackedGlyphs(NSGlyph *glyphs,int length,NSMultibyteGlyphPacking packing,char *outputX) {
   int      i,result=0;
   CGGlyph *output=(CGGlyph *)outputX;

   for(i=0;i<length;i++){
    NSGlyph check=glyphs[i];

    if(check!=NSNullGlyph && check!=NSControlGlyph)
     output[result++]=check;
   }

   return result*2;
}

