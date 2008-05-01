/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "ForEach.h"


@implementation ForEach
-(void)testMutableArray
{
	NSMutableArray *array=[NSMutableArray new];
	NSMutableArray *array2=[NSMutableArray new];
	for(int i=0; i<1000; i++)
	{
		[array addObject:[NSNumber numberWithInt:rand()]];
	}
	
	for(id object in array)
	{
		[array2 addObject:object];
	}
	
	STAssertEqualObjects(array, array2, nil);	
}

-(void)mutateArray:(id)array
{
	for(id object in array)
	{
		[array addObject:object];
	}	
}

-(void)testArrayMutation
{
	NSMutableArray *array=[NSMutableArray new];
	for(int i=0; i<1000; i++)
	{
		[array addObject:[NSNumber numberWithInt:rand()]];
	}
	STAssertThrows([self mutateArray:array], nil);
}


-(void)testArray
{
	NSMutableArray *array=[NSMutableArray new];
	NSMutableArray *array2=[NSMutableArray new];
	for(int i=0; i<1000; i++)
	{
		[array addObject:[NSNumber numberWithInt:rand()]];
	}

	array=[[array copy] autorelease];

	for(id object in array)
	{
		[array2 addObject:object];
	}
	
	STAssertEqualObjects(array, array2, nil);	
}


-(void)testSmall
{
	NSMutableArray *array=[NSMutableArray new];
	NSMutableArray *array2=[NSMutableArray new];
	for(int i=0; i<12; i++)
	{
		[array addObject:[NSNumber numberWithInt:rand()]];
	}
	
	for(id object in array)
	{
		[array2 addObject:object];
	}
	
	STAssertEqualObjects(array, array2, nil);	
}



-(void)testSet
{
	NSMutableSet *set=[NSMutableSet new];
	NSMutableSet *set2=[NSMutableSet new];
	for(int i=0; i<1000; i++)
	{
		[set addObject:[NSNumber numberWithInt:rand()]];
	}
	
	for(id object in set)
	{
		[set2 addObject:object];
	}
	
	STAssertEqualObjects(set, set2, nil);	
}

-(void)testCountedSet
{
	NSMutableSet *set=[NSCountedSet new];
	NSMutableSet *set2=[NSCountedSet new];
	for(int i=0; i<1000; i++)
	{
		[set addObject:[NSNumber numberWithInt:rand()%999]];
	}

	for(id object in set)
	{
		[set2 addObject:object];
	}
	
	STAssertFalse([set isEqual:set2], @"should enumerate distinct objects");	
	STAssertEquals([set count], [set2 count], @"number of distinct objects should be the same");	
}
@end
