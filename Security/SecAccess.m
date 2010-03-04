//
//  SecAccess.m
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SecAccess.h"


@implementation SecAccess

-initWithDescriptor:(CFStringRef)descriptor trustedList:(CFArrayRef)trustedList {
   _descriptor=CFRetain(descriptor);
   _trustedList=(CFArrayRef)CFRetain(trustedList);
   return self;
}

-(void)dealloc {
   CFRelease(_descriptor);
   CFRelease(_trustedList);
   [super dealloc];
}

@end
