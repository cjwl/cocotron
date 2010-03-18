#import "objc_protocol.h"

@implementation Protocol(public)

const char *protocol_getName(Protocol *protocol) {
   return protocol->nameCString;
}

objc_property_t protocol_getProperty(Protocol *protocol,const char *name,BOOL isRequired,BOOL isInstance) {
   // UNIMPLEMENTED
   return NULL;
}

objc_property_t *protocol_copyPropertyList(Protocol *protocol,unsigned int *countp) {
   // UNIMPLEMENTED
   return NULL;
}

Protocol **protocol_copyProtocolList(Protocol *protocol,unsigned int *countp) {
   // UNIMPLEMENTED
   return NULL;
}

struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *protocol,BOOL isRequired,BOOL isInstance,unsigned int *countp) {
   // UNIMPLEMENTED
   return NULL;
}

struct objc_method_description protocol_getMethodDescription(Protocol *protocol,SEL selector,BOOL isRequired,BOOL isInstance) {
   struct objc_method_description result={0,0};
   // UNIMPLEMENTED
   return result;
}

BOOL protocol_conformsToProtocol(Protocol *protocol,Protocol *other) {
   // UNIMPLEMENTED
   return NO;
}

BOOL protocol_isEqual(Protocol *protocol,Protocol *other) {
   // UNIMPLEMENTED
   return NO;
}

@end
