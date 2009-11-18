/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "O2Font.h"
#import "O2Exceptions.h"

@implementation O2Font

-initWithFontName:(NSString *)name {
   _name=[name copy];
   return self;
}

-initWithDataProvider:(O2DataProviderRef)provider {
   return self;
}

-(void)dealloc {
   [_name release];
   if(_advances!=NULL)
    NSZoneFree(NULL,_advances);
   if(_MacRomanEncoding!=NULL)
    NSZoneFree(NULL,_MacRomanEncoding);
   [super dealloc];
}

+(O2Font *)createWithFontName:(NSString *)name {
   return [[self alloc] initWithFontName:name];
}

-(NSData *)copyTableForTag:(uint32_t)tag {
   O2InvalidAbstractInvocation();
   return nil;
}

-(O2Glyph)glyphWithGlyphName:(NSString *)name {
   O2InvalidAbstractInvocation();
   return 0;
}

-(NSString *)copyGlyphNameForGlyph:(O2Glyph)glyph {
   O2InvalidAbstractInvocation();
   return nil;
}

-(void)fetchAdvances {
   O2InvalidAbstractInvocation();
}

NSString *O2MacRomanGlyphNames[256]={
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@".notdef",
@"space",
@"exclam",
@"quotedbl",
@"numbersign",
@"dollar",
@"percent",
@"ampersand",
@"quotesingle",
@"parenleft",
@"parenright",
@"asterisk",
@"plus",
@"comma",
@"hyphen",
@"period",
@"slash",
@"zero",
@"one",
@"two",
@"three",
@"four",
@"five",
@"six",
@"seven",
@"eight",
@"nine",
@"colon",
@"semicolon",
@"less",
@"equal",
@"greater",
@"question",
@"at",
@"A",
@"B",
@"C",
@"D",
@"E",
@"F",
@"G",
@"H",
@"I",
@"J",
@"K",
@"L",
@"M",
@"N",
@"O",
@"P",
@"Q",
@"R",
@"S",
@"T",
@"U",
@"V",
@"W",
@"X",
@"Y",
@"Z",
@"bracketleft",
@"backslash",
@"bracketright",
@"asciicircum",
@"underscore",
@"grave",
@"a",
@"b",
@"c",
@"d",
@"e",
@"f",
@"g",
@"h",
@"i",
@"j",
@"k",
@"l",
@"m",
@"n",
@"o",
@"p",
@"q",
@"r",
@"s",
@"t",
@"u",
@"v",
@"w",
@"x",
@"y",
@"z",
@"braceleft",
@"bar",
@"braceright",
@"asciitilde",
@".notdef",
@"Adieresis",
@"Aring",
@"Ccedilla",
@"Eacute",
@"Ntilde",
@"Odieresis",
@"Udieresis",
@"aacute",
@"agrave",
@"acircumflex",
@"adieresis",
@"atilde",
@"aring",
@"ccedilla",
@"eacute",
@"egrave",
@"ecircumflex",
@"edieresis",
@"iacute",
@"igrave",
@"icircumflex",
@"idieresis",
@"ntilde",
@"oacute",
@"ograve",
@"ocircumflex",
@"odieresis",
@"otilde",
@"uacute",
@"ugrave",
@"ucircumflex",
@"udieresis",
@"dagger",
@"degree",
@"cent",
@"sterling",
@"section",
@"bullet",
@"paragraph",
@"germandbls",
@"registered",
@"copyright",
@"trademark",
@"acute",
@"dieresis",
@"notequal",
@"AE",
@"Oslash",
@"infinity",
@"plusminus",
@"lessequal",
@"greaterequal",
@"yen",
@"mu",
@"partialdiff",
@"summation",
@"product",
@"pi",
@"integral",
@"ordfeminine",
@"ordmasculine",
@"Omegagreek",
@"ae",
@"oslash",
@"questiondown",
@"exclamdown",
@"logicalnot",
@"radical",
@"florin",
@"approxequal",
@"Delta",
@"guillemotleft",
@"guillemotright",
@"ellipsis",
@"nobreakspace",
@"Agrave",
@"Atilde",
@"Otilde",
@"OE",
@"oe",
@"endash",
@"emdash",
@"quotedblleft",
@"quotedblright",
@"commaturnedmod",
@"apostrophemod",
@"divide",
@"lozenge",
@"ydieresis",
@"Ydieresis",
@"fraction",
@"Euro",
@"guilsinglleft",
@"guilsinglright",
@"fi",
@"fl",
@"daggerdbl",
@"periodcentered",
@"quotesinglbase",
@"quotedblbase",
@"perthousand",
@"Acircumflex",
@"Ecircumflex",
@"Aacute",
@"Edieresis",
@"Egrave",
@"Iacute",
@"Icircumflex",
@"Idieresis",
@"Igrave",
@"Oacute",
@"Ocircumflex",
@"apple",
@"Ograve",
@"Uacute",
@"Ucircumflex",
@"Ugrave",
@"dotlessi",
@"circumflex",
@"tilde",
@"macron",
@"breve",
@"dotaccent",
@"ring",
@"cedilla",
@"hungarumlaut",
@"ogonek",
@"caron",
};

-(O2Glyph *)MacRomanEncoding {
   if(_MacRomanEncoding==NULL){
    int i;
   
    _MacRomanEncoding=NSZoneMalloc(NULL,sizeof(O2Glyph)*256);
    
    for(i=0;i<256;i++)
     _MacRomanEncoding[i]=O2FontGetGlyphWithGlyphName(self,O2MacRomanGlyphNames[i]);
   }
   return _MacRomanEncoding;
}

-(O2Glyph *)glyphTableForEncoding:(O2TextEncoding)encoding {
   return [self MacRomanEncoding];
}

O2FontRef O2FontCreateWithFontName(NSString *name) {
   return [[O2Font alloc] initWithFontName:name];
}

O2FontRef O2FontCreateWithDataProvider(O2DataProviderRef provider) {
   return [[O2Font alloc] initWithDataProvider:provider];
}

O2FontRef O2FontRetain(O2FontRef self) {
   return [self retain];
}

void      O2FontRelease(O2FontRef self) {
   [self release];
}


CFStringRef O2FontCopyFullName(O2FontRef self) {
   return (CFStringRef)[self->_name copy];
}

int       O2FontGetUnitsPerEm(O2FontRef self) {
   return self->_unitsPerEm;
}

int       O2FontGetAscent(O2FontRef self) {
   return self->_ascent;
}

int       O2FontGetDescent(O2FontRef self) {
   return self->_descent;
}

int       O2FontGetLeading(O2FontRef self) {
   return self->_leading;
}

int       O2FontGetCapHeight(O2FontRef self) {
   return self->_capHeight;
}

int       O2FontGetXHeight(O2FontRef self) {
   return self->_xHeight;
}

O2Float   O2FontGetItalicAngle(O2FontRef self){
   return self->_italicAngle;
}

O2Float   O2FontGetStemV(O2FontRef self) {
   return self->_stemV;
}

O2Rect    O2FontGetFontBBox(O2FontRef self) {
   return self->_bbox;
}

size_t    O2FontGetNumberOfGlyphs(O2FontRef self) {
   return self->_numberOfGlyphs;
}

BOOL O2FontGetGlyphAdvances(O2FontRef self,const O2Glyph *glyphs,size_t count,int *advances) {
   size_t i;
   
   if(self->_advances==NULL)
    [self fetchAdvances];
    
   for(i=0;i<count;i++){
    O2Glyph glyph=glyphs[i];
    
    if(glyph<self->_numberOfGlyphs)
     advances[i]=self->_advances[glyph];
    else
     advances[i]=0;
   }
   return YES;
}

O2Glyph   O2FontGetGlyphWithGlyphName(O2FontRef self,NSString *name) {
   return [self glyphWithGlyphName:name];
}

NSString *O2FontCopyGlyphNameForGlyph(O2FontRef self,O2Glyph glyph) {
   return [self copyGlyphNameForGlyph:glyph];
}

NSData   *O2FontCopyTableForTag(O2FontRef self,uint32_t tag) {
   return [self copyTableForTag:(uint32_t)tag];
}

@end
