#import <objc/runtime.h>

#define SELNAME sel_getName

OBJC_EXPORT void class_addMethods(Class class,struct objc_method_list *methodList);
OBJC_EXPORT struct objc_method_list *class_nextMethodList(Class class,void **iterator);
OBJC_EXPORT BOOL sel_isMapped(SEL selector);

