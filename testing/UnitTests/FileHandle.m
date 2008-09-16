/* Copyright (c) 2008 Tobias Platen
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "FileHandle.h"


@implementation FileHandle
-(void) testReadingFromPipe4k
{
	char buffer[4096];
	NSPipe* p=[NSPipe new];
	NSFileHandle* w=[p fileHandleForWriting];
	NSFileHandle* r=[p fileHandleForReading];
	data=[NSData dataWithBytes:&buffer length:sizeof(buffer)];
	[NSThread detachNewThreadSelector:@selector(writingThead:) toTarget:self withObject:w];
	STAssertEqualObjects([r availableData],data,@"read data should match to buffer");
	
}
-(void) testReadingFromPipe4kLess1
{
	char buffer[4095];
	NSPipe* p=[NSPipe new];
	NSFileHandle* w=[p fileHandleForWriting];
	NSFileHandle* r=[p fileHandleForReading];
	data=[NSData dataWithBytes:&buffer length:sizeof(buffer)];
	[NSThread detachNewThreadSelector:@selector(writingThead:) toTarget:self withObject:w];
	STAssertEqualObjects([r availableData],data,@"read data should match to buffer");
	
}
-(void) testReadingFromPipeToEnd8k
{
	char buffer[8*1024];
	NSPipe* p=[NSPipe new];
	NSFileHandle* w=[p fileHandleForWriting];
	NSFileHandle* r=[p fileHandleForReading];
	data=[NSData dataWithBytes:&buffer length:sizeof(buffer)];
	[NSThread detachNewThreadSelector:@selector(writingTheadClosesHandle:) toTarget:self withObject:w];
	STAssertEqualObjects([r readDataToEndOfFile],data,@"read data should match to buffer");
	
}
-(void) testReadingFromPipeToEnd1k
{
	char buffer[1024];
	NSPipe* p=[NSPipe new];
	NSFileHandle* w=[p fileHandleForWriting];
	NSFileHandle* r=[p fileHandleForReading];
	data=[NSData dataWithBytes:&buffer length:sizeof(buffer)];
	[NSThread detachNewThreadSelector:@selector(writingTheadClosesHandle:) toTarget:self withObject:w];
	STAssertEqualObjects([r readDataToEndOfFile],data,@"read data should match to buffer");	
}


-(void) writingThead:(NSFileHandle*)w
{
	[w writeData:data];
}
-(void) writingTheadClosesHandle:(NSFileHandle*)w
{
	[w writeData:data];
	[w closeFile];
}

@end
