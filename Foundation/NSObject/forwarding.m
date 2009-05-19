#import <objc/runtime.h>

#if 0
@interface NSObject(fastforwarding)
-forwardingTargetForSelector:(SEL)selector;
@end

id NSObjCGetFastForwardTarget(id object,SEL selector){
   id check=nil;
   
   if([object respondsToSelector:@selector(forwardingTargetForSelector:)])
    if((check=[object forwardingTargetForSelector:selector])==object)
     check=nil;
   
   return check;
}

void NSObjCForward(id object,SEL selector,...){
   id check=NSObjCGetFastForwardFunction(object,selector);
   
   if(check!=nil){
    object=check;
    ;// jmp objc_msgSend
   }
   
   va_list arguments;
   
   va_start(arguments,selector);
   
   NSObjCForwardInvocation(object,selector,arguments);
   
   va_end(arguments);
}

void NSObjCForward_stret(void *value,id object,SEL selector,...){
   id check=NSObjCGetFastForwardFunction(object,selector);
   
   if(check!=nil){
    object=check;
    ;// jmp objc_msgSend_stret
   }
   
   va_list arguments;
   
   va_start(arguments,selector);
   
   NSObjCForwardInvocation(object,selector,arguments);
   
   va_end(arguments);
}
#endif

// both of these suck, we should be using NSMethodSignature types to extract the frame and create the NSInvocation here
#ifdef SOLARIS
id objc_msgForward(id object,SEL message,...){
   Class       class=object->isa;
   struct objc_method *method;
   va_list     arguments;
   unsigned    i,frameLength,limit;
   unsigned   *frame;
   
   if((method=class_getInstanceMethod(class,@selector(_frameLengthForSelector:)))==NULL){
    OBJCRaiseException("OBJCDoesNotRecognizeSelector","%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name,sel_getName(message),message);
    return nil;
   }
   frameLength=method->method_imp(object,@selector(_frameLengthForSelector:),message);
   frame=__builtin_alloca(frameLength);
   
   va_start(arguments,message);
   frame[0]=object;
   frame[1]=message;
   for(i=2;i<frameLength/sizeof(unsigned);i++)
    frame[i]=va_arg(arguments,unsigned);
   
   if((method=class_getInstanceMethod(class,@selector(forwardSelector:arguments:)))!=NULL)
    return method->method_imp(object,@selector(forwardSelector:arguments:),message,frame);
   else {
    OBJCRaiseException("OBJCDoesNotRecognizeSelector","%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name,sel_getName(message),message);
    return nil;
   }
}
#else
id objc_msgForward(id object,SEL message,...){
   Class       class=object->isa;
   struct objc_method *method;
   void       *arguments=&object;

   if((method=class_getInstanceMethod(class,@selector(forwardSelector:arguments:)))!=NULL)
    return method->method_imp(object,@selector(forwardSelector:arguments:),message,arguments);
   else {
    OBJCRaiseException("OBJCDoesNotRecognizeSelector","%c[%s %s(%d)]", class_isMetaClass(class) ? '+' : '-', class->name,sel_getName(message),message);
    return nil;
   }
}
#endif
