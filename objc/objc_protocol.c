#import "objc_protocol.h"
#import <string.h>

const char *protocol_getName(Protocol *protocol) {
    return protocol->nameCString;
}

objc_property_t protocol_getProperty(Protocol *protocol, const char *name, BOOL isRequired, BOOL isInstance) {
    // UNIMPLEMENTED
    return NULL;
}

objc_property_t *protocol_copyPropertyList(Protocol *protocol, unsigned int *countp) {
    // UNIMPLEMENTED
    return NULL;
}

Protocol **protocol_copyProtocolList(Protocol *protocol, unsigned int *countp) {
    // UNIMPLEMENTED
    return NULL;
}

struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *protocol, BOOL isRequired, BOOL isInstance, unsigned int *countp) {
    // UNIMPLEMENTED
    return NULL;
}

struct objc_method_description protocol_getMethodDescription(Protocol *protocol, SEL selector, BOOL isRequired, BOOL isInstance) {
    struct objc_method_description result = {0, 0};
    // UNIMPLEMENTED
    return result;
}

BOOL protocol_conformsToProtocol(Protocol *protocol, Protocol *other) {

    if(other == nil)
        return NO;

    if(strcmp(other->nameCString, protocol->nameCString) == 0)
        return YES;
    else if(protocol->childProtocols == NULL)
        return NO;
    else {
        int i;

        for(i = 0; i < protocol->childProtocols->count; i++) {
            Protocol *proto = protocol->childProtocols->list[i];

            if(strcmp(other->nameCString, proto->nameCString) == 0)
                return YES;

            if(protocol_conformsToProtocol(proto, other))
                return YES;
        }
        return NO;
    }
}

BOOL protocol_isEqual(Protocol *protocol, Protocol *other) {
    // UNIMPLEMENTED
    return NO;
}
