#import <Onyx2D/O2Font.h>
#import <windows.h>

@class Win32Font;

// Enable that to scale the fonts according the system DPI setting
// You probably don't want that because most text will probably won't fit the UI controls anymore
//#define SUPPORT_FONT_DPI_SCALING

#ifdef SUPPORT_FONT_DPI_SCALING
#define FONT_DPI(dc) (GetDeviceCaps(dc, LOGPIXELSY))
#else
#define FONT_DPI(dc) (96.)
#endif

@interface O2Font_gdi : O2Font {
    BOOL _useMacMetrics;
    unichar *_glyphsToCharacters;
    HANDLE _fontMemResource;
    O2Encoding *_macRomanEncoding;
    O2Encoding *_macExpertEncoding;
    O2Encoding *_winAnsiEncoding;
}

- (Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize;
- (Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize angle:(CGFloat)angle;

@end
