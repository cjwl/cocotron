/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KGContext_builtin_gdi.h"
#import <CoreGraphics/KGGraphicsState.h>
#import "KGSurface_DIBSection.h"
#import "KGDeviceContext_gdi.h"
#import "KGFont_gdi.h"
#import <CoreGraphics/O2ColorSpace.h>
#import <CoreGraphics/O2Color.h>
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

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   [super deviceClipToNonZeroPath:path];

   KGGraphicsState *state=[self currentState];
   [[self deviceContext] clipToNonZeroPath:path withTransform:CGAffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)deviceClipToEvenOddPath:(O2Path *)path {
   [super deviceClipToEvenOddPath:path];

   KGGraphicsState *state=[self currentState];
   [[self deviceContext] clipToEvenOddPath:path withTransform:CGAffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   CGAffineTransform transformToDevice=[self userSpaceToDeviceSpaceTransform];
   KGGraphicsState  *gState=[self currentState];
   CGAffineTransform Trm=CGAffineTransformConcat(gState->_textTransform,transformToDevice);
   NSPoint           point=CGPointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   SetTextColor(_dc,COLORREFFromColor([self fillColor]));

   ExtTextOutW(_dc,lroundf(point.x),lroundf(point.y),ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);

   KGFont *font=[gState font];
   int     i,advances[count];
   CGFloat unitsPerEm=CGFontGetUnitsPerEm(font);
   
   O2FontGetGlyphAdvances(font,glyphs,count,advances);
   
   CGFloat total=0;
   
   for(i=0;i<count;i++)
    total+=advances[i];
    
   total=(total/CGFontGetUnitsPerEm(font))*gState->_pointSize;
      
   [self currentState]->_textTransform.tx+=total;
   [self currentState]->_textTransform.ty+=0;
}

-(void)showText:(const char *)text length:(unsigned)length {
   CGGlyph *encoding=[[self currentState] glyphTableForTextEncoding];
   CGGlyph  glyphs[length];
   int      i;
   
   for(i=0;i<length;i++)
    glyphs[i]=encoding[(uint8_t)text[i]];
    
   [self showGlyphs:glyphs count:length];
}

-(void)establishFontStateInDevice {
   KGGraphicsState *gState=[self currentState];
   [_gdiFont release];
   _gdiFont=[(KGFont_gdi *)[gState font] createGDIFontSelectedInDC:_dc pointSize:[gState pointSize]];
}

-(void)establishFontState {
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
