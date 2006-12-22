/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSObjCRuntime.h>

@class NSArray,NSData,NSDictionary,NSCharacterSet;

typedef unsigned short unichar;

typedef enum {
   NSUnicodeStringEncoding,
   NSASCIIStringEncoding,
   NSNEXTSTEPStringEncoding,
   NSEUCStringEncoding,
   NSUTFStringEncoding,
   NSISOLatin1StringEncoding,
   NSSymbolStringEncoding,
   NSNonLossyASCIIStringEncoding,
   NSShiftJISStringEncoding,
   NSUTF8StringEncoding
} NSStringEncoding;

enum {
   NSCaseInsensitiveSearch=0x01,
   NSLiteralSearch=0x02,
   NSBackwardsSearch=0x04,
   NSAnchoredSearch=0x08
};

FOUNDATION_EXPORT const unsigned NSMaximumStringLength;

@interface NSString : NSObject <NSCopying,NSMutableCopying,NSCoding>

-initWithCharactersNoCopy:(unichar *)unicode length:(unsigned)length
             freeWhenDone:(BOOL)freeBuffer;
-initWithCharacters:(const unichar *)unicode length:(unsigned)length;
-init;

-initWithCStringNoCopy:(char *)cString length:(unsigned)length
          freeWhenDone:(BOOL)freeBuffer;
-initWithCString:(const char *)cString length:(unsigned)length;
-initWithCString:(const char *)cString;

-initWithString:(NSString *)string;

-initWithFormat:(NSString *)format locale:(NSDictionary *)locale
      arguments:(va_list)arguments;
-initWithFormat:(NSString *)format locale:(NSDictionary *)locale,...;
-initWithFormat:(NSString *)format arguments:(va_list)arguments;
-initWithFormat:(NSString *)format,...;

-initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

-initWithContentsOfFile:(NSString *)path;

+stringWithCharacters:(const unichar *)unicode length:(unsigned)length;
+string;
+stringWithCString:(const char *)cString length:(unsigned)length;
+stringWithCString:(const char *)cString;
+stringWithString:(NSString *)string;
+stringWithFormat:(NSString *)format,...;
+stringWithContentsOfFile:(NSString *)path;
+localizedStringWithFormat:(NSString *)format,...;

-(unichar)characterAtIndex:(unsigned)location;
-(unsigned)length;

-(void)getCharacters:(unichar *)buffer range:(NSRange)range;
-(void)getCharacters:(unichar *)buffer;

-(NSComparisonResult)compare:(NSString *)string options:(unsigned)options;
-(NSComparisonResult)compare:(NSString *)string;
-(NSComparisonResult)caseInsensitiveCompare:(NSString *)string;

-(BOOL)isEqualToString:(NSString *)string;

-(BOOL)hasPrefix:(NSString *)string;
-(BOOL)hasSuffix:(NSString *)string;
-(NSRange)rangeOfString:(NSString *)string options:(unsigned)options range:(NSRange)range;
-(NSRange)rangeOfString:(NSString *)string options:(unsigned)options;
-(NSRange)rangeOfString:(NSString *)string;

-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set
   options:(unsigned)options range:(NSRange)range;
-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set
   options:(unsigned)options;
-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set;

-(void)getLineStart:(unsigned *)startp end:(unsigned *)endp contentsEnd:(unsigned *)contentsEndp forRange:(NSRange)range;
-(NSRange)lineRangeForRange:(NSRange)range;

-(NSString *)substringWithRange:(NSRange)range;
-(NSString *)substringFromIndex:(unsigned)location;
-(NSString *)substringToIndex:(unsigned)location;

-(int)intValue;
-(float)floatValue;
-(double)doubleValue;

-(NSString *)lowercaseString;
-(NSString *)uppercaseString;
-(NSString *)capitalizedString;

-(NSString *)stringByAppendingFormat:(NSString *)format,...;
-(NSString *)stringByAppendingString:(NSString *)string;

-(NSArray *)componentsSeparatedByString:(NSString *)separator;

-propertyList;
-(NSDictionary *)propertyListFromStringsFileFormat;

-(BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;

-(BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding;

-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding
        allowLossyConversion:(BOOL)lossy;
-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding;

+(NSStringEncoding)defaultCStringEncoding;

-(void)getCString:(char *)buffer maxLength:(unsigned)maxLength
            range:(NSRange)range remainingRange:(NSRange *)remainingRange;
-(void)getCString:(char *)buffer maxLength:(unsigned)maxLength;
-(void)getCString:(char *)buffer;

-(unsigned)cStringLength;
-(const char *)cString;
-(const char *)lossyCString;

@end

@interface NSConstantString : NSString {
    char    *_bytes;
    unsigned _length;
}
@end

#import <Foundation/NSMutableString.h>

