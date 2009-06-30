/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KGFont.h"
#import "KGExceptions.h"

@implementation KGFont

-initWithFontName:(NSString *)name {
   _name=[name copy];
   return self;
}

-(void)dealloc {
   [_name release];
   [super dealloc];
}

+(KGFont *)createWithFontName:(NSString *)name {
   return [[self alloc] initWithFontName:name];
}

-(NSData *)copyTableForTag:(uint32_t)tag {
   KGInvalidAbstractInvocation();
   return nil;
}

-(CGGlyph)glyphWithGlyphName:(NSString *)name {
   KGInvalidAbstractInvocation();
   return 0;
}

-(NSString *)copyGlyphNameForGlyph:(CGGlyph)glyph {
   KGInvalidAbstractInvocation();
   return nil;
}

-(void)fetchAdvances {
   KGInvalidAbstractInvocation();
}

O2FontRef O2FontCreateWithFontName(NSString *name) {
   return [[KGFont alloc] initWithFontName:name];
}

O2FontRef O2FontRetain(O2FontRef self) {
   return [self retain];
}

void      O2FontRelease(O2FontRef self) {
   [self release];
}


NSString *O2FontCopyFullName(O2FontRef self) {
   return [self->_name copy];
}

int       O2FontGetUnitsPerEm(O2FontRef self) {
   return self->_unitsPerEm;
}

int       O2FontGetAscent(O2FontRef self) {
   return self->_ascent;
}

int       O2FontGetDescent(O2FontRef self) {
   return self->_descent;
}

int       O2FontGetLeading(O2FontRef self) {
   return self->_leading;
}

int       O2FontGetCapHeight(O2FontRef self) {
   return self->_capHeight;
}

int       O2FontGetXHeight(O2FontRef self) {
   return self->_xHeight;
}

CGFloat   O2FontGetItalicAngle(O2FontRef self){
   return self->_italicAngle;
}

CGFloat   O2FontGetStemV(O2FontRef self) {
   return self->_stemV;
}

CGRect    O2FontGetFontBBox(O2FontRef self) {
   return self->_bbox;
}

size_t    O2FontGetNumberOfGlyphs(O2FontRef self) {
   return self->_numberOfGlyphs;
}

BOOL O2FontGetGlyphAdvances(O2FontRef self,const CGGlyph *glyphs,size_t count,int *advances) {
   size_t i;
   
   if(self->_advances==NULL)
    [self fetchAdvances];
    
   for(i=0;i<count;i++){
    CGGlyph glyph=glyphs[i];
    
    if(glyph<self->_numberOfGlyphs)
     advances[i]=self->_advances[glyph];
    else
     advances[i]=0;
   }
   return YES;
}

CGGlyph   O2FontGetGlyphWithGlyphName(O2FontRef self,NSString *name) {
   return [self glyphWithGlyphName:name];
}

NSString *O2FontCopyGlyphNameForGlyph(O2FontRef self,CGGlyph glyph) {
   return [self copyGlyphNameForGlyph:glyph];
}

NSData   *O2FontCopyTableForTag(O2FontRef self,uint32_t tag) {
   return [self copyTableForTag:(uint32_t)tag];
}

@end
