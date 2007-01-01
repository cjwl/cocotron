/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/NSFont.h>

@class NSEvent,NSColor, NSPasteboard,NSDraggingManager,NSPrintInfo, CGContext, NSView, NSSavePanel, NSOpenPanel, CGWindow;

typedef struct NSGlyphRange {
   NSGlyph glyphs[256];
} NSGlyphRange;

typedef struct NSGlyphRangeTable {
   unsigned              numberOfGlyphs;
   struct NSGlyphRange  *ranges[256]; 
} NSGlyphRangeTable;

typedef struct {
   NSGlyph previous;
   float   xoffset;
} NSKerningOffset;

typedef struct NSGlyphMetrics {
   BOOL             hasAdvancement;
   float            advanceA;
   float            advanceB;
   float            advanceC;
   unsigned         numberOfKerningOffsets;
   NSKerningOffset *kerningOffsets;
} NSGlyphMetrics;

typedef struct NSGlyphMetricsSet {
   unsigned     numberOfGlyphs;
   NSGlyphMetrics *info;
} NSGlyphMetricsSet;

typedef struct NSFontMetrics {
   NSRect boundingRect;
   float  ascender;
   float  descender;
   float  underlineThickness;
   float  underlinePosition;
   BOOL   isFixedPitch;
} NSFontMetrics;

@interface NSDisplay : NSObject {
   unsigned _fontCacheCapacity;
   unsigned _fontCacheSize;
   NSFont **_fontCache;

   unsigned        _eventMask;
   NSMutableArray *_eventQueue;

   NSTimer        *_periodicTimer;
}

+(NSDisplay *)currentDisplay;

-(void)showSplashImage;
-(void)closeSplashImage;

-(NSArray *)screens;

-(NSPasteboard *)pasteboardWithName:(NSString *)name;

-(NSDraggingManager *)draggingManager;

-(CGWindow *)windowWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType;
-(CGWindow *)panelWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType;

-(CGRenderingContext *)bitmapRenderingContextWithSize:(NSSize)size;

-(NSColor *)colorWithName:(NSString *)colorName;
-(NSString *)menuFontNameAndSize:(float *)pointSize;

-(NSFont *)cachedFontWithName:(NSString *)name size:(float)size;
-(void)addFontToCache:(NSFont *)font;
-(void)removeFontFromCache:(NSFont *)font;

-(NSTimeInterval)textCaretBlinkInterval;

-(void)hideCursor;
-(void)unhideCursor;

// Arrow, IBeam, HorizontalResize, VerticalResize
-(id)cursorWithName:(NSString *)name;
-(void)setCursor:(id)cursor;

-(NSEvent *)nextEventMatchingMask:(unsigned)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue;

-(void)discardEventsMatchingMask:(unsigned)mask beforeEvent:(NSEvent *)event;

-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart;

-(BOOL)containsAndRemovePeriodicEvents;
-(BOOL)hasEventsMatchingMask;

-(void)startPeriodicEventsAfterDelay:(NSTimeInterval)delay withPeriod:(NSTimeInterval)period;
-(void)stopPeriodicEvents;

-(unsigned)modifierForDefault:(NSString *)key:(unsigned)standard;

-(void)beep;

-(NSSet *)allFontFamilyNames;
-(NSArray *)fontTypefacesForFamilyName:(NSString *)name;

-(float)scrollerWidth;

-(void)metricsForFontWithName:(NSString *)name pointSize:(float)pointSize metrics:(NSFontMetrics *)metrics;

-(void)loadGlyphRangeTable:(NSGlyphRangeTable *)table fontName:(NSString *)name range:(NSRange)range;

-(void)fetchAdvancementsForFontWithName:(NSString *)name pointSize:(float)pointSize glyphRanges:(NSGlyphRangeTable *)table infoSet:(NSGlyphMetricsSet *)infoSet forGlyph:(NSGlyph)glyph;
-(void)fetchGlyphKerningForFontWithName:(NSString *)name pointSize:(float)pointSize glyphRanges:(NSGlyphRangeTable *)table infoSet:(NSGlyphMetricsSet *)infoSet;

-(void)runModalWithPrintInfo:(NSPrintInfo *)printInfo;

-(CGContext *)graphicsPortForPrintOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo pageRange:(NSRange)pageRange;

-(int)savePanel:(NSSavePanel *)savePanel runModalForDirectory:(NSString *)directory file:(NSString *)file;
-(int)openPanel:(NSOpenPanel *)openPanel runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types;

@end
