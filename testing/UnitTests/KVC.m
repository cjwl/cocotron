/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KVC.h"

@interface RetainLogger : NSObject
{
   int _loggedRetainCount;
   BOOL _logsRetains;
}
@property int loggedRetainCount;
@end

@implementation RetainLogger 

@synthesize loggedRetainCount=_loggedRetainCount;

-(id)retain {
   _loggedRetainCount++;
   return [super retain];
}

-(void)release {
   _loggedRetainCount--;
   [super release];
}
@end


@implementation KVC

-(BOOL)accessInstanceVariablesDirectly {
   return _inDirectTest;
}

-(void)cleanUp {
   _inDirectTest=NO;  
}

-(void)testDirectSetting {
   RetainLogger* logger=[[[RetainLogger alloc] init] autorelease];
   _inDirectTest=YES;

   logger.loggedRetainCount=0;
   id pool=[NSAutoreleasePool new];
   
   [self setValue:logger forKey:@"objectInstanceVariable"];
   
   [pool drain];
   
   STAssertEquals(logger.loggedRetainCount, 1, @"Direct setting retains object value");
   STAssertEqualObjects(_objectInstanceVariable, logger, @"Direct setting sets object value");
   
   RetainLogger* logger2=[[RetainLogger alloc] init];
   
   
   pool=[NSAutoreleasePool new];
   
   [self setValue:logger2 forKey:@"objectInstanceVariable"];
   
   [pool drain];
   
   STAssertEquals(logger.loggedRetainCount, 0, @"Direct setting releases old object value");

   [logger2 release];
   [logger2 release];

}


-(void)testKVC
{
	NSMutableDictionary *dict=[NSMutableDictionary dictionary];
	
	[dict setValue:@"value" forKey:@"key"];

	STAssertEqualObjects([dict valueForKey:@"key"] , @"value", nil);
}

-(void)testMutableArray
{
	id container=[KVCArrayContainer new];
	
	id array=[container mutableArrayValueForKey:@"contents"];

	[array addObject:@"SomeObject"];
	[array insertObject:@"Stuff" atIndex:0];
	[array removeObject:@"SomeObject"];
	

	[container release];	
}

-(void)testDescription {
   STAssertNotNil([self valueForKeyPath:@"description"], nil);
}
@end



@implementation KVCArrayContainer

-(void)_setContents:(id)contents
{
	if(_contents!=contents)
	{
		[_contents release];
		_contents=[contents retain];
	}
}

-(id)contents
{
	return _contents;
}

-(id)init
{
	if(self=[super init])
	{
		_contents=[NSMutableArray new];
	}
	return self;
}

-(void)dealloc
{
	[_contents release];
	[super dealloc];
}
@end