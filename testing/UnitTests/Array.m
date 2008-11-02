/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "Array.h"

@interface NSArray (HiddenStuff)
-(void)_insertObject:(id)obj inArraySortedByDescriptors:(id)desc;
@end


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

-(void)testPrivateSortedInsert
{
   id sortDesc=[[[NSSortDescriptor alloc] initWithKey:@"self" ascending:NO] autorelease];
   id descArray=[NSArray arrayWithObject:sortDesc];
   NSMutableArray *array=[NSMutableArray new];
   
   for(int i=0; i<100; i++)
   {
      [array _insertObject:[NSNumber numberWithInt:rand()] inArraySortedByDescriptors:descArray];
      id other=[array mutableCopy];
      [other sortUsingDescriptors:descArray];

      STAssertEqualObjects(array, other, @"sorted array not equal to array after insertion");
      
      [other release];
   }
   
   [array release];
}

@end
