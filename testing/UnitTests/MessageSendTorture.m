//
//  MessageSendTorture.m
//  UnitTests
//
//  Created by Johannes Fortmann on 23.09.08.
//  Copyright 2008 -. All rights reserved.
//

#import "MessageSendTorture.h"
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#import <string.h>
#import <ctype.h>

#define SEL_PREFIX "_torture_"
#define NUM_SELECTORS 5000

extern id objc_msgSend(id self, SEL op, ...);

@interface MessageSendTortureThread : NSThread
{
   id _delegate;
   BOOL _msgSend;

}
@property (retain) id delegate;
@property (assign) BOOL useMsgSend;

@end

@implementation MessageSendTortureThread
@synthesize useMsgSend=_msgSend;
@synthesize delegate=_delegate;
-(void)main
{
   [_delegate callSelectors:_msgSend];
}
@end




@implementation MessageSendTorture

-(int)_torture_
{
   const char* name=sel_getName(_cmd);
   name+=strlen(SEL_PREFIX);
   return atoi(name);   
}

+(void)initialize
{
   BOOL didInit=NO;
   if(!didInit)
   {
      didInit=YES;
      
      struct objc_method_list *list = calloc(sizeof(struct objc_method_list)+NUM_SELECTORS*sizeof(struct objc_method), 1);
      list->method_count=NUM_SELECTORS;
      Method torture=class_getInstanceMethod([self class], @selector(_torture_));
      
      for(int currentMethod=0; currentMethod<NUM_SELECTORS; currentMethod++)
      {
         struct objc_method *newMethod=&list->method_list[currentMethod];
         char buf[strlen(SEL_PREFIX)+10];
         
         sprintf(buf, "%s%i", SEL_PREFIX, currentMethod);
         
         newMethod->method_name=sel_registerName(buf);
         newMethod->method_types=strdup(torture->method_types);
         newMethod->method_imp=torture->method_imp;
      }
      class_addMethods(self, list);
   }
}

-(void)callSelectors:(BOOL)useMsgSend
{
   typedef int	(*TestImp)(id, SEL, ...); 
   
   for(int i=0; i<1000; i++)
   {
      char buf[strlen(SEL_PREFIX)+10];
      int ret=0;
      int currentMethod=rand()%NUM_SELECTORS;
      sprintf(buf, "%s%i", SEL_PREFIX, currentMethod);
      SEL sel=sel_getUid(buf);
      
      if(useMsgSend)
      {
         TestImp send=(TestImp)objc_msgSend;
         ret=send(self, sel);         
      }
      else
      {
         TestImp imp = (TestImp)objc_msg_lookup(self, sel);
         if(imp)
            ret=imp(self, sel);
      }

      if(ret!=currentMethod)
      {
         __sync_add_and_fetch(&_numFailures, 1);
      }
      else
      {
         __sync_add_and_fetch(&_numSuccesses, 1);
      }
   }
}

-(void)testMessageSendTorture
{
   for(int i=0; i<12; i++)
   {
      MessageSendTortureThread *thread=[MessageSendTortureThread new];
      thread.delegate=self;
      thread.useMsgSend=rand()%2;
      [thread start];
      [thread release];
   }
   [self callSelectors:YES];
   [self callSelectors:YES];

   NSLog(@"%i iterations run", _numSuccesses);
   STAssertTrue(_numFailures==0, nil);
}

@end
