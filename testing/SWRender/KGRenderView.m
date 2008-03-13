/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRenderView.h"
#import "KGRender.h"


@implementation KGRenderView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   gState=&gStateX;
   gState->_shouldAntialias=YES;
   gState->_interpolationQuality=kCGInterpolationDefault;
   gState->_scalex=1;
   gState->_scaley=1;
   gState->_rotation=0;
   gState->_blendMode=kCGBlendModeNormal;
   gState->_shadowColor=[[NSColor blackColor] copy];
   gState->_shadowBlur=0;
   gState->_shadowOffset=NSMakeSize(10,10);
   gState->_lineWidth=1;
   gState->_lineCap=kCGLineCapButt;
   gState->_lineJoin=kCGLineJoinMiter;
   gState->_miterLimit=1;
   gState->_dashPhase=100;
   gState->_dashLengthsCount=0;
   gState->_dashLengths=NSZoneMalloc([self zone],sizeof(float)*4);
   _destinationColor=[[NSColor redColor] copy];
   _sourceColor=[[NSColor blueColor] copy];
   return self;
}

-(void)setOverlayImageRep:(NSBitmapImageRep *)imageRep {
  [_overlayRep release];
  _overlayRep=[imageRep retain];
}

-(void)setRender:(KGRender *)render {
   [_render autorelease];
   _render=[render retain];
   [_render setSize:[self bounds].size];
}

-(void)setDestinationColor:(NSColor *)color {
   [_destinationColor autorelease];
   _destinationColor=[color copy];
   [self setNeedsDisplay:YES];
}

-(void)setSourceColor:(NSColor *)color {
   [_sourceColor autorelease];
   _sourceColor=[color copy];
   [self setNeedsDisplay:YES];
}

-(void)setBlendMode:(CGBlendMode)blendMode {
   gState->_blendMode=blendMode;
   [self setNeedsDisplay:YES];
}

-(void)setShadowColor:(NSColor *)value {
   [gState->_shadowColor release];
   gState->_shadowColor=[value copy];
   [self setNeedsDisplay:YES];
}

-(void)setShadowBlur:(float)value {
   gState->_shadowBlur=value;
   [self setNeedsDisplay:YES];
}

-(void)setShadowOffsetX:(float)value {
   gState->_shadowOffset.width=value;
   [self setNeedsDisplay:YES];
}

-(void)setShadowOffsetY:(float)value {
   gState->_shadowOffset.height=value;
   [self setNeedsDisplay:YES];
}

-(void)setPathDrawingMode:(CGPathDrawingMode)pathDrawingMode {
   _pathDrawingMode=pathDrawingMode;
   [self setNeedsDisplay:YES];
}

-(void)setLineWidth:(float)width {
   gState->_lineWidth=width;
   [self setNeedsDisplay:YES];
}

-(void)setDashPhase:(float)value {
   gState->_dashPhase=value;
   [self setNeedsDisplay:YES];
}

-(void)setDashLength:(float)value {
   if(value<1)
    gState->_dashLengthsCount=0;
   else {
    int i;
    
    gState->_dashLengthsCount=4;
    for(i=0;i<4;i++)
     gState->_dashLengths[i]=value*(i+1);
   }
   [self setNeedsDisplay:YES];
}

-(void)setScaleX:(float)value {
   gState->_scalex=value;
   [self setNeedsDisplay:YES];
}

-(void)setScaleY:(float)value {
   gState->_scaley=value;
   [self setNeedsDisplay:YES];
}

-(void)setRotation:(float)value {
   gState->_rotation=value;
   [self setNeedsDisplay:YES];
}

-(void)setShouldAntialias:(BOOL)value {
   gState->_shouldAntialias=value;
   [self setNeedsDisplay:YES];
}

-(void)setInterpolationQuality:(CGInterpolationQuality)value {
   gState->_interpolationQuality=value;
   [self setNeedsDisplay:YES];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize {
   [super resizeWithOldSuperviewSize:oldSize];
   [_render setSize:[self bounds].size];
}

static CGColorRef cgColorFromColor(NSColor *color){
   NSColor *rgbColor=[color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
   float rgba[4];
   
   [rgbColor getComponents:rgba];
   return (CGColorRef)[(id)CGColorCreate(CGColorSpaceCreateDeviceRGB(),rgba) autorelease];
}

-(void)drawRect:(NSRect)rect {
   CGContextRef context=(CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
   float      blackComponents[4]={0,0,0,1};
   CGColorRef blackColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),blackComponents);
   CGColorRef redColor=cgColorFromColor(_destinationColor);
   CGColorRef blueColor=cgColorFromColor(_sourceColor);
   
   CGMutablePathRef  path1=CGPathCreateMutable();
   CGMutablePathRef  path2=CGPathCreateMutable();
   CGAffineTransform xform=CGAffineTransformMakeScale(1,2);
   
   [[NSColor whiteColor] set];
   NSRectFill([self bounds]);
   
   CGPathMoveToPoint(path1,NULL,0,0);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddCurveToPoint(path1,NULL,0,100,100,200,200,200);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddLineToPoint(path1,NULL,200,10);
   CGPathCloseSubpath(path1);

   CGPathAddPath(path2,&xform,path1);
   
   [_render clear];
  
   CGAffineTransform ctm=CGAffineTransformMakeScale( gState->_scalex,gState->_scaley);
   
   ctm=CGAffineTransformRotate(ctm,M_PI*gState->_rotation/180.0);
   
   [_render setShadowColor:cgColorFromColor(gState->_shadowColor)];
   [_render setShadowOffset:CGSizeMake(gState->_shadowOffset.width,gState->_shadowOffset.height)];
   [_render setShadowBlur:gState->_shadowBlur];
   
   [_render drawPath:path1 drawingMode:_pathDrawingMode blendMode:kCGBlendModeNormal
      interpolationQuality:kCGInterpolationDefault fillColor:redColor strokeColor:blackColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths transform:ctm antialias:gState->_shouldAntialias];
      
   [_render setShadowColor:NULL];

   [_render drawPath:path2 drawingMode:_pathDrawingMode blendMode:gState->_blendMode
      interpolationQuality:kCGInterpolationDefault fillColor:blueColor strokeColor:blackColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths transform:ctm antialias:gState->_shouldAntialias];
    
   [_render drawBitmapImageRep:_overlayRep antialias:YES interpolationQuality:gState->_interpolationQuality blendMode:gState->_blendMode fillColor:blackColor transform:ctm];
   
   [_render drawImageInContext:context];
}

@end
