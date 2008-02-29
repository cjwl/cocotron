/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/KGGraphicsState.h>

#import <AppKit/CoreGraphics.h>
#import "KGColor.h"
#import "KGColorSpace.h"
#import "KGMutablePath.h"
#import "KGFont.h"
#import "KGClipPhase.h"

@implementation KGGraphicsState

-initWithDeviceTransform:(CGAffineTransform)deviceTransform {
   _deviceSpaceTransform=deviceTransform;
   _userSpaceTransform=CGAffineTransformIdentity;
   _textTransform=CGAffineTransformIdentity;
   _clipPhases=[NSMutableArray new];
   _lineWidth=1.0;
   _strokeColor=[[KGColor alloc] init];
   _fillColor=[[KGColor alloc] init];
   _blendMode=kCGBlendModeNormal;
   _interpolationQuality=kCGInterpolationDefault;
   _shouldAntialias=NO;
   return self;
}

-init {
   return [self initWithDeviceTransform:CGAffineTransformIdentity];
}

-(void)dealloc {
   [_clipPhases release];
   [_strokeColor release];
   [_fillColor release];
   [_font release];
   if(_dashLengths!=NULL)
    NSZoneFree(NULL,_dashLengths);
   [_shadowColor release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   KGGraphicsState *copy=NSCopyObject(self,0,zone);

   copy->_clipPhases=[[NSMutableArray alloc] initWithArray:_clipPhases];
   copy->_strokeColor=[_strokeColor copyWithZone:zone];
   copy->_fillColor=[_fillColor copyWithZone:zone];
   copy->_font=[_font retain];
   if(_dashLengths!=NULL){
    int i;
    
    copy->_dashLengths==NSZoneMalloc(zone,sizeof(float)*_dashLengthsCount);
    for(i=0;i<_dashLengthsCount;i++)
     copy->_dashLengths[i]=_dashLengths[i];
   }
    
   copy->_shadowColor=[_shadowColor copyWithZone:zone];
   
   return copy;
}

-(CGAffineTransform)userSpaceToDeviceSpaceTransform {
   return _deviceSpaceTransform;
}

-(CGAffineTransform)userSpaceTransform {
   return _userSpaceTransform;
}

-(NSRect)clipBoundingBox {
   NSUnimplementedMethod();
   return NSZeroRect;
}

-(CGAffineTransform)textMatrix {
   return _textTransform;
}

-(CGInterpolationQuality)interpolationQuality {
   return _interpolationQuality;
}

-(NSPoint)textPosition {
// FIX, is this right?
  return NSMakePoint(_textTransform.tx,_textTransform.ty);
}

-(NSPoint)convertPointToDeviceSpace:(NSPoint)point {
   return CGPointApplyAffineTransform(point,_deviceSpaceTransform);
}

-(NSPoint)convertPointToUserSpace:(NSPoint)point {
   return CGPointApplyAffineTransform(point,CGAffineTransformInvert(_deviceSpaceTransform));
}

-(NSSize)convertSizeToDeviceSpace:(NSSize)size {
   return CGSizeApplyAffineTransform(size,_deviceSpaceTransform);
}

-(NSSize)convertSizeToUserSpace:(NSSize)size {
   return CGSizeApplyAffineTransform(size,CGAffineTransformInvert(_deviceSpaceTransform));
}

-(NSRect)convertRectToDeviceSpace:(NSRect)rect {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(NSRect)convertRectToUserSpace:(NSRect)rect {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(void)setDeviceSpaceCTM:(CGAffineTransform)transform {
   _deviceSpaceTransform=transform;
}

-(void)setUserSpaceCTM:(CGAffineTransform)transform {
   _userSpaceTransform=transform;
}

-(void)concatCTM:(CGAffineTransform)transform {
   _deviceSpaceTransform=CGAffineTransformConcat(_deviceSpaceTransform,transform);
   _userSpaceTransform=CGAffineTransformConcat(_userSpaceTransform,transform);
}

-(NSArray *)clipPhases {
   return _clipPhases;
}

-(void)removeAllClipPhases {
   [_clipPhases removeAllObjects];
}

-(void)addClipToPath:(KGPath *)path {
   KGClipPhase *phase=[[KGClipPhase alloc] initWithNonZeroPath:path];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(void)addEvenOddClipToPath:(KGPath *)path {
   KGClipPhase *phase=[[KGClipPhase alloc] initWithEOPath:path];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(void)addClipToMask:(KGImage *)image inRect:(NSRect)rect {
   KGClipPhase *phase=[[KGClipPhase alloc] initWithMask:image rect:rect transform:_deviceSpaceTransform];
   
   [_clipPhases addObject:phase];
   [phase release];
}

-(KGColor *)strokeColor {
   return _strokeColor;
}

-(KGColor *)fillColor {
   return _fillColor;
}

-(void)setStrokeColor:(KGColor *)color {
   [color retain];
   [_strokeColor release];
   _strokeColor=color;
}

-(void)setFillColor:(KGColor *)color {
   [color retain];
   [_fillColor release];
   _fillColor=color;
}

-(void)setPatternPhase:(NSSize)phase {
   _patternPhase=phase;
}

-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components {
}

-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components {
}

-(void)setTextMatrix:(CGAffineTransform)transform {
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

-(KGFont *)font {
   return _font;
}

-(void)setFont:(KGFont *)font {
   font=[font retain];
   [_font release];
   _font=font;
}

-(void)setShouldSmoothFonts:(BOOL)yesOrNo {
   _shouldSmoothFonts=yesOrNo;
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

-(void)setRenderingIntent:(CGColorRenderingIntent)intent {
   _renderingIntent=intent;
}

-(void)setBlendMode:(CGBlendMode)mode {
   _blendMode=mode;
}

-(void)setFlatness:(float)flatness {
   _flatness=flatness;
}

-(void)setInterpolationQuality:(CGInterpolationQuality)quality {
   _interpolationQuality=quality;
}

-(void)setShadowOffset:(NSSize)offset blur:(float)blur color:(KGColor *)color {
   _shadowOffset=offset;
   _shadowBlur=blur;
   [color retain];
   [_shadowColor release];
   _shadowColor=color;
}

-(void)setShadowOffset:(NSSize)offset blur:(float)blur {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   float         components[4]={0,0,0,1.0/3.0};

   _shadowOffset=offset;
   _shadowBlur=blur;
   [_shadowColor release];
   _shadowColor=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   [colorSpace release];
}

-(void)setShouldAntialias:(BOOL)flag {
   _shouldAntialias=flag;
}

// temporary

-(void)setWordSpacing:(float)spacing {
   _wordSpacing=spacing;
}

-(void)setTextLeading:(float)leading {
   _textLeading=leading;
}

@end
