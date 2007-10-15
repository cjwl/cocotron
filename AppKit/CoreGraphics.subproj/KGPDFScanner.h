/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/KGPDFObject.h>

@class NSData,NSMutableArray;
@class KGPDFContentStream,KGPDFOperatorTable;
@class KGPDFString,KGPDFArray,KGPDFDictionary,KGPDFStream,KGPDFxref,KGPDFObject_identifier;

BOOL KGPDFScanBackwardsByLines(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,int delta);
BOOL KGPDFScanVersion(const char *bytes,unsigned length,KGPDFString **string);
BOOL KGPDFScanObject(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFObject **objectp);
BOOL KGPDFScanIdentifier(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFObject_identifier **identifier);
BOOL KGPDFScanInteger(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFInteger *value);

BOOL KGPDFParse_xref(NSData *data,KGPDFxref **xrefp);
BOOL KGPDFParseIndirectObject(NSData *data,KGPDFInteger position,KGPDFObject **objectp,KGPDFInteger number,KGPDFInteger generation,KGPDFxref *xref);

@interface KGPDFScanner : NSObject {
   NSMutableArray     *_stack;
   KGPDFContentStream *_stream;
   KGPDFOperatorTable *_operatorTable;
   void               *_info;
}

-initWithContentStream:(KGPDFContentStream *)stream operatorTable:(KGPDFOperatorTable *)operatorTable info:(void *)info;

-(KGPDFContentStream *)contentStream;

-(BOOL)popObject:(KGPDFObject **)value;
-(BOOL)popBoolean:(KGPDFBoolean *)value;
-(BOOL)popInteger:(KGPDFInteger *)value;
-(BOOL)popNumber:(KGPDFReal *)value;
-(BOOL)popName:(const char **)value;
-(BOOL)popString:(KGPDFString **)stringp;
-(BOOL)popArray:(KGPDFArray **)arrayp;
-(BOOL)popDictionary:(KGPDFDictionary **)dictionaryp;
-(BOOL)popStream:(KGPDFStream **)streamp;

-(BOOL)scan;

@end

