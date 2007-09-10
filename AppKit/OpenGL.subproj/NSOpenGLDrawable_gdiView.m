#import "NSOpenGLDrawable_gdiView.h"
#import <AppKit/NSOpenGLPixelFormat.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/Win32Window.h>
#import <AppKit/Win32Application.h>

@implementation NSOpenGLDrawable_gdiView 

-(LRESULT)windowProcedure:(UINT)message wParam:(WPARAM)wParam
  lParam:(LPARAM)lParam {

   switch(message){
    case WM_MOUSEACTIVATE: return MA_NOACTIVATE;
    case WM_PAINT:{
     PAINTSTRUCT paintStruct;
     RECT        updateRECT;

     if(GetUpdateRect(_windowHandle,&updateRECT,NO)){
      BeginPaint(_windowHandle,&paintStruct);
      [_view lockFocus];
      [_view drawRect:[_view bounds]];
      [_view unlockFocus];
      EndPaint(_windowHandle,&paintStruct);
      break;
     }
    }
    return 0;

    default:
     break;
   }

   return DefWindowProc(_windowHandle,message,wParam,lParam);
}

static LRESULT CALLBACK windowProcedure(HWND handle,UINT message,WPARAM wParam,LPARAM lParam){
   NSAutoreleasePool        *pool=[NSAutoreleasePool new];
   NSOpenGLDrawable_gdiView *self=GetProp(handle,"self");
   LRESULT                   result;

   if(self==nil)
    result=DefWindowProc(handle,message,wParam,lParam);
   else
    result=[self windowProcedure:message wParam:wParam lParam:lParam];

   [pool release];

   return result;
}

+(void)initialize {
   if(self==[NSOpenGLDrawable_gdiView class]){
    static WNDCLASS windowClass;
    
    windowClass.style=CS_HREDRAW|CS_VREDRAW|CS_OWNDC|CS_DBLCLKS;
    windowClass.lpfnWndProc=windowProcedure;
    windowClass.cbClsExtra=0;
    windowClass.cbWndExtra=0;
    windowClass.hInstance=NULL;
    windowClass.hIcon=NULL;
    windowClass.hCursor=LoadCursor(NULL,IDC_ARROW);
    windowClass.hbrBackground=NULL;
    windowClass.lpszMenuName=NULL;
    windowClass.lpszClassName=NULL;

    windowClass.lpszClassName="NSWin32OpenGLWindow";
    windowClass.hIcon=NULL;
    if(RegisterClass(&windowClass)==0)
     NSLog(@"RegisterClass failed %d %s",__LINE__,__FILE__);
   }
}

static inline long attributeLong(NSOpenGLPixelFormat *pixelFormat,NSOpenGLPixelFormatAttribute attribute,int virtualScreen){
   long value=0;
   
   [pixelFormat getValues:&value forAttribute:attribute forVirtualScreen:virtualScreen];

   return value;
}

static inline BOOL attributeBool(NSOpenGLPixelFormat *pixelFormat,NSOpenGLPixelFormatAttribute attribute,int virtualScreen){
   return attributeLong(pixelFormat,attribute,virtualScreen)?YES:NO;
}

static void pfdFromPixelFormat(PIXELFORMATDESCRIPTOR *pfd,NSOpenGLPixelFormat *pixelFormat){
   int  virtualScreen=0;
   long value;
   
   pfd->nSize=sizeof(PIXELFORMATDESCRIPTOR);
   pfd->nVersion=1;
   
   pfd->dwFlags=PFD_SUPPORT_OPENGL|PFD_DOUBLEBUFFER;
   if(attributeBool(pixelFormat,NSOpenGLPFADoubleBuffer,virtualScreen))
    pfd->dwFlags|=PFD_DOUBLEBUFFER;
    
   if(attributeBool(pixelFormat,NSOpenGLPFAStereo,virtualScreen))
    pfd->dwFlags|=PFD_STEREO;
    
   if(attributeBool(pixelFormat,NSOpenGLPFAOffScreen,virtualScreen))
    pfd->dwFlags|=PFD_DRAW_TO_BITMAP;

   if(attributeBool(pixelFormat,NSOpenGLPFAAccelerated,virtualScreen))
    pfd->dwFlags|=PFD_GENERIC_ACCELERATED;

   if(attributeBool(pixelFormat,NSOpenGLPFAWindow,virtualScreen))
    pfd->dwFlags|=PFD_DRAW_TO_WINDOW;

   pfd->iPixelType=PFD_TYPE_RGBA;
   pfd->cColorBits=attributeLong(pixelFormat,NSOpenGLPFAColorSize,virtualScreen);
   pfd->cRedBits=0;
   pfd->cRedShift=0;
   pfd->cGreenBits=0;
   pfd->cGreenShift=0;
   pfd->cBlueBits=0;
   pfd->cBlueShift=0;
   pfd->cAlphaBits=attributeLong(pixelFormat,NSOpenGLPFAAlphaSize,virtualScreen);
   pfd->cAlphaShift=0;
   pfd->cAccumBits=attributeLong(pixelFormat,NSOpenGLPFAAccumSize,virtualScreen);
   pfd->cAccumRedBits=0;
   pfd->cAccumGreenBits=0;
   pfd->cAccumBlueBits=0;
   pfd->cAccumAlphaBits=0;
   pfd->cDepthBits=attributeLong(pixelFormat,NSOpenGLPFADepthSize,virtualScreen);
   pfd->cStencilBits=attributeLong(pixelFormat,NSOpenGLPFAStencilSize,virtualScreen);
   pfd->cAuxBuffers=attributeLong(pixelFormat,NSOpenGLPFAAuxBuffers,virtualScreen);
   pfd->iLayerType=PFD_MAIN_PLANE;
   pfd->bReserved=0;
   pfd->dwLayerMask=0; // ignored
   pfd->dwVisibleMask=0;
   pfd->dwDamageMask=0; // ignored
}

-initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat view:(NSView *)view {
   PIXELFORMATDESCRIPTOR pfd;
   int                   pfIndex;
   
   pfdFromPixelFormat(&pfd,pixelFormat);

   _view=view;
   _windowHandle=CreateWindowEx(WS_EX_TOOLWINDOW,"NSWin32OpenGLWindow", "", WS_CLIPCHILDREN | WS_CLIPSIBLINGS| WS_POPUP|WS_CHILD,
      0, 0, 500, 500,
      NULL,NULL, Win32ApplicationHandle(),NULL);
   SetProp(_windowHandle,"self",self);
   
   _dc=GetDC(_windowHandle);
   
   pfIndex=ChoosePixelFormat(_dc,&pfd); 
 
   if(!SetPixelFormat(_dc,pfIndex,&pfd))
    NSLog(@"SetPixelFormat failed");
    
   [self updateWithView:view];
    
    SetWindowPos(_windowHandle,HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   return self;
}

-(void)dealloc {
   SetProp(_windowHandle,"self",nil);
   ReleaseDC(_windowHandle,_dc);
   DestroyWindow(_windowHandle);
   _windowHandle=NULL;
   [super dealloc];
}

-(HDC)dc {
   return _dc;
}

-(void)invalidate {
}

-(void)updateWithView:(NSView *)view {
   NSWindow    *window=[view window];
   Win32Window *parent=[window platformWindow];
   HWND         parentHandle=[parent windowHandle];
   RECT         clientRECT;
   int          parentHeight;
   
   if(parentHandle!=NULL)
    SetParent(_windowHandle,parentHandle);

   NSRect frame=[view frame];
   frame=[[view superview] convertRect:frame toView:nil];
   
   GetClientRect(parentHandle,&clientRECT);
   parentHeight=clientRECT.bottom-clientRECT.top;
   
   MoveWindow(_windowHandle, frame.origin.x, parentHeight-(frame.origin.y+frame.size.height),frame.size.width, frame.size.height,YES);
}

-(void)makeCurrentWithGLContext:(HGLRC)glContext {   
   if(!opengl_wglMakeCurrent(_dc,glContext))
    NSLog(@"wglMakeCurrent failed");
}

-(void)swapBuffers {
   SwapBuffers(_dc);
}

@end
