/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>


typedef struct __NSTimeZone *CFTimeZoneRef;

#import <CoreFoundation/CFDate.h>


enum {
   kCFTimeZoneNameStyleStandard           =0,
   kCFTimeZoneNameStyleShortStandard      =1,
   kCFTimeZoneNameStyleDaylightSaving     =2,
   kCFTimeZoneNameStyleShortDaylightSaving=3,
};
typedef CFIndex CFTimeZoneNameStyle;

COREFOUNDATION_EXPORT const CFStringRef kCFTimeZoneSystemTimeZoneDidChangeNotification;

CFTypeID        CFTimeZoneGetTypeID(void);
CFDictionaryRef CFTimeZoneCopyAbbreviationDictionary(void);
CFTimeZoneRef   CFTimeZoneCopyDefault(void);
CFArrayRef      CFTimeZoneCopyKnownNames(void);
CFTimeZoneRef   CFTimeZoneCopySystem(void);
void            CFTimeZoneResetSystem(void);
void            CFTimeZoneSetAbbreviationDictionary(CFDictionaryRef dictionary);
void            CFTimeZoneSetDefault(CFTimeZoneRef self);

CFTimeZoneRef CFTimeZoneCreate(CFAllocatorRef allocator,CFStringRef name,CFDataRef data);
CFTimeZoneRef CFTimeZoneCreateWithName(CFAllocatorRef allocator,CFStringRef name,Boolean checkAbbreviations);
CFTimeZoneRef CFTimeZoneCreateWithTimeIntervalFromGMT(CFAllocatorRef allocator,CFTimeInterval timeInterval);

CFStringRef     CFTimeZoneGetName(CFTimeZoneRef self);
CFDataRef       CFTimeZoneGetData(CFTimeZoneRef self);

CFTimeInterval  CFTimeZoneGetSecondsFromGMT(CFTimeZoneRef self,CFAbsoluteTime absoluteTime);
CFStringRef     CFTimeZoneCopyAbbreviation(CFTimeZoneRef self,CFAbsoluteTime absoluteTime);
CFStringRef     CFTimeZoneCopyLocalizedName(CFTimeZoneRef self,CFTimeZoneNameStyle style,CFLocaleRef locale);
CFTimeInterval  CFTimeZoneGetDaylightSavingTimeOffset(CFTimeZoneRef self,CFAbsoluteTime absoluteTime);
CFAbsoluteTime  CFTimeZoneGetNextDaylightSavingTimeTransition(CFTimeZoneRef self,CFAbsoluteTime absoluteTime);
Boolean         CFTimeZoneIsDaylightSavingTime(CFTimeZoneRef self,CFAbsoluteTime absoluteTime);
