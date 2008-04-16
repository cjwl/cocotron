//
//  Properties.m
//  UnitTests
//
//  Created by Johannes Fortmann on 16.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

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
