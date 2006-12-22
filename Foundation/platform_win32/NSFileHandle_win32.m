/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSFileHandle_win32.h>
#import <Foundation/NSPlatform_win32.h>
#import <Foundation/NSHandleMonitor_win32.h>
#import <Foundation/NSReadInBackground_win32.h>
#import <Foundation/NSData.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRaise.h>

@implementation NSFileHandle_win32

-initWithHandle:(HANDLE)handle closeOnDealloc:(BOOL)closeOnDealloc {
   _handle=handle;
   _closeOnDealloc=closeOnDealloc;
   return self;
}

-(void)dealloc {
   if(_closeOnDealloc)
    [self closeFile];

   [_background detach];

   [super dealloc];
}


+fileHandleForReadingAtPath:(NSString *)path {
   HANDLE handle=CreateFile([path fileSystemRepresentation],
    GENERIC_READ,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);

   if(handle==NULL)
    return nil;

   return [[[self allocWithZone:NULL] initWithHandle:handle closeOnDealloc:YES] autorelease]; 
}

+fileHandleForWritingAtPath:(NSString *)path {
   HANDLE handle=CreateFile([path fileSystemRepresentation],
    GENERIC_WRITE,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);

   if(handle==NULL)
    return nil;

   return [[[self allocWithZone:NULL] initWithHandle:handle closeOnDealloc:YES] autorelease]; 
}

+fileHandleForUpdatingAtPath:(NSString *)path {
   HANDLE handle=CreateFile([path fileSystemRepresentation],
    GENERIC_WRITE|GENERIC_READ,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);

   if(handle==NULL)
    return nil;

   return [[[self allocWithZone:NULL] initWithHandle:handle closeOnDealloc:YES] autorelease]; 
}

+fileHandleWithNullDevice {
   NSUnimplementedMethod();
   return nil;
}

+fileHandleWithStandardInput {
   return [[[self allocWithZone:NULL] initWithHandle:GetStdHandle(STD_INPUT_HANDLE) closeOnDealloc:NO] autorelease];
}

+fileHandleWithStandardOutput {
   return [[[self allocWithZone:NULL] initWithHandle:GetStdHandle(STD_OUTPUT_HANDLE) closeOnDealloc:NO] autorelease];
}

+fileHandleWithStandardError {
   return [[[self allocWithZone:NULL] initWithHandle:GetStdHandle(STD_ERROR_HANDLE) closeOnDealloc:NO] autorelease];
}

-(HANDLE)fileHandle {
   return _handle;
}

-(void)closeFile {
   CloseHandle(_handle);
   _handle=NULL;
}

-(void)synchronizeFile {
   if(!FlushFileBuffers(_handle))
    Win32Assert("FlushFileBuffers");
}

-(unsigned long long)offsetInFile {
   NSUnimplementedMethod();
   return 0;
}

-(void)seekToFileOffset:(unsigned long long)offset {
   LONG  highWord=offset>>32;

   SetFilePointer(_handle,offset&0xFFFFFFFF,&highWord,FILE_BEGIN);

//   Win32Assert("SetFilePointer");
}

-(unsigned long long)seekToEndOfFile {
   unsigned long long result=0;
   LONG  highWord=0;
   DWORD lowWord=SetFilePointer(_handle,0,&highWord,FILE_END);

   Win32Assert("SetFilePointer");

   result= highWord;
   result<<=32;
   result|=lowWord;

   return result;
}

-(NSData *)readDataOfLength:(unsigned)length {
   NSMutableData *result=[NSMutableData dataWithLength:length];
   DWORD          readLength;

   if(!ReadFile(_handle,[result mutableBytes],length,&readLength,NULL)){
    return nil;
   }

   [result setLength:readLength];

   return result;
}

-(NSData *)readDataToEndOfFile {
   NSUnimplementedMethod();
   return nil;
}

-(NSData *)availableData {
   NSUnimplementedMethod();
   return nil;
}

-(void)writeData:(NSData *)data {
   DWORD bytesWritten=0;

   if(!WriteFile(_handle,[data bytes],[data length],&bytesWritten,NULL))
    Win32Assert("WriteFile");
}

-(void)truncateFileAtOffset:(unsigned long long)offset {
   NSUnimplementedMethod();
}

-(void)readInBackground:(NSReadInBackground_win32 *)rib data:(NSData *)data {
   NSDictionary   *userInfo;
   NSNotification *note;

   userInfo=[NSDictionary dictionaryWithObject:data forKey:NSFileHandleNotificationDataItem];
   note=[NSNotification notificationWithName:NSFileHandleReadCompletionNotification object:self userInfo:userInfo];

   [_background detach];
   _background=nil;

   [[NSNotificationCenter defaultCenter] postNotification:note];
}

-(void)readInBackgroundAndNotifyForModes:(NSArray *)modes {
   if(_background!=nil)
    [NSException raise:NSInternalInconsistencyException format:@"file handle has background activity already"];

   _background=[NSReadInBackground_win32 readInBackgroundWithFileHandle:self modes:modes];
}

@end
