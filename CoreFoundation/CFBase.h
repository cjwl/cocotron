/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <sys/types.h>
#import <stdlib.h>
#import <ctype.h>
#import <errno.h>
#import <float.h>
#import <limits.h>
#import <math.h>
#import <stdarg.h>
#import <stddef.h>
#import <stdio.h>
#import <string.h>
#import <assert.h>
#import <stdint.h>
#import <time.h>

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(COREFOUNDATION_INSIDE_BUILD)
#define COREFOUNDATION_EXPORT extern "C" __declspec(dllexport)
#else
#define COREFOUNDATION_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define COREFOUNDATION_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(COREFOUNDATION_INSIDE_BUILD)
#define COREFOUNDATION_EXPORT __declspec(dllexport) extern
#else
#define COREFOUNDATION_EXPORT __declspec(dllimport) extern
#endif
#else
#define COREFOUNDATION_EXPORT extern
#endif

#endif // __cplusplus

/* Apple's Foundation imports CoreGraphics in order to get some of the basic CG* types, unfortunately
   this is a hassle on platforms where you just want to use Foundation, so we put them in CoreFoundation and see what happens
*/
 
#ifdef __LP64__
typedef double CGFloat;
#else
typedef float CGFloat;
#endif

typedef struct CGPoint {
   CGFloat x;
   CGFloat y;
} CGPoint;

typedef struct CGSize {
   CGFloat width;
   CGFloat height;
} CGSize;

typedef struct CGRect {
   CGPoint origin;
   CGSize  size;
} CGRect;
 

// FIXME: 
typedef int mach_port_t;
typedef unsigned short UniChar;
typedef unsigned long UTF32Char;
typedef float Float32;
typedef double Float64;
// ---

typedef unsigned CFUInteger;
typedef int CFInteger;
typedef int SInt32;
typedef signed char SInt8;

typedef const void *CFTypeRef;
typedef CFUInteger CFTypeID;
typedef CFUInteger CFHashCode;
typedef char       Boolean;
typedef CFInteger  CFIndex;
typedef CFUInteger CFOptionFlags;

typedef struct {
   CFIndex location;
   CFIndex length;
} CFRange;

static inline CFRange CFRangeMake(CFIndex loc,CFIndex len){
   CFRange result={loc,len};
   
   return result;
}

#ifndef TRUE
#define TRUE ((Boolean)1)
#endif

#ifndef FALSE
#define FALSE ((Boolean)0)
#endif

typedef enum  {
   kCFCompareLessThan  = -1,
   kCFCompareEqualTo   = 0,
   kCFCompareGreaterThan= 1
} CFComparisonResult;

typedef CFComparisonResult (*CFComparatorFunction)(const void *value,const void *other,void *context);

typedef struct CFAllocator *CFAllocatorRef;

#import <CoreFoundation/CFString.h>

typedef void       *(*CFAllocatorAllocateCallBack)(CFIndex size,CFOptionFlags hint,void *info);
typedef CFStringRef (*CFAllocatorCopyDescriptionCallBack)(const void *info);
typedef void        (*CFAllocatorDeallocateCallBack)(void *ptr,void *info);
typedef CFIndex     (*CFAllocatorPreferredSizeCallBack)(CFIndex size,CFOptionFlags hint,void *info);
typedef void       *(*CFAllocatorReallocateCallBack)(void *ptr,CFIndex size,CFOptionFlags hint,void *info);
typedef void        (*CFAllocatorReleaseCallBack)(const void *info);
typedef const void *(*CFAllocatorRetainCallBack)(const void *info);

typedef struct {
   CFIndex                            version;
   void                              *info;
   CFAllocatorRetainCallBack          retain;
   CFAllocatorReleaseCallBack         release;
   CFAllocatorCopyDescriptionCallBack copyDescription;
   CFAllocatorAllocateCallBack        allocate;
   CFAllocatorReallocateCallBack      reallocate;
   CFAllocatorDeallocateCallBack      deallocate;
   CFAllocatorPreferredSizeCallBack   preferredSize;
} CFAllocatorContext;

COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorDefault;
COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorSystemDefault;
COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorMalloc;
COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorMallocZone;
COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorNull;
COREFOUNDATION_EXPORT const CFAllocatorRef kCFAllocatorUseContext;

CFAllocatorRef CFAllocatorGetDefault(void);
void           CFAllocatorSetDefault(CFAllocatorRef self);

CFTypeID       CFAllocatorGetTypeID(void);

CFAllocatorRef CFAllocatorCreate(CFAllocatorRef self,CFAllocatorContext *context);

void           CFAllocatorGetContext(CFAllocatorRef self,CFAllocatorContext *context);
CFIndex        CFAllocatorGetPreferredSizeForSize(CFAllocatorRef self,CFIndex size,CFOptionFlags hint);

void          *CFAllocatorAllocate(CFAllocatorRef self,CFIndex size,CFOptionFlags hint);
void           CFAllocatorDeallocate(CFAllocatorRef self,void *ptr);
void          *CFAllocatorReallocate(CFAllocatorRef self,void *ptr,CFIndex size,CFOptionFlags hint);


CFTypeID       CFGetTypeID(CFTypeRef self);

CFTypeRef      CFRetain(CFTypeRef self);
void           CFRelease(CFTypeRef self);
CFIndex        CFGetRetainCount(CFTypeRef self);

CFAllocatorRef CFGetAllocator(CFTypeRef self);

CFHashCode     CFHash(CFTypeRef self);
Boolean        CFEqual(CFTypeRef self,CFTypeRef other);
CFStringRef    CFCopyTypeIDDescription(CFTypeID typeID);
CFStringRef    CFCopyDescription(CFTypeRef self);
CFTypeRef      CFMakeCollectable(CFTypeRef self);


