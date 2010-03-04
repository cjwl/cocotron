//
//  SecAccess.h
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SecAccess : NSObject {
   CFStringRef _descriptor;
   CFArrayRef  _trustedList;
}

-initWithDescriptor:(CFStringRef)descriptor trustedList:(CFArrayRef)trustedList;

@end
