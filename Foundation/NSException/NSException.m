/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSThread-Private.h>
#import <Foundation/NSObjCRuntime.h>
#import <stdio.h>

NSString *NSGenericException=@"NSGenericException";
NSString *NSInvalidArgumentException=@"NSInvalidArgumentException";
NSString *NSRangeException=@"NSRangeException";

NSString *NSInternalInconsistencyException=@"NSInternalInconsistencyException";
NSString *NSMallocException=@"NSMallocException";

NSString *NSParseErrorException=@"NSParseErrorException";

@implementation NSException

+(void)raise:(NSString *)name format:(NSString *)format,... {
   va_list  arguments;

   va_start(arguments,format);

   return [self raise:name format:format arguments:arguments];
}

+(void)raise:(NSString *)name format:(NSString *)format arguments:(va_list)arguments {
   [[self exceptionWithName:name
     reason:NSStringWithFormatArguments(format,arguments) userInfo:nil] raise];
}

void __NSPushExceptionFrame(NSExceptionFrame *frame) {
   frame->parent=NSThreadCurrentHandler();
   frame->exception=nil;

   NSThreadSetCurrentHandler(frame);
}

void __NSPopExceptionFrame(NSExceptionFrame *frame) {
   NSThreadSetCurrentHandler(frame->parent);
}

static void defaultHandler(NSException *exception){  
   fprintf(stderr,"*** Uncaught exception <%s> *** %s\n",[[exception name] cString],[[exception reason] cString]);
}

void _NSRaiseException(NSException *exception) {
   NSExceptionFrame *top=NSThreadCurrentHandler();

   if(top==NULL){
    NSUncaughtExceptionHandler *proc=NSGetUncaughtExceptionHandler();

    if(proc==NULL)
     defaultHandler(exception);
    else
     proc(exception);
   }
   else {
    NSThreadSetCurrentHandler(top->parent);

    top->exception=exception;

    longjmp(top->state,1);
   }
}

NSUncaughtExceptionHandler *NSGetUncaughtExceptionHandler(void) {
   return NSThreadUncaughtExceptionHandler();
}

void NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *proc) {
   NSThreadSetUncaughtExceptionHandler(proc);
}

-initWithName:(NSString *)name reason:(NSString *)reason
  userInfo:(NSDictionary *)userInfo {
   _name=[name copy];
   _reason=[reason copy];
   _userInfo=[userInfo retain];
   return self;
}

-(void)dealloc {
   [_name release];
   [_reason release];
   [_userInfo release];
   NSDeallocateObject(self);
}

+(NSException *)exceptionWithName:(NSString *)name reason:(NSString *)reason
  userInfo:(NSDictionary *)userInfo {
   return [[[self allocWithZone:NULL] initWithName:name reason:reason userInfo:userInfo] autorelease];
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<NSException: %@ %@>",_name,_reason];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-initWithCoder:(NSCoder *)coder {
   NSUnsupportedMethod();
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnsupportedMethod();
}

-(void)raise {
   //NSLog(@"RAISE %@",self);

   _NSRaiseException(self);
}

-(NSString *)name {
   return _name;
}

-(NSString *)reason {
   return _reason;
}

-(NSDictionary *)userInfo {
   return _userInfo;
}

@end

