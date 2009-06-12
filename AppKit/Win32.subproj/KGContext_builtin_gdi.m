/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KGContext_builtin_gdi.h"
#import <AppKit/KGGraphicsState.h>
#import "KGSurface_DIBSection.h"
#import "KGDeviceContext_gdi.h"
#import "KTFont_gdi.h"
#import "../../CoreGraphics/KGColorSpace.h"
#import "../../CoreGraphics/KGColor.h"
#import <AppKit/Win32Font.h>

@implementation KGContext_builtin_gdi

static inline BOOL transformIsFlipped(CGAffineTransform matrix){
   return (matrix.d<0)?YES:NO;
}

-initWithSurface:(KGSurface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   _dc=[[(KGSurface_DIBSection *)[self surface] deviceContext] dc];
   _gdiFont=nil;
   return self;
}

-(void)dealloc {
   [_gdiFont release];
   [super dealloc];
}

-(HDC)dc {
   return _dc;
}

-(KGDeviceContext_gdi *)deviceContext {
   return [(KGSurface_DIBSection *)[self surface] deviceContext];
}

-(void)deviceClipReset {
   [super deviceClipReset];
   [[self deviceContext] clipReset];
}

-(void)deviceClipToNonZeroPath:(KGPath *)path {
   [super deviceClipToNonZeroPath:path];

   KGGraphicsState *state=[self currentState];
   [[self deviceContext] clipToNonZeroPath:path withTransform:CGAffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)deviceClipToEvenOddPath:(KGPath *)path {
   [super deviceClipToEvenOddPath:path];

   KGGraphicsState *state=[self currentState];
   [[self deviceContext] clipToEvenOddPath:path withTransform:CGAffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   CGAffineTransform transformToDevice=[self userSpaceToDeviceSpaceTransform];
   CGAffineTransform Trm=CGAffineTransformConcat([self currentState]->_textTransform,transformToDevice);
   NSPoint           point=CGPointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   SetTextColor(_dc,COLORREFFromColor([self fillColor]));
   ExtTextOutW(_dc,point.x,point.y,ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);
   
   KTFont_gdi *ktFont=[[self currentState] fontState];
   NSSize advancement=[ktFont advancementForNominalGlyphs:glyphs count:count];
   
   [self currentState]->_textTransform.tx+=advancement.width;
   [self currentState]->_textTransform.ty+=advancement.height;
}

-(void)showText:(const char *)text length:(unsigned)length {
   unichar unicode[length];
   CGGlyph glyphs[length];
   int     i;
   
// FIX, encoding
   for(i=0;i<length;i++)
    unicode[i]=text[i];
    
   [[[self currentState] fontState] getGlyphs:glyphs forCharacters:unicode length:length];
   [self showGlyphs:glyphs count:length];
}


-(void)establishFontStateInDevice {
   KTFont *font=[[self currentState] fontState];
   [_gdiFont release];
   _gdiFont=[[[self currentState] fontState] createGDIFontSelectedInDC:_dc];
}

-(void)establishFontState {
   KGGraphicsState *state=[self currentState];
   KTFont *fontState=[[KTFont_gdi alloc] initWithFont:[state font] size:[state pointSize]];

   [state setFontState:fontState];
   [fontState release];
   [self establishFontStateInDevice];
}

-(void)setFont:(KGFont *)font {
   [super setFont:font];
   [self establishFontState];
}

-(void)setFontSize:(float)size {
   [super setFontSize:size];
   [self establishFontState];
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding {
   [super selectFontWithName:name size:size encoding:encoding];
   [self establishFontState];
}

-(void)restoreGState {
   [super restoreGState];
   [self establishFontStateInDevice];
}

@end
