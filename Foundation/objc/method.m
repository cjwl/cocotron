#import <objc/runtime.h>

IMP method_getImplementation(Method method){
   return method->method_imp;
}

SEL method_getName(Method method){
   return method->method_name;
}

#if 0
unsigned method_getNumberOfArguments(Method method){
}

void method_getReturnType(Method method,char *type,size_t typeCapacity){
}

void method_getArgumentType(Method method,unsigned int index,char *type,size_t typeCapacity){
}

char *method_copyReturnType(Method method){
}

char *method_copyArgumentType(Method method,unsigned int index){
}
#endif

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

