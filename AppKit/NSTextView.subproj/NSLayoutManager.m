/* Copyright (c) 2006-2009 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSGlyphGenerator.h>
#import <AppKit/NSTypesetter.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextAttachment.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContextFunctions.h>

#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <ApplicationServices/ApplicationServices.h>
#import "../../Foundation/NSAttributedString/NSRangeEntries.h"
#import <Foundation/NSKeyedArchiver.h>

typedef struct {
   NSRect  rect;
   NSRect  usedRect;
   NSPoint location;
} NSGlyphFragment;

typedef struct {
   int _xxxNeedSomething;
} NSInvalidFragment;

@implementation NSLayoutManager

static inline NSGlyphFragment *fragmentForGlyphRange(NSLayoutManager *self,NSRange range){
   NSGlyphFragment *result=NSRangeEntryAtRange(self->_glyphFragments,range);

   if(result==NULL)
    [NSException raise:NSGenericException format:@"fragmentForGlyphRange fragment is NULL for range %d %d",range.location,range.length];

   return result;
}

static inline NSGlyphFragment *fragmentAtGlyphIndex(NSLayoutManager *self,unsigned index,NSRange *effectiveRange){
   NSGlyphFragment *result=NSRangeEntryAtIndex(self->_glyphFragments,index,effectiveRange);

   if(result==NULL){
    [NSException raise:NSGenericException format:@"fragmentAtGlyphIndex fragment is NULL for index %d",index];
   }

   return result;
}

-initWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;

   _textStorage=[keyed decodeObjectForKey:@"NSTextStorage"];
   _typesetter=[NSTypesetter new];
   _glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
   _delegate=[keyed decodeObjectForKey:@"NSDelegate"];
   _textContainers=[NSMutableArray new];
   [_textContainers addObjectsFromArray:[keyed decodeObjectForKey:@"NSTextContainers"]];
   _glyphFragments=NSCreateRangeToOwnedPointerEntries(2);
   _invalidFragments=NSCreateRangeToOwnedPointerEntries(2);
   _layoutInvalid=YES;
   _rectCacheCapacity=16;
   _rectCacheCount=0;
   _rectCache=NSZoneMalloc(NULL,sizeof(NSRect)*_rectCacheCapacity);    
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }
   return self;
}

-init {
   _typesetter=[NSTypesetter new];
   _glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
   _textContainers=[NSMutableArray new];
   _glyphFragments=NSCreateRangeToOwnedPointerEntries(2);
   _invalidFragments=NSCreateRangeToOwnedPointerEntries(2);
   _layoutInvalid=YES;
   _rectCacheCapacity=16;
   _rectCacheCount=0;
   _rectCache=NSZoneMalloc(NULL,sizeof(NSRect)*_rectCacheCapacity);
   return self;
}

-(void)dealloc {
   _textStorage=nil;
   [_typesetter release];
   [_glyphGenerator release];
   [_textContainers release];
   NSFreeRangeEntries(_glyphFragments);
   NSFreeRangeEntries(_invalidFragments);
   NSZoneFree(NULL,_rectCache);
   [super dealloc];
}

-(NSTextStorage *)textStorage {
   return _textStorage;
}

-(NSGlyphGenerator *)glyphGenerator {
   return _glyphGenerator;
}

-(NSTypesetter *)typesetter {
   return _typesetter;
}

-delegate {
   return _delegate;
}

-(NSArray *)textContainers {
   return _textContainers;
}

-(NSTextView *)firstTextView {
   return [[_textContainers objectAtIndex:0] textView];
}

-(NSTextView *)textViewForBeginningOfSelection {
   return [[_textContainers objectAtIndex:0] textView];
}

-(BOOL)layoutManagerOwnsFirstResponderInWindow:(NSWindow *)window {
   NSResponder *first=[window firstResponder];
   int          i,count=[_textContainers count];
   
   for(i=0;i<count;i++)
    if([[_textContainers objectAtIndex:i] textView]==first)
     return YES;
     
   return NO;
}

-(void)setTextStorage:(NSTextStorage *)textStorage {
   _textStorage=textStorage;
}

-(void)replaceTextStorage:(NSTextStorage *)textStorage {
   _textStorage=textStorage;
}

-(void)setGlyphGenerator:(NSGlyphGenerator *)generator {
   generator=[generator retain];
   [_glyphGenerator release];
   _glyphGenerator=generator;
}

-(void)setTypesetter:(NSTypesetter *)typesetter {
   typesetter=[typesetter retain];
   [_typesetter release];
   _typesetter=typesetter;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(BOOL)usesScreenFonts {
   return YES;
}

-(void)setUsesScreenFonts:(BOOL)yorn {

}

-(void)addTextContainer:(NSTextContainer *)container {
   [_textContainers addObject:container];
   [container setLayoutManager:self];
}

-(void)removeTextContainerAtIndex:(unsigned)index {
   [_textContainers removeObjectAtIndex:index];
}

-(void)insertTextContainer:(NSTextContainer *)container atIndex:(unsigned)index {
   [_textContainers insertObject:container atIndex:index];
   [container setLayoutManager:self];
}

-(void)insertGlyph:(NSGlyph)glyph atGlyphIndex:(unsigned)glyphIndex characterIndex:(unsigned)characterIndex {
}

-(void)replaceGlyphAtIndex:(unsigned)glyphIndex withGlyph:(NSGlyph)glyph {
}

-(void)deleteGlyphsInRange:(NSRange)glyphRange {
}

-(void)setCharacterIndex:(unsigned)characterIndex forGlyphAtIndex:(unsigned)glyphIndex {
}

-(void)setNotShownAttribute:(BOOL)notShown forGlyphAtIndex:(unsigned)glyphIndex {
}

-(void)setAttachmentSize:(NSSize)size forGlyphRange:(NSRange)glyphRange {
}

-(void)setDrawsOutsideLineFragment:(BOOL)drawsOutside forGlyphAtIndex:(unsigned)glyphIndex {
}

-(unsigned)numberOfGlyphs {
   return [_textStorage length];
}

-(NSFont *)_fontForGlyphRange:(NSRange)glyphRange {
   NSRange       characterRange=[self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
   NSDictionary *attributes=[_textStorage attributesAtIndex:characterRange.location effectiveRange:NULL];

   return NSFontAttributeInDictionary(attributes);
}

-(unsigned)getGlyphs:(NSGlyph *)glyphs range:(NSRange)glyphRange {
   NSRange characterRange=[self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
   NSFont *font=[self _fontForGlyphRange:glyphRange];
   unichar buffer[characterRange.length];

   [[_textStorage string] getCharacters:buffer range:characterRange];
   [font getGlyphs:glyphs forCharacters:buffer length:characterRange.length];

   return glyphRange.length;
}

-(unsigned)getGlyphsInRange:(NSRange)range glyphs:(NSGlyph *)glyphs characterIndexes:(unsigned *)charIndexes glyphInscriptions:(NSGlyphInscription *)inscriptions elasticBits:(BOOL *)elasticBits {
   return [self getGlyphsInRange:range glyphs:glyphs characterIndexes:charIndexes glyphInscriptions:inscriptions elasticBits:elasticBits bidiLevels:NULL];
}

-(unsigned)getGlyphsInRange:(NSRange)range glyphs:(NSGlyph *)glyphs characterIndexes:(unsigned *)charIndexes glyphInscriptions:(NSGlyphInscription *)inscriptions elasticBits:(BOOL *)elasticBits bidiLevels:(unsigned char *)bidiLevels {
   return 0;
}

-(NSTextContainer *)textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange {
   return nil;
}

-(NSRect)lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange {
   NSGlyphFragment *fragment=fragmentAtGlyphIndex(self,glyphIndex,effectiveGlyphRange);

   if(fragment==NULL)
    return NSZeroRect;

   return fragment->rect;
}

-(NSPoint)locationForGlyphAtIndex:(unsigned)glyphIndex {
   NSGlyphFragment *fragment= fragmentAtGlyphIndex(self,glyphIndex,NULL);

   if(fragment==NULL)
    return NSZeroPoint;

   return fragment->location;
}

-(NSRect)lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange {
   NSGlyphFragment *fragment= fragmentAtGlyphIndex(self,glyphIndex,effectiveGlyphRange);

   if(fragment==NULL)
    return NSZeroRect;

   return fragment->usedRect;
}

-(NSRange)validateGlyphsAndLayoutForGlyphRange:(NSRange)glyphRange {
   // DO: Validate glyphs in glyph cache for glyph range

   if(_layoutInvalid){
    NSResetRangeEntries(_glyphFragments);
    [_typesetter layoutGlyphsInLayoutManager:self startingAtGlyphIndex:0 maxNumberOfLineFragments:0 nextGlyphIndex:NULL];
    _layoutInvalid=NO;
   }

   return glyphRange;

#if 0
   unsigned glyphIndex=[self firstUnlaidGlyphIndex];

   while(glyphIndex<NSMaxRange(glyphRange)){
    [_typesetter layoutGlyphsInLayoutManager:self
      startingAtGlyphIndex:glyphIndex maxNumberOfLineFragments:2
            nextGlyphIndex:&glyphIndex];
   }
#endif
}

-(void)validateGlyphsAndLayoutForContainer:(NSTextContainer *)container {
   NSRange glyphRange=[self glyphRangeForTextContainer:container];

   [self validateGlyphsAndLayoutForGlyphRange:glyphRange];
}


-(NSRect)usedRectForTextContainer:(NSTextContainer *)container {
   [self validateGlyphsAndLayoutForContainer:container];
  {
   NSRect            result=NSZeroRect;
   BOOL              assignFirst=YES;
   NSRangeEnumerator state=NSRangeEntryEnumerator(_glyphFragments);
   NSRange           range;
   NSGlyphFragment  *fragment;

   while(NSNextRangeEnumeratorEntry(&state,&range,(void **)&fragment)){
    NSRect rect=fragment->usedRect;

    if(assignFirst){
     result=rect;
     assignFirst=NO;
    }
    else {
     result.origin.x=MIN(rect.origin.x,result.origin.x);
     result.origin.y=MIN(rect.origin.y,result.origin.y);
     result.size.width=MAX(NSMaxX(rect),NSMaxX(result))-result.origin.x;
     result.size.height=MAX(NSMaxY(rect),NSMaxY(result))-result.origin.y;
    }
   }

   return result;
  }
}

-(NSRect)extraLineFragmentRect {
   return _extraLineFragmentRect;
}

-(NSRect)extraLineFragmentUsedRect {
   return _extraLineFragmentUsedRect;
}

-(NSTextContainer *)extraLineFragmentTextContainer {
   return _extraLineFragmentTextContainer;
}

-(void)setTextContainer:(NSTextContainer *)container forGlyphRange:(NSRange)glyphRange {
   NSGlyphFragment *insert=NSZoneMalloc(NULL,sizeof(NSGlyphFragment));

   insert->rect=NSZeroRect;
   insert->usedRect=NSZeroRect;
   insert->location=NSZeroPoint;

   NSRangeEntryInsert(_glyphFragments,glyphRange,insert);
}

-(void)setLineFragmentRect:(NSRect)rect forGlyphRange:(NSRange)range usedRect:(NSRect)usedRect {
   NSGlyphFragment *fragment=fragmentForGlyphRange(self,range);

   if(fragment==NULL)
    return;

   fragment->rect=rect;
   fragment->usedRect=usedRect;
}

-(void)setLocation:(NSPoint)location forStartOfGlyphRange:(NSRange)range {
   NSGlyphFragment *fragment=fragmentForGlyphRange(self,range);

   if(fragment==NULL)
    return;

   fragment->location=location;
}

-(void)setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container {
   _extraLineFragmentRect=fragmentRect;
   _extraLineFragmentUsedRect=usedRect;
   _extraLineFragmentTextContainer=container;
}



-(void)invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRangePointer)actualRange {
   if(actualRange!=NULL)
    *actualRange=charRange;
}

-(void)invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)isSoft actualCharacterRange:(NSRangePointer)actualRangep {
#if 0
   unsigned location=charRange.location;
   unsigned limit=NSMaxRange(charRange);
   NSRange  actualRange=NSMakeRange(NSNotFound,NSNotFound);

   while(location<limit){
    NSRange            effectiveRange;
    NSGlyphFragment   *fragment=fragmentAtGlyphIndex(self,location,&effectiveRange);

    if(fragment!=NULL){
     NSInvalidFragment *invalid=NSZoneMalloc(NULL,sizeof(NSInvalidFragment));

     if(actualRange.location==NSNotFound)
      actualRange=effectiveRange;
     else
      actualRange=NSUnionRange(actualRange,effectiveRange);

     NSRangeEntryInsert(_invalidFragments,effectiveRange,invalid);
    }
   }
#endif
   _layoutInvalid=YES;
}

-(void)invalidateDisplayForGlyphRange:(NSRange)glyphRange {
   NSRange characterRange=[self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];

   [self invalidateDisplayForCharacterRange:characterRange];
}

-(void)invalidateDisplayForCharacterRange:(NSRange)charRange {
   int i,count=[_textContainers count];

//   charRange=[self validateGlyphsAndLayoutForGlyphRange:charRange];

   for(i=0;i<count;i++){
    NSTextContainer *container=[_textContainers objectAtIndex:i];
    NSTextView      *textView=[container textView];

    [textView sizeToFit];
    [textView setNeedsDisplay:YES];
   }
//FIX
}

// must be a more official way to do this
-(void)fixupSelectionInRange:(NSRange)range changeInLength:(int)changeInLength {
   int i,count=[_textContainers count];

   for(i=0;i<count;i++){
    NSTextContainer *container=[_textContainers objectAtIndex:i];
    NSTextView      *textView=[container textView];

    [textView setSelectedRange:NSMakeRange([_textStorage length],0)];
   }
}

-(void)textStorage:(NSTextStorage *)storage edited:(unsigned)editedMask range:(NSRange)range changeInLength:(int)changeInLength invalidatedRange:(NSRange)invalidateRange {
   NSRange actualRange;

   [self invalidateGlyphsForCharacterRange:invalidateRange changeInLength:changeInLength actualCharacterRange:&actualRange];

   [self invalidateLayoutForCharacterRange:actualRange isSoft:NO actualCharacterRange:&actualRange];

   [self invalidateDisplayForCharacterRange:actualRange];

   [self fixupSelectionInRange:range changeInLength:changeInLength];
}

-(void)textContainerChangedGeometry:(NSTextContainer *)container {
   NSRange range=NSMakeRange(0,[_textStorage length]);

   [self invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:NULL];
}

-(unsigned)glyphIndexForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container fractionOfDistanceThroughGlyph:(float *)fraction {
   unsigned          endOfFragment=0;
   NSRange           range;
   NSGlyphFragment  *fragment;
   NSRangeEnumerator state;

   [self validateGlyphsAndLayoutForContainer:container];

   *fraction=0;

   state=NSRangeEntryEnumerator(_glyphFragments);

   while(NSNextRangeEnumeratorEntry(&state,&range,(void **)&fragment)){

    if(point.y<NSMinY(fragment->rect)){
     if(endOfFragment>0){
// if we're at the end of a line we want to back up before the newline
// This is a very ugly way to do it
      if([[_textStorage string] characterAtIndex:endOfFragment-1]=='\n')
       endOfFragment--;
     }
     return endOfFragment;
    }
    if(point.y<NSMaxY(fragment->rect)){
     if(point.x<NSMinX(fragment->rect)){
      return range.location;
     }
     else if(point.x<NSMaxX(fragment->rect)){
      NSRect   glyphRect=fragment->usedRect;
      NSGlyph  glyphs[range.length];
      NSFont  *font=[self _fontForGlyphRange:range];
      unsigned i,length=[self getGlyphs:glyphs range:range];

      glyphRect.size.width=0;
 
      for(i=0;i<length;i++){
       NSGlyph glyph=glyphs[i];

       if(glyph!=NSControlGlyph){
        NSSize  advancement=[font advancementForGlyph:glyph];

        glyphRect.size.width=advancement.width;

        if(point.x>=NSMinX(glyphRect) && point.x<=NSMaxX(glyphRect)){
         *fraction=(point.x-glyphRect.origin.x)/glyphRect.size.width;
         return range.location+i;
        }

        glyphRect.origin.x+=advancement.width;
        glyphRect.size.width=0;
       }
      }
     }
    }

    endOfFragment=NSMaxRange(range);
   }

   return endOfFragment;
}

/* Apple's documentation claims glyphIndexForPoint:inTextContainer:fractionOfDistanceThroughGlyph: is implemented using these two methods. Verify. The method was split in two for the sake of Java, inefficient to keep it split */
-(unsigned)glyphIndexForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container {
   float fraction;

   return [self glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:&fraction];
}

-(float)fractionOfDistanceThroughGlyphForPoint:(NSPoint)point inTextContainer:(NSTextContainer *)container {
   float fraction;

   [self glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:&fraction];

   return fraction;
}

-(NSRange)glyphRangeForTextContainer:(NSTextContainer *)container {
   return NSMakeRange(0,[self numberOfGlyphs]);
}

-(NSRange)glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRangePointer)actualCharRange {
   if(actualCharRange!=NULL)
    *actualCharRange=charRange;

   return charRange;
}

-(NSRange)glyphRangeForBoundingRect:(NSRect)bounds inTextContainer:(NSTextContainer *)container {
   [self validateGlyphsAndLayoutForContainer:container];
  {
   NSRange           result=NSMakeRange(NSNotFound,0);
   NSRangeEnumerator state=NSRangeEntryEnumerator(_glyphFragments);
   NSRange           range;
   NSGlyphFragment  *fragment;

   while(NSNextRangeEnumeratorEntry(&state,&range,(void **)&fragment)){
    NSRect check=fragment->rect;

    if(NSIntersectsRect(bounds,check)){
     NSRange extend=range;

     if(result.location==NSNotFound)
      result=extend;
     else
      result=NSUnionRange(result,extend);
    }
   }

   return result;
  }
}

-(NSRange)glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds inTextContainer:(NSTextContainer *)container {
   return NSMakeRange(0,0);
}

-(NSRange)rangeOfNominallySpacedGlyphsContainingIndex:(unsigned)glyphIndex {
   return NSMakeRange(0,0);
}

-(NSRect)boundingRectForGlyphRange:(NSRange)glyphRange inTextContainer:(NSTextContainer *)container {
   glyphRange=[self validateGlyphsAndLayoutForGlyphRange:glyphRange];
  {
   NSRect      result=NSZeroRect;
   unsigned    i,rectCount=0;
   NSRect * rects=[self rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound,0)
     inTextContainer:container rectCount:&rectCount];

   for(i=0;i<rectCount;i++){
    if(i==0)
     result=rects[i];
    else
     result=NSUnionRect(result,rects[i]);
   }
   return result;
  }
}

static inline void _appendRectToCache(NSLayoutManager *self,NSRect rect){
   if(self->_rectCacheCount>=self->_rectCacheCapacity){
    self->_rectCacheCapacity*=2;
    self->_rectCache=NSZoneRealloc(NULL,self->_rectCache,sizeof(NSRect)*self->_rectCacheCapacity);
   }

   self->_rectCache[self->_rectCacheCount++]=rect;
}

-(NSRect *)rectArrayForGlyphRange:(NSRange)glyphRange withinSelectedGlyphRange:(NSRange)selGlyphRange inTextContainer:(NSTextContainer *)container rectCount:(unsigned *)rectCount {
   NSRange remainder=(selGlyphRange.location==NSNotFound)?glyphRange:selGlyphRange;

   _rectCacheCount=0;

   do {
    NSRange          range;
    NSGlyphFragment *fragment=fragmentAtGlyphIndex(self,remainder.location,&range);

    if(fragment==NULL)
     break;
    else {
     NSRange intersect=NSIntersectionRange(remainder,range);
     NSRect  fill=fragment->rect;

     if(!NSEqualRanges(range,intersect)){
      NSGlyph glyphs[range.length],previousGlyph=NSNullGlyph;
      int     i,length=[self getGlyphs:glyphs range:range];
      NSFont *font=[self _fontForGlyphRange:range];
      float   advance;
      BOOL    ignore;

      fill.size.width=0;
      for(i=0;i<length;i++){
       NSGlyph glyph=glyphs[i];

       if(glyph==NSControlGlyph)
        glyph=NSNullGlyph;

       advance=[font positionOfGlyph:glyph precededByGlyph:previousGlyph isNominal:&ignore].x;

       if(range.location+i<=intersect.location)
        fill.origin.x+=advance;
       else if(range.location+i<=NSMaxRange(intersect))
        fill.size.width+=advance;

       previousGlyph=glyph;
      }
      advance=[font positionOfGlyph:NSNullGlyph precededByGlyph:previousGlyph isNominal:&ignore].x;
      if(range.location+i<=NSMaxRange(intersect)){
       fill.size.width=NSMaxX(fragment->rect)-fill.origin.x;
      }

      range=intersect;
     }

     _appendRectToCache(self,fill);

     remainder.length=NSMaxRange(remainder)-NSMaxRange(range);
     remainder.location=NSMaxRange(range);
    }
   }while(remainder.length>0);

   *rectCount=_rectCacheCount;

   return _rectCache;
}

-(unsigned)characterIndexForGlyphAtIndex:(unsigned)glyphIndex {
// Validate glyphs;

   return glyphIndex;
}

-(NSRange)characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange {
   if(actualGlyphRange!=NULL)
    *actualGlyphRange=glyphRange;

   return glyphRange;
}

-(NSRect *)rectArrayForCharacterRange:(NSRange)characterRange withinSelectedCharacterRange:(NSRange)selectedCharRange inTextContainer:(NSTextContainer *)container rectCount:(unsigned *)rectCount {
   NSRange glyphRange=[self glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
   NSRange glyphSelRange=[self glyphRangeForCharacterRange:selectedCharRange actualCharacterRange:NULL];

   return [self rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:glyphSelRange inTextContainer:container rectCount:rectCount];
}

-(unsigned)firstUnlaidGlyphIndex {
   return NSNotFound;
}

-(unsigned)firstUnlaidCharacterIndex {
   return NSNotFound;
}

-(void)getFirstUnlaidCharacterIndex:(unsigned *)charIndex glyphIndex:(unsigned *)glyphIndex {
   *charIndex=[self firstUnlaidCharacterIndex];
   *glyphIndex=[self firstUnlaidGlyphIndex];
}

-(void)showPackedGlyphs:(char *)glyphs length:(unsigned)length glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment {
   CGContextRef context=NSCurrentGraphicsPort();
   CGGlyph     *cgGlyphs=(CGGlyph *)glyphs;
   int          cgGlyphsLength=length/2;

   CGContextShowGlyphsAtPoint(context,point.x,point.y,cgGlyphs,cgGlyphsLength);
}


-(void)drawSelectionAtPoint:(NSPoint)origin {
   NSTextView *textView=[self textViewForBeginningOfSelection];
   NSColor    *selectedColor=[[textView selectedTextAttributes] objectForKey:NSBackgroundColorAttributeName];
   NSRange     range;
   NSRect * rectArray;
   unsigned    i,rectCount=0;

   if(textView==nil)
    return;

   range=[textView selectedRange];
   if(range.length==0)
    return;

   rectArray=[self rectArrayForGlyphRange:range withinSelectedGlyphRange:range inTextContainer:[textView textContainer] rectCount:&rectCount];

   if(selectedColor==nil)
    selectedColor=[NSColor selectedTextBackgroundColor];

   [selectedColor setFill];
   for(i=0;i<rectCount;i++){
    NSRect fill=rectArray[i];
    fill.origin.x+=origin.x;
    fill.origin.y+=origin.y;
    NSRectFill(fill);
   }
}

-(void)drawBackgroundForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)origin {
   glyphRange=[self validateGlyphsAndLayoutForGlyphRange:glyphRange];
   {
    NSTextContainer *container=[self textContainerForGlyphAtIndex:glyphRange.location effectiveRange:&glyphRange];
    NSRange          characterRange=[self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    unsigned         location=characterRange.location;
    unsigned         limit=NSMaxRange(characterRange);
    BOOL             isFlipped=[[NSView focusView] isFlipped];
    float            usedHeight=[self usedRectForTextContainer:container].size.height;
    
    while(location<limit){
     NSRange          effectiveRange;
     NSDictionary    *attributes=[_textStorage attributesAtIndex:location effectiveRange:&effectiveRange];
     NSColor         *color=NSBackgroundColorAttributeInDictionary(attributes);

     effectiveRange=NSIntersectionRange(characterRange,effectiveRange);

     if(color!=nil){
      unsigned         i,rectCount;
      NSRect *      rects=[self rectArrayForCharacterRange:effectiveRange withinSelectedCharacterRange:NSMakeRange(NSNotFound,0) inTextContainer:container rectCount:&rectCount];

      [color setFill];

      for(i=0;i<rectCount;i++){
       NSRect fill=rects[i];

       if(!isFlipped)
        fill.origin.y=usedHeight-(fill.origin.y+fill.size.height);

       fill.origin.x+=origin.x;
       fill.origin.y+=origin.y;
        
       NSRectFill(fill);
      }
     }

     location=NSMaxRange(effectiveRange);
    }
   }
   [self drawSelectionAtPoint:origin];
}

-(void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)origin {
   NSTextView *textView=[self textViewForBeginningOfSelection];
   NSRange     selectedRange=(textView==nil)?NSMakeRange(0,0):[textView selectedRange];
   NSColor    *selectedColor=[[textView selectedTextAttributes] objectForKey:NSForegroundColorAttributeName];
   
   NSTextContainer *container=[self textContainerForGlyphAtIndex:glyphRange.location effectiveRange:&glyphRange];
   BOOL             isFlipped=[[NSView focusView] isFlipped];
   float            usedHeight=[self usedRectForTextContainer:container].size.height;

   if(selectedColor==nil)
    selectedColor=[NSColor selectedTextColor];

   glyphRange=[self validateGlyphsAndLayoutForGlyphRange:glyphRange];

   {
    NSRangeEnumerator state=NSRangeEntryEnumerator(_glyphFragments);
    NSRange range;
    NSGlyphFragment *fragment;

    while(NSNextRangeEnumeratorEntry(&state,&range,(void **)&fragment)){
     NSRange intersect=NSIntersectionRange(range,glyphRange);

     if(intersect.length>0){
      NSPoint           point=NSMakePoint(fragment->location.x,fragment->location.y);
      NSRange           characterRange=[self characterRangeForGlyphRange:range actualGlyphRange:NULL];
      NSRange           intersectRange=NSIntersectionRange(selectedRange,characterRange);
      NSDictionary     *attributes=[_textStorage attributesAtIndex:characterRange.location effectiveRange:NULL];
      NSTextAttachment *attachment=[attributes objectForKey:NSAttachmentAttributeName];

       if(!isFlipped)
        point.y=usedHeight-point.y;

      point.x+=origin.x;
      point.y+=origin.y;
      
      if(attachment!=nil){
       id <NSTextAttachmentCell> cell=[attachment attachmentCell];
       NSRect frame;
       
       frame.origin=point;
       frame.size=[cell cellSize];
       
       [cell drawWithFrame:frame inView:textView characterIndex:characterRange.location layoutManager:self];
      }
      else {
       NSColor      *color=NSForegroundColorAttributeInDictionary(attributes);
       NSFont       *font=NSFontAttributeInDictionary(attributes);
       NSMultibyteGlyphPacking packing=[font glyphPacking];
       NSGlyph       glyphs[range.length];
       unsigned      glyphsLength;
       char          packedGlyphs[range.length];
       int           packedGlyphsLength;

       glyphsLength=[self getGlyphs:glyphs range:range];

       [font set];

       if(intersectRange.length>0){
        NSGlyph  previousGlyph=NSNullGlyph;
        float    partWidth=0;
        unsigned i,location=range.location;
        unsigned limit=NSMaxRange(range);

        for(i=0;location<=limit;i++,location++){
         NSGlyph  glyph=(location<limit)?glyphs[i]:NSNullGlyph;
         BOOL     ignore;
         unsigned start=0;
         unsigned length=0;
         BOOL     showGlyphs=NO;

         if(location==intersectRange.location && location>range.location){
          [color set];

          start=0;
          length=location-range.location;
          showGlyphs=YES;
         }
         else if(location==NSMaxRange(intersectRange)){
          [selectedColor set];

          start=intersectRange.location-range.location;
          length=intersectRange.length;
          showGlyphs=YES;
         }
         else if(location==limit){
          [color set];

          start=NSMaxRange(intersectRange)-range.location;
          length=NSMaxRange(range)-NSMaxRange(intersectRange);
          showGlyphs=YES;
         }

         if(!showGlyphs)
          partWidth+=[font positionOfGlyph:glyph precededByGlyph:previousGlyph isNominal:&ignore].x;
         else {
          packedGlyphsLength=NSConvertGlyphsToPackedGlyphs(glyphs+start,length,packing,packedGlyphs);
          [self showPackedGlyphs:packedGlyphs length:packedGlyphsLength glyphRange:range atPoint:point font:font color:color printingAdjustment:NSZeroSize];
          partWidth+=[font positionOfGlyph:glyph precededByGlyph:previousGlyph isNominal:&ignore].x;
          point.x+=partWidth;
          partWidth=0;
         }

         previousGlyph=glyph;
        }
       }
       else {
        [color set];
        packedGlyphsLength=NSConvertGlyphsToPackedGlyphs(glyphs,glyphsLength,packing,packedGlyphs);
        [self showPackedGlyphs:packedGlyphs length:packedGlyphsLength glyphRange:range atPoint:point font:font color:color printingAdjustment:NSZeroSize];
       }
      }
     }
    }
   }
}

// dwy
- (NSRange)_softLineRangeForCharacterAtIndex:(unsigned)location {
    NSRange result=NSMakeRange(location,0);
    int i, j;
    float origin;
    NSGlyphFragment *fragment;

    if (location >= [[_textStorage string] length])
        location = [[_textStorage string] length]-1;

    result = [self glyphRangeForCharacterRange:result actualCharacterRange:NULL];

    fragment = NSRangeEntryAtIndex(self->_glyphFragments, result.location, NULL);
    if (fragment == NULL)
        return result;
    
    origin = fragment->location.y;

    i = result.location;
    j = result.location;
    while ((fragment = NSRangeEntryAtIndex(self->_glyphFragments, i-1, NULL))) {
        if (fragment->location.y != origin)
            break;
        result.location=i;
        i--;
    }

    result.location = i;
    while ((fragment = NSRangeEntryAtIndex(self->_glyphFragments, j, NULL))) {
        if (fragment->location.y != origin)
            break;
        j++;
    }

    result.length = j - i;

#if 0    
// broken for empty lines
    // word-break fixup; best effort; produces some strange effects when a single word is wider than the view
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[[_textStorage string] characterAtIndex:NSMaxRange(result)-1]])
        result.length--;
#endif

    return [self characterRangeForGlyphRange:result actualGlyphRange:NULL];
}

-(float)defaultLineHeightForFont:(NSFont *)font {
   return [font defaultLineHeightForFont];
}

@end

