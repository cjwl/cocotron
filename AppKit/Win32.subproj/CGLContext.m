#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <stdbool.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Win32Window.h"
#import "O2Context_gdi.h"
#import "O2Surface_DIBSection.h"
#import "O2DeviceContext_gdiDIBSection.h"

#import "opengl_dll.h"

struct _CGLContextObj {
   GLuint           retainCount;
   CRITICAL_SECTION lock; // FIXME: this should be converted to the OS*Lock* functions when they appear
   HWND             window;
   HDC              dc;
   HGLRC            glContext;
   int              x,y,w,h;
   GLint            opacity;
   int              windowNumber;
   O2DeviceContext_gdiDIBSection *dibSection;
   void            *imagePixelData;
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
   if(message==WM_PAINT)
    return 1;
   
   if(message==WM_MOUSEACTIVATE)
    return MA_NOACTIVATE;

   if(message==WM_ACTIVATE)
    return 1;
        
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

CGL_EXPORT CGLError CGLSetCurrentContext(CGLContextObj context) {
   TlsSetValue(cglThreadStorageIndex(),context);
   if(context==NULL)
    opengl_wglMakeCurrent(NULL,NULL);
   else
    opengl_wglMakeCurrent(context->dc,context->glContext);
   return kCGLNoError;
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
   
   pfd->dwFlags=PFD_SUPPORT_OPENGL|PFD_DRAW_TO_WINDOW|PFD_GENERIC_ACCELERATED|PFD_DOUBLEBUFFER;
   pfd->iLayerType=PFD_MAIN_PLANE;
   pfd->iPixelType=PFD_TYPE_RGBA;

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
   CGLContextObj         result=NSZoneCalloc(NULL,1,sizeof(struct _CGLContextObj));
   PIXELFORMATDESCRIPTOR pfd;
   int                   pfIndex;
   
   CGLInitializeIfNeeded();

   result->retainCount=1;
   
   pfdFromPixelFormat(&pfd,pixelFormat);

   InitializeCriticalSection(&(result->lock));
   
   result->window=CreateWindowEx(WS_EX_TOOLWINDOW,"CGLWindow","",WS_POPUP,0,0,1,1,NULL,NULL,GetModuleHandle(NULL),NULL);
   SetWindowPos(result->window,HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);

   result->dc=GetDC(result->window);
   
   pfIndex=ChoosePixelFormat(result->dc,&pfd); 
 
   if(!SetPixelFormat(result->dc,pfIndex,&pfd))
    NSLog(@"SetPixelFormat failed");

   result->glContext=opengl_wglCreateContext(result->dc);
   result->opacity=1;
   
   *resultp=result;
   
   return kCGLNoError;
}

CGL_EXPORT CGLContextObj CGLRetainContext(CGLContextObj context) {
   if(context==NULL)
    return NULL;

   context->retainCount++;
   return context;
}

CGL_EXPORT void CGLReleaseContext(CGLContextObj context) {
   if(context==NULL)
    return;
    
   context->retainCount--;
   
   if(context->retainCount==0){
    if(CGLGetCurrentContext()==context)
     CGLSetCurrentContext(NULL);
    
    ReleaseDC(context->window,context->dc);
    DestroyWindow(context->window);
    
    [context->dibSection release];

    DeleteCriticalSection(&(context->lock));
    opengl_wglDeleteContext(context->glContext);
    NSZoneFree(NULL,context);
   }
   
}

CGL_EXPORT GLuint CGLGetContextRetainCount(CGLContextObj context) {
   if(context==NULL)
    return 0;

   return context->retainCount;
}

CGL_EXPORT CGLError CGLDestroyContext(CGLContextObj context) {
   CGLReleaseContext(context);

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

static bool usesChildWindow(CGLContextObj context){
   return (context->opacity!=0)?TRUE:FALSE;
}

static void adjustFrameInParent(CGLContextObj context,Win32Window *parentWindow,GLint *x,GLint *y,GLint *w,GLint *h){
   if(parentWindow!=nil){
    CGFloat top,left,bottom,right;

    CGNativeBorderFrameWidthsForStyle([parentWindow styleMask],&top,&left,&bottom,&right);

    *y=[parentWindow frame].size.height-(*y+*h);

    *y-=top;
    *x-=left;
   }
}

static void adjustInParentForSurfaceOpacity(CGLContextObj context){
   GLint x=context->x;
   GLint y=context->y;
   GLint w=context->w;
   GLint h=context->h;

   if(usesChildWindow(context)){
    Win32Window *parentWindow=[Win32Window windowWithWindowNumber:context->windowNumber];
    HWND         parentHandle=[parentWindow windowHandle];
   
    SetProp(context->window,"self",parentWindow);
    SetParent(context->window,parentHandle);
    ShowWindow(context->window,SW_SHOWNOACTIVATE);

    adjustFrameInParent(context,parentWindow,&x,&y,&w,&h);
   }
   else {
    ShowWindow(context->window,SW_HIDE);
    SetProp(context->window,"self",NULL);
    SetParent(context->window,NULL);
   }

   MoveWindow(context->window,x,y,w,h,NO);
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
    
    case kCGLCPSurfaceFrame:;
     context->x=value[0];
     context->y=value[1];
     context->w=value[2];
     context->h=value[3];

     if(context->imagePixelData!=NULL){
      [context->dibSection release];
      context->imagePixelData=NULL;
     }
     
     context->dibSection=[[O2DeviceContext_gdiDIBSection alloc] initWithWidth:context->w height:-context->h deviceContext:nil];
     context->imagePixelData=[context->dibSection bitmapBytes];
     adjustInParentForSurfaceOpacity(context);     
     break;
    
    case kCGLCPSurfaceOpacity:
     context->opacity=*value;
     adjustInParentForSurfaceOpacity(context);
     break;
    
    case kCGLCPWindowNumber:
     context->windowNumber=*value;
     adjustInParentForSurfaceOpacity(context);
     break;
     
    default:
     NSUnimplementedFunction();
     break;
   }
  
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLGetParameter(CGLContextObj context,CGLContextParameter parameter,GLint *value) { 
   switch(parameter){
   
    case kCGLCPSurfaceOpacity:
     *value=context->opacity;
     break;
    
    default:
     break;
   }
   
   return kCGLNoError;
}

CGLError CGLFlushDrawable(CGLContextObj context) {
   if(usesChildWindow(context))
    SwapBuffers(context->dc);
   else if(context->windowNumber!=0 && context->imagePixelData!=NULL){
    Win32Window *parentWindow=[Win32Window windowWithWindowNumber:context->windowNumber];
    HWND         parentHandle=[parentWindow windowHandle];
    O2Context   *o2Context=[parentWindow cgContext];
    GLint  pixelsWide=context->w;
    GLint  pixelsHigh=context->h;
    int    bitsPerPixel=32;
    int    samplesPerPixel=4;
    int    bytesPerRow=pixelsWide*4;
    GLuint bufferId;

  // glFinish(); supposedly this is not needed with glReadPixels
  
    GLint mode;
    opengl_glGetIntegerv(GL_DRAW_BUFFER,&mode);
    opengl_glReadBuffer(mode);
    
    opengl_glReadPixels(0,0,pixelsWide,pixelsHigh,GL_BGRA,GL_UNSIGNED_INT_8_8_8_8_REV,context->imagePixelData);
    
    int r,c;
    unsigned char *imageRow=context->imagePixelData;
    
    for(r=0;r<pixelsHigh;r++,imageRow+=bytesPerRow){
     for(c=0;c<bytesPerRow;c+=4){
      unsigned int b=imageRow[c+0];
      unsigned int g=imageRow[c+1];
      unsigned int r=imageRow[c+2];
      unsigned int a=imageRow[c+3];
      
      imageRow[c+2]=alphaMultiply(r,a);
      imageRow[c+1]=alphaMultiply(g,a);
      imageRow[c+0]=alphaMultiply(b,a);
     }
    }

    O2DeviceContext_gdi *deviceContext=nil;

    if([o2Context isKindOfClass:[O2Context_gdi class]])
     deviceContext=[(O2Context_gdi *)o2Context deviceContext];
    else {
     O2Surface *surface=[o2Context surface];
       
     if([surface isKindOfClass:[O2Surface_DIBSection class]])
      deviceContext=[(O2Surface_DIBSection *)surface deviceContext];
    }

    BLENDFUNCTION blend;
    
    blend.BlendOp=AC_SRC_OVER;
    blend.BlendFlags=0;
    blend.SourceConstantAlpha=255;
    blend.AlphaFormat=AC_SRC_ALPHA;

    int y=[parentWindow frame].size.height-(context->y+context->h);

    AlphaBlend([deviceContext dc],context->x,y,context->w,context->h,[context->dibSection dc],0,0,context->w,context->h,blend);

   }
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

