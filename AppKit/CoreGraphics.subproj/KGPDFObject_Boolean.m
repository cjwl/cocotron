/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFObject_Boolean.h"
#import <Foundation/NSString.h>

@implementation KGPDFObject_Boolean

-initWithBoolean:(KGPDFBoolean)value {
   _value=value;
   return self;
}

+pdfObjectWithTrue {
   return [[[self alloc] initWithBoolean:YES] autorelease];
}

+pdfObjectWithFalse {
   return [[[self alloc] initWithBoolean:NO] autorelease];
}

-(KGPDFObjectType)objectType {
   return kKGPDFObjectTypeBoolean;
}

-(BOOL)checkForType:(KGPDFObjectType)type value:(void *)value {
   if(type!=kKGPDFObjectTypeBoolean)
    return NO;
   
   *((KGPDFBoolean *)value)=_value;
   return YES;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ %s>",isa,_value?"true":"false"];
}

@end
