#import <AppKit/KGContext.h>

@class KGRenderingContext_gdi;

@interface KGContext_gdi : KGContext {
   KGRenderingContext_gdi *_renderingContext;
}

-(KGRenderingContext_gdi *)renderingContext;

@end

