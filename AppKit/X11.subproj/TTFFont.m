//
//  TTFFont.m
//  AppKit
//
//  Created by Johannes Fortmann on 13.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import "TTFFont.h"

@implementation KGFont(TTFFont)
+(id)allocWithZone:(NSZone*)zone
{
   return NSAllocateObject([TTFFont class], 0, NULL);
}
@end

@implementation TTFFont
FT_Library library;

+(void)initialize {
   FT_Init_FreeType(&library);
}

-initWithName:(NSString *)name size:(float)size {
   if(self=[super initWithName:name size:size])
   {
      FT_New_Face(library,
                  "/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType/Vera.ttf",
                  0,
                  &_face);
   }
   return self;
}

-(void)fetchMetrics{
   
}

-(void)loadGlyphRangeTable {
}

-(void)fetchGlyphRanges {
   
}

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length {
   int i;
   for(i=0; i<length; i++)
      glyphs[i]=FT_Get_Char_Index(_face, characters[i]);
}

-(void)fetchGlyphKerning {
   
}

-(CGSize)advancementForGlyph:(CGGlyph)glyph {
   return CGSizeMake(1.0, 1.0);
}
@end


