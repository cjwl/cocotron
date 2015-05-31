#import <objc/runtime.h>
#import <stdbool.h>

OBJC_EXPORT id objc_retain(id value);
OBJC_EXPORT void objc_release(id value);

// Private to CF/Foundation/objc
OBJC_EXPORT void object_incrementExternalRefCount(id value);
OBJC_EXPORT bool object_decrementExternalRefCount(id value);
OBJC_EXPORT unsigned long object_externalRefCount(id value);
