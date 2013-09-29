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
#import <AppKit/NSRaise.h>

#import "NSBidiHelper.h"

@interface NSLayoutManager(private)
- (void)_rollbackLatestFragment;
@end

@interface NSTypesetter_concrete(forward)
- (void)_updateBidiLevelsForRange:(NSRange)range;
@end

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
    NSZoneFree([self zone],_bidiLevels);
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

- (void)getLineFragmentRect:(NSRectPointer)lineFragmentRect usedRect:(NSRectPointer)lineFragmentUsedRect remainingRect:(NSRectPointer)remainingRect forStartingGlyphAtIndex:(unsigned)startingGlyphIndex proposedRect:(NSRect)proposedRect lineSpacing:(float)lineSpacing paragraphSpacingBefore:(float)paragraphSpacingBefore paragraphSpacingAfter:(float)paragraphSpacingAfter
{
	unsigned glyphIndex;
	NSRange  fragmentRange=NSMakeRange(_nextGlyphLocation,0);
	float    fragmentWidth=0;
	float    fragmentHeight=_fontDefaultLineHeight;
	NSRange  wordWrapRange=NSMakeRange(_nextGlyphLocation,0);
	float    wordWrapWidth=0;
	NSGlyph  wordWrapPreviousGlyph=NSNullGlyph;
	NSRect   fragmentRect;
	BOOL     isNominal,advanceScanRect=NO,endOfString=NO,endOfLine=NO;

	_scanRect = proposedRect;
	
	float wantedHeight = MAX(proposedRect.size.height, fragmentHeight);
	_scanRect.size.height = wantedHeight;

	_scanRect = [_container lineFragmentRectForProposedRect:_scanRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:remainingRect];
	if ([_glyphRangesInLine count] != 0 && _scanRect.origin.y > proposedRect.origin.y) {
		// We don't want the rects to move down, if it's not the first one of the line
		// We could use NSLineNoMove with lineFragmentRectForProposedRect but Cocoa doesn't do that
		_scanRect = NSZeroRect;
	}
	if (_scanRect.size.height < wantedHeight) {
		// Too small for our text
		_scanRect = NSZeroRect;		
	}
	if (!NSEqualRects(_scanRect, NSZeroRect)) {
		// Add left/right padding
		_scanRect.size.width -= _container.lineFragmentPadding;
		if ([_glyphRangesInLine count] == 0) {
			// Add left padding too for the first fragment of the line
			_scanRect.size.width -= _container.lineFragmentPadding;
			_scanRect.origin.x += _container.lineFragmentPadding;
			_fullLineRect = _scanRect;
		}
		if (_scanRect.size.width <= 0.) {
			_scanRect = NSZeroRect;
		}
	}
	if (NSEqualRects(_scanRect, NSZeroRect)) {
		if ([_glyphRangesInLine count] == 0) {
			// No more room for another line
			return;
		} else {
			// No more room on that line - we will try next one - just reset the scanRect location to the end of the line
			// so the advanceScanRect logic will continue from the right place
			_scanRect.origin.x = NSMaxX(_fullLineRect);
			_scanRect.origin.y = NSMinY(proposedRect);
			_scanRect.size.width = 0;
			_scanRect.size.height = MAX(proposedRect.size.height, fragmentHeight);
		}
	}

	for(;(glyphIndex=NSMaxRange(fragmentRange))<NSMaxRange(_attributesGlyphRange);){
		NSGlyph  glyph;
		unichar  character;
		float    glyphAdvance,glyphMaxWidth;
		BOOL     fragmentExit=NO;
		
		_paragraphBreak=NO;
		fragmentRange.length++;
		_lineRange.length++;
		
		if(!NSLocationInRange(glyphIndex,_glyphCacheRange))
			loadGlyphAndCharacterCacheForLocation(self,glyphIndex);
		
		glyph=_glyphCache[glyphIndex-_glyphCacheRange.location];
		character=_characterCache[glyphIndex-_glyphCacheRange.location];
        // TODO: there must be other chars to check for word wrapping
		if(character==' '){
			// We can word wrap from here if needed
			wordWrapRange=fragmentRange;
			wordWrapWidth=fragmentWidth;
			wordWrapPreviousGlyph=_previousGlyph;
			// Keep the info so we can rollback to that point even if we switch to another 
			// fragment
			_wordWrapWidth=wordWrapWidth;
			_wordWrapRange=wordWrapRange;
			_wordWrapPreviousGlyph=wordWrapPreviousGlyph;
			_wordWrapScanRect = _scanRect;
		}
		
		if(character==NSAttachmentCharacter){
			NSTextAttachment         *attachment=[_attributes objectForKey:NSAttachmentAttributeName];
			id <NSTextAttachmentCell> cell=[attachment attachmentCell];
			NSSize                    size=[cell cellSize];
			
			fragmentHeight=size.height;
			glyphAdvance=_positionOfGlyph(_font,NULL,NSNullGlyph,_previousGlyph,&isNominal).x;
			glyphMaxWidth=size.width;
			_previousGlyph=NSNullGlyph;
		} else {
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
						
					case NSTypesetterParagraphBreakAction:
						_paragraphBreak=YES;
						advanceScanRect=YES;
						break;
					case NSTypesetterLineBreakAction:
						advanceScanRect=YES;
						break;
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
							// Break the line at previously found wrap location
							_lineRange.length=NSMaxRange(wordWrapRange)-_lineRange.location;
							fragmentRange=wordWrapRange;
							fragmentWidth=wordWrapWidth;
							_previousGlyph=wordWrapPreviousGlyph;
							wordWrapWidth = _wordWrapWidth = 0;
						} else {
							if ([_glyphRangesInLine count] != 0) {
								// We need to rollback all of the previous fragments until one ending with a white space
								//		 because words can span on several fragment because of some attribute changes
								if (_wordWrapWidth > 0) {
									_lineRange.length=NSMaxRange(_wordWrapRange)-_lineRange.location;
									// Rollback all fragments up to the previous wrapable one
									do {
										NSRange range = [_glyphRangesInLine rangeAtIndex:[_glyphRangesInLine count]- 1];
										[_layoutManager _rollbackLatestFragment];
										[_glyphRangesInLine removeRangeAtIndex:[_glyphRangesInLine count]- 1];
										if (_wordWrapRange.location == range.location) {
											break;
										}
									} while ([_glyphRangesInLine count]);
									_scanRect = _wordWrapScanRect;
									fragmentRange=_wordWrapRange;
									fragmentWidth=_wordWrapWidth;
									_previousGlyph=_wordWrapPreviousGlyph;
									wordWrapWidth = _wordWrapWidth = 0;
								} else {
									// We'll put the whole fragment on next line
									// No more room on that line - we will try next one - just reset the scanRect location to the end of the line
									// so the advanceScanRect logic will continue from the right place
									_scanRect.origin.x = NSMaxX(_fullLineRect);
									_scanRect.origin.y = NSMinY(proposedRect);
									_scanRect.size.width = 0;
									_scanRect.size.height = MAX(proposedRect.size.height, fragmentHeight);
									_lineRange.length -= fragmentRange.length;
									fragmentRange.length=0;
									fragmentWidth=0;
								}
							} else {
								// No wrapping location candidate - we'll just break the line
								// at current glyph
								_lineRange.length--;
								fragmentRange.length--;
							}
						}
						fragmentExit=YES;
						advanceScanRect=YES;
					}
				}
				break;
				
			case NSLineBreakByCharWrapping:
				if(_lineRange.length>1){
					if(fragmentWidth+glyphAdvance+glyphMaxWidth>_scanRect.size.width){
						// Break the line at current glyph
						_lineRange.length--;
						fragmentRange.length--;
						fragmentExit=YES;
						advanceScanRect=YES;
					}
				}
				break;
				
			case NSLineBreakByClipping:
				// Nothing special to do
				break;
				
			case NSLineBreakByTruncatingHead:
			case NSLineBreakByTruncatingTail:
			case NSLineBreakByTruncatingMiddle:
				// TODO: implement these styles
				break;
			default:
				break;
		}
		
		if (fragmentExit == NO && _alignment == NSJustifiedTextAlignment) {
			if (character == ' ') {
				// Make a new fragment after a ' ' so we can insert some white spaces to justify the line
				_previousGlyph=glyph;
				fragmentWidth+=glyphAdvance;
				break;
			}
		}
		if(fragmentExit){
			_previousGlyph=NSNullGlyph;
			fragmentWidth+=glyphAdvance;
			break;
		}
		_previousGlyph=glyph;
		fragmentWidth+=glyphAdvance;
	}
	
	if(fragmentRange.length>0){
		_nextGlyphLocation=NSMaxRange(fragmentRange);
		
		if(_nextGlyphLocation>=_numberOfGlyphs) {
			endOfString=YES;
		} else {
			if(!NSLocationInRange(_nextGlyphLocation,_glyphCacheRange))
				loadGlyphAndCharacterCacheForLocation(self,_nextGlyphLocation);
			
			int nextChar=_characterCache[glyphIndex-_glyphCacheRange.location];
			if (nextChar == '\n') {
				endOfLine=YES;
			}
		}
		
		if(!advanceScanRect){
			fragmentWidth+=_positionOfGlyph(_font,NULL,NSNullGlyph,_previousGlyph,&isNominal).x;
			// This should be done only when switching font or something?
			if (glyphIndex==NSMaxRange(_attributesGlyphRange)) {
				_previousGlyph=NSNullGlyph;
			} else {
				// Break because of full justification
			}
		}
		float height = MAX(_scanRect.size.height,fragmentHeight);
		if (_scanRect.size.height != height) {
			// Check we still fit if something changed our height
			_scanRect.size.height=height;
			_scanRect = [_container lineFragmentRectForProposedRect:_scanRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:remainingRect];
		}
		if (!NSEqualRects(_scanRect, NSZeroRect)) {
			[_glyphRangesInLine addRange:fragmentRange];
			_maxAscender=MAX(_maxAscender,_fontAscender);
			[_layoutManager setTextContainer:_container forGlyphRange:fragmentRange];
			fragmentRect=_scanRect;
			fragmentRect.size.width=fragmentWidth;
			[_layoutManager setLineFragmentRect:_scanRect forGlyphRange:fragmentRange usedRect:fragmentRect];
			[_layoutManager setLocation:_scanRect.origin forStartOfGlyphRange:fragmentRange];
		} else {
			// Can't fit any more text
			return;
		}
	}
		
	if(advanceScanRect || endOfString){
		// We're done with a line - fix the fragment rects for its
		int   i,count=[_glyphRangesInLine count];
		float alignmentDelta=0;
		
        // First, we need to reorder the fragments according to the bidi algo
        if (_bidiLevels && count > 1) {
            uint8_t levels[count];
            unsigned int indexes[count];
            for (int i = 0; i < count; ++i) {
                NSRange range=[_glyphRangesInLine rangeAtIndex:i];
                levels[i] = _bidiLevels[range.location];
                indexes[i] = i;
            }
            int baseLevel = _currentParagraphBidiLevel;
            NSBidiHelperProcessLine(baseLevel, indexes, NULL, levels, NO, count);

            NSRange range=[_glyphRangesInLine rangeAtIndex:0];
            NSPoint currentLocation =[_layoutManager locationForGlyphAtIndex:range.location];
            for (int i = 0; i < count; ++i) {
                int idx = indexes[i];
                NSRange range=[_glyphRangesInLine rangeAtIndex:idx];
                NSPoint location=[_layoutManager locationForGlyphAtIndex:range.location];
                NSRect  usedRect=[_layoutManager lineFragmentUsedRectForGlyphAtIndex:range.location effectiveRange:NULL];
                NSRect  rect=[_layoutManager lineFragmentRectForGlyphAtIndex:range.location effectiveRange:NULL];
                usedRect.origin = currentLocation;
                rect.origin = currentLocation;
                [_layoutManager setLineFragmentRect:rect forGlyphRange:range usedRect:usedRect];
                [_layoutManager setLocation:currentLocation forStartOfGlyphRange:range];
                currentLocation.x += usedRect.size.width;
            }
            // Reorder the ranges LtoR
            for (int i = 0; i < count; ++i) {
                int idx = indexes[i];
                [_glyphRangesInLine addRange:[_glyphRangesInLine rangeAtIndex:idx]];
            }
            for (int i = 0; i < count; ++i) {
                [_glyphRangesInLine removeRangeAtIndex:0];
            }
        }

		if(_alignment!=NSLeftTextAlignment){
			// Find the total line width so we can adjust the rect x origin according to the alignment
			float totalWidth=NSMaxX(_fullLineRect);
			
			float totalUsedWidth=0;
			if (count) {
				NSRange range=[_glyphRangesInLine rangeAtIndex:count-1];
				NSRect  usedRect=[_layoutManager lineFragmentUsedRectForGlyphAtIndex:range.location effectiveRange:NULL];
				totalUsedWidth=NSMaxX(usedRect);
			}
			
			// Calc the delta to apply to the origins so the alignment is respected
			switch(_alignment){
				case NSRightTextAlignment:
					alignmentDelta=totalWidth-totalUsedWidth;
					break;
					
				case NSCenterTextAlignment:
					alignmentDelta=(totalWidth-totalUsedWidth)/2;
					break;
					
				case NSJustifiedTextAlignment: 
					if (!endOfString && !endOfLine) {
						int blankCount = 0;
						// Find the number of fragments ending with a ' '
						for(i=1;i<count;i++){
							NSRange range=[_glyphRangesInLine rangeAtIndex:i];
							if(!NSLocationInRange(range.location,_glyphCacheRange))
								loadGlyphAndCharacterCacheForLocation(self,range.location-1);
							
							int character=_characterCache[range.location-1-_glyphCacheRange.location];
							if (character==' '){
								blankCount++;
							}
						}
						if (blankCount) {
							alignmentDelta=(totalWidth-totalUsedWidth)/blankCount;
						}
					}
					break;
					
				default:
					break;
			}
		}
		
		int blankCount = 0;
		for(i=0;i<count;i++){
			NSRange range=[_glyphRangesInLine rangeAtIndex:i];
			NSRect  backRect=[_layoutManager lineFragmentRectForGlyphAtIndex:range.location effectiveRange:NULL];
			NSRect  usedRect=[_layoutManager lineFragmentUsedRectForGlyphAtIndex:range.location effectiveRange:NULL];
			NSPoint location=[_layoutManager locationForGlyphAtIndex:range.location];
			
			usedRect.size.height=backRect.size.height=_scanRect.size.height;
			location.y+=_maxAscender;
			if (_alignment == NSJustifiedTextAlignment) {
				if (i > 0) {
					if(!NSLocationInRange(range.location,_glyphCacheRange))
						loadGlyphAndCharacterCacheForLocation(self,range.location-1);
					
					int character=_characterCache[range.location-1-_glyphCacheRange.location];
					if (character==' ') {
						// Add some more pixels from here
						blankCount++;
					}
					usedRect.origin.x+=alignmentDelta*blankCount;
					location.x+=alignmentDelta*blankCount;
					if(i+1==count) {
						// Adjust the last rect
						backRect.origin.x+=alignmentDelta*blankCount;
						backRect.size.width-=alignmentDelta*blankCount;
					}
				}
			} else {
				if(i==0) {
					// Grow the first rect to it contains the white space added for justification
					backRect.size.width+=alignmentDelta;
				}
				usedRect.origin.x+=alignmentDelta;
				location.x+=alignmentDelta;
				if(i+1==count) {
					// Adjust the last rect
					backRect.origin.x+=alignmentDelta;
					backRect.size.width-=alignmentDelta;
				}
			}
			if(i+1<count || !advanceScanRect || endOfString) {
				[_layoutManager setLineFragmentRect:usedRect forGlyphRange:range usedRect:usedRect];
			} else {
				// Last rect
				[_layoutManager setLineFragmentRect:backRect forGlyphRange:range usedRect:usedRect];
			}
			[_layoutManager setLocation:location forStartOfGlyphRange:range];
		}
		// Some cleaning after we're done with the current line
		[_glyphRangesInLine removeAllRanges];
		_wordWrapWidth=0;
		_wordWrapRange = NSMakeRange(0,0);
	}
	
	if(advanceScanRect){
		_lineRange.location=NSMaxRange(fragmentRange);
		_lineRange.length=0;
		_scanRect.origin.x=0;
		_scanRect.origin.y+=_scanRect.size.height;
		_scanRect.size.width=1e7; // That's what Cocoa is sending
		_scanRect.size.height=0;
		_maxAscender=0;
	} else {
		_scanRect.origin.x+=fragmentWidth;
		_scanRect.size.width=NSMaxX(_fullLineRect)-_scanRect.origin.x;
	}
}


-(void)layoutNextFragment {
	NSRect lineFragmentUsedRect;
	NSRect remainingRect;
	NSRect proposedRect = _scanRect;
	
	// FIXME: getLineFragmentRect: does actually more that it should do - part of its code (like filing the typesetter layout info) should really be moved to the layoutNextFragment
	// mehod
	[self getLineFragmentRect:&_scanRect usedRect:&lineFragmentUsedRect remainingRect:&remainingRect forStartingGlyphAtIndex:_nextGlyphLocation proposedRect:proposedRect lineSpacing:1 paragraphSpacingBefore:0 paragraphSpacingAfter:0];
}

-(void)fetchAttributes {
   NSFont  *nextFont;
   unsigned characterIndex=_nextGlyphLocation; // FIX
   NSGlyph  spaceGlyph;
   unichar  space=' ';

   _attributes=[_attributedString attributesAtIndex:characterIndex effectiveRange:&_attributesRange];
    _currentBidiLevel = 0;

    if (_bidiLevels) {
        // Let's process the line - that's mostly resolving blanks and check if we have a direction switch
        NSRange lineRange = [_string lineRangeForRange:_lineRange];
        NSRange range;
        range.location = _lineRange.location;
        range.length = NSMaxRange(lineRange) - range.location;
        
        unichar text[range.length];
        uint8_t levels[range.length];
        for (int i = 0; i < range.length; ++i) {
            levels[i] = _bidiLevels[range.location + i];
        }
        [_string getCharacters:text range:range];
        
        // Resolve the bidi level for the whitespace in this line [we should save the current bidi level at the start of the line and use it]
        NSBidiHelperProcessLine(_currentParagraphBidiLevel, NULL, text, levels, NO, range.length);
        
        // We'll create a new fragment everytime the bidi level switches direction
        _currentBidiLevel = levels[characterIndex - range.location];

        int max = MIN(NSMaxRange(range), NSMaxRange(_attributesRange));
        
        for (int i = characterIndex + 1; i < max; ++i) {
            if ((levels[i - range.location]&1) != (_currentBidiLevel&1)) {
                _attributesRange.length = i - _attributesRange.location;
                break;
            }
        }
    }
    _attributesGlyphRange=_attributesRange; // FIX

   nextFont=NSFontAttributeInDictionary(_attributes);
   if(_font!=nextFont){
    _previousGlyph=NSNullGlyph;
    _font=nextFont;
    _fontAscender=ceilf([_font ascender]);
    _fontDefaultLineHeight=ceilf([_font defaultLineHeightForFont]);
    _positionOfGlyph=(void *)[_font methodForSelector:@selector(positionOfGlyph:precededByGlyph:isNominal:)];

    [_font getGlyphs:&spaceGlyph forCharacters:&space length:1];
    _whitespaceAdvancement=[_font advancementForGlyph:spaceGlyph].width;
   }

   if((_currentParagraphStyle=[_attributes objectForKey:NSParagraphStyleAttributeName])==nil)
    _currentParagraphStyle=[NSParagraphStyle defaultParagraphStyle];
   _alignment=[_currentParagraphStyle alignment];
    _currentParagraphBidiLevel = 0;
    if (_bidiLevels) {
        NSRange paragraphRange = [_string paragraphRangeForRange:NSMakeRange(characterIndex, 0)];
        _currentParagraphBidiLevel = _bidiLevels[paragraphRange.location];
    }
    if (_alignment == NSNaturalTextAlignment) {
        _alignment = NSLeftTextAlignment;
        if (_currentParagraphBidiLevel & 1) {
            _alignment = NSRightTextAlignment;
        }
    }
   _lineBreakMode=[_currentParagraphStyle lineBreakMode];
}

-(void)layoutGlyphsInLayoutManager:(NSLayoutManager *)layoutManager
       startingAtGlyphIndex:(unsigned)glyphIndex
   maxNumberOfLineFragments:(unsigned)maxNumLines
             nextGlyphIndex:(unsigned *)nextGlyph {

	[layoutManager retain];
   [_layoutManager release];
	_layoutManager=layoutManager;
   _textContainers=[layoutManager textContainers];
   
   [self setAttributedString:[layoutManager textStorage]];
   
    NSUInteger length = [_attributedString length];
    _currentBidiLevel = 0;
    _currentParagraphBidiLevel = 0;
    [self _updateBidiLevelsForRange: NSMakeRange(0, length)];
    
   _nextGlyphLocation=0;
   _numberOfGlyphs=[_string length];
   _glyphCacheRange=NSMakeRange(0,0);
   _previousGlyph=NSNullGlyph;

	NSTextContainer *container = [[_textContainers objectAtIndex:0] retain];

   [_container release];
   _container=container;
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
   _scanRect.size.width=1e7; // That's what Cocoa is sending
   _scanRect.size.height=0;
   _maxAscender=0;
	_wordWrapWidth=0;
  while(_nextGlyphLocation<_numberOfGlyphs){

    if(!NSLocationInRange(_nextGlyphLocation,_attributesRange))
     [self fetchAttributes];

    _layoutNextFragment(self,NULL);
	   if (NSEqualRects(_scanRect, NSZeroRect)) {
		   break;
	   }
   }

   if(_font==nil){
    _font=NSFontAttributeInDictionary(nil);
    _fontAscender=ceilf([_font ascender]);
    _fontDefaultLineHeight=ceilf([_font defaultLineHeightForFont]);
    _positionOfGlyph=(void *)[_font methodForSelector:@selector(positionOfGlyph:precededByGlyph:isNominal:)];
   }

	if (((_paragraphBreak && _nextGlyphLocation>=_numberOfGlyphs) || _numberOfGlyphs == 0)) {
		NSRect remainingRect; // Ignored for now
		_scanRect.size.height=MAX(_scanRect.size.height,_fontDefaultLineHeight);
		_scanRect = [_container lineFragmentRectForProposedRect:_scanRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remainingRect];
		NSRect usedRect = _scanRect;
		usedRect.size.width = 10;
		[_layoutManager setExtraLineFragmentRect:_scanRect usedRect:usedRect textContainer:_container];
	} else {
		[_layoutManager setExtraLineFragmentRect:NSZeroRect	usedRect:NSZeroRect textContainer:_container];
	}
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

-(void)insertGlyphs:(const NSGlyph *)glyphs length:(unsigned)length forStartingGlyphAtIndex:(unsigned)glyphIndex characterIndex:(unsigned int)characterIndex
{
    NSUnimplementedMethod();
}

-(void)setIntAttribute:(int)intAttribute value:(int)value forGlyphAtIndex:(unsigned)glyphIndex;
{
    NSUnimplementedMethod();
}

-(unsigned)getGlyphsInRange:(NSRange)glyphRange glyphs:(NSGlyph *)glyphs characterIndexes:(unsigned *)characterIndexes glyphInscriptions:(NSGlyphInscription *)glyphInscriptions elasticBits:(BOOL *)elasticBits bidiLevels:(unsigned char *)bidiLevels
{
    unsigned result  = 0;
    if (glyphs) {
        result = [_layoutManager getGlyphs:glyphs range:glyphRange];
    }
    if (characterIndexes) {
        for (int i = 0; i < glyphRange.length; ++i) {
            characterIndexes[i] = glyphRange.location + i;
        }
    }
    if (glyphInscriptions) {
        // Not supported for now
        for (int i = 0; i < glyphRange.length; ++i) {
            glyphInscriptions[i] = 0;
        }
    }
    if (elasticBits) {
        // Not supported for now
        for (int i = 0; i < glyphRange.length; ++i) {
            elasticBits[i] = NO;
        }
    }
    if (bidiLevels) {
        for (int i = 0; i < glyphRange.length; ++i) {
            if (_bidiLevels) {
                bidiLevels[i] = _bidiLevels[glyphRange.location + i];
            } else {
                bidiLevels[i] = 0;
            }
        }
    }
    return result;
}


-(void)setBidiLevels:(const unsigned char *)bidiLevels forGlyphRange:(NSRange)glyphRange {
    // Check if we're all left-to-right - if so, we don't have to use any bidi level
    BOOL ltor = YES;
    if (_bidiLevels) {
        for (unsigned int i = 0; ltor && i < _bidiLevelsCapacity; ++i) {
            if (!NSLocationInRange(i, glyphRange)) {
                ltor = _bidiLevels[i] == 0;
            }
        }
    }
    if (ltor) {
        for (unsigned int i = 0; ltor && i < glyphRange.length; ++i) {
            ltor = bidiLevels[i] == 0;
        }
        if (ltor) {
            // Both the old data and the new one are Left-to-Right only - we don't need any bidilevel
            if (_bidiLevels) {
                NSZoneFree([self zone], _bidiLevels);
                _bidiLevels = NULL;
            }
            return;
        }
    }
    // Both ltor & ltor
    if (_bidiLevels == NULL) {
        _bidiLevelsCapacity = MAX([_attributedString length], 32);
        _bidiLevels = (uint8_t *)NSZoneMalloc([self zone], _bidiLevelsCapacity * sizeof(uint8_t));
        // Anything new is left-to-right by default
        bzero(_bidiLevels, _bidiLevelsCapacity);
    }
    if (_bidiLevelsCapacity < NSMaxRange(glyphRange)) {
        int newBidiLevelsCapacity = MAX(_bidiLevelsCapacity*2, NSMaxRange(glyphRange));
        _bidiLevels = (uint8_t *)NSZoneRealloc([self zone], _bidiLevels, newBidiLevelsCapacity * sizeof(uint8_t));
        // Anything new is left-to-right by default
        bzero(_bidiLevels + _bidiLevelsCapacity, newBidiLevelsCapacity - _bidiLevelsCapacity);
        _bidiLevelsCapacity = newBidiLevelsCapacity;
    }
    memcpy(_bidiLevels+glyphRange.location, bidiLevels, glyphRange.length * sizeof(uint8_t));
}

-(void)_updateBidiLevelsForRange:(NSRange)range
{
    if (NSBidiHelperBidiInfoAvailable()) {
        NSString *string = [[self attributedString] string];
        range = [string paragraphRangeForRange:range];
        if (range.length == 0) {
            return;
        }
        uint8_t *bidiLevels = malloc(range.length * sizeof(uint8_t));
        unichar *buffer = malloc(range.length * sizeof(unichar));
        [string getCharacters:buffer range:range];
        
        int level = -1;
        NSBidiHelperParagraph(&level, buffer, bidiLevels, range.length);
        free(buffer);
        
        [self setBidiLevels:bidiLevels forGlyphRange:range];   

        free(bidiLevels);
    }
}
@end
