/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32RenderingContext.h>
#import <AppKit/Win32DeviceContextBitmap.h>
#import <AppKit/Win32DeviceContextPrinter.h>
#import <AppKit/Win32DeviceContextWindow.h>
#import <AppKit/Win32GraphicsContext.h>

@implementation Win32RenderingContext

-(CGContext *)graphicsContextWithTransform:(CGAffineTransform)transform clipRect:(NSRect)clipRect {
   return [[[Win32GraphicsContext alloc] initWithRenderingContext:self transform:transform clipRect:clipRect] autorelease];
}

-initWithWindowHandle:(HWND)handle {
   _color=[[Win32DeviceContextWindow alloc] initWithWindowHandle:handle];
   _alpha=nil;
   return self;
}

-initWithPixelSize:(NSSize)size compatibleWithContext:(Win32RenderingContext *)compatible {
   _color=[[Win32DeviceContextBitmap alloc] initWithSize:size deviceContext:[compatible colorContext]];
   _alpha=nil;
   return self;
}

-initWithPixelSize:(NSSize)size {
   _color=[[Win32DeviceContextBitmap alloc] initWithSize:size];
   _alpha=nil;
   return self;
}

-initWithPrinterName:(NSString *)name {
   _color=[[Win32DeviceContextPrinter alloc] initWithPrinterName:name];
   _alpha=nil;
   return self;
}

-initWithPrinterDC:(HDC)dc {
   _color=[[Win32DeviceContextPrinter alloc] initWithDC:dc];
   _alpha=nil;
   return self;
}

-(void)dealloc {
   [_color release];
   [_alpha release];
   [super dealloc];
}

-(Win32DeviceContext *)colorContext {
   return _color;
}

-(Win32DeviceContext *)alphaContext {
   return _alpha;
}

-(NSSize)size {
   NSSize result;

   result.width=GetDeviceCaps([_color dc],HORZRES);
   result.height=GetDeviceCaps([_color dc],VERTRES);

   return result;
}

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize {
   [_color selectFontWithName:name pointSize:pointSize];
}

-(void)copyColorsToContext:(Win32RenderingContext *)other size:(NSSize)size {
   [self copyColorsToContext:other size:size toPoint:NSMakePoint(0,0) fromPoint:NSMakePoint(0,0)];
}

-(void)copyColorsToContext:(Win32RenderingContext *)other size:(NSSize)size toPoint:(NSPoint)toPoint fromPoint:(NSPoint)fromPoint {
   BitBlt([[other colorContext] dc],toPoint.x,toPoint.y,size.width,size.height,[_color dc],fromPoint.x,fromPoint.y,SRCCOPY);
}

-(void)beginPage {
   [_color beginPage];
}

-(void)endPage {
   [_color endPage];
}

-(void)beginDocument {
   [_color beginDocument];
}

-(void)endDocument {
   [_color endDocument];
}

-(void)scalePage:(float)scalex:(float)scaley {
   HDC colorDC=[_color dc];
   int xmul=scalex*1000;
   int xdiv=1000;
   int ymul=scaley*1000;
   int ydiv=1000;

   int width=GetDeviceCaps(colorDC,HORZRES);
   int height=GetDeviceCaps(colorDC,VERTRES);

   SetWindowExtEx(colorDC,width,height,NULL);
   SetViewportExtEx(colorDC,width,height,NULL);

   ScaleWindowExtEx(colorDC,xdiv,xmul,ydiv,ymul,NULL);
}

@end
