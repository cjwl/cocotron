/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSInputStream_data.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRaise.h>

@implementation NSInputStream_data

-initWithData:(NSData *)data {
   _data=[data retain];
   _position=0;
   return self;
}

-(void)dealloc {
   [_data release];
   [super dealloc];
}

-(BOOL)getBuffer:(unsigned char **)buffer length:(unsigned *)length {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)hasBytesAvailable {
   return _position<[_data length];
}

-(int)read:(unsigned char *)buffer maxLength:(unsigned)maxLength {
   const unsigned char *bytes=[_data bytes];
   unsigned i,length=[_data length];
   
   for(i=0;_position<length;i++,_position++)
    buffer[i]=bytes[_position];
    
   return i;
}


@end
