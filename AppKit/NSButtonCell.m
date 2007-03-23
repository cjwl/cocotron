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
#import <AppKit/NSInterfaceGraphics.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSButtonImageSource.h>

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
        
    switch(flags2&0x37){
     case 1: _bezelStyle=NSRoundedBezelStyle; break;
     case 2: _bezelStyle=NSRegularSquareBezelStyle; break;
     case 3: _bezelStyle=NSThickSquareBezelStyle; break;
     case 4: _bezelStyle=NSThickerSquareBezelStyle; break;
     case 5: _bezelStyle=NSDisclosureBezelStyle; break;
     case 6: _bezelStyle=NSShadowlessSquareBezelStyle; break;
     case 7: _bezelStyle=NSCircularBezelStyle; break;

     case 32: _bezelStyle=NSTexturedSquareBezelStyle; break;
     case 33: _bezelStyle=NSHelpButtonBezelStyle; break;
     case 34: _bezelStyle=NSSmallSquareBezelStyle; break;
     case 35: _bezelStyle=NSTexturedRoundedBezelStyle; break;
     case 36: _bezelStyle=NSRoundRectBezelStyle; break;
     case 37: _bezelStyle=NSRecessedBezelStyle; break;
     //case 38: _bezelStyle=NSRoundedDisclosureBezelStyle; break; 38 not possible, 31?
     default: _bezelStyle=NSRoundedBezelStyle; break;
    }
        
    _isTransparent=(flags&0x00008000)?YES:NO;
    _imageDimsWhenDisabled=(flags&0x00002000)?NO:YES;
    
    check=[keyed decodeObjectForKey:@"NSAlternateImage"];
    if([check isKindOfClass:[NSImage class]])
     _alternateImage=[check retain];
    else if([check isKindOfClass:[NSButtonImageSource class]]){
     [_image release];
     _image=[[check normalImage] retain];
     _alternateImage=[[check alternateImage] retain];
    }
    
    _keyEquivalent=[[keyed decodeObjectForKey:@"NSKeyEquivalent"] retain];
    _keyEquivalentModifierMask=flags2>>8;
   }
   else {
    _title=[[coder decodeObjectForKey:@"NSButtonCell title"] retain];
    _alternateTitle=[[coder decodeObjectForKey:@"NSButtonCell alternateTitle"] retain];
    _imagePosition=[coder decodeIntForKey:@"NSButtonCell imagePosition"];
    _highlightsBy=[coder decodeIntForKey:@"NSButtonCell highlightsBy"];
    _showsStateBy=[coder decodeIntForKey:@"NSButtonCell showsStateBy"];
    _isTransparent=[coder decodeBoolForKey:@"NSButtonCell transparent"];
    _imageDimsWhenDisabled=[coder decodeBoolForKey:@"NSButtonCell imageDimsWhenDisabled"];
    _alternateImage=[[coder decodeObjectForKey:@"NSButtonCell alternateImage"] retain];
    _keyEquivalent=[[coder decodeObjectForKey:@"NSButtonCell keyEquivalent"] retain];
    _keyEquivalentModifierMask=[coder decodeIntForKey:@"NSButtonCell keyEquivalentModifierMask"];
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
   if((([self highlightsBy]&NSContentsCellMask) && [self isHighlighted]) ||
      (([self showsStateBy]&NSContentsCellMask) && [self state]))
    return [self alternateImage];

   return [self image];
}

-(BOOL)isVisuallyHighlighted {
   return ((([self highlightsBy]&NSChangeGrayCellMask) && [self isHighlighted]) ||
           (([self showsStateBy]&NSChangeGrayCellMask) && [self state]));
}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
   NSAttributedString *title=[self titleForHighlight];
   NSImage            *image=[self imageForHighlight];
   NSSize              imageSize=(image==nil)?NSMakeSize(0,0):[image size];
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
    float dimFraction=[self imageDimsWhenDisabled]?0.5:1.0;

    [image compositeToPoint:imageOrigin operation:NSCompositeSourceOver fraction:[self isEnabled]?1.0:dimFraction];
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
   _controlView=control;

   if([self isTransparent])
    return;

   if ([[control window] defaultButtonCell] == self) {
       [[NSColor blackColor] set];
       NSRectFill(frame);
       frame = NSInsetRect(frame,1,1);
   }

   if([self isBordered]){
    if(([self highlightsBy]&NSPushInCellMask) && [self isHighlighted]){
     NSInterfaceDrawDepressedButton(frame,frame);
    }
    else {
     if([self isVisuallyHighlighted])
      NSInterfaceDrawHighlightedButton(frame,frame);
     else
      NSDrawButton(frame,frame);
    }

    frame=NSInsetRect(frame,2,2);
   }

   [self drawInteriorWithFrame:frame inView:control];
}

@end
