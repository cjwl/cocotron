#import <Onyx2D/O2Font.h>
#import <windows.h>

@class Win32Font;

@interface O2Font_gdi : O2Font {
   BOOL     _useMacMetrics;
   unichar *_glyphsToCharacters;
}

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize;

@end
