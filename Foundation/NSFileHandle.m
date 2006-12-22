/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSRaise.h>

NSString *NSFileHandleConnectionAcceptedNotification = @"NSFileHandleConnectionAcceptedNotification";
NSString *NSFileHandleDataAvailableNotification = @"NSFileHandleDataAvailableNotification";
NSString *NSFileHandleReadCompletionNotification = @"NSFileHandleReadCompletionNotification";
NSString *NSFileHandleReadToEndOfFileCompletionNotification = @"NSFileHandleReadToEndOfFileCompletionNotification";

NSString *NSFileHandleNotificationDataItem = @"NSFileHandleNotificationDataItem";
NSString *NSFileHandleNotificationFileHandleItem = @"NSFileHandleNotificationFileHandleItem";

NSString *NSFileHandleNotificationMonitorModes = @"NSFileHandleNotificationMonitorModes";

NSString *NSFileHandleOperationException = @"NSFileHandleOperationException";

@implementation NSFileHandle

+fileHandleForReadingAtPath:(NSString *)path {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleForReadingAtPath:path];
}

+fileHandleForWritingAtPath:(NSString *)path {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleForWritingAtPath:path];
}

+fileHandleForUpdatingAtPath:(NSString *)path {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleForUpdatingAtPath:path];
}

+fileHandleWithNullDevice {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleWithNullDevice];
}

+fileHandleWithStandardInput {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleWithStandardInput];
}

+fileHandleWithStandardOutput {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleWithStandardOutput];
}

+fileHandleWithStandardError {
   return [[[NSPlatform currentPlatform] fileHandleClass] fileHandleWithStandardError];
}

-(void)closeFile {
   NSInvalidAbstractInvocation();
}

-(void)synchronizeFile {
   NSInvalidAbstractInvocation();
}

-(unsigned long long)offsetInFile {
   NSInvalidAbstractInvocation();
   return 0;
}

-(void)seekToFileOffset:(unsigned long long)offset {
   NSInvalidAbstractInvocation();
}

-(unsigned long long)seekToEndOfFile {
   NSInvalidAbstractInvocation();
   return 0;
}

-(NSData *)readDataOfLength:(unsigned)length {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSData *)readDataToEndOfFile {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSData *)availableData {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)writeData:(NSData *)data {
   NSInvalidAbstractInvocation();
}

-(void)truncateFileAtOffset:(unsigned long long)offset {
   NSInvalidAbstractInvocation();
}

-(void)readInBackgroundAndNotifyForModes:(NSArray *)modes {
   NSInvalidAbstractInvocation();
}

-(void)readInBackgroundAndNotify {
   [self readInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

@end
