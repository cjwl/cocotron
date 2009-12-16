/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "O2Context_builtin_gdi.h"
#import <CoreGraphics/O2GraphicsState.h>
#import "O2Surface_DIBSection.h"
#import "O2DeviceContext_gdi.h"
#import "O2Font_gdi.h"
#import <CoreGraphics/O2ColorSpace.h>
#import <CoreGraphics/O2Color.h>
#import <AppKit/Win32Font.h>

@implementation O2Context_builtin_gdi

static inline O2GState *currentState(O2Context *self){        
   return [self->_stateStack lastObject];
}

-initWithSurface:(O2Surface *)surface flipped:(BOOL)flipped {
   [super initWithSurface:surface flipped:flipped];
   if([[self surface] isKindOfClass:[O2Surface_DIBSection class]])
    _dc=[[(O2Surface_DIBSection *)[self surface] deviceContext] dc];
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

-(O2DeviceContext_gdi *)deviceContext {
   return [(O2Surface_DIBSection *)[self surface] deviceContext];
}

-(void)deviceClipReset {
   [super deviceClipReset];
   [[self deviceContext] clipReset];
}

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   [super deviceClipToNonZeroPath:path];

   O2GState *state=currentState(self);
   [[self deviceContext] clipToNonZeroPath:path withTransform:O2AffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)deviceClipToEvenOddPath:(O2Path *)path {
   [super deviceClipToEvenOddPath:path];

   O2GState *state=currentState(self);
   [[self deviceContext] clipToEvenOddPath:path withTransform:O2AffineTransformInvert(state->_userSpaceTransform) deviceTransform:state->_deviceSpaceTransform];
}

-(void)establishFontStateInDeviceIfDirty {
   O2GState *gState=currentState(self);
   
   if(gState->_fontIsDirty){
    [gState clearFontIsDirty];
    [_gdiFont release];
    _gdiFont=[(O2Font_gdi *)[gState font] createGDIFontSelectedInDC:_dc pointSize:[gState pointSize]];
   }
}

-(void)showGlyphs:(const O2Glyph *)glyphs count:(unsigned)count {
   O2AffineTransform transformToDevice=O2ContextGetUserSpaceToDeviceSpaceTransform(self);
   O2GState  *gState=currentState(self);
   O2AffineTransform Trm=O2AffineTransformConcat(gState->_textTransform,transformToDevice);
   NSPoint           point=O2PointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   [self establishFontStateInDeviceIfDirty];
   
   SetTextColor(_dc,COLORREFFromColor([self fillColor]));

   ExtTextOutW(_dc,lroundf(point.x),lroundf(point.y),ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);

   O2Font *font=[gState font];
   int     i,advances[count];
   O2Float unitsPerEm=O2FontGetUnitsPerEm(font);
   
   O2FontGetGlyphAdvances(font,glyphs,count,advances);
   
   O2Float total=0;
   
   for(i=0;i<count;i++)
    total+=advances[i];
    
   total=(total/O2FontGetUnitsPerEm(font))*gState->_pointSize;
      
   currentState(self)->_textTransform.tx+=total;
   currentState(self)->_textTransform.ty+=0;
}

@end
