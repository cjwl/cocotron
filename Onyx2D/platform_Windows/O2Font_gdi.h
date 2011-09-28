#import <Onyx2D/O2Font.h>
#import <windows.h>

@class Win32Font;

@interface O2Font_gdi : O2Font {
   BOOL     _useMacMetrics;
   unichar *_glyphsToCharacters;
   HANDLE   _fontMemResource;
   O2Encoding *_macRomanEncoding;
   O2Encoding *_macExpertEncoding;
   O2Encoding *_winAnsiEncoding;
}

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize;
-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize angle:(CGFloat)angle;

@end
