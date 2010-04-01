#import <CoreFoundation/CFString.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>

struct __CFString {
};

#define ToNSString(object) ((NSString *)object)
#define ToCFString(object) ((CFStringRef)object)

static inline NSStringEncoding convertCFEncodingToNSEncoding(CFStringEncoding encoding){
   switch(encoding){
    case kCFStringEncodingUTF8:
     return NSUTF8StringEncoding;
    case kCFStringEncodingUTF16:
     return NSUnicodeStringEncoding;
    case kCFStringEncodingUTF16BE:
     return NSUTF16BigEndianStringEncoding;
    case kCFStringEncodingUTF16LE:
     return NSUTF16LittleEndianStringEncoding;
    case kCFStringEncodingUTF32:
     return NSUTF32StringEncoding;
    case kCFStringEncodingUTF32BE:
     return NSUTF32BigEndianStringEncoding;
    case kCFStringEncodingUTF32LE:
     return NSUTF32LittleEndianStringEncoding;
    
    case kCFStringEncodingMacRoman:
     return NSMacOSRomanStringEncoding;
    case kCFStringEncodingWindowsLatin1:
     return NSWindowsCP1252StringEncoding;
    case kCFStringEncodingISOLatin1:
     return NSISOLatin1StringEncoding;
    case kCFStringEncodingNextStepLatin:
     return NSNEXTSTEPStringEncoding;
    case kCFStringEncodingASCII:
     return NSASCIIStringEncoding;
//    case kCFStringEncodingUnicode: same as kCFStringEncodingUTF16
    case kCFStringEncodingNonLossyASCII:
     return NSNonLossyASCIIStringEncoding;
   }
   return NSASCIIStringEncoding;
}

void CFStringAppendCharacters(CFMutableStringRef mutableString, const UniChar *chars, CFIndex numChars)
{
	[(NSMutableString *)mutableString appendString:[NSString stringWithCharacters:chars length:numChars]];
}

CFStringRef CFStringMakeConstant(const char *cString) {
// FIXME: constify
   return (CFStringRef)[[[NSString allocWithZone:NULL]initWithUTF8String:cString] autorelease];
}

CFStringRef CFStringCreateByCombiningStrings(CFAllocatorRef allocator,CFArrayRef array,CFStringRef separator){
   NSUnimplementedFunction();
   return 0;
}

CFStringRef CFStringCreateCopy(CFAllocatorRef allocator,CFStringRef self){
   return ToCFString([ToNSString(self) copyWithZone:NULL]);
}

CFStringRef CFStringCreateWithBytes(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithBytesNoCopy(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation,CFAllocatorRef contentsDeallocator){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef allocator,const UniChar *chars,CFIndex length){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithCharactersNoCopy(CFAllocatorRef allocator,const UniChar *chars,CFIndex length,CFAllocatorRef contentsDeallocator){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithCString(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding){
   return ToCFString([[NSString allocWithZone:NULL] initWithCString:cString encoding:convertCFEncodingToNSEncoding(encoding)]);
}

CFStringRef CFStringCreateWithCStringNoCopy(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding,CFAllocatorRef contentsDeallocator){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithFileSystemRepresentation(CFAllocatorRef allocator,const char *buffer){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithFormat(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,...){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateWithFormatAndArguments(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,va_list arguments){
   NSUnimplementedFunction();
   return 0;
}
CFStringRef CFStringCreateFromExternalRepresentation(CFAllocatorRef allocator,CFDataRef data,CFStringEncoding encoding){
   NSUnimplementedFunction();
   return 0;
}

CFStringRef CFStringCreateWithSubstring(CFAllocatorRef allocator,CFStringRef self,CFRange range) {
   NSUnimplementedFunction();
   return 0;
}


void CFShow(CFTypeRef self) {
   NSPlatformLogString([ToNSString(self) description]);
}

void CFShowStr(CFStringRef self) {
   NSUnimplementedFunction();
}


CFComparisonResult CFStringCompare(CFStringRef self,CFStringRef other,CFOptionFlags options){
   return [ToNSString(self) compare:(NSString *)other options:options];
}

CFComparisonResult CFStringCompareWithOptions(CFStringRef self,CFStringRef other,CFRange range,CFOptionFlags options) {
   NSRange nsRange={range.location,range.length};
   return [ToNSString(self) compare:(NSString *)other options:options range:nsRange];
}

CFComparisonResult CFStringCompareWithOptionsAndLocale(CFStringRef self,CFStringRef other,CFRange range,CFOptionFlags options,CFLocaleRef locale) {
   NSRange nsRange={range.location,range.length};
   return [ToNSString(self) compare:(NSString *)other options:options range:nsRange locale:(id)locale];
}


CFIndex CFStringGetLength(CFStringRef self) {
   return [ToNSString(self) length];
}

UniChar CFStringGetCharacterAtIndex(CFStringRef self,CFIndex index) {
   return [ToNSString(self) characterAtIndex:index];
}

void CFStringGetCharacters(CFStringRef self,CFRange range,UniChar *buffer) {
   NSRange nsRange={range.location,range.length};
   [ToNSString(self) getCharacters:buffer range:nsRange];
}

Boolean CFStringGetCString(CFStringRef self,char *buffer,CFIndex bufferSize,CFStringEncoding encoding) {
   return [(NSString *)self getCString:buffer maxLength:bufferSize encoding:convertCFEncodingToNSEncoding(encoding)];
}

const char *CFStringGetCStringPtr(CFStringRef self,CFStringEncoding encoding) {
   return [(NSString *)self cStringUsingEncoding:convertCFEncodingToNSEncoding(encoding)];
}



