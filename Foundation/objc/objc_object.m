/* Copyright (c) 2006-2009 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <objc/runtime.h>

Class object_getClass(id object) {
   return object->isa;
}

const char *object_getClassName(id object) {
   return class_getName(object->isa);
}

static Ivar instanceVariableWithName(struct objc_class *class,const char *name) {
   for(;;class=class->super_class){
    struct objc_ivar_list *ivarList=class->ivars;
    int i;

    for(i=0;ivarList!=NULL && i<ivarList->ivar_count;i++){
     if(strcmp(ivarList->ivar_list[i].ivar_name,name)==0)
      return &(ivarList->ivar_list[i]);
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

// This only works for 'id' ivars
Ivar object_setInstanceVariable(id object,const char *name,void *value) {
   Ivar ivar=instanceVariableWithName(object->isa,name);

   if(ivar!=NULL)
    ivarCopy(object,ivar->ivar_offset,value,sizeof(id));
   
   return ivar;
}
