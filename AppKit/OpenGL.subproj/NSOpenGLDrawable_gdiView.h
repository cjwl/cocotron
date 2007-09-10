#import <Foundation/NSObject.h>
#import <windows.h>

@class NSView,NSOpenGLPixelFormat;

@interface NSOpenGLDrawable_gdiView : NSObject {
   NSView *_view;
   HWND _windowHandle;
   HDC  _dc;
   PAINTSTRUCT ps;
}

-initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat view:(NSView *)view;

-(HDC)dc;

-(void)invalidate;

-(void)updateWithView:(NSView *)view;

-(void)makeCurrentWithGLContext:(HGLRC)glContext;

-(void)swapBuffers;

@end
