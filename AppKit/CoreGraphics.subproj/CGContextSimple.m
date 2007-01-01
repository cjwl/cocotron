/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/CGContextSimple.h>
#import <AppKit/CGGraphicsState.h>
#import <AppKit/CGRenderingContext.h>

@implementation CGContextSimple

-initWithRenderingContext:(CGRenderingContext *)renderingContext transform:(CGAffineTransform)deviceTransform clipRect:(NSRect)clipRect {
   _renderingContext=[renderingContext retain];
   _deviceTransform=deviceTransform;
   _clipRect=clipRect;
   _stateStack=[NSMutableArray new];
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [_stateStack release];
   [super dealloc];
}

static inline CGGraphicsState *currentState(CGContextSimple *self){
   return [self->_stateStack lastObject];
}

-(CGGraphicsState *)currentState {
   return currentState(self);
}

-(void)saveGState {
   CGGraphicsState *current=currentState(self),*next;

   [current save];
   next=[current copy];
   [_stateStack addObject:next];
   [next release];
}

-(void)restoreGState {
   [[_stateStack lastObject] abort];
   [_stateStack removeLastObject];
   [currentState(self) restore];
}

-(void)scaleCTM:(float)scalex:(float)scaley {
   [currentState(self) scaleCTM:scalex:scaley];
}

-(void)translateCTM:(float)tx:(float)ty {
   [currentState(self) translateCTM:tx:ty];
}

-(void)concatCTM:(CGAffineTransform)transform {
   [currentState(self) concatCTM:transform];
}

-(void)setLineWidth:(float)width {
   [currentState(self) setLineWidth:width];
}

-(void)beginPath {
   [currentState(self) beginPath];
}

-(void)moveToPoint:(float)x:(float)y {
   [currentState(self) moveToPoint:x:y];
}

-(void)addLineToPoint:(float)x:(float)y {
   [currentState(self) addLineToPoint:x:y];
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   [currentState(self) addCurveToPoint:cx1:cy1:cx2:cy2:x:y];
}

-(void)closePath {
   [currentState(self) closePath];
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   [currentState(self) addArc:x:y:radius:startRadian:endRadian:clockwise];
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   [currentState(self) addArcToPoint:x1:y1:x2:y2:radius];
}

-(void)fillPath {
   [currentState(self) fillPath];
}

-(void)strokePath {
   [currentState(self) strokePath];
}

-(void)setDeviceColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   [currentState(self) setDeviceColorRed:red green:green blue:blue alpha:alpha];
}

-(void)setDeviceColorWhite:(float)white alpha:(float)alpha {
   [self setDeviceColorRed:white green:white blue:white alpha:alpha];
}

-(void)setDeviceColorCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha {
   NSUnimplementedMethod();
}

-(void)setCalibratedColorRed:(float)r green:(float)g blue:(float)b alpha:(float)alpha {
// NeXT gamma is 2.2 I think, my PC card is probably 1.3. This should be
// assumed = PC card setting
// display = NeXT 2.2
// I think.

   const float assumedGamma=1.3;
   const float displayGamma=2.2;

   r=pow(r,assumedGamma/displayGamma);
   if(r>1.0)
    r=1.0;

   g=pow(g,assumedGamma/displayGamma);
   if(g>1.0)
    g=1.0;

   b=pow(b,assumedGamma/displayGamma);
   if(b>1.0)
    b=1.0;

   [self setDeviceColorRed:r green:g blue:b alpha:alpha];
}

-(void)setCalibratedColorWhite:(float)white alpha:(float)alpha {
   [self setCalibratedColorRed:white green:white blue:white alpha:alpha];
}

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize { 
   [currentState(self) selectFontWithName:name pointSize:pointSize];
}

-(void)setTextMatrix:(CGAffineTransform)transform {
   [currentState(self) setTextMatrix:transform];
}

-(CGAffineTransform)textMatrix {
   return [currentState(self) textMatrix];
}

-(void)moveto:(float)x:(float)y
         show:(const char *)cString:(int)length {
   [currentState(self) moveto:x:y ashow:cString:length:0:0];
}

-(void)moveto:(float)x:(float)y
        ashow:(const char *)cString:(int)length:(float)dx:(float)dy {
   [currentState(self) moveto:x:y ashow:cString:length:dx:dy];
}

-(void)showGlyphs:(const CGGlyph *)glyphs:(unsigned)numberOfGlyphs atPoint:(NSPoint)point {
   [currentState(self) showGlyphs:glyphs:numberOfGlyphs atPoint:point];
}

-(void)showGlyphs:(const CGGlyph *)glyphs advances:(const CGSize *)advances count:(unsigned)count {
   [currentState(self) showGlyphs:glyphs advances:advances count:count];
}


-(void)drawRGBAImageInRect:(NSRect)rect width:(int)width height:(int)height data:(unsigned int *)data fraction:(float)fraction {
   [currentState(self) drawRGBAImageInRect:rect width:width height:height data:data fraction:fraction];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState {
   [currentState(self) copyBitsInRect:rect toPoint:point];
}

-(void)fillRects:(const CGRect *)rects count:(unsigned)count {
   [currentState(self) fillRects:rects count:count];
}

-(void)strokeRect:(CGRect)strokeRect width:(float)width {
   [currentState(self) strokeRect:strokeRect width:width];
}

-(void)clipToRect:(NSRect)rect {
   [currentState(self) clipToRect:rect];
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   [currentState(self) clipToRects:rects count:count];
}

-(void)bitCopyToPoint:(NSPoint)dstOrigin renderingContext:(CGRenderingContext *)renderingContext fromPoint:(NSPoint)srcOrigin size:(NSSize)size {
   [currentState(self) bitCopyToPoint:dstOrigin renderingContext:renderingContext fromPoint:srcOrigin size:size];
}

// printing

-(void)beginPage:(const CGRect *)mediaBox {
   [_renderingContext beginPage];
}

-(void)endPage {
   [_renderingContext endPage];
}

-(void)beginDocument {
   [_renderingContext beginDocument];
}

-(void)scalePage:(float)scalex:(float)scaley {
   [_renderingContext scalePage:scalex:scaley];
}

-(void)endDocument {
   [_renderingContext endDocument];
}

@end
