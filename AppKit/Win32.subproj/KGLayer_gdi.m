#import "KGLayer_gdi.h"
#import <AppKit/KGContext_gdi.h>

@implementation KGLayer_gdi

-initRelativeToContext:(KGContext *)context size:(NSSize)size unused:(NSDictionary *)unused {
   [super initRelativeToContext:context size:size unused:unused];
   _context=[[KGContext_gdi alloc] initWithSize:size context:context];
   return self;
}

-(void)dealloc {
   [_unused release];
   [_context release];
   [super dealloc];
}

-(KGContext *)cgContext {
   return _context;
}

@end
