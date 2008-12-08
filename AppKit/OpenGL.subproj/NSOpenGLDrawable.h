#import <Foundation/NSObject.h>

@class NSOpenGLPixelFormat,NSView;

@interface NSOpenGLDrawable : NSObject

-initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat view:(NSView *)view;

-(void *)createGLContext;

-(void)invalidate;
-(void)updateWithView:(NSView *)view;
-(void)makeCurrentWithGLContext:(void *)glContext;
-(void)swapBuffers;

@end
