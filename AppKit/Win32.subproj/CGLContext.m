#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>

#import "opengl_dll.h"

struct _CGLContextObj {
   CRITICAL_SECTION lock; // FIXME: this should be converted to the OS*Lock* functions when they appear
   HDC              dc;
   HGLRC            glrc;
};

// FIXME: there should be a lock around initialization of this
static DWORD cglThreadStorageIndex(){
   static DWORD tlsIndex=TLS_OUT_OF_INDEXES;

   if(tlsIndex==TLS_OUT_OF_INDEXES)
    tlsIndex=TlsAlloc();

   if(tlsIndex==TLS_OUT_OF_INDEXES)
    NSLog(@"TlsAlloc failed in CGLContext");

   return tlsIndex;
}

CGL_EXPORT CGLContextObj CGLGetCurrentContext(void) {
   CGLContextObj result=TlsGetValue(cglThreadStorageIndex());
   
   return result;
}

CGL_EXPORT CGLError CGLSetCurrentContext(CGLContextObj context) {
   TlsSetValue(cglThreadStorageIndex(),context);
   if(context==NULL)
    opengl_wglMakeCurrent(NULL,NULL);
   else
    opengl_wglMakeCurrent(context->dc,context->glrc);
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,HDC dc,CGLContextObj *resultp) {
   CGLContextObj result=NSZoneMalloc(NULL,sizeof(struct _CGLContextObj));
   
   InitializeCriticalSection(&(result->lock));
   result->dc=dc;
   result->glrc=opengl_wglCreateContext(dc);
   *resultp=result;
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context) {
   if(context!=NULL){
    if(CGLGetCurrentContext()==context)
     CGLSetCurrentContext(NULL);
    
    DeleteCriticalSection(&(context->lock));
    opengl_wglDeleteContext(context->glrc);
    NSZoneFree(NULL,context);
   }

   return kCGLNoError;
}

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context) {
   EnterCriticalSection(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context) {
   LeaveCriticalSection(&(context->lock));
   return kCGLNoError;
}


CGL_EXPORT CGLError CGLSetParameter(CGLContextObj context,CGLContextParameter parameter,const GLint *value) {
   switch(parameter){
    case kCGLCPSwapInterval:;
     typedef BOOL (WINAPI * PFNWGLSWAPINTERVALEXTPROC)(int interval); 
     PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)opengl_wglGetProcAddress("wglSwapIntervalEXT"); 
     if(wglSwapIntervalEXT==NULL){
      NSLog(@"wglGetProcAddress failed for wglSwapIntervalEXT");
      return kCGLNoError;
     }
     
     wglSwapIntervalEXT(*value); 
     break;
     
    default:
     NSUnimplementedFunction();
     break;
   }
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLGetParameter(CGLContextObj context,CGLContextParameter parameter,GLint *value) { 
   NSUnimplementedFunction();
   return kCGLNoError;
}


