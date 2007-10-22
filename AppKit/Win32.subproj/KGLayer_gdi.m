#import "KGLayer_gdi.h"
#import "KGRenderingContext_gdi.h"

@implementation KGLayer_gdi

-initRelativeToRenderingContext:(KGRenderingContext_gdi *)otherContext size:(NSSize)size unused:(NSDictionary *)unused {
   [super initWithSize:size unused:unused];
   _renderingContext=[[KGRenderingContext_gdi renderingContextWithSize:size renderingContext:otherContext] retain];
   return self;
}

-(void)dealloc {
   [_unused release];
   [_renderingContext release];
   [super dealloc];
}

-(KGRenderingContext_gdi *)renderingContext {
   return _renderingContext;
}

-(KGContext *)cgContext {
   return [_renderingContext cgContextWithSize:_size];
}


@end
