/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSStringDrawer.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSObject+BindingSupport.h>
#import <AppKit/NSRaise.h>

@implementation NSTextFieldCell

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
    _drawsBackground=[keyed decodeBoolForKey:@"NSDrawsBackground"];
    _backgroundColor=[[keyed decodeObjectForKey:@"NSBackgroundColor"] retain];
    _textColor=[[keyed decodeObjectForKey:@"NSTextColor"] retain];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }

   return self;
}

-initTextCell:(NSString *)string {
  [super initTextCell:string];

  _isEditable=YES;
  _isSelectable=YES;
  _isBezeled=YES;

  return self;
}

-(void)dealloc {
   [_backgroundColor release];
   [_textColor release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
    NSTextFieldCell *cell = [super copyWithZone:zone];

    cell->_backgroundColor=[_backgroundColor retain];
    cell->_textColor=[_textColor retain];

    return cell;
}

-(NSCellType)type {
   return NSTextCellType;
}

-(NSColor *)backgroundColor {
   return _backgroundColor;
}

-(NSColor *)textColor {
   return _textColor;
}

-(BOOL)drawsBackground {
   return _drawsBackground;
}

-(void)setBackgroundColor:(NSColor *)color {
   color=[color retain];
   [_backgroundColor release];
   _backgroundColor=color; 
}

-(void)setTextColor:(NSColor *)color {
   color=[color retain];
   [_textColor release];
   _textColor=color; 
}

-(void)setDrawsBackground:(BOOL)flag {
   _drawsBackground=flag;
}

-(NSRect)titleRectForBounds:(NSRect)rect {
   if([self isBezeled])
    rect=NSInsetRect(rect,3,3);
   else if([self isBordered])
    rect=NSInsetRect(rect,2,2);
   else 
    rect=NSInsetRect(rect,2,0); 

   return rect;
}

-(NSRect)drawingRectForBounds:(NSRect)rect {
   return [self titleRectForBounds:rect];
}

-(NSAttributedString *)attributedStringValue {
   if([_objectValue isKindOfClass:[NSAttributedString class]]){
    if(_textColor==nil)
     return _objectValue;
    else {
     NSMutableAttributedString *result=[[_objectValue mutableCopy] autorelease];

     [result addAttribute:NSForegroundColorAttributeName value:_textColor range:NSMakeRange(0,[result length])];

     return result;
    }
   }
   else {
    NSMutableDictionary *attributes=[NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paraStyle=[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    NSFont              *font=[self font];

    if(font!=nil)
     [attributes setObject:font forKey:NSFontAttributeName];

    if([self isEnabled]){
     if(_textColor!=nil)
      [attributes setObject:_textColor
                     forKey:NSForegroundColorAttributeName];
    }
    else {
     [attributes setObject:[NSColor disabledControlTextColor]
                     forKey:NSForegroundColorAttributeName];
    }

#if 0
    if([self drawsBackground]/* && ![self isBezeled]*/){
     NSColor *color=(_backgroundColor==nil)?[NSColor controlColor]:_backgroundColor;
     [attributes setObject:color
                    forKey:NSBackgroundColorAttributeName];
    }
#endif

    [paraStyle setLineBreakMode:_lineBreakMode];
    [paraStyle setAlignment:_textAlignment];
    [attributes setObject:paraStyle forKey:NSParagraphStyleAttributeName];

    return [[[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes] autorelease];
   }
}

-(NSSize)cellSize 
{
	NSSize size = [[self attributedStringValue] size];
	
	if([self isBezeled])
	{
		size.width += 6;
		size.height += 6;
	}
	else if([self isBordered])
	{
		size.width += 4;
		size.height += 4;
	}
	else
	{
		size.width += 4;
	}
	return size;
}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control {
   [[self attributedStringValue] _clipAndDrawInRect:frame];
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView *)control {
   NSRect titleRect=[self titleRectForBounds:frame];
   NSRect backRect=titleRect;

   _controlView=control;

   if([self isBezeled]){
    [[control graphicsStyle] drawTextFieldBorderInRect:frame bezeledNotLine:YES];
    backRect=NSInsetRect(backRect,-1,-1);
   }
   else {
    if([self isBordered]){
     [[control graphicsStyle] drawTextFieldBorderInRect:frame bezeledNotLine:NO];
     backRect=NSInsetRect(backRect,-1,-1);
    }
   }

   if([self drawsBackground]){
    NSColor *color=(_backgroundColor==nil)?[NSColor controlColor]:_backgroundColor;

    [color setFill];
    NSRectFill(backRect);
   }

   [self drawInteriorWithFrame:titleRect inView:control];
}

-(id)_replacementKeyPathForBinding:(id)binding {
   if([binding isEqual:@"value"])
		return @"stringValue";
   return [super _replacementKeyPathForBinding:binding];
}

@end
