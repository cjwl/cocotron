/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
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
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSGraphicsStyle.h>

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

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    _borderType=[keyed decodeIntForKey:@"NSBorderType"];
    _titlePosition=[keyed decodeIntForKey:@"NSTitlePosition"];
    _contentViewMargins=[keyed decodeSizeForKey:@"NSOffsets"];
    _titleCell=[[keyed decodeObjectForKey:@"NSTitleCell"] retain];
    [[_subviews lastObject] setAutoresizingMask: NSViewWidthSizable| NSViewHeightSizable];
    [[_subviews lastObject] setAutoresizesSubviews:YES];
   }
   else {
    _borderType=[coder decodeIntForKey:@"NSBox borderType"];
    _titlePosition=[coder decodeIntForKey:@"NSBox titlePosition"];
    _contentViewMargins=[coder decodeSizeForKey:@"NSBox contentViewMargins"];
    _titleCell=[[coder decodeObjectForKey:@"NSBox titleCell"] retain];
   }
   return self;
}

-(void)dealloc {
   [_titleCell release];
   [super dealloc];
}

-contentView {
   return [[self subviews] lastObject];
}

-(void)setTitle:(NSString *)title {
   [_titleCell setStringValue:title];
   [self setNeedsDisplay:YES];
}

-(NSAttributedString *)attributedTitle {
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

-(BOOL)isOpaque {
   return YES;
}

-(void)drawRect:(NSRect)rect {
   NSAttributedString *title=[self attributedTitle];
   NSRect              grooveRect=_bounds;
   NSSize              titleSize=[title size];
   NSRect              titleRect;
   BOOL                drawTitle=YES;

   titleRect.origin.x=10+TEXTGAP;
   titleSize.height=ceil(titleSize.height);
   titleSize.width=ceil(titleSize.width);
   titleRect.size=titleSize;
   
   switch(_titlePosition){

    case NSNoTitle:
     drawTitle=NO;
     break;

    case NSAboveTop:
     titleRect.origin.y=_bounds.size.height-titleSize.height;
     grooveRect.size.height-=titleSize.height+TEXTGAP;
     break;

    case NSAtTop:
     titleRect.origin.y=_bounds.size.height-titleSize.height;
     grooveRect.size.height-=floor(titleSize.height/2);
     break;

    case NSBelowTop:
     titleRect.origin.y=_bounds.size.height-(titleSize.height+TEXTGAP);
     break;

    case NSAboveBottom:
     titleRect.origin.y=TEXTGAP;
     break;

    case NSAtBottom:
     grooveRect.origin.y+=floor(titleSize.height/2);
     grooveRect.size.height-=floor(titleSize.height/2);
     break;

    case NSBelowBottom:
     titleRect.origin.y=0;
     grooveRect.origin.y+=titleSize.height+TEXTGAP;
     grooveRect.size.height-=titleSize.height+TEXTGAP;
     break;
   }

   [[NSColor controlColor] set];
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
    [[NSColor windowBackgroundColor] set];
    titleRect.origin.x-=TEXTGAP;
    titleRect.size.width+=TEXTGAP*2;
    NSRectFill(titleRect);
    titleRect.origin.x+=TEXTGAP;
    titleRect.size.width-=TEXTGAP*2;

    [title _clipAndDrawInRect:titleRect];
   }
}


@end
