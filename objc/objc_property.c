#import <objc/runtime.h>
#import <string.h>
#import <stddef.h>
#import <stdlib.h>
#import <ctype.h>

const char *property_getAttributes(objc_property_t property) {
    return property->attributes;
}

const char *property_getName(objc_property_t property) {
    return property->name;
}

id objc_assign_ivar(id self, id value, unsigned int offset) {
    //   NSCLog("objc_assign_ivar(%x,%s,%x,%s,%d)",self,(self!=nil)?self->isa->name:"nil",value,(value!=nil)?value->isa->name:"nil",offset);
    id *ivar = (id *)(((uint8_t *)self) + offset);
    return *ivar = value;
}

void objc_copyStruct(void *dest, const void *src, size_t size, BOOL atomic, BOOL hasStrong) {
    int i;

    for(i = 0; i < size; i++)
        ((uint8_t *)dest)[i] = ((uint8_t *)src)[i];
}

void objc_setProperty(id self, SEL _cmd, size_t offset, id value, BOOL isAtomic, BOOL shouldCopy) {
    if(isAtomic) {
        //	NSUnimplementedFunction();
    }
    void *buffer = (void *)self + offset;
    id oldValue = *(id *)buffer;

    static SEL copySelector = NULL;
    static SEL retainSelector = NULL;
    static SEL releaseSelector = NULL;

    if(copySelector == NULL)
        copySelector = sel_getUid("copy");
    if(retainSelector == NULL)
        retainSelector = sel_getUid("retain");
    if(releaseSelector == NULL)
        releaseSelector = sel_getUid("releaseSelector");

    SEL useSelector = shouldCopy ? copySelector : retainSelector;
    struct objc_method *assignMethod = class_getClassMethod(object_getClass(value), useSelector);

    if(assignMethod != NULL)
        value = assignMethod->method_imp(value, useSelector);

    *(id *)buffer = value;

    struct objc_method *releaseMethod = class_getClassMethod(object_getClass(oldValue), releaseSelector);
    if(releaseMethod != NULL)
        releaseMethod->method_imp(oldValue, releaseSelector);
}

id objc_getProperty(id self, SEL _cmd, size_t offset, BOOL isAtomic) {
    if(isAtomic) {
        //	NSUnimplementedFunction();
    }

    void *buffer = (void *)self + offset;
    id value = *(id *)buffer;

    return value;
}
