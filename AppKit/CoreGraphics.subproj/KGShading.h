/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class KGColorSpace,KGFunction,KGPDFObject,KGPDFContext;

@interface KGShading : NSObject {
   KGColorSpace *_colorSpace;
   NSPoint       _startPoint;
   NSPoint       _endPoint;
   KGFunction   *_function;
   BOOL          _extendStart;
   BOOL          _extendEnd;
   BOOL          _isRadial;
   float         _startRadius;
   float         _endRadius;
}

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd;

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint startRadius:(float)startRadius endPoint:(NSPoint)endPoint endRadius:(float)endRadius function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd;

-(KGColorSpace *)colorSpace;

-(NSPoint)startPoint;
-(NSPoint)endPoint;

-(float)startRadius;
-(float)endRadius;

-(BOOL)extendStart;
-(BOOL)extendEnd;

-(KGFunction *)function;

-(BOOL)isAxial;

-(KGPDFObject *)pdfObjectInContext:(KGPDFContext *)context;
+(KGShading *)shadingWithPDFObject:(KGPDFObject *)object;

@end
