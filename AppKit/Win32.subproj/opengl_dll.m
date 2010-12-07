#import "opengl_dll.h"
#import <Foundation/NSString.h>
#import <OpenGL/glext.h>

HGLRC opengl_wglCreateContext(HDC dc) {
   return wglCreateContext(dc);
   }
    
BOOL  opengl_wglDeleteContext(HGLRC hglrc) {
   return wglDeleteContext(hglrc);
   }
    
HGLRC opengl_wglGetCurrentContext(void) {
   return wglGetCurrentContext();
   }
    
BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc) {
   return wglMakeCurrent(dc,hglrc);
   }

PROC  opengl_wglGetProcAddress(LPCSTR name){
   return wglGetProcAddress(name);
   }

BOOL opengl_wglShareLists(HGLRC hglrc1,HGLRC hglrc2) {
   return wglShareLists(hglrc1,hglrc2);
}

void  opengl_glReadBuffer(GLenum mode) {
   glReadBuffer(mode);
}

void opengl_glGetIntegerv(GLenum pname,GLint *params) {
   glGetIntegerv(pname,params);
}

void  opengl_glDrawBuffer(GLenum mode) {
   glDrawBuffer(mode);
}

void opengl_glReadPixels(GLint x,GLint y,GLsizei width,GLsizei height,GLenum format,GLenum type,GLvoid *pixels) {
   glReadPixels(x,y,width,height,format,type,pixels);
}

bool opengl_hasPixelBufferObject(){
   
   if(wglGetProcAddress("glGenBuffersARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glBindBufferARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glBufferDataARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glBufferSubDataARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glDeleteBuffersARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glGetBufferParameterivARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glMapBufferARB")==NULL)
    return FALSE;
    
   if(wglGetProcAddress("glUnmapBufferARB")==NULL)
    return FALSE;
    
   return TRUE;
}

void opengl_glGenBuffers(GLsizei n,GLuint *buffers) {
   PFNGLGENBUFFERSARBPROC function=(PFNGLGENBUFFERSARBPROC)wglGetProcAddress("glGenBuffersARB");
   function(n,buffers);
}

void opengl_glBindBuffer(GLenum target,GLuint buffer) {
   PFNGLBINDBUFFERARBPROC function=(PFNGLBINDBUFFERARBPROC)wglGetProcAddress("glBindBufferARB");
   function(target,buffer);
}

void opengl_glBufferData(GLenum target,GLsizeiptr size,const GLvoid *bytes,GLenum usage) {
   PFNGLBUFFERDATAARBPROC function=(PFNGLBUFFERDATAARBPROC)wglGetProcAddress("glBufferDataARB");
   function(target,size,bytes,usage);
}

void opengl_glBufferSubData(GLenum target,GLsizeiptr offset,GLsizeiptr size,const GLvoid *bytes) {
   PFNGLBUFFERSUBDATAARBPROC function=(PFNGLBUFFERSUBDATAARBPROC)wglGetProcAddress("glBufferSubDataARB");
   function(target,offset,size,bytes);
}

void opengl_glDeleteBuffers(GLsizei n,const GLuint *buffers) {
   PFNGLDELETEBUFFERSARBPROC function=(PFNGLDELETEBUFFERSARBPROC)wglGetProcAddress("glDeleteBuffersARB");
   function(n,buffers);
}

void opengl_glGetBufferParameteriv(GLenum target,GLenum value,GLint *data) {
   PFNGLGETBUFFERPARAMETERIVARBPROC function=(PFNGLGETBUFFERPARAMETERIVARBPROC)wglGetProcAddress("glGetBufferParameterivARB");
   function(target,value,data);
}

GLvoid *opengl_glMapBuffer(GLenum target,GLenum access) {
    PFNGLMAPBUFFERARBPROC function=(PFNGLMAPBUFFERARBPROC)wglGetProcAddress("glMapBufferARB");
   return function(target,access);
}

GLboolean opengl_glUnmapBuffer(GLenum target) {
   PFNGLUNMAPBUFFERARBPROC function=(PFNGLUNMAPBUFFERARBPROC)wglGetProcAddress("glUnmapBufferARB");
   return function(target);
}



