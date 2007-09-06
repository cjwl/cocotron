#import "NSOpenGLDrawable_gdiView.h"
#import <AppKit/NSWindow-Private.h>
#import <AppKit/Win32Window.h>
#import <AppKit/Win32Application.h>

@implementation NSOpenGLDrawable_gdiView 

static void pfdFromPixelFormat(PIXELFORMATDESCRIPTOR *pfd,NSOpenGLPixelFormat *pixelFormat){
   pfd->nSize=sizeof(PIXELFORMATDESCRIPTOR);
   pfd->nVersion=1;
   pfd->dwFlags=PFD_DRAW_TO_WINDOW|PFD_SUPPORT_OPENGL|PFD_GENERIC_ACCELERATED|PFD_DOUBLEBUFFER;
   pfd->iPixelType=PFD_TYPE_RGBA;
   pfd->cColorBits=24;
   pfd->cRedBits=0;
   pfd->cRedShift=0;
   pfd->cGreenBits=0;
   pfd->cGreenShift=0;
   pfd->cBlueBits=0;
   pfd->cBlueShift=0;
   pfd->cAlphaBits=0;
   pfd->cAlphaShift=0;
   pfd->cAccumBits=0;
   pfd->cAccumRedBits=0;
   pfd->cAccumGreenBits=0;
   pfd->cAccumBlueBits=0;
   pfd->cAccumAlphaBits=0;
   pfd->cDepthBits=32;
   pfd->cStencilBits=0;
   pfd->cAuxBuffers=0;
   pfd->iLayerType=PFD_MAIN_PLANE;
   pfd->bReserved=0;
   pfd->dwLayerMask=0;
   pfd->dwVisibleMask=0;
   pfd->dwDamageMask=0;
}

-initWithPixelFormat:(NSOpenGLPixelFormat *)pixelFormat view:(NSView *)view {
   PIXELFORMATDESCRIPTOR pfd;
   int                   pfIndex;
   
   pfdFromPixelFormat(&pfd,pixelFormat);

   _windowHandle=CreateWindowEx(WS_EX_TOOLWINDOW,"NSWin32OpenGLWindow", "", WS_CLIPCHILDREN | WS_CLIPSIBLINGS| WS_POPUP|WS_CHILD,
      0, 0, 500, 500,
      NULL,NULL, Win32ApplicationHandle(),NULL);
      
   _dc=GetDC(_windowHandle);
   
   pfIndex=ChoosePixelFormat(_dc,&pfd); 
 
   if(!SetPixelFormat(_dc,pfIndex,&pfd))
    NSLog(@"SetPixelFormat failed");
    
   [self updateWithView:view];
    
    SetWindowPos(_windowHandle,HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   return self;
}

-(void)dealloc {
   ReleaseDC(_windowHandle,_dc);
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
