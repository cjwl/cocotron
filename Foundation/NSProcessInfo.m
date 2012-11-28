/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSThread-Private.h>
#import <Foundation/NSPlatform.h>
#import <objc/runtime.h>

@implementation NSProcessInfo

int                 NSProcessInfoArgc=0;
const char * const *NSProcessInfoArgv=NULL;

-(NSInteger)incrementCounter {
   NSInteger result;

   [_counterLock lock];
   _counter++;
   result=_counter;
   [_counterLock unlock];

   return result;
}

+(NSProcessInfo *)processInfo {
   return NSThreadSharedInstance(@"NSProcessInfo");
}

-init {
   _environment=nil;
   _arguments=nil;
   _hostName=nil;
   _processName=nil;
   _counter=0;
   _counterLock=[NSLock new];
   return self;
}

-(NSUInteger)processorCount {
   NSUnimplementedMethod();
   return 0;
}

-(NSUInteger)activeProcessorCount {
   NSUnimplementedMethod();
   return 0;
}

-(uint64_t)physicalMemory {
   NSUnimplementedMethod();
   return 0;
}

-(NSUInteger)operatingSystem {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)operatingSystemName {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)operatingSystemVersionString {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)hostName {
   if(_hostName==nil){
    _hostName=[[[NSPlatform currentPlatform] hostName] retain];

    if(_hostName==nil)
     _hostName=@"HOSTNAME";
   }

   return _hostName;
}

-(NSString *)processName {
   if(_processName==nil){
    NSArray *arguments=[self arguments];

    if([arguments count]>0)
     _processName=[[[[[self arguments] objectAtIndex:0]
       lastPathComponent] stringByDeletingPathExtension] retain];

    if(_processName==nil){
     _processName=@"";
    }
   }

   return _processName;
}

-(void)setProcessName:(NSString *)name {
   [_processName release];
   _processName=[name copy];
}

-(int)processIdentifier {
   return NSPlatformProcessID();
}

-(NSArray *)arguments {
   if(_arguments==nil){
    _arguments=[[[NSPlatform currentPlatform] arguments] retain];
   }

   return _arguments;
}

-(NSDictionary *)environment {
   if(_environment==nil)
    _environment=[[[NSPlatform currentPlatform] environment] retain];

   return _environment;
}

-(NSString *)globallyUniqueString {
   return NSStringWithFormat(@"%@_%d_%d_%d_%d",[self hostName],
     [self processIdentifier],0,0,[self incrementCounter]);
}

@end

FOUNDATION_EXPORT void NSInitializeProcess(int argc,const char *argv[])
{
    //no more used
}

void __NSInitializeProcess(int argc,const char *argv[])
{
    NSProcessInfoArgc=argc;
    NSProcessInfoArgv=argv;
#if !defined(GCC_RUNTIME_3)
#if !defined(APPLE_RUNTIME_4)
    OBJCInitializeProcess();
#endif
#ifdef __APPLE__
    // init NSConstantString reference-tag (see http://lists.apple.com/archives/objc-language/2006/Jan/msg00013.html)
    // only Darwin ppc!?
    Class cls = objc_lookUpClass("NSConstantString");
    memcpy(&_NSConstantStringClassReference, cls, sizeof(_NSConstantStringClassReference));
    cls = objc_lookUpClass("NSDarwinString");
    memcpy(&__CFConstantStringClassReference, cls, sizeof(_NSConstantStringClassReference));
    
    // Override the compiler version of the class
    //objc_addClass(&_NSConstantStringClassReference);
#endif
#endif

}

