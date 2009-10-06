#import <CoreGraphics/KGLayer.h>

@interface KGLayer_gdi : KGLayer {
   O2Context *_context;
}

-initRelativeToContext:(O2Context *)context size:(NSSize)size unused:(NSDictionary *)unused;

-(O2Context *)cgContext;

@end
