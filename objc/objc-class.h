/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc-export.h>
#import <objc/objc.h>

enum {
   CLASS_INFO_CLASS=0x001,
   CLS_CLASS=CLASS_INFO_CLASS,
   CLASS_INFO_META=0x002,
   CLS_META=CLASS_INFO_META,
   CLASS_INFO_INITIALIZED=0x004,
   CLASS_INFO_POSING=0x008,
   CLASS_INFO_LINKED=0x100
};

typedef struct objc_ivar {
   char *ivar_name;
   char *ivar_type;
   int   ivar_offset;
} *Ivar, OBJCInstanceVariable;

typedef struct {
   int                  count;
   OBJCInstanceVariable list[1];
} OBJCInstanceVariableList;

typedef struct objc_method {
   SEL   method_name;
   char *method_types;
   IMP   method_imp;
} *Method, OBJCMethod;

typedef struct objc_method_list {
   struct objc_method_list *next;
   int                      method_count;
   OBJCMethod               method_list[1]; 
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
   struct objc_class        *super_class;	
   const char               *name;		
   long                      version;
   long                      info;
   long                      instance_size;
   OBJCInstanceVariableList *ivars;
   OBJCMethodList           *methodLists;
   OBJCMethodCache          *cache;
   OBJCProtocolList         *protocols;
   void                     *privateData;
} OBJCClassTemplate;

OBJC_EXPORT Ivar class_getInstanceVariable(Class class,const char *variableName);
OBJC_EXPORT void class_addMethods(Class class,OBJCMethodList *methodList);

OBJC_EXPORT struct objc_method_list *class_nextMethodList(Class class,void **iterator);
