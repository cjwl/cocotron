#import <CoreGraphics/KGLayer.h>

@interface KGLayer_gdi : KGLayer {
   KGContext *_context;
}

-initRelativeToContext:(KGContext *)context size:(NSSize)size unused:(NSDictionary *)unused;

-(KGContext *)cgContext;

@end
