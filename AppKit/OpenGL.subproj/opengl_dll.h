#import <Foundation/NSObject.h>
#import <gl/gl.h>
#import <windows.h>

HGLRC opengl_wglCreateContext(HDC dc);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
