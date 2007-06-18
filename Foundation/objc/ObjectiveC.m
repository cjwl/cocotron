/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>, Christopher Lloyd <cjwl@objc.net>
#import <Foundation/ObjectiveC.h>
#import <Foundation/ObjCHashTable.h>
#import <Foundation/ObjCClass.h>
#import "Protocol.h"
#import <Foundation/ObjCSelector.h>
#import <Foundation/ObjCModule.h>

Class OBJCMetaClassFromClass(Class class) {
   return class->isa;
}

// Class OBJCClassFromString(const char *name) defined in ObjCClass

const char *OBJCStringFromClass(Class class){
   struct objc_class *cls=class;
   return cls->name;
}

Class OBJCSuperclassFromClass(Class class) {
   struct objc_class *cls=class;
   return cls->super_class;
}

FOUNDATION_EXPORT Class OBJCSuperclassFromObject(id object) {
   return OBJCSuperclassFromClass(object->isa);
}

BOOL OBJCClassConformsToProtocol(Class class,Protocol *protocol) {

   for(;;class=class->super_class){
    OBJCProtocolList *protoList=class->protocols;

    for(;protoList!=NULL;protoList=protoList->next){
     int i;

     for(i=0;i<protoList->count;i++){
      if([protoList->list[i] conformsTo:protocol])
       return YES;
     }
    }

    if(class->isa->isa==class)
     break;
   }

   return NO;
}

BOOL OBJCIsMetaClass(Class class) {
   return (class->info&CLASS_INFO_META)?YES:NO;
}

const char *OBJCTypesForSelector(Class class,SEL selector) {
   OBJCMethod *method=OBJCLookupUniqueIdInClass(class,OBJCSelectorUniqueId(selector));

   return (method==NULL)?NULL:method->method_types;
}

int OBJCClassVersion(Class class) {
   struct objc_class *cls=class;
   return cls->version;
}

void OBJCSetClassVersion(Class class,int version) {
   struct objc_class *cls=class;
   cls->version=version;
}

unsigned OBJCInstanceSize(Class class) {
   struct objc_class *cls=class;
   return cls->instance_size;
}

static OBJCInstanceVariable *instanceVariableWithName(OBJCClassTemplate *class,const char *name) {
   for(;;class=class->super_class){
    OBJCInstanceVariableList *ivarList=class->ivars;
    int i;

    for(i=0;ivarList!=NULL && i<ivarList->count;i++){
     if(strcmp(ivarList->list[i].ivar_name,name)==0)
      return &(ivarList->list[i]);
    }
    if(class->isa->isa==class)
     break;
   }

   return NULL;
}

static void ivarCopy(void *vdst,unsigned offset,void *vsrc,unsigned length){
   unsigned char *dst=vdst;
   unsigned char *src=vsrc;
   unsigned       i;

   for(i=0;i<length;i++)
    dst[offset+i]=src[i];
}

void OBJCSetInstanceVariable(id object,const char *name,void *value) {
   OBJCInstanceVariable *ivar=instanceVariableWithName(object->isa,name);

   if(ivar!=NULL)
    ivarCopy(object,ivar->ivar_offset,value,sizeof(id));
}

BOOL OBJCIsKindOfClass(id object,Class kindOf) {
   struct objc_class *class=object->isa;

   for(;;class=class->super_class){
    if(kindOf==class)
     return YES;
    if(class->isa->isa==class)
     break;
   }

   return NO;
}
