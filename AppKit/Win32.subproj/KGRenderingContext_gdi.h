/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/CGAffineTransform.h>
#import <AppKit/CGFont.h>

@class KGDeviceContext_gdi,KGContext,KGColor,KGPath,KGImage,KGLayer,KGShading;

#import <windows.h>

@class Win32Font, NSAffineTransform;

@interface KGRenderingContext_gdi : NSObject {
   KGDeviceContext_gdi *_deviceContext;
   KGFont          *_font;
   HDC        _dc;
   HRGN       _clipRegion;
   BOOL       _isAdvanced;
   Win32Font *_gdiFont;
}

+(KGRenderingContext_gdi *)renderingContextWithPrinterDC:(HDC)dc;
+(KGRenderingContext_gdi *)renderingContextWithWindowHWND:(HWND)handle;
+(KGRenderingContext_gdi *)renderingContextWithSize:(NSSize)size renderingContext:(KGRenderingContext_gdi *)otherContext;
+(KGRenderingContext_gdi *)renderingContextWithSize:(NSSize)size;

-(KGContext *)createGraphicsContext;
-(KGContext *)cgContextWithSize:(NSSize)size;

-initWithDC:(HDC)dc deviceContext:(KGDeviceContext_gdi *)deviceContext;

-(KGDeviceContext_gdi *)deviceContext;
-(HDC)dc;
-(HWND)windowHandle;

-(NSSize)size;

-(void)beginPage;
-(void)endPage;

-(void)beginPrintingWithDocumentName:(NSString *)name;
-(void)endPrinting;

-(void)setFont:(KGFont *)font;

-(id)saveCopyOfDeviceState;
-(void)restoreDeviceState:(id)state;

-(void)clipToDeviceSpacePath:(KGPath *)path;
-(void)evenOddClipToDeviceSpacePath:(KGPath *)path;

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect ctm:(CGAffineTransform)ctm;

-(void)drawInUserSpace:(CGAffineTransform)matrix shading:(KGShading *)shading;

-(void)resetClip;

-(void)selectFontWithName:(const char *)name pointSize:(float)pointSize;
-(void)selectFontWithName:(const char *)name pointSize:(float)pointSize antialias:(BOOL)antialias;
-(Win32Font *)currentFont;

-(void)copyColorsToContext:(KGRenderingContext_gdi *)other size:(NSSize)size toPoint:(NSPoint)toPoint ;

-(void)copyColorsToContext:(KGRenderingContext_gdi *)other size:(NSSize)size;

-(void)clipInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)userRects count:(unsigned)count;

-(void)fillInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)rects count:(unsigned)count color:(KGColor *)color;

-(void)strokeInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect width:(float)width color:(KGColor *)color;

-(void)copyBitsInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect toPoint:(NSPoint)point;

-(void)showInUserSpace:(CGAffineTransform)ctm textSpace:(CGAffineTransform)textSpace text:(const char *)text count:(unsigned)count color:(KGColor *)color;

-(void)showInUserSpace:(CGAffineTransform)ctm textSpace:(CGAffineTransform)textSpace glyphs:(const CGGlyph *)glyphs count:(unsigned)count color:(KGColor *)color;

-(void)drawPathInDeviceSpace:(KGPath *)path drawingMode:(int)mode ctm:(CGAffineTransform)ctm lineWidth:(float)lineWidth fillColor:(KGColor *)fillColor strokeColor:(KGColor *)strokeColor;

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect ctm:(CGAffineTransform)ctm fraction:(float)fraction;

-(void)drawOther:(KGRenderingContext_gdi *)other inRect:(NSRect)rect ctm:(CGAffineTransform)ctm;

@end

NSRect Win32TransformRect(CGAffineTransform matrix,NSRect rect);
