#import <Foundation/NSObject.h>
#import <GL/gl.h>
#import <windows.h>

HGLRC opengl_wglCreateContext(HDC dc);
BOOL  opengl_wglDeleteContext(HGLRC hglrc);
HGLRC opengl_wglGetCurrentContext(void);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
