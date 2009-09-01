#import <AppKit/NSOpenGLDrawable.h>

@implementation NSOpenGLDrawable 

-initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat view:(NSView *)view {
   return self;
}

-(void *)createGLContext {
   return NULL;
}

-(void)invalidate {
}

-(void)updateWithView:(NSView *)view {
}

-(void)makeCurrentWithGLContext:(void *)glContext {
}

-(void)clearCurrentWithGLContext:(void *)glContext {
}

-(void)swapBuffers {
}

@end
