#import "opengl_dll.h"
#import <Foundation/NSString.h>

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

void opengl_glReadPixels(GLint x,GLint y,GLsizei width,GLsizei height,GLenum format,GLenum type,GLvoid *pixels) {
   static typeof(glReadPixels) *function=NULL;

   if(function==NULL){
    HANDLE library=LoadLibrary("OPENGL32");
    
    function=(typeof(function))GetProcAddress(library,"glReadPixels");
   }
   if(function==NULL)
    return;

   return function(x,y,width,height,format,type,pixels);
}



