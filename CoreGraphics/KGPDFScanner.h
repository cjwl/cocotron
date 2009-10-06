/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFObject.h"

@class NSData,NSMutableArray;
@class O2PDFContentStream,O2PDFOperatorTable;
@class O2PDFString,O2PDFArray,O2PDFDictionary,O2PDFStream,O2PDFxref,O2PDFObject_identifier;

BOOL O2PDFScanBackwardsByLines(const char *bytes,unsigned length,O2PDFInteger position,O2PDFInteger *lastPosition,int delta);
BOOL O2PDFScanVersion(const char *bytes,unsigned length,O2PDFString **string);
BOOL O2PDFScanObject(const char *bytes,unsigned length,O2PDFInteger position,O2PDFInteger *lastPosition,O2PDFObject **objectp);
BOOL O2PDFScanIdentifier(const char *bytes,unsigned length,O2PDFInteger position,O2PDFInteger *lastPosition,O2PDFObject_identifier **identifier);
BOOL O2PDFScanInteger(const char *bytes,unsigned length,O2PDFInteger position,O2PDFInteger *lastPosition,O2PDFInteger *value);

BOOL O2PDFParse_xref(NSData *data,O2PDFxref **xrefp);
BOOL O2PDFParseIndirectObject(NSData *data,O2PDFInteger position,O2PDFObject **objectp,O2PDFInteger number,O2PDFInteger generation,O2PDFxref *xref);

@interface O2PDFScanner : NSObject {
   NSMutableArray     *_stack;
   O2PDFContentStream *_stream;
   O2PDFOperatorTable *_operatorTable;
   void               *_info;
}

-initWithContentStream:(O2PDFContentStream *)stream operatorTable:(O2PDFOperatorTable *)operatorTable info:(void *)info;

-(O2PDFContentStream *)contentStream;

-(BOOL)popObject:(O2PDFObject **)value;
-(BOOL)popBoolean:(O2PDFBoolean *)value;
-(BOOL)popInteger:(O2PDFInteger *)value;
-(BOOL)popNumber:(O2PDFReal *)value;
-(BOOL)popName:(const char **)value;
-(BOOL)popString:(O2PDFString **)stringp;
-(BOOL)popArray:(O2PDFArray **)arrayp;
-(BOOL)popDictionary:(O2PDFDictionary **)dictionaryp;
-(BOOL)popStream:(O2PDFStream **)streamp;

-(BOOL)scan;

@end

