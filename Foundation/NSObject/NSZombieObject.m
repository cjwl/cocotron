/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSZombieObject.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSString.h>
#import <Foundation/NSInvocation.h>

static NSMapTable *objectToClassName=NULL;

void NSRegisterZombie(NSObject *object) {
   if(objectToClassName==NULL){
    objectToClassName=NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
     NSNonOwnedPointerMapValueCallBacks,0);
   }

   NSMapInsert(objectToClassName,object,((struct objc_object *)object)->isa);
   ((struct objc_object *)object)->isa=objc_lookUpClass("NSZombieObject");
}

@implementation NSZombieObject

-(NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
   Class cls=NSMapGet(objectToClassName,self);
   
   NSLog(@"-[NSZombieObject %x methodSignatureForSelector:%s] %s",self,sel_getName(selector),class_getName((Class)NSMapGet(objectToClassName,self)));
   
   return [cls instanceMethodSignatureForSelector:selector];
}

-(void)forwardInvocation:(NSInvocation *)invocation {
   NSLog(@"-[NSZombieObject %x forwardInvocation:%s] %s",self,sel_getName([invocation selector]),class_getName((Class)NSMapGet(objectToClassName,self)));
}

-(id)forwardSelector:(SEL)selector arguments:(void *)arguments {
   NSLog(@"-[NSZombieObject %x %s] %s",self,sel_getName(selector),class_getName((Class)NSMapGet(objectToClassName,self)));
   return nil;
}

@end

