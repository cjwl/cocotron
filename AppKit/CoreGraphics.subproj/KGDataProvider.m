/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGDataProvider.h"
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSStream.h>
#import <string.h>

@implementation KGDataProvider

-initWithData:(NSData *)data {
   _data=[data retain];
   _isDirectAccess=YES;
   _bytes=[data bytes];
   _length=[data length];
   return self;
}

-initWithBytes:(const void *)bytes length:(size_t)length {
   _data=nil;
   _isDirectAccess=YES;
   _bytes=bytes;
   _length=length;
   return self;
}

-initWithFilename:(const char *)pathCString {
// why doesn't CGDataProvider use CFString's, ugh
   NSUInteger len=strlen(pathCString);
   _path=[[[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathCString length:len] copy];
   
   _isDirectAccess=NO;
   _bytes=NULL;
   _length=0;
   return self;
}

-(void)dealloc {
   [_data release];
   [super dealloc];
}

-(BOOL)isDirectAccess {
   return _isDirectAccess;
}

-(NSData *)data {
   return _data;
}

-(const void *)bytes {
   return _bytes;
}

-(size_t)length {
   return _length;
}

-(NSData *)copyData {
   if(_data!=nil)
    return [_data copy];
   else
    return [[NSData alloc] initWithContentsOfFile:_path]; 
}

@end
