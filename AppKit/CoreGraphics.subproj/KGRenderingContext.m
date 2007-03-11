/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/KGRenderingContext.h>

@implementation KGRenderingContext

-(NSSize)size {
  return NSZeroSize;
}

-(KGContext *)graphicsContextWithSize:(NSSize)size {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)beginPage {
   NSInvalidAbstractInvocation();
}

-(void)endPage {
   NSInvalidAbstractInvocation();
}

-(void)beginDocument {
   NSInvalidAbstractInvocation();
}

-(void)endDocument {
   NSInvalidAbstractInvocation();
}

-(void)scalePage:(float)scalex:(float)scaley {
   NSInvalidAbstractInvocation();
}

-(void)selectFontWithName:(const char *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
   NSInvalidAbstractInvocation();
}

-(id)saveCopyOfDeviceState {
   NSInvalidAbstractInvocation();
}

-(void)restoreDeviceState:(id)state {
   NSInvalidAbstractInvocation();
}

-(void)clipInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)rect count:(unsigned)count {
   NSInvalidAbstractInvocation();
}

-(void)fillInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)rects count:(unsigned)count color:(KGColor *)color {
   NSInvalidAbstractInvocation();
}

-(void)strokeInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect width:(float)width color:(KGColor *)color {
   NSInvalidAbstractInvocation();
}

-(void)copyBitsInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect toPoint:(NSPoint)point {
   NSInvalidAbstractInvocation();
}

-(void)showInUserSpace:(CGAffineTransform)ctm text:(const char *)text count:(unsigned)count atPoint:(float)x:(float)y color:(KGColor *)color {
   NSInvalidAbstractInvocation();
}

-(void)showInUserSpace:(CGAffineTransform)ctm glyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y color:(KGColor *)color {
   NSInvalidAbstractInvocation();
}

-(void)drawPathInDeviceSpace:(KGPath *)path drawingMode:(int)mode ctm:(CGAffineTransform)ctm lineWidth:(float)lineWidth fillColor:(KGColor *)fillColor strokeColor:(KGColor *)strokeColor {
   NSInvalidAbstractInvocation();
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect ctm:(CGAffineTransform)ctm fraction:(float)fraction {
   NSInvalidAbstractInvocation();
}

@end
