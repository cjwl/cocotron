/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFObject.h"
#import <ApplicationServices/ApplicationServices.h>

@class KGPDFString,KGPDFArray,KGPDFDictionary,KGPDFStream;

@interface KGPDFArray : KGPDFObject {
   unsigned      _capacity;
   unsigned      _count;
   KGPDFObject **_objects;
}

+(KGPDFArray *)pdfArray;
+(KGPDFArray *)pdfArrayWithRect:(CGRect)rect;
+(KGPDFArray *)pdfArrayWithNumbers:(KGPDFReal *)values count:(unsigned)count;
+(KGPDFArray *)pdfArrayWithIntegers:(KGPDFInteger *)values count:(unsigned)count;

-(unsigned)count;

-(void)addObject:(KGPDFObject *)anObject;
-(void)addNumber:(KGPDFReal)value;
-(void)addInteger:(KGPDFInteger)value;
-(void)addBoolean:(KGPDFBoolean)value;

-(KGPDFObject *)objectAtIndex:(unsigned)index;

-(BOOL)getObjectAtIndex:(unsigned)index value:(KGPDFObject **)objectp;
-(BOOL)getNullAtIndex:(unsigned)index;
-(BOOL)getBooleanAtIndex:(unsigned)index value:(KGPDFBoolean *)valuep;
-(BOOL)getIntegerAtIndex:(unsigned)index value:(KGPDFInteger *)valuep;
-(BOOL)getNumberAtIndex:(unsigned)index value:(KGPDFReal *)valuep;
-(BOOL)getNameAtIndex:(unsigned)index value:(const char **)namep;
-(BOOL)getStringAtIndex:(unsigned)index value:(KGPDFString **)stringp;
-(BOOL)getArrayAtIndex:(unsigned)index value:(KGPDFArray **)arrayp;
-(BOOL)getDictionaryAtIndex:(unsigned)index value:(KGPDFDictionary **)dictionaryp;
-(BOOL)getStreamAtIndex:(unsigned)index value:(KGPDFStream **)streamp;

-(BOOL)getNumbers:(KGPDFReal **)numbersp count:(unsigned *)count;

@end
