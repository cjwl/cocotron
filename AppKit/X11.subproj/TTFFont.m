/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "TTFFont.h"
#import <AppKit/KTFont.h>
#import <AppKit/KGFont.h>

@implementation KTFont(TTFFont)
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

-initWithFont:(KGFont *)font size:(float)size {
   NSString* key=[NSString stringWithFormat:@"%@@%f", [font fontName], size];
   
   static NSMutableDictionary *cache=nil;
   if(!cache)
      cache=[NSMutableDictionary new];
   id ret=[cache objectForKey:key];

   if(ret) {
      [self release];
      return [ret retain]; 
   }
   
   [cache setObject:self forKey:key];
   
   if(self=[super init])
   {
      FT_Error ret=FT_New_Face(library,
                  "/Library/Fonts/Tahoma.ttf",
                  0,
                  &_face);
            
      
      FT_Select_Charmap(_face, FT_ENCODING_UNICODE);

     // NSAssert(ret==0, nil);
      _size=size;
      _name=@"FreeSans";
      
   }
   return self;
}

-(void)releasePlatformFont {
   
}

-(void)dealloc {
   FT_Done_Face(_face);
   [_name release];
   [self releasePlatformFont];
   [super dealloc];
}

-initWithUIFontType:(CTFontUIFontType)uiFontType size:(CGFloat)size language:(NSString *)language {
   KGFont *font=nil;
   
   switch(uiFontType){
  
    case kCTFontMenuTitleFontType:
    case kCTFontMenuItemFontType:
     if(size==0)
      size=12;
     font=[KGFont createWithFontName:@"Vera"];
     break;
 
    default:
     NSUnimplementedMethod();
     return nil;
   }
   
   self=[self initWithFont:font size:size];
   
   [font release];
   
   return self;
}

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length {
   int i;
   for(i=0; i<length; i++)
   {
      glyphs[i]=FT_Get_Char_Index(_face, characters[i]);
   }
}

-(void)getAdvancements:(CGSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   int i;
   FT_Set_Pixel_Sizes(_face, _size, _size);

   for(i=0;i<count;i++){
    FT_Load_Glyph(_face, glyphs[i], FT_LOAD_DEFAULT);
      advancements[i]= CGSizeMake(_face->glyph->bitmap_left,
                                  0);
   }
}

-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp {
   *isNominalp=YES;
 
   if(!current)
      return NSZeroPoint;

   FT_Set_Pixel_Sizes(_face, _size, _size);

   FT_Load_Glyph(_face, current, FT_LOAD_DEFAULT);
   return NSMakePoint(_face->glyph->advance.x/(float)(2<<5),
                      _face->glyph->advance.y/(float)(2<<5));
}

-(FT_Face)face
{
   return _face;
}
@end


