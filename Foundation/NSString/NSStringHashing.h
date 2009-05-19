/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSString.h>

#define NSHashStringLength 63

// djb2

static inline unsigned NSStringHashUnicode(const unichar *buffer,NSUInteger length){
   unsigned i,result=5381;

   for(i=0;i<length;i++)
    result=((result<<5)+result)+buffer[i]; // hash*33+c

   return result;
}

static inline unsigned NSStringHashASCII(const char *buffer,unsigned length){
   unsigned i,result=5381;

   for(i=0;i<length;i++)
    result=((result<<5)+result)+(unsigned)(buffer[i]); // hash*33+c

   return result;
}

static inline unsigned NSStringHashZeroTerminatedASCII(const char *buffer){
   unsigned i,result=5381;

   for(i=0;buffer[i]!='\0';i++)
    result=((result<<5)+result)+(unsigned)(buffer[i]); // hash*33+c

   return result;
}
