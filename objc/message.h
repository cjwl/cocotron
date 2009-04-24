#import <objc/runtime.h>

struct objc_super {
    id    receiver;
	Class super_class;
};


OBJC_EXPORT id     objc_msgSend(id self,SEL selector,...);
OBJC_EXPORT id     objc_msgSendSuper(struct objc_super *super,SEL selector,...);

OBJC_EXPORT void   objc_msgSend_stret(id self, SEL selector,  ...);
OBJC_EXPORT void   objc_msgSendSuper_stret(struct objc_super *super,SEL selector,...);

OBJC_EXPORT double objc_msgSend_fpret(id self,SEL selector,...);

// FIXME. TO BE CLEANED UP.

OBJC_EXPORT IMP objc_msg_lookup(id self, SEL selector);
OBJC_EXPORT IMP objc_msg_lookup_super(struct objc_super *super, SEL selector);
