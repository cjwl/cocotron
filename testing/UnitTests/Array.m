//
//  Array.m
//  UnitTests
//
//  Created by Johannes Fortmann on 08.05.08.
//  Copyright 2008 -. All rights reserved.
//

#import "Array.h"


@implementation Array
-(void)testMutableArray
{
	id array=[NSMutableArray array];
	for(int i=0; i<1000; i++)
	{
		[array addObject:[NSNumber numberWithInt:i]];
	}
	array=[array copy];
	id otherArray=[array mutableCopy];
	id yetAnotherArray=[array mutableCopy];
	for(id i in array)
	{
		[otherArray removeObject:i];
		
		[yetAnotherArray addObject:i];
	}
	
	STAssertEquals((unsigned)[otherArray count], (unsigned)0, nil);
	STAssertEquals((unsigned)[yetAnotherArray count], (unsigned)2000, nil);
	
	[array release];
	[otherArray release];
	[yetAnotherArray release];
}


@end
