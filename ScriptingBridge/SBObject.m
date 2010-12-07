#import <ScriptingBridge/SBObject.h>
#import <Foundation/NSRaise.h>

@implementation SBObject

-initWithProperties:(NSDictionary *)properties {
   _properties=[properties copy];
   return self;
}

-(void)dealloc {
   [_properties release];
   [super dealloc];
}

@end
