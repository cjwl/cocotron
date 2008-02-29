/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>
#import <AppKit/CGGeometry.h>
#import <AppKit/CGContext.h>

@class KGImage,KGColorSpace,KGColor,KGPattern,KGShading,KGMutablePath,KGPath;

@interface KGGraphicsState : NSObject <NSCopying> {
@public
   CGAffineTransform   _deviceSpaceTransform;
   CGAffineTransform   _userSpaceTransform;
   CGAffineTransform   _textTransform;
   
   NSMutableArray     *_clipPhases;
   KGColor            *_strokeColor;
   KGColor            *_fillColor;
   KGFont             *_font;
   NSSize              _patternPhase;   
   float               _characterSpacing;
   int                 _textDrawingMode;
   BOOL                _shouldSmoothFonts;
   float               _lineWidth;
   CGLineCap           _lineCap;
   CGLineJoin          _lineJoin;
   float               _miterLimit;
   float               _dashPhase;
   float               _dashLengthsCount;
   float              *_dashLengths;
   CGColorRenderingIntent _renderingIntent;
   CGBlendMode          _blendMode;
   float               _flatness;
   CGInterpolationQuality _interpolationQuality;
   NSSize              _shadowOffset;
   float               _shadowBlur;
   KGColor            *_shadowColor;
   BOOL                _shouldAntialias;
   
   float               _wordSpacing;
   float               _textLeading;
}

-initWithDeviceTransform:(CGAffineTransform)deviceTransform;
-init;

-(CGAffineTransform)userSpaceToDeviceSpaceTransform;
-(CGAffineTransform)userSpaceTransform;
-(NSRect)clipBoundingBox;
-(CGAffineTransform)textMatrix;
-(CGInterpolationQuality)interpolationQuality;
-(NSPoint)textPosition;
-(NSPoint)convertPointToDeviceSpace:(NSPoint)point;
-(NSPoint)convertPointToUserSpace:(NSPoint)point;
-(NSSize)convertSizeToDeviceSpace:(NSSize)size;
-(NSSize)convertSizeToUserSpace:(NSSize)size;
-(NSRect)convertRectToDeviceSpace:(NSRect)rect;
-(NSRect)convertRectToUserSpace:(NSRect)rect;

-(void)setDeviceSpaceCTM:(CGAffineTransform)transform;
-(void)setUserSpaceCTM:(CGAffineTransform)transform;
-(void)concatCTM:(CGAffineTransform)transform;

-(NSArray *)clipPhases;
-(void)removeAllClipPhases;
-(void)addClipToPath:(KGPath *)path;
-(void)addEvenOddClipToPath:(KGPath *)path;
-(void)addClipToMask:(KGImage *)image inRect:(NSRect)rect;

-(KGColor *)strokeColor;
-(KGColor *)fillColor;

-(void)setStrokeColor:(KGColor *)color;
-(void)setFillColor:(KGColor *)color;

-(void)setPatternPhase:(NSSize)phase;
-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components;
-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components;

-(void)setTextMatrix:(CGAffineTransform)transform;
-(void)setTextPosition:(float)x:(float)y;
-(void)setCharacterSpacing:(float)spacing;
-(void)setTextDrawingMode:(int)textMode;
-(KGFont *)font;
-(void)setFont:(KGFont *)font;
-(void)setShouldSmoothFonts:(BOOL)yesOrNo;

-(void)setLineWidth:(float)width;
-(void)setLineCap:(int)lineCap;
-(void)setLineJoin:(int)lineJoin;
-(void)setMiterLimit:(float)limit;
-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count;

-(void)setRenderingIntent:(CGColorRenderingIntent)intent;
-(void)setBlendMode:(CGBlendMode)mode;

-(void)setFlatness:(float)flatness;
-(void)setInterpolationQuality:(CGInterpolationQuality)quality;

-(void)setShadowOffset:(NSSize)offset blur:(float)blur color:(KGColor *)color;
-(void)setShadowOffset:(NSSize)offset blur:(float)blur;

-(void)setShouldAntialias:(BOOL)flag;

// temporary?

-(void)setWordSpacing:(float)spacing;
-(void)setTextLeading:(float)leading;

@end
