#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class CALayer,O2Surface;

@interface CARenderer : NSObject {
   void    *_cglContext;
   CGRect   _bounds;
   CALayer *_rootLayer;
}

@property(assign) CGRect bounds;
@property(retain) CALayer *layer;

+(CARenderer *)rendererWithCGLContext:(void *)cglContext options:(NSDictionary *)options;

-(void)render;
-(void)renderWithSurface:(O2Surface *)surface;

@end
