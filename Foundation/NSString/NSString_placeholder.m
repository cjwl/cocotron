/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSString_placeholder.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSString_unicode.h>
#import <Foundation/NSString_unicodePtr.h>
#import <Foundation/NSUnicodeCaseMapping.h>
#import <Foundation/NSString_nextstep.h>
#import <Foundation/NSString_isoLatin1.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSStringFileIO.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSStringUTF8.h>
#import <Foundation/NSStringSymbol.h>

#import <Foundation/NSData.h>
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation NSString_placeholder

-init {
   NSDeallocateObject(self);
   return @"";
}

-initWithCharactersNoCopy:(unichar *)characters length:(unsigned)length
             freeWhenDone:(BOOL)freeWhenDone {
   NSDeallocateObject(self);

   if(freeWhenDone)
    return NSString_unicodePtrNewNoCopy(NULL,characters,length);
   else
    return NSString_unicodeNew(NULL,characters,length);
}

-initWithCharacters:(const unichar *)characters length:(unsigned)length {
   NSDeallocateObject(self);
   return NSString_unicodeNew(NULL,characters,length);
}

-initWithCStringNoCopy:(char *)bytes length:(unsigned)length
          freeWhenDone:(BOOL)freeWhenDone {
   NSString *string=NSString_cStringNewWithBytes(NULL,bytes,length);

   NSDeallocateObject(self);

   if(freeWhenDone)
    NSZoneFree(NSZoneFromPointer(bytes),bytes);

   return string;
}

-initWithCString:(const char *)bytes length:(unsigned)length {
   NSDeallocateObject(self);

   return NSString_cStringNewWithBytes(NULL,bytes,length);
}

-initWithCString:(const char *)bytes {
   NSDeallocateObject(self);

   return NSString_cStringNewWithBytes(NULL,bytes,strlen(bytes));
}

-initWithString:(NSString *)string {
   unsigned length=[string length];
   unichar *unicode=NSZoneMalloc(NULL,sizeof(unichar)*length);

   [string getCharacters:unicode];

   NSDeallocateObject(self);

   return NSString_unicodePtrNewNoCopy(NULL,unicode,length);
}

-initWithFormat:(NSString *)format,... {
   va_list arguments;

   va_start(arguments,format);

   NSDeallocateObject(self);

   return NSStringNewWithFormat(format,nil,arguments,NULL);
}

-initWithFormat:(NSString *)format arguments:(va_list)arguments {
   NSDeallocateObject(self);

   return NSStringNewWithFormat(format,nil,arguments,NULL);
}

-initWithFormat:(NSString *)format locale:(NSDictionary *)locale,... {
   va_list arguments;

   va_start(arguments,locale);

   NSDeallocateObject(self);

   return NSStringNewWithFormat(format,locale,arguments,NULL);
}

-initWithFormat:(NSString *)format
             locale:(NSDictionary *)locale arguments:(va_list)arguments {
   NSDeallocateObject(self);

   return NSStringNewWithFormat(format,locale,arguments,NULL);
}

-initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
   NSDeallocateObject(self);

   if(encoding==NSString_cStringEncoding)
    return NSString_cStringNewWithBytes(NULL,[data bytes],[data length]);

   switch(encoding){

    case NSUnicodeStringEncoding:{
      unsigned length;
      unichar *characters=NSUnicodeFromData(data,&length);

      return NSString_unicodePtrNewNoCopy(NULL,characters,length);
     }

    case NSNEXTSTEPStringEncoding:
     return NSNEXTSTEPStringNewWithBytes(NULL,[data bytes],[data length]);

// FIX, not nextstep
    case NSASCIIStringEncoding:
     return NSNEXTSTEPStringNewWithBytes(NULL,[data bytes],[data length]);

    case NSISOLatin1StringEncoding:
     return NSString_isoLatin1NewWithBytes(NULL,[data bytes],[data length]);

    case NSSymbolStringEncoding:{
      unsigned length;
      unichar *characters=NSSymbolToUnicode([data bytes],[data length],&length,NULL);

      return NSString_unicodePtrNewNoCopy(NULL,characters,length);
     }
     break;

    case NSUTF8StringEncoding:{
      unsigned length;
      unichar *characters;

      characters=NSUTF8ToUnicode([data bytes],[data length],&length,NULL);

      return NSString_unicodePtrNewNoCopy(NULL,characters,length);
     }
     break;

    case NSUTF16BigEndianStringEncoding:{
      unsigned length;
      unichar *characters=NSUnicodeFromDataUTF16BigEndian(data,&length);

      return NSString_unicodePtrNewNoCopy(NULL,characters,length);
     }
     break;
     
    default:
 
     break;
   }

   NSInvalidAbstractInvocation();
   return nil;
}

-initWithUTF8String:(const char *)utf8 {
   unsigned length;
   unichar *characters;

   characters=NSUTF8ToUnicode(utf8,strlen(utf8),&length,NULL);

   return NSString_unicodePtrNewNoCopy(NULL,characters,length);
}

-initWithContentsOfFile:(NSString *)path {
   unsigned  length;
   unichar  *unicode;

   NSDeallocateObject(self);

   if((unicode=NSCharactersWithContentsOfFile(path,&length,NULL))==NULL)
    return nil;

   return NSString_unicodePtrNewNoCopy(NULL,unicode,length);
}

@end
