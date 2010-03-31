#import <QuartzCore/CARenderer.h>
#import <OpenGL/OpenGL.h>
#import <Onyx2D/O2Surface.h>

@implementation CARenderer

@synthesize bounds=_bounds;
@synthesize layer=_rootLayer;

-initWithCGLContext:(void *)cglContext options:(NSDictionary *)options {
   _cglContext=cglContext;
   _bounds=CGRectZero;
   _rootLayer=nil;
   return self;
}

+(CARenderer *)rendererWithCGLContext:(void *)cglContext options:(NSDictionary *)options {
   return [[[self alloc] initWithCGLContext:cglContext options:options] autorelease];
}

-(void)render {
}

@end
