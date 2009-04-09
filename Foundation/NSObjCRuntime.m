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

#import <objc/runtime.h>
#import <Foundation/objc_size_alignment.h>
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

   NSPlatform *p = [NSPlatform currentPlatform];
   NSLogFormat(@"%@ %@[%d:%x] %@",date,process,[p processID],[p threadID],string);
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

	*size=objc_sizeof_type(type);
	*alignment=objc_alignof_type(type);
	return objc_skip_type_specifier(type);
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

   return objc_lookUpClass(cString);
}

NSString *NSStringFromClass(Class class) {
   if(class==Nil)
    return nil;

   return NSString_cStringWithBytesAndZero(NULL,class_getName(class));
}

