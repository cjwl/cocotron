#import "objc_tls.h"
#import <stdio.h>

OBJC_EXPORT NSUncaughtExceptionHandler *NSGetUncaughtExceptionHandler(void);
OBJC_EXPORT void NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *);

NSUncaughtExceptionHandler *NSThreadUncaughtExceptionHandler(void);
void NSThreadSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *function);

objc_exception_frame *NSThreadCurrentHandler(void) {
    return objc_tlsCurrent()->exception_frame;
}

void NSThreadSetCurrentHandler(objc_exception_frame *handler) {
    return objc_tlsCurrent()->exception_frame = handler;
}

NSUncaughtExceptionHandler *NSThreadUncaughtExceptionHandler(void) {
    return objc_tlsCurrent()->uncaught_exception_handler;
}

void NSThreadSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *function) {
    objc_tlsCurrent()->uncaught_exception_handler = function;
}

void __NSPushExceptionFrame(objc_exception_frame *frame) {
    frame->parent = NSThreadCurrentHandler();
    frame->exception = nil;

    NSThreadSetCurrentHandler(frame);
}

void __NSPopExceptionFrame(objc_exception_frame *frame) {
    NSThreadSetCurrentHandler(frame->parent);
}

static void defaultHandler(id exception) {
    __builtin_trap();
    fprintf(stderr, "*** Uncaught exception\n");
    // fprintf(stderr,"*** Uncaught exception <%s> *** %s\n",[[exception name] cString],[[exception reason] cString]);
}

void _NSRaiseException(id exception) {
    objc_exception_frame *top = NSThreadCurrentHandler();

    if(top == NULL) {
        NSUncaughtExceptionHandler *proc = NSGetUncaughtExceptionHandler();

        if(proc == NULL)
            defaultHandler(exception);
        else
            proc(exception);
    } else {
        NSThreadSetCurrentHandler(top->parent);

        top->exception = exception;

        longjmp(top->state, 1);
    }
}

// Enable that to put back original Cocotron behaviour, where every thread has its own default
// uncaught handler
//#define PER_THREAD_UNHANDLED_EXCEPTION_HANDLER

#ifdef PER_THREAD_UNHANDLED_EXCEPTION_HANDLER

NSUncaughtExceptionHandler *NSGetUncaughtExceptionHandler(void) {
    return NSThreadUncaughtExceptionHandler();
}

void NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *proc) {
    NSThreadSetUncaughtExceptionHandler(proc);
}
#else
static NSUncaughtExceptionHandler *uncaughtExceptionHandler = NULL;

NSUncaughtExceptionHandler *NSGetUncaughtExceptionHandler(void) {
    return uncaughtExceptionHandler;
}

void NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *proc) {
    uncaughtExceptionHandler = proc;
}
#endif

#if !defined(GCC_RUNTIME_3) && !defined(APPLE_RUNTIME_4)

void __gnu_objc_personality_sj0() {
    printf("shouldn't get here\n");
    abort();
}

void objc_exception_try_enter(void *exceptionFrame) {
    __NSPushExceptionFrame((objc_exception_frame *)exceptionFrame);
}

void objc_exception_try_exit(void *exceptionFrame) {
    __NSPopExceptionFrame((objc_exception_frame *)exceptionFrame);
}

id objc_exception_extract(void *exceptionFrame) {
    objc_exception_frame *frame = (objc_exception_frame *)exceptionFrame;
    return (id)frame->exception;
}

void objc_exception_throw(id exception) {
    _NSRaiseException(exception);
    abort();
}

static BOOL isKindOfClass(id object, Class kindOf) {
    Class class = object_getClass(object);

    while(object_getClass((id)object_getClass((id) class)) != class) {

        if(kindOf == class) {
            return YES;
        }

        class = class_getSuperclass(class);
    }

    return NO;
}

int objc_exception_match(Class exceptionClass, id exception) {
    return isKindOfClass(exception, exceptionClass);
}

#endif
