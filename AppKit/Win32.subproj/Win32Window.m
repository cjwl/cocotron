/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32Window.h>
#import <AppKit/Win32Event.h>
#import <AppKit/Win32Application.h>
#import <AppKit/Win32Display.h>
#import <Foundation/NSString_win32.h>
#import <AppKit/KGRenderingContext_gdi.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSDrawerWindow.h>
#import "KGLayer_gdi.h"
#import <AppKit/KGContext.h>

@implementation Win32Window

-(float)primaryScreenHeight {
   return GetSystemMetrics(SM_CYSCREEN);
}

-(NSRect)flipOnWin32Screen:(NSRect)rect {

   rect.origin.y=[self primaryScreenHeight]-(rect.origin.y+rect.size.height);

   return rect;
}

-(DWORD)win32ExtendedStyle {
   DWORD result=0;

   if(_styleMask==NSBorderlessWindowMask)
    result=WS_EX_TOOLWINDOW;
   else
    result=WS_EX_ACCEPTFILES;

   if(_styleMask&NSUtilityWindowMask)
    result|=WS_EX_TOOLWINDOW;

#if 0
#define CS_DROPSHADOW  0x00020000
   result|=CS_DROPSHADOW|WS_EX_LAYERED;
#endif

   return result/*|0x80000*/ ;
}

-(DWORD)win32Style {
   DWORD result=WS_CLIPCHILDREN|WS_CLIPSIBLINGS;

   if(_styleMask==NSBorderlessWindowMask)
    result|=WS_POPUP;
   else if(_styleMask==NSDocModalWindowMask)
    result|=WS_POPUP;
   else if(_styleMask==NSDrawerWindowMask)
    result|=WS_THICKFRAME|WS_POPUP; 
   else {
    result|=WS_OVERLAPPED;

    if(_styleMask&NSTitledWindowMask)
     result|=WS_CAPTION;
    if(_styleMask&NSClosableWindowMask)
     result|=WS_CAPTION;

    if(_styleMask&NSMiniaturizableWindowMask && !_isPanel)
     result|=WS_MINIMIZEBOX|WS_MAXIMIZEBOX;

    if(_styleMask&NSResizableWindowMask)
     result|=WS_THICKFRAME;

    if(_isPanel){
     result|=WS_CAPTION;// without CAPTION it puts space for a menu (???)
    }

    result|=WS_SYSMENU; // Is there a way to get a closebutton without SYSMENU for panels?
   }

   return result;
}

-(const char *)win32ClassName {
   if(_styleMask==NSBorderlessWindowMask)
    return "NSWin32PopUpWindow";
   else
    return "NSWin32StandardWindow";
}

-(RECT)win32FrameRECTFromContentRECT:(RECT)rect {
   DWORD style=[self win32Style];
   DWORD exStyle=[self win32ExtendedStyle];

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
   DWORD  style=[self win32Style];
   DWORD  exStyle=[self win32ExtendedStyle];
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

-initWithFrame:(NSRect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(Win32BackingStoreType)backingType {
   _styleMask=styleMask;
   _isPanel=isPanel;

   {
    DWORD  style=[self win32Style];
    DWORD  extendStyle=[self win32ExtendedStyle];
    NSRect win32Frame=[self win32FrameForRect:frame];
    const char *className=[self win32ClassName];

    _handle=CreateWindowEx(extendStyle,className,"", style,
      win32Frame.origin.x, win32Frame.origin.y,
      win32Frame.size.width, win32Frame.size.height,
      NULL,NULL, Win32ApplicationHandle(),NULL);
#if 0
#define LWA_ALPHA 0x00000002
    GetProcAddress(LoadLibrary("USER32"),"SetLayeredWindowAttributes")(_handle,RGB(255,255,255),0xFF,LWA_ALPHA);
#endif
   }

   SetProp(_handle,"self",self);

   _renderingContext=[[KGRenderingContext_gdi renderingContextWithWindowHWND:_handle] retain];

   _backingType=backingType;

   if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSAllWindowsRetained"])
    _backingType=Win32BackingStoreRetained;

   _size=frame.size;
   _backingSize=frame.size;
   switch(_backingType){

    case Win32BackingStoreRetained:
    case Win32BackingStoreNonretained:
     _backingLayer=nil;
     break;

    case Win32BackingStoreBuffered:
     _backingLayer=[[KGLayer_gdi alloc] initRelativeToRenderingContext:_renderingContext size:_backingSize unused:nil];
     break;
   }

   _ignoreMinMaxMessage=NO;
   _sentBeginSizing=NO;

   return self;
}

-(void)dealloc {
   [self invalidate];
   [super dealloc];
}

-(void)invalidate {
   _delegate=nil;
   SetProp(_handle,"self",nil);
   DestroyWindow(_handle);
   _handle=NULL;
   [_renderingContext release];
   _renderingContext=nil;
   [_backingLayer release];
   _backingLayer=nil;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}


-(HWND)windowHandle {
   return _handle;
}

-(KGContext *)cgContext {
   switch(_backingType){

    case Win32BackingStoreRetained:
    case Win32BackingStoreNonretained:
    default:
     return [_renderingContext cgContextWithSize:_size];

    case Win32BackingStoreBuffered:
    return [_backingLayer cgContext];
   }
}

-(void)rebuildBackingContextWithSize:(NSSize)size forceRebuild:(BOOL)forceRebuild {
   _size=size;
   
   switch(_backingType){

    case Win32BackingStoreRetained:
    case Win32BackingStoreNonretained:
     [_backingLayer release];
     _backingLayer=nil;
     break;

    case Win32BackingStoreBuffered:
     if(!NSEqualSizes(_backingSize,size) || _backingLayer==nil || forceRebuild){
      _backingSize=size;

      [_backingLayer release];
      _backingLayer=[[KGLayer_gdi alloc] initRelativeToRenderingContext:_renderingContext size:_backingSize unused:nil];
     }
     break;
   }
}

-(void)rebuildBackingContextWithSize:(NSSize)size {
   [self rebuildBackingContextWithSize:size forceRebuild:NO];
}


-(void)setTitle:(NSString *)title {
   SetWindowTextW(_handle,NSNullTerminatedUnicodeFromString(title));
}

-(void)setFrame:(NSRect)frame {
   NSRect moveTo=[self win32FrameForRect:frame];

   _ignoreMinMaxMessage=YES;
   MoveWindow([self windowHandle], moveTo.origin.x, moveTo.origin.y,
    moveTo.size.width, moveTo.size.height,YES);
   _ignoreMinMaxMessage=NO;

   [self rebuildBackingContextWithSize:frame.size];
}

-(void)showWindowForAppActivation:(NSRect)frame {
   [self showWindowWithoutActivation];
}

-(void)hideWindowForAppDeactivation:(NSRect)frame {
   [self hideWindow];
}

-(void)hideWindow {
#if 0
// doesn't work, window must be layered
   HANDLE  library=LoadLibrary("USER32");
   FARPROC animateWindow=GetProcAddress(library,"AnimateWindow");

   if(animateWindow!=NULL)
    animateWindow([self windowHandle],200,0x10000); // AW_HIDE
#endif

   ShowWindow([self windowHandle],SW_HIDE);
}

-(void)showWindowWithoutActivation {
   ShowWindow([self windowHandle],SW_SHOWNOACTIVATE);
}

-(void)bringToTop {
   if(_styleMask==NSBorderlessWindowMask){
    SetWindowPos([self windowHandle],HWND_TOPMOST,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   }
   else {
    SetWindowPos([self windowHandle],HWND_TOP,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   }
}

-(void)placeAboveWindow:(Win32Window *)other {
   HWND otherHandle=[other windowHandle];

   if(otherHandle==NULL)
    otherHandle=(_styleMask==NSBorderlessWindowMask)?HWND_TOPMOST:HWND_TOP;

   SetWindowPos([self windowHandle],otherHandle,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
}

-(void)placeBelowWindow:(Win32Window *)other {
   HWND before=GetNextWindow([other windowHandle],GW_HWNDNEXT);

   if(before==NULL)
    before=HWND_BOTTOM;

   SetWindowPos([self windowHandle],before,0,0,0,0,
      SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
}

-(void)makeKey {
   SetActiveWindow([self windowHandle]);
}

-(void)captureEvents {
   SetCapture([self windowHandle]);
}

-(void)miniaturize {
    ShowWindow([self windowHandle],SW_MINIMIZE);
}

-(void)deminiaturize {
    ShowWindow([self windowHandle],SW_RESTORE);
}

-(BOOL)isMiniaturized {
    return IsIconic(_handle);
}

-(void)flushBuffer {
   switch(_backingType){

    case Win32BackingStoreRetained:
    case Win32BackingStoreNonretained:
     break;

    case Win32BackingStoreBuffered:
     [[_renderingContext cgContextWithSize:_size] drawLayer:_backingLayer atPoint:NSMakePoint(0,0)];
     break;
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
   NSPoint point;

   GetCursorPos(&winPoint);

   point.x=winPoint.x;
   point.y=winPoint.y;
   point.y=[self primaryScreenHeight]-point.y;

   return point;
}

-(void)sendEvent:(CGEvent *)eventX {
   Win32Event *event=(Win32Event *)eventX;
   MSG         msg=[event msg];

   DispatchMessage(&msg);
}

-(void)_GetWindowRect {
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
    [_delegate platformWindow:self frameChanged:frame];
}

-(int)WM_SIZE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   NSSize contentSize={LOWORD(lParam),HIWORD(lParam)};
//   BOOL   equalSizes=NSEqualSizes(_backingSize,contentSize);

   if(contentSize.width>0 && contentSize.height>0){
    [self rebuildBackingContextWithSize:contentSize];

    [self _GetWindowRect];

//    if(equalSizes)
//     return 0;

    switch(_backingType){

     case Win32BackingStoreRetained:
     case Win32BackingStoreNonretained:
      break;

     case Win32BackingStoreBuffered:
      [_delegate platformWindow:self needsDisplayInRect:NSZeroRect];
      break;
    }
   }

   return 0;
}

-(int)WM_MOVE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   [_delegate platformWindowWillMove:self];
   [self _GetWindowRect];
   [_delegate platformWindowDidMove:self];
   return 0;
}

-(int)WM_PAINT_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   PAINTSTRUCT paintStruct;
   RECT        updateRECT;
//   NSRect      displayRect;

   if(GetUpdateRect([self windowHandle],&updateRECT,NO)){
// The update rect is usually empty

    switch(_backingType){

     case Win32BackingStoreRetained:
     case Win32BackingStoreNonretained:
      BeginPaint([self windowHandle],&paintStruct);
      [_delegate platformWindow:self needsDisplayInRect:NSZeroRect];
      EndPaint([self windowHandle],&paintStruct);
      break;

     case Win32BackingStoreBuffered:
      BeginPaint([self windowHandle],&paintStruct);
      [self flushBuffer];
      EndPaint([self windowHandle],&paintStruct);
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
    if(LOWORD(wParam))
     [_delegate platformWindowActivated:self];
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

#if 0
// doesn't seem to work
    case WM_PALETTECHANGED:
     [self rebuildBackingContextWithSize:_backingSize forceRebuild:YES];
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
    

    initializeWindowClass(&_standardWindowClass);
    _standardWindowClass.lpszClassName="NSWin32StandardWindow";
    _standardWindowClass.hIcon=icon;
    if(RegisterClass(&_standardWindowClass)==0)
     NSLog(@"RegisterClass failed");

    initializeWindowClass(&_popupWindowClass);
    _popupWindowClass.style|=CS_SAVEBITS;

#ifdef CS_DROPSHADOW
#warning CS_DROPSHADOW is defined, can get rid of it here
#else
#define CS_DROPSHADOW 0x20000
#endif

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
