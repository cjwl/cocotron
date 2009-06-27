#import "KGFont+PDF.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFContext.h"
#import <Foundation/NSArray.h>

@implementation KGFont(PDF)

static NSString *MacRomanEncoding[256]={
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

uint8_t O2PDFMacRomanPositionOfGlyphName(NSString *name){
   static NSDictionary *map=nil;
   
   if(map==nil){
    NSMutableDictionary *mutmap=[NSDictionary new];
    int i;
    for(i=0;i<256;i++)
     [mutmap setObject:[NSNumber numberWithInt:i] forKey:MacRomanEncoding[i]];
     map=mutmap;
   }
   
   return [[map objectForKey:name] intValue];
}

KGPDFArray *O2FontCreatePDFWidthsWithEncoding(O2FontRef self,CGGlyph encoding[256]){
   CGFloat       unitsPerEm=O2FontGetUnitsPerEm(self);
   KGPDFArray   *result=[[KGPDFArray alloc] init];
   int           widths[256];
   int           i;
   
   O2FontGetGlyphAdvances(self,encoding,256,widths);

   for(i=32;i<256;i++){
    KGPDFReal width=(widths[i]/unitsPerEm)*1000; // normalized to 1000
    
    [result addNumber:width];
   }
   
   return result;
}

-(void)getBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length {
   int i;
   
   for(i=0;i<length;i++){
    NSString *name=O2FontCopyGlyphNameForGlyph(self,glyphs[i]);

    bytes[i]=O2PDFMacRomanPositionOfGlyphName(name);

    [name release];
   }
}

-(const char *)pdfFontName {
   return [[[self->_name componentsSeparatedByString:@" "] componentsJoinedByString:@","] cString];
}

-(KGPDFDictionary *)_pdfFontDescriptorWithSize:(CGFloat)size {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

   [result setNameForKey:"Type" value:"FontDescriptor"];
   [result setNameForKey:"FontName" value:[self pdfFontName]];
   [result setIntegerForKey:"Flags" value:4];
   
   CGFloat   unitsPerEm=O2FontGetUnitsPerEm(self);
   KGPDFReal bbox[4];
   CGRect    bRect=O2FontGetFontBBox(self);
   bRect.origin.x/=unitsPerEm*size;
   bRect.origin.y/=unitsPerEm*size;
   bRect.size.width/=unitsPerEm*size;
   bRect.size.height/=unitsPerEm*size;
   
   bbox[0]=bRect.origin.x;
   bbox[1]=bRect.origin.y;
   bbox[2]=bRect.size.width;
   bbox[3]=bRect.size.height;
   [result setObjectForKey:"FontBBox" value:[KGPDFArray pdfArrayWithNumbers:bbox count:4]];
   [result setIntegerForKey:"ItalicAngle" value:O2FontGetItalicAngle(self)/unitsPerEm*size];
   [result setIntegerForKey:"Ascent" value:O2FontGetAscent(self)/unitsPerEm*size];
   [result setIntegerForKey:"Descent" value:O2FontGetDescent(self)/unitsPerEm*size];
   [result setIntegerForKey:"CapHeight" value:O2FontGetCapHeight(self)/unitsPerEm*size];
   [result setIntegerForKey:"StemV" value:0];
   [result setIntegerForKey:"StemH" value:0];
   
   return result;
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context size:(CGFloat)size {
   KGPDFObject *reference=[context referenceForFontWithName:self->_name size:size];
   
   if(reference==nil){
    KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];
    CGGlyph          encoding[256];
    int              i;
    
    for(i=32;i<256;i++)
     encoding[i]=O2FontGetGlyphWithGlyphName(self,MacRomanEncoding[i]);
     
    [result setNameForKey:"Type" value:"Font"];
    [result setNameForKey:"Subtype" value:"TrueType"];
    [result setNameForKey:"BaseFont" value:[self pdfFontName]];
    [result setIntegerForKey:"FirstChar" value:32];
    [result setIntegerForKey:"LastChar" value:255];
    KGPDFArray *widths=O2FontCreatePDFWidthsWithEncoding(self,encoding);
    [result setObjectForKey:"Widths" value:[context encodeIndirectPDFObject:widths]];
    [widths release];
    
    [result setObjectForKey:"FontDescriptor" value:[context encodeIndirectPDFObject:[self _pdfFontDescriptorWithSize:size]]];

    [result setNameForKey:"Encoding" value:"MacRomanEncoding"];

    reference=[context encodeIndirectPDFObject:result];
    [context setReference:reference forFontWithName:self->_name size:size];
   }
   
   return reference;
}

@end
