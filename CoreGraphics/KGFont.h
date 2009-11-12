/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import "O2Geometry.h"

@class O2Font;

typedef O2Font *O2FontRef;

typedef uint16_t O2Glyph;

#import "KGContext.h"
#import "KGDataProvider.h"
#import "KGImage.h"

@class NSData;

@interface O2Font : NSObject {
   NSString *_name;
   int       _unitsPerEm;
   int       _ascent;
   int       _descent;
   int       _leading;
   int       _capHeight;
   int       _xHeight;
   O2Float   _italicAngle;
   O2Float   _stemV;
   O2Rect    _bbox;
   int       _numberOfGlyphs;
   int      *_advances;
   O2Glyph  *_MacRomanEncoding;
}

+(O2Font *)createWithFontName:(NSString *)name;

-initWithFontName:(NSString *)name;
-initWithDataProvider:(O2DataProviderRef)provider;

-(NSData *)copyTableForTag:(uint32_t)tag;

-(O2Glyph)glyphWithGlyphName:(NSString *)name;
-(NSString *)copyGlyphNameForGlyph:(O2Glyph)glyph;

-(void)fetchAdvances;

-(O2Glyph *)MacRomanEncoding;
-(O2Glyph *)glyphTableForEncoding:(O2TextEncoding)encoding;

O2FontRef O2FontCreateWithFontName(NSString *name);
O2FontRef O2FontCreateWithDataProvider(O2DataProviderRef provider);
O2FontRef O2FontRetain(O2FontRef self);
void      O2FontRelease(O2FontRef self);

CFStringRef O2FontCopyFullName(O2FontRef self);
int       O2FontGetUnitsPerEm(O2FontRef self);
int       O2FontGetAscent(O2FontRef self);
int       O2FontGetDescent(O2FontRef self);
int       O2FontGetLeading(O2FontRef self);
int       O2FontGetCapHeight(O2FontRef self);
int       O2FontGetXHeight(O2FontRef self);
O2Float   O2FontGetItalicAngle(O2FontRef self);
O2Float   O2FontGetStemV(O2FontRef self);
O2Rect    O2FontGetFontBBox(O2FontRef self);

size_t    O2FontGetNumberOfGlyphs(O2FontRef self);
BOOL      O2FontGetGlyphAdvances(O2FontRef self,const O2Glyph *glyphs,size_t count,int *advances);

O2Glyph   O2FontGetGlyphWithGlyphName(O2FontRef self,NSString *name);
NSString *O2FontCopyGlyphNameForGlyph(O2FontRef self,O2Glyph glyph);

NSData   *O2FontCopyTableForTag(O2FontRef self,uint32_t tag);


@end
