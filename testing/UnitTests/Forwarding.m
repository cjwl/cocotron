/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "Forwarding.h"


@interface Forwarding (UnimplementedMethods)
-(float)doStuffWithFloats:(float)first :(float)second :(float)third;
-(int)doStuffWithInts:(int)first :(int)second :(int)third;
-(NSString*)doStuffWithObjects:(NSString*)first :(NSString*)second :(NSString*)third;
-(id)doStuffWithStructs:(NSSize)size :(char)c :(NSRange)range :(NSRect)rect :(double)d :(long long)l;
-(TestingStruct)testingStructWithParam:(float)x;
@end

@implementation Forwarding
-(void)forwardInvocation:(NSInvocation*)inv
{
	if([inv selector]==@selector(doStuffWithObjects:::))
	{
		[inv setSelector:@selector(concatObjects:::)];
		[inv invoke];
		return;
	}
	if([inv selector]==@selector(doStuffWithInts:::))
	{
		[inv setSelector:@selector(addInts:::)];
		[inv invoke];
		return;
	}
	if([inv selector]==@selector(doStuffWithFloats:::))
	{

		[inv setSelector:@selector(addFloats:::)];
      
		[inv invoke];
		return;
	}
	if([inv selector]==@selector(doStuffWithStructs::::::))
	{
		[inv setSelector:@selector(makeStringFromStructs::::::)];
		[inv invoke];
		return;
	}
	if([inv selector]==@selector(testingStructWithParam:))
	{
		[inv setSelector:@selector(returnTestingStructWithParam:)];
		[inv invoke];
		return;
	}
	
	
	[super forwardInvocation:inv];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	if(sel==@selector(doStuffWithObjects:::))
		return [self methodSignatureForSelector:@selector(concatObjects:::)];
	
	if(sel==@selector(doStuffWithInts:::))
		return [self methodSignatureForSelector:@selector(addInts:::)];

	if(sel==@selector(doStuffWithFloats:::))
		return [self methodSignatureForSelector:@selector(addFloats:::)];
	
	if(sel==@selector(doStuffWithStructs::::::))
		return [self methodSignatureForSelector:@selector(makeStringFromStructs::::::)];
	
	if(sel==@selector(testingStructWithParam:))
		return [self methodSignatureForSelector:@selector(returnTestingStructWithParam:)];

	return [super methodSignatureForSelector:sel];
}

-(NSString*)concatObjects:(NSString*)first :(NSString*)second :(NSString*)third
{
	beenInMethodFlag=YES;
	return [NSString stringWithFormat:@"%@%@%@", first, second, third];
}

-(int)addInts:(int)first :(int)second :(int)third
{
	beenInMethodFlag=YES;
	return first+second+third;
}

-(float)addFloats:(float)first :(float)second :(float)third
{
	beenInMethodFlag=YES;
	return first+second+third;
}


-(id)makeStringFromStructs:(NSSize)size :(char)c :(NSRange)range :(NSRect)rect :(double)d :(long long)l
{
	beenInMethodFlag=YES;
	return [NSString stringWithFormat:@"%i %i %i %i %i %i %i %i %i %i %i",
			(int)size.width, (int)size.height,
			c,
			range.location, range.length,
			(int)rect.origin.x, (int)rect.origin.y,
			(int)rect.size.width, (int)rect.size.height,
			(int)d, (int)l];
}

-(TestingStruct)returnTestingStructWithParam:(float)x
{
	beenInMethodFlag=YES;
	TestingStruct ret={0};
	ret.a=x;
	ret.b=x+1;
	ret.c=x+2;
	ret.d=x+3;
	ret.e=x+4;
	return ret;
}

-(void)testForwardStructs
{
	beenInMethodFlag=NO;
	id retObj=[self doStuffWithStructs:NSMakeSize(1, 2)
									  :3
									  :NSMakeRange(4, 5)
									  :NSMakeRect(6, 7, 8, 9)
									  :10
									  :11];
	
	STAssertTrue(beenInMethodFlag, nil);
	STAssertEqualObjects(@"1 2 3 4 5 6 7 8 9 10 11", retObj, nil);
}

-(void)testStructReturn
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
	
	stuff.ret=[self testingStructWithParam:x];
	if(stuff.guard!=0xdeadbeef)
		NSLog(@"error: guard overwritten, will probably crash");
	if(stuff.guard2!=0xdeadbeef)
		NSLog(@"error: guard 2 overwritten, will probably crash");
	TestingStruct cmp={0};
	cmp.a=x;
	cmp.b=x+1;
	cmp.c=x+2;
	cmp.d=x+3;
	cmp.e=x+4;
	
	STAssertTrue(beenInMethodFlag, nil);
	STAssertEquals(stuff.ret, cmp, nil);
	
}

-(void)testForwardSimple
{
	beenInMethodFlag=NO;
	id retObj=[self doStuffWithObjects:@"First" :@"Second" :@"Third"];
	
	STAssertTrue(beenInMethodFlag, nil);
	STAssertEqualObjects(@"FirstSecondThird", retObj, nil);
	
	beenInMethodFlag=NO;
	int retInt=[self doStuffWithInts:1 :2 :3];
	
	STAssertTrue(beenInMethodFlag, nil);
	STAssertEquals(6, retInt, nil);
}


-(void)testFloatReturn
{
   beenInMethodFlag=NO;
	float ret=[self doStuffWithFloats:1. :2. :3.];
   ret=[self doStuffWithFloats:1. :2. :3.];
	STAssertTrue(beenInMethodFlag, nil);   
	STAssertEqualsWithAccuracy(6.0f, ret, 0.001, nil);   
}

@end
