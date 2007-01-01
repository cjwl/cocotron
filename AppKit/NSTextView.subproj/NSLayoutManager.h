/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/NSFont.h>

@class NSTextStorage,NSTypesetter,NSTextContainer,NSTextView;
@class NSWindow,NSColor,NSCell;
@class NSGlyphIndex,NSLayoutIndex;

typedef int NSGlyphInscription;

@interface NSLayoutManager : NSObject {
   NSTextStorage  *_textStorage;
   NSTypesetter   *_typesetter;

   id              _delegate;

   NSMutableArray  *_textContainers;

   struct NSRangeEntries *_glyphFragments;
   struct NSRangeEntries *_invalidFragments;

   BOOL             _layoutInvalid;

   NSRect           _extraLineFragmentRect;
   NSRect           _extraLineFragmentUsedRect;
   NSTextContainer *_extraLineFragmentTextContainer;

   unsigned    _rectCacheCapacity,_rectCacheCount;
   NSRectArray _rectCache;
}

-init;

-(NSTextStorage *)textStorage;
-(NSTypesetter *)typesetter;
-delegate;
-(NSArray *)textContainers;

-(NSTextView *)firstTextView;
-(NSTextView *)textViewForBeginningOfSelection;
-(BOOL)layoutManagerOwnsFirstResponderInWindow:(NSWindow *)window;

-(void)setTextStorage:(NSTextStorage *)textStorage;
-(void)replaceTextStorage:(NSTextStorage *)textStorage;
-(void)setTypesetter:(NSTypesetter *)typesetter;
-(void)setDelegate:delegate;

-(void)addTextContainer:(NSTextContainer *)container;
-(void)removeTextContainerAtIndex:(unsigned)index;
-(void)insertTextContainer:(NSTextContainer *)container atIndex:(unsigned)index;

-(unsigned)numberOfGlyphs;
-(unsigned)getGlyphs:(NSGlyph *)glyphs range:(NSRange)glyphRange;

-(unsigned)getGlyphsInRange:(NSRange)range glyphs:(NSGlyph *)glyphs characterIndexes:(unsigned *)charIndexes glyphInscriptions:(NSGlyphInscription *)inscriptions elasticBits:(BOOL *)elasticBits;

-(NSTextContainer *)textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange;
-(NSRect)lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange;
-(NSPoint)locationForGlyphAtIndex:(unsigned)glyphIndex;
-(NSRect)lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange;
-(NSRect)usedRectForTextContainer:(NSTextContainer *)container;
-(NSRect)extraLineFragmentRect;
-(NSRect)extraLineFragmentUsedRect;
-(NSTextContainer *)extraLineFragmentTextContainer;

-(void)setTextContainer:(NSTextContainer *)container forGlyphRange:(NSRange)glyphRange;
-(void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect;
-(void)setLocation:(NSPoint)location forStartOfGlyphRange:(NSRange)glyphRange;

-(void)setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container;

-(void)invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRangePointer)actualCharRange;
-(void)invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)isSoft actualCharacterRange:(NSRangePointer)actualCharRange;
-(void)invalidateDisplayForGlyphRange:(NSRange)glyphRange;
-(void)invalidateDisplayForCharacterRange:(NSRange)charRange;

-(void)textStorage:(NSTextStorage *)storage edited:(unsigned)editedMask range:(NSRange)range changeInLength:(int)changeInLength invalidatedRange:(NSRange)invalidateRange;

-(void)textContainerChangedGeometry:(NSTextContainer *)container;

-(unsigned)glyphIndexForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container fractionOfDistanceThroughGlyph:(float *)fraction;
-(unsigned)glyphIndexForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container;
-(float)fractionOfDistanceThroughGlyphForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container;

-(NSRange)glyphRangeForTextContainer:(NSTextContainer *)container;
-(NSRange)glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRangePointer)actualCharRange;
-(NSRange)glyphRangeForBoundingRect:(NSRect)bounds inTextContainer:(NSTextContainer *)container;
-(NSRange)glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds inTextContainer:(NSTextContainer *)container;
-(NSRange)rangeOfNominallySpacedGlyphsContainingIndex:(unsigned)glyphIndex;

-(NSRect)boundingRectForGlyphRange:(NSRange)glyphRange inTextContainer:(NSTextContainer *)container;
-(NSRectArray)rectArrayForGlyphRange:(NSRange)glyphRange withinSelectedGlyphRange:(NSRange)selectedGlyphRange inTextContainer:(NSTextContainer *)container rectCount:(unsigned *)rectCount;

-(unsigned)characterIndexForGlyphAtIndex:(unsigned)glyphIndex;
-(NSRange)characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange;
-(NSRectArray)rectArrayForCharacterRange:(NSRange)characterRange withinSelectedCharacterRange:(NSRange)selectedCharRange inTextContainer:(NSTextContainer *)container rectCount:(unsigned *)rectCount;

-(unsigned)firstUnlaidGlyphIndex;
-(unsigned)firstUnlaidCharacterIndex;
-(void)getFirstUnlaidCharacterIndex:(unsigned *)charIndex glyphIndex:(unsigned *)glyphIndex;

-(void)showPackedGlyphs:(char *)glyphs length:(unsigned)length glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment;

-(void)drawBackgroundForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)origin;
-(void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)origin;

@end

