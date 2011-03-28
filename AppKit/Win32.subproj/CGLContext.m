#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <stdbool.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreGraphics/CGLPixelSurface.h>

#import "opengl_dll.h"

#ifndef PFD_SUPPORT_COMPOSITION
#define PFD_SUPPORT_COMPOSITION 0x00008000
#endif

struct _CGLContextObj {
   GLuint           retainCount;
   CRITICAL_SECTION lock; // This must be a recursive lock.
   HWND             window;
   HDC              dc;
   HGLRC            glContext;
   int              w,h;
   GLint            opacity;
   CGLPixelSurface  *overlay;
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

static CGLError _CGLSetCurrentContextFromThreadLocal(){
   CGLContextObj context=TlsGetValue(cglThreadStorageIndex());
   
   if(context==NULL)
    opengl_wglMakeCurrent(NULL,NULL);
   else
    opengl_wglMakeCurrent(context->dc,context->glContext);
   
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
   pfd->dwFlags=PFD_SUPPORT_OPENGL|PFD_DRAW_TO_WINDOW|PFD_DOUBLEBUFFER;
   pfd->iLayerType=PFD_MAIN_PLANE;
   pfd->iPixelType=PFD_TYPE_RGBA;
   pfd->cColorBits=32;
   pfd->cRedBits=8;
   pfd->cGreenBits=8;
   pfd->cBlueBits=8;
   pfd->cAlphaBits=8;
   pfd->cDepthBits=32;
return;
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

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj share,CGLContextObj *resultp) {
   CGLContextObj         context=NSZoneCalloc(NULL,1,sizeof(struct _CGLContextObj));
   PIXELFORMATDESCRIPTOR pfd;
   int                   pfIndex;
   
   CGLInitializeIfNeeded();

   context->retainCount=1;
   
   pfdFromPixelFormat(&pfd,pixelFormat);

   InitializeCriticalSection(&(context->lock));
   
   context->w=32;
   context->h=32;

   context->window=CreateWindowEx(WS_EX_TOOLWINDOW,"CGLWindow","",WS_POPUP|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,0,0,context->w,context->h,NULL,NULL,GetModuleHandle(NULL),NULL);
   
   context->dc=GetDC(context->window);

   pfIndex=ChoosePixelFormat(context->dc,&pfd); 

   if(!SetPixelFormat(context->dc,pfIndex,&pfd))
    NSLog(@"SetPixelFormat failed");

   context->glContext=opengl_wglCreateContext(context->dc);
   
   if(share!=NULL){
    if(!opengl_wglShareLists(share->glContext,context->glContext))
     NSLog(@"opengl_wglShareLists failed");
   }

   context->opacity=1;

   context->overlay=[[CGLPixelSurface alloc] initWithFrame:O2RectMake(0,0,context->w,context->h)];
   [context->overlay setOpaque:YES];
   
   *resultp=context;

   if([[NSUserDefaults standardUserDefaults] boolForKey:@"CGLContextShowWindow"])
    SetWindowPos(context->window,HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   
   return kCGLNoError;
}

CGL_EXPORT CGLContextObj CGLRetainContext(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return NULL;
    
   CGLLockContext(context);

   context->retainCount++;
   
   CGLUnlockContext(context);
   
   return context;
}

CGL_EXPORT void CGLReleaseContext(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return;
    
   CGLLockContext(context);
   context->retainCount--;
   CGLUnlockContext(context);
   
   if(context->retainCount==0){
    if(CGLGetCurrentContext()==context)
     CGLSetCurrentContext(NULL);
    
    ReleaseDC(context->window,context->dc);
    DestroyWindow(context->window);
    
    [context->overlay release];

    DeleteCriticalSection(&(context->lock));
    opengl_wglDeleteContext(context->glContext);
    NSZoneFree(NULL,context);
   }
}

CGL_EXPORT GLuint CGLGetContextRetainCount(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   if(context==NULL)
    return 0;

   return context->retainCount;
}

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   CGLReleaseContext(context);

   return kCGLNoError;
}

CGL_EXPORT CGLError CGLLockContext(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   EnterCriticalSection(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context) {
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
   LeaveCriticalSection(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLSetParameter(CGLContextObj context,CGLContextParameter parameter,const GLint *value) {
if(NSDebugEnabled) NSCLog("%s %d %p CGLSetParameter parameter=%d",__FILE__,__LINE__,context,parameter);
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

      MoveWindow(context->window,0,0,context->w,context->h,NO);

       CGLSetCurrentContext(context);
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
if(NSDebugEnabled) NSCLog("%s %d %p CGLGetParameter parameter=%d",__FILE__,__LINE__,context,parameter);
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
if(NSDebugEnabled) NSCLog("%s %d %s %p",__FILE__,__LINE__,__PRETTY_FUNCTION__,context);
/*
  If we SwapBuffers() and read from the front buffer we get junk because the swapbuffers may not be
  complete. Read from GL_BACK.
 */
   CGLLockContext(context);

   CGLSetCurrentContext(context);
    
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

