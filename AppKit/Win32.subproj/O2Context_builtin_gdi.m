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
   /* FIX: we need to also override initWithBytes:... and create an O2Surface_DIBSection for the pixel format.
      Right now we just ignore GDI stuff if we get a surface which can't handle it.
    */
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
   if(_dc==NULL)
    return nil;
    
   return [(O2Surface_DIBSection *)[self surface] deviceContext];
}

-(void)deviceClipReset {
   O2ContextDeviceClipReset_builtin(self);
   if(_dc!=NULL)
    O2DeviceContextClipReset_gdi(_dc);
}

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   O2ContextDeviceClipToNonZeroPath_builtin(self,path);

   O2GState *state=currentState(self);
   
   if(_dc!=NULL)
    O2DeviceContextClipToNonZeroPath_gdi(_dc,path,O2AffineTransformInvert(state->_userSpaceTransform),state->_deviceSpaceTransform);
}

-(void)deviceClipToEvenOddPath:(O2Path *)path {
   O2ContextDeviceClipToEvenOddPath_builtin(self,path);
   
   O2GState *state=currentState(self);
   if(_dc!=NULL)
    O2DeviceContextClipToEvenOddPath_gdi(_dc,path,O2AffineTransformInvert(state->_userSpaceTransform),state->_deviceSpaceTransform);
}

-(void)showGlyphs:(const O2Glyph *)glyphs count:(unsigned)count {
   O2GState  *gState=currentState(self);
   O2AffineTransform transformToDevice=gState->_deviceSpaceTransform;
   O2AffineTransform Trm=O2AffineTransformConcat(gState->_textTransform,transformToDevice);
   NSPoint           point=O2PointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   if(gState->_fontIsDirty){
    O2GStateClearFontIsDirty(gState);
    [_gdiFont release];
    _gdiFont=[(O2Font_gdi *)[gState font] createGDIFontSelectedInDC:_dc pointSize:O2GStatePointSize(gState)];
   }
   
   SetTextColor(_dc,COLORREFFromColor(O2ContextFillColor(self)));

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
