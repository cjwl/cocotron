#import <OpenGL/OpenGL.h>
#import <Foundation/NSString.h>
#import "X11Display.h"

#import <X11/X.h>
#import <X11/Xlib.h>
#import <GL/gl.h>
#import <GL/glx.h>
#import <pthread.h>

struct _CGLContextObj {
   GLuint           retainCount;
   pthread_mutex_t lock;
   Window       window;
   Display     *display;
   XVisualInfo *vis;
   GLXContext   glc;
   int          x,y,w,h;
   GLint        opacity;
   int          windowNumber;
};

struct _CGLPixelFormatObj {
   GLuint retainCount;
   CGLPixelFormatAttribute *attributes;
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
    glXMakeCurrent(context->display, context->window, context->glc);
   
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

static GLint *addAttribute(GLint *attribList,int *capacity,int *count,GLint value){

   if(*count>=*capacity){
    *capacity*=2;
    attribList=realloc(attribList,*capacity*sizeof(GLint));
   }
   
   attribList[(*count)++]=value;
   
   return attribList;
}

static GLint *attributesFromPixelFormat(CGLPixelFormatObj pixelFormat){
   int    resultCapacity=8,resultCount=0;
   GLint *result=malloc(resultCapacity*sizeof(GLint));
   int  i,virtualScreen=0;
   
   attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_RGBA);

   for(i=0;pixelFormat->attributes[i]!=0;i++){
    CGLPixelFormatAttribute attribute=pixelFormat->attributes[i];

    if(attributeHasArgument(pixelFormat->attributes[i]))
     i++;

    switch(attribute){
    
     case kCGLPFAColorSize:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_RED_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/3);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_GREEN_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/3);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_BLUE_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/3);
      break;
      
     case kCGLPFAAlphaSize:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_ALPHA_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]);
      break;
      
     case kCGLPFAAccumSize:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_ACCUM_RED_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/4);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_ACCUM_GREEN_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/4);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_ACCUM_BLUE_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/4);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_ACCUM_ALPHA_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]/4);
      break;
      
     case kCGLPFADepthSize:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_DEPTH_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]);
      break;
      
     case kCGLPFAStencilSize:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_STENCIL_SIZE);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]);
      break;
      
     case kCGLPFAAuxBuffers:
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,GLX_AUX_BUFFERS);
      attribList=addAttribute(attribList,&resultCapacity,&resultCount,pixelFormat->attributes[i]);
      break;
    }
    
   }
   attribList=addAttribute(attribList,&resultCapacity,&resultCount,None);
}

CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,CGLContextObj share,CGLContextObj *resultp) {
   CGLContextObj result=malloc(sizeof(struct _CGLContextObj));
   GLint        *attribList=attributesFromPixelFormat(pixelFormat);
   
   result->display=[(X11Display*)[NSDisplay currentDisplay] display];
   
   int screen = DefaultScreen(_display);
      
   if((_visualInfo=glXChooseVisual(_display,screen,att))==NULL){
    NSLog(@"glXChooseVisual failed");
    return kCGLBadDisplay;
   }



   if(vis==NULL)
    return kCGLBadDisplay;
    
    
    
      
      Colormap cmap = XCreateColormap(_display, RootWindow(_display, _visualInfo->screen), _visualInfo->visual, AllocNone);

      if(cmap<0){
       NSLog(@"XCreateColormap failed");
       [self dealloc];
       return nil;
      }
      
      XSetWindowAttributes xattr;
      
      bzero(&xattr,sizeof(xattr));
      
      xattr.colormap=cmap;
      xattr.border_pixel = 0;                                                           
      xattr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask | StructureNotifyMask;
                                            
      NSRect frame=[view frame];
    
       Window parent=[(X11Window*)[[view window] platformWindow] drawable];
       
       if(parent==0)
        parent=RootWindow(_display, _visualInfo->screen);
        
      _window = XCreateWindow(_display,parent, frame.origin.x, frame.origin.y, frame.size.width,frame.size.height, 0, _visualInfo->depth, InputOutput, _visualInfo->visual, CWBorderPixel | CWColormap | CWEventMask, &xattr);
      
      
     // XSetWindowBackgroundPixmap(_display, _window, None);
     // [X11Window removeDecorationForWindow:_window onDisplay:_display];
      
      XMapWindow(_display, _window);

    
    
    
   
   pthread_mutex_init(&(result->lock),NULL);
   result->display=display;
   result->vis=vis;
   result->window=window;
   result->glc=glXCreateContext(result->display,result->vis,NULL,GL_TRUE);
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
    
   if(_window)
      XDestroyWindow(_display, _window);

    pthread_mutex_destroy(&(context->lock));
    glXDestroyContext(context->display, context->glc);
    free(context);
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
   pthread_mutex_lock(&(context->lock));
   return kCGLNoError;
}

CGL_EXPORT CGLError CGLUnlockContext(CGLContextObj context) {
   pthread_mutex_unlock(&(context->lock));
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







   NSRect frame=[view frame];
   frame=[[view superview] convertRect:frame toView:nil];

   X11Window *wnd=(X11Window*)[[view window] platformWindow];
   NSRect wndFrame=[wnd frame];
   
   frame.origin.y=wndFrame.size.height-(frame.origin.y+frame.size.height);
   
   XMoveResizeWindow(_display, _window, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
   Window viewWindow=[(X11Window*)[[view window] platformWindow] drawable];
   if(_lastParent!=viewWindow) {
      XReparentWindow(_display, _window, viewWindow, frame.origin.x, frame.origin.y);
      _lastParent=viewWindow;
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
   glXSwapBuffers(_display, _window);
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


