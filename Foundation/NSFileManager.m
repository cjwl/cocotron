/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

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
#import <Foundation/NSConcreteDirectoryEnumerator.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPathUtilities.h>

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

-delegate {
   NSUnimplementedMethod();
   return 0;
}
-(void)setDelegate:delegate {
   NSUnimplementedMethod();
}

-(NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)errorp {
   NSUnimplementedMethod();
   return 0;
}
-(NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)changeCurrentDirectoryPath:(NSString *)path {
   NSUnimplementedMethod();
   return 0;
}
-(NSArray *)componentsToDisplayForPath:(NSString *)path {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 {
   NSUnimplementedMethod();
   return 0;
}
-(NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)copyItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)displayNameAtPath:(NSString *)path {
   NSBundle *bundle=[NSBundle bundleWithPath:path];
   NSString *name=nil;
   if(bundle) {
    NSDictionary *localizedInfo=[bundle localizedInfoDictionary];
    name=[localizedInfo objectForKey:@"CFBundleDisplayName"];
    if(!name)
     name=[localizedInfo objectForKey:@"CFBundleName"];
   }
   if(!name)
    name=[path lastPathComponent];
   return name;
}

-(NSDictionary *)fileSystemAttributesAtPath:(NSString *)path {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isDeletableFileAtPath:(NSString *)path {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)linkItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)linkPath:(NSString *)source toPath:(NSString *)destination handler:handler {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)stringWithFileSystemRepresentation:(const char *)string length:(NSUInteger)length {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)subpathsAtPath:(NSString *)path {
   NSUnimplementedMethod();
   return 0;
}
-(NSArray *)subpathsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
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
    return [[[NSConcreteDirectoryEnumerator alloc] initWithPath: path] autorelease];
}

-(BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)intermediates attributes:(NSDictionary *)attributes error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)createSymbolicLinkAtPath:(NSString *)path pathContent:(NSString *)destination {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)destPath error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)path {
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

-(NSString *)fileType {
   return [self objectForKey:NSFileType];
}

-(unsigned long long)fileSize {
   return [[self objectForKey:NSFileSize] unsignedLongLongValue];
}

@end
