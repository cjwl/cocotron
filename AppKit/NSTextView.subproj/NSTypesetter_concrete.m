/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSTypesetter_concrete.h"
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSRangeArray.h>
#import <AppKit/NSTextAttachment.h>
#import <AppKit/NSTextTab.h>
#import <AppKit/NSImage.h>

@implementation NSTypesetter_concrete

-init {
   [super init];
   _layoutNextFragment=[self methodForSelector:@selector(layoutNextFragment)];
   _glyphCacheRange=NSMakeRange(0,0);
   _glyphCacheCapacity=256;
   _glyphCache=NSZoneMalloc([self zone],sizeof(NSGlyph)*_glyphCacheCapacity);
   _characterCache=NSZoneMalloc([self zone],sizeof(unichar)*_glyphCacheCapacity);

   _glyphRangesInLine=[NSRangeArray new];
   return self;
}

-(void)dealloc {
   NSZoneFree([self zone],_glyphCache);
   NSZoneFree([self zone],_characterCache);
   [_container release];

   [_glyphRangesInLine release];
   [super dealloc];
}

static void loadGlyphAndCharacterCacheForLocation(NSTypesetter_concrete *self,unsigned location) {
   unsigned length=MIN(self->_glyphCacheCapacity,NSMaxRange(self->_attributesGlyphRange)-location);

   self->_glyphCacheRange=NSMakeRange(location,length);

   [self->_string getCharacters:self->_characterCache range:self->_glyphCacheRange];
   [self->_layoutManager getGlyphs:self->_glyphCache range:self->_glyphCacheRange];
}

-(void)layoutNextFragment {
   unsigned glyphIndex;
   NSRange  fragmentRange=NSMakeRange(_nextGlyphLocation,0);
   float    fragmentWidth=0;
   float    fragmentHeight=_fontDefaultLineHeight;
   NSRange  wordWrapRange=NSMakeRange(_nextGlyphLocation,0);
   float    wordWrapWidth=0;
   NSGlyph  wordWrapPreviousGlyph=NSNullGlyph;

   NSRect   fragmentRect;
   BOOL     isNominal,advanceScanRect=NO,endOfString=NO;

   for(;(glyphIndex=NSMaxRange(fragmentRange))<NSMaxRange(_attributesGlyphRange);){
    NSGlyph  glyph;
    unichar  character;
    float    glyphAdvance,glyphMaxWidth;
    BOOL     fragmentExit=NO;

    fragmentRange.length++;
    _lineRange.length++;

    if(!NSLocationInRange(glyphIndex,_glyphCacheRange))
     loadGlyphAndCharacterCacheForLocation(self,glyphIndex);

    glyph=_glyphCache[glyphIndex-_glyphCacheRange.location];
    character=_characterCache[glyphIndex-_glyphCacheRange.location];
    if(character==' '){
     wordWrapRange=fragmentRange;
     wordWrapWidth=fragmentWidth;
     wordWrapPreviousGlyph=_previousGlyph;
    }

    if(character==NSAttachmentCharacter){
     NSTextAttachment         *attachment=[_attributes objectForKey:NSAttachmentAttributeName];
     id <NSTextAttachmentCell> cell=[attachment attachmentCell];
     NSSize                    size=[cell cellSize];

     fragmentHeight=size.height;
     glyphAdvance=_positionOfGlyph(_font,NULL,NSNullGlyph,_previousGlyph,&isNominal).x;
     glyphMaxWidth=size.width;
     _previousGlyph=NSNullGlyph;
    }
    else {
     if(glyph==NSControlGlyph){
      fragmentWidth+=_positionOfGlyph(_font,NULL,NSNullGlyph,_previousGlyph,&isNominal).x;
      _previousGlyph=NSNullGlyph;

      switch([self actionForControlCharacterAtIndex:glyphIndex]){
      
       case NSTypesetterZeroAdvancementAction:
        // do nothing
        break;
        
       case NSTypesetterWhitespaceAction:
        fragmentWidth+=_whitespaceAdvancement;
        break;
        
       case NSTypesetterHorizontalTabAction:{
         float      x=_scanRect.origin.x+fragmentWidth;
         NSTextTab *tab=[self textTabForGlyphLocation:x writingDirection:[_currentParagraphStyle baseWritingDirection] maxLocation:NSMaxX(_scanRect)];
         float      nextx;
       
         if(tab!=nil)
          nextx=[tab location];
         else {
          float interval=[_currentParagraphStyle defaultTabInterval];
          
          if(interval>0)
           nextx=(((int)(x/interval))+1)*interval;
          else
           nextx=x;
         }
        
         fragmentWidth+=nextx-x;
        }
        break;
        
       case NSTypesetterLineBreakAction:
       case NSTypesetterParagraphBreakAction:
       case NSTypesetterContainerBreakAction:
        advanceScanRect=YES;
        break;
      }
      
      break;
     }

     glyphAdvance=_positionOfGlyph(_font,NULL,glyph,_previousGlyph,&isNominal).x;

     if(!isNominal && fragmentRange.length>1){
      _lineRange.length--;
      fragmentRange.length--;
      fragmentWidth+=glyphAdvance;
      _previousGlyph=NSNullGlyph;
      fragmentExit=YES;
      break;
     }

     glyphMaxWidth=_positionOfGlyph(_font,NULL,NSNullGlyph,glyph,&isNominal).x;
    }

    switch(_lineBreakMode){

     case NSLineBreakByWordWrapping:
      if(_lineRange.length>1){
       if(fragmentWidth+glyphAdvance+glyphMaxWidth>_scanRect.size.width){
        if(wordWrapWidth>0){
         _lineRange.length=NSMaxRange(wordWrapRange)-_lineRange.location;
         fragmentRange=wordWrapRange;
         fragmentWidth=wordWrapWidth;
         _previousGlyph=wordWrapPreviousGlyph;
        }
        else {
         _lineRange.length--;
         fragmentRange.length--;
        }
        fragmentExit=YES;
        advanceScanRect=YES;
       }
      }
      break;

     case NSLineBreakByCharWrapping:
      if(_lineRange.length>1){
       if(fragmentWidth+glyphAdvance+glyphMaxWidth>_scanRect.size.width){
        _lineRange.length--;
        fragmentRange.length--;
        fragmentExit=YES;
        advanceScanRect=YES;
       }
      }
      break;

     case NSLineBreakByClipping:
      break;

     default:
      break;
    }

    if(fragmentExit){
     fragmentWidth+=glyphMaxWidth;
     _previousGlyph=NSNullGlyph;
     break;
    }

    _previousGlyph=glyph;
    fragmentWidth+=glyphAdvance;
   }

   if(fragmentRange.length>0){
    _nextGlyphLocation=NSMaxRange(fragmentRange);

    if(_nextGlyphLocation>=_numberOfGlyphs)
     endOfString=YES;

    if(glyphIndex==NSMaxRange(_attributesGlyphRange)){
     fragmentWidth+=_positionOfGlyph(_font,NULL,NSNullGlyph,_previousGlyph,&isNominal).x;
     _previousGlyph=NSNullGlyph;
    }

    [_glyphRangesInLine addRange:fragmentRange];
    _scanRect.size.height=MAX(_scanRect.size.height,fragmentHeight);
    _maxAscender=MAX(_maxAscender,_fontAscender);

    [_layoutManager setTextContainer:_container forGlyphRange:fragmentRange];
    fragmentRect=_scanRect;
    fragmentRect.size.width=fragmentWidth;
    [_layoutManager setLineFragmentRect:_scanRect forGlyphRange:fragmentRange usedRect:fragmentRect];
    [_layoutManager setLocation:_scanRect.origin forStartOfGlyphRange:fragmentRange];
   }

   if(advanceScanRect || endOfString){
    int   i,count=[_glyphRangesInLine count];
    float alignmentDelta=0;

    if(_alignment!=NSLeftTextAlignment){
     float totalWidth=0;
     float totalUsedWidth=_containerSize.width;

     for(i=0;i<count;i++){
      NSRange range=[_glyphRangesInLine rangeAtIndex:i];
      NSRect  usedRect=[_layoutManager lineFragmentUsedRectForGlyphAtIndex:range.location effectiveRange:NULL];

      totalWidth+=usedRect.size.width;
     }

     totalWidth=ceil(totalWidth);

     switch(_alignment){

      case NSRightTextAlignment:
       alignmentDelta=totalUsedWidth-totalWidth;
       break;

      case NSCenterTextAlignment:
       alignmentDelta=(totalUsedWidth-totalWidth)/2;
       break;

      default:
       break;
     }
    }

    for(i=0;i<count;i++){
     NSRange range=[_glyphRangesInLine rangeAtIndex:i];
     NSRect  backRect=[_layoutManager lineFragmentRectForGlyphAtIndex:range.location effectiveRange:NULL];
     NSRect  usedRect=[_layoutManager lineFragmentUsedRectForGlyphAtIndex:range.location effectiveRange:NULL];
     NSPoint location=[_layoutManager locationForGlyphAtIndex:range.location];

     backRect.size.height=_scanRect.size.height;
     location.y+=_maxAscender;

     if(i==0)
      backRect.size.width+=alignmentDelta;
     usedRect.origin.x+=alignmentDelta;
     location.x+=alignmentDelta;
     if(i+1==count)
      backRect.size.width-=alignmentDelta;

     if(i+1<count || !advanceScanRect || endOfString)
      [_layoutManager setLineFragmentRect:usedRect forGlyphRange:range usedRect:usedRect];
     else
      [_layoutManager setLineFragmentRect:backRect forGlyphRange:range usedRect:usedRect];

     [_layoutManager setLocation:location forStartOfGlyphRange:range];
    }

    [_glyphRangesInLine removeAllRanges];
   }

   if(advanceScanRect){
    _lineRange.location=NSMaxRange(fragmentRange);
    _lineRange.length=0;
    _scanRect.origin.x=0;
    _scanRect.origin.y+=_scanRect.size.height;
    _scanRect.size.width=_containerSize.width;
    _scanRect.size.height=0;
    _maxAscender=0;
   }
   else {
    _scanRect.origin.x+=fragmentWidth;
    _scanRect.size.width-=fragmentWidth;
   }
}

-(void)fetchAttributes {
   NSFont  *nextFont;
   unsigned characterIndex=_nextGlyphLocation; // FIX
   NSGlyph  spaceGlyph;
   unichar  space=' ';

   _attributes=[_attributedString attributesAtIndex:characterIndex effectiveRange:&_attributesRange];

   _attributesGlyphRange=_attributesRange; // FIX

   nextFont=NSFontAttributeInDictionary(_attributes);
   if(_font!=nextFont){
    _previousGlyph=NSNullGlyph;
    _font=nextFont;
    _fontAscender=[_font ascender];
    _fontDefaultLineHeight=[_font defaultLineHeightForFont];
    _positionOfGlyph=(void *)[_font methodForSelector:@selector(positionOfGlyph:precededByGlyph:isNominal:)];

    [_font getGlyphs:&spaceGlyph forCharacters:&space length:1];
    _whitespaceAdvancement=[_font advancementForGlyph:spaceGlyph].width;
   }

   if((_currentParagraphStyle=[_attributes objectForKey:NSParagraphStyleAttributeName])==nil)
    _currentParagraphStyle=[NSParagraphStyle defaultParagraphStyle];
   _alignment=[_currentParagraphStyle alignment];
   _lineBreakMode=[_currentParagraphStyle lineBreakMode];
}

-(void)layoutGlyphsInLayoutManager:(NSLayoutManager *)layoutManager
       startingAtGlyphIndex:(unsigned)glyphIndex
   maxNumberOfLineFragments:(unsigned)maxNumLines
             nextGlyphIndex:(unsigned *)nextGlyph {
   [_layoutManager release];
   _layoutManager=[layoutManager retain];
   _textContainers=[layoutManager textContainers];
   
   [self setAttributedString:[layoutManager textStorage]];
   
   _nextGlyphLocation=0;
   _numberOfGlyphs=[_string length];
   _glyphCacheRange=NSMakeRange(0,0);
   _previousGlyph=NSNullGlyph;

   [_container release];
   _container=[[[_layoutManager textContainers] objectAtIndex:0] retain];
   _containerSize=[_container containerSize];

   _attributesRange=NSMakeRange(0,0);
   _attributesGlyphRange=NSMakeRange(0,0);
   _attributes=nil;
   _font=nil;

   _lineRange=NSMakeRange(0,0);
   [_glyphRangesInLine removeAllRanges];
   _previousGlyph=NSNullGlyph;
   _scanRect.origin.x=0;
   _scanRect.origin.y=0;
   _scanRect.size.width=_containerSize.width;
   _scanRect.size.height=0;
   _maxAscender=0;

   while(_nextGlyphLocation<_numberOfGlyphs){

    if(!NSLocationInRange(_nextGlyphLocation,_attributesRange))
     [self fetchAttributes];

    _layoutNextFragment(self,NULL);
   }

   if(_font==nil){
    _font=NSFontAttributeInDictionary(nil);
    _fontAscender=[_font ascender];
    _fontDefaultLineHeight=[_font defaultLineHeightForFont];
    _positionOfGlyph=(void *)[_font methodForSelector:@selector(positionOfGlyph:precededByGlyph:isNominal:)];
   }
   _scanRect.size.height=MAX(_scanRect.size.height,_fontDefaultLineHeight);
   [_layoutManager setExtraLineFragmentRect:_scanRect usedRect:_scanRect textContainer:_container];

   _currentParagraphStyle=nil;
   _font=nil;
   _attributes=nil;

   [_container release];
   _container=nil;
   [self setAttributedString:nil];
   _textContainers=nil;
   [_layoutManager release];
   _layoutManager=nil;
}

@end
