/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class KGFont;
typedef KGFont *O2FontRef;

@interface KGFont : NSObject {
   NSString *_name;
   int       _unitsPerEm;
   int       _ascent;
   int       _descent;
   int       _leading;
   int       _capHeight;
   int       _xHeight;
   CGFloat   _italicAngle;
   CGFloat   _stemV;
   CGRect    _bbox;
   int       _numberOfGlyphs;
   int      *_advances;
   CGGlyph  *_MacRomanEncoding;
}

+(KGFont *)createWithFontName:(NSString *)name;

-initWithFontName:(NSString *)name;
-(NSData *)copyTableForTag:(uint32_t)tag;

-(CGGlyph)glyphWithGlyphName:(NSString *)name;
-(NSString *)copyGlyphNameForGlyph:(CGGlyph)glyph;

-(void)fetchAdvances;

-(CGGlyph *)MacRomanEncoding;
-(CGGlyph *)glyphTableForEncoding:(CGTextEncoding)encoding;

O2FontRef O2FontCreateWithFontName(NSString *name);
O2FontRef O2FontRetain(O2FontRef self);
void      O2FontRelease(O2FontRef self);

NSString *O2FontCopyFullName(O2FontRef self);
int       O2FontGetUnitsPerEm(O2FontRef self);
int       O2FontGetAscent(O2FontRef self);
int       O2FontGetDescent(O2FontRef self);
int       O2FontGetLeading(O2FontRef self);
int       O2FontGetCapHeight(O2FontRef self);
int       O2FontGetXHeight(O2FontRef self);
CGFloat   O2FontGetItalicAngle(O2FontRef self);
CGFloat   O2FontGetStemV(O2FontRef self);
CGRect    O2FontGetFontBBox(O2FontRef self);

size_t    O2FontGetNumberOfGlyphs(O2FontRef self);
BOOL      O2FontGetGlyphAdvances(O2FontRef self,const CGGlyph *glyphs,size_t count,int *advances);

CGGlyph   O2FontGetGlyphWithGlyphName(O2FontRef self,NSString *name);
NSString *O2FontCopyGlyphNameForGlyph(O2FontRef self,CGGlyph glyph);

NSData   *O2FontCopyTableForTag(O2FontRef self,uint32_t tag);


@end
