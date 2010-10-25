/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2PDFString.h>
#import <Onyx2D/O2PDFContext.h>
#import <Foundation/NSString.h>
#import <string.h>

@implementation O2PDFString

-initWithBytes:(const char *)bytes length:(unsigned)length {
   _length=length;
   _noCopyNoFree=NO;
   _bytes=NSZoneMalloc(NULL,length);
   strncpy(_bytes,bytes,length);
   return self;
}

-initWithBytesNoCopyNoFree:(const char *)bytes length:(unsigned)length {
   _length=length;
   _noCopyNoFree=YES;
   _bytes=(char *)bytes;
   return self;
}

-(void)dealloc {
   if(!_noCopyNoFree)
    NSZoneFree(NULL,_bytes);
   [super dealloc];
}

+pdfObjectWithBytes:(const char *)bytes length:(unsigned)length {
   return [[(O2PDFString *)[self alloc] initWithBytes:bytes length:length] autorelease];
}

+pdfObjectWithBytesNoCopyNoFree:(const char *)bytes length:(unsigned)length {
   return [[(O2PDFString *)[self alloc] initWithBytesNoCopyNoFree:bytes length:length] autorelease];
}

+pdfObjectWithCString:(const char *)cString {
   return [[(O2PDFString *)[self alloc] initWithBytes:cString length:strlen(cString)] autorelease];
}

+pdfObjectWithString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSISOLatin1StringEncoding];
   
   return [[(O2PDFString *)[self alloc] initWithBytes:[data bytes] length:[data length]] autorelease];
}

-(O2PDFObjectType)objectType {
   return kO2PDFObjectTypeString;
}

-(BOOL)checkForType:(O2PDFObjectType)type value:(void *)value {
   if(type!=kO2PDFObjectTypeString)
    return NO;
   
   *((O2PDFString **)value)=self;
   return YES;
}

-(unsigned)length {
   return _length;
}

-(const char *)bytes {
   return _bytes;
}

size_t O2PDFStringGetLength(O2PDFStringRef string) {
   return string->_length;
}

const unsigned char *O2PDFStringGetBytePtr(O2PDFStringRef string) {
   return string->_bytes;
}


-(void)encodeWithPDFContext:(O2PDFContext *)encoder {
   [encoder appendPDFStringWithBytes:_bytes length:_length];
}

-(NSString *)description {
   char s[_length+1];
   
   strncpy(s,_bytes,_length);
   s[_length]='\0';
   return [NSString stringWithFormat:@"<%@ %s>",isa,s];
}

@end
