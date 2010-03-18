/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <objc/Protocol.h>
#import "objc_protocol.h"

#import "ObjCHashTable.h"
#import "objc_class.h"
#import "objc_sel.h"
#import "ObjCException.h"

#define PROTOCOL_CLASS "Protocol"

static SEL OBJCRegisterMethodDescription(struct objc_method_description *method) {
   return sel_registerNameNoCopy((const char *)method->name);
}

static void OBJCRegisterMethodList(OBJCMethodDescriptionList *list){
   unsigned i;

   for (i=0;i<list->count;i++)
    list->list[i].name=OBJCRegisterMethodDescription(list->list+i);
}

void OBJCRegisterProtocol(OBJCProtocolTemplate *template) {
   unsigned          i;
   struct objc_protocol_list *subprotos;
   Class             class=objc_lookUpClass(PROTOCOL_CLASS);

   if(template->isa==class)
    return; // already registered

   template->isa=class;

   if(template->instanceMethods!=NULL)
    OBJCRegisterMethodList(template->instanceMethods);

   if(template->classMethods!=NULL)
    OBJCRegisterMethodList(template->classMethods);
   for(subprotos=template->childProtocols;subprotos!=NULL;subprotos=subprotos->next){
    for (i=0;i<subprotos->count;i++)
     OBJCRegisterProtocol((OBJCProtocolTemplate *)subprotos->list[i]);
   }
}

@implementation Protocol

-(const char *)name {
    return nameCString;
}

-(struct objc_method_description *)descriptionForInstanceMethod:(SEL)selector {
   struct objc_protocol_list *list;
   unsigned          i;

   if(instanceMethods!=NULL)
    for(i=0;i<instanceMethods->count;i++)
     if(instanceMethods->list[i].name==selector)
      return &instanceMethods->list[i];
    
   list=childProtocols;
   while(list!=NULL){
    unsigned j;

    for(j=0;j<list->count;j++){
     unsigned k;

     for(k=0;k<list->list[j]->instanceMethods->count;k++)
      if(list->list[j]->instanceMethods->list[k].name==selector)
       return &list->list[j]->instanceMethods->list[k];
    }
    list=list->next;
   }

   return NULL;
}

-(struct objc_method_description *)descriptionForClassMethod:(SEL)selector {
   struct objc_protocol_list *list;
   unsigned          i;

   if(classMethods!=NULL)
    for(i=0;i<classMethods->count;i++)
     if(classMethods->list[i].name==selector)
      return &classMethods->list[i];

   list=childProtocols;
   while(list!=NULL){
    unsigned j;

    for(j=0;j<list->count;j++) {
     unsigned k;

     for (k=0;k<list->list[j]->classMethods->count;k++)
      if(list->list[j]->classMethods->list[k].name==selector)
       return &list->list[j]->classMethods->list[k];
    }
    list=list->next;
   }

   return NULL;
}

-(BOOL)conformsTo:(Protocol *)other {

   if(other==nil)
    return NO;

   if(strcmp(other->nameCString,nameCString)==0)
    return YES;
   else if(childProtocols==NULL)
    return NO;
   else {
    int i;

    for (i=0;i<childProtocols->count;i++) {
     Protocol *proto=childProtocols->list[i];

     if (strcmp(other->nameCString,proto->nameCString) == 0)
      return YES;

     if ([proto conformsTo:other])
      return YES;
    }
    return NO;
   }
}

@end
