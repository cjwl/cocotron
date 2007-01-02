/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/ObjCHashTable.h>
#import <Foundation/ObjCTypes.h>
#import <Foundation/ObjCSelector.h>
#import <objc/objc-class.h>

enum {
   CLASS_INFO_CLASS=0x001,
   CLASS_INFO_META=0x002,
   CLASS_INFO_INITIALIZED=0x004,
   CLASS_INFO_POSING=0x008,
   CLASS_INFO_LINKED=0x100
};

typedef struct {
   int                  count;
   OBJCInstanceVariable list[1];
} OBJCInstanceVariableList;


typedef struct OBJCMethodList {
   struct OBJCMethodList *next;
   int                    count;
   OBJCMethod             list[1]; 
} OBJCMethodList;
 
typedef struct {
   long        offsetToNextEntry;
   OBJCMethod *method;
} OBJCMethodCacheEntry;

#define OBJCMethodCacheNumberOfEntries 64
#define OBJCMethodCacheMask            ((OBJCMethodCacheNumberOfEntries-1)*sizeof(OBJCMethodCacheEntry))

typedef struct {
   OBJCMethodCacheEntry table[OBJCMethodCacheNumberOfEntries];
// if we need a lock, put it at the end to avoid addition during cache lookup
} OBJCMethodCache;

@class Protocol;

typedef struct OBJCProtocolList {
    struct OBJCProtocolList *next;
    int                      count;
    Protocol                *list[1];
} OBJCProtocolList;

typedef struct {
   const char       *name;
   const char       *className;
   OBJCMethodList   *instanceMethods;
   OBJCMethodList   *classMethods;
   OBJCProtocolList *protocols;
} OBJCCategory;

typedef struct objc_class {			
   struct objc_class        *isa;	
   struct objc_class        *superclass;	
   const char               *name;		
   long                      version;
   long                      info;
   long                      instanceSize;
   OBJCInstanceVariableList *ivars;
   OBJCMethodList           *methods;
   OBJCMethodCache          *cache;
   OBJCProtocolList         *protocols;
   void                     *privateData;
} OBJCClassTemplate;


typedef struct OBJCMethodDescriptionList {
   int                    count;
   OBJCMethodDescription list[1];
} OBJCMethodDescriptionList;

FOUNDATION_EXPORT Class OBJCClassFromString(const char *name);
FOUNDATION_EXPORT id objc_getClass(const char *name);
FOUNDATION_EXPORT id objc_getOrigClass(const char *name);

FOUNDATION_EXPORT void OBJCRegisterClass(Class class);
FOUNDATION_EXPORT void OBJCRegisterCategory(OBJCCategory *category,Class class);

FOUNDATION_EXPORT OBJCMethod *OBJCLookupUniqueIdInClass(Class class,SEL uniqueId);
FOUNDATION_EXPORT IMP OBJCLookupAndCacheUniqueIdInClass(Class class,SEL uniqueId);
FOUNDATION_EXPORT IMP OBJCInitializeLookupAndCacheUniqueIdForObject(id object,SEL message);

FOUNDATION_EXPORT void OBJCLinkClassTable(void);

