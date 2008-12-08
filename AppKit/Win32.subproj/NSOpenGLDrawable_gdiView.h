#import <Foundation/NSObject.h>
#import <AppKit/NSOpenGLDrawable.h>
#import <windows.h>

@class NSView,NSOpenGLPixelFormat;

@interface NSOpenGLDrawable_gdiView : NSOpenGLDrawable {
   NSView *_view;
   HWND _windowHandle;
   HDC  _dc;
   PAINTSTRUCT ps;
}

@end
