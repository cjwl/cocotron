#import <OpenGL/glweak.h>
#import <windows.h>
#import <Foundation/NSString.h>

/* Extension function pointers are PER-CONTEXT, do not store in globals */

void CGLBufferData(GLenum target,GLsizeiptr size,const GLvoid *data,GLenum usage) {
   PFNGLBUFFERDATAPROC function=(PFNGLBUFFERDATAPROC)wglGetProcAddress("glBufferData");

   if(function==NULL){
    NSLog(@"wglGetProcAddress(glBufferData) failed");
    return;
   }
   
   function(target,size,data,usage);
}

void CGLGenBuffers(GLsizei n,GLuint *buffers) {
   PFNGLGENBUFFERSPROC function=(PFNGLGENBUFFERSPROC)wglGetProcAddress("glGenBuffers");
   
   if(function==NULL){
    NSLog(@"wglGetProcAddress(glGenBuffers) failed");
    return;
   }
   function(n,buffers);
}

void CGLBindBuffer(GLenum target,GLuint buffer) {
   PFNGLBINDBUFFERPROC function=(PFNGLBINDBUFFERPROC)wglGetProcAddress("glBindBuffer");

   if(function==NULL){
    NSLog(@"wglGetProcAddress(glBindBuffer) failed");
    return;
   }
   
   function(target,buffer);
}

void *CGLMapBuffer(GLenum target,GLenum access) {
   PFNGLMAPBUFFERPROC function=(PFNGLMAPBUFFERPROC)wglGetProcAddress("glMapBuffer");

   if(function==NULL){
    NSLog(@"wglGetProcAddress(glMapBuffer) failed");
    return NULL;
   }
   
   return function(target,access);
}

CGL_EXPORT GLboolean CGLUnmapBuffer(GLenum target) {
   PFNGLUNMAPBUFFERPROC function=(PFNGLUNMAPBUFFERPROC)wglGetProcAddress("glUnmapBuffer");

   if(function==NULL){
    NSLog(@"wglGetProcAddress(glUnmapBuffer) failed");
    return 0;
   }
   
   return function(target);
}

void CGLBufferSubData(GLenum target,GLintptr offset,GLsizeiptr size,const GLvoid *data) {
   PFNGLBUFFERSUBDATAPROC function=(PFNGLBUFFERSUBDATAPROC)wglGetProcAddress("glBufferSubData");

   if(function==NULL){
    NSLog(@"wglGetProcAddress(glBufferSubData) failed");
    return;
   }
   
   function(target,offset,size,data);
}

