
#ifdef GCC_RUNTIME_3
IMP objc_msg_forward(id rcv, SEL message);
#endif
id objc_msgForward(id object,SEL message,...);
void objc_msgForward_stret(void *result,id object,SEL message,...);
