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

@implementation KGGraphicsState

-initWithTransform:(CGAffineTransform)deviceTransform {
   _ctm=deviceTransform;
   _textTransform=CGAffineTransformIdentity;
   _lineWidth=1.0;
   _strokeColor=[[KGColor alloc] init];
   _fillColor=[[KGColor alloc] init];
   _shouldAntialias=NO;
   return self;
}

-init {
   return [self initWithTransform:CGAffineTransformIdentity];
}

-(void)dealloc {
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

-(void)save {
}

-(void)restore {
}

-(CGAffineTransform)userSpaceToDeviceSpaceTransform {
   NSUnimplementedMethod();
   return CGAffineTransformIdentity;
}

-(CGAffineTransform)ctm {
   return _ctm;
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
   return CGPointApplyAffineTransform(point,_ctm);
}

-(NSPoint)convertPointToUserSpace:(NSPoint)point {
   return CGPointApplyAffineTransform(point,CGAffineTransformInvert(_ctm));
}

-(NSSize)convertSizeToDeviceSpace:(NSSize)size {
   return CGSizeApplyAffineTransform(size,_ctm);
}

-(NSSize)convertSizeToUserSpace:(NSSize)size {
   return CGSizeApplyAffineTransform(size,CGAffineTransformInvert(_ctm));
}

-(NSRect)convertRectToDeviceSpace:(NSRect)rect {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(NSRect)convertRectToUserSpace:(NSRect)rect {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(void)setCTM:(CGAffineTransform)transform {
   _ctm=transform;
}

-(void)concatCTM:(CGAffineTransform)transform {
   _ctm=CGAffineTransformConcat(_ctm,transform);
}

-(void)clipToPath:(KGPath *)path {
   NSInvalidAbstractInvocation();
}

-(void)evenOddClipToPath:(KGPath *)path {
   NSInvalidAbstractInvocation();
}

-(void)clipToMask:(KGImage *)image inRect:(NSRect)rect {
   NSInvalidAbstractInvocation();
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   NSInvalidAbstractInvocation();
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

-(void)setBlendMode:(int)mode {
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

-(void)resetClip {
}

-(void)setWordSpacing:(float)spacing {
   _wordSpacing=spacing;
}

-(void)setTextLeading:(float)leading {
   _textLeading=leading;
}

@end
