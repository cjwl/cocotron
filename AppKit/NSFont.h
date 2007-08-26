/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/CoreGraphics.h>

@class KGFont;

typedef unsigned NSGlyph;

enum {
   NSNullGlyph=0x0,
   NSControlGlyph=0x00FFFFFF
};

typedef enum {
   NSCoreGraphicsGlyphPacking,
} NSMultibyteGlyphPacking;

@interface NSFont : NSObject <NSCopying> {
   NSString        *_name;
   float            _pointSize;
   float            _matrix[6];
   NSStringEncoding _encoding;

   NSRect    _boundingRect;
   float     _underlinePosition;
   float     _underlineThickness;
   float     _ascender;
   float     _descender;
   BOOL      _isFixedPitch;

   KGFont   *_kgFont;
}

+(NSFont *)fontWithName:(NSString *)name size:(float)size;
+(NSFont *)fontWithName:(NSString *)name matrix:(const float *)matrix;

+(NSFont *)boldSystemFontOfSize:(float)size;
+(NSFont *)controlContentFontOfSize:(float)size;
+(NSFont *)labelFontOfSize:(float)size;
+(NSFont *)menuFontOfSize:(float)size;
+(NSFont *)messageFontOfSize:(float)size;
+(NSFont *)paletteFontOfSize:(float)size;
+(NSFont *)systemFontOfSize:(float)size;
+(NSFont *)titleBarFontOfSize:(float)size;
+(NSFont *)toolTipsFontOfSize:(float)size;
+(NSFont *)userFontOfSize:(float)size;
+(NSFont *)userFixedPitchFontOfSize:(float)size;

-(float)pointSize;
-(NSString *)fontName;
-(const float *)matrix;

-(NSRect)boundingRectForFont;

-(unsigned)numberOfGlyphs;
-(BOOL)glyphIsEncoded:(NSGlyph)glyph;
-(NSSize)advancementForGlyph:(NSGlyph)glyph;
-(NSSize)maximumAdvancement;
-(NSFont *)screenFont;
-(float)underlinePosition;
-(float)underlineThickness;
-(float)ascender;
-(float)descender;
-(float)defaultLineHeightForFont;
-(BOOL)isFixedPitch;

-(void)set;

-(NSStringEncoding)mostCompatibleStringEncoding;
-(NSMultibyteGlyphPacking)glyphPacking;

-(NSPoint)positionOfGlyph:(NSGlyph)current precededByGlyph:(NSGlyph)previous isNominal:(BOOL *)isNominalp;

-(unsigned)getGlyphs:(NSGlyph *)glyphs forCharacters:(unichar *)characters length:(unsigned)length;

-(void)getAdvancements:(NSSize *)advancements forGlyphs:(const NSGlyph *)glyphs count:(unsigned)count;

@end

int NSConvertGlyphsToPackedGlyphs(NSGlyph *glyphs,int length,NSMultibyteGlyphPacking packing,char *output);
