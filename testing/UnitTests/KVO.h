//
//  KVO.h
//  UnitTests
//
//  Created by Johannes Fortmann on 08.05.08.
//  Copyright 2008 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface KVO : SenTestCase {
	NSString *someKey;
	NSMutableDictionary *dict;
	NSString *lastObserved;
	BOOL observerCalled;
}
@property (copy) NSString *someKey;
@property (copy) NSString *lastObserved;
@property (retain) NSMutableDictionary *dict;
@property (readonly) NSString *derived;
@property (readonly) NSString *newStyleDerived;
@end
