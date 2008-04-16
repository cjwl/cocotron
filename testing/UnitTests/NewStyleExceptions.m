//
//  NewStyleExceptions.m
//  UnitTests
//
//  Created by Johannes Fortmann on 16.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NewStyleExceptions.h"


@implementation NewStyleExceptions

-(void)raiseException
{
	[NSException raise:NSInvalidArgumentException
				format:nil];
}

-(void)throwString
{
	@throw(@"SomeString");
}


-(void)testTryCatch
{
	id test=nil;
	@try
	{
		[self raiseException];
	}
	@catch(NSException *a)
	{
		test=a;
	}
	
	STAssertNotNil(test, nil);
}

-(void)testFinally
{
	id test=nil;
	@try
	{
		[self raiseException];
	}
	@catch(NSException *a)
	{
		test=a;
	}
	@finally
	{
		test=@"Test";
	}
	
	STAssertEqualObjects(test, @"Test", nil);
}

-(void)testMatch
{
	id test=nil;
	@try
	{
		[self throwString];
	}
	@catch(NSException *a)
	{
	}
	@catch(NSString *a)
	{
		test=a;
	}
	STAssertEqualObjects(test, @"SomeString", nil);
}

-(void)testJumpOut
{
	id test=@"Test";
	BOOL loop=YES;
	while(loop)
	{
		@try
		{
			if(loop)
			{
				loop=NO;
				continue;
			}
		}
		@catch(NSException *a)
		{
		}
		@catch(NSString *a)
		{
			test=a;
		}
		@finally
		{
			test=nil;
		}
		
		STAssertNil(test, nil);
	}
}

@end
