/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/KGGraphicsState.h>
#import <AppKit/KGRenderingContext.h>

#import <AppKit/CoreGraphics.h>
#import "KGColor.h"
#import "KGColorSpace.h"
#import "KGMutablePath.h"

@implementation KGGraphicsState

-initWithRenderingContext:(KGRenderingContext *)context transform:(CGAffineTransform)deviceTransform userSpaceSize:(NSSize)userSpaceSize {
   _renderingContext=[context retain];
   _ctm=deviceTransform;
   _textTransform=CGAffineTransformIdentity;
   _clipRect=NSMakeRect(0,0,userSpaceSize.width,userSpaceSize.height);
   _deviceState=nil;
   _lineWidth=1.0;
   _strokeColor=[[KGColor alloc] init];
   _fillColor=[[KGColor alloc] init];
   _shouldAntialias=NO;
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [_deviceState release];
   [_strokeColor release];
   [_fillColor release];
   if(_dashLengths!=NULL)
    NSZoneFree(NULL,_dashLengths);
   [_shadowColor release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   KGGraphicsState *copy=NSCopyObject(self,0,zone);

   copy->_renderingContext=[_renderingContext retain];
   copy->_deviceState=nil;
   copy->_strokeColor=[_strokeColor copyWithZone:zone];
   copy->_fillColor=[_fillColor copyWithZone:zone];
   copy->_shadowColor=[_shadowColor copyWithZone:zone];
   
   return copy;
}

-(KGRenderingContext *)renderingContext {
   return _renderingContext;
}

-(void)save {
   _deviceState=[_renderingContext saveCopyOfDeviceState];
}

-(void)restore {
   [_renderingContext restoreDeviceState:_deviceState];
   [_deviceState release];
   _deviceState=nil;
}

-(CGAffineTransform)userSpaceToDeviceSpaceTransform {
   NSUnimplementedMethod();
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

-(int)interpolationQuality {
}

-(NSPoint)textPosition {
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
}

-(NSRect)convertRectToUserSpace:(NSRect)rect {
}

-(void)concatCTM:(CGAffineTransform)transform {
   _ctm=CGAffineTransformConcat(_ctm,transform);
}

-(void)translateCTM:(float)tx:(float)ty {
   _ctm=CGAffineTransformTranslate(_ctm,tx,ty);
}

-(void)scaleCTM:(float)scalex:(float)scaley {
   _ctm=CGAffineTransformScale(_ctm,scalex,scaley);
}

-(void)rotateCTM:(float)radians {
   _ctm=CGAffineTransformRotate(_ctm,radians);
}

-(void)clipToPath:(KGPath *)path {
   [_renderingContext clipToDeviceSpacePath:path];
}

-(void)evenOddClipToPath:(KGPath *)path {
   [_renderingContext evenOddClipToDeviceSpacePath:path];
}

-(void)clipToMask:(KGImage *)image inRect:(NSRect)rect {
}

-(void)clipToRect:(NSRect)clipRect  {
   [_renderingContext clipInUserSpace:_ctm rects:&clipRect count:1];
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   [_renderingContext clipInUserSpace:_ctm rects:rects count:count];
}

-(KGColor *)strokeColor {
   return _strokeColor;
}

-(KGColor *)fillColor {
   return _fillColor;
}

-(void)setStrokeColorSpace:(KGColorSpace *)colorSpace {
   KGColor *color=[[KGColor alloc] initWithColorSpace:colorSpace];
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setFillColorSpace:(KGColorSpace *)colorSpace {
   KGColor *color=[[KGColor alloc] initWithColorSpace:colorSpace];
   
   [self setFillColor:color];
   
   [color release];
}

-(void)setStrokeColorWithComponents:(const float *)components {
   KGColorSpace *colorSpace=[_strokeColor colorSpace];
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
}

-(void)setStrokeColor:(KGColor *)color {
   [color retain];
   [_strokeColor release];
   _strokeColor=color;
}

-(void)setGrayStrokeColor:(float)gray:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setStrokeColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setFillColorWithComponents:(const float *)components {
   KGColorSpace *colorSpace=[_fillColor colorSpace];
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
}

-(void)setFillColor:(KGColor *)color {
   [color retain];
   [_fillColor release];
   _fillColor=color;
}

-(void)setGrayFillColor:(float)gray:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceGray];
   float         components[2]={gray,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   float         components[4]={r,g,b,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}


-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k:(float)alpha {
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceCMYK];
   float         components[5]={c,m,y,k,alpha};
   KGColor      *color=[[KGColor alloc] initWithColorSpace:colorSpace components:components];
   
   [self setFillColor:color];
   
   [color release];
   [colorSpace release];
}

-(void)setStrokeAndFillAlpha:(float)alpha {
   [self setStrokeAlpha:alpha];
   [self setFillAlpha:alpha];
}

-(void)setStrokeAlpha:(float)alpha {
   KGColor *color=[_strokeColor copyWithAlpha:alpha];
   [self setStrokeColor:color];
   [color release];
}

-(void)setGrayStrokeColor:(float)gray {
   float alpha=[_strokeColor alpha];
   
   [self setGrayStrokeColor:gray:alpha];
}

-(void)setRGBStrokeColor:(float)r:(float)g:(float)b {
   float alpha=[_strokeColor alpha];
   [self setRGBStrokeColor:r:g:b:alpha];
}

-(void)setCMYKStrokeColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=[_strokeColor alpha];
   [self setCMYKStrokeColor:c:m:y:k:alpha];
}

-(void)setFillAlpha:(float)alpha {
   KGColor *color=[_fillColor copyWithAlpha:alpha];
   [self setFillColor:color];
   [color release];
}

-(void)setGrayFillColor:(float)gray {
   float alpha=[_fillColor alpha];
   [self setGrayFillColor:gray:alpha];
}

-(void)setRGBFillColor:(float)r:(float)g:(float)b {
   float alpha=[_fillColor alpha];
   [self setRGBFillColor:r:g:b:alpha];
}

-(void)setCMYKFillColor:(float)c:(float)m:(float)y:(float)k {
   float alpha=[_fillColor alpha];
   [self setCMYKFillColor:c:m:y:k:alpha];
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

-(void)setFont:(KGFont *)font {
}

-(void)setFontSize:(float)size {
}

-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding {
   [_renderingContext selectFontWithName:name pointSize:size antialias:_shouldAntialias];
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

-(void)setRenderingIntent:(int)intent {
   _renderingIntent=intent;
}

-(void)setBlendMode:(int)mode {
   _blendMode=mode;
}

-(void)setFlatness:(float)flatness {
   _flatness=flatness;
}

-(void)setInterpolationQuality:(int)quality {
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

-(void)strokeLineSegmentsWithPoints:(NSPoint *)points count:(unsigned)count {
   NSUnimplementedMethod();
}

-(void)strokeRect:(NSRect)rect {
   NSUnimplementedMethod();
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [_renderingContext strokeInUserSpace:_ctm rect:rect width:width color:_strokeColor];
}

-(void)strokeEllipseInRect:(NSRect)rect {
   NSUnimplementedMethod();
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [_renderingContext fillInUserSpace:_ctm rects:rects count:count color:_fillColor];
}

-(void)fillEllipseInRect:(NSRect)rect {
   NSUnimplementedMethod();
}

-(void)drawPath:(KGPath *)path mode:(int)mode {
   [_renderingContext drawPathInDeviceSpace:path drawingMode:mode ctm:_ctm lineWidth:_lineWidth fillColor:_fillColor strokeColor:_strokeColor];
}

-(void)clearRect:(NSRect)rect {
   NSUnimplementedMethod();
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)numberOfGlyphs {
   [_renderingContext showInUserSpace:_ctm textSpace:_textTransform glyphs:glyphs count:numberOfGlyphs color:_fillColor];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)numberOfGlyphs atPoint:(float)x:(float)y {   
   _textTransform.tx=x;
   _textTransform.ty=y;
   [_renderingContext showInUserSpace:_ctm textSpace:_textTransform glyphs:glyphs count:numberOfGlyphs color:_fillColor];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count advances:(const NSSize *)advances {
   NSUnimplementedMethod();
}

-(void)showText:(const char *)text length:(unsigned)length {
   [_renderingContext showInUserSpace:_ctm textSpace:_textTransform text:text count:length color:_fillColor];
}

-(void)showText:(const char *)text length:(unsigned)length atPoint:(float)x:(float)y {
   _textTransform.tx=x;
   _textTransform.ty=y;
   [_renderingContext showInUserSpace:_ctm textSpace:_textTransform text:text count:length color:_fillColor];
}

-(void)drawShading:(KGShading *)shading {
   [_renderingContext drawInUserSpace:_ctm shading:shading];
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   [_renderingContext drawImage:image inRect:rect ctm:_ctm fraction:[_fillColor alpha]];
}

// temporary
-(void)setWordSpacing:(float)spacing {
   _wordSpacing=spacing;
}

-(void)setTextLeading:(float)leading {
   _textLeading=leading;
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point {
   [_renderingContext copyBitsInUserSpace:_ctm rect:rect toPoint:point];
}

@end

void CGGraphicsSourceOver_rgba32_onto_bgrx32(unsigned char *sourceRGBA,unsigned char *resultBGRX,int width,int height,float fraction) {
   int sourceIndex=0;
   int sourceLength=width*height*4;
   int destinationReadIndex=0;
   int destinationWriteIndex=0;

   while(sourceIndex<sourceLength){
    unsigned srcr=sourceRGBA[sourceIndex++];
    unsigned srcg=sourceRGBA[sourceIndex++];
    unsigned srcb=sourceRGBA[sourceIndex++];
    unsigned srca=sourceRGBA[sourceIndex++]*fraction;

    unsigned dstb=resultBGRX[destinationReadIndex++];
    unsigned dstg=resultBGRX[destinationReadIndex++];
    unsigned dstr=resultBGRX[destinationReadIndex++];
    unsigned dsta=255-srca;

    destinationReadIndex++;

    dstr=(srcr*srca+dstr*dsta)>>8;
    dstg=(srcg*srca+dstg*dsta)>>8;
    dstb=(srcb*srca+dstb*dsta)>>8;

    resultBGRX[destinationWriteIndex++]=dstb;
    resultBGRX[destinationWriteIndex++]=dstg;
    resultBGRX[destinationWriteIndex++]=dstr;
    destinationWriteIndex++; // skip x
   }
}
