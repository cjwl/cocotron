/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <objc/runtime.h>
#import <string.h>

Ivar class_getInstanceVariable(Class class,const char *variableName) {
   for(;;class=class->super_class){
    struct objc_ivar_list *ivarList=class->ivars;
    int i;

    for(i=0;ivarList!=NULL && i<ivarList->ivar_count;i++){
     if(strcmp(ivarList->ivar_list[i].ivar_name,variableName)==0)
      return &(ivarList->ivar_list[i]);
    }
    if(class->isa->isa==class)
     break;
   }

   return NULL;
}

void class_addMethods(Class class,struct objc_method_list *methodList) {
   struct objc_method_list **methodLists=class->methodLists;
   struct objc_method_list **newLists=NULL;
   int i;

   if(!methodLists) {
      // no method list yet: create one
      newLists=calloc(sizeof(struct objc_method_list*), 2);
      newLists[0]=methodList;
   } else {
      // we have a method list: measure it out
      for(i=0; methodLists[i]!=NULL; i++) {
      }
      // allocate new method list array
      newLists=calloc(sizeof(struct objc_method_list*), i+2);
      // copy over
      newLists[0]=methodList;
      for(i=0; methodLists[i]!=NULL; i++) {
         newLists[i+1]=methodLists[i];
      }
   }
   // set new lists
   class->methodLists=newLists;
   // free old ones (FIXME: thread safety)
   if(methodLists)
      free(methodLists);
}

BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types) {
	struct objc_method *newMethod = calloc(sizeof(struct objc_method), 1);
	struct objc_method_list *methodList = calloc(sizeof(struct objc_method_list)+sizeof(struct objc_method), 1);
	
	newMethod->method_name = name;
	newMethod->method_types = (char*)types;
	newMethod->method_imp = imp;

	methodList->method_count = 1;
	memcpy(methodList->method_list, newMethod, sizeof(struct objc_method));
	free(newMethod);
	class_addMethods(cls, methodList);
	return YES; // TODO: check if method exists
}

struct objc_method_list *class_nextMethodList(Class class,void **iterator) {
   int *it=(int*)iterator;
   struct objc_method_list *ret=NULL;
   if(!class->methodLists)
      return NULL;
   
   ret=class->methodLists[*it];
   *it=*it+1;
   
   return ret;
}
