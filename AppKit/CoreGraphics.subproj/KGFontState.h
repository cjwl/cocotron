/* Copyright (c) 2006-2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSString.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGMutablePath;

enum {
   CGNullGlyph=0x0
};

typedef struct CGFontMetrics {
   float  emsquare;
   float  scale;
   CGRect boundingRect;
   float  ascender;
   float  descender;
   float  leading;
   float  italicAngle;
   float  capHeight;
   float  xHeight;
   float  stemV;
   float  stemH;
   float  underlineThickness;
   float  underlinePosition;
   BOOL   isFixedPitch;
} CGFontMetrics;

typedef struct CGGlyphRange {
   CGGlyph glyphs[256];
} CGGlyphRange;

typedef struct CGGlyphRangeTable {
   unsigned                 numberOfGlyphs;
   struct CGGlyphRange     *ranges[256];
   unichar                 *characters;
} CGGlyphRangeTable;

typedef struct {
   CGGlyph previous;
   float   xoffset;
} CGKerningOffset;

typedef struct CGGlyphMetrics {
   BOOL             hasAdvancement;
   float            advanceA;
   float            advanceB;
   float            advanceC;
   unsigned         numberOfKerningOffsets;
   CGKerningOffset *kerningOffsets;
} CGGlyphMetrics;

typedef struct CGGlyphMetricsSet {
   unsigned        numberOfGlyphs;
   CGGlyphMetrics *info;
} CGGlyphMetricsSet;

@interface KGFontState : NSObject {
   NSString                 *_name;
   float                     _size;
   CGFontMetrics             _metrics;
   // subclasses are responsible for alloc/dealloc of _glyphRangeTable
   struct CGGlyphRangeTable *_glyphRangeTable;
   struct CGGlyphMetricsSet *_glyphInfoSet;
}

-initWithName:(NSString *)name size:(float)size;

-(NSString *)name;
-(float)pointSize;
-(float)nominalSize;

-(CGRect)boundingRect;
-(float)ascender;
-(float)descender;
-(float)leading;
-(float)underlineThickness;
-(float)underlinePosition;
-(BOOL)isFixedPitch;
-(float)italicAngle;
-(float)leading;
-(float)xHeight;
-(float)capHeight;

-(unsigned)numberOfGlyphs;
-(BOOL)glyphIsEncoded:(CGGlyph)glyph;
-(CGSize)advancementForGlyph:(CGGlyph)glyph;
-(CGSize)maximumAdvancement;

-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp;

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length;
-(void)getCharacters:(unichar *)characters forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length;
-(void)getBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length;
-(void)getGlyphs:(CGGlyph *)glyphs forBytes:(const unsigned char *)bytes length:(unsigned)length;

-(void)getAdvancements:(CGSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;

-(CGSize)advancementForNominalGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;

// implement in subclass
-(void)fetchMetrics;
-(void)loadGlyphRangeTable;
-(void)fetchGlyphKerning;
-(void)fetchAdvancementsForGlyph:(CGGlyph)glyph;
-(void)appendCubicOutlinesToPath:(KGMutablePath *)path glyphs:(CGGlyph *)glyphs length:(unsigned)length;
@end
