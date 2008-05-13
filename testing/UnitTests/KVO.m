//
//  KVO.m
//  UnitTests
//
//  Created by Johannes Fortmann on 08.05.08.
//  Copyright 2008 -. All rights reserved.
//

#import "KVO.h"


@implementation KVO
@synthesize someKey;
@synthesize dict;
@synthesize lastObserved;

+(NSSet*)keyPathsForValuesAffectingNewStyleDerived
{
	return [NSSet setWithObject:@"dict.derivedProperty"];
}

-(void)setUp
{
	[isa setKeys:[NSArray arrayWithObjects:@"someKey", @"someOtherKey", nil] triggerChangeNotificationsForDependentKey:@"derived"];
	dict=[NSMutableDictionary new];
}

-(void)dealloc
{
	[someKey release];
	[dict release];
	[lastObserved release];
	[super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == 0) {
		observerCalled=YES;
		self.lastObserved=keyPath;
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


-(void)testKVO
{
	observerCalled=NO;
	[self addObserver:self forKeyPath:@"someKey" options:0 context:nil];
	
	self.someKey=@"SomeValue";	
	
	[self removeObserver:self forKeyPath:@"someKey"];
	STAssertTrue(observerCalled, nil);
	STAssertEqualObjects(lastObserved, @"someKey", nil);
}

-(void)testDeepKVO
{
	[self addObserver:self forKeyPath:@"dict.someKey" options:0 context:nil];

	observerCalled=NO;
	[dict setObject:@"val1" forKey:@"someKey"];
	STAssertTrue(observerCalled, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val1", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	observerCalled=NO;
	[dict setValue:@"val2" forKey:@"someKey"];
	STAssertTrue(observerCalled, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val2", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	observerCalled=NO;
	[self setValue:@"val3" forKeyPath:@"dict.someKey"];
	STAssertTrue(observerCalled, nil);
	STAssertEqualObjects([dict valueForKey:@"someKey"], @"val3", nil);
	STAssertEqualObjects(lastObserved, @"dict.someKey", nil);

	[self removeObserver:self forKeyPath:@"dict.someKey"];
}


-(void)testDeps
{
	[self addObserver:self forKeyPath:@"derived" options:0 context:nil];

	observerCalled=NO;
	[self setValue:@"val3" forKeyPath:@"someKey"];
	STAssertTrue(observerCalled, nil);	
	STAssertEqualObjects(lastObserved, @"derived", nil);

	[self removeObserver:self forKeyPath:@"derived"];
	
	[self addObserver:self forKeyPath:@"newStyleDerived" options:0 context:nil];
	
	observerCalled=NO;
	[self setValue:@"val3" forKeyPath:@"dict.derivedProperty"];
	STAssertTrue(observerCalled, nil);	
	STAssertEqualObjects(lastObserved, @"newStyleDerived", nil);

	[self removeObserver:self forKeyPath:@"newStyleDerived"];
	
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
