/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSRaise.h>
#import "NSFileHandle_stream.h"

NSString *NSFileHandleConnectionAcceptedNotification = @"NSFileHandleConnectionAcceptedNotification";
NSString *NSFileHandleDataAvailableNotification = @"NSFileHandleDataAvailableNotification";
NSString *NSFileHandleReadCompletionNotification = @"NSFileHandleReadCompletionNotification";
NSString *NSFileHandleReadToEndOfFileCompletionNotification = @"NSFileHandleReadToEndOfFileCompletionNotification";

NSString *NSFileHandleNotificationDataItem = @"NSFileHandleNotificationDataItem";
NSString *NSFileHandleNotificationFileHandleItem = @"NSFileHandleNotificationFileHandleItem";

NSString *NSFileHandleNotificationMonitorModes = @"NSFileHandleNotificationMonitorModes";

NSString *NSFileHandleOperationException = @"NSFileHandleOperationException";

@interface NSFileHandle(ImplementedInPlatform)
+(Class)concreteSubclass;
@end

@implementation NSFileHandle

+allocWithZone:(NSZone *)zone {
   if(self==[NSFileHandle class])
    return NSAllocateObject([self concreteSubclass],0,NULL);

   return NSAllocateObject(self,0,zone);
}

+fileHandleForReadingAtPath:(NSString *)path {
   return [[self concreteSubclass] fileHandleForReadingAtPath:path];
}

+fileHandleForWritingAtPath:(NSString *)path {
   return [[self concreteSubclass] fileHandleForWritingAtPath:path];
}

+fileHandleForUpdatingAtPath:(NSString *)path {
   return [[self concreteSubclass] fileHandleForUpdatingAtPath:path];
}

+fileHandleWithNullDevice {
   return [[self concreteSubclass] fileHandleWithNullDevice];
}

+fileHandleWithStandardInput {
   return [[self concreteSubclass] fileHandleWithStandardInput];
}

+fileHandleWithStandardOutput {
   return [[self concreteSubclass] fileHandleWithStandardOutput];
}

+fileHandleWithStandardError {
   return [[self concreteSubclass] fileHandleWithStandardError];
}

-initWithFileDescriptor:(int)descriptor {
    return [self initWithFileDescriptor:descriptor closeOnDealloc:YES];
}

-initWithFileDescriptor:(int)descriptor closeOnDealloc:(BOOL)closeOnDealloc {
   NSSocket *socket=[[[NSSocket alloc] initWithFileDescriptor:descriptor] autorelease];
   
   [self dealloc];
   if(socket==nil)
    return nil;

   return [[NSFileHandle_stream alloc] initWithSocket:socket closeOnDealloc:closeOnDealloc];
}

-(int)fileDescriptor {
   NSInvalidAbstractInvocation();
   return -1;
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

-(void)readToEndOfFileInBackgroundAndNotifyForModes:(NSArray *)modes {
   NSInvalidAbstractInvocation();
}

-(void)readToEndOfFileInBackgroundAndNotify {
   [self readToEndOfFileInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

-(void)acceptConnectionInBackgroundAndNotifyForModes:(NSArray *)modes {
   NSInvalidAbstractInvocation();
}

-(void)acceptConnectionInBackgroundAndNotify {
   [self acceptConnectionInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

-(void)waitForDataInBackgroundAndNotifyForModes:(NSArray *)modes {
   NSInvalidAbstractInvocation();
}

-(void)waitForDataInBackgroundAndNotify {
   [self waitForDataInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

@end
