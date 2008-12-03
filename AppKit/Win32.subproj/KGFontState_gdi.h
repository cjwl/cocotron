#import <AppKit/KGFontState.h>

@interface KGFontState_gdi : KGFontState {
   CGFontMetrics             _metrics;
   struct CGGlyphRangeTable *_glyphRangeTable;
   struct CGGlyphMetricsSet *_glyphInfoSet;
   BOOL _useMacMetrics;
}

@end
