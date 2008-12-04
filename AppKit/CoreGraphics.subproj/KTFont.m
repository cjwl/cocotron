/* Copyright (c) 2006-2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KTFont.h"
#import "KGExceptions.h"
#import <Foundation/NSArray.h>
#import "KGFont.h"

@implementation KTFont

-initWithFont:(KGFont *)font size:(CGFloat)size {
   _font=[font retain];
   _size=size;
   return self;
}

-(void)dealloc {
   [_font release];
   [super dealloc];
}

-(NSString *)name {
   return [_font fontName];
}

-(float)pointSize {
   return _size;
}

-(CGRect)boundingRect {
   KGInvalidAbstractInvocation();
   return CGRectZero;
}

-(float)ascender {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)descender {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)leading {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)stemV {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)stemH {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)underlineThickness {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)underlinePosition {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)italicAngle {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)xHeight {
   KGInvalidAbstractInvocation();
   return 0;
}

-(float)capHeight {
   KGInvalidAbstractInvocation();
   return 0;
}

-(unsigned)numberOfGlyphs {
   KGInvalidAbstractInvocation();
   return 0;
}

-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp {
   KGInvalidAbstractInvocation();
   return CGPointZero;
}

-(void)getGlyphs:(CGGlyph *)glyphs forCharacters:(const unichar *)characters length:(unsigned)length {
   KGInvalidAbstractInvocation();
}

-(void)getCharacters:(unichar *)characters forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length {
   KGInvalidAbstractInvocation();
}

// FIX, lame, this needs to do encoding properly
-(void)getBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length {
   KGInvalidAbstractInvocation();
}

// FIX, lame, this needs to do encoding properly
-(void)getGlyphs:(CGGlyph *)glyphs forBytes:(const unsigned char *)bytes length:(unsigned)length {
   KGInvalidAbstractInvocation();
}

-(void)getAdvancements:(CGSize *)advancements forGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   KGInvalidAbstractInvocation();
}

-(CGSize)advancementForNominalGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   KGInvalidAbstractInvocation();
   return CGSizeZero;
}

-(void)appendCubicOutlinesToPath:(KGMutablePath *)path glyphs:(CGGlyph *)glyphs length:(unsigned)length {
   KGInvalidAbstractInvocation();
}

@end
