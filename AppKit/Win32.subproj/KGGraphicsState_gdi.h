#import <AppKit/KGGraphicsState.h>

@class KGRenderingContext_gdi;

@interface KGGraphicsState_gdi : KGGraphicsState {
   KGRenderingContext_gdi *_renderingContext;
   id                  _deviceState;
}

-initWithRenderingContext:(KGRenderingContext_gdi *)context transform:(CGAffineTransform)deviceTransform;

-(KGRenderingContext_gdi *)renderingContext;

@end
