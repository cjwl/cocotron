/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFPropertyList.h>

COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesCurrentApplication;
COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesCurrentHost;
COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesCurrentUser;

COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesAnyApplication;
COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesAnyHost;
COREFOUNDATION_EXPORT const CFStringRef kCFPreferencesAnyUser;

void              CFPreferencesAddSuitePreferencesToApp(CFStringRef application,CFStringRef suite);
Boolean           CFPreferencesAppSynchronize(CFStringRef application);
Boolean           CFPreferencesAppValueIsForced(CFStringRef key,CFStringRef application);

CFArrayRef        CFPreferencesCopyApplicationList(CFStringRef user,CFStringRef host);
CFPropertyListRef CFPreferencesCopyAppValue(CFStringRef key,CFStringRef application);
Boolean           CFPreferencesGetAppBooleanValue(CFStringRef key,CFStringRef application,Boolean *validKey);
CFIndex           CFPreferencesGetAppIntegerValue(CFStringRef key,CFStringRef application,Boolean *validKey);

CFArrayRef        CFPreferencesCopyKeyList(CFStringRef application,CFStringRef user,CFStringRef host);
CFDictionaryRef   CFPreferencesCopyMultiple(CFArrayRef keysToFetch,CFStringRef application,CFStringRef user,CFStringRef host);
CFPropertyListRef CFPreferencesCopyValue(CFStringRef key,CFStringRef application,CFStringRef user,CFStringRef host);
void              CFPreferencesSetAppValue(CFStringRef key,CFPropertyListRef value,CFStringRef application);
void              CFPreferencesSetMultiple(CFDictionaryRef dictionary,CFArrayRef removeTheseKeys,CFStringRef application,CFStringRef user,CFStringRef host);
void              CFPreferencesSetValue(CFStringRef key,CFPropertyListRef value,CFStringRef application,CFStringRef user,CFStringRef host);

void              CFPreferencesRemoveSuitePreferencesFromApp(CFStringRef application,CFStringRef suite);
Boolean           CFPreferencesSynchronize(CFStringRef application,CFStringRef user,CFStringRef host);

