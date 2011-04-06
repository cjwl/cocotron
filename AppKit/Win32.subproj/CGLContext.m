#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <stdbool.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreGraphics/CGLPixelSurface.h>

/* There is essentially only two ways to implement a CGLContext on Windows.

   1) A double buffered off-screen window, using glReadPixels on the back buffer. You can't use a single buffered window because the front buffer is typically considered on-screen and will more likely fail the pixel ownership test. You can't use the front buffer in a double buffered window for the same reasons.
   
     Technique 1 works on a lot of systems, but not all. Some drivers will consider an off-screen window as failing the pixel ownership test and not produce any results (black). Some nVidia card/drivers exhibit this behavior.
     Technique 1 is also slow and there are no acceleration options, the pixels must be retrieved with glReadPixels
     
     
   2) Two pbuffers. Because pbuffers can't be resized you must use one pbuffer for the rendering context and another which is destroyed/created for the backing. The one small static pbuffer is used as the primary rendering context and participates in wglShareLists and preserves rendering context state during resizes. A second pbuffer is used as the backing HDC, this pbuffer is destroyed/created during a context resize (pbuffers can't be resized), no HGLRC is created for this pbuffer. This is all possible because wglMakeCurrent accepts both a HDC and HGLRC, provided the HDC and HGLRC have the same pixel format.
   
   Technique 2 is used if pbuffers are available, 1 is the fallback.
   
   You can't use FBO's because they are context state and you can't hide them from the application software. E.g. if the application switches to fbo 0 (default), and CGLContext is using 1 for the backing things will fail. Pbuffer doesn't have this problem, pbuffer is also older and more common on Windows at least. 
      
   You can't use child windows (this was the first implementation) because they have a number of problems, e.g. no transparency, they are not supported well in layered windows, you can't have multiple child windows with different pixels formats and they have a number of visual artifacts which are hard to control, e.g. flicker during resize.
   
   VMWare Fusion (as of April 4,2011) does not support pbuffers so you can't test it there.
   Parallels Desktop (as of April 4,2011) does support pbuffers but the implementation appears buggy, they usually work, but sometimes don't.
    */
 
#import "opengl_dll.h"

struct _CGLContextObj {
   GLuint           retainCount;
   CRITICAL_SECTION lock; // This must be a recursive lock.
   HWND             window;
   int              w,h;
   GLint            opacity;
   CGLPixelSurface  *overlay;
   HPBUFFERARB      staticPbuffer;
   HDC              staticPbufferDC;
   HGLRC            staticPbufferGLContext;
   HPBUFFERARB      dynamicPbuffer;
   HDC              dynamicPbufferDC;
   BOOL             needsViewport;
   HDC              windowDC;
   HGLRC            windowGLContext;
};

struct _CGLPixelFormatObj {
   GLuint retainCount;
   CGLPixelFormatAttribute *attributes;
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

static LRESULT CALLBACK windowProcedure(HWND handle,UINT message,WPARAM wParam,LPARAM lParam){
   if(message==WM_PAINT){    
    ValidateRect(handle, NULL);
    return 0;
   }
   
   if(message==WM_MOUSEACTIVATE)
    return MA_NOACTIVATE;

//   if(message==WM_ACTIVATE)
  //  return 1;

 //  if(message==WM_ERASEBKGND)
   // return 1;
        
   return DefWindowProc(handle,message,wParam,lParam);
}

void CGLInitializeIfNeeded(){
   static bool registerWindowClass=FALSE;
   
   if(!registerWindowClass){
    static WNDCLASSEX windowClass;
    
    windowClass.cbSize=sizeof(WNDCLASSEX);
    windowClass.style=CS_HREDRAW|CS_VREDRAW|CS_OWNDC|CS_DBLCLKS;
    windowClass.lpfnWndProc=windowProcedure;
    windowClass.cbClsExtra=0;
    windowClass.cbWndExtra=0;
    windowClass.hInstance=NULL;
    windowClass.hIcon=NULL;
    windowClass.hCursor=LoadCursor(NULL,IDC_ARROW);
    windowClass.hbrBackground=NULL;
    windowClass.lpszMenuName=NULL;
    windowClass.lpszClassName="CGLWindow";
    windowClass.hIconSm=NULL;
    
    if(RegisterClassEx(&windowClass)==0)
     NSLog(@"RegisterClass failed %s %d",__FILE__,__LINE__);
     
    registerWindowClass=TRUE;
   }
}

CGL_EXPORT CGLContextObj CGLGetCurrentContext(void) {
   CGLContextObj result=TlsGetValue(cglThreadStorageIndex());
   
   return result;
}

static void reportGLErrorIfNeeded(const char *function,int line){
   GLenum error=glGetError();

   if(error!=GL_NO_ERROR)
     NSLog(@"%s %d error=%d/%x",function,line,error,error);

}

#if 0
static BOOL contextHasMakeCurrentReadExtension(CGLContextObj context){
   const char *extensions=opengl_wglGetExtensionsStringARB(context->windowDC);
      
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

   if(extensions==NULL)
    return NO;
   
   if(strstr(extensions,"WGL_ARB_make_current_read")==NULL)
    return NO;

   return YES;
}
#endif

static CGLError _CGLSetCurrentContextFromThreadLocal(){
   CGLContextObj context=TlsGetValue(cglThreadStorageIndex());
   
   if(context==NULL)
    opengl_wglMakeCurrent(NULL,NULL);
   else {

    opengl_wglMakeCurrent(context->windowDC,context->windowGLContext);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    
    if(context->dynamicPbufferDC!=NULL){
     int lost;
     
     opengl_wglQueryPbufferARB(context->dynamicPbuffer, WGL_PBUFFER_LOST_ARB, &lost);
     
     if(lost)
      NSLog(@"lost dynamic pBuffer",lost);

     opengl_wglQueryPbufferARB(context->staticPbuffer, WGL_PBUFFER_LOST_ARB, &lost);
     
     if(lost)
      NSLog(@"lost static pBuffer",lost);

#if 0
     if(contextHasMakeCurrentReadExtension(context))
      opengl_wglMakeContextCurrentARB(context->dynamicPbufferDC,context->dynamicPbufferDC,context->staticPbufferGLContext);
     else  
#endif

      opengl_wglMakeCurrent(context->dynamicPbufferDC,context->staticPbufferGLContext);
      if(context->needsViewport){
       glViewport(0,0,context->w,context->h);
       context->needsViewport=NO;
      }
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    }
    
   }
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLSetCurrentContext(CGLContextObj context) {
   TlsSetValue(cglThreadStorageIndex(),context);
   return _CGLSetCurrentContextFromThreadLocal();
}

static inline bool attributeHasArgument(CGLPixelFormatAttribute attribute){
   switch(attribute){
    case kCGLPFAAuxBuffers:
    case kCGLPFAColorSize:
    case kCGLPFAAlphaSize:
    case kCGLPFADepthSize:
    case kCGLPFAStencilSize:
    case kCGLPFAAccumSize:
    case kCGLPFARendererID:
    case kCGLPFADisplayMask:
     return TRUE;
     
    default:
     return FALSE;
   }
}

static void pfdFromPixelFormat(PIXELFORMATDESCRIPTOR *pfd,CGLPixelFormatObj pixelFormat){
   int  i,virtualScreen=0;
   
   memset(pfd,0,sizeof(PIXELFORMATDESCRIPTOR));
   
   pfd->nSize=sizeof(PIXELFORMATDESCRIPTOR);
   pfd->nVersion=1;
   
   /* It has to be double buffered regardless of what the application asks for, because we're reading from it, all the pixels must be
      valid. A single buffer context is problematic in that the driver may not render obscured pixels, all of them since it is off-screen.
      That isnt a problem with pbuffers but this is the fallback. */
      
   pfd->dwFlags=PFD_SUPPORT_OPENGL|PFD_DRAW_TO_WINDOW|PFD_DOUBLEBUFFER;
   pfd->iLayerType=PFD_MAIN_PLANE;
   pfd->iPixelType=PFD_TYPE_RGBA;
   pfd->cColorBits=32;
   pfd->cRedBits=8;
   pfd->cGreenBits=8;
   pfd->cBlueBits=8;
   pfd->cAlphaBits=8;
   pfd->cDepthBits=24;
return;
//ignored for now
   for(i=0;pixelFormat->attributes[i]!=0;i++){
    CGLPixelFormatAttribute attribute=pixelFormat->attributes[i];

    if(attributeHasArgument(pixelFormat->attributes[i]))
     i++;

    switch(attribute){
    
     case kCGLPFAColorSize:
      pfd->cColorBits=pixelFormat->attributes[i];
      break;
      
     case kCGLPFAAlphaSize:
      pfd->cAlphaBits=pixelFormat->attributes[i];
      break;
      
     case kCGLPFAAccumSize:
      pfd->cAccumBits=pixelFormat->attributes[i];
      break;
      
     case kCGLPFADepthSize:
      pfd->cDepthBits=pixelFormat->attributes[i];
      break;
      
     case kCGLPFAStencilSize:
      pfd->cStencilBits=pixelFormat->attributes[i];
      break;
      
     case kCGLPFAAuxBuffers:
      pfd->cAuxBuffers=pixelFormat->attributes[i];
      break;
    }
    
   }
}

static BOOL contextHasPbufferExtension(CGLContextObj context){
   const char *extensions=opengl_wglGetExtensionsStringARB(context->windowDC);
   
  // NSLog(@"extensions=%s",extensions);
   
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

   if(extensions==NULL)
    return NO;
   
   if(strstr(extensions,"WGL_ARB_pbuffer")==NULL)
    return NO;

   if(strstr(extensions,"WGL_ARB_pixel_format")==NULL)
    return NO;
    
   const char *vendor=glGetString(GL_VENDOR);
   
   if(strstr(vendor,"Parallels")!=NULL)
    return NO;
    
   return YES;
}

static int powerOfTwo(int value){
   int result=1;
   
   while(result<value)
    result*=2;
    
   return result;
}

void _CGLCreateDynamicPbufferBacking(CGLContextObj context){
   
   if(!contextHasPbufferExtension(context))
    return;
    
   int piFormats[1];
   int piAttribIList[]={
        WGL_SUPPORT_OPENGL_ARB,GL_TRUE,
        WGL_DRAW_TO_PBUFFER_EXT, GL_TRUE,
        WGL_RED_BITS_ARB,8,
        WGL_GREEN_BITS_ARB,8,
        WGL_BLUE_BITS_ARB,8,
        WGL_ALPHA_BITS_ARB,8,
        WGL_DEPTH_BITS_ARB,24,
        WGL_PIXEL_TYPE_EXT,WGL_TYPE_RGBA_EXT,
        WGL_BIND_TO_TEXTURE_RGBA_ARB, GL_TRUE,
        WGL_ACCELERATION_ARB,WGL_FULL_ACCELERATION_ARB,
        WGL_DOUBLE_BUFFER_ARB,GL_FALSE,
        0
   }; 
        			
   UINT nNumFormats=0;	
    
   if(opengl_wglChoosePixelFormatARB(context->windowDC,piAttribIList,NULL,1,piFormats,&nNumFormats)==FALSE){
    NSLog(@"wglChoosePixelFormatARB returned %i", GetLastError());
    return;			
   }
    
   if(nNumFormats==0){
    NSLog(@"opengl_wglChoosePixelFormatARB return nNumFormats==0");
    return;
   }

   if(context->staticPbuffer==NULL){
    context->staticPbuffer=opengl_wglCreatePbufferARB(context->windowDC, piFormats[0], 1, 1, NULL);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    context->staticPbufferDC=opengl_wglGetPbufferDCARB(context->staticPbuffer);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    context->staticPbufferGLContext=opengl_wglCreateContext(context->staticPbufferDC);		
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   }
   
	const int attributes[]= {
     WGL_TEXTURE_FORMAT_ARB,
     WGL_TEXTURE_RGBA_ARB, // p-buffer will have RBA texture format
     WGL_TEXTURE_TARGET_ARB,
     WGL_TEXTURE_2D_ARB,
     0}; // Of texture target will be GL_TEXTURE_2D

   context->dynamicPbuffer=opengl_wglCreatePbufferARB(context->windowDC, piFormats[0], context->w, context->h, NULL);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    
    if(context->dynamicPbuffer==NULL){
     NSLog(@"dynamic Pbuffer creation failed");
     return ;
    }
    
   context->dynamicPbufferDC=opengl_wglGetPbufferDCARB(context->dynamicPbuffer);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   
   if(context->dynamicPbufferDC==NULL)
     NSLog(@"dynamic Pbuffer DC creation failed");

   context->needsViewport=YES;
   
   // Verify result dimensions
   int width=0;
   int height=0;
   opengl_wglQueryPbufferARB(context->dynamicPbuffer, WGL_PBUFFER_WIDTH_ARB, &width);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   
   opengl_wglQueryPbufferARB(context->dynamicPbuffer, WGL_PBUFFER_HEIGHT_ARB, &height);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    
   if(width!=context->w)
    NSLog(@"opengl_wglQueryPbufferARB width!=context->w");
   if(height!=context->h)
    NSLog(@"opengl_wglQueryPbufferARB height!=context->h");
}



void _CGLCreateBufferBackingIfPossible(CGLContextObj context){
   CGLContextObj saveContext=CGLGetCurrentContext();
   
// Window context must be current for pBuffer functions to work.  
   opengl_wglMakeCurrent(context->windowDC,context->windowGLContext);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

   const char *extensions=glGetString(GL_EXTENSIONS);
   
  // NSLog(@"extensions=%s",extensions);
  // NSLog(@"vendor=%s",glGetString(GL_VENDOR));
   
   _CGLCreateDynamicPbufferBacking(context);
   CGLSetCurrentContext(saveContext);
}

void _CGLDestroyStaticPbufferBacking(CGLContextObj context){
// Window context must be current for pBuffer functions to work.  
   opengl_wglMakeCurrent(context->windowDC,context->windowGLContext);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

   if(context->staticPbufferGLContext!=NULL){
    opengl_wglDeleteContext(context->staticPbufferGLContext);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   }
   
   if(context->staticPbufferDC!=NULL){
    opengl_wglReleasePbufferDCARB(context->staticPbuffer,context->staticPbufferDC);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   }
   
   if(context->staticPbuffer!=NULL){
     opengl_wglDestroyPbufferARB(context->staticPbuffer);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   }
   
   context->staticPbuffer=NULL;
   context->staticPbufferDC=NULL;
}

void _CGLDestroyDynamicPbufferBacking(CGLContextObj context){
// Window context must be current for pBuffer functions to work.  

   opengl_wglMakeCurrent(context->windowDC,context->windowGLContext);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   
    if(context->dynamicPbufferDC!=NULL){
     opengl_wglReleasePbufferDCARB(context->dynamicPbuffer,context->dynamicPbufferDC);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    }
    
    if(context->dynamicPbuffer!=NULL){
     opengl_wglDestroyPbufferARB(context->dynamicPbuffer);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   }
   
    context->dynamicPbuffer=NULL;
    context->dynamicPbufferDC=NULL;
}


void _CGLResizeBufferBackingIfNeeded(CGLContextObj context){    
   CGLContextObj saveContext=CGLGetCurrentContext();

// Window context must be current for pBuffer functions to work.
   opengl_wglMakeCurrent(context->windowDC,context->windowGLContext);

   _CGLDestroyDynamicPbufferBacking(context);
   _CGLCreateDynamicPbufferBacking(context);

   CGLSetCurrentContext(saveContext);
}


CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj share,CGLContextObj *resultp) {
   CGLContextObj         context=NSZoneCalloc(NULL,1,sizeof(struct _CGLContextObj));
   PIXELFORMATDESCRIPTOR pfd;
   int                   pfIndex;
   
   CGLInitializeIfNeeded();

   context->retainCount=1;
   
   pfdFromPixelFormat(&pfd,pixelFormat);

   InitializeCriticalSection(&(context->lock));
   
   context->w=16;
   context->h=16;

   context->window=CreateWindowEx(WS_EX_TOOLWINDOW,"CGLWindow","",WS_POPUP|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,0,0,context->w,context->h,NULL,NULL,GetModuleHandle(NULL),NULL);
   
   context->windowDC=GetDC(context->window);

   pfIndex=ChoosePixelFormat(context->windowDC,&pfd); 

   if(!SetPixelFormat(context->windowDC,pfIndex,&pfd))
    NSLog(@"SetPixelFormat failed");

   context->windowGLContext=opengl_wglCreateContext(context->windowDC);
   
/* Creating a CGL context does NOT set it as current, if you need the context to be current,
   save it and restore it. Some applications may create a context while using another, so
   we don't want to improperly switch to another context during creating */
      
   _CGLCreateBufferBackingIfPossible(context);
   
   if(share!=NULL){
    HGLRC shareGL=(share->staticPbufferGLContext!=NULL)?share->staticPbufferGLContext:share->windowGLContext;
    HGLRC otherGL=(context->staticPbufferGLContext!=NULL)?context->staticPbufferGLContext:context->windowGLContext;

    if(!opengl_wglShareLists(shareGL,otherGL))
     NSLog(@"opengl_wglShareLists failed");
   }
   
   context->opacity=1;

   context->overlay=[[CGLPixelSurface alloc] initWithFrame:O2RectMake(0,0,context->w,context->h)];
   [context->overlay setOpaque:YES];
   
   *resultp=context;
   
   return kCGLNoError;
}

CGL_EXPORT CGLContextObj CGLRetainContext(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return NULL;
    
   CGLLockContext(context);

   context->retainCount++;
   
   CGLUnlockContext(context);
   
   return context;
}

CGL_EXPORT void CGLReleaseContext(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return;
    
   CGLLockContext(context);
   context->retainCount--;
   CGLUnlockContext(context);
   
   if(context->retainCount==0){

    if(CGLGetCurrentContext()==context)
     CGLSetCurrentContext(NULL);
        
    _CGLDestroyDynamicPbufferBacking(context);
    _CGLDestroyStaticPbufferBacking(context);

    ReleaseDC(context->window,context->windowDC);
    DestroyWindow(context->window);
    
    [context->overlay release];

    DeleteCriticalSection(&(context->lock));
    opengl_wglDeleteContext(context->windowGLContext);
    
    
    NSZoneFree(NULL,context);
   }
}

CGL_EXPORT GLuint CGLGetContextRetainCount(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return 0;

   return context->retainCount;
}

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   CGLReleaseContext(context);

   return kCGLNoError;
}

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   EnterCriticalSection(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   LeaveCriticalSection(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLSetParameter(CGLContextObj context,CGLContextParameter parameter,const GLint *value) {
//if(NSDebugEnabled) NSCLog("%s %d %p CGLSetParameter parameter=%d",__FILE__,__LINE__,context,parameter);
   CGLLockContext(context);

   switch(parameter){
    case kCGLCPSwapInterval:;
     CGLSetCurrentContext(context);
     
     typedef BOOL (WINAPI * PFNWGLSWAPINTERVALEXTPROC)(int interval); 
     PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)opengl_wglGetProcAddress("wglSwapIntervalEXT"); 
     if(wglSwapIntervalEXT==NULL){
      NSLog(@"wglGetProcAddress failed for wglSwapIntervalEXT");
     }
     else {
      wglSwapIntervalEXT(*value); 
     }
     break;
    
    case kCGLCPSurfaceOpacity:
     context->opacity=*value;
     
     [context->overlay setOpaque:context->opacity?YES:NO];
     break;
    
    case kCGLCPSurfaceBackingSize:;
     BOOL sizeChanged=(context->w!=value[0] || context->h!=value[1])?YES:NO;
     
     if(sizeChanged){
      context->w=value[0];
      context->h=value[1];

      /* If we're using a Pbuffer we don't want the window large because it consumes resources */
      if(context->staticPbufferGLContext==NULL)
       MoveWindow(context->window,0,0,context->w,context->h,NO);
      else
       _CGLResizeBufferBackingIfNeeded(context);
      
      /* It is not appropriate to set this context as current, _CGLResizeBufferBackingIfNeeded saves/restores
         because it may be made current on another thread, and if it is current on the resize thread the
         other thread make current will fail. Basically, don't leave current! */

      [context->overlay setFrameSize:O2SizeMake(context->w,context->h)];
     }
     break;
     
    default:
     NSUnimplementedFunction();
     break;
   }
  
   CGLUnlockContext(context);
   
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLGetParameter(CGLContextObj context,CGLContextParameter parameter,GLint *value) { 
//if(NSDebugEnabled) NSCLog("%s %d %p CGLGetParameter parameter=%d",__FILE__,__LINE__,context,parameter);
   CGLLockContext(context);
   switch(parameter){
   
    case kCGLCPSurfaceOpacity:
     *value=context->opacity;
     break;
    
    case kCGLCPOverlayPointer:
     *((CGLPixelSurface **)value)=context->overlay;
     break;
     
    default:
     break;
   }
   CGLUnlockContext(context);
   
   return kCGLNoError;
}

CGLError CGLFlushDrawable(CGLContextObj context) {
//if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
/*
  If we SwapBuffers() and read from the front buffer we get junk because the swapbuffers may not be
  complete. Read from GL_BACK.
 */
   CGLLockContext(context);

   CGLSetCurrentContext(context);
   
   GLint buffer;
   
   glGetIntegerv(GL_DRAW_BUFFER,&buffer);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   glReadBuffer(buffer);
   reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   
   [context->overlay readBuffer];
   
   CGLUnlockContext(context);

   [[context->overlay window] flushOverlay:context->overlay];

   return kCGLNoError;
}

static int attributesCount(const CGLPixelFormatAttribute *attributes){
   int result;
   
   for(result=0;attributes[result]!=0;result++)
    if(attributeHasArgument(attributes[result]))
     result++;
   
   return result;
}

CGLError CGLChoosePixelFormat(const CGLPixelFormatAttribute *attributes,CGLPixelFormatObj *pixelFormatp,GLint *numberOfScreensp) {
   CGLPixelFormatObj result=malloc(sizeof(struct _CGLPixelFormatObj));
   int               i,count=attributesCount(attributes);
     
   result->retainCount=1;
   result->attributes=malloc(sizeof(CGLPixelFormatAttribute)*count);
   for(i=0;i<count;i++)
    result->attributes[i]=attributes[i];
   
   *pixelFormatp=result;
   *numberOfScreensp=1;
   
   return kCGLNoError;
}

CGLPixelFormatObj CGLRetainPixelFormat(CGLPixelFormatObj pixelFormat) {
   if(pixelFormat==NULL)
    return NULL;
    
   pixelFormat->retainCount++;
   return pixelFormat;
}

void CGLReleasePixelFormat(CGLPixelFormatObj pixelFormat) {
   if(pixelFormat==NULL)
    return;
    
   pixelFormat->retainCount--;
   
   if(pixelFormat->retainCount==0){
    free(pixelFormat->attributes);
    free(pixelFormat);
   }
}

CGLError CGLDestroyPixelFormat(CGLPixelFormatObj pixelFormat) {
   CGLReleasePixelFormat(pixelFormat);
   return kCGLNoError;
}

GLuint CGLGetPixelFormatRetainCount(CGLPixelFormatObj pixelFormat) {
   return pixelFormat->retainCount;
}

CGL_EXPORT CGLError CGLDescribePixelFormat(CGLPixelFormatObj pixelFormat,GLint screenNumber,CGLPixelFormatAttribute attribute,GLint *valuesp) {
   int i;
   
   for(i=0;pixelFormat->attributes[i]!=0;i++){
    bool hasArgument=attributeHasArgument(pixelFormat->attributes[i]);
    
    if(pixelFormat->attributes[i]==attribute){
     if(hasArgument)
      *valuesp=pixelFormat->attributes[i+1];
     else
      *valuesp=1;
     
     return kCGLNoError;
    }
    
    if(hasArgument)
     i++;
   }
   *valuesp=0;
     return kCGLNoError;
}

struct _CGLPBufferObj {
   GLuint retainCount;
   GLsizei width;
   GLsizei height;
   GLenum target;
   GLenum internalFormat;
   GLint maxDetail;
};

CGLError CGLCreatePBuffer(GLsizei width,GLsizei height,GLenum target,GLenum internalFormat,GLint maxDetail,CGLPBufferObj *pbufferp) {
   CGLPBufferObj pbuffer=calloc(1,sizeof(struct _CGLPBufferObj));
   pbuffer->width=width;
   pbuffer->height=height;
   pbuffer->target=target;
   pbuffer->internalFormat=internalFormat;
   pbuffer->maxDetail=maxDetail;
   *pbufferp=pbuffer;
   return kCGLNoError;
}

CGLError CGLDescribePBuffer(CGLPBufferObj pbuffer,GLsizei *width,GLsizei *height,GLenum *target,GLenum *internalFormat,GLint *mipmap) {
   *width=pbuffer->width;
   *height=pbuffer->height;
   *target=pbuffer->target;
   *internalFormat=pbuffer->internalFormat;
   *mipmap=pbuffer->maxDetail;
   return kCGLNoError;
}

CGLPBufferObj CGLRetainPBuffer(CGLPBufferObj pbuffer) {
   if(pbuffer==NULL)
    return NULL;
    
   pbuffer->retainCount++;
   return pbuffer;
}

void CGLReleasePBuffer(CGLPBufferObj pbuffer) {
   if(pbuffer==NULL)
    return;
    
   pbuffer->retainCount--;
   
   if(pbuffer->retainCount==0){
    free(pbuffer);
   }
}

GLuint CGLGetPBufferRetainCount(CGLPBufferObj pbuffer) {
   return pbuffer->retainCount;
}

CGLError CGLDestroyPBuffer(CGLPBufferObj pbuffer) {
   CGLReleasePBuffer(pbuffer);
   return kCGLNoError;
}

CGLError CGLGetPBuffer(CGLContextObj context,CGLPBufferObj *pbuffer,GLenum *face,GLint *level,GLint *screen) {
   return kCGLNoError;
}

CGLError CGLSetPBuffer(CGLContextObj context,CGLPBufferObj pbuffer,GLenum face,GLint level,GLint screen) {
   return kCGLNoError;
}

CGLError CGLTexImagePBuffer(CGLContextObj context,CGLPBufferObj pbuffer,GLenum sourceBuffer) {
   return kCGLNoError;
}

