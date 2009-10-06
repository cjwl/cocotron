#import "O2Font_ttf.h"
#import "O2TTFDecoder.h"


@implementation O2Font_ttf

-initWithDataProvider:(O2DataProviderRef)provider {
   O2TTFDecoderRef decoder=O2TTFDecoderCreate(provider);
   
   _nameToGlyph=O2TTFDecoderGetPostScriptNameMapTable(decoder,&_numberOfGlyphs);
   _glyphLocations=O2TTFDecoderGetGlyphLocations(decoder,_numberOfGlyphs);
   return self;
}

-(CGGlyph)glyphWithGlyphName:(NSString *)name {
   return (CGGlyph)NSMapGet(_nameToGlyph,name);
}

@end
