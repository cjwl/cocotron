/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

@class NSColorPanel, NSImage, NSButtonCell, NSColorList, NSView, NSColor;

@protocol NSColorPickingDefault

-initWithPickerMask:(int)mask colorPanel:(NSColorPanel *)colorPanel;

-(void)setMode:(int)mode;
-(void)attachColorList:(NSColorList *)colorList;
-(void)detachColorList:(NSColorList *)colorList;

-(NSImage *)provideNewButtonImage;

-(void)insertNewButtonImage:(NSImage *)image in:(NSButtonCell *)buttonCell;

-(void)alphaControlAddedOrRemoved:sender;

-(void)viewSizeChanged:sender;

@end

@protocol NSColorPickingCustom

-(int)currentMode;
-(BOOL)supportsMode:(int)mode;

-(void)setColor:(NSColor *)color;

-(NSView *)provideNewView:(BOOL)firstTime;

@end

@interface NSColorPicker : NSObject <NSColorPickingDefault, NSColorPickingCustom> {
   int           _mask;
   NSColorPanel *_colorPanel;
   NSView       *_subview;
}

-(NSColorPanel *)colorPanel;

@end
