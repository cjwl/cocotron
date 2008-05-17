//
//  SizeAndAlignment.m
//  UnitTests
//
//  Created by Johannes Fortmann on 20.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SizeAndAlignment.h"
#import "Forwarding.h"

#define TEST_TYPE(type) { size_t size, alignment;\
NSGetSizeAndAlignment(@encode(type), &size, &alignment);\
STAssertEquals(size, sizeof(type), @"size of type %i != %i", size, sizeof(type));\
STAssertEquals(alignment, __alignof__(type), @"alignment of type %i != %i", alignment, __alignof__(type)); }

typedef struct 
   {
      float a;
      union
      {
         long long b;
         char c;
      } blah;
      TestingStruct str;
      TestingStruct *strPtr;
      NSArray *array;
      union
      {
         float d;
         double e;
      };
   } TestingStruct2;

@implementation SizeAndAlignment
-(void)testPrimitives
{
	TEST_TYPE(float);
	TEST_TYPE(int);
	TEST_TYPE(char);
	TEST_TYPE(void*);
	TEST_TYPE(SEL);
	TEST_TYPE(id);

}

-(void)testComposites
{
	TEST_TYPE(TestingStruct);
   TEST_TYPE(TestingStruct2);
}
@end
