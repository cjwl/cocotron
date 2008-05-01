/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KVC.h"

@implementation KVC
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