#import <objc/objc.h>
#import <objc/objc-class.h>
#import <stdint.h>

typedef struct objc_method   *Method;
typedef struct objc_ivar     *Ivar;
typedef struct objc_category *Category;
typedef struct objc_property *objc_property_t;

OBJC_EXPORT id           objc_lookUpClass(const char *name);
OBJC_EXPORT id           objc_getClass(const char *name);
OBJC_EXPORT int          objc_getClassList(Class *list,int listCapacity);
OBJC_EXPORT Class        objc_getFutureClass(const char *name);
OBJC_EXPORT id           objc_getMetaClass(const char *name);
OBJC_EXPORT id           objc_getRequiredClass(const char *name);
OBJC_EXPORT Protocol    *objc_getProtocol(const char *name);
OBJC_EXPORT Protocol   **objc_copyProtocolList(unsigned int *countp);
OBJC_EXPORT void         objc_addClass(Class cls);
OBJC_EXPORT void         objc_registerClassPair(Class cls);
OBJC_EXPORT void         objc_setFutureClass(Class cls,const char *name);
OBJC_EXPORT Class        objc_allocateClassPair(Class parent,const char *name,size_t extraBytes);
OBJC_EXPORT void         objc_setForwardHandler(void *handler, void *handler_stret);
OBJC_EXPORT const char **objc_copyImageNames(unsigned *count); // free the ptr but not the strings

OBJC_EXPORT const char      *class_getName(Class cls);
OBJC_EXPORT BOOL             class_isMetaClass(Class cls);
OBJC_EXPORT Class            class_getSuperclass(Class cls);
OBJC_EXPORT int              class_getVersion(Class cls);
OBJC_EXPORT Method           class_getClassMethod(Class cls,SEL selector);
OBJC_EXPORT Ivar             class_getClassVariable(Class cls,const char *name);
OBJC_EXPORT Method           class_getInstanceMethod(Class cls,SEL selector);
OBJC_EXPORT size_t           class_getInstanceSize(Class cls);
OBJC_EXPORT Ivar             class_getInstanceVariable(Class cls,const char *name);
OBJC_EXPORT const char      *class_getIvarLayout(Class cls);
OBJC_EXPORT IMP              class_getMethodImplementation(Class cls,SEL selector);
OBJC_EXPORT IMP              class_getMethodImplementation_stret(Class cls,SEL selector);
OBJC_EXPORT objc_property_t  class_getProperty(Class cls,const char *name);
OBJC_EXPORT const char      *class_getWeakIvarLayout(Class cls);
OBJC_EXPORT Ivar            *class_copyIvarList(Class cls,unsigned int *countp);
OBJC_EXPORT Method          *class_copyMethodList(Class cls,unsigned int *countp);
OBJC_EXPORT objc_property_t *class_copyPropertyList(Class cls,unsigned int *countp);
OBJC_EXPORT Protocol       **class_copyProtocolList(Class cls,unsigned int *countp);

OBJC_EXPORT Class            class_setSuperclass(Class cls,Class parent);
OBJC_EXPORT void             class_setVersion(Class cls,int version);
OBJC_EXPORT void             class_setIvarLayout(Class cls,const char *layout);
OBJC_EXPORT void             class_setWeakIvarLayout(Class cls,const char *layout);

OBJC_EXPORT BOOL             class_addIvar(Class cls,const char *name,size_t size,uint8_t alignment,const char *type);
OBJC_EXPORT BOOL             class_addMethod(Class cls,SEL selector,IMP imp,const char *types);
OBJC_EXPORT BOOL             class_addProtocol(Class cls,Protocol *protocol);
OBJC_EXPORT BOOL             class_conformsToProtocol(Class cls,Protocol *protocol);
OBJC_EXPORT id               class_createInstance(Class cls,size_t extraBytes);
OBJC_EXPORT IMP              class_replaceMethod(Class cls,SEL selector,IMP imp,const char *types);
OBJC_EXPORT BOOL             class_respondsToSelector(Class cls,SEL selector);
OBJC_EXPORT const char      *class_getImageName(Class cls);

OBJC_EXPORT const char                     *protocol_getName(Protocol *protocol);
OBJC_EXPORT objc_property_t                 protocol_getProperty(Protocol *protocol,const char *name,BOOL isRequired,BOOL isInstance);
OBJC_EXPORT objc_property_t                *protocol_copyPropertyList(Protocol *protocol,unsigned int *countp);
OBJC_EXPORT Protocol                      **protocol_copyProtocolList(Protocol *protocol,unsigned int *countp);
OBJC_EXPORT struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *protocol,BOOL isRequired,BOOL isInstance,unsigned int *countp);
OBJC_EXPORT struct objc_method_description  protocol_getMethodDescription(Protocol *protocol,SEL selector,BOOL isRequired,BOOL isInstance);
OBJC_EXPORT BOOL                            protocol_conformsToProtocol(Protocol *protocol,Protocol *other);
OBJC_EXPORT BOOL                            protocol_isEqual(Protocol *protocol,Protocol *other);

OBJC_EXPORT const char *sel_getName(SEL selector);
OBJC_EXPORT SEL         sel_getUid(const char *name);
OBJC_EXPORT BOOL        sel_isEqual(SEL selector,SEL other);
OBJC_EXPORT SEL         sel_registerName(const char *name);

OBJC_EXPORT const char *property_getAttributes(objc_property_t property);
OBJC_EXPORT const char *property_getName(objc_property_t property);

OBJC_EXPORT const char *ivar_getName(Ivar ivar);
OBJC_EXPORT size_t      ivar_getOffset(Ivar ivar);
OBJC_EXPORT const char *ivar_getTypeEncoding(Ivar ivar);

OBJC_EXPORT IMP         method_getImplementation(Method method);
OBJC_EXPORT SEL         method_getName(Method method);
OBJC_EXPORT unsigned    method_getNumberOfArguments(Method method);
OBJC_EXPORT void        method_getReturnType(Method method,char *type,size_t typeCapacity);
OBJC_EXPORT void        method_getArgumentType(Method method,unsigned int index,char *type,size_t typeCapacity);
OBJC_EXPORT char       *method_copyReturnType(Method method);
OBJC_EXPORT char       *method_copyArgumentType(Method method,unsigned int index);
OBJC_EXPORT const char *method_getTypeEncoding(Method method);
OBJC_EXPORT IMP         method_setImplementation(Method method,IMP imp);
OBJC_EXPORT void        method_exchangeImplementations(Method method,Method other);

OBJC_EXPORT Class       object_getClass(id object);
OBJC_EXPORT const char *object_getClassName(id object);
OBJC_EXPORT Ivar        object_getInstanceVariable(id object,const char *name,void **ptrToValuep);
OBJC_EXPORT id          object_getIvar(id object,Ivar ivar);
OBJC_EXPORT void       *object_getIndexedIvars(id object);
OBJC_EXPORT Class       object_setClass(id object,Class cls);
OBJC_EXPORT Ivar        object_setInstanceVariable(id object,const char *name,void *ptrToValue);
OBJC_EXPORT void        object_setIvar(id object,Ivar ivar,id value);

OBJC_EXPORT id          object_copy(id object,size_t size);
OBJC_EXPORT id          object_dispose(id object);


// FIXME. Non-compliant API. TO BE CLEANED UP.

OBJC_EXPORT const char *objc_mainImageName();
OBJC_EXPORT void OBJCResetModuleQueue(void);
OBJC_EXPORT void OBJCLinkQueuedModulesToObjectFileWithPath(const char *path);

OBJC_EXPORT void objc_enableMessageLoggingWithCount(int count);
OBJC_EXPORT void OBJCEnableMsgTracing();
OBJC_EXPORT void OBJCDisableMsgTracing();

OBJC_EXPORT void OBJCInitializeProcess();

OBJC_EXPORT BOOL object_cxxConstruct(id self, Class c);
OBJC_EXPORT BOOL object_cxxDestruct(id self, Class c);

