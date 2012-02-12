#import <objc/runtime.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSInvocation.h>
#include <stdio.h>

#define NSABISizeofRegisterReturn 8
#define NSABIasm_jmp_objc_msgSend __asm__("jmp _objc_msgSend")
#define NSABIasm_jmp_objc_msgSend_stret __asm__("jmp _objc_msgSend_stret")

#if !COCOTRON_DISALLOW_FORWARDING
@interface NSObject(fastforwarding)
-forwardingTargetForSelector:(SEL)selector;
@end

@interface NSInvocation(private)
+(NSInvocation *)invocationWithMethodSignature:(NSMethodSignature *)signature arguments:(void *)arguments;
@end

static void OBJCRaiseException(const char *name,const char *format,...) {
   va_list arguments;

   va_start(arguments,format);

   fprintf(stderr,"ObjC:%s:",name);
   vfprintf(stderr,format,arguments);
   fprintf(stderr,"\n");
   fflush(stderr);
   va_end(arguments);
}

id NSObjCGetFastForwardTarget(id object,SEL selector){
   id check=nil;

   if([object respondsToSelector:@selector(forwardingTargetForSelector:)])
    if((check=[object forwardingTargetForSelector:selector])==object)
     check=nil;

   return check;
}

void NSObjCForwardInvocation(void *returnValue,id object,SEL selector,va_list arguments){
   NSMethodSignature *signature=[object methodSignatureForSelector:selector];

   if(signature==nil)
    [object doesNotRecognizeSelector:selector];
   else {
    NSInvocation *invocation=[NSInvocation invocationWithMethodSignature:signature arguments:arguments];

    [object forwardInvocation:invocation];
    [invocation getReturnValue:returnValue];
   }
}

void NSObjCForward(id object,SEL selector,...){
   id check=NSObjCGetFastForwardTarget(object,selector);

   if(check!=nil){
    object=check;
    NSABIasm_jmp_objc_msgSend;
   }

   uint8_t returnValue[NSABISizeofRegisterReturn];

   va_list arguments;

   va_start(arguments,selector);

   NSObjCForwardInvocation(returnValue,object,selector,arguments);

   va_end(arguments);
}

void NSObjCForward_stret(void *returnValue,id object,SEL selector,...){
   id check=NSObjCGetFastForwardTarget(object,selector);

   if(check!=nil){
    object=check;
    NSABIasm_jmp_objc_msgSend_stret;
   }

   va_list arguments;

   va_start(arguments,selector);

   NSObjCForwardInvocation(returnValue,object,selector,arguments);

   va_end(arguments);
}
#endif


// both of these suck, we should be using NSMethodSignature types to extract the frame and create the NSInvocation here
#ifdef SOLARIS
id objc_msgForward(id object, SEL message, ...)
{
    Class class = object->isa;
    struct objc_method *method;
    va_list arguments;
    unsigned i, frameLength, limit;
    unsigned *frame;

    if ((method = class_getInstanceMethod(class, @selector(_frameLengthForSelector:))) == NULL) {
        OBJCRaiseException("OBJCDoesNotRecognizeSelector", "%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name, sel_getName(message), message);
        return nil;
    }
    frameLength = method->method_imp(object, @selector(_frameLengthForSelector:), message);
    frame = __builtin_alloca(frameLength);

    va_start(arguments, message);
    frame[0] = object;
    frame[1] = message;
    for (i = 2; i < frameLength / sizeof(unsigned); i++) {
        frame[i] = va_arg(arguments, unsigned);
    }

    if ((method = class_getInstanceMethod(class, @selector(forwardSelector:arguments:))) != NULL) {
        return method->method_imp(object, @selector(forwardSelector:arguments:), message, frame);
    } else {
        OBJCRaiseException("OBJCDoesNotRecognizeSelector", "%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name, sel_getName(message), message);
        return nil;
    }
}


void objc_msgForward_stret(void *result, id object, SEL message, ...)
{
}

#else

id objc_msgForward(id object, SEL message, ...)
{
    Class class = object->isa;
    struct objc_method *method;
    void *arguments = &object;

    if ((method = class_getInstanceMethod(class, @selector(forwardSelector:arguments:))) != NULL) {
        return method->method_imp(object, @selector(forwardSelector:arguments:), message, arguments);
    } else {
        OBJCRaiseException("OBJCDoesNotRecognizeSelector", "%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name, sel_getName(message), message);
        return nil;
    }
}


void objc_msgForward_stret(void *result, id object, SEL message, ...)
{
}


#endif
