/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Onyx2D/O2Context_builtin.h>
#import <windows.h>
#import <Onyx2D/O2GlyphStencil.h>

#ifdef __cplusplus
extern "C" {
#endif

@class Win32Font,O2DeviceContext_gdi,O2DeviceContext_gdiDIBSection;

@interface O2Context_builtin_gdi : O2Context_builtin {
   HDC        _dc;
   Win32Font *_gdiFont;
   int        _gdiDescent;
   O2Paint   *_textFillPaint;
   size_t             _glyphCacheCount;
   O2GlyphStencilRef *_glyphCache;
   
   int _scratchWidth;
   int _scratchHeight;
   O2DeviceContext_gdiDIBSection *_scratchContext;
   HDC _scratchDC;
   uint8_t *_scratchBitmap;
   Win32Font *_scratchFont;
}

-(O2DeviceContext_gdi *)deviceContext;

@end

#ifdef __cplusplus
}
#endif
