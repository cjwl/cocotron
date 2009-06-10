#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFString.h>
#import <Foundation/NSString.h>

CFStringRef CFSTR(const char *cString)
{
	return (CFStringRef)[[NSString alloc]initWithUTF8String:cString];
}

CFStringRef CFStringCreateByCombiningStrings(CFAllocatorRef allocator,CFArrayRef array,CFStringRef separator){}
CFStringRef CFStringCreateCopy(CFAllocatorRef allocator,CFStringRef self){}
CFStringRef CFStringCreateWithBytes(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation){}
CFStringRef CFStringCreateWithBytesNoCopy(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,Boolean isExternalRepresentation,CFAllocatorRef contentsDeallocator){}
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef allocator,const UniChar *chars,CFIndex length){}
CFStringRef CFStringCreateWithCharactersNoCopy(CFAllocatorRef allocator,const UniChar *chars,CFIndex length,CFAllocatorRef contentsDeallocator){}
CFStringRef CFStringCreateWithCString(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding){}
CFStringRef CFStringCreateWithCStringNoCopy(CFAllocatorRef allocator,const char *cString,CFStringEncoding encoding,CFAllocatorRef contentsDeallocator){}
CFStringRef CFStringCreateWithFileSystemRepresentation(CFAllocatorRef allocator,const char *buffer){}
CFStringRef CFStringCreateWithFormat(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,...){}
CFStringRef CFStringCreateWithFormatAndArguments(CFAllocatorRef allocator,CFDictionaryRef formatOptions,CFStringRef format,va_list arguments){}
CFStringRef CFStringCreateFromExternalRepresentation(CFAllocatorRef allocator,CFDataRef data,CFStringEncoding encoding){}
#endif
