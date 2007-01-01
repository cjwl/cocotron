/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import <Foundation/NSString.h>

FOUNDATION_EXPORT NSStringEncoding NSString_cStringEncoding;

unichar *NSCharactersFromCString(const char *cString,unsigned length,
  unsigned *resultLength,NSZone *zone);

char    *NSString_cStringFromCharacters(const unichar *characters,unsigned length,
  BOOL lossy,unsigned *resultLength,NSZone *zone);

unsigned NSGetCStringWithMaxLength(const unichar *characters,unsigned length,unsigned *location,char *cString,unsigned maxLength,BOOL lossy);

NSString *NSString_cStringNewWithBytesAndZero(NSZone *zone,const char *bytes);

NSString *NSString_cStringNewWithBytes(NSZone *zone,
 const char *bytes,unsigned length);

NSString *NSString_cStringNewWithCharacters(NSZone *zone,
 const unichar *characters,unsigned length,BOOL lossy);

NSString *NSString_cStringNewWithCapacity(NSZone *zone,unsigned capacity,char **ptr);


NSString *NSString_cStringWithBytesAndZero(NSZone *zone,const char *bytes);
