/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFData.h>



typedef struct __NSURL *CFURLRef;

typedef enum {
   kCFURLComponentScheme           =1,
   kCFURLComponentNetLocation      =2,
   kCFURLComponentPath             =3,
   kCFURLComponentResourceSpecifier=4,
   kCFURLComponentUser             =5,
   kCFURLComponentPassword         =6,
   kCFURLComponentUserInfo         =7,
   kCFURLComponentHost             =8,
   kCFURLComponentPort             =9,
   kCFURLComponentParameterString  =10,
   kCFURLComponentQuery            =11,
   kCFURLComponentFragment         =12,
} CFURLComponentType;

typedef enum  {
   kCFURLPOSIXPathStyle  =0,
   kCFURLHFSPathStyle    =1,
   kCFURLWindowsPathStyle=2,
} CFURLPathStyle;

CFTypeID CFURLGetTypeID(void);

CFURLRef CFURLCreateAbsoluteURLWithBytes(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,CFURLRef baseURL,Boolean useCompatibilityMode);
CFURLRef CFURLCreateWithBytes(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFStringEncoding encoding,CFURLRef baseURL);
CFURLRef CFURLCreateWithFileSystemPath(CFAllocatorRef allocator,CFStringRef path,CFURLPathStyle pathStyle,Boolean isDirectory);
CFURLRef CFURLCreateWithFileSystemPathRelativeToBase(CFAllocatorRef allocator,CFStringRef path,CFURLPathStyle pathStyle,Boolean isDirectory,CFURLRef baseURL);
CFURLRef CFURLCreateWithString(CFAllocatorRef allocator,CFStringRef string,CFURLRef baseURL);
CFURLRef CFURLCreateFromFileSystemRepresentation(CFAllocatorRef allocator,const uint8_t *buffer,CFIndex length,Boolean isDirectory);
CFURLRef CFURLCreateFromFileSystemRepresentationRelativeToBase(CFAllocatorRef allocator,const uint8_t *buffer,CFIndex length,Boolean isDirectory,CFURLRef baseURL);

CFURLRef    CFURLCopyAbsoluteURL(CFURLRef url);

CFStringRef CFURLGetString(CFURLRef self);
CFURLRef    CFURLGetBaseURL(CFURLRef self);
Boolean     CFURLCanBeDecomposed(CFURLRef self);
CFStringRef CFURLCopyFileSystemPath(CFURLRef self,CFURLPathStyle pathStyle);
CFStringRef CFURLCopyFragment(CFURLRef self,CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyHostName(CFURLRef self);
CFStringRef CFURLCopyLastPathComponent(CFURLRef self);
CFStringRef CFURLCopyNetLocation(CFURLRef self);
CFStringRef CFURLCopyParameterString(CFURLRef self,CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyPassword(CFURLRef self);
CFStringRef CFURLCopyPath(CFURLRef self);
CFStringRef CFURLCopyPathExtension(CFURLRef self);
CFStringRef CFURLCopyQueryString(CFURLRef self,CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyResourceSpecifier(CFURLRef self);
CFStringRef CFURLCopyScheme(CFURLRef self);
CFStringRef CFURLCopyStrictPath(CFURLRef self,Boolean *isAbsolute);
CFStringRef CFURLCopyUserName(CFURLRef self);
CFInteger   CFURLGetPortNumber(CFURLRef self);
Boolean     CFURLHasDirectoryPath(CFURLRef self);

CFURLRef    CFURLCreateCopyAppendingPathComponent(CFAllocatorRef allocator,CFURLRef self,CFStringRef pathComponent,Boolean isDirectory);
CFURLRef    CFURLCreateCopyAppendingPathExtension(CFAllocatorRef allocator,CFURLRef self,CFStringRef extension);
CFURLRef    CFURLCreateCopyDeletingLastPathComponent(CFAllocatorRef allocator,CFURLRef self);
CFURLRef    CFURLCreateCopyDeletingPathExtension(CFAllocatorRef allocator,CFURLRef self);
CFDataRef   CFURLCreateData(CFAllocatorRef allocator,CFURLRef self,CFStringEncoding encoding,Boolean escapeWhitespace);
CFStringRef CFURLCreateStringByAddingPercentEscapes(CFAllocatorRef allocator,CFStringRef string,CFStringRef charactersToLeaveUnescaped,CFStringRef charactersToBeEscaped,CFStringEncoding encoding);
CFStringRef CFURLCreateStringByReplacingPercentEscapes(CFAllocatorRef allocator,CFStringRef string,CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCreateStringByReplacingPercentEscapesUsingEncoding(CFAllocatorRef allocator,CFStringRef string,CFStringRef charactersToLeaveEscaped,CFStringEncoding encoding);
CFRange     CFURLGetByteRangeForComponent(CFURLRef self,CFURLComponentType component,CFRange *rangeIncludingSeparators);
CFIndex     CFURLGetBytes(CFURLRef self,uint8_t *buffer,CFIndex bufferLength);
Boolean     CFURLGetFileSystemRepresentation(CFURLRef self,Boolean resolveAgainstBase,uint8_t *buffer,CFIndex bufferLength);
