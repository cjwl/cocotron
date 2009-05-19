#import <objc/runtime.h>
#import <objc/Protocol.h>

typedef struct {
   Class isa;
   const char *nameCString;
   struct objc_protocol_list *childProtocols;
   struct OBJCMethodDescriptionList *instanceMethods;
   struct OBJCMethodDescriptionList *classMethods;
} OBJCProtocolTemplate;

OBJC_EXPORT void OBJCRegisterProtocol(OBJCProtocolTemplate *protocolTemplate);

