/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


typedef struct __NSMutableString *CFStringRef;
typedef struct __NSMutableString *CFMutableStringRef;

#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFArray.h>
#import <CoreFoundation/CFDictionary.h>
#import <CoreFoundation/CFLocale.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFCharacterSet.h>

typedef CFOptionFlags CFStringCompareFlags;

typedef CFUInteger CFStringEncoding;

enum {
   kCFCompareCaseInsensitive     = (1<<0),
   // no 2
   kCFCompareBackwards           = (1<<2),
   kCFCompareAnchored            = (1<<3),
   kCFCompareNonliteral          = (1<<4),
   kCFCompareLocalized           = (1<<5),
   kCFCompareNumerically         = (1<<6),
   kCFCompareDiacriticInsensitive= (1<<7),
   kCFCompareWidthInsensitive    = (1<<8),
   kCFCompareForcedOrdering      = (1<<9),
};

typedef enum  {
   kCFStringEncodingUTF8         = 0x08000100,
   kCFStringEncodingUTF16        = 0x00000100,
   kCFStringEncodingUTF16BE      = 0x10000100,
   kCFStringEncodingUTF16LE      = 0x14000100,
   kCFStringEncodingUTF32        = 0x0c000100,
   kCFStringEncodingUTF32BE      = 0x18000100,
   kCFStringEncodingUTF32LE      = 0x1c000100,

   kCFStringEncodingMacRoman     = 0,
   kCFStringEncodingWindowsLatin1= 0x0500,
   kCFStringEncodingISOLatin1    = 0x0201,
   kCFStringEncodingNextStepLatin= 0x0B01,
   kCFStringEncodingASCII        = 0x0600,
   kCFStringEncodingUnicode      = kCFStringEncodingUTF16,
   kCFStringEncodingNonLossyASCII= 0x0BFF,
} CFStringBuiltInEncodings;

typedef struct CFStringInlineBuffer {
  int nothing;
} CFStringInlineBuffer;

CFTypeID CFStringGetTypeID(void);

CFStringEncoding CFStringGetSystemEncoding(void);
const CFStringEncoding *CFStringGetListOfAvailableEncodings(void);
Boolean          CFStringIsEncodingAvailable(CFStringEncoding encoding);
CFStringRef      CFStringGetNameOfEncoding(CFStringEncoding encoding);
CFStringEncoding CFStringGetMostCompatibleMacStringEncoding(CFStringEncoding encoding);
CFIndex CFStringGetMaximumSizeForEncoding(CFIndex length,CFStringEncoding encoding);

#ifdef __OBJC__
#define CFSTR(s) (NSString*)(@##s)
#else

#define CFSTR(s) CFStringMakeConstant(const char *s);
#endif

CFStringRef CFStringCreateByCombiningStrings(CFAllocatorRef allocator,CFArrayRef array,CFStringRef separator);
CFStringRef CFStringCreateCopy(CFAllocatorRef allocator,CFStringRef self);
CFStringRef CFStringCreateWithBytes(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation);
CFStringRef CFStringCreateWithBytesNoCopy(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation,CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef allocator,const UniChar *chars,CFIndex length);
CFStringRef CFStringCreateWithCharactersNoCopy(CFAllocatorRef allocator,const UniChar *chars,CFIndex length,CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithCString(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding);
CFStringRef CFStringCreateWithCStringNoCopy(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding,CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithFileSystemRepresentation(CFAllocatorRef allocator,const char *buffer);
CFStringRef CFStringCreateWithFormat(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,...);
CFStringRef CFStringCreateWithFormatAndArguments(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,va_list arguments);
CFStringRef CFStringCreateFromExternalRepresentation(CFAllocatorRef allocator,CFDataRef data,CFStringEncoding encoding);

CFStringRef CFStringCreateWithSubstring(CFAllocatorRef allocator,CFStringRef self,CFRange range);

void CFShow(CFTypeRef self);
void CFShowStr(CFStringRef self);


CFComparisonResult CFStringCompare(CFStringRef self,CFStringRef other,CFOptionFlags options);
CFComparisonResult CFStringCompareWithOptions(CFStringRef self,CFStringRef other,CFRange rangeToCompare,CFOptionFlags options);
CFComparisonResult CFStringCompareWithOptionsAndLocale(CFStringRef self,CFStringRef other,CFRange rangeToCompare,CFOptionFlags options,CFLocaleRef locale);

CFStringRef CFStringConvertEncodingToIANACharSetName(CFStringEncoding encoding);
CFUInteger CFStringConvertEncodingToNSStringEncoding(CFStringEncoding encoding);
CFUInteger CFStringConvertEncodingToWindowsCodepage(CFStringEncoding encoding);

CFStringEncoding CFStringConvertIANACharSetNameToEncoding(CFStringRef self);
CFStringEncoding CFStringConvertNSStringEncodingToEncoding(CFUInteger encoding);
CFStringEncoding CFStringConvertWindowsCodepageToEncoding(CFUInteger codepage);
CFArrayRef       CFStringCreateArrayBySeparatingStrings(CFAllocatorRef allocator,CFStringRef self,CFStringRef separatorString);
CFArrayRef       CFStringCreateArrayWithFindResults(CFAllocatorRef allocator,CFStringRef self,CFStringRef stringToFind,CFRange range,CFOptionFlags options);
CFDataRef        CFStringCreateExternalRepresentation(CFAllocatorRef allocator,CFStringRef self,CFStringEncoding encoding,uint8_t lossByte);

Boolean          CFStringHasPrefix(CFStringRef self,CFStringRef prefix);
Boolean          CFStringHasSuffix(CFStringRef self,CFStringRef suffix);
CFRange          CFStringFind(CFStringRef self,CFStringRef stringToFind,CFOptionFlags options);
Boolean          CFStringFindCharacterFromSet(CFStringRef self,CFCharacterSetRef set,CFRange range,CFOptionFlags options,CFRange *result);
Boolean          CFStringFindWithOptions(CFStringRef self,CFStringRef stringToFind,CFRange range,CFOptionFlags options,CFRange *result);
Boolean          CFStringFindWithOptionsAndLocale(CFStringRef self,CFStringRef stringToFind,CFRange range,CFOptionFlags options,CFLocaleRef locale,CFRange *result);
CFIndex          CFStringGetBytes(CFStringRef self,CFRange range,CFStringEncoding encoding,uint8_t lossByte,Boolean isExternalRepresentation,uint8_t *bytes,CFIndex length,CFIndex *resultLength);

CFIndex          CFStringGetLength(CFStringRef self);
UniChar          CFStringGetCharacterAtIndex(CFStringRef self,CFIndex index);

void             CFStringGetCharacters(CFStringRef self,CFRange range,UniChar *buffer);
const UniChar   *CFStringGetCharactersPtr(CFStringRef self);

Boolean         CFStringGetCString(CFStringRef self,char *buffer,CFIndex bufferSize,CFStringEncoding encoding);
const char     *CFStringGetCStringPtr(CFStringRef self,CFStringEncoding encoding);

void            CFStringInitInlineBuffer(CFStringRef self,CFStringInlineBuffer *buffer,CFRange range);
UniChar         CFStringGetCharacterFromInlineBuffer(CFStringInlineBuffer *buffer,CFIndex index);

CFInteger        CFStringGetIntValue(CFStringRef self);
double           CFStringGetDoubleValue(CFStringRef self);
CFStringEncoding CFStringGetFastestEncoding(CFStringRef self);
CFStringEncoding CFStringGetSmallestEncoding(CFStringRef self);

CFIndex          CFStringGetMaximumSizeOfFileSystemRepresentation(CFStringRef self);
Boolean          CFStringGetFileSystemRepresentation(CFStringRef self,char *buffer,CFIndex bufferCapacity);

void             CFStringGetLineBounds(CFStringRef self,CFRange range,CFIndex *beginIndex,CFIndex *endIndex,CFIndex *contentsEndIndex);
void             CFStringGetParagraphBounds(CFStringRef self,CFRange range,CFIndex *beginIndex,CFIndex *endIndex,CFIndex *contentsEndIndex);
CFRange          CFStringGetRangeOfComposedCharactersAtIndex(CFStringRef self,CFIndex index);



