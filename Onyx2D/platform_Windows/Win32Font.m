/* Copyright (c) 2006-2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/Win32Font.h>

#ifndef CLEARTYPE_QUALITY
#define CLEARTYPE_QUALITY 5
#endif

#ifndef CLEARTYPE_NATURAL_QUALITY
#define CLEARTYPE_NATURAL_QUALITY 6
#endif


@implementation Win32Font

static BOOL g_disableAntialias = NO;

+ (void)setAntialiasDisabled:(BOOL)f {
    g_disableAntialias = f;
}

-initWithName:(NSString *)name height:(int)height antialias:(BOOL)antialias {
   NSUInteger length=[name length];
   unichar    buffer[length+1];
   
   [name getCharacters:buffer];
   buffer[length]=0x0000;
   
   long quality = antialias?CLEARTYPE_QUALITY:DEFAULT_QUALITY;
   
   // in Win32, "antialiased" apparently means the Win98-style AA where only large pixel sizes are antialiased.
   // hence passing this flag will result in the old rendering.
   if (g_disableAntialias) quality = ANTIALIASED_QUALITY;
   
   _handle=CreateFontW(height,0,0,0,FW_NORMAL,
     FALSE,FALSE,FALSE,
     DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,
     quality,
     DEFAULT_PITCH|FF_DONTCARE,buffer);
   return self;
}

-(void)dealloc {
   DeleteObject(_handle);
   NSDeallocateObject(self);
   return;
   [super dealloc];
}

-(HFONT)fontHandle {
   return _handle;
}

@end
