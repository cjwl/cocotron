/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSButtonImageSource.h>
#import <AppKit/NSPopUpButtonCell.h>
#import <AppKit/NSSound.h>

@implementation NSButtonCell

-(void)encodeWithCoder:(NSCoder *)coder {
   [super encodeWithCoder:coder];
   [coder encodeObject:_title forKey:@"NSButtonCell title"];
   [coder encodeObject:_alternateTitle forKey:@"NSButtonCell alternateTitle"];
   [coder encodeInt:_imagePosition forKey:@"NSButtonCell imagePosition"];
   [coder encodeInt:_highlightsBy forKey:@"NSButtonCell highlightsBy"];
   [coder encodeInt:_showsStateBy forKey:@"NSButtonCell showsStateBy"];
   [coder encodeBool:_isTransparent forKey:@"NSButtonCell transparent"];
   [coder encodeBool:_imageDimsWhenDisabled forKey:@"NSButtonCell imageDimsWhenDisabled"];
   [coder encodeObject:_alternateImage forKey:@"NSButtonCell alternateImage"];
   [coder encodeObject:_keyEquivalent forKey:@"NSButtonCell keyEquivalent"];
   [coder encodeInt:_keyEquivalentModifierMask forKey:@"NSButtonCell keyEquivalentModifierMask"];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned           flags=[keyed decodeIntForKey:@"NSButtonFlags"];
    unsigned           flags2=[keyed decodeIntForKey:@"NSButtonFlags2"];
    id                 check;
    
    _title=[[keyed decodeObjectForKey:@"NSContents"] retain];
    _alternateTitle=[[keyed decodeObjectForKey:@"NSAlternateContents"] retain];
    
    _imagePosition=NSNoImage;
    if((flags&0x00480000)==0x00400000)
     _imagePosition=NSImageOnly;
    else if((flags&0x00480000)==0x00480000)
     _imagePosition=NSImageOverlaps;
    else if((flags&0x00380000)==0x00380000)
     _imagePosition=NSImageLeft;
    else if((flags&0x00380000)==0x00280000)
     _imagePosition=NSImageRight;
    else if((flags&0x00380000)==0x00180000)
     _imagePosition=NSImageBelow;
    else if((flags&0x00380000)==0x00080000)
     _imagePosition=NSImageAbove;

    _highlightsBy=0;
    _showsStateBy=0;
    
    if(flags&0x80000000)
     _highlightsBy|=NSPushInCellMask;
    if(flags&0x40000000)
     _showsStateBy|=NSContentsCellMask;
    if(flags&0x20000000)
     _showsStateBy|=NSChangeBackgroundCellMask;
    if(flags&0x10000000)
     _showsStateBy|=NSChangeGrayCellMask;
    if(flags&0x08000000)
     _highlightsBy|=NSContentsCellMask;
    if(flags&0x04000000)
     _highlightsBy|=NSChangeBackgroundCellMask;
    if(flags&0x02000000)
     _highlightsBy|=NSChangeGrayCellMask;
    
    _isBordered=(flags&0x00800000)?YES:NO; // err, this flag is in NSCell too

    _bezelStyle=(flags2&0x7)|(flags2&0x20>>2);

    _isTransparent=(flags&0x00008000)?YES:NO;
    _imageDimsWhenDisabled=(flags&0x00002000)?NO:YES;
    
    _showsBorderOnlyWhileMouseInside=(flags2&0x8)?YES:NO;

    check=[keyed decodeObjectForKey:@"NSAlternateImage"];
    if([check isKindOfClass:[NSImage class]])
     _alternateImage=[check retain];
    else if([check isKindOfClass:[NSButtonImageSource class]]){
     [_image release];
     _image=[[check normalImage] retain];
     _alternateImage=[[check alternateImage] retain];
    }
    else
     _alternateImage=nil;

    _keyEquivalent=[[keyed decodeObjectForKey:@"NSKeyEquivalent"] retain];
    _keyEquivalentModifierMask=flags2>>8;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }
   return self;
}

-initTextCell:(NSString *)string {
   [super initTextCell:string];
   _alternateTitle=@"";
   _imagePosition=NSNoImage;
   _highlightsBy=NSPushInCellMask;
   _showsStateBy=0;
   _isTransparent=NO;
   _imageDimsWhenDisabled=NO;
   _alternateImage=nil;
   _keyEquivalent=@"";
   _keyEquivalentModifierMask=0;
   _showsBorderOnlyWhileMouseInside=NO;

   [self setBordered:YES];
   [self setBezeled:YES];
   [self setAlignment:NSCenterTextAlignment];

   return self;
}

-initImageCell:(NSImage *)image {
   [super initImageCell:image];
   _imagePosition=NSImageOnly;
   return self;
}

-(void)dealloc {
   [_alternateTitle release];
   [_alternateImage release];
   [_keyEquivalent release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   NSButtonCell *result=[super copyWithZone:zone];

   result->_alternateTitle =[_alternateTitle copy];
   result->_alternateImage=[_alternateImage retain];
   result->_keyEquivalent=[_keyEquivalent copy];

   return result;
}

-(BOOL)isTransparent {
   return _isTransparent;
}

-(NSString *)keyEquivalent {
   return _keyEquivalent;
}

-(NSCellImagePosition)imagePosition {
   return _imagePosition;
}

-(NSString *)title {
   return _title;
}

-(NSString *)alternateTitle {
   return _alternateTitle;
}

-(NSImage *)alternateImage {
   return _alternateImage;
}

-(NSAttributedString *)attributedTitle {
   NSMutableDictionary *attributes=[NSMutableDictionary dictionary];
   NSMutableParagraphStyle *paraStyle=[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
   NSFont              *font=[self font];

   if(font!=nil)
    [attributes setObject:font forKey:NSFontAttributeName];

   if(![self wraps])
    [paraStyle setLineBreakMode:NSLineBreakByClipping];
   [paraStyle setAlignment:_textAlignment];
   [attributes setObject:paraStyle forKey:NSParagraphStyleAttributeName];

   if([self isEnabled])
    [attributes setObject:[NSColor controlTextColor]
                   forKey:NSForegroundColorAttributeName];
   else
    [attributes setObject:[NSColor disabledControlTextColor]
                   forKey:NSForegroundColorAttributeName];

   return [[[NSAttributedString alloc] initWithString:[self title] attributes:attributes] autorelease];
}

-(NSAttributedString *)attributedAlternateTitle {
   NSMutableDictionary *attributes=[NSMutableDictionary dictionary];
   NSMutableParagraphStyle *paraStyle=[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
   NSFont              *font=[self font];

   if(font!=nil)
    [attributes setObject:font forKey:NSFontAttributeName];

   if(![self wraps])
    [paraStyle setLineBreakMode:NSLineBreakByClipping];
   [paraStyle setAlignment:_textAlignment];
   [attributes setObject:paraStyle forKey:NSParagraphStyleAttributeName];

   if([self isEnabled])
    [attributes setObject:[NSColor controlTextColor]
                   forKey:NSForegroundColorAttributeName];
   else
    [attributes setObject:[NSColor disabledControlTextColor]
                   forKey:NSForegroundColorAttributeName];


   return [[[NSAttributedString alloc] initWithString:[self alternateTitle] attributes:attributes] autorelease];
}

-(int)highlightsBy {
   return _highlightsBy;
}

-(int)showsStateBy {
   return _showsStateBy;
}

-(BOOL)imageDimsWhenDisabled {
   return _imageDimsWhenDisabled;
}

-(unsigned)keyEquivalentModifierMask {
   return _keyEquivalentModifierMask;
}

-(NSBezelStyle)bezelStyle {
   return _bezelStyle;
}

-(BOOL)showsBorderOnlyWhileMouseInside {
   return _showsBorderOnlyWhileMouseInside;
}

-(NSSound *)sound {
   return _sound;
}

-(int)state {
   return [self intValue];
}

-(void)setTransparent:(BOOL)flag {
   _isTransparent=flag;
}

-(void)setKeyEquivalent:(NSString *)keyEquivalent {
   keyEquivalent=[keyEquivalent copy];
   [_keyEquivalent release];
   _keyEquivalent=keyEquivalent;
}

-(void)setImagePosition:(NSCellImagePosition)position {
   _imagePosition=position;
}

-(void)setTitle:(NSString *)title {
   title=[title copy];
   [_title release];
   _title=title;
}

-(void)setAlternateTitle:(NSString *)title {
   title=[title copy];
   [_alternateTitle release];
   _alternateTitle=title;
}

-(void)setAlternateImage:(NSImage *)image {
   image=[image retain];
   [_alternateImage release];
   _alternateImage=image;
}

-(void)setAttributedTitle:(NSAttributedString *)title {
   NSUnimplementedMethod();
}

-(void)setAttributedAlternateTitle:(NSAttributedString *)title {
   NSUnimplementedMethod();
}

-(void)setHighlightsBy:(int)type {
   _highlightsBy=type;
}

-(void)setShowsStateBy:(int)type {
   _showsStateBy=type;
}

-(void)setImageDimsWhenDisabled:(BOOL)flag {
   _imageDimsWhenDisabled=flag;
}

-(void)setKeyEquivalentModifierMask:(unsigned)mask {
   _keyEquivalentModifierMask=mask;
}

-(void)setState:(int)value {
   [self setIntValue:value];
}

-(void)setNextState {
   [self setIntValue:[self nextState]];
}

-(void)setObjectValue:(id <NSCopying>)value {
   if ([(id)value isKindOfClass:[NSNumber class]])
      [super setState:[(NSNumber *)value intValue]];
   else
      [super setState:0];

   [_objectValue release];
   _objectValue = [[NSNumber numberWithInt:[super state]] retain];

   [(NSControl *)[self controlView] updateCell:self];
}

-(void)setBezelStyle:(NSBezelStyle)bezelStyle {
   _bezelStyle = bezelStyle;
}

-(void)setButtonType:(NSButtonType)buttonType {
   switch (buttonType)
   {
      case NSMomentaryLightButton:
         _highlightsBy = NSChangeBackgroundCellMask;
	      _showsStateBy = NSNoCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSMomentaryPushInButton:
	      _highlightsBy = NSPushInCellMask|NSChangeGrayCellMask;
	      _showsStateBy = NSNoCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSMomentaryChangeButton:
	      _highlightsBy = NSContentsCellMask;
	      _showsStateBy = NSNoCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSPushOnPushOffButton:
	      _highlightsBy = NSPushInCellMask|NSChangeGrayCellMask;
	      _showsStateBy = NSChangeBackgroundCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSOnOffButton:
	      _highlightsBy = NSChangeBackgroundCellMask;
	      _showsStateBy = NSChangeBackgroundCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSToggleButton:
	      _highlightsBy = NSPushInCellMask|NSContentsCellMask;
	      _showsStateBy = NSContentsCellMask;
         _imageDimsWhenDisabled = YES;
         break;

      case NSSwitchButton:
	      _highlightsBy = NSContentsCellMask;
	      _showsStateBy = NSContentsCellMask;
         _imagePosition = NSImageLeft;
         _imageDimsWhenDisabled = NO;
	      [self setImage:[NSImage imageNamed:@"NSSwitch"]];
	      [self setAlternateImage:[NSImage imageNamed:@"NSHighlightedSwitch"]];
	      [self setAlignment:NSLeftTextAlignment];
	      [self setBordered:NO];
	      [self setBezeled:NO];
         break;

      case NSRadioButton:
	      _highlightsBy = NSContentsCellMask;
	      _showsStateBy = NSContentsCellMask;
         _imagePosition = NSImageLeft;
         _imageDimsWhenDisabled = NO;
	      [self setImage:[NSImage imageNamed:@"NSRadioButton"]];
	      [self setAlternateImage:[NSImage imageNamed:@"NSHighlightedRadioButton"]];
	      [self setAlignment:NSLeftTextAlignment];
	      [self setBordered:NO];
	      [self setBezeled:NO];
         break;
   }

   [(NSControl *)[self controlView] updateCell:self];
}

-(void)setShowsBorderOnlyWhileMouseInside:(BOOL)show {
   _showsBorderOnlyWhileMouseInside=show;
}

-(void)setSound:(NSSound *)sound {
   sound=[sound retain];
   [_sound release];
   _sound=sound;
}

-(NSAttributedString *)titleForHighlight {
   if((([self highlightsBy]&NSContentsCellMask) && [self isHighlighted]) ||
      (([self showsStateBy]&NSContentsCellMask) && [self state])){
    NSAttributedString *result=[self attributedAlternateTitle];

    if([result length]>0)
     return result;
   }

   return [self attributedTitle];
}

-(NSImage *)imageForHighlight {
   if(_bezelStyle==NSDisclosureBezelStyle){
   
    if((([self highlightsBy]&NSContentsCellMask) && [self isHighlighted]))
     return [NSImage imageNamed:@"NSButtonCell_disclosure_highlighted"];
    else if([self state])
     return [NSImage imageNamed:@"NSButtonCell_disclosure_selected"];
    else
     return [NSImage imageNamed:@"NSButtonCell_disclosure_normal"];
     
    return nil;
   }
   else {
    if((([self highlightsBy]&NSContentsCellMask) && [self isHighlighted]) ||
       (([self showsStateBy]&NSContentsCellMask) && [self state]))
     return [self alternateImage];

    return [self image];
   }
}

-(BOOL)isVisuallyHighlighted {
   return ((([self highlightsBy]&NSChangeGrayCellMask) && [self isHighlighted]) ||
           (([self showsStateBy]&NSChangeGrayCellMask) && [self state]));
}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
   NSAttributedString *title=[self titleForHighlight];
   NSImage            *image=[self imageForHighlight];
   BOOL                enabled=[self isEnabled]?YES:![self imageDimsWhenDisabled];
   BOOL                mixed=([self state]==NSMixedState)?YES:NO;
   NSSize              imageSize=(image==nil)?NSMakeSize(0,0):[[controlView graphicsStyle] sizeOfButtonImage:image enabled:enabled mixed:mixed];
   NSPoint             imageOrigin=frame.origin;
   NSSize              titleSize=[title size];
   NSRect              titleRect=frame;
   BOOL                drawImage=YES,drawTitle=YES;

   if([self isTransparent])
    return;

   imageOrigin.x+=floor((frame.size.width-imageSize.width)/2);
   imageOrigin.y+=floor((frame.size.height-imageSize.height)/2);

   titleRect.origin.y+=floor((titleRect.size.height-titleSize.height)/2);
   titleRect.size.height=titleSize.height;

   switch([self imagePosition]){

    case NSNoImage:
     drawImage=NO;
     break;

    case NSImageOnly:
     drawTitle=NO;
     break;

    case NSImageLeft:
     imageOrigin.x=frame.origin.x;
     titleRect.origin.x+=imageSize.width+2;
     titleRect.size.width-=imageSize.width+2;
     break;

    case NSImageRight:
     imageOrigin.x=frame.origin.x+(frame.size.width-imageSize.width);
     titleRect.size.width-=(imageSize.width+2);
     break;

    case NSImageBelow:
     imageOrigin.y=frame.origin.y;
     titleRect.origin.y+=imageSize.height;
     break;

    case NSImageAbove:
     imageOrigin.y=frame.origin.y+(frame.size.height-imageSize.height);
     titleRect.origin.y-=imageSize.height;
     if(titleRect.origin.y<frame.origin.y)
      titleRect.origin.y=frame.origin.y;
     break;

    case NSImageOverlaps:
     break;
   }

   if(![self isBordered]){
    if([self isVisuallyHighlighted]){
     [[NSColor whiteColor] set];
     NSRectFill(frame);
    }
    else {
     [[NSColor controlColor] set];
     NSRectFill(frame);
    }
   }

   if([self isBordered]){
    if(([self highlightsBy]&NSPushInCellMask) && [self isHighlighted]){
     imageOrigin.x+=1;
     imageOrigin.y+=[controlView isFlipped]?1:-1;
     titleRect.origin.x+=1;
     titleRect.origin.y+=[controlView isFlipped]?1:-1;
    }
   }

   if(drawImage){
    NSRect rect=NSMakeRect(imageOrigin.x,imageOrigin.y,imageSize.width,imageSize.height);
    
    [[_controlView graphicsStyle] drawButtonImage:image inRect:rect enabled:enabled mixed:mixed];
   }

   if(drawTitle){
    BOOL drawDottedRect=NO;

    [title _clipAndDrawInRect:titleRect];

    if([[controlView window] firstResponder]==controlView){

     if([controlView isKindOfClass:[NSMatrix class]]){
      NSMatrix *matrix=(NSMatrix *)controlView;

      drawDottedRect=([matrix keyCell]==self)?YES:NO;
     }
     else if([controlView isKindOfClass:[NSControl class]]){
      NSControl *control=(NSControl *)controlView;

      drawDottedRect=([control selectedCell]==self)?YES:NO;
     }
    }

    if(drawDottedRect)
     NSDottedFrameRect(NSInsetRect(titleRect,1,1));
   }
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView *)control {
   BOOL defaulted;
   
   _controlView=control;

   if([self isTransparent])
    return;

   defaulted=([[control window] defaultButtonCell] == self);
   
/*
 Aqua Push Buttons actually have a frame much larger than told by IB to make room for shadows and whatnot
 So we have to compensate for this when drawing simpler buttons.
 There is probably a way to streamline this, make NSPopUpButtonCell draw itself for starters
 NSGraphicsStyle should probably do this adjustment too
 */
   if((_bezelStyle==NSRoundedBezelStyle) && (_highlightsBy&NSPushInCellMask) && (_highlightsBy&NSChangeGrayCellMask) && (_showsStateBy==NSNoCellMask)){
    if (![self isKindOfClass:[NSPopUpButtonCell class]] && _controlSize <= NSSmallControlSize) 
         { 
            frame.size.width  -= 10 - _controlSize*2; 
            frame.size.height -= 10 - _controlSize*2; 
            frame.origin.x    +=  5 - _controlSize; 
            frame.origin.y    += [control isFlipped] ? _controlSize*2 - 3 : 7 - _controlSize*2; 
         } 
   }
   
   if(_bezelStyle==NSDisclosureBezelStyle){
// FIX The background isn't getting erased during pressing ? shouldn't the view be doing this during tracking ?
    [[NSColor controlColor] set];
    NSRectFill(frame);
   }
   else if(![self isBordered])
    frame=[[_controlView graphicsStyle] drawUnborderedButtonInRect:frame defaulted:defaulted];
   else {
    if(([self highlightsBy]&NSPushInCellMask) && [self isHighlighted])
     [[_controlView graphicsStyle] drawPushButtonPressedInRect:frame];
    else if([self isVisuallyHighlighted])
     [[_controlView graphicsStyle] drawPushButtonHighlightedInRect:frame];
    else
     [[_controlView graphicsStyle] drawPushButtonNormalInRect:frame defaulted:defaulted];
         
    frame=NSInsetRect(frame,2,2);
   }

   [self drawInteriorWithFrame:frame inView:control];
}

-(void)performClick:sender {
   if([_controlView respondsToSelector:@selector(performClick:)])
    [_controlView performSelector:@selector(performClick:) withObject:sender];
}

@end
