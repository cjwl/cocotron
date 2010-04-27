#import <Foundation/NSObject.h>
#import <GL/gl.h>
#import <windows.h>

HGLRC opengl_wglCreateContext(HDC dc);
BOOL  opengl_wglDeleteContext(HGLRC hglrc);
HGLRC opengl_wglGetCurrentContext(void);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
PROC  opengl_wglGetProcAddress(LPCSTR name);
void  opengl_glReadPixels(GLint x,GLint y,GLsizei width,GLsizei height,GLenum format,GLenum type,GLvoid *pixels);
