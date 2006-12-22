/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

@class NSTimeZone, NSThread, NSInputSource;

@interface NSPlatform : NSObject

+currentPlatform;

-(NSInputSource *)parentDeathInputSource;

-(Class)inputSourceSetClass;

-(NSString *)fileManagerClassName;
-(Class)taskClass;
-(Class)fileHandleClass;
-(Class)pipeClass;
-(Class)lockClass;
-(Class)persistantDomainClass;

-(NSString *)userName;
-(NSString *)fullUserName;
-(NSString *)homeDirectory;
-(NSString *)temporaryDirectory;
-(NSString *)executableDirectory;
-(NSString *)resourceNameSuffix;
-(NSString *)loadableObjectFileExtension;
-(NSString *)loadableObjectFilePrefix;

-(NSArray *)arguments;
-(NSDictionary *)environment;

-(NSTimeInterval)timeIntervalSinceReferenceDate;

-(NSTimeZone *)systemTimeZone;

-(unsigned)processID;

-(NSString *)hostName;

-(NSString *)DNSHostName;
-(NSArray *)addressesForDNSHostName:(NSString *)name;

-(void)sleepThreadForTimeInterval:(NSTimeInterval)interval;

-(void)logString:(NSString *)string;

-(void *)contentsOfFile:(NSString *)path length:(unsigned *)length;
-(void *)mapContentsOfFile:(NSString *)path length:(unsigned *)length;
-(void)unmapAddress:(void *)ptr length:(unsigned)length;

-(BOOL)writeContentsOfFile:(NSString *)path bytes:(const void *)bytes length:(unsigned)length atomically:(BOOL)atomically;

-(void)checkEnvironmentKey:(NSString *)key value:(NSString *)value;

@end

// These functions are implemented in the platform subproject

NSThread *NSPlatformCurrentThread();
