/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "SizeAndAlignment.h"
#import "Forwarding.h"

#define TEST_TYPE(type) { size_t size, alignment;\
NSGetSizeAndAlignment(@encode(type), &size, &alignment);\
STAssertEquals(size, sizeof(type), @"size of type %s: %s is %i, should be %i", #type, @encode(type), size, sizeof(type));\
STAssertEquals(alignment, __alignof__(type), @"alignment of type %s: %s is %i, should be %i", #type,  @encode(type), alignment, __alignof__(type)); }

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
   TEST_TYPE(double);
   TEST_TYPE(long);
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
