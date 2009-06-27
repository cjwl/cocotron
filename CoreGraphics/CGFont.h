/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphicsExport.h>
#import <CoreGraphics/CGGeometry.h>

@class KGFont;

typedef KGFont *CGFontRef;

#ifndef WIN32
typedef uint32_t CGGlyph;
#else
typedef unsigned short CGGlyph;
#endif

COREGRAPHICS_EXPORT CGFontRef CGFontCreateWithFontName(NSString *name);
COREGRAPHICS_EXPORT CGFontRef CGFontRetain(CGFontRef self);
COREGRAPHICS_EXPORT void      CGFontRelease(CGFontRef self);

COREGRAPHICS_EXPORT NSString *CGFontCopyFullName(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetUnitsPerEm(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetAscent(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetDescent(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetLeading(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetCapHeight(CGFontRef self);
COREGRAPHICS_EXPORT int       CGFontGetXHeight(CGFontRef self);
COREGRAPHICS_EXPORT CGFloat   CGFontGetItalicAngle(CGFontRef self);
COREGRAPHICS_EXPORT CGFloat   CGFontGetStemV(CGFontRef self);
COREGRAPHICS_EXPORT CGRect    CGFontGetFontBBox(CGFontRef self);

COREGRAPHICS_EXPORT size_t    CGFontGetNumberOfGlyphs(CGFontRef self);
COREGRAPHICS_EXPORT BOOL      CGFontGetGlyphAdvances(CGFontRef self,const CGGlyph *glyphs,size_t count,int *advances);

COREGRAPHICS_EXPORT CGGlyph   CGFontGetGlyphWithGlyphName(CGFontRef self,NSString *name);
COREGRAPHICS_EXPORT NSString *CGFontCopyGlyphNameForGlyph(CGFontRef self,CGGlyph glyph);

COREGRAPHICS_EXPORT NSData   *CGFontCopyTableForTag(CGFontRef self,uint32_t tag);
