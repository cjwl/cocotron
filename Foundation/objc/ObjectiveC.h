/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// yea this should be updated to use the standard objc function names

#import <Foundation/ObjCTypes.h>

#define sel_getUid             OBJCSelectorFromString
#define sel_getName            OBJCStringFromSelector
#define sel_registerName       OBJCCreateSelectorFromCString
#define SELNAME                OBJCStringFromSelector

@class Protocol;

FOUNDATION_EXPORT Class       OBJCMetaClassFromClass(Class class);
FOUNDATION_EXPORT Class       OBJCClassFromString(const char *name);
FOUNDATION_EXPORT const char *OBJCStringFromClass(Class class);

FOUNDATION_EXPORT Class OBJCSuperclassFromClass(Class class);
FOUNDATION_EXPORT Class OBJCSuperclassFromObject(id object);

FOUNDATION_EXPORT BOOL OBJCInstanceRespondsToSelector(id object,SEL selector);
FOUNDATION_EXPORT BOOL OBJCClassConformsToProtocol(Class class,Protocol *protocol);

FOUNDATION_EXPORT BOOL OBJCIsMetaClass(Class class);

FOUNDATION_EXPORT IMP OBJCMethodForSelector(Class class,SEL selector);
FOUNDATION_EXPORT const char *OBJCTypesForSelector(Class class,SEL selector);

FOUNDATION_EXPORT int OBJCClassVersion(Class class);
FOUNDATION_EXPORT void OBJCSetClassVersion(Class class,int version);
FOUNDATION_EXPORT unsigned OBJCInstanceSize(Class class);

// This only works for 'id' ivars
FOUNDATION_EXPORT void OBJCSetInstanceVariable(id,const char *name,void *);

FOUNDATION_EXPORT BOOL OBJCIsKindOfClass(id object,Class class);

FOUNDATION_EXPORT const char *OBJCStringFromSelector(SEL selector);
FOUNDATION_EXPORT SEL OBJCCreateSelectorFromCString(const char *string);
FOUNDATION_EXPORT SEL OBJCSelectorFromString(const char *string);

FOUNDATION_EXPORT const char *OBJCModulePathFromClass(Class class);
FOUNDATION_EXPORT const char *OBJCModulePathForProcess();
FOUNDATION_EXPORT const char **OBJCAllModulePaths(); // free the ptr but not the strings

struct objc_super {
    id    object;
    Class class;
};

FOUNDATION_EXPORT IMP objc_msg_lookup(id self, SEL selector);
FOUNDATION_EXPORT IMP objc_msg_lookup_super(struct objc_super *super, SEL selector);
FOUNDATION_EXPORT id objc_msg_sendv(id self, SEL selector, unsigned arg_size, void *arg_frame);

FOUNDATION_EXPORT void OBJCReportStatistics();
FOUNDATION_EXPORT void OBJCSetDispatchTracing(BOOL yesOrNo);

#import <Foundation/ObjCDynamicModule.h>
