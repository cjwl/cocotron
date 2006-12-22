/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSParagraphStyle.h>

@class NSLayoutManager,NSTextContainer,NSRangeArray, NSParagraphStyle;

@interface NSTypesetter : NSObject {
   IMP                 _layoutNextFragment;
   NSLayoutManager    *_layoutManager;
   NSAttributedString *_attributedString;
   NSString           *_string;

   unsigned            _nextGlyphLocation;
   unsigned            _numberOfGlyphs;
   NSRange             _glyphCacheRange;
   unsigned            _glyphCacheCapacity;
   NSGlyph            *_glyphCache;
   unichar            *_characterCache;

   NSTextContainer    *_container;
   NSSize              _containerSize;

   NSDictionary       *_attributes;
   NSRange             _attributesRange;
   NSRange             _attributesGlyphRange;
   NSFont             *_font;
   float               _fontAscender;
   float               _fontDefaultLineHeight;
   NSPoint           (*_positionOfGlyph)(NSFont *,SEL,NSGlyph,NSGlyph,BOOL *);
   NSParagraphStyle   *_paragraphStyle;
   NSTextAlignment     _alignment;
   NSLineBreakMode     _lineBreakMode;
   NSArray            *_tabStops;
   float               _defaultTabStop;

   NSRange             _lineRange;
   NSRangeArray       *_glyphRangesInLine;
   NSGlyph             _previousGlyph;
   NSRect              _scanRect;
   float               _maxAscender;
}

-(void)layoutGlyphsInLayoutManager:(NSLayoutManager *)layoutManager startingAtGlyphIndex:(unsigned)startGlyphIndex maxNumberOfLineFragments:(unsigned)maxNumLines nextGlyphIndex:(unsigned *)nextGlyph;

@end
