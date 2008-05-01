//
//  Forwarding.h
//  UnitTests
//
//  Created by Johannes Fortmann on 19.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface Forwarding : SenTestCase 
{
	BOOL beenInMethodFlag;
}


@end


typedef struct 
{
	float a;
	long long b;
	char padding[27];
	char c;
	struct
	{
		float d;
		double e;
	};
} TestingStruct;
