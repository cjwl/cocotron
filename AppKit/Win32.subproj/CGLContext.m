#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>

#import "opengl_dll.h"

struct CGLContextObj {
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
   opengl_wglMakeCurrent(context->dc,context->glrc);
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj other,CGLContextObj *resultp) {
// FIXME: yes, this is bogus
   HDC           dc=(HDC)other;
   CGLContextObj result=NSZoneMalloc(NULL,sizeof(struct CGLContextObj));
   
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

