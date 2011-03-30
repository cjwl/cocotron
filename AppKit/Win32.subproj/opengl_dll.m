#import "opengl_dll.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
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


const char *opengl_wglGetExtensionsStringARB(HDC hdc) {
   APIENTRY typeof(opengl_wglGetExtensionsStringARB) *function=(typeof(function))wglGetProcAddress("wglGetExtensionsStringARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NULL;
   }
   
   return function(hdc);
}

HPBUFFERARB opengl_wglCreatePbufferARB(HDC hDC,int iPixelFormat,int iWidth,int iHeight,const int *piAttribList) {
   APIENTRY typeof(opengl_wglCreatePbufferARB) *function=(typeof(function))wglGetProcAddress("wglCreatePbufferARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NULL;
   }
   
   return function(hDC,iPixelFormat,iWidth,iHeight,piAttribList);
}

HDC  opengl_wglGetPbufferDCARB(HPBUFFERARB hPbuffer) {
   APIENTRY typeof(opengl_wglGetPbufferDCARB) *function=(typeof(function))wglGetProcAddress("wglGetPbufferDCARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NULL;
   }
   
   return function(hPbuffer);
}

int  opengl_wglReleasePbufferDCARB(HPBUFFERARB hPbuffer,HDC hDC) {
   APIENTRY typeof(opengl_wglReleasePbufferDCARB) *function=(typeof(function))wglGetProcAddress("wglReleasePbufferDCARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return 0;
   }
   
   return function(hPbuffer,hDC);
}

BOOL opengl_wglDestroyPbufferARB(HPBUFFERARB hPbuffer) {
   APIENTRY typeof(opengl_wglDestroyPbufferARB) *function=(typeof(function))wglGetProcAddress("wglDestroyPbufferARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NO;
   }
   
   return function(hPbuffer);
}

BOOL opengl_wglQueryPbufferARB(HPBUFFERARB hPbuffer,int iAttribute,int *piValue) {
   APIENTRY typeof(opengl_wglQueryPbufferARB) *function=(typeof(function))wglGetProcAddress("wglQueryPbufferARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NO;
   }
   
   return function(hPbuffer,iAttribute,piValue);
}

BOOL opengl_wglGetPixelFormatAttribivARB(HDC hdc,int iPixelFormat,int iLayerPlane,UINT nAttributes,const int *piAttributes,int *piValues) {
   APIENTRY typeof(opengl_wglGetPixelFormatAttribivARB) *function=(typeof(function))wglGetProcAddress("wglGetPixelFormatAttribivARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NO;
   }
   
   return function(hdc,iPixelFormat,iLayerPlane,nAttributes,piAttributes,piValues);
}

BOOL opengl_wglGetPixelFormatAttribfvARB(HDC hdc,int iPixelFormat,int iLayerPlane,UINT nAttributes,const int *piAttributes,FLOAT *pfValues) {
   APIENTRY typeof(opengl_wglGetPixelFormatAttribfvARB) *function=(typeof(function))wglGetProcAddress("wglGetPixelFormatAttribfvARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NO;
   }
   
   return function(hdc,iPixelFormat,iLayerPlane,nAttributes,piAttributes,pfValues);
}

BOOL opengl_wglChoosePixelFormatARB(HDC hdc,const int *piAttribIList,const FLOAT *pfAttribFList,UINT nMaxFormats,int *piFormats,UINT *nNumFormats) {
   APIENTRY typeof(opengl_wglChoosePixelFormatARB) *function=(typeof(function))wglGetProcAddress("wglChoosePixelFormatARB");

   if(function==NULL){
    if(NSDebugEnabled)
     NSLog(@"wglGetProcAddress(wglGetExtensionsStringARB) failed");
    return NO;
   }
   
   return function(hdc,piAttribIList,pfAttribFList,nMaxFormats,piFormats,nNumFormats);
}

