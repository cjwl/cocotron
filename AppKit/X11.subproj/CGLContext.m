#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>

#import <X11/X.h>
#import <X11/Xlib.h>
#import <GL/gl.h>
#import <GL/glx.h>
#import <pthread.h>

struct _CGLContextObj {
   pthread_mutex_t lock;
   Display     *dpy;
   XVisualInfo *vis;
   Window       window;
   GLXContext   glc;
};

static pthread_key_t cglContextKey;

static void make_key(){
   pthread_key_create(&cglContextKey,NULL);
}

static pthread_key_t cglThreadKey(){
   static pthread_once_t key_once=PTHREAD_ONCE_INIT;
   
   pthread_once(&key_once,make_key);

   return cglContextKey;
}

CGL_EXPORT CGLContextObj CGLGetCurrentContext(void) {
   CGLContextObj result=pthread_getspecific(cglThreadKey());
   
   return result;
}

CGL_EXPORT CGLError CGLSetCurrentContext(CGLContextObj context) {
   pthread_setspecific(cglThreadKey(), context);
      
   if(context==NULL)
    ;//glXMakeCurrent(NULL, None, NULL); // FIXME: NULL for display? probably crashes
   else    
    glXMakeCurrent(context->dpy, context->window, context->glc);
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,Display *dpy,XVisualInfo *vis,Window window,CGLContextObj *resultp) {
   if(vis==NULL)
    return kCGLBadDisplay;
    
   CGLContextObj result=NSZoneMalloc(NULL,sizeof(struct _CGLContextObj));
   
   pthread_mutex_init(&(result->lock),NULL);
   result->dpy=dpy;
   result->vis=vis;
   result->window=window;
   result->glc=glXCreateContext(result->dpy,result->vis,NULL,GL_TRUE);
   *resultp=result;
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context) {
   if(context!=NULL){
    if(CGLGetCurrentContext()==context)
     CGLSetCurrentContext(NULL);
    
    pthread_mutex_destroy(&(context->lock));
    glXDestroyContext(context->dpy, context->glc);
    NSZoneFree(NULL,context);
   }

   return kCGLNoError;
}

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context) {
   pthread_mutex_lock(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context) {
   pthread_mutex_unlock(&(context->lock));
   return kCGLNoError;
}

