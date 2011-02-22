/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSFont.h>
#import <AppKit/NSFontDescriptor.h>
#import <AppKit/NSFontFamily.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSRaise.h>

FOUNDATION_EXPORT char *NSUnicodeToSymbol(const unichar *characters,unsigned length,
  BOOL lossy,unsigned *resultLength,NSZone *zone);


@implementation NSFont

static unsigned _fontCacheCapacity=0;
static unsigned _fontCacheSize=0;
static NSFont **_fontCache=NULL;

+(void)initialize {
   if(self==[NSFont class]){
    _fontCacheCapacity=4;
    _fontCacheSize=0;
    _fontCache=NSZoneMalloc([self zone],sizeof(NSFont *)*_fontCacheCapacity);
   }
}

+(unsigned)_cacheIndexOfFontWithName:(NSString *)name size:(float)size {
   unsigned i;

   for(i=0;i<_fontCacheSize;i++){
    NSFont *check=_fontCache[i];

    if(check!=nil && [[check fontName] isEqualToString:name] && [check pointSize]==size)
     return i;
   }

   return NSNotFound;
}

+(NSFont *)cachedFontWithName:(NSString *)name size:(float)size {
   unsigned i=[self _cacheIndexOfFontWithName:name size:size];

   return (i==NSNotFound)?(NSFont *)nil:_fontCache[i];
}

+(void)addFontToCache:(NSFont *)font {
   unsigned i;

   for(i=0;i<_fontCacheSize;i++){
    if(_fontCache[i]==nil){
     _fontCache[i]=font;
     return;
    }
   }

   if(_fontCacheSize>=_fontCacheCapacity){
    _fontCacheCapacity*=2;
    _fontCache=NSZoneRealloc([self zone],_fontCache,sizeof(NSFont *)*_fontCacheCapacity);
   }
   _fontCache[_fontCacheSize++]=font;
}

+(void)removeFontFromCache:(NSFont *)font {
   unsigned i=[self _cacheIndexOfFontWithName:[font fontName] size:[font pointSize]];

   if(i!=NSNotFound)
    _fontCache[i]=nil;
}

+(float)systemFontSize {
   return 12.0;
}

+(float)smallSystemFontSize {
   return 10.0;
}

+(float)labelFontSize {
   return 12.0;
}

+(float)systemFontSizeForControlSize:(NSControlSize)size {
   switch(size){
    default:
    case NSRegularControlSize:
     return 13.0;
     
    case NSSmallControlSize:
     return 11.0;
     
    case NSMiniControlSize:
     return 9.0;
   }
}

+(NSFont *)boldSystemFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial Bold" size:(size==0)?[self systemFontSize]:size];
}

+(NSFont *)controlContentFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)labelFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?[self labelFontSize]:size];
}

+(NSFont *)menuFontOfSize:(float)size {
   CTFontRef ctFont=CTFontCreateUIFontForLanguage(kCTFontMenuItemFontType,size,nil);
   NSString *name=(NSString *)CTFontCopyFullName(ctFont);
   
   size=CTFontGetSize(ctFont);
   
   NSFont *result=[NSFont fontWithName:name size:size];
   
   [ctFont release];
   [name release];
   
   return result;
}

+(NSFont *)menuBarFontOfSize:(float)size {
   CTFontRef ctFont=CTFontCreateUIFontForLanguage(kCTFontMenuTitleFontType,size,nil);
   NSString *name=(NSString *)CTFontCopyFullName(ctFont);
   
   size=CTFontGetSize(ctFont);
   
   NSFont *result=[NSFont fontWithName:name size:size];
   
   [ctFont release];
   [name release];
   
   return result;
}

+(NSFont *)messageFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)paletteFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)systemFontOfSize:(float)size {
   return [self messageFontOfSize:size];
}

+(NSFont *)titleBarFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)toolTipsFontOfSize:(float)size {
   return [NSFont fontWithName:@"Tahoma" size:(size==0)?10.0:size];
}

+(NSFont *)userFontOfSize:(float)size {
   return [NSFont fontWithName:@"Arial" size:(size==0)?12.0:size];
}

+(NSFont *)userFixedPitchFontOfSize:(float)size {
   return [NSFont fontWithName:@"Courier New" size:(size==0)?12.0:size];
}

+(void)setUserFont:(NSFont *)value {
   NSUnimplementedMethod();
}

+(void)setUserFixedPitchFont:(NSFont *)value {
   NSUnimplementedMethod();
}

-(NSString *)_translateToNibFontName:(NSString *)name {
   if([name isEqual:@"Arial"])
    return @"Helvetica";
   if([name isEqual:@"Arial Bold"])
    return @"Helvetica-Bold";
   if([name isEqual:@"Arial Italic"])
    return @"Helvetica-Oblique";
   if([name isEqual:@"Arial Bold Italic"])
    return @"Helvetica-BoldOblique";

   if([name isEqual:@"Times New Roman"])
    return @"Times-Roman";
   if([name isEqual:@"Courier New"])
    return @"Courier";

   if([name isEqual:@"Symbol"])
    return name;

   return name;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
     [coder encodeObject:[self _translateToNibFontName:_name] forKey:@"NSName"];
     [coder encodeFloat:_pointSize forKey:@"NSSize"];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not encodeWithCoder:%@",isa,[coder class]];
   }
}

-(NSString *)_translateFromNibFontName:(NSString *)name {

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
   if([name isEqual:@"LucidaGrande"])
    return @"Lucida Sans Unicode Regular";
   if([name isEqual:@"LucidaGrande-Bold"])
    return @"Lucida Sans Unicode Regular";

   if([name isEqual:@"HelveticaNeue-CondensedBold"])
    return @"Arial";    
   if([name isEqual:@"HelveticaNeue-Bold"])
	return @"Arial";
   if([name isEqual:@"HelveticaNeue-Regular"])
	return @"Arial";
    
   return name;
}

-initWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    NSString          *name=[self _translateFromNibFontName:[keyed decodeObjectForKey:@"NSName"]];
    float              size=[keyed decodeFloatForKey:@"NSSize"];
    // int                flags=[keyed decodeIntForKey:@"NSfFlags"]; // ?
    
    [self dealloc];
    
    return [[NSFont fontWithName:name size:size] retain];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
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

   [isa addFontToCache:self];
   
   _cgFont=CGFontCreateWithFontName((CFStringRef)_name);
   _ctFont=CTFontCreateWithGraphicsFont(_cgFont,_pointSize,NULL,NULL);
   
   return self;
}

-(void)dealloc {
   [isa removeFontFromCache:self];

   [_name release];
   CGFontRelease(_cgFont);
   [_ctFont release];
   [super dealloc];
}

+(NSFont *)fontWithName:(NSString *)name size:(float)size {
   NSFont *result;

   if(name==nil)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] name==nil",self,sel_getName(_cmd)];

   result=[self cachedFontWithName:name size:size];

   if(result==nil)
    result=[[[NSFont alloc] initWithName:name size:size] autorelease];

   return result;
}

+(NSFont *)fontWithName:(NSString *)name matrix:(const float *)matrix {
   return [self fontWithName:name size:matrix[0]];
}

+(NSFont *)fontWithDescriptor:(NSFontDescriptor *)descriptor size:(float)size {
	
	NSDictionary* attributes = [descriptor fontAttributes];
	NSString* fontName = [attributes objectForKey: NSFontNameAttribute];
	if (fontName) {
		return [NSFont fontWithName: fontName size: size];
	}

	NSString* fontFamily = [attributes objectForKey: NSFontFamilyAttribute];
	
	if (fontFamily) {
		NSFontManager* fontMgr = [NSFontManager sharedFontManager];
		
		NSArray* matchingFonts = [fontMgr availableMembersOfFontFamily: fontFamily];
		
		if ([matchingFonts count] == 1) {
			// won't find anything better than this
			NSArray* members = [matchingFonts objectAtIndex: 0];
			return [NSFont fontWithName: [members objectAtIndex: 0] size: size];
		} else {
			// Let's hope that we've got more to go on.
			NSString* fontFace = [attributes objectForKey: NSFontFaceAttribute];
			if (fontFace != nil) {
				int i = 0;
				for (i = 0; i < [matchingFonts count]; i++) {
					NSArray* members = [matchingFonts objectAtIndex: 0];
					NSString* candidateFace = [members objectAtIndex: 1];
					if ([candidateFace isEqualToString: fontFace]) {
						return [NSFont fontWithName: [members objectAtIndex: 0] size: size];
					}
				}
			}
		}
	}
	NSLog(@"unable to match font descriptor: %@", descriptor);
	return nil;
}

+(NSFont *)fontWithDescriptor:(NSFontDescriptor *)descriptor size:(float)size textTransform:(NSAffineTransform *)transform {
   NSUnimplementedMethod();
   return 0;
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
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

-(NSAffineTransform *)textTransform {
   NSAffineTransform      *result=[NSAffineTransform transform];
   NSAffineTransformStruct fields={
    _matrix[0],_matrix[1],_matrix[2],
    _matrix[3],_matrix[4],_matrix[5],
   };
   
   [result setTransformStruct:fields];

   return result;
}

-(NSFontRenderingMode)renderingMode {
   NSUnimplementedMethod();
   return 0;
}

-(NSCharacterSet *)coveredCharacterSet {
   NSUnimplementedMethod();
   return nil;
}

-(NSStringEncoding)mostCompatibleStringEncoding {
   return _encoding;
}

-(NSString *)familyName {
   NSString *familyName = [[NSFontFamily fontFamilyWithName:_name]
name];
   if (familyName == nil)
   {
      NSString *blank = @" ";
      NSMutableArray *nameComponents = [NSMutableArray
arrayWithArray:[_name componentsSeparatedByString:blank]];
      while ([nameComponents count] > 1 && familyName == nil)
      {
         [nameComponents removeLastObject];
         familyName = [[NSFontFamily fontFamilyWithName:
[nameComponents componentsJoinedByString:blank]] name];
      }
   }

   return familyName;
}

-(NSString *)displayName {
   return [self fontName];
}

-(NSFontDescriptor *)fontDescriptor {
   NSUnimplementedMethod();
   return nil;
}

-(NSFont *)printerFont {
   NSUnimplementedMethod();
   return nil;
}

-(NSFont *)screenFont {
   return self;
}

-(NSFont *)screenFontWithRenderingMode:(NSFontRenderingMode)mode {
   NSUnimplementedMethod();
   return nil;
}

-(NSRect)boundingRectForFont {
   return CTFontGetBoundingBox(_ctFont);
}

-(NSRect)boundingRectForGlyph:(NSGlyph)glyph {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(NSMultibyteGlyphPacking)glyphPacking {
   return NSNativeShortGlyphPacking;
}

-(unsigned)numberOfGlyphs {
   return CTFontGetGlyphCount(_ctFont);
}

-(NSGlyph)glyphWithName:(NSString *)name {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)glyphIsEncoded:(NSGlyph)glyph {
   return (glyph<CTFontGetGlyphCount(_ctFont))?YES:NO;
}

-(NSSize)advancementForGlyph:(NSGlyph)glyph {
   CGSize  cgSize;
   CGGlyph cgGlyphs[1]={glyph};
   
   CTFontGetAdvancesForGlyphs(_ctFont,0,cgGlyphs,&cgSize,1);

   return NSMakeSize(cgSize.width,cgSize.height);
}

-(NSSize)maximumAdvancement {
   CGSize  max=CGSizeZero;
   int     glyph,glyphCount=CTFontGetGlyphCount(_ctFont);
   CGGlyph glyphs[glyphCount];
   CGSize  advances[glyphCount];
   
   for(glyph=0;glyph<glyphCount;glyph++)
    glyphs[glyph]=glyph;
    
   CTFontGetAdvancesForGlyphs(_ctFont,0,glyphs,advances,glyphCount);
   
   for(glyph=0;glyph<glyphCount;glyph++){
    max.width=MAX(max.width,advances[glyph].width);
    max.height=MAX(max.height,advances[glyph].height);
   }

   return max;
}

-(float)underlinePosition {
   return CTFontGetUnderlinePosition(_ctFont);
}

-(float)underlineThickness {
   return CTFontGetUnderlineThickness(_ctFont);
}

-(float)ascender {
   return CTFontGetAscent(_ctFont);
}

-(float)descender {
   return CTFontGetDescent(_ctFont);
}

-(float)leading {
   return CTFontGetLeading(_ctFont);
}

-(float)defaultLineHeightForFont {
   return CTFontGetAscent(_ctFont)-CTFontGetDescent(_ctFont)+CTFontGetLeading(_ctFont);;
}

-(BOOL)isFixedPitch {
   CGSize  current;
   int     glyph,glyphCount=CTFontGetGlyphCount(_ctFont);
   CGGlyph glyphs[glyphCount];
   CGSize  advances[glyphCount];
   
   for(glyph=0;glyph<glyphCount;glyph++)
    glyphs[glyph]=glyph;
   
   CTFontGetAdvancesForGlyphs(_ctFont,0,glyphs,advances,glyphCount);
   current=advances[0];
   
   for(glyph=1;glyph<glyphCount;glyph++){
    if(advances[glyph].width!=current.width || advances[glyph].height!=current.height)
     return NO;
   }

   return YES;
}

-(float)italicAngle {
   return CTFontGetSlantAngle(_ctFont);
}

-(float)xHeight {
   return CTFontGetXHeight(_ctFont);
}

-(float)capHeight {
   return CTFontGetCapHeight(_ctFont);
}

-(void)setInContext:(NSGraphicsContext *)context {
   CGContextRef cgContext=[context graphicsPort];
   
   CGContextSetFont(cgContext,_cgFont);
   CGContextSetFontSize(cgContext,_pointSize);

   CGAffineTransform textMatrix;
   
// FIX, should check the focusView in the context instead of NSView's
   if([[NSGraphicsContext currentContext] isFlipped])
    textMatrix=(CGAffineTransform){1,0,0,-1,0,0};
   else
    textMatrix=CGAffineTransformIdentity;

   CGContextSetTextMatrix(cgContext,textMatrix);
}

-(void)set {
   [self setInContext:[NSGraphicsContext currentContext]];
}

-(NSPoint)positionOfGlyph:(NSGlyph)current precededByGlyph:(NSGlyph)previous isNominal:(BOOL *)isNominalp {
   return [_ctFont positionOfGlyph:current precededByGlyph:previous isNominal:isNominalp];
}

-(void)getAdvancements:(NSSize *)advancements forGlyphs:(const NSGlyph *)glyphs count:(unsigned)count {
   CGGlyph cgGlyphs[count];
   int     i;
   
   for(i=0;i<count;i++)
    cgGlyphs[i]=glyphs[i];
   
   CTFontGetAdvancesForGlyphs(_ctFont,0,cgGlyphs,advancements,count);
}

-(void)getAdvancements:(NSSize *)advancements forPackedGlyphs:(const void *)packed length:(unsigned)length {
   CTFontGetAdvancesForGlyphs(_ctFont,0,packed,advancements,length);
}

-(void)getBoundingRects:(NSRect *)rects forGlyphs:(const NSGlyph *)glyphs count:(unsigned)count {
   NSUnimplementedMethod();
}

-(unsigned)getGlyphs:(NSGlyph *)glyphs forCharacters:(unichar *)characters length:(unsigned)length {
   CGGlyph  cgGlyphs[length];
   int      i;
   
   CTFontGetGlyphsForCharacters(_ctFont,characters,cgGlyphs,length);
   
   for(i=0;i<length;i++){
    unichar check=characters[i];

    if(check<' ' || (check>=0x7F && check<=0x9F) || check==0x200B)
     glyphs[i]=NSControlGlyph;
    else
     glyphs[i]=cgGlyphs[i];
   }

   return length;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ %@ %f>",isa,_name,_pointSize];
}

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

@end

