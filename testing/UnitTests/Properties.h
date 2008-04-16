//
//  Properties.h
//  UnitTests
//
//  Created by Johannes Fortmann on 16.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface Properties : SenTestCase 
{
	NSString *firstName;
	NSString *lastName;
}

@property (copy) NSString *firstName;
@property (copy) NSString *lastName;
@property (readonly) NSString *fullName;

@end
