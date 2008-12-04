/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <ApplicationServices/CoreGraphicsExport.h>
#import <ApplicationServices/CGAffineTransform.h>
#import <ApplicationServices/CGFont.h>

@class KTFont;

typedef KTFont *CTFontRef;

COREGRAPHICS_EXPORT CTFontRef CTFontCreateWithGraphicsFont(CGFontRef cgFont,CGFloat size,CGAffineTransform *xform,id attributes);

COREGRAPHICS_EXPORT size_t  CTFontGetGlyphCount(CTFontRef self);
COREGRAPHICS_EXPORT BOOL    CTFontGetGlyphsForCharacters(CTFontRef self,const unichar *characters,CGGlyph *glyphs,size_t count);
COREGRAPHICS_EXPORT CGRect  CTFontGetBoundingBox(CTFontRef self);
COREGRAPHICS_EXPORT void    CTFontGetAdvancesForGlyphs(CTFontRef self,int orientation,const CGGlyph *glyphs,CGSize *advances,size_t count);
COREGRAPHICS_EXPORT CGFloat CTFontGetUnderlinePosition(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetUnderlineThickness(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetAscent(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetDescent(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetLeading(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetSlantAngle(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetXHeight(CTFontRef self);
COREGRAPHICS_EXPORT CGFloat CTFontGetCapHeight(CTFontRef self);

