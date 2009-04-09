#import <objc/runtime.h>

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
