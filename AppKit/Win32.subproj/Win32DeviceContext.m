/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32DeviceContext.h>
#import <AppKit/Win32DeviceContextWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/Win32Font.h>
#import <AppKit/Win32Application.h>

@implementation Win32DeviceContext

-initWithDC:(HDC)dc {
   _dc=dc;

   if(SetMapMode(_dc,MM_ANISOTROPIC)==0)
    NSLog(@"SetMapMode failed");

   //SetICMMode(_dc,ICM_ON); MSDN says only available on 2000, not NT.

   SetBkMode(_dc,TRANSPARENT);
   SetTextAlign(_dc,TA_BASELINE);

#if 0
   if(_useAdvanced){
    if(SetGraphicsMode(_dc,GM_ADVANCED)==0)
     NSLog(@"SetGraphicsMode(_dc,GM_ADVANCED) failed");
   }
#endif

   _font=nil;
   return self;
}

-(void)dealloc {
   [_font release];
   [super dealloc];
}

-(HDC)dc {
   return _dc;
}

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize {
   int height=(pointSize*GetDeviceCaps(_dc,LOGPIXELSY))/72.0;

   [_font release];
   _font=[[Win32Font alloc] initWithName:name size:NSMakeSize(0,height)];
   SelectObject(_dc,[_font fontHandle]);
}

-(Win32Font *)currentFont {
   return _font;
}

+(Win32DeviceContext *)deviceContextForWindowHandle:(HWND)handle {
   return [[[Win32DeviceContextWindow alloc] initWithWindowHandle:handle] autorelease];
}

-(BOOL)isPrinter {
   return NO;
}

-(void)beginPage {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(void)beginDocument {
   // do nothing
}

-(void)endDocument {
   // do nothing
}

@end
