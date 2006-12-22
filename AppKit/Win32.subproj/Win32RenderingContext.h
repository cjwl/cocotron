/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/CGRenderingContext.h>
#import <windows.h>

@class Win32DeviceContext;

@interface Win32RenderingContext : CGRenderingContext {
   Win32DeviceContext *_color;
   Win32DeviceContext *_alpha;
}

-initWithWindowHandle:(HWND)handle;
-initWithPixelSize:(NSSize)size compatibleWithContext:(Win32RenderingContext *)compatible;
-initWithPixelSize:(NSSize)size;
-initWithPrinterName:(NSString *)name;
-initWithPrinterDC:(HDC)dc;

-(Win32DeviceContext *)colorContext;
-(Win32DeviceContext *)alphaContext;

-(NSSize)size;

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize;

-(void)copyColorsToContext:(Win32RenderingContext *)other size:(NSSize)size;
-(void)copyColorsToContext:(Win32RenderingContext *)other size:(NSSize)size toPoint:(NSPoint)toPoint fromPoint:(NSPoint)fromPoint;

-(void)beginPage;
-(void)endPage;
-(void)beginDocument;
-(void)endDocument;

-(void)scalePage:(float)scalex:(float)scaley;

@end
