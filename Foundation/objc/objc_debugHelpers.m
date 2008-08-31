/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <signal.h>
#import <setjmp.h>
#import <objc/objc.h>
#import <objc/objc-class.h>
#import <string.h>

#import <Foundation/NSMutableArray.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

extern Class objc_lookUpClass(const char* name);

static void *_objc_returnAddress(unsigned frame)
{
   void *ret=0;
#define ADDR(x) case x: ret=__builtin_return_address(x); break;
   switch(frame)
   {
         ADDR(0)
         ADDR(1)
         ADDR(2)
         ADDR(3)
         ADDR(4)
         ADDR(5)
         ADDR(6)
         ADDR(7)
         ADDR(8)
         ADDR(9)
         ADDR(10)
         ADDR(11)
         ADDR(12)
         ADDR(13)
         ADDR(14)
         ADDR(15)
         ADDR(16)
         ADDR(17)
         ADDR(18)
         ADDR(19)
         ADDR(20)
         ADDR(21)
         ADDR(22)
      default:
         ;
   }
#undef ADDR
   
   return ret;
}

static jmp_buf handleBadAccess;

static void _objc_badAccessHandler()
{
   longjmp(handleBadAccess, 1);
}

id _NSStackTrace()
{
#ifdef DEBUG
   NSMutableArray *ret=[NSMutableArray array];

#ifdef SIGSEGV
   void *oldSegv=signal(SIGSEGV, _objc_badAccessHandler);
#endif
#ifdef SIGBUS
   void *oldBus=signal(SIGBUS, _objc_badAccessHandler);
#endif

   // only _objc_guardedReturnAddress may fail in the below code (because of a corrupted/unexpected stack)
   // since we're not in a library function at that time, we can longjmp to the following error handling routine
   if(setjmp(handleBadAccess))
   {
      NSLog(@"Protection fault during creation of stack trace.");
      [ret addObject:@"<invalid frame>"];
      goto restore;
   }
   
   int frame=0;
   void *addr=_objc_returnAddress(frame);
   
   while(addr)
   {
      [ret addObject:[NSValue valueWithPointer:addr]];
      frame++;
      addr=_objc_returnAddress(frame);
   }
   
restore:
#ifdef SIGSEGV
   signal(SIGSEGV, oldSegv);
#endif
#ifdef SIGBUS
   signal(SIGBUS, oldBus);
#endif

   return ret;
#else
   return [NSArray arrayWithObject:@"Stack trace unavailable in Release builds"];
#endif
}


static id objc_lookUpMetaClass(const char *name) {
   Class c=objc_lookUpClass(name);
   if(c)
      return c->isa;
   return nil;
}

BOOL _objc_checkObject(volatile id object)
{
   // assume no objects below a certain address 
   if(object<(id)0x2000)
      return NO;
   // objects begin at even addresses
   if((int)object%4!=0)
      return NO;
   volatile Class isa=object->isa;
   
   if(isa<(Class)0x2000)
      return NO;
   if((int)isa%4!=0)
      return NO;
   
   // check if name is all-ascii. We can't assume that name points to a nul-terminated string,
   // so only copy the first 256 characters.
   char *saneName=__builtin_alloca(256);
   strncpy(saneName, isa->name, 256);
   saneName[255]='\0';
   unsigned char* cur;
   for(cur=saneName; *cur!='\0'; cur++) {
      if((*cur<=32 || *cur>128))
      {
         return NO;
      }
   }
   // name is ok; lookup class and compare with what it should be
   Class accordingToName=Nil;
   
   if(isa->info&CLASS_INFO_META)
      accordingToName=objc_lookUpMetaClass(saneName);
   else
      accordingToName=objc_lookUpClass(saneName);
   
   if(isa==accordingToName)
      return YES;
   
   return NO;
}
