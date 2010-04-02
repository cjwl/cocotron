/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/Win32Window.h>
#import <AppKit/Win32Event.h>
#import <AppKit/Win32Display.h>
#import <Foundation/NSString_win32.h>
#import <Onyx2D/O2Context.h>
#import <Onyx2D/O2Surface.h>
#import <AppKit/O2Context_gdi.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSDrawerWindow.h>
#import <QuartzCore/CABackingRenderer.h>

@implementation Win32Window

-(float)primaryScreenHeight {
   return GetSystemMetrics(SM_CYSCREEN);
}

-(NSRect)flipOnWin32Screen:(NSRect)rect {

   rect.origin.y=[self primaryScreenHeight]-(rect.origin.y+rect.size.height);

   return rect;
}

static DWORD Win32ExtendedStyleForStyleMask(unsigned styleMask,BOOL isPanel,BOOL isLayered) {
   DWORD result=0;

   if(styleMask==NSBorderlessWindowMask)
    result=WS_EX_TOOLWINDOW;
   else
    result=WS_EX_ACCEPTFILES;

   if(styleMask&(NSUtilityWindowMask|NSDocModalWindowMask))
    result|=WS_EX_TOOLWINDOW;

   if(isPanel)
    result|=WS_EX_NOACTIVATE;
    
   if(isLayered)
    result|=/*CS_DROPSHADOW|*/WS_EX_LAYERED;

   return result/*|0x80000*/ ;
}

static DWORD Win32StyleForStyleMask(unsigned styleMask,BOOL isPanel) {
   DWORD result=WS_CLIPCHILDREN|WS_CLIPSIBLINGS;

   if(styleMask==NSBorderlessWindowMask)
    result|=WS_POPUP;
   else if(styleMask==NSDocModalWindowMask)
    result|=WS_POPUP;
   else if(styleMask==NSDrawerWindowMask)
    result|=WS_THICKFRAME|WS_POPUP; 
   else {
    result|=WS_OVERLAPPED;

    if(styleMask&NSTitledWindowMask)
     result|=WS_CAPTION;
    if(styleMask&NSClosableWindowMask)
     result|=WS_CAPTION;

    if(styleMask&NSMiniaturizableWindowMask && !isPanel){
     result|=WS_MINIMIZEBOX;
     if(styleMask&NSResizableWindowMask)
      result|=WS_MAXIMIZEBOX;
    }

    if(styleMask&NSResizableWindowMask)
     result|=WS_THICKFRAME;

    if(isPanel){
     result|=WS_CAPTION;// without CAPTION it puts space for a menu (???)
    }

    result|=WS_SYSMENU; // Is there a way to get a closebutton without SYSMENU for panels?
   }

   return result;
}

static const char *Win32ClassNameForStyleMask(unsigned styleMask) {
   if(styleMask==NSBorderlessWindowMask)
    return "NSWin32PopUpWindow";
   else
    return "NSWin32StandardWindow";
}

-(RECT)win32FrameRECTFromContentRECT:(RECT)rect {
   DWORD style=Win32StyleForStyleMask(_styleMask,_isPanel);
   DWORD exStyle=Win32ExtendedStyleForStyleMask(_styleMask,_isPanel,_isLayered);

   AdjustWindowRectEx(&rect,style,NO,exStyle);

   return rect;
}

-(NSRect)win32FrameForRect:(NSRect)frame {
   NSRect moveTo=[self flipOnWin32Screen:frame];
   RECT   winRect;

   winRect.top=moveTo.origin.y;
   winRect.left=moveTo.origin.x;
   winRect.bottom=moveTo.origin.y+moveTo.size.height;
   winRect.right=moveTo.origin.x+moveTo.size.width;

   winRect=[self win32FrameRECTFromContentRECT:winRect];

   moveTo.origin.y=winRect.top;
   moveTo.origin.x=winRect.left;
   moveTo.size.width=(winRect.right-winRect.left);
   moveTo.size.height=(winRect.bottom-winRect.top); 

   return moveTo;
}

-(RECT)win32ContentRECTFromFrameRECT:(RECT)rect {
   DWORD  style=Win32StyleForStyleMask(_styleMask,_isPanel);
   DWORD  exStyle=Win32ExtendedStyleForStyleMask(_styleMask,_isPanel,_isLayered);
   RECT   delta;

   delta.top=0;
   delta.left=0;
   delta.bottom=100;
   delta.right=100;

   AdjustWindowRectEx(&delta,style,NO,exStyle);

   rect.top+=-delta.top;
   rect.left+=-delta.left;
   rect.bottom-=(delta.bottom-100);
   rect.right-=(delta.right-100);

   return rect;
}

-(void)createWindowHandle {
   DWORD  style=Win32StyleForStyleMask(_styleMask,_isPanel);
   DWORD  extendStyle=Win32ExtendedStyleForStyleMask(_styleMask,_isPanel,_isLayered);
   NSRect win32Frame=[self win32FrameForRect:_frame];
   const char *className=Win32ClassNameForStyleMask(_styleMask);

   _handle=CreateWindowEx(extendStyle,className,"", style,
     win32Frame.origin.x, win32Frame.origin.y,
     win32Frame.size.width, win32Frame.size.height,
     NULL,NULL, GetModuleHandle (NULL),NULL);

   SetProp(_handle,"self",self);
}

-(void)destroyWindowHandle {
   SetProp(_handle,"self",nil);
   DestroyWindow(_handle);
   _handle=NULL;
}

-initWithFrame:(NSRect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(CGSBackingStoreType)backingType {
   _styleMask=styleMask;
   _isPanel=isPanel;
   _isLayered=(_styleMask&(NSDocModalWindowMask|NSBorderlessWindowMask))?YES:NO;
   _isOpenGL=NO;
   _frame=frame;
   
   [self createWindowHandle];

   if(_isOpenGL){
    PIXELFORMATDESCRIPTOR pfd;
   
    memset(&pfd,0,sizeof(pfd));
   
    pfd.nSize=sizeof(PIXELFORMATDESCRIPTOR);
    pfd.nVersion=1;
    pfd.dwFlags=PFD_SUPPORT_OPENGL|PFD_DOUBLEBUFFER|PFD_GENERIC_ACCELERATED|PFD_DRAW_TO_WINDOW;
    pfd.iPixelType=PFD_TYPE_RGBA;
    pfd.cColorBits=24;
    pfd.cAlphaBits=8;
    pfd.iLayerType=PFD_MAIN_PLANE;

    HDC dc=GetDC(_handle);
    int pfIndex=ChoosePixelFormat(dc,&pfd); 
 
    if(!SetPixelFormat(dc,pfIndex,&pfd))
     NSLog(@"SetPixelFormat failed at %s %d",__FILE__,__LINE__);

    ReleaseDC(_handle,dc);
   }
   
   _size=frame.size;
   _cgContext=nil;

   _backingType=backingType;

   if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSAllWindowsRetained"])
    _backingType=CGSBackingStoreRetained;

   _backingContext=nil;

   _ignoreMinMaxMessage=NO;
   _sentBeginSizing=NO;
   _deviceDictionary=[NSMutableDictionary new];
   NSString *check=[[NSUserDefaults standardUserDefaults] stringForKey:@"CGBackingRasterizer"];
   if([check isEqual:@"Onyx"] || [check isEqual:@"GDI"])
    [_deviceDictionary setObject:check forKey:@"CGContext"];
    
   return self;
}

-(void)dealloc {
   [self invalidate];
   [_deviceDictionary release];
   [super dealloc];
}

-(void)invalidate {
   _delegate=nil;
   [self destroyWindowHandle];
   [_cgContext release];
   _cgContext=nil;
   [_backingContext release];
   _backingContext=nil;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}

-(NSWindow *)appkitWindow {
   return _delegate;
}

-(HWND)windowHandle {
   return _handle;
}

-(O2Context *)createCGContextIfNeeded {
   if(_cgContext==nil)
    _cgContext=[O2Context createContextWithSize:_size window:self];

   return _cgContext;
}

-(O2Context *)createBackingCGContextIfNeeded {
   if(_backingContext==nil){
    _backingContext=[O2Context createBackingContextWithSize:_size context:[self createCGContextIfNeeded] deviceDictionary:_deviceDictionary];
   }
   
   return _backingContext;
}

-(O2Context *)cgContext {
   switch(_backingType){

    case CGSBackingStoreRetained:
    case CGSBackingStoreNonretained:
    default:
     return [self createCGContextIfNeeded];

    case CGSBackingStoreBuffered:
     return [self createBackingCGContextIfNeeded];
   }
}

-(void)invalidateContextsWithNewSize:(NSSize)size forceRebuild:(BOOL)forceRebuild {
   if(!NSEqualSizes(_size,size) || forceRebuild){
    _size=size;
    [_cgContext release];
    _cgContext=nil;
    [_backingContext release];
    _backingContext=nil;
    [_delegate platformWindowDidInvalidateCGContext:self];
   }  
}

-(void)invalidateContextsWithNewSize:(NSSize)size {
   [self invalidateContextsWithNewSize:size forceRebuild:NO];
}

-(void)setStyleMask:(unsigned)mask {
   _styleMask=mask;
   _isLayered=(_styleMask&(NSDocModalWindowMask|NSBorderlessWindowMask))?YES:NO;
   [self destroyWindowHandle];
   [self createWindowHandle];
}

-(void)setTitle:(NSString *)title {
   SetWindowTextW(_handle,(const unichar *)[title cStringUsingEncoding:NSUnicodeStringEncoding]);
}

-(void)setFrame:(NSRect)frame {
   _frame=frame;
   
   NSRect moveTo=[self win32FrameForRect:_frame];

   _ignoreMinMaxMessage=YES;
   MoveWindow(_handle, moveTo.origin.x, moveTo.origin.y,
    moveTo.size.width, moveTo.size.height,YES);
   _ignoreMinMaxMessage=NO;

   [self invalidateContextsWithNewSize:frame.size];
}

-(void)sheetOrderFrontFromFrame:(NSRect)frame aboveWindow:(CGWindow *)aboveWindow {
   NSRect moveTo=[self win32FrameForRect:_frame];
   POINT origin={moveTo.origin.x,moveTo.origin.y};
   SIZE sizeWnd = {_size.width, 1};
   POINT ptSrc = {0, 0};

   UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
   _disableDisplay=YES;
   SetWindowPos(_handle,[(Win32Window *)aboveWindow windowHandle],0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW);
   _disableDisplay=NO;

   int i;
   int interval=(_size.height/400.0)*100;
   int chunk=_size.height/(interval/2);
   
   if(chunk<1)
    chunk=1;
    
   for(i=0;i<_size.height;i+=chunk){
    sizeWnd = (SIZE){_size.width, i};
    ptSrc = (POINT){0, _size.height-i};
    UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
    Sleep(1);
   }
   UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
}

-(void)sheetOrderOutToFrame:(NSRect)frame {
   int i;
   int interval=(_size.height/400.0)*100;
   int chunk=_size.height/(interval/2);
   
   if(chunk<1)
    chunk=1;
    
   for(i=0;i<_size.height;i+=chunk){
   SIZE sizeWnd = {_size.width, _size.height-i};
   POINT ptSrc = {0, i};
    UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
    Sleep(1);
   }
   SIZE sizeWnd = {_size.width, 0};
   POINT ptSrc = {0, i};
   UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
}

-(void)showWindowForAppActivation:(NSRect)frame {
   [self showWindowWithoutActivation];
}

-(void)hideWindowForAppDeactivation:(NSRect)frame {
   [self hideWindow];
}

-(void)hideWindow {   
   ShowWindow(_handle,SW_HIDE);
}

-(void)showWindowWithoutActivation {
   ShowWindow(_handle,SW_SHOWNOACTIVATE);
}

-(void)bringToTop {
   if(_styleMask==NSBorderlessWindowMask){
    SetWindowPos(_handle,HWND_TOPMOST,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   }
   else {
    SetWindowPos(_handle,HWND_TOP,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   }
}

-(void)placeAboveWindow:(Win32Window *)other {
   HWND otherHandle=[other windowHandle];

   if(otherHandle==NULL)
    otherHandle=(_styleMask==NSBorderlessWindowMask)?HWND_TOPMOST:HWND_TOP;

   SetWindowPos(_handle,otherHandle,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
}

-(void)placeBelowWindow:(Win32Window *)other {
   HWND before=GetNextWindow([other windowHandle],GW_HWNDNEXT);

   if(before==NULL)
    before=HWND_BOTTOM;

   SetWindowPos(_handle,before,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
}

-(void)makeKey {
   SetActiveWindow(_handle);
}

-(void)captureEvents {
   SetCapture(_handle);
}

-(void)miniaturize {
    ShowWindow(_handle,SW_MINIMIZE);
}

-(void)deminiaturize {
    ShowWindow(_handle,SW_RESTORE);
}

-(BOOL)isMiniaturized {
    return IsIconic(_handle);
}

-(CGLContextObj)createCGLContextObjIfNeeded {
   if(_cglContext==NULL){
    CGLError error;
    HDC dc=GetDC(_handle);
    
    CGL_EXPORT CGLError CGLCreateContext(CGLPixelFormatObj pixelFormat,HDC dc,CGLContextObj *resultp);
 
    if((error=CGLCreateContext(NULL,dc,&_cglContext))!=kCGLNoError)
     NSLog(@"CGLCreateContext failed with %d in %s %d",error,__FILE__,__LINE__);
    
    ReleaseDC(_handle,dc);
   }
   
   return _cglContext;
}

-(BOOL)openGLFlushBuffer {
   CGLError error;
   O2Surface *surface=[_backingContext surface];
   
   if(surface==nil){
    NSLog(@"no surface on %@",_backingContext);
    return NO;
   }
    
   [self createCGLContextObjIfNeeded];
       
   CABackingRenderer *renderer=(CABackingRenderer *)[NSClassFromString(@"CABackingRenderer") rendererWithCGLContext:_cglContext options:nil];
   
   if(renderer==nil)
    return NO;
    
   [renderer renderWithSurface:surface];
   
   HDC dc=GetDC(_handle);
   SwapBuffers(dc);
   ReleaseDC(_handle,dc);
   
   return YES;
}

-(void)flushBuffer {
   if(_isOpenGL){
    if([self openGLFlushBuffer])
     return;
   }
   
   if(_isLayered){
    BLENDFUNCTION blend = {0,0,0,0};
    blend.BlendOp = AC_SRC_OVER;
    blend.SourceConstantAlpha = 255;
    blend.AlphaFormat = AC_SRC_ALPHA;
    
    SIZE sizeWnd = {_size.width, _size.height};
    POINT ptSrc = {0, 0};

  //  UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, &blend, ULW_ALPHA);
    UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, &blend, ULW_OPAQUE);
   }
   else {
    switch(_backingType){

     case CGSBackingStoreRetained:
     case CGSBackingStoreNonretained:
      break;
 
     case CGSBackingStoreBuffered:
      if(_backingContext!=nil)
       [_cgContext drawBackingContext:_backingContext size:_size];
      break;
    }
   }
}

-(NSPoint)convertPOINTLToBase:(POINTL)point {
   NSPoint result;

   result.x=point.x;
   result.y=point.y;
   result.y=[self primaryScreenHeight]-result.y;

   return result;
}

-(NSPoint)mouseLocationOutsideOfEventStream {
   POINT   winPoint;

   GetCursorPos(&winPoint);

   return [self convertPOINTLToBase:winPoint];
}

-(void)adjustEventLocation:(NSPoint *)location {
    location->y=(_size.height-1)-location->y;
}

-(void)sendEvent:(CGEvent *)eventX {
   Win32Event *event=(Win32Event *)eventX;
   MSG         msg=[event msg];

   DispatchMessage(&msg);
}

-(void)addEntriesToDeviceDictionary:(NSDictionary *)entries {
   [_deviceDictionary addEntriesFromDictionary:entries];
}

-(void)flashWindow {
   FlashWindow(_handle,TRUE);
}

-(void)_GetWindowRectDidSize:(BOOL)didSize {
   RECT   windowRect;
   RECT   clientRect;
   NSRect frame;

   GetWindowRect(_handle,&windowRect);
   windowRect=[self win32ContentRECTFromFrameRECT:windowRect];

   GetClientRect(_handle,&clientRect);
   windowRect.right=windowRect.left+clientRect.right;
   windowRect.bottom=windowRect.top+clientRect.bottom;

   frame=[self flipOnWin32Screen:NSRectFromRECT(windowRect)];

   if(frame.size.width>0 && frame.size.height>0)
    [_delegate platformWindow:self frameChanged:frame didSize:didSize];
}

-(int)WM_SIZE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   NSSize contentSize={LOWORD(lParam),HIWORD(lParam)};
//   BOOL   equalSizes=NSEqualSizes(_backingSize,contentSize);

   if(contentSize.width>0 && contentSize.height>0){
    [self invalidateContextsWithNewSize:contentSize];

    [self _GetWindowRectDidSize:YES];

//    if(equalSizes)
//     return 0;

    switch(_backingType){

     case CGSBackingStoreRetained:
     case CGSBackingStoreNonretained:
      break;

     case CGSBackingStoreBuffered:
      [_delegate platformWindow:self needsDisplayInRect:NSZeroRect];
      break;
    }
   }

   return 0;
}

-(int)WM_MOVE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   [_delegate platformWindowWillMove:self];
   [self _GetWindowRectDidSize:NO];
   [_delegate platformWindowDidMove:self];
   return 0;
}

-(int)WM_PAINT_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {    
   PAINTSTRUCT paintStruct;
   RECT        updateRECT;
//   NSRect      displayRect;

   if(GetUpdateRect(_handle,&updateRECT,NO)){
// The update rect is usually empty

    switch(_backingType){

     case CGSBackingStoreRetained:
     case CGSBackingStoreNonretained:
      BeginPaint(_handle,&paintStruct);
      [_delegate platformWindow:self needsDisplayInRect:NSZeroRect];
      EndPaint(_handle,&paintStruct);
      break;

     case CGSBackingStoreBuffered:
      BeginPaint(_handle,&paintStruct);
      [self flushBuffer];
      EndPaint(_handle,&paintStruct);
      break;
    }
   }

   return 0;
}

-(int)WM_CLOSE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   [_delegate platformWindowWillClose:self];
   return 0;
}

-(int)WM_ACTIVATE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   if(HIWORD(wParam)){ // minimized
    if(LOWORD(wParam)){
     [_delegate platformWindowDeminiaturized:self];
    }
    else {
     [_delegate platformWindowMiniaturized:self];
    }
   }
   else {
    if(LOWORD(wParam)){
     [_delegate platformWindowActivated:self displayIfNeeded:!_disableDisplay];
    }
    else
     [_delegate platformWindowDeactivated:self checkForAppDeactivation:(lParam==0)];
   }
   return 0;
}

-(int)WM_MOUSEACTIVATE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   if([_delegate canBecomeKeyWindow])
    return MA_ACTIVATE;
   else
    return MA_NOACTIVATE;
}

-(int)WM_SETCURSOR_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   if([_delegate platformWindowSetCursorEvent:self])
    return 0;

   return DefWindowProc(_handle,WM_SETCURSOR,wParam,lParam);
}

-(int)WM_SIZING_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   RECT   rect=[self win32ContentRECTFromFrameRECT:*(RECT *)lParam];
   NSSize size=NSMakeSize(rect.right-rect.left,rect.bottom-rect.top);

   if(!_sentBeginSizing)
    [_delegate platformWindowWillBeginSizing:self];

   _sentBeginSizing=YES;

   size=[_delegate platformWindow:self frameSizeWillChange:size];

   switch(wParam){
    case WMSZ_LEFT:
    case WMSZ_BOTTOMLEFT:
     rect.bottom=rect.top+size.height;
     rect.left=rect.right-size.width;
     break;

    case WMSZ_TOP:
    case WMSZ_TOPRIGHT:
     rect.top=rect.bottom-size.height;
     rect.right=rect.left+size.width;
     break;

    case WMSZ_TOPLEFT:
     rect.top=rect.bottom-size.height;
     rect.left=rect.right-size.width;
     break;

    case WMSZ_RIGHT:
    case WMSZ_BOTTOM:
    case WMSZ_BOTTOMRIGHT:
     rect.bottom=rect.top+size.height;
     rect.right=rect.left+size.width;
     break;
   }

   *(RECT *)lParam=[self win32FrameRECTFromContentRECT:rect];

   return 0;
}

-(int)WM_GETMINMAXINFO_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   MINMAXINFO *info=(MINMAXINFO *)lParam;

   if(_ignoreMinMaxMessage)
    return 0;

   if([_delegate minSize].width>0)
    info->ptMinTrackSize.x=[_delegate minSize].width;
   if([_delegate minSize].height>0)
    info->ptMinTrackSize.y=[_delegate minSize].height;

   return 0;
}

-(int)WM_ENTERSIZEMOVE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   return 0;
}

-(int)WM_EXITSIZEMOVE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   if(_sentBeginSizing)
    [_delegate platformWindowDidEndSizing:self];

   [_delegate platformWindowExitMove:self];

   _sentBeginSizing=NO;

   return 0;
}

-(LRESULT)windowProcedure:(UINT)message wParam:(WPARAM)wParam
  lParam:(LPARAM)lParam {

   if([_delegate platformWindowIgnoreModalMessages:self]){
// these messages are sent directly, so we can't drop them in NSApplication's modal run loop
    switch(message){
     case WM_SETCURSOR:
     case WM_MOUSEACTIVATE:
      return 0;

     case WM_NCHITTEST:
      return HTCLIENT;
    }
   }

   switch(message){

    case WM_ACTIVATE:      return [self WM_ACTIVATE_wParam:wParam lParam:lParam];
    case WM_MOUSEACTIVATE: return [self WM_MOUSEACTIVATE_wParam:wParam lParam:lParam];
    case WM_SIZE:          return [self WM_SIZE_wParam:wParam lParam:lParam];
    case WM_MOVE:          return [self WM_MOVE_wParam:wParam lParam:lParam];
    case WM_PAINT:         return [self WM_PAINT_wParam:wParam lParam:lParam];
    case WM_CLOSE:         return [self WM_CLOSE_wParam:wParam lParam:lParam];
    case WM_SETCURSOR:     return [self WM_SETCURSOR_wParam:wParam lParam:lParam];
    case WM_SIZING:        return [self WM_SIZING_wParam:wParam lParam:lParam];
    case WM_GETMINMAXINFO: return [self WM_GETMINMAXINFO_wParam:wParam lParam:lParam];
    case WM_ENTERSIZEMOVE: return [self WM_ENTERSIZEMOVE_wParam:wParam lParam:lParam];
    case WM_EXITSIZEMOVE:  return [self WM_EXITSIZEMOVE_wParam:wParam lParam:lParam];
    case WM_SYSCOLORCHANGE:
     [[Win32Display currentDisplay] invalidateSystemColors];
     [_delegate platformWindowStyleChanged:self];
     return 0;
 //   case WM_ERASEBKGND: return 1;

#if 0
// doesn't seem to work
    case WM_PALETTECHANGED:
     [self invalidateContextsWithNewSize:_backingSize forceRebuild:YES];
     [_delegate platformWindow:self needsDisplayInRect:NSZeroRect];
     break;
#endif

    default:
     break;
   }

   return DefWindowProc(_handle,message,wParam,lParam);
}

static LRESULT CALLBACK windowProcedure(HWND handle,UINT message,WPARAM wParam,LPARAM lParam){
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   Win32Window       *self=GetProp(handle,"self");
   LRESULT            result;

   if(self==nil)
    result=DefWindowProc(handle,message,wParam,lParam);
   else
    result=[self windowProcedure:message wParam:wParam lParam:lParam];

   [pool release];

   return result;
}

static void initializeWindowClass(WNDCLASS *class){
   class->style=CS_HREDRAW|CS_VREDRAW|CS_OWNDC|CS_DBLCLKS;
   class->lpfnWndProc=windowProcedure;
   class->cbClsExtra=0;
   class->cbWndExtra=0;
   class->hInstance=NULL;
   class->hIcon=NULL;
   class->hCursor=LoadCursor(NULL,IDC_ARROW);
   class->hbrBackground=NULL;
   class->lpszMenuName=NULL;
   class->lpszClassName=NULL;
}

+(void)initialize {
   if(self==[Win32Window class]){
    NSString *name=[[NSProcessInfo processInfo] processName];
    NSString *path=[[NSBundle mainBundle] pathForResource:name ofType:@"ico"];
    HICON     icon=(path==nil)?NULL:LoadImage(NULL,[path fileSystemRepresentation],IMAGE_ICON,0,0,LR_DEFAULTCOLOR|LR_LOADFROMFILE);

    static WNDCLASS _standardWindowClass,_popupWindowClass,_glWindowClass;
    OSVERSIONINFOEX osVersion;
    
    if(icon==NULL)
     icon=LoadImage(NULL,IDI_APPLICATION,IMAGE_ICON,0,0,LR_DEFAULTCOLOR|LR_SHARED);

    initializeWindowClass(&_standardWindowClass);
    _standardWindowClass.lpszClassName="NSWin32StandardWindow";
    _standardWindowClass.hIcon=icon;
    if(RegisterClass(&_standardWindowClass)==0)
     NSLog(@"RegisterClass failed");

    initializeWindowClass(&_popupWindowClass);
    _popupWindowClass.style|=CS_SAVEBITS;

    osVersion.dwOSVersionInfoSize=sizeof(osVersion);
    GetVersionEx((OSVERSIONINFO *)&osVersion);
    // XP or higher
    if((osVersion.dwMajorVersion==5 && osVersion.dwMinorVersion>=1) || osVersion.dwMajorVersion>5){
     _popupWindowClass.style|=CS_DROPSHADOW;
    }

    _popupWindowClass.lpszClassName="NSWin32PopUpWindow";
    if(RegisterClass(&_popupWindowClass)==0)
     NSLog(@"RegisterClass failed");
   }
}

@end
