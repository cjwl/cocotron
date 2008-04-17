/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGPDFArray,KGPDFDictionary,KGPDFObject,KGPDFContext;

@interface KGFunction : NSObject {
   void               *_info;
   unsigned            _domainCount;
   float              *_domain;
   unsigned            _rangeCount;
   float              *_range;
   CGFunctionCallbacks _callbacks;
}

-initWithDomain:(KGPDFArray *)domain range:(KGPDFArray *)range;
-initWithInfo:(void *)info domainCount:(unsigned)domainCount domain:(const float *)domain rangeCount:(unsigned)rangeCount range:(const float *)range callbacks:(const CGFunctionCallbacks *)callbacks;

-(unsigned)domainCount;
-(const float *)domain;
-(unsigned)rangeCount;
-(const float *)range;

-(BOOL)isLinear;

// FIX, only works for one input value
-(void)evaluateInput:(float)x output:(float *)outp;

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGFunction *)pdfFunctionWithDictionary:(KGPDFDictionary *)dictionary;

@end
