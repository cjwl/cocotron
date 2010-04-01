/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2GraphicsState.h>

#import <Onyx2D/O2Geometry.h>
#import <Onyx2D/O2Color.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2MutablePath.h>
#import <Onyx2D/O2Font.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Foundation/NSArray.h>
#import <Onyx2D/O2Exceptions.h>
#import <Onyx2D/O2Surface.h>

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

-initFlippedWithDeviceHeight:(O2Float)height {
   O2AffineTransform flip={1,0,0,-1,0,height};
   
   return [self initWithDeviceTransform:flip];
}

-initFlippedWithDeviceHeight:(O2Float)height concat:(O2AffineTransform)concat {
   O2AffineTransform flip={1,0,0,-1,0,height};

   return [self initWithDeviceTransform:O2AffineTransformConcat(flip,concat)];
}

-init {
   return [self initWithDeviceTransform:O2AffineTransformIdentity];
}

-(void)dealloc {
   [_clipPhases release];
   O2ColorRelease(_strokeColor);
   O2ColorRelease(_fillColor);
   [_font release];
   [_fontState release];
   if(_dashLengths!=NULL)
    NSZoneFree(NULL,_dashLengths);
   O2ColorRelease(_shadowColor);
   O2GaussianKernelRelease(_shadowKernel);
   NSDeallocateObject(self);
   return;
   [super dealloc];
}

O2GState *O2GStateCopyWithZone(O2GState *self,NSZone *zone) {
   O2GState *copy=NSCopyObject(self,0,zone);

   copy->_clipPhases=[[NSMutableArray alloc] initWithArray:self->_clipPhases];
   copy->_strokeColor=O2ColorCreateCopy(self->_strokeColor);
   copy->_fillColor=O2ColorCreateCopy(self->_fillColor);
   copy->_font=[self->_font retain];
   copy->_fontState=[self->_fontState retain];
   if(self->_dashLengths!=NULL){
    int i;
    
    copy->_dashLengths=NSZoneMalloc(zone,sizeof(float)*self->_dashLengthsCount);
    for(i=0;i<self->_dashLengthsCount;i++)
     copy->_dashLengths[i]=self->_dashLengths[i];
   }
    
   copy->_shadowColor=O2ColorCreateCopy(self->_shadowColor);
   
   copy->_shadowKernel=O2GaussianKernelRetain(self->_shadowKernel);
   
   return copy;
}

-(O2AffineTransform)userSpaceToDeviceSpaceTransform {
   return _deviceSpaceTransform;
}

O2AffineTransform O2GStateUserSpaceTransform(O2GState *self) {
   return self->_userSpaceTransform;
}

-(O2Rect)clipBoundingBox {
   O2UnimplementedMethod();
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
   O2UnimplementedMethod();
   return O2RectZero;
}

-(O2Rect)convertRectToUserSpace:(O2Rect)rect {
   O2UnimplementedMethod();
   return O2RectZero;
}

void O2GStateSetDeviceSpaceCTM(O2GState *self,O2AffineTransform transform){
   self->_deviceSpaceTransform=transform;
}

void O2GStateSetUserSpaceCTM(O2GState *self,O2AffineTransform transform) {
   self->_userSpaceTransform=transform;
}

void O2GStateConcatCTM(O2GState *self,O2AffineTransform transform) {
   self->_deviceSpaceTransform=O2AffineTransformConcat(transform,self->_deviceSpaceTransform);
   self->_userSpaceTransform=O2AffineTransformConcat(transform,self->_userSpaceTransform);
}

NSArray *O2GStateClipPhases(O2GState *self){
   return self->_clipPhases;
}

-(void)removeAllClipPhases {
   [_clipPhases removeAllObjects];
}

void O2GStateAddClipToPath(O2GState *self,O2Path *path) {
   O2ClipPhase *phase=O2ClipPhaseInitWithNonZeroPath([O2ClipPhase allocWithZone:NULL],path);
   
   [self->_clipPhases addObject:phase];
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

O2ColorRef O2GStateStrokeColor(O2GState *self){
   return self->_strokeColor;
}

O2ColorRef O2GStateFillColor(O2GState *self){
   return self->_fillColor;
}

void O2GStateSetStrokeColor(O2GState *self,O2ColorRef color) {
   [color retain];
   [self->_strokeColor release];
   self->_strokeColor=color;
}

void O2GStateSetFillColor(O2GState *self,O2ColorRef color) {
   [color retain];
   [self->_fillColor release];
   self->_fillColor=color;
}

-(void)setPatternPhase:(O2Size)phase {
   _patternPhase=phase;
}

-(void)setStrokePattern:(O2Pattern *)pattern components:(const float *)components {
}

-(void)setFillPattern:(O2Pattern *)pattern components:(const float *)components {
}

void O2GStateSetTextMatrix(O2GState *self,O2AffineTransform transform) {
   self->_textTransform=transform;
}

void O2GStateSetTextPosition(O2GState *self,float x,float y) {
   self->_textTransform.tx=x;
   self->_textTransform.ty=y;
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

O2Float O2GStatePointSize(O2GState *self) {
   return self->_pointSize;
}

-(O2TextEncoding)textEncoding {
   return _textEncoding;
}

-(O2Glyph *)glyphTableForTextEncoding {
   return [_font glyphTableForEncoding:_textEncoding];
}

void O2GStateClearFontIsDirty(O2GState *self){
   self->_fontIsDirty=NO;
}

-(id)fontState {
   return _fontState;
}

-(void)setFontState:(id)fontState {
   fontState=[fontState retain];
   [_fontState release];
   _fontState=fontState;
}

void O2GStateSetFont(O2GState *self,O2Font *font) {
   if(font!=self->_font){
    font=[font retain];
    [self->_font release];
    self->_font=font;
    self->_fontIsDirty=YES;
   }
}

void O2GStateSetFontSize(O2GState *self,float size) {
   if(self->_pointSize!=size){
    self->_pointSize=size;
    self->_fontIsDirty=YES;
   }
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(O2TextEncoding)encoding {
   O2Font *font=O2FontCreateWithFontName([NSString stringWithCString:name encoding:NSUTF8StringEncoding]);
   
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

void O2GStateSetLineWidth(O2GState *self,float width){
   self->_lineWidth=width;
}

void O2GStateSetLineCap(O2GState *self,int lineCap){
   self->_lineCap=lineCap;
}

void O2GStateSetLineJoin(O2GState *self,int lineJoin) {
   self->_lineJoin=lineJoin;
}

void O2GStateSetMiterLimit(O2GState *self,float limit) {
   self->_miterLimit=limit;
}

void O2GStateSetLineDash(O2GState *self,float phase,const float *lengths,unsigned count){
   self->_dashPhase=phase;
   self->_dashLengthsCount=count;
   
   if(self->_dashLengths!=NULL)
    NSZoneFree(NULL,self->_dashLengths);
    
   if(lengths==NULL || count==0)
    self->_dashLengths=NULL;
   else {
    int i;
    
    self->_dashLengths=NSZoneMalloc(NULL,sizeof(float)*count);
    for(i=0;i<count;i++)
     self->_dashLengths[i]=lengths[i];
   }
}

-(void)setRenderingIntent:(O2ColorRenderingIntent)intent {
   _renderingIntent=intent;
}

void O2GStateSetBlendMode(O2GState *self,O2BlendMode mode){
   self->_blendMode=mode;
}

-(void)setFlatness:(float)flatness {
   _flatness=flatness;
}

-(void)setInterpolationQuality:(O2InterpolationQuality)quality {
   _interpolationQuality=quality;
}

-(void)setShadowOffset:(O2Size)offset blur:(float)blur color:(O2ColorRef )color {
   _shadowOffset=offset;
   _shadowBlur=blur;
   [color retain];
   [_shadowColor release];
   _shadowColor=color;
   O2GaussianKernelRelease(_shadowKernel);
   _shadowKernel=(_shadowColor==nil)?NULL:O2CreateGaussianKernelWithDeviation(blur);
}

-(void)setShadowOffset:(O2Size)offset blur:(float)blur {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceRGB();
   float         components[4]={0,0,0,1.0/3.0};
   O2ColorRef color=O2ColorCreate(colorSpace,components);

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
