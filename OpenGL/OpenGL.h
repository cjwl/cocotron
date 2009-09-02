#import <OpenGL/gl.h>
#import <OpenGL/glext.h>

#import <OpenGL/CGLTypes.h>
#import <OpenGL/CGLCurrent.h>

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj other,CGLContextObj *result);
CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context);

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context);
CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context);
