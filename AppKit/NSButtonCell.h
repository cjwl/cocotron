/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSActionCell.h>

enum {
   NSNoCellMask=0x00,
   NSContentsCellMask=0x01,
   NSPushInCellMask=0x02,
   NSChangeGrayCellMask=0x04,
   NSChangeBackgroundCellMask=0x08,
};

typedef enum {
   NSRoundedBezelStyle=1,
   NSRegularSquareBezelStyle,
   NSThickSquareBezelStyle,
   NSThickerSquareBezelStyle,
   NSDisclosureBezelStyle,
   NSShadowlessSquareBezelStyle,
   NSCircularBezelStyle,
   NSTexturedSquareBezelStyle,
   NSHelpButtonBezelStyle,
   NSSmallSquareBezelStyle,
   NSTexturedRoundedBezelStyle,
   NSRoundRectBezelStyle,
   NSRecessedBezelStyle,
   NSRoundedDisclosureBezelStyle,    
} NSBezelStyle;

@interface NSButtonCell : NSActionCell {
   NSString *_alternateTitle;
   NSImage  *_alternateImage;
   int       _imagePosition;
   unsigned  _highlightsBy:4;
   unsigned  _showsStateBy:4;
   NSBezelStyle _bezelStyle;
   BOOL      _isTransparent;
   BOOL      _imageDimsWhenDisabled;
   NSString *_keyEquivalent;
   unsigned  _keyEquivalentModifierMask;
}

-(BOOL)isTransparent;
-(NSString *)keyEquivalent;
-(NSCellImagePosition)imagePosition;
-(NSString *)title;
-(NSString *)alternateTitle;
-(NSImage *)alternateImage;
-(NSAttributedString *)attributedTitle;
-(NSAttributedString *)attributedAlternateTitle;
-(int)highlightsBy;
-(int)showsStateBy;
-(BOOL)imageDimsWhenDisabled;
-(unsigned)keyEquivalentModifierMask;

-(void)setTransparent:(BOOL)flag;
-(void)setKeyEquivalent:(NSString *)keyEquivalent;
-(void)setImagePosition:(NSCellImagePosition)position;
-(void)setTitle:(NSString *)title;
-(void)setAlternateTitle:(NSString *)title;
-(void)setAlternateImage:(NSImage *)image;
-(void)setAttributedTitle:(NSAttributedString *)title;
-(void)setAttributedAlternateTitle:(NSAttributedString *)title;
-(void)setHighlightsBy:(int)type;
-(void)setShowsStateBy:(int)type;
-(void)setImageDimsWhenDisabled:(BOOL)flag;
-(void)setKeyEquivalentModifierMask:(unsigned)mask;

@end

