#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

static inline void _KGInvalidAbstractInvocation(SEL selector,id object,const char *file,int line) {
   [NSException raise:NSInvalidArgumentException
     format:@"-%s only defined for abstract class. Define -[%@ %s] in %s:%d!",
       sel_getName (selector),[object class], sel_getName (selector),file,line];
}

static inline void _KGUnimplementedMethod(SEL selector,id object,const char *file,int line) {
   NSLog(@"-[%@ %s] unimplemented in %s at %d",[object class],sel_getName(selector),file,line);
}

#define KGInvalidAbstractInvocation() \
  _KGInvalidAbstractInvocation(_cmd,self,__FILE__,__LINE__)

#define KGUnimplementedMethod() \
 _KGUnimplementedMethod(_cmd,self,__FILE__,__LINE__)
