/* Copyright (c) 2009 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "MessageBenchmark.h"
#import "Forwarding.h"

@implementation MessageBenchmark (MessageSend)

-(void)testMessageSend
{
   int ret=1;
   for(int i=0; i<count; i++) {
      ret|=[self testStuff:object];
   }
   STAssertEquals(ret, 1, nil);
}

+(int)classMethod
{
   return 1;
}

-(void)testClassMethod
{
   STAssertEquals([MessageBenchmark classMethod], 1, nil);
}

-(void)testSuperMethod
{
   STAssertTrue([[super self] isKindOfClass:[MessageBenchmark class]], nil);
}

-(float)floatReturn
{
   return 1.0;
}


-(void)testMessageSendFloatReturn
{
   STAssertTrue([self floatReturn]==1.0, nil);
}


@end

@implementation Forwarding (MessageSend)

-(void)testRegularStructs
{
	beenInMethodFlag=NO;
	id retObj=[self makeStringFromStructs:NSMakeSize(1, 2)
                                        :3
                                        :NSMakeRange(4, 5)
                                        :NSMakeRect(6, 7, 8, 9)
                                        :10
                                        :11];

	STAssertTrue(beenInMethodFlag, nil);
	STAssertEqualObjects(@"1 2 3 4 5 6 7 8 9 10 11", retObj, nil);
}

-(void)testRegularStructReturn
{
	beenInMethodFlag=NO;
	int x=12;
	struct stuff
	{
		int guard;
		TestingStruct ret;
		int guard2;
	} stuff;
	stuff.guard=0xdeadbeef;
	stuff.guard2=0xdeadbeef;
	
	stuff.ret=[self returnTestingStructWithParam:x];
	TestingStruct cmp={0};
	cmp.a=x;
	cmp.b=x+1;
	cmp.c=x+2;
	cmp.d=x+3;
	cmp.e=x+4;
	
	STAssertTrue(beenInMethodFlag, nil);
	STAssertEquals(stuff.ret, cmp, nil);
	
}
@end