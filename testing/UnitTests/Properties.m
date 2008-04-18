/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "Properties.h"

@implementation Properties
@synthesize firstName;
@synthesize lastName;
@dynamic fullName;


- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if(aSelector==@selector(fullName))
	{
		return [self methodSignatureForSelector:@selector(replacementFullName)];
	}
	return [super methodSignatureForSelector:aSelector];	
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if([anInvocation selector]==@selector(fullName))
	{
		[anInvocation setSelector:@selector(replacementFullName)];
		[anInvocation invoke];
	}
	else
		[super forwardInvocation:anInvocation];
}

-(NSString*)replacementFullName
{
	return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
}

-(void)testSetting
{
	self.firstName=@"Johannes";
	self.lastName=@"Fortmann";
	
	STAssertEqualObjects(@"Johannes", firstName, nil);
	STAssertEqualObjects(@"Fortmann", lastName, nil);
}

-(void)testGetting
{
	self.firstName=@"Johannes";
	self.lastName=@"Fortmann";
	
	STAssertEqualObjects(self.firstName, firstName, nil);
	STAssertEqualObjects(self.lastName, lastName, nil);
}

-(void)testDynamic
{
	self.firstName=@"Johannes";
	self.lastName=@"Fortmann";
	
	STAssertEqualObjects(self.fullName, @"Johannes Fortmann", nil);
}

-(void)tearDown
{
	self.firstName=nil;
	self.lastName=nil;
}
@end
