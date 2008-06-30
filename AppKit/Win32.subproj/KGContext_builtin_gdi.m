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

-initWithSurface:(KGSurface *)surface {
   [super initWithSurface:surface];
   _dc=[[(KGSurface_DIBSection *)[self surface] deviceContext] dc];
   
   if(SetMapMode(_dc,MM_ANISOTROPIC)==0)
    NSLog(@"SetMapMode failed");
   //SetICMMode(_dc,ICM_ON); MSDN says only available on 2000, not NT.

   SetBkMode(_dc,TRANSPARENT);
   SetTextAlign(_dc,TA_BASELINE);

   _gdiFont=nil;
   return self;
}

-(KGDeviceContext_gdi *)deviceContext {
   return [(KGSurface_DIBSection *)[self surface] deviceContext];
}

static inline void CMYKAToRGBA(float *input,float *output){
   float white=1-input[3];
   
   output[0]=(input[0]>white)?0:white-input[0];
   output[1]=(input[1]>white)?0:white-input[1];
   output[2]=(input[2]>white)?0:white-input[2];
   output[3]=input[4];
}


static COLORREF gammaAdjustedRGBFromComponents(float r,float g,float b){
// lame gamma adjustment so that non-system colors appear similar to those on a Mac

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
    
   return RGB(r*255,g*255,b*255);
}

static COLORREF RGBFromColor(KGColor *color){
   KGColorSpace *colorSpace=[color colorSpace];
   float        *components=[color components];
   
   switch([colorSpace type]){

    case KGColorSpaceDeviceGray:
     return gammaAdjustedRGBFromComponents(components[0],components[0],components[0]);
     
    case KGColorSpaceDeviceRGB:
     return gammaAdjustedRGBFromComponents(components[0],components[1],components[2]);
     
    case KGColorSpaceDeviceCMYK:{
      float rgba[4];
      
      CMYKAToRGBA(components,rgba);
      return gammaAdjustedRGBFromComponents(rgba[0],rgba[1],rgba[2]);
     }
     break;
     
     case KGColorSpacePlatformRGB:
     return RGB(components[0]*255,components[1]*255,components[2]*255);
          
    default:
     NSLog(@"GDI context can't translate from colorspace %@",colorSpace);
     return RGB(0,0,0);
   }
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   CGAffineTransform transformToDevice=[self userSpaceToDeviceSpaceTransform];
   CGAffineTransform Trm=CGAffineTransformConcat([self currentState]->_textTransform,transformToDevice);
   NSPoint           point=CGPointApplyAffineTransform(NSMakePoint(0,0),Trm);
   
   SetTextColor(_dc,RGBFromColor([self fillColor]));
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
   if([other respondsToSelector:@selector(deviceContext)])
    return;
   
   CGAffineTransform ctm=[self userSpaceToDeviceSpaceTransform];
         
   KGDeviceContext_gdi *deviceContext=[(KGContext_builtin_gdi *)other deviceContext];

   [self drawDeviceContext:deviceContext inRect:rect ctm:ctm];
}

@end
