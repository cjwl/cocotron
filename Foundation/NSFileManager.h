/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>

@class NSData,NSDate,NSDirectoryEnumerator;

FOUNDATION_EXPORT NSString *NSFileType;
FOUNDATION_EXPORT NSString    *NSFileTypeRegular;
FOUNDATION_EXPORT NSString    *NSFileTypeDirectory;
FOUNDATION_EXPORT NSString    *NSFileTypeSymbolicLink;

FOUNDATION_EXPORT NSString    *NSFileTypeCharacterSpecial;
FOUNDATION_EXPORT NSString    *NSFileTypeBlockSpecial;
FOUNDATION_EXPORT NSString    *NSFileTypeFIFO;

FOUNDATION_EXPORT NSString    *NSFileTypeSocket;

FOUNDATION_EXPORT NSString    *NSFileTypeUnknown;

FOUNDATION_EXPORT NSString *NSFileSize;
FOUNDATION_EXPORT NSString *NSFileModificationDate;
FOUNDATION_EXPORT NSString *NSFileOwnerAccountName;
FOUNDATION_EXPORT NSString *NSFileGroupOwnerAccountName;

FOUNDATION_EXPORT NSString *NSFilePosixPermissions;
FOUNDATION_EXPORT NSString *NSFileReferenceCount;
FOUNDATION_EXPORT NSString *NSFileIdentifier;
FOUNDATION_EXPORT NSString *NSFileDeviceIdentifier;

@interface NSFileManager : NSObject

+(NSFileManager *)defaultManager;

-(NSData *)contentsAtPath:(NSString *)path;

-(BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data 
             attributes:(NSDictionary *)attributes;

-(NSArray *)directoryContentsAtPath:(NSString *)path;
-(NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)path;

-(BOOL)createDirectoryAtPath:(NSString *)path
                  attributes:(NSDictionary *)attributes;

-(NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)path;

-(BOOL)fileExistsAtPath:(NSString *)path;
-(BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;

-(BOOL)removeFileAtPath:(NSString *)path handler:handler;

-(BOOL)movePath:(NSString *)src toPath:(NSString *)dest handler:handler;
-(BOOL)copyPath:(NSString *)src toPath:(NSString *)dest handler:handler;


-(NSString *)currentDirectoryPath;

-(NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)traverse;

-(BOOL)isReadableFileAtPath:(NSString *)path;
-(BOOL)isWritableFileAtPath:(NSString *)path;
-(BOOL)isExecutableFileAtPath:(NSString *)path;

// this only does date
-(BOOL)changeFileAttributes:(NSDictionary *)attributes atPath:(NSString *)path;

-(const char *)fileSystemRepresentationWithPath:(NSString *)path;

@end

@interface NSObject(NSFileManager_handler)
-(BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSDictionary *)dictionary;
-(void)fileManager:(NSFileManager *)fileManager willProcessPath:(NSString *)path;
@end

@interface NSDictionary(NSFileManager_fileAttributes)
-(NSDate *)fileModificationDate;
-(unsigned long)filePosixPermissions;
-(NSString *)fileOwnerAccountName;
-(NSString *)fileGroupOwnerAccountName;
-(NSString *)fileType;
@end
