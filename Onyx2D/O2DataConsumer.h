/* Copyright (c) 2009 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFURL.h>

@class O2DataConsumer;
typedef O2DataConsumer *O2DataConsumerRef;

@interface O2DataConsumer : NSObject {
   NSMutableData *_data;
   size_t         _position;
}

-(NSMutableData *)mutableData;

O2DataConsumerRef O2DataConsumerCreateWithCFData(CFMutableDataRef data);
O2DataConsumerRef O2DataConsumerCreateWithURL(CFURLRef url);
O2DataConsumerRef O2DataConsumerRetain(O2DataConsumerRef self);
void O2DataConsumerRelease(O2DataConsumerRef self);

// private internal use
size_t O2DataConsumerPutBytes(O2DataConsumerRef self,const void *buffer,size_t count);

@end

