#import <Foundation/NSObject.h>
#import <AppKit/CGFont.h>

@class KGPDFObject,KGPDFContext;

typedef struct CGGlyphRange {
   CGGlyph glyphs[256];
} CGGlyphRange;

typedef struct CGGlyphRangeTable {
   unsigned              numberOfGlyphs;
   struct CGGlyphRange  *ranges[256]; 
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
   unsigned     numberOfGlyphs;
   CGGlyphMetrics *info;
} CGGlyphMetricsSet;

@interface KGFont : NSObject {
   NSString                 *_name;
   float                     _size;
   BOOL                      _glyphRangeTableLoaded;
   struct CGGlyphRangeTable *_glyphRangeTable;
   struct CGGlyphMetricsSet *_glyphInfoSet;
}

-initWithName:(NSString *)name size:(float)size;

-(NSString *)name;
-(float)pointSize;

-(unsigned)numberOfGlyphs;
-(BOOL)glyphIsEncoded:(CGGlyph)glyph;
-(NSSize)advancementForGlyph:(CGGlyph)glyph;
-(NSSize)maximumAdvancement;

-(NSPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp;

-(unsigned)getGlyphs:(CGGlyph *)glyphs forCharacters:(unichar *)characters length:(unsigned)length;

-(void)getAdvancements:(NSSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;

-(NSSize)advancementForNominalGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;

-(KGPDFObject *)pdfObjectInContext:(KGPDFContext *)context;

@end
