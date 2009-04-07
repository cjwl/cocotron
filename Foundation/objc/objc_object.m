#import <objc/runtime.h>

Class object_getClass(id object) {
   return object->isa;
}

const char *object_getClassName(id object) {
   return class_getName(object->isa);
}

static Ivar instanceVariableWithName(struct objc_class *class,const char *name) {
   for(;;class=class->super_class){
    struct objc_ivar_list *ivarList=class->ivars;
    int i;

    for(i=0;ivarList!=NULL && i<ivarList->ivar_count;i++){
     if(strcmp(ivarList->ivar_list[i].ivar_name,name)==0)
      return &(ivarList->ivar_list[i]);
    }
    if(class->isa->isa==class)
     break;
   }

   return NULL;
}

static void ivarCopy(void *vdst,unsigned offset,void *vsrc,unsigned length){
   unsigned char *dst=vdst;
   unsigned char *src=vsrc;
   unsigned       i;

   for(i=0;i<length;i++)
    dst[offset+i]=src[i];
}

// This only works for 'id' ivars
Ivar object_setInstanceVariable(id object,const char *name,void *value) {
   Ivar ivar=instanceVariableWithName(object->isa,name);

   if(ivar!=NULL)
    ivarCopy(object,ivar->ivar_offset,value,sizeof(id));
   
   return ivar;
}
