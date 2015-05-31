#import <objc/runtime.h>
#include <setjmp.h>

typedef struct objc_autoreleasepool {
    struct objc_autoreleasepool *_parent;
    unsigned long _pageCount;
    id **_pages;
    unsigned long _nextSlot;
    struct objc_autoreleasepool *_childPool;
} objc_autoreleasepool;

typedef struct objc_exception_frame {
    jmp_buf state;
    struct objc_exception_frame *parent;
    id exception;
} objc_exception_frame;

typedef void NSUncaughtExceptionHandler(id exception);

typedef struct objc_tls {
    objc_autoreleasepool *pool;
    objc_exception_frame *exception_frame;
    NSUncaughtExceptionHandler *uncaught_exception_handler;
} objc_tls;

objc_tls *objc_tlsCurrent();
