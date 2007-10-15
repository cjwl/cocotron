#import <AppKit/KGLayer.h>

@class KGRenderingContext;

@interface KGLayer_gdi : KGLayer {
   KGRenderingContext *_renderingContext;
}

-initRelativeToRenderingContext:(KGRenderingContext *)context size:(NSSize)size unused:(NSDictionary *)unused;

-(KGRenderingContext *)renderingContext;

@end
