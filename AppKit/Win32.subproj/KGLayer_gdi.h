#import <AppKit/KGLayer.h>

@class KGRenderingContext_gdi;

@interface KGLayer_gdi : KGLayer {
   KGRenderingContext_gdi *_renderingContext;
}

-initRelativeToRenderingContext:(KGRenderingContext_gdi *)context size:(NSSize)size unused:(NSDictionary *)unused;

-(KGRenderingContext_gdi *)renderingContext;

@end
