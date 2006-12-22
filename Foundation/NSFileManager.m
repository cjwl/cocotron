/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>, David Young <daver@geeks.org>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>

NSString *NSFileType = @"NSFileType";
NSString *NSFileTypeRegular = @"NSFileTypeRegular";
NSString *NSFileTypeDirectory = @"NSFileTypeDirectory";
NSString *NSFileTypeSymbolicLink = @"NSFileTypeSymbolicLink";
NSString *NSFileTypeCharacterSpecial = @"NSFileTypeCharacterSpecial";
NSString *NSFileTypeBlockSpecial = @"NSFileTypeBlockSpecial";
NSString *NSFileTypeFIFO = @"NSFileTypeFIFO";
NSString *NSFileTypeSocket = @"NSFileTypeSocket";
NSString *NSFileTypeUnknown = @"NSFileTypeUnknown";

NSString *NSFileSize = @"NSFileSize";
NSString *NSFileModificationDate = @"NSFileModificationDate";
NSString *NSFileOwnerAccountName = @"NSFileOwnerAccountName";
NSString *NSFileGroupOwnerAccountName = @"NSFileGroupOwnerAccountName";

NSString *NSFileReferenceCount = @"NSFileReferenceCount";
NSString *NSFileIdentifier = @"NSFileIdentifier";
NSString *NSFileDeviceIdentifier = @"NSFileDeviceIdentifier";
NSString *NSFilePosixPermissions = @"NSFilePosixPermissions";
NSString *NSFileHFSCreatorCode = @"NSFileHFSCreatorCode";
NSString *NSFileHFSTypeCode = @"NSFileHFSTypeCode";

@implementation NSFileManager

+(NSFileManager *)defaultManager {
   return NSThreadSharedInstance([[NSPlatform currentPlatform] fileManagerClassName]);
}

-(NSData *)contentsAtPath:(NSString *)path {
   return [NSData dataWithContentsOfFile:path];
}

-(BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data 
             attributes:(NSDictionary *)attributes {
   NSInvalidAbstractInvocation();
   return NO;
}

-(NSArray *)directoryContentsAtPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)path {
// FIX
   return (id)[[self directoryContentsAtPath:path] objectEnumerator];
}

-(BOOL)createDirectoryAtPath:(NSString *)path
                  attributes:(NSDictionary *)attributes {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)fileExistsAtPath:(NSString *)path {
   BOOL foo;
   return [self fileExistsAtPath:path isDirectory:&foo];
}

-(BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)removeFileAtPath:(NSString *)path handler:handler {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)movePath:(NSString *)src toPath:(NSString *)dest handler:handler {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)copyPath:(NSString *)src toPath:(NSString *)dest handler:handler {
   NSInvalidAbstractInvocation();
   return NO;
}

-(NSString *)currentDirectoryPath {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)traverse {
   NSInvalidAbstractInvocation();
   return nil;
}

-(BOOL)isReadableFileAtPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)isWritableFileAtPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)isExecutableFileAtPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)changeFileAttributes:(NSDictionary *)attributes atPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(const char *)fileSystemRepresentationWithPath:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NULL;
}

@end

@implementation NSDictionary(NSFileAttributes)

-(NSDate *)fileModificationDate {
   return [self objectForKey:NSFileModificationDate];
}

-(unsigned long)filePosixPermissions {
   return [[self objectForKey:NSFilePosixPermissions] unsignedLongValue];
}

-(NSString *)fileOwnerAccountName {
   return [self objectForKey:NSFileOwnerAccountName];
}

-(NSString *)fileGroupOwnerAccountName {
   return [self objectForKey:NSFileGroupOwnerAccountName];
}

@end
