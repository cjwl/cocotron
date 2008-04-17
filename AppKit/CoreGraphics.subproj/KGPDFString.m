/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFString.h"
#import "KGPDFContext.h"
#import <Foundation/NSString.h>
#import <string.h>

@implementation KGPDFString

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
   return [[(KGPDFString *)[self alloc] initWithBytes:bytes length:length] autorelease];
}

+pdfObjectWithBytesNoCopyNoFree:(const char *)bytes length:(unsigned)length {
   return [[(KGPDFString *)[self alloc] initWithBytesNoCopyNoFree:bytes length:length] autorelease];
}

+pdfObjectWithCString:(const char *)cString {
   return [[(KGPDFString *)[self alloc] initWithBytes:cString length:strlen(cString)] autorelease];
}

+pdfObjectWithString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSISOLatin1StringEncoding];
   
   return [[(KGPDFString *)[self alloc] initWithBytes:[data bytes] length:[data length]] autorelease];
}

-(KGPDFObjectType)objectType {
   return kKGPDFObjectTypeString;
}

-(BOOL)checkForType:(KGPDFObjectType)type value:(void *)value {
   if(type!=kKGPDFObjectTypeString)
    return NO;
   
   *((KGPDFString **)value)=self;
   return YES;
}

-(unsigned)length {
   return _length;
}

-(const char *)bytes {
   return _bytes;
}

-(void)encodeWithPDFContext:(KGPDFContext *)encoder {
   [encoder appendPDFStringWithBytes:_bytes length:_length];
}

-(NSString *)description {
   char s[_length+1];
   
   strncpy(s,_bytes,_length);
   s[_length]='\0';
   return [NSString stringWithFormat:@"<%@ %s>",isa,s];
}

@end
