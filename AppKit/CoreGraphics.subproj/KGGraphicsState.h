/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGImage,KGColorSpace,KGColor,KGPattern,KGMutablePath,KGPath,NSArray,NSMutableArray,KGFont,KTFont;

@interface KGGraphicsState : NSObject <NSCopying> {
@public
   CGAffineTransform   _deviceSpaceTransform;
   CGAffineTransform   _userSpaceTransform;
   CGAffineTransform   _textTransform;
   
   NSMutableArray     *_clipPhases;
   KGColor            *_strokeColor;
   KGColor            *_fillColor;
   KGFont             *_font;
   CGFloat             _pointSize;
   id                  _fontState;
   CGSize              _patternPhase;   
   float               _characterSpacing;
   int                 _textDrawingMode;
   BOOL                _shouldSmoothFonts;
   float               _lineWidth;
   CGLineCap           _lineCap;
   CGLineJoin          _lineJoin;
   float               _miterLimit;
   float               _dashPhase;
   int                 _dashLengthsCount;
   float              *_dashLengths;
   CGColorRenderingIntent _renderingIntent;
   CGBlendMode          _blendMode;
   float               _flatness;
   CGInterpolationQuality _interpolationQuality;
   CGSize              _shadowOffset;
   float               _shadowBlur;
   KGColor            *_shadowColor;
   void               *_shadowKernel;
   BOOL                _shouldAntialias;
   
   int                 _antialiasingQuality;
   float               _wordSpacing;
   float               _textLeading;
}

-initWithDeviceTransform:(CGAffineTransform)deviceTransform;
-init;

-(CGAffineTransform)userSpaceToDeviceSpaceTransform;
-(CGAffineTransform)userSpaceTransform;
-(CGRect)clipBoundingBox;
-(CGAffineTransform)textMatrix;
-(CGInterpolationQuality)interpolationQuality;
-(CGPoint)textPosition;
-(CGPoint)convertPointToDeviceSpace:(CGPoint)point;
-(CGPoint)convertPointToUserSpace:(CGPoint)point;
-(CGSize)convertSizeToDeviceSpace:(CGSize)size;
-(CGSize)convertSizeToUserSpace:(CGSize)size;
-(CGRect)convertRectToDeviceSpace:(CGRect)rect;
-(CGRect)convertRectToUserSpace:(CGRect)rect;

-(void)setDeviceSpaceCTM:(CGAffineTransform)transform;
-(void)setUserSpaceCTM:(CGAffineTransform)transform;
-(void)concatCTM:(CGAffineTransform)transform;

-(NSArray *)clipPhases;
-(void)removeAllClipPhases;
-(void)addClipToPath:(KGPath *)path;
-(void)addEvenOddClipToPath:(KGPath *)path;
-(void)addClipToMask:(KGImage *)image inRect:(CGRect)rect;

-(KGColor *)strokeColor;
-(KGColor *)fillColor;

-(void)setStrokeColor:(KGColor *)color;
-(void)setFillColor:(KGColor *)color;

-(void)setPatternPhase:(CGSize)phase;
-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components;
-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components;

-(void)setTextMatrix:(CGAffineTransform)transform;
-(void)setTextPosition:(float)x:(float)y;
-(void)setCharacterSpacing:(float)spacing;
-(void)setTextDrawingMode:(int)textMode;
-(KGFont *)font;
-(NSString *)fontName;
-(CGFloat)pointSize;
-(id)fontState;
-(void)setFontState:(id)fontState;
-(void)setFont:(KGFont *)font;
-(void)setFontSize:(float)size;
-(void)selectFontWithName:(const char *)name size:(float)size encoding:(int)encoding;
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

-(void)setShadowOffset:(CGSize)offset blur:(float)blur color:(KGColor *)color;
-(void)setShadowOffset:(CGSize)offset blur:(float)blur;

-(void)setShouldAntialias:(BOOL)flag;

// temporary?
-(void)setAntialiasingQuality:(int)value;
-(void)setWordSpacing:(float)spacing;
-(void)setTextLeading:(float)leading;

@end
