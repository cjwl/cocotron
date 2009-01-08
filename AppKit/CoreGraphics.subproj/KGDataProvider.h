/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSData,NSInputStream,NSURL;

@interface KGDataProvider : NSObject {
   NSInputStream *_inputStream;
   NSData        *_data;
   NSString      *_path;
   BOOL           _isDirectAccess;
   const void    *_bytes;
   size_t         _length;
}

-initWithData:(NSData *)data;
-initWithBytes:(const void *)bytes length:(size_t)length;
-initWithFilename:(const char *)pathCString;
-initWithURL:(NSURL *)url;

-(BOOL)isDirectAccess;

-(NSString *)path;

-(NSData *)data;
-(const void *)bytes;
-(size_t)length;

-(NSInteger)getBytes:(void *)bytes range:(NSRange)range;

-(NSData *)copyData;

@end
