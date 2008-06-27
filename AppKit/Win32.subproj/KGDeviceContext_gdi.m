/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/KGDeviceContext_gdi.h>

@implementation KGDeviceContext_gdi

-initWithDC:(HDC)dc {
   _dc=dc;
   return self;
}

-(HDC)dc {
   return _dc;
}

-(Win32DeviceContextWindow *)windowDeviceContext {
   return nil;
}

-(void)beginPrintingWithDocumentName:(NSString *)name {
   // do nothing
}

-(void)endPrinting {
   // do nothing
}

-(void)beginPage {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(unsigned)bitsPerPixel {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(NSSize)pixelsPerInch {
   [self doesNotRecognizeSelector:_cmd];
   return NSMakeSize(0,0);
}

-(NSSize)pixelSize {
   float pixelsWide=GetDeviceCaps(_dc,HORZRES);
   float pixelsHigh=GetDeviceCaps(_dc,VERTRES);
   
   return NSMakeSize(pixelsWide,pixelsHigh);
}

-(NSSize)pointSize {
   NSSize pixelPerInch=[self pixelsPerInch];
   NSSize pixelSize=[self pixelSize];

   float pointsWide=(pixelSize.width/pixelPerInch.width)*72.0;
   float pointsHigh=(pixelSize.height/pixelPerInch.height)*72.0;
   
   return NSMakeSize(pointsWide,pointsHigh);
}

-(NSRect)paperRect {
   NSRect result;
   
   result.size=[self pointSize];
   result.origin=NSMakePoint(0,0);
   
   return result;
}

-(NSRect)imageableRect {
   return [self paperRect];
}


@end
