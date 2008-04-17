/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "KGPDFObject.h"

typedef enum {
 KGPDFIdentifierUnknown,
 KGPDFIdentifier_true,
 KGPDFIdentifier_false,
 KGPDFIdentifier_null,
 KGPDFIdentifier_f,
 KGPDFIdentifier_n,
 KGPDFIdentifier_R,
 KGPDFIdentifier_xref,
 KGPDFIdentifier_trailer,
 KGPDFIdentifier_startxref,
 KGPDFIdentifier_obj,
 KGPDFIdentifier_endobj,
 KGPDFIdentifier_stream,
 KGPDFIdentifier_endstream,
} KGPDFIdentifier;

KGPDFIdentifier KGPDFClassifyIdentifier(const char *bytes,unsigned length);

@interface KGPDFObject_identifier : KGPDFObject {
   KGPDFIdentifier _identifier;
   unsigned        _length;
   char           *_bytes;
}

+pdfObjectWithIdentifier:(KGPDFIdentifier)identifier name:(const char *)bytes length:(unsigned)length;

-(KGPDFIdentifier)identifier;

-(const char *)name;

@end

