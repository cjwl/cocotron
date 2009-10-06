#import <CoreGraphics/KGFont.h>
#import <windows.h>

@class Win32Font;

@interface KGFont_gdi : O2Font {
   BOOL     _useMacMetrics;
   unichar *_glyphsToCharacters;
}

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize;

@end
