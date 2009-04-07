#import <objc/runtime.h>

const char *ivar_getName(Ivar ivar){
   return ivar->ivar_name;
}

size_t ivar_getOffset(Ivar ivar){
   return ivar->ivar_offset;
}

const char *ivar_getTypeEncoding(Ivar ivar){
   return ivar->ivar_type;
}
