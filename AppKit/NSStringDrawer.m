/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSView.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/CGContext.h>

static NSSize largeSize={1000000,1000000};

@implementation NSStringDrawer

NSStringDrawer *NSCurrentStringDrawer() {
   return NSThreadSharedInstance(@"NSStringDrawer");
}

-init {
   return [self initWithSize:largeSize];
}

-initWithSize:(NSSize)size {
   _textStorage=[NSTextStorage new];
   _layoutManager=[NSLayoutManager new];
   _textContainer=[[NSTextContainer alloc] initWithContainerSize:size];
   [_textStorage addLayoutManager:_layoutManager];
   [_layoutManager addTextContainer:_textContainer];
   return self;
}

-(NSSize)sizeOfString:(NSString *)string withAttributes:(NSDictionary *)attributes {
   [_textContainer setContainerSize:largeSize];
   [_textStorage beginEditing];
   [_textStorage replaceCharactersInRange:NSMakeRange(0,[_textStorage length]) withString:string];
   [_textStorage setAttributes:attributes range:NSMakeRange(0,[_textStorage length])];
   [_textStorage endEditing];
   return [_layoutManager usedRectForTextContainer:_textContainer].size;
}

-(NSPoint)lockFocusToPoint:(NSPoint)point height:(float)height isFlipped:(BOOL *)isFlipped {

   if((*isFlipped=[[NSView focusView] isFlipped]))
    return point;
   else {
    CGContext        *context=NSCurrentGraphicsPort();
    CGAffineTransform translate=CGAffineTransformMakeTranslation(point.x,point.y);
    CGAffineTransform flip={1,0,0,-1,0,height};

    CGContextSaveGState(context);
    CGContextConcatCTM(context,CGAffineTransformConcat(translate,flip));
    return NSMakePoint(0,0);
   }
}

-(NSPoint)lockFocusToRect:(NSRect)rect isFlipped:(BOOL *)isFlipped {
   if((*isFlipped=[[NSView focusView] isFlipped]))
    return rect.origin;
   else {
    CGContext        *context=NSCurrentGraphicsPort();
    CGAffineTransform translate=CGAffineTransformMakeTranslation(NSMinX(rect),NSMinY(rect));
    CGAffineTransform flip={1,0,0,-1,0,rect.size.height};

    CGContextSaveGState(context);
    CGContextConcatCTM(context,CGAffineTransformConcat(translate,flip));
    return NSMakePoint(0,0);
   }
}

-(void)unlockFocusIsFlipped:(BOOL)isFlipped {
   if(!isFlipped)
    CGContextRestoreGState(NSCurrentGraphicsPort());
}

-(void)drawString:(NSString *)string withAttributes:(NSDictionary *)attributes inRect:(NSRect)rect {
   BOOL    isFlipped;
   NSRange glyphRange;
   NSPoint origin;

   [_textContainer setContainerSize:rect.size];
   [_textStorage beginEditing];
   [_textStorage replaceCharactersInRange:NSMakeRange(0,[_textStorage length]) withString:string];
   [_textStorage setAttributes:attributes range:NSMakeRange(0,[_textStorage length])];
   [_textStorage endEditing];

   glyphRange=[_layoutManager glyphRangeForTextContainer:_textContainer];
   origin=[self lockFocusToRect:rect isFlipped:&isFlipped];
   [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
   [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
   [self unlockFocusIsFlipped:isFlipped];
}

-(void)drawString:(NSString *)string withAttributes:(NSDictionary *)attributes atPoint:(NSPoint)point {
   BOOL    isFlipped;
   NSRange glyphRange;
   NSPoint origin;

   [_textContainer setContainerSize:largeSize];
   [_textStorage beginEditing];
   [_textStorage replaceCharactersInRange:NSMakeRange(0,[_textStorage length]) withString:string];
   [_textStorage setAttributes:attributes range:NSMakeRange(0,[_textStorage length])];
   [_textStorage endEditing];

   glyphRange=[_layoutManager glyphRangeForTextContainer:_textContainer];
   origin=[self lockFocusToPoint:point height:[_layoutManager usedRectForTextContainer:_textContainer].size.height isFlipped:&isFlipped];
   [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
   [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
   [self unlockFocusIsFlipped:isFlipped];
}

-(NSSize)sizeOfAttributedString:(NSAttributedString *)astring {
   [_textContainer setContainerSize:largeSize];
   [_textStorage setAttributedString:astring];
   return [_layoutManager usedRectForTextContainer:_textContainer].size;
}

-(void)drawAttributedString:(NSAttributedString *)astring inRect:(NSRect)rect {
   BOOL    isFlipped;
   NSRange glyphRange;
   NSPoint origin;

   [_textContainer setContainerSize:rect.size];
   [_textStorage setAttributedString:astring];

   glyphRange=[_layoutManager glyphRangeForTextContainer:_textContainer];
   origin=[self lockFocusToRect:rect isFlipped:&isFlipped];
   [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
   [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
   [self unlockFocusIsFlipped:isFlipped];
}

-(void)drawAttributedString:(NSAttributedString *)astring atPoint:(NSPoint)point {
   BOOL    isFlipped;
   NSRange glyphRange;
   NSPoint origin;

   [_textContainer setContainerSize:largeSize];
   [_textStorage setAttributedString:astring];

   glyphRange=[_layoutManager glyphRangeForTextContainer:_textContainer];
   origin=[self lockFocusToPoint:point height:[_layoutManager usedRectForTextContainer:_textContainer].size.height isFlipped:&isFlipped];
   [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
   [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
   [self unlockFocusIsFlipped:isFlipped];
}

@end

@implementation NSString(NSStringDrawer)

-(void)_clipAndDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
   CGContext *graphicsPort=NSCurrentGraphicsPort();

   CGContextSaveGState(graphicsPort);
   CGContextClipToRect(graphicsPort,rect);
   [NSCurrentStringDrawer() drawString:self withAttributes:attributes inRect:rect];
   CGContextRestoreGState(graphicsPort);
}

@end

@implementation NSAttributedString(NSStringDrawer)

-(void)_clipAndDrawInRect:(NSRect)rect {
   CGContext *graphicsPort=NSCurrentGraphicsPort();

   CGContextSaveGState(graphicsPort);
   CGContextClipToRect(graphicsPort,rect);
   [NSCurrentStringDrawer() drawAttributedString:self inRect:rect];
   CGContextRestoreGState(graphicsPort);
}

@end
