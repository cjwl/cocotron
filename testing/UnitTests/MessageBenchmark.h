//
//  MessageBenchmark.h
//  UnitTests
//
//  Created by Johannes Fortmann on 17.08.08.
//  Copyright 2008 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface MessageBenchmark : SenTestCase {
   int count;
   id object;
}

-(int)testStuff:(id)string;
@end
