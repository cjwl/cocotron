/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRenderController.h"
#import "KGImageView.h"
#import "KGRender_cg.h"
#import "KGRender_baseline.h"

@implementation KGRenderController

static CGColorRef cgColorFromColor(NSColor *color){
   NSColor *rgbColor=[color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
   float rgba[4];
   
   [rgbColor getComponents:rgba];
   return (CGColorRef)[(id)CGColorCreate(CGColorSpaceCreateDeviceRGB(),rgba) autorelease];
}

-init {
   gState=&gStateX;
   gState->_shouldAntialias=YES;
   gState->_interpolationQuality=kCGInterpolationDefault;
   gState->_scalex=1;
   gState->_scaley=1;
   gState->_rotation=0;
   gState->_blendMode=kCGBlendModeNormal;
   gState->_shadowColor=cgColorFromColor([NSColor blackColor]);
   gState->_shadowBlur=0;
   gState->_shadowOffset=CGSizeMake(10,10);
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


-(CGAffineTransform)ctm {
   CGAffineTransform ctm=CGAffineTransformMakeTranslation(386/2,386/2);
   
   ctm=CGAffineTransformScale(ctm, gState->_scalex,gState->_scaley);
   
   return CGAffineTransformRotate(ctm,M_PI*gState->_rotation/180.0);
}

static void addSliceToPath(CGMutablePathRef path,float innerRadius,float outerRadius,float startAngle,float endAngle){
   CGPoint point;

   point=CGPointApplyAffineTransform(CGPointMake(outerRadius,0),CGAffineTransformMakeRotation(startAngle));
   CGPathMoveToPoint(path,NULL,point.x,point.y);
   CGPathAddArc(path,NULL,0,0,outerRadius,startAngle,endAngle,NO);
   point=CGPointApplyAffineTransform(CGPointMake(innerRadius,0),CGAffineTransformMakeRotation(endAngle));
   CGPathAddLineToPoint(path,NULL,point.x,point.y);
   CGPathAddArc(path,NULL,0,0,innerRadius,endAngle,startAngle,YES);
   CGPathCloseSubpath(path);
}

-(void)drawSampleInRender:(KGRender *)render {
   float      blackComponents[4]={0,0,0,1};
   CGColorRef blackColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),blackComponents);
   CGColorRef redColor=cgColorFromColor(_destinationColor);
   CGColorRef blueColor=cgColorFromColor(_sourceColor);
   
   CGMutablePathRef  path1=CGPathCreateMutable();
   CGMutablePathRef  path2=CGPathCreateMutable();
   CGAffineTransform xform=CGAffineTransformMakeScale(.5,.5);
#if 1   
   addSliceToPath(path1,50,100,M_PI*30/180.0,M_PI*330/180.0);

   addSliceToPath(path1,150,300,M_PI*0/180.0,M_PI*60/180.0);
   addSliceToPath(path1,150,300,M_PI*120/180.0,M_PI*180/180.0);
   addSliceToPath(path1,150,300,M_PI*240/180.0,M_PI*300/180.0);
#else      
   CGPathMoveToPoint(path1,NULL,0,0);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddCurveToPoint(path1,NULL,0,100,100,200,200,200);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddLineToPoint(path1,NULL,200,10);
   CGPathCloseSubpath(path1);
#endif

   CGPathAddPath(path2,&xform,path1);
   
   [render clear];
  
   CGAffineTransform ctm=[self ctm];
   
#if 0   
   [render setShadowColor:cgColorFromColor(gState->_shadowColor)];
   [render setShadowOffset:CGSizeMake(gState->_shadowOffset.width,gState->_shadowOffset.height)];
   [render setShadowBlur:gState->_shadowBlur];
#endif
#if 0   
   [render drawPath:path1 drawingMode:_pathDrawingMode blendMode:kCGBlendModeNormal
      interpolationQuality:kCGInterpolationDefault fillColor:redColor strokeColor:blackColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths transform:ctm antialias:gState->_shouldAntialias];
 #endif
      
   [render drawPath:path2 drawingMode:_pathDrawingMode blendMode:gState->_blendMode
      interpolationQuality:kCGInterpolationDefault fillColor:blueColor strokeColor:blackColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths transform:ctm antialias:gState->_shouldAntialias];
    
   CGAffineTransform t=CGAffineTransformMakeTranslation(-[_imageRep pixelsWide],-[_imageRep pixelsHigh]);
   ctm=CGAffineTransformConcat(t,ctm);
   ctm=CGAffineTransformScale(ctm,2,2);
   [render drawBitmapImageRep:_imageRep antialias:YES interpolationQuality:gState->_interpolationQuality blendMode:gState->_blendMode fillColor:blackColor transform:ctm];
}

-(void)drawStraightLinesInRender:(KGRender *)render {
   float      blackComponents[4]={0,0,0,1};
   CGColorRef blackColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),blackComponents);
   CGColorRef redColor=cgColorFromColor(_destinationColor);
    CGAffineTransform ctm=[self ctm];
  int               i,width=386,height=386;
   [render clear];

    CGMutablePathRef  path=CGPathCreateMutable();

   for(i=0;i<386;i+=10){
    
   CGPathMoveToPoint(path,NULL,i,0);
   CGPathAddLineToPoint(path,NULL,i,height);
   }
   
   for(i=0;i<386;i+=10){
   CGPathMoveToPoint(path,NULL,0,i);
   CGPathAddLineToPoint(path,NULL,width,i);
   }
   
   [render drawPath:path drawingMode:_pathDrawingMode blendMode:kCGBlendModeNormal
      interpolationQuality:kCGInterpolationDefault fillColor:redColor strokeColor:blackColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths transform:ctm antialias:gState->_shouldAntialias];
      
   CGPathRelease(path);
}

-(void)setNeedsDisplay {
   switch([_testPopUp selectedTag]){
    case 0:
     [self drawSampleInRender:_cgRender];
     [self drawSampleInRender:_kgRender];
     break;

    case 1:
     [self drawStraightLinesInRender:_cgRender];
     [self drawStraightLinesInRender:_kgRender];
     break;
   }
   
   [_cgView setImageRef:[_cgRender imageRef]];
   [_kgView setImageRef:[_kgRender imageRef]];
   [_diffView setImageRef:[_kgRender imageRefOfDifferences:_cgRender]];
}

-(void)awakeFromNib {
   _cgRender=[[KGRender_cg alloc] init];
   _kgRender=[[KGRender_baseline alloc] init] ;
   [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
   
   NSString         *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"overlay" ofType:@"png"];
   
  _imageRep=[[NSBitmapImageRep imageRepWithContentsOfFile:path] retain];
  [self setNeedsDisplay];
  
}

-(void)selectTest:sender {
   [self setNeedsDisplay];
}

-(void)setDestinationColor:(NSColor *)color {
   [_destinationColor autorelease];
   _destinationColor=[color copy];
}

-(void)setSourceColor:(NSColor *)color {
   [_sourceColor autorelease];
   _sourceColor=[color copy];
}

-(void)setBlendMode:(CGBlendMode)blendMode {
   gState->_blendMode=blendMode;
}

-(void)setShadowBlur:(float)value {
   gState->_shadowBlur=value;
}

-(void)setShadowOffsetX:(float)value {
   gState->_shadowOffset.width=value;
}

-(void)setShadowOffsetY:(float)value {
   gState->_shadowOffset.height=value;
}

-(void)setShadowColor:(CGColorRef)value {
   value=CGColorRetain(value);
   CGColorRelease(gState->_shadowColor);
   gState->_shadowColor=value;
}

-(void)setShadowOffset:(CGSize)value {
   gState->_shadowOffset=value;
}

-(void)setPathDrawingMode:(CGPathDrawingMode)pathDrawingMode {
   _pathDrawingMode=pathDrawingMode;
}

-(void)setLineWidth:(float)width {
   gState->_lineWidth=width;
}

-(void)setDashPhase:(float)value {
   gState->_dashPhase=value;
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
}

-(void)setScaleX:(float)value {
   gState->_scalex=value;
}

-(void)setScaleY:(float)value {
   gState->_scaley=value;
}

-(void)setRotation:(float)value {
   gState->_rotation=value;
}

-(void)setShouldAntialias:(BOOL)value {
   gState->_shouldAntialias=value;
}

-(void)setInterpolationQuality:(CGInterpolationQuality)value {
   gState->_interpolationQuality=value;
}


-(void)selectDestinationColor:sender {
   [self setDestinationColor:[sender color]];
   [self setNeedsDisplay];
}

-(void)setectSourceColor:sender {
   [self setSourceColor:[sender color]];
   [self setNeedsDisplay];
}

-(void)selectBlendMode:sender {
   [self setBlendMode:(CGBlendMode)[sender selectedTag]];
   [self setNeedsDisplay];
}

-(void)selectShadowColor:sender {
   [self setShadowColor:cgColorFromColor([sender color])];
   [self setNeedsDisplay];
}

-(void)selectShadowBlur:sender {
   [self setShadowBlur:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectShadowOffsetX:sender {
   [self setShadowOffsetX:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectShadowOffsetY:sender {
   [self setShadowOffsetY:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectPathDrawingMode:sender {
   [self setPathDrawingMode:(CGPathDrawingMode)[sender selectedTag]];
   [self setNeedsDisplay];
}

-(void)selectLineWidth:sender {
   [self setLineWidth:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectDashPhase:sender {
   [self setDashPhase:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectDashLength:sender {
   [self setDashLength:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectScaleX:sender {
   [self setScaleX:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectScaleY:sender {
   [self setScaleY:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectRotation:sender {
   [self setRotation:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectAntialias:sender {
   [self setShouldAntialias:[sender intValue]];
   [self setNeedsDisplay];
}

-(void)selectInterpolationQuality:sender {
   [self setInterpolationQuality:(CGInterpolationQuality)[sender selectedTag]];
   [self setNeedsDisplay];
}

@end
