/* Copyright (c) 2006-2009 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <objc/runtime.h>
#import "objc_class.h"

Class object_getClass(id object) {
    if (object == nil) {
        return Nil;
    }
   return object->isa;
}

const char *object_getClassName(id object) {
   return class_getName(object->isa);
}

Ivar object_getInstanceVariable(id object,const char *name,void **ptrToValuep) {
   Ivar result=class_getInstanceVariable(object->isa,name);
   
   *ptrToValuep=(char *)object+result->ivar_offset;
   
   return result;
}

id object_getIvar(id object,Ivar ivar) {
   if(object==nil)
    return nil;
   
   return *(id *)((char *)object+ivar->ivar_offset);
}

void *object_getIndexedIvars(id object) {
   return (char *)object+object->isa->instance_size;
}

Class object_setClass(id object,Class cls) {
   if(object==nil)
    return Nil;
    
   Class result=object->isa;
   
   object->isa=cls;
   
   return result;
}

static void ivarCopy(void *vdst,unsigned offset,void *vsrc,size_t length){
   uint8_t *dst=vdst;
   uint8_t *src=vsrc;
   size_t       i;

   for(i=0;i<length;i++)
    dst[offset+i]=src[i];
}

// FIXME: This only works for 'id' ivars
Ivar object_setInstanceVariable(id object,const char *name,void *value) {
   Ivar ivar=class_getInstanceVariable(object->isa,name);

   if(ivar!=NULL)
    ivarCopy(object,ivar->ivar_offset,value,sizeof(id));
   
   return ivar;
}

void object_setIvar(id object,Ivar ivar,id value) {
   ivarCopy(object,ivar->ivar_offset,&value,sizeof(id));
}

id object_copy(id object,size_t size) {
   // UNIMPLEMENTED
   return nil;
}

id object_dispose(id object) {
   free(object);
   return nil;
}

static inline BOOL OBJCCallCXXSelector(id self, Class class, SEL selector)
{
	struct objc_method *result=NULL;
	if(!class->super_class)
		return YES;

	if(!OBJCCallCXXSelector(self, class->super_class, selector))
		return NO;
	
	if((result=OBJCLookupUniqueIdInOnlyThisClass(class,selector))!=NULL)
	{
		if(result->method_imp(self, selector))
		{
			return YES;
		}
		else
		{
			object_cxxDestruct(self, class->super_class);
			return NO;
		}
	}
	return YES;
}

BOOL object_cxxConstruct(id self, Class class)
{
	static SEL cxx_constructor=0;
	if(!cxx_constructor)
		cxx_constructor=sel_registerName(".cxx_construct");
	
	if(!self)
		return YES;
	if(class->info&CLASS_HAS_CXX_STRUCTORS)
		return OBJCCallCXXSelector(self, class, cxx_constructor);
	return YES;
}

BOOL object_cxxDestruct(id self, Class class)
{
	static SEL cxx_destructor=0;
	if(!cxx_destructor)
		cxx_destructor=sel_registerName(".cxx_destruct");

	if(!self)
		return YES;
	if(class->info&CLASS_HAS_CXX_STRUCTORS)
		return OBJCCallCXXSelector(self, class, cxx_destructor);
	return YES;
}
