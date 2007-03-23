/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSFileManager_win32.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSThread-Private.h>

#import <Foundation/NSPlatform_win32.h>

#import <windows.h>

@implementation NSFileManager_win32

-(BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data 
             attributes:(NSDictionary *)attributes {
   return [[NSPlatform currentPlatform] writeContentsOfFile:path bytes:[data bytes] length:[data length] atomically:YES];
}

-(NSArray *)directoryContentsAtPath:(NSString *)path {
   NSMutableArray *result=[NSMutableArray array];
   WIN32_FIND_DATA findData;
   HANDLE          handle=FindFirstFile([[path stringByAppendingString:@"\\*.*"] fileSystemRepresentation],&findData);

   if(handle==INVALID_HANDLE_VALUE)
    return nil;

   do{
    if(strcmp(findData.cFileName,".")!=0 && strcmp(findData.cFileName,"..")!=0)
     [result addObject:[NSString stringWithCString:findData.cFileName]];
   }while(FindNextFile(handle,&findData));

   FindClose(handle);

   return result;
}

-(BOOL)createDirectoryAtPath:(NSString *)path
                  attributes:(NSDictionary *)attributes {
   return CreateDirectory([path fileSystemRepresentation],NULL)?YES:NO;
}

-(BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
   DWORD attributes=GetFileAttributes([path fileSystemRepresentation]);

   if(attributes==0xFFFFFFFF)
    return NO;

   *isDirectory=(attributes&FILE_ATTRIBUTE_DIRECTORY)?YES:NO;

   return YES;
#if 0
   struct stat buf;

   *isDirectory=NO;

   if(stat([path fileSystemRepresentation],&buf)<0)
    return NO;

   if((buf.st_mode&S_IFMT)==S_IFDIR)
    *isDirectory=YES;

   return YES;
#endif
}


// we dont want to use fileExists... because it chases links 
-(BOOL)_isDirectory:(NSString *)path {
   DWORD attributes=GetFileAttributes([path fileSystemRepresentation]);

   if(attributes==0xFFFFFFFF)
    return NO;

   return (attributes&FILE_ATTRIBUTE_DIRECTORY)?YES:NO;
}

-(BOOL)removeFileAtPath:(NSString *)path handler:handler {
   const char *fsrep=[path fileSystemRepresentation];
   DWORD       attribute=GetFileAttributes(fsrep);

   if([path isEqualToString:@"."] || [path isEqualToString:@".."])
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] path should not be . or ..",isa,SELNAME(_cmd)];

   if(attribute==0xFFFFFFFF)
    return NO;

   if(attribute&FILE_ATTRIBUTE_READONLY){
    attribute&=~FILE_ATTRIBUTE_READONLY;
    if(!SetFileAttributes(fsrep,attribute))
     return NO;
   }

   if(![self _isDirectory:path]){
    if(!DeleteFile(fsrep))
     return NO;
   }
   else {
    NSArray *contents=[self directoryContentsAtPath:path];
    int      i,count=[contents count];

    for(i=0;i<count;i++){
     NSString *fullPath=[path stringByAppendingPathComponent:[contents objectAtIndex:i]];
     if(![self removeFileAtPath:fullPath handler:handler])
      return NO;
    }

    if(!RemoveDirectory(fsrep))
     return NO;
   }
   return YES;
}

-(BOOL)movePath:(NSString *)src toPath:(NSString *)dest handler:handler {
   return MoveFile([src fileSystemRepresentation],[dest fileSystemRepresentation])?YES:NO;
}

-(BOOL)copyPath:(NSString *)src toPath:(NSString *)dest handler:handler {
   BOOL isDirectory;

   if(![self fileExistsAtPath:src isDirectory:&isDirectory])
    return NO;

   if(!isDirectory){
    if(!CopyFile([src fileSystemRepresentation],[dest fileSystemRepresentation],YES))
     return NO;
   }
   else {
    NSArray *files=[self directoryContentsAtPath:src];
    int      i,count=[files count];

    if(!CreateDirectory([dest fileSystemRepresentation],NULL))
     return NO;

    for(i=0;i<count;i++){
     NSString *name=[files objectAtIndex:i];
     NSString *subsrc=[src stringByAppendingPathComponent:name];
     NSString *subdst=[dest stringByAppendingPathComponent:name];

     if(![self copyPath:subsrc toPath:subdst handler:handler])
      return NO;
    }

   }

   return YES;
}

-(NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)traverse {
   NSMutableDictionary       *result=[NSMutableDictionary dictionary];
   WIN32_FILE_ATTRIBUTE_DATA  fileData;
   NSDate                    *date;

   if(!GetFileAttributesEx([path fileSystemRepresentation],GetFileExInfoStandard,&fileData))
    return nil;

   date=[NSDate dateWithTimeIntervalSinceReferenceDate:Win32TimeIntervalFromFileTime(fileData.ftLastWriteTime)];
   [result setObject:date forKey:NSFileModificationDate];

   // dth
   NSString* fileType = NSFileTypeRegular;
   if (fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
          fileType = NSFileTypeDirectory;
   // FIX: Support for links and other attributes needed!

   [result setObject:fileType forKey:NSFileType];
   [result setObject:@"USER" forKey:NSFileOwnerAccountName];
   [result setObject:@"GROUP" forKey:NSFileGroupOwnerAccountName];
   [result setObject:[NSNumber numberWithUnsignedLong:0666]
              forKey:NSFilePosixPermissions];

   return result;
}

-(BOOL)isReadableFileAtPath:(NSString *)path {
   DWORD attributes=GetFileAttributes([path fileSystemRepresentation]);

   if(attributes==-1)
    return NO;

   if(attributes&FILE_ATTRIBUTE_DIRECTORY)
    return NO;

   return YES;
}

-(BOOL)isWritableFileAtPath:(NSString *)path {
   DWORD attributes=GetFileAttributes([path fileSystemRepresentation]);

   if(attributes==-1)
    return NO;

   if(attributes&(FILE_ATTRIBUTE_DIRECTORY|FILE_ATTRIBUTE_READONLY))
    return NO;

   return YES;
}

-(BOOL)isExecutableFileAtPath:(NSString *)path {
   DWORD attributes=GetFileAttributes([path fileSystemRepresentation]);

   if(attributes==-1)
    return NO;

   if(attributes&(FILE_ATTRIBUTE_DIRECTORY))
    return NO;

   return [[[path pathExtension] uppercaseString] isEqualToString:@"EXE"];
}

-(BOOL)changeFileAttributes:(NSDictionary *)attributes atPath:(NSString *)path {
   NSUnimplementedMethod();
   return NO;
#if 0
   NSDate *date=[attributes objectForKey:NSFileModificationDate];

   if(date!=nil){
    time_t timep[2]={ time(NULL),[date timeIntervalSince1970] };
    if(utime((char *)[path fileSystemRepresentation],timep)<0)
     return NO;
   }
   return YES;
#endif
}

-(NSString *)currentDirectoryPath {
   char  path[MAX_PATH+1];
   DWORD length;

   length=GetCurrentDirectory(MAX_PATH+1,path);
   Win32Assert("GetCurrentDirectory");

   return [NSString stringWithCString:path length:length];
}


-(const char *)fileSystemRepresentationWithPath:(NSString *)path {
   unsigned i,length=[path length];
   unichar  buffer[length];
   BOOL     converted=NO;

   [path getCharacters:buffer];

   for(i=0;i<length;i++){
    if(buffer[i]=='/'){
     buffer[i]='\\';
     converted=YES;
    }
   }

   if(converted){
    //NSLog(@"%s %@",SELNAME(_cmd),path);
    path=[NSString stringWithCharacters:buffer length:length];
   }

   return [path cString];
}

@end
