//
//  MessageBenchmark.m
//  UnitTests
//
//  Created by Johannes Fortmann on 17.08.08.
//  Copyright 2008 -. All rights reserved.
//

#import "MessageBenchmark.h"


@implementation MessageBenchmark

-(void)setUp
{
   object=@"Test";
   count = 50000000;
}

-(void)testLookup
{
   int ret=1;
   for(int i=0; i<count; i++) {
      ret|=[self testStuff:object];
   }
   STAssertEquals(ret, 1, nil);
}

-(int)testStuff:(id)string
{
   if(string==object)
   {
      return 1;
   }
   return 0;
}
@end
