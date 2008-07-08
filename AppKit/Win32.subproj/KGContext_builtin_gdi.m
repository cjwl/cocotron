/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KGContext_builtin_gdi.h"
#import <AppKit/KGGraphicsState.h>
#import "KGSurface_DIBSection.h"
#import "KGDeviceContext_gdi.h"
#import <AppKit/KGFont.h>
#import "../CoreGraphics.subproj/KGColorSpace.h"
#import "../CoreGraphics.subproj/KGColor.h"
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
   
   NSSize advancement=[[self currentFont] advancementForNominalGlyphs:glyphs count:count];
   
   [self currentState]->_textTransform.tx+=advancement.width;
   [self currentState]->_textTransform.ty+=advancement.height;
}

-(void)deviceSelectFontWithName:(NSString *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
   int height=(pointSize*GetDeviceCaps(_dc,LOGPIXELSY))/72.0;

   [_gdiFont release];
   _gdiFont=[[Win32Font alloc] initWithName:name size:NSMakeSize(0,height) antialias:antialias];
   SelectObject(_dc,[_gdiFont fontHandle]);
}

-(void)drawDeviceContext:(KGDeviceContext_gdi *)deviceContext inRect:(NSRect)rect ctm:(CGAffineTransform)ctm {
   rect.origin=CGPointApplyAffineTransform(rect.origin,ctm);

   if(transformIsFlipped(ctm))
    rect.origin.y-=rect.size.height;

   BitBlt(_dc,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,[deviceContext dc],0,0,SRCCOPY);
}

-(void)drawContext:(KGContext *)other inRect:(CGRect)rect {
   if(![other respondsToSelector:@selector(deviceContext)])
    return;
   
   CGAffineTransform ctm=[self userSpaceToDeviceSpaceTransform];
         
   KGDeviceContext_gdi *deviceContext=[(KGContext_builtin_gdi *)other deviceContext];

   [self drawDeviceContext:deviceContext inRect:rect ctm:ctm];
}

@end
