#import <objc/runtime.h>
#import <objc/Protocol.h>

typedef struct {
    @defs(Protocol)
} OBJCProtocolTemplate;

OBJC_EXPORT void OBJCRegisterProtocol(OBJCProtocolTemplate *protocolTemplate);

