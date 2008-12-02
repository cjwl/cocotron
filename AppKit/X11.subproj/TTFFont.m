/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "TTFFont.h"

@implementation KGFontState(TTFFont)
+(id)allocWithZone:(NSZone*)zone
{
   return NSAllocateObject([TTFFont class], 0, NULL);
}
@end

@implementation TTFFont
FT_Library library;

+(void)initialize {
   int ret=FT_Init_FreeType(&library);
   NSAssert(ret==0, nil);
}

-(float)pointSize
{
   return _size;
}

-(id)name
{
   return _name;
}

-(float)ascender
{
   return _size * _face->ascender/(float)_face->units_per_EM;
}

-(float)descender
{
   return _size * _face->descender/(float)_face->units_per_EM;
}

-(float)leading
{
   return 0.0;
}

-initWithName:(NSString *)name size:(float)size {
   if(self=[super init])
   {
      int ret=FT_New_Face(library,
                  "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
                  0,
                  &_face);
      
      FT_Set_Pixel_Sizes(_face, 0, _size);
      
      FT_Select_Charmap(_face, FT_ENCODING_UNICODE);

      NSAssert(ret==0, nil);
      _size=size;
      _name=@"FreeSans";
      
   }
   return self;
}

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length {
   int i;
   for(i=0; i<length; i++)
   {
      glyphs[i]=FT_Get_Char_Index(_face, characters[i]);
   }
}

-(CGSize)advancementForGlyph:(CGGlyph)glyph {
   FT_Load_Glyph(_face, glyph, FT_LOAD_DEFAULT);
   return NSMakeSize(_face->glyph->bitmap_left,
                      0);
}

-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp {
   *isNominalp=YES;   
 
   FT_Load_Glyph(_face, current, FT_LOAD_DEFAULT);
   return NSMakePoint(_face->glyph->advance.x/(float)(2<<5),
                     _face->glyph->advance.y/(float)(2<<5));
   
   
}

-(FT_Face)face
{
   return _face;
}
@end


