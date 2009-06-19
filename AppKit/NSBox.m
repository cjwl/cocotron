/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBox.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSCell.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSRaise.h>

@implementation NSBox

-(void)encodeWithCoder:(NSCoder *)coder {
   [super encodeWithCoder:coder];
   [coder encodeInt:_borderType forKey:@"NSBox borderType"];
   [coder encodeInt:_titlePosition forKey:@"NSBox titlePosition"];
   [coder encodeSize:_contentViewMargins forKey:@"NSBox contentViewMargins"];
   [coder encodeObject:_titleCell forKey:@"NSBox titleCell"];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
    _borderType=[keyed decodeIntForKey:@"NSBorderType"];
    _titlePosition=[keyed decodeIntForKey:@"NSTitlePosition"];
    _contentViewMargins=[keyed decodeSizeForKey:@"NSOffsets"];
    _titleCell=[[keyed decodeObjectForKey:@"NSTitleCell"] retain];
    [[_subviews lastObject] setAutoresizingMask: NSViewWidthSizable| NSViewHeightSizable];
    [[_subviews lastObject] setAutoresizesSubviews:YES];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }
   return self;
}

-(void)dealloc {
   [_titleCell release];
   [super dealloc];
}

-(NSBoxType)boxType {
   return _boxType;
}

-(NSBorderType)borderType {
   return _borderType;
}

-(NSString *)title {
   return [_titleCell stringValue];
}

-(NSFont *)titleFont {
   return [_titleCell font];
}

-contentView {
   return [[self subviews] lastObject];
}

-(NSSize)contentViewMargins {
   return _contentViewMargins;
}

-(NSTitlePosition)titlePosition {
   return _titlePosition;
}

-(void)setBoxType:(NSBoxType)value {
   _boxType=value;
   [self setNeedsDisplay:YES];
}

-(void)setBorderType:(NSBorderType)value {
   _borderType=value;
   [self setNeedsDisplay:YES];
}

-(void)setTitle:(NSString *)title {
   [_titleCell setStringValue:title];
   [self setNeedsDisplay:YES];
}

-(void)setTitleFont:(NSFont *)font {
   [_titleCell setFont:font];
}

-(void)setContentView:(NSView *)view {
   if(![[self subviews] containsObject:view]){
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // FIX, adjust size
    [self addSubview:view];
   }
}

-(void)setContentViewMargins:(NSSize)value {
   _contentViewMargins=value;
   [self setNeedsDisplay:YES];
}

-(void)setTitlePosition:(NSTitlePosition)value {
   _titlePosition=value;
   [self setNeedsDisplay:YES];
}

-(void)setTitleWithMnemonic:(NSString *)value {
   NSUnimplementedMethod();
}

-(NSAttributedString *)_attributedTitle {
   NSMutableDictionary *attributes=[NSMutableDictionary dictionary];
   NSMutableParagraphStyle *paraStyle=[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
   NSFont              *font=[_titleCell font];

   if(font!=nil)
    [attributes setObject:font forKey:NSFontAttributeName];

   [paraStyle setLineBreakMode:NSLineBreakByClipping];
   [paraStyle setAlignment:NSLeftTextAlignment];
   [attributes setObject:paraStyle forKey:NSParagraphStyleAttributeName];

   [attributes setObject:[NSColor controlTextColor]
                  forKey: NSForegroundColorAttributeName];

   [attributes setObject:[NSColor windowBackgroundColor]
                  forKey:NSBackgroundColorAttributeName];

   return [[[NSAttributedString alloc] initWithString:[_titleCell stringValue] attributes:attributes] autorelease];
}

#define TEXTGAP 4

-(NSRect)titleRect {
   NSAttributedString *title=[self _attributedTitle];
   NSSize              size=[title size];
   NSRect              bounds=[self bounds];
   NSRect              result=NSZeroRect;
   
   result.origin.x=10+TEXTGAP;
   result.size.height=ceil(size.height);
   result.size.width=ceil(size.width);

   switch(_titlePosition){

    case NSNoTitle:
     break;

    case NSAboveTop:
     result.origin.y=bounds.size.height-result.size.height;
     break;

    case NSAtTop:
     result.origin.y=bounds.size.height-result.size.height;
     break;

    case NSBelowTop:
     result.origin.y=bounds.size.height-(result.size.height+TEXTGAP);
     break;

    case NSAboveBottom:
     result.origin.y=TEXTGAP;
     break;

    case NSAtBottom:
     break;

    case NSBelowBottom:
     result.origin.y=0;
     break;
   }

   return result;
}

-(NSRect)borderRect {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-titleCell {
   return _titleCell;
}

-(void)setFrameFromContentFrame:(NSRect)content {
// FIX, adjust content frame size to accomodate border/title
   [self setFrame:content];
}

-(void)sizeToFit {
   NSUnimplementedMethod();
}

-(BOOL)isOpaque {
   return YES;
}


-(void)drawRect:(NSRect)rect {
   NSAttributedString *title=[self _attributedTitle];
   NSRect              grooveRect=_bounds;
   NSRect              titleRect=[self titleRect];
   BOOL                drawTitle=YES;

   switch(_titlePosition){

    case NSNoTitle:
     drawTitle=NO;
     break;

    case NSAboveTop:
     grooveRect.size.height-=titleRect.size.height+TEXTGAP;
     break;

    case NSAtTop:
     grooveRect.size.height-=floor(titleRect.size.height/2);
     break;

    case NSBelowTop:
     break;

    case NSAboveBottom:
     break;

    case NSAtBottom:
     grooveRect.origin.y+=floor(titleRect.size.height/2);
     grooveRect.size.height-=floor(titleRect.size.height/2);
     break;

    case NSBelowBottom:
     grooveRect.origin.y+=titleRect.size.height+TEXTGAP;
     grooveRect.size.height-=titleRect.size.height+TEXTGAP;
     break;
   }

   [[NSColor controlColor] setFill];
   NSRectFill(rect);

   switch(_borderType){
    case NSNoBorder:
     break;

    case NSLineBorder:
     [[self graphicsStyle] drawBoxWithLineInRect:grooveRect];
     break;

    case NSBezelBorder:
     [[self graphicsStyle] drawBoxWithBezelInRect:grooveRect clipRect:rect];
     break;

    case NSGrooveBorder:
     [[self graphicsStyle] drawBoxWithGrooveInRect:grooveRect clipRect:rect];
     break;
   }

   if(drawTitle){
    [[NSColor windowBackgroundColor] setFill];
    titleRect.origin.x-=TEXTGAP;
    titleRect.size.width+=TEXTGAP*2;
    NSRectFill(titleRect);
    titleRect.origin.x+=TEXTGAP;
    titleRect.size.width-=TEXTGAP*2;

    [title _clipAndDrawInRect:titleRect];
   }
}

@end
