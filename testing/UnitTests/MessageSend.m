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