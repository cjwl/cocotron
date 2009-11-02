/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGGraphicsState.h"

#import "O2Geometry.h"
#import "O2Color.h"
#import "O2ColorSpace.h"
#import "O2MutablePath.h"
#import "KGFont.h"
#import "KGClipPhase.h"
#import <Foundation/NSArray.h>
#import "KGExceptions.h"
#import "KGSurface.h"

@implementation O2GState

-initWithDeviceTransform:(O2AffineTransform)deviceTransform {
   _deviceSpaceTransform=deviceTransform;
   _userSpaceTransform=O2AffineTransformIdentity;
   _textTransform=O2AffineTransformIdentity;
   _clipPhases=[NSMutableArray new];
   _strokeColor=[[O2Color alloc] init];
   _fillColor=[[O2Color alloc] init];
   _font=nil;
   _pointSize=12.0;
   _fontIsDirty=YES;
   _textEncoding=kO2EncodingFontSpecific;
   _fontState=nil;
   _patternPhase=O2SizeMake(0,0);
   _lineWidth=1.0;
   _miterLimit=10;
   _blendMode=kO2BlendModeNormal;
   _interpolationQuality=kO2InterpolationDefault;
   _shouldAntialias=YES;
   _antialiasingQuality=64;
   return self;
}

-init {
   return [self initWithDeviceTransform:O2AffineTransformIdentity];
}

-(void)dealloc {
   [_clipPhases release];
   [_strokeColor release];
   [_fillColor release];
   [_font release];
   [_fontState release];
   if(_dashLengths!=NULL)
    NSZoneFree(NULL,_dashLengths);
   [_shadowColor release];
   KGGaussianKernelRelease(_shadowKernel);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   O2GState *copy=NSCopyObject(self,0,zone);

   copy->_clipPhases=[[NSMutableArray alloc] initWithArray:_clipPhases];
   copy->_strokeColor=O2ColorCreateCopy(_strokeColor);
   copy->_fillColor=O2ColorCreateCopy(_fillColor);
   copy->_font=[_font retain];
   copy->_fontState=[_fontState retain];
   if(_dashLengths!=NULL){
    int i;
    
    copy->_dashLengths=NSZoneMalloc(zone,sizeof(float)*_dashLengthsCount);
    for(i=0;i<_dashLengthsCount;i++)
     copy->_dashLengths[i]=_dashLengths[i];
   }
    
   copy->_shadowColor=O2ColorCreateCopy(_shadowColor);
   
   copy->_shadowKernel=KGGaussianKernelRetain(_shadowKernel);
   
   return copy;
}

-(O2AffineTransform)userSpaceToDeviceSpaceTransform {
   return _deviceSpaceTransform;
}

-(O2AffineTransform)userSpaceTransform {
   return _userSpaceTransform;
}

-(O2Rect)clipBoundingBox {
   KGUnimplementedMethod();
   return O2RectZero;
}

-(O2AffineTransform)textMatrix {
   return _textTransform;
}

-(O2InterpolationQuality)interpolationQuality {
   return _interpolationQuality;
}

-(O2Point)textPosition {
// FIX, is this right?
  return O2PointMake(_textTransform.tx,_textTransform.ty);
}

-(O2Point)convertPointToDeviceSpace:(O2Point)point {
   return O2PointApplyAffineTransform(point,_deviceSpaceTransform);
}

-(O2Point)convertPointToUserSpace:(O2Point)point {
   return O2PointApplyAffineTransform(point,O2AffineTransformInvert(_deviceSpaceTransform));
}

-(O2Size)convertSizeToDeviceSpace:(O2Size)size {
   return O2SizeApplyAffineTransform(size,_deviceSpaceTransform);
}

-(O2Size)convertSizeToUserSpace:(O2Size)size {
   return O2SizeApplyAffineTransform(size,O2AffineTransformInvert(_deviceSpaceTransform));
}

-(O2Rect)convertRectToDeviceSpace:(O2Rect)rect {
   KGUnimplementedMethod();
   return O2RectZero;
}

-(O2Rect)convertRectToUserSpace:(O2Rect)rect {
   KGUnimplementedMethod();
   return O2RectZero;
}

-(void)setDeviceSpaceCTM:(O2AffineTransform)transform {
   _deviceSpaceTransform=transform;
}

-(void)setUserSpaceCTM:(O2AffineTransform)transform {
   _userSpaceTransform=transform;
}

-(void)concatCTM:(O2AffineTransform)transform {
   _deviceSpaceTransform=O2AffineTransformConcat(transform,_deviceSpaceTransform);
   _userSpaceTransform=O2AffineTransformConcat(transform,_userSpaceTransform);
}

-(NSArray *)clipPhases {
   return _clipPhases;
}

-(void)removeAllClipPhases {
   [_clipPhases removeAllObjects];
}

-(void)addClipToPath:(O2Path *)path {
   O2ClipPhase *phase=[[O2ClipPhase alloc] initWithNonZeroPath:path];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(void)addEvenOddClipToPath:(O2Path *)path {
   O2ClipPhase *phase=[[O2ClipPhase alloc] initWithEOPath:path];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(void)addClipToMask:(O2Image *)image inRect:(O2Rect)rect {
   O2ClipPhase *phase=[[O2ClipPhase alloc] initWithMask:image rect:rect transform:_deviceSpaceTransform];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(O2Color *)strokeColor {
   return _strokeColor;
}

-(O2Color *)fillColor {
   return _fillColor;
}

-(void)setStrokeColor:(O2Color *)color {
   [color retain];
   [_strokeColor release];
   _strokeColor=color;
}

-(void)setFillColor:(O2Color *)color {
   [color retain];
   [_fillColor release];
   _fillColor=color;
}

-(void)setPatternPhase:(O2Size)phase {
   _patternPhase=phase;
}

-(void)setStrokePattern:(O2Pattern *)pattern components:(const float *)components {
}

-(void)setFillPattern:(O2Pattern *)pattern components:(const float *)components {
}

-(void)setTextMatrix:(O2AffineTransform)transform {
   _textTransform=transform;
}

-(void)setTextPosition:(float)x:(float)y {
   _textTransform.tx=x;
   _textTransform.ty=y;
}

-(void)setCharacterSpacing:(float)spacing {
   _characterSpacing=spacing;
}

-(void)setTextDrawingMode:(int)textMode {
   _textDrawingMode=textMode;
}

-(O2Font *)font {
   return _font;
}

-(O2Float)pointSize {
   return _pointSize;
}

-(O2TextEncoding)textEncoding {
   return _textEncoding;
}

-(O2Glyph *)glyphTableForTextEncoding {
   return [_font glyphTableForEncoding:_textEncoding];
}

-(void)clearFontIsDirty {
   _fontIsDirty=NO;
}

-(id)fontState {
   return _fontState;
}

-(void)setFontState:(id)fontState {
   fontState=[fontState retain];
   [_fontState release];
   _fontState=fontState;
}

-(void)setFont:(O2Font *)font {
   if(font!=_font){
    font=[font retain];
    [_font release];
    _font=font;
    _fontIsDirty=YES;
   }
}

-(void)setFontSize:(float)size {
   if(_pointSize!=size){
    _pointSize=size;
    _fontIsDirty=YES;
   }
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(O2TextEncoding)encoding {
   O2Font *font=O2FontCreateWithFontName([NSString stringWithCString:name]);
   
   if(font!=nil){
    [_font release];
    _font=font;
   }
   
   _pointSize=size;
   _textEncoding=encoding;
   _fontIsDirty=YES;
}

-(void)setShouldSmoothFonts:(BOOL)yesOrNo {
   _shouldSmoothFonts=yesOrNo;
   _fontIsDirty=YES;
}

-(void)setLineWidth:(float)width {
   _lineWidth=width;
}

-(void)setLineCap:(int)lineCap {
   _lineCap=lineCap;
}

-(void)setLineJoin:(int)lineJoin {
   _lineJoin=lineJoin;
}

-(void)setMiterLimit:(float)limit {
   _miterLimit=limit;
}

-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count {
   _dashPhase=phase;
   _dashLengthsCount=count;
   
   if(_dashLengths!=NULL)
    NSZoneFree(NULL,_dashLengths);
    
   if(lengths==NULL || count==0)
    _dashLengths=NULL;
   else {
    int i;
    
    _dashLengths=NSZoneMalloc(NULL,sizeof(float)*count);
    for(i=0;i<count;i++)
     _dashLengths[i]=lengths[i];
   }
}

-(void)setRenderingIntent:(O2ColorRenderingIntent)intent {
   _renderingIntent=intent;
}

-(void)setBlendMode:(O2BlendMode)mode {
   _blendMode=mode;
}

-(void)setFlatness:(float)flatness {
   _flatness=flatness;
}

-(void)setInterpolationQuality:(O2InterpolationQuality)quality {
   _interpolationQuality=quality;
}

-(void)setShadowOffset:(O2Size)offset blur:(float)blur color:(O2Color *)color {
   _shadowOffset=offset;
   _shadowBlur=blur;
   [color retain];
   [_shadowColor release];
   _shadowColor=color;
   KGGaussianKernelRelease(_shadowKernel);
   _shadowKernel=(_shadowColor==nil)?NULL:KGCreateGaussianKernelWithDeviation(blur);
}

-(void)setShadowOffset:(O2Size)offset blur:(float)blur {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceRGB();
   float         components[4]={0,0,0,1.0/3.0};
   O2Color      *color=O2ColorCreate(colorSpace,components);

   [self setShadowOffset:offset blur:blur color:color];
   [color release];
   [colorSpace release];
}

-(void)setShouldAntialias:(BOOL)flag {
   _shouldAntialias=flag;
}

// temporary

-(void)setAntialiasingQuality:(int)value {
   _antialiasingQuality=value;
}

-(void)setWordSpacing:(float)spacing {
   _wordSpacing=spacing;
}

-(void)setTextLeading:(float)leading {
   _textLeading=leading;
}

@end
