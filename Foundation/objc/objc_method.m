#import <objc/runtime.h>

IMP method_getImplementation(Method method){
   return method->method_imp;
}

SEL method_getName(Method method){
   return method->method_name;
}

unsigned method_getNumberOfArguments(Method method){
   unsigned    result=2;
   const char *name=sel_getName(method->method_name);
   
   for(;*name!='\0';name++)
    if(*name==':')
     result++;
     
   return result;
}

void method_getReturnType(Method method,char *type,size_t typeCapacity){
   // UNIMPLEMENTED
}

void method_getArgumentType(Method method,unsigned int index,char *type,size_t typeCapacity){
   // UNIMPLEMENTED
}

char *method_copyReturnType(Method method){
   // UNIMPLEMENTED
   return NULL;
}

char *method_copyArgumentType(Method method,unsigned int index){
   // UNIMPLEMENTED
   return NULL;
}

const char *method_getTypeEncoding(Method method) {
   return (method==NULL)?NULL:method->method_types;
}

IMP method_setImplementation(Method method,IMP imp){
   IMP result=method->method_imp;
   method->method_imp=imp;
   return result;
}

void method_exchangeImplementations(Method method,Method other){
// FIXME: needs to be atomic
   IMP tmp=method->method_imp;
   
   method->method_imp=other->method_imp;
   other->method_imp=tmp;
}

