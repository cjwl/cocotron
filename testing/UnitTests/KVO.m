/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KVO.h"


@implementation KVO

@synthesize someKey;
@synthesize otherKey;
@synthesize dict;
@synthesize lastObserved;
@synthesize propertyWithBadDependencies;

+(NSSet*)keyPathsForValuesAffectingNewStyleDerived
{
	return [NSSet setWithObject:@"dict.derivedProperty"];
}

+(NSSet*)keyPathsForValuesAffectingPropertyWithBadDependencies
{
	return [NSSet setWithObjects:@"dict.derivedProperty", @"path.which.doesnt.exist", nil];
}


-(void)setUp
{
	[isa setKeys:[NSArray arrayWithObjects:@"someKey", @"someOtherKey", nil] triggerChangeNotificationsForDependentKey:@"derived"];
	dict=[NSMutableDictionary new];
}

-(void)dealloc
{
	[someKey release];
   [otherKey release];
	[dict release];
	[lastObserved release];
	[super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == 0) {
		observerCalled++;
		self.lastObserved=keyPath;
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

-(void)testDependencyKVOException
{
	observerCalled=0;
   STAssertThrowsSpecificNamed([self addObserver:self forKeyPath:@"propertyWithBadDependencies" options:0 context:nil],
                                NSException,
                                NSUndefinedKeyException,
                                nil);
   STAssertTrue([self observationInfo]==nil, nil);

   STAssertThrows([self removeObserver:self forKeyPath:@"propertyWithBadDependencies"], nil);
   
   STAssertTrue([self observationInfo]==nil, nil);
}

-(void)testDeepKVOException
{
	observerCalled=0;

   STAssertThrowsSpecificNamed([self addObserver:self forKeyPath:@"nonExisting.other" options:0 context:nil],
                               NSException,
                               NSUndefinedKeyException,
                               nil);
   STAssertTrue([self observationInfo]==nil, nil);
   
   STAssertNoThrowSpecificNamed([self addObserver:self forKeyPath:@"nonExisting" options:0 context:nil],
                                NSException,
                                NSUndefinedKeyException,
                                nil);
	
   STAssertNoThrow([self removeObserver:self forKeyPath:@"nonExisting"], nil);
   STAssertThrows([self removeObserver:self forKeyPath:@"nonExisting.other"], nil);
   STAssertTrue([self observationInfo]==nil, nil);

}


-(void)testMultiKVO
{
	observerCalled=0;
	[self addObserver:self forKeyPath:@"someKey" options:0 context:nil];
	[self addObserver:self forKeyPath:@"otherKey" options:0 context:nil];
	
   self.otherKey=@"SomeValue";	
	STAssertTrue(observerCalled==1, nil);
   observerCalled=0;
   
	self.someKey=@"SomeValue";	
	STAssertTrue(observerCalled==1, nil);
   observerCalled=0;
   
	STAssertEqualObjects(lastObserved, @"someKey", nil);
   
   [self removeObserver:self forKeyPath:@"otherKey"];
   [self removeObserver:self forKeyPath:@"someKey"];
   STAssertTrue([self observationInfo]==nil, nil);
}

-(void)testKVO
{
	observerCalled=0;
	[self addObserver:self forKeyPath:@"someKey" options:0 context:nil];
	
	self.someKey=@"SomeValue";	
	
	[self removeObserver:self forKeyPath:@"someKey"];
	STAssertTrue(observerCalled==1, nil);
	STAssertEqualObjects(lastObserved, @"someKey", nil);
   STAssertTrue([self observationInfo]==nil, nil);
}

-(void)testDeepKVO
{
	[self addObserver:self forKeyPath:@"dict.someKey" options:0 context:nil];

	observerCalled=0;
	[dict setObject:@"val1" forKey:@"someKey"];
	STAssertTrue(observerCalled==1, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val1", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	observerCalled=0;
	[dict setValue:@"val2" forKey:@"someKey"];
	STAssertTrue(observerCalled==1, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val2", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	observerCalled=0;
	[self setValue:@"val3" forKeyPath:@"dict.someKey"];
	STAssertTrue(observerCalled==1, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val3", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	[self removeObserver:self forKeyPath:@"dict.someKey"];
}


-(void)testDeps
{
	[self addObserver:self forKeyPath:@"derived" options:0 context:nil];

	observerCalled=0;
	[self setValue:@"val3" forKeyPath:@"someKey"];
	STAssertTrue(observerCalled==1, nil);	
	STAssertEqualObjects(lastObserved, @"derived", nil);

	[self removeObserver:self forKeyPath:@"derived"];
	
	[self addObserver:self forKeyPath:@"newStyleDerived" options:0 context:nil];
	
	observerCalled=0;
	[self setValue:@"val3" forKeyPath:@"dict.derivedProperty"];
	STAssertTrue(observerCalled==1, nil);	
	STAssertEqualObjects(lastObserved, @"newStyleDerived", nil);

	[self removeObserver:self forKeyPath:@"newStyleDerived"];
   STAssertTrue([self observationInfo]==nil, nil);
}

-(void)testNameAndClass {
   [self addObserver:self forKeyPath:@"someKey" options:0 context:nil];
   
   STAssertEqualObjects([self className], @"KVO", nil);

   STAssertEqualObjects([self class], [KVO class], nil);
   STAssertEqualObjects([self classForCoder], [KVO class], nil);
                         
   [self removeObserver:self forKeyPath:@"someKey"];

}

-(NSString*)derived
{
	return someKey;
}

-(NSString *)newStyleDerived
{
	return [dict objectForKey:@"derivedProperty"];
}
@end
