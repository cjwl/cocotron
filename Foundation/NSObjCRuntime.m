/* Copyright (c) 2006-2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSProcessInfo.h>

#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>

#import <Foundation/ObjectiveC.h>
#import <objc/objc.h>
#include <ctype.h>

static void NSLogFormat(NSString *format,...){
   NSString *string;
   va_list   arguments;

   va_start(arguments,format);

   string=NSStringNewWithFormat(format,nil,arguments,NULL);

   [[NSPlatform currentPlatform] logString:string];

   [string release];
}

static inline void NSLogMessageString(NSString *string){
   NSString *date=[[NSDate date]
       descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S.%F"
                            timeZone:nil locale:nil];
   NSString *process=[[NSProcessInfo processInfo] processName];

   NSLogFormat(@"%@ %@[%d] %@",date,process,[[NSPlatform currentPlatform] processID],string);
}

void NSLogv(NSString *format,va_list arguments) {
   NSString *string=NSStringNewWithFormat(format,nil,arguments,NULL);

   NSLogMessageString(string);

   [string release];
}

void NSLog(NSString *format,...) {
   va_list arguments;

   va_start(arguments,format);

   NSLogv(format,arguments);
}

const char *NSGetSizeAndAlignment(const char *type,unsigned *size,
  unsigned *alignment) {
   BOOL quit=NO;
	
	unsigned ignore=0;
	if(!size)
		size=&ignore;
	if(!alignment)
		alignment=&ignore;

   *size=0;
   *alignment=0;

   for(;*type && !quit;type++){
    switch(*type){
     case 'r':
     case 'n':
     case 'N':
     case 'o':
     case 'O':
     case 'R':
     case 'V':
      break;

     case 'c':
      *size=sizeof(char);
      quit=YES;
      break;

     case 'i':
      *size=sizeof(int);
      quit=YES;
      break;

     case 's':
      *size=sizeof(short);
      quit=YES;
      break;

     case 'l':
      *size=sizeof(long);
      quit=YES;
      break;

     case 'q':
      *size=sizeof(long long);
      quit=YES;
      break;

     case 'C':
      *size=sizeof(unsigned char);
      quit=YES;
      break;

     case 'I':
      *size=sizeof(unsigned int);
      quit=YES;
      break;

     case 'S':
      *size=sizeof(unsigned short);
      quit=YES;
      break;

     case 'L':
      *size=sizeof(unsigned long);
      quit=YES;
      break;

     case 'Q':
      *size=sizeof(unsigned long long);
      quit=YES;
      break;

     case 'f':
      *size=sizeof(float);
      quit=YES;
      break;

     case 'd':
      *size=sizeof(double);
      quit=YES;
      break;

     case 'v':
      *size=0;
      quit=YES;
      break;

     case '*':
      *size=sizeof(char *);
      quit=YES;
      break;

     case '@':
      *size=sizeof(id);
      quit=YES;
      break;

     case '#':
      *size=sizeof(Class);
      quit=YES;
      break;

     case ':':
      *size=sizeof(SEL);
      quit=YES;
      break;
			
	  case '?':
		*size=0;
		quit=YES;

     case '[':
    {
        unsigned subsize;
        type++;
        int len = atoi(type);
        while (isdigit(*type))
            type++;
        type=NSGetSizeAndAlignment(type,&subsize,alignment);
        *size=subsize*len;
        quit=YES;
    }
     break;

     case '{':
      type++;
      if(*type=='?')
       type++;
      if(*type=='=')
       type++;
      do {
       unsigned subsize,subalignment;

       type=NSGetSizeAndAlignment(type,&subsize,&subalignment);
       *size+=subsize;
      }while(*type!='}');
      quit=YES;
      break;
                
    case '(':
    {
        type++;
        if(*type=='?')
            type++;
        if(*type=='=')
            type++;
        do {
            unsigned subsize,subalignment;
                        
            type=NSGetSizeAndAlignment(type,&subsize,&subalignment);
            *size=MAX(subsize, *size);
            *alignment=MAX(subalignment, *alignment);
        }while(*type!=')');
        quit=YES;
        break;
    }
                
     case '^':
	 {
		 unsigned subsize,subalignment;
		 type++;
		 	 
		 type=NSGetSizeAndAlignment(type,&subsize,&subalignment);
		 type--;
		 *size=sizeof(void*);
		 quit=YES;
		 break;
	 }

     default:
		 NSLog(@"unimplemented for %s %c", type, *type);
      NSUnimplementedFunction();
      quit=YES;
      break;
    }
   }
   return type;
}

SEL NSSelectorFromString(NSString *selectorName) {
   SEL      result;
   
   unsigned length=[selectorName length];
   char     cString[length+1];

   [selectorName getCString:cString maxLength:length];

   if((result=sel_getUid(cString))==NULL)
    result=sel_registerName(cString);
   
   return result;
}

NSString *NSStringFromSelector(SEL selector) {
   if(selector==NULL)
    return @"";

   return NSString_cStringWithBytesAndZero(NULL,sel_getName(selector));
}

Class NSClassFromString(NSString *className) {
   unsigned length=[className length];
   char     cString[length+1];

   [className getCString:cString maxLength:length];

   return OBJCClassFromString(cString);
}

NSString *NSStringFromClass(Class class) {
   if(class==Nil)
    return nil;

   return NSString_cStringWithBytesAndZero(NULL,OBJCStringFromClass(class));
}

