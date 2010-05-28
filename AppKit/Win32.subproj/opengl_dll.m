#import "opengl_dll.h"
#import <Foundation/NSString.h>
#import <OpenGL/glext.h>

/* This indirection is so that applications which don't use the NSOpenGL* classes don't have to link or load opengl32.dll just because the AppKit might use it. This should probably get reworked into a CGL interface
 */
HGLRC opengl_wglCreateContext(HDC dc) {
   typedef WINGDIAPI HGLRC WINAPI (*ftype)(HDC);
   static ftype                     function=NULL;
   
   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"wglCreateContext");
   }
   if(function==NULL)
    return NULL;
    
   return function(dc);
}

BOOL  opengl_wglDeleteContext(HGLRC hglrc) {
   typedef WINGDIAPI BOOL WINAPI (*ftype)(HGLRC);
   static ftype                    function=NULL;
   
   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"wglDeleteContext");
   }
   if(function==NULL)
    return NO;
    
   return function(hglrc);
}

HGLRC opengl_wglGetCurrentContext(void) {
   typedef WINGDIAPI HGLRC WINAPI (*ftype)(void);
   static ftype                     function=NULL;
   
   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"wglGetCurrentContext");
   }
   if(function==NULL)
    return NULL;
    
   return function();
}

BOOL  opengl_wglMakeCurrent(HDC dc,HGLRC hglrc) {
   typedef WINGDIAPI BOOL WINAPI (*ftype)(HDC,HGLRC);
   static ftype                    function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"wglMakeCurrent");
   }
   if(function==NULL)
    return NO;

   return function(dc,hglrc);
}

PROC  opengl_wglGetProcAddress(LPCSTR name){
   typedef WINGDIAPI PROC WINAPI (*ftype)(LPCSTR name);
   static ftype                    function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"wglGetProcAddress");
   }
   if(function==NULL)
    return NULL;

   return function(name);
}

void  opengl_glReadBuffer(GLenum mode) {
   typedef WINGDIAPI PROC WINAPI (*ftype)(GLenum mode);
   static ftype                    function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"glReadBuffer");
   }
   if(function==NULL)
    return;

   function(mode);
}

void opengl_glGetIntegerv(GLenum pname,GLint *params) {
   typedef WINGDIAPI PROC WINAPI (*ftype)(GLenum pname,GLint *params);
   static ftype                    function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"glGetIntegerv");
   }
   if(function==NULL)
    return;

   function(pname,params);
}


void  opengl_glDrawBuffer(GLenum mode) {
   typedef WINGDIAPI PROC WINAPI (*ftype)(GLenum mode);
   static ftype                    function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(ftype)GetProcAddress(library,"glDrawBuffer");
   }
   if(function==NULL)
    return;

   function(mode);
}

void opengl_glReadPixels(GLint x,GLint y,GLsizei width,GLsizei height,GLenum format,GLenum type,GLvoid *pixels) {
   static typeof(glReadPixels) *function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(typeof(function))GetProcAddress(library,"glReadPixels");
   }
   if(function==NULL)
    return;

   function(x,y,width,height,format,type,pixels);
}

static PFNGLGENBUFFERSARBPROC glGenBuffersARB;
static PFNGLBINDBUFFERARBPROC glBindBufferARB;
static PFNGLBUFFERDATAARBPROC glBufferDataARB;
static PFNGLBUFFERSUBDATAARBPROC glBufferSubDataARB;
static PFNGLDELETEBUFFERSARBPROC glDeleteBuffersARB;
static PFNGLGETBUFFERPARAMETERIVARBPROC glGetBufferParameterivARB;
static PFNGLMAPBUFFERARBPROC glMapBufferARB;
static PFNGLUNMAPBUFFERARBPROC glUnmapBufferARB;

bool opengl_hasPixelBufferObject(){
   glGenBuffersARB=(PFNGLGENBUFFERSARBPROC)wglGetProcAddress("glGenBuffersARB");
   glBindBufferARB=(PFNGLBINDBUFFERARBPROC)wglGetProcAddress("glBindBufferARB");
   glBufferDataARB=(PFNGLBUFFERDATAARBPROC)wglGetProcAddress("glBufferDataARB");
   glBufferSubDataARB=(PFNGLBUFFERSUBDATAARBPROC)wglGetProcAddress("glBufferSubDataARB");
   glDeleteBuffersARB=(PFNGLDELETEBUFFERSARBPROC)wglGetProcAddress("glDeleteBuffersARB");
   glGetBufferParameterivARB=(PFNGLGETBUFFERPARAMETERIVARBPROC)wglGetProcAddress("glGetBufferParameterivARB");
   glMapBufferARB=(PFNGLMAPBUFFERARBPROC)wglGetProcAddress("glMapBufferARB");
   glUnmapBufferARB=(PFNGLUNMAPBUFFERARBPROC)wglGetProcAddress("glUnmapBufferARB");
   
   if(glGenBuffersARB==NULL)
    return FALSE;
   if(glBindBufferARB==NULL)
    return FALSE;
   if(glBufferDataARB==NULL)
    return FALSE;
   if(glBufferSubDataARB==NULL)
    return FALSE;
   if(glDeleteBuffersARB==NULL)
    return FALSE;
   if(glGetBufferParameterivARB==NULL)
    return FALSE;
   if(glMapBufferARB==NULL)
    return FALSE;
   if(glUnmapBufferARB==NULL)
    return FALSE;
    
   return TRUE;
}

void opengl_glGenBuffers(GLsizei n,GLuint *buffers) {
   glGenBuffersARB(n,buffers);
}

void opengl_glBindBuffer(GLenum target,GLuint buffer) {
   glBindBufferARB(target,buffer);
}

void opengl_glBufferData(GLenum target,GLsizeiptr size,const GLvoid *bytes,GLenum usage) {
   glBufferDataARB(target,size,bytes,usage);
}

void opengl_glBufferSubData(GLenum target,GLsizeiptr offset,GLsizeiptr size,const GLvoid *bytes) {
   glBufferSubDataARB(target,offset,size,bytes);
}

void opengl_glDeleteBuffers(GLsizei n,const GLuint *buffers) {
  glDeleteBuffersARB(n,buffers);
}

void opengl_glGetBufferParameteriv(GLenum target,GLenum value,GLint *data) {
   glGetBufferParameterivARB(target,value,data);
}

GLvoid *opengl_glMapBuffer(GLenum target,GLenum access) {
   return glMapBufferARB(target,access);
}

GLboolean opengl_glUnmapBuffer(GLenum target) {
   return glUnmapBufferARB(target);
}



