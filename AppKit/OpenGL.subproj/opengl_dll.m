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
