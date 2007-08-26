/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <objc/objc-class.h>
#import <Foundation/ObjCClass.h>

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
	
	if(class->methodLists==NULL)
		class->methodLists=methodList;
	else {
		struct objc_method_list *node;
		
		for(node=class->methodLists;node->method_next!=NULL;node=node->method_next)
			;
		node->method_next=methodList;
	}
}

struct objc_method_list *class_nextMethodList(Class class,void **iterator) {
   struct objc_method_list *next=*iterator;
   
   if(next==NULL)
    next=class->methodLists;
   else
    next=next->method_next;
   
   *iterator=next;
   
   return next;
}
