/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "TTFFont.h"
#import <AppKit/KTFont.h>
#import <AppKit/KGFont.h>
#import <AppKit/NSFontTypeface.h>
#import <fontconfig.h>

@implementation KTFont(TTFFont)
+(id)allocWithZone:(NSZone*)zone
{
   return NSAllocateObject([TTFFont class], 0, NULL);
}
@end

@implementation TTFFont
FT_Library library;
FcConfig *fontConfig;

+(NSSet*)allFontFamilyNames {
   int i;
   FcPattern *pat=FcPatternCreate();
   FcObjectSet *props=FcObjectSetBuild(FC_FAMILY, 0);
   
   FcFontSet *set = FcFontList (fontConfig, pat, props);
   NSMutableSet* ret=[NSMutableSet set];
   
   for(i = 0; i < set->nfont; i++)
   {
      FcChar8 *family;
      if (FcPatternGetString (set->fonts[i], FC_FAMILY, 0, &family) == FcResultMatch) {
         [ret addObject:[NSString stringWithUTF8String:(char*)family]];
      }
   }
   
   FcPatternDestroy(pat);
   FcObjectSetDestroy(props);
   FcFontSetDestroy(set);
   return ret;
}

+(NSArray *)fontTypefacesForFamilyName:(NSString *)familyName {
   int i;
   FcPattern *pat=FcPatternCreate();
   FcPatternAddString(pat, FC_FAMILY, (unsigned char*)[familyName UTF8String]);
   FcObjectSet *props=FcObjectSetBuild(FC_FAMILY, FC_STYLE, FC_SLANT, FC_WIDTH, FC_WEIGHT, 0);

   FcFontSet *set = FcFontList (fontConfig, pat, props);
   NSMutableArray* ret=[NSMutableArray array];
   
   for(i = 0; i < set->nfont; i++)
   {
      FcChar8 *typeface;
      FcPattern *p=set->fonts[i];
      if (FcPatternGetString (p, FC_STYLE, 0, &typeface) == FcResultMatch) {
         NSString* traitName=[NSString stringWithUTF8String:(char*)typeface];
         FcChar8* pattern=FcNameUnparse(p);
         NSString* name=[NSString stringWithUTF8String:(char*)pattern];
         FcStrFree(pattern);
         
         NSFontTraitMask traits=0;
         int slant, width, weight;
         
         FcPatternGetInteger(p, FC_SLANT, FC_SLANT_ROMAN, &slant);
         FcPatternGetInteger(p, FC_WIDTH, FC_WIDTH_NORMAL, &width);
         FcPatternGetInteger(p, FC_WEIGHT, FC_WEIGHT_REGULAR, &weight);

         switch(slant) {
            case FC_SLANT_OBLIQUE:
            case FC_SLANT_ITALIC:
               traits|=NSItalicFontMask;
               break;
            default:
               traits|=NSUnitalicFontMask;
               break;
         }
         
         if(weight<=FC_WEIGHT_LIGHT)
            traits|=NSUnboldFontMask;
         else if(weight>=FC_WEIGHT_SEMIBOLD)
            traits|=NSBoldFontMask;
         
         if(width<=FC_WIDTH_SEMICONDENSED)
            traits|=NSNarrowFontMask;
         else if(width>=FC_WIDTH_SEMIEXPANDED)
            traits|=NSExpandedFontMask;
         
         NSFontTypeface *face=[[NSFontTypeface alloc] initWithName:name traitName:traitName traits:traits];
         [ret addObject:face];
         [face release];
      }
   }
   
   FcPatternDestroy(pat);
   FcObjectSetDestroy(props);
   FcFontSetDestroy(set);
   return ret;
}

+(NSString*)filenameForPattern:(NSString *)pattern {
   int i;
   FcPattern *pat=FcNameParse((unsigned char*)[pattern UTF8String]);

   FcObjectSet *props=FcObjectSetBuild(FC_FILE, 0);

   FcFontSet *set = FcFontList (fontConfig, pat, props);
   NSString* ret=NULL;
   for(i = 0; i < set->nfont && !ret; i++) {
      FcChar8 *filename;

      if (FcPatternGetString (set->fonts[i], FC_FILE, 0, &filename) == FcResultMatch) {
         ret=[NSString stringWithUTF8String:(char*)filename];
      }
   }

   FcPatternDestroy(pat);
   FcObjectSetDestroy(props);
   FcFontSetDestroy(set);
   
   return ret;
}


+(void)initialize {
   int ret=FT_Init_FreeType(&library);
   NSAssert(ret==0, nil);
   fontConfig=FcInitLoadConfigAndFonts();
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
      id pattern=[font fontName];
      
      id filename=[isa filenameForPattern:pattern];
      if(!filename) {
         filename=[isa filenameForPattern:@""];
         if(!filename) {
#ifdef LINUX
            filename=@"/usr/share/fonts/truetype/freefont/FreeSans.ttf";
#else
            filename=@"/System/Library/Fonts/Geneva.dfont";
#endif
         }
      }
      
      FT_Error ret=FT_New_Face(library,
                  [filename fileSystemRepresentation],
                  0,
                  &_face);
            
      
      FT_Select_Charmap(_face, FT_ENCODING_UNICODE);

      _size=size;
      _name=[pattern retain];
      
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
     font=[KGFont createWithFontName:@"Arial"];
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


