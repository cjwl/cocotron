/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class NSData,NSArray;

FOUNDATION_EXPORT NSString *NSFileHandleConnectionAcceptedNotification;
FOUNDATION_EXPORT NSString *NSFileHandleDataAvailableNotification;
FOUNDATION_EXPORT NSString *NSFileHandleReadCompletionNotification;
FOUNDATION_EXPORT NSString *NSFileHandleReadToEndOfFileCompletionNotification;

FOUNDATION_EXPORT NSString *NSFileHandleNotificationDataItem;
FOUNDATION_EXPORT NSString *NSFileHandleNotificationFileHandleItem;

FOUNDATION_EXPORT NSString *NSFileHandleNotificationMonitorModes;

FOUNDATION_EXPORT NSString *NSFileHandleOperationException;

@interface NSFileHandle : NSObject

+fileHandleForReadingAtPath:(NSString *)path;
+fileHandleForWritingAtPath:(NSString *)path;
+fileHandleForUpdatingAtPath:(NSString *)path;

+fileHandleWithNullDevice;
+fileHandleWithStandardInput;
+fileHandleWithStandardOutput;
+fileHandleWithStandardError;

-(void)closeFile;
-(void)synchronizeFile;

-(unsigned long long)offsetInFile;
-(void)seekToFileOffset:(unsigned long long)offset;
-(unsigned long long)seekToEndOfFile;

-(NSData *)readDataOfLength:(unsigned)length;
-(NSData *)readDataToEndOfFile;
-(NSData *)availableData;

-(void)writeData:(NSData *)data;

-(void)truncateFileAtOffset:(unsigned long long)offset;

-(void)readInBackgroundAndNotifyForModes:(NSArray *)modes;
-(void)readInBackgroundAndNotify;

@end
