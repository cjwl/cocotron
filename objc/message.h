#import <objc/runtime.h>

struct objc_super {
    id    receiver;
	Class super_class;
};


OBJC_EXPORT id objc_msgSend(id theReceiver, SEL theSelector, ...);
id     objc_msgSendSuper(struct objc_super *super, SEL op,  ...);
void   objc_msgSendSuper_stret(struct objc_super *super, SEL op, ...);
double objc_msgSend_fpret(id self, SEL op, ...);
void   objc_msgSend_stret(void * stretAddr, id theReceiver, SEL theSelector,  ...);

#define marg_free(margs)
#define marg_getRef(margs, offset, type)
#define marg_getValue(margs, offset, type)
#define marg_malloc(margs, method)
#define marg_setValue(margs, offset, type, value)

// FIXME. TO BE CLEANED UP.

OBJC_EXPORT IMP objc_msg_lookup(id self, SEL selector);
OBJC_EXPORT IMP objc_msg_lookup_super(struct objc_super *super, SEL selector);
OBJC_EXPORT id objc_msg_sendv(id self, SEL selector, unsigned arg_size, void *arg_frame);
