#import <Foundation/NSObject.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <stdbool.h>
#import <windows.h>

HGLRC opengl_wglCreateContext(HDC dc);
BOOL  opengl_wglDeleteContext(HGLRC hglrc);
HGLRC opengl_wglGetCurrentContext(void);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc);
PROC  opengl_wglGetProcAddress(LPCSTR name);
BOOL  opengl_wglShareLists(HGLRC hglrc1,HGLRC hglrc2);
void  opengl_glReadBuffer(GLenum mode);
void  opengl_glGetIntegerv(GLenum pname,GLint *params);
void  opengl_glDrawBuffer(GLenum mode);
void  opengl_glReadPixels(GLint x,GLint y,GLsizei width,GLsizei height,GLenum format,GLenum type,GLvoid *pixels);


bool      opengl_hasPixelBufferObject();
void      opengl_glGenBuffers(GLsizei n,GLuint *buffers);
void      opengl_glBindBuffer(GLenum target,GLuint buffer);
void      opengl_glBufferData(GLenum target,GLsizeiptr size,const GLvoid *bytes,GLenum usage);
void      opengl_glBufferSubData(GLenum target,GLsizeiptr offset,GLsizeiptr size,const GLvoid *bytes);
void      opengl_glDeleteBuffers(GLsizei n,const GLuint *buffers);
void      opengl_glGetBufferParameteriv(GLenum target,GLenum value,GLint *data);
GLvoid   *opengl_glMapBuffer(GLenum target,GLenum access);
GLboolean opengl_glUnmapBuffer(GLenum target);
