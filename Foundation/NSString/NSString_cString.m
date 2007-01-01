/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSString_nextstepCString.h>
#import <Foundation/NSAutoreleasePool-private.h>

NSStringEncoding NSString_cStringEncoding=NSNEXTSTEPStringEncoding;

unichar *NSCharactersFromCString(const char *cString,unsigned length,
  unsigned *resultLength,NSZone *zone) {
   return NSNEXTSTEPToUnicode(cString,length,resultLength,zone);
}

char    *NSString_cStringFromCharacters(const unichar *characters,unsigned length,
  BOOL lossy,unsigned *resultLength,NSZone *zone) {
   return NSUnicodeToNEXTSTEP(characters,length,lossy,resultLength,zone);
}

unsigned NSGetCStringWithMaxLength(const unichar *characters,unsigned length,unsigned *location,char *cString,unsigned maxLength,BOOL lossy){
   return NSGetNEXTSTEPStringWithMaxLength(characters,length,location,cString,maxLength,lossy);
}

NSString *NSString_cStringNewWithBytesAndZero(NSZone *zone,const char *bytes) {
   int length=0;

   while(bytes[length]!='\0')
    length++;

   return NSString_cStringNewWithBytes(zone,bytes,length);
}

NSString *NSString_cStringNewWithBytes(NSZone *zone,
 const char *bytes,unsigned length) {
   return NSNEXTSTEPCStringNewWithBytes(zone,bytes,length);
}

NSString *NSString_cStringNewWithCharacters(NSZone *zone,
 const unichar *characters,unsigned length,BOOL lossy) {
   return NSNEXTSTEPCStringNewWithCharacters(zone,characters,length,lossy);
}

NSString *NSString_cStringNewWithCapacity(NSZone *zone,unsigned capacity,char **ptr) {
   return NSNEXTSTEPCStringNewWithCapacity(zone,capacity,ptr);
}

NSString *NSString_cStringWithBytesAndZero(NSZone *zone,const char *bytes) {
   return NSAutorelease(NSString_cStringNewWithBytesAndZero(zone,bytes));
}
