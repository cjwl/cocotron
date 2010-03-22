#import <OpenGL/gl.h>
#ifdef WINDOWS
#import <OpenGL/glext.h>
#endif

#import <OpenGL/CGLTypes.h>
#import <OpenGL/CGLCurrent.h>

// CGLCreateContext is currently platform specific
// CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj other,CGLContextObj *result);

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context);

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context);
CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context);

CGL_EXPORT CGLError CGLSetParameter(CGLContextObj context,CGLContextParameter parameter,const GLint *value);
CGL_EXPORT CGLError CGLGetParameter(CGLContextObj context,CGLContextParameter parameter,GLint *value);
