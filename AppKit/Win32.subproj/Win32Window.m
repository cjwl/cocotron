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
#import <Onyx2D/O2Context_gdi.h>
#import <Foundation/NSPlatform_win32.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSDrawerWindow.h>
#import <QuartzCore/CAWindowOpenGLContext.h>
#import <Onyx2D/O2Surface_DIBSection.h>
#import <CoreGraphics/CGLPixelSurface.h>

#import "opengl_dll.h"

@implementation Win32Window

static CGRect convertFrameToWin32ScreenCoordinates(CGRect rect){
   rect.origin.y=GetSystemMetrics(SM_CYSCREEN)-(rect.origin.y+rect.size.height);

   return rect;
}

static CGRect convertFrameFromWin32ScreenCoordinates(CGRect rect){
   rect.origin.y=GetSystemMetrics(SM_CYSCREEN)-(rect.origin.y+rect.size.height);

   return rect;
}

-(BOOL)isLayeredWindow {
   if(_styleMask&NSDocModalWindowMask)
    return TRUE;
   
   if(_styleMask==NSBorderlessWindowMask)
    return TRUE;
/*
   if(!_isOpaque)
    return TRUE;
   
   if(_alphaValue<1.0f)
    return TRUE;
 */  
   return FALSE;
}

static DWORD Win32ExtendedStyleForStyleMask(unsigned styleMask,BOOL isPanel,BOOL isLayeredWindow) {
   DWORD result=0;

   if(styleMask==NSBorderlessWindowMask)
    result=WS_EX_TOOLWINDOW;
   else
    result=WS_EX_ACCEPTFILES;

   if(styleMask&(NSUtilityWindowMask|NSDocModalWindowMask))
    result|=WS_EX_TOOLWINDOW;

   if(isPanel)
    result|=WS_EX_NOACTIVATE;
    
   if(isLayeredWindow)
    result|=/*CS_DROPSHADOW|*/WS_EX_LAYERED;

	if (styleMask&NSUtilityWindowMask) {
		result|=WS_EX_TOPMOST;// Make it floating as a utility window should be
	}
		
   return result/*|0x80000*/ ;
}

static DWORD Win32StyleForStyleMask(unsigned styleMask,BOOL isPanel,BOOL isLayeredWindow) {
   DWORD result=isLayeredWindow?0:WS_CLIPCHILDREN|WS_CLIPSIBLINGS;

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

-(void)changeWindowStyle {
   SetWindowLong(_handle,GWL_EXSTYLE,Win32ExtendedStyleForStyleMask(_styleMask,_isPanel,[self isLayeredWindow])); 
   SetWindowLong(_handle,GWL_STYLE,Win32StyleForStyleMask(_styleMask,_isPanel,[self isLayeredWindow])); 
}

void CGNativeBorderFrameWidthsForStyle(unsigned styleMask,CGFloat *top,CGFloat *left,CGFloat *bottom,CGFloat *right){   
   RECT delta;

   delta.top=0;
   delta.left=0;
   delta.bottom=100;
   delta.right=100;

   AdjustWindowRectEx(&delta,Win32StyleForStyleMask(styleMask,NO,NO),NO,Win32ExtendedStyleForStyleMask(styleMask,NO,NO));
   
   *top=-delta.top;
   *left=-delta.left;
   *bottom=delta.bottom-100;
   *right=delta.right-100;
}

CGRect CGInsetRectForNativeWindowBorder(CGRect frame,unsigned styleMask){
   CGFloat top,left,bottom,right;
   
   CGNativeBorderFrameWidthsForStyle(styleMask,&top,&left,&bottom,&right);
   
   frame.origin.x+=left;
   frame.origin.y+=bottom;
   frame.size.width-=left+right;
   frame.size.height-=top+bottom;
   
   return frame;
}

CGRect CGOutsetRectForNativeWindowBorder(CGRect frame,unsigned styleMask){
   CGFloat top,left,bottom,right;
   
   CGNativeBorderFrameWidthsForStyle(styleMask,&top,&left,&bottom,&right);
   
   frame.origin.x-=left;
   frame.origin.y-=bottom;
   frame.size.width+=left+right;
   frame.size.height+=top+bottom;
   
   return frame;
}

static const char *Win32ClassNameForStyleMask(unsigned styleMask,bool hasShadow) {
   if(styleMask==NSBorderlessWindowMask)
    return  hasShadow?"Win32BorderlessWindowWithShadow":"Win32BorderlessWindow";
   else
    return "NSWin32StandardWindow";
}

-(void)createWindowHandle {
   CGRect win32Frame=convertFrameToWin32ScreenCoordinates(_frame);
   DWORD  style=Win32StyleForStyleMask(_styleMask,_isPanel,[self isLayeredWindow]);
   DWORD  extendStyle=Win32ExtendedStyleForStyleMask(_styleMask,_isPanel,[self isLayeredWindow]);
   const char *className=Win32ClassNameForStyleMask(_styleMask,_hasShadow);
    
   _handle=CreateWindowEx(extendStyle,className,"", style,
     win32Frame.origin.x, win32Frame.origin.y,
     win32Frame.size.width, win32Frame.size.height,
     NULL,NULL, GetModuleHandle (NULL),NULL);

   if(_title!=nil)
    SetWindowTextW(_handle,(const unichar *)[_title cStringUsingEncoding:NSUnicodeStringEncoding]);

   SetProp(_handle,"Win32Window",self);

   [self setupPixelFormat];
}

-(void)destroyWindowHandle {
   SetProp(_handle,"Win32Window",nil);
   DestroyWindow(_handle);
   _handle=NULL;
}

-initWithFrame:(CGRect)frame styleMask:(unsigned)styleMask isPanel:(BOOL)isPanel backingType:(CGSBackingStoreType)backingType {   
   InitializeCriticalSection(&_lock);
   _frame=frame;
   _level=kCGNormalWindowLevel;
   _isOpaque=YES;
   _hasShadow=YES;
   _alphaValue=1.0;
   
   _styleMask=styleMask;
   _isPanel=isPanel;
   
   [self createWindowHandle];

   _cgContext=nil;

   _backingType=backingType;

   if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSAllWindowsRetained"])
    _backingType=CGSBackingStoreRetained;

   _backingContext=nil;

    _surfaceCount=0;
    _surfaces=NULL;
   
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
    if(_surfaces!=NULL)
        NSZoneFree(NULL,_surfaces);  
    CGLReleaseContext(_overlayResult);
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

-(void)lock {
   EnterCriticalSection(&_lock);
}

-(void)unlock {
   LeaveCriticalSection(&_lock);
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
    _cgContext=(O2Context_gdi *)[O2Context createContextWithSize:_frame.size window:self];

   return _cgContext;
}

-(O2Context *)createBackingCGContextIfNeeded {
   if(_backingContext==nil){
    _backingContext=[O2Context createBackingContextWithSize:_frame.size context:[self createCGContextIfNeeded] deviceDictionary:_deviceDictionary];
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

-(void)invalidateContextsWithNewSize:(CGSize)size forceRebuild:(BOOL)forceRebuild {
   if(!NSEqualSizes(_frame.size,size) || forceRebuild){
    [self lock];
    _frame.size=size;
    [_cgContext release];
    _cgContext=nil;
    [_backingContext release];
    _backingContext=nil;
    [_delegate platformWindowDidInvalidateCGContext:self];
    [self unlock];
   }  
}

-(void)invalidateContextsWithNewSize:(CGSize)size {
   [self invalidateContextsWithNewSize:size forceRebuild:NO];
}

-(CGRect)frame {
   return _frame;
}

-(unsigned)styleMask {
   return _styleMask;
}

-(void)setLevel:(int)value {
   _level=value;
}

-(void)setStyleMask:(unsigned)mask {
   _styleMask=mask;
   [self destroyWindowHandle];
   [self createWindowHandle];
}

-(void)setTitle:(NSString *)title {
   title=[title copy];
   [_title release];
   _title=title;
   
   SetWindowTextW(_handle,(const unichar *)[_title cStringUsingEncoding:NSUnicodeStringEncoding]);
}

-(void)setFrame:(CGRect)frame {
   [self invalidateContextsWithNewSize:frame.size];

    // _frame must be set before the MoveWindow as MoveWindow generates WM_SIZE and WM_MOVE messages
    // which need to check the size against the current to prevent erroneous resize/move notifications
    _frame=frame;
    
   CGRect moveTo=convertFrameToWin32ScreenCoordinates(frame);

   _ignoreMinMaxMessage=YES;
   MoveWindow(_handle, moveTo.origin.x, moveTo.origin.y,moveTo.size.width, moveTo.size.height,YES);
   _ignoreMinMaxMessage=NO;
}

-(void)setOpaque:(BOOL)value {
   _isOpaque=value;
   [self flushBuffer];
}

-(void)setAlphaValue:(CGFloat)value {
   _alphaValue=value;
   [self flushBuffer];
}

-(void)setHasShadow:(BOOL)value {
   _hasShadow=value;
   [self destroyWindowHandle];
   [self createWindowHandle];
}

-(void)sheetOrderFrontFromFrame:(CGRect)frame aboveWindow:(CGWindow *)aboveWindow {
   CGRect moveTo=convertFrameToWin32ScreenCoordinates(_frame);
   POINT origin={moveTo.origin.x,moveTo.origin.y};
   SIZE sizeWnd = {_frame.size.width, 1};
   POINT ptSrc = {0, 0};

   UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
   _disableDisplay=YES;
   SetWindowPos(_handle,[(Win32Window *)aboveWindow windowHandle],0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW);
   _disableDisplay=NO;

   int i;
   int interval=(_frame.size.height/400.0)*100;
   int chunk=_frame.size.height/(interval/2);
   
   if(chunk<1)
    chunk=1;
    
   for(i=0;i<_frame.size.height;i+=chunk){
    sizeWnd = (SIZE){_frame.size.width, i};
    ptSrc = (POINT){0, _frame.size.height-i};
    UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
    Sleep(1);
   }
   UpdateLayeredWindow(_handle, NULL, &origin, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
}

-(void)sheetOrderOutToFrame:(CGRect)frame {
   int i;
   int interval=(_frame.size.height/400.0)*100;
   int chunk=_frame.size.height/(interval/2);
   
   if(chunk<1)
    chunk=1;
    
   for(i=0;i<_frame.size.height;i+=chunk){
   SIZE sizeWnd = {_frame.size.width, _frame.size.height-i};
   POINT ptSrc = {0, i};
    UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
    Sleep(1);
   }
   SIZE sizeWnd = {_frame.size.width, 0};
   POINT ptSrc = {0, i};
   UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [(O2Context_gdi *)_backingContext dc], &ptSrc, 0, NULL, ULW_OPAQUE);
}

-(void)showWindowForAppActivation:(CGRect)frame {
   [self showWindowWithoutActivation];
}

-(void)hideWindowForAppDeactivation:(CGRect)frame {
   [self hideWindow];
}

-(void)hideWindow {   
   ShowWindow(_handle,SW_HIDE);
}

-(void)showWindowWithoutActivation {
   ShowWindow(_handle,SW_SHOWNOACTIVATE);
}

-(void)bringToTop {
   SetWindowPos(_handle,(_level>kCGNormalWindowLevel)?HWND_TOPMOST:HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW);
   }

-(void)placeAboveWindow:(Win32Window *)other {
   HWND otherHandle=[other windowHandle];

   if(otherHandle==NULL)
    otherHandle=(_level>kCGNormalWindowLevel)?HWND_TOPMOST:HWND_TOP;

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

-(void)makeMain {
}

-(void)captureEvents {
   SetCapture(_handle);
}

-(void)miniaturize {
    _isMiniaturized=YES;
    ShowWindow(_handle,SW_MINIMIZE);
}

-(void)deminiaturize {
    _isMiniaturized=NO;
    ShowWindow(_handle,SW_RESTORE);
}

-(BOOL)isMiniaturized {
// We need to track miniaturized state more accurately than IsIconic
    return _isMiniaturized;
}

CGL_EXPORT CGLError CGLCopyPixelsFromSurface(O2Surface_DIBSection *srcSurface,CGLContextObj destination);
CGL_EXPORT CGLError CGLCopyPixels(CGLContextObj source,CGLContextObj destination);

-(O2Surface_DIBSection *)resultSurface {
    O2Surface_DIBSection *backingSurface=(O2Surface_DIBSection *)[_backingContext surface];

    if(_surfaceCount==0)
        return backingSurface;
        
    if(_overlayResult==NULL){
        CGLPixelFormatObj pf;
        GLint novs;
        
        CGLPixelFormatAttribute attributes[]={
        
            0
        };
        
        CGLChoosePixelFormat(attributes,&pf,&novs);
        
        CGLError error;
        
        if((error=CGLCreateContext(pf,NULL,&_overlayResult))!=kCGLNoError)
            NSLog(@"CGLCreateContext failed with %d in %s %d",error,__FILE__,__LINE__);

        CGLReleasePixelFormat(pf);
    }
   [self lock];
    
    GLint size[2]={ O2ImageGetWidth(backingSurface), O2ImageGetHeight(backingSurface) };
    
    CGLSetParameter(_overlayResult,kCGLCPSurfaceBackingSize,size);
    
    CGLCopyPixelsFromSurface(backingSurface,_overlayResult);
      
    int i;
    for(i=0;i<_surfaceCount;i++)
        CGLCopyPixels(_surfaces[i],_overlayResult);
    
    CGLPixelSurface *pixelSurface;
    
    CGLGetParameter(_overlayResult,kCGLCPOverlayPointer,&pixelSurface);
    
    [self unlock];
    return (O2Surface_DIBSection *)[pixelSurface validSurface];
}

static int reportGLErrorIfNeeded(const char *function,int line){
   GLenum error=glGetError();

   if(error!=GL_NO_ERROR)
     NSLog(@"%s %d error=%d/%x",function,line,error,error);
   
   return error;
}

-(void)flushCGLContext:(CGLContextObj)cglContext {
/*
  If we SwapBuffers() and read from the front buffer we get junk because the swapbuffers may not be
  complete. Read from GL_BACK.
 */
   // only pull the pixels if this context is not a pbuffer
    CGLPBufferObj CGLGetRetainedPBuffer(CGLContextObj context);
    
    CGLPBufferObj pBuffer=CGLGetRetainedPBuffer(cglContext);
    
    if(pBuffer==NULL){
        CGLLockContext(cglContext);

        CGLContextObj saveContext=CGLGetCurrentContext();

        CGLSetCurrentContext(cglContext);

        GLint buffer;
   
        glGetIntegerv(GL_DRAW_BUFFER,&buffer);
        reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
        glReadBuffer(buffer);
        reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
   
        CGLPixelSurface *overlay;
    
        CGLGetParameter(cglContext,kCGLCPOverlayPointer,&overlay);

        [overlay readBuffer];
   
        CGLSetCurrentContext(saveContext);

        CGLUnlockContext(cglContext);
   }
   
   CGLReleasePBuffer(pBuffer);
   
   [self flushBuffer];
}

-(void)disableFlushWindow {
   _disableFlushWindow++;
}

-(void)enableFlushWindow {
   _disableFlushWindow--;
}

-(void)setupPixelFormat {
    PIXELFORMATDESCRIPTOR pfd;
    HDC       dc=GetDC(_handle);
       
    memset(&pfd,0,sizeof(pfd));
   
    pfd.nSize=sizeof(PIXELFORMATDESCRIPTOR);
    pfd.nVersion=1;
    pfd.dwFlags=PFD_SUPPORT_OPENGL|PFD_GENERIC_ACCELERATED|PFD_DRAW_TO_WINDOW|PFD_DOUBLEBUFFER;
    pfd.iPixelType=PFD_TYPE_RGBA;
    pfd.cColorBits=24;
    pfd.cRedBits=8;
    pfd.cGreenBits=8;
    pfd.cBlueBits=8;
    pfd.cAlphaBits=8;
    pfd.iLayerType=PFD_MAIN_PLANE;

    int pfIndex=ChoosePixelFormat(dc,&pfd); 
 
    if(!SetPixelFormat(dc,pfIndex,&pfd))
     NSLog(@"SetPixelFormat failed at %s %d",__FILE__,__LINE__);

    ReleaseDC(_handle,dc);
}

-(BOOL)createCGLContextObjIfNeeded {
    if(_hglrc!=NULL)
        return NO;
        
    HDC dc=GetDC(_handle);
    
    _hglrc=opengl_wglCreateContext(dc);
    
    ReleaseDC(_handle,dc);
    
    return YES;
}

-(void)flushSurface:(O2Surface *)surface flip:(BOOL)flip textureId:(GLint)textureId {

    glBindTexture(GL_TEXTURE_2D, textureId);						
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

    O2SurfaceLock(surface);
    size_t width=O2ImageGetWidth(surface);
    size_t height=O2ImageGetHeight(surface);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, [surface pixelBytes]);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    O2SurfaceUnlock(surface);

    GLint vertices[4*2];
    GLint texture[4*2];
   
    vertices[0]=0;
    vertices[1]=0;
    vertices[2]=width;
    vertices[3]=0;
    vertices[4]=0;
    vertices[5]=height;
    vertices[6]=width;
    vertices[7]=height;
   
    if(flip){
        texture[0]=0;
        texture[1]=1;
        texture[2]=1;
        texture[3]=1;
        texture[4]=0;
        texture[5]=0;
        texture[6]=1;
        texture[7]=0;
    }
    else {
        texture[0]=0;
        texture[1]=0;
        texture[2]=1;
        texture[3]=0;
        texture[4]=0;
        texture[5]=1;
        texture[6]=1;
        texture[7]=1;
    }
    
    glTexCoordPointer(2, GL_INT, 0, texture);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    glVertexPointer(2, GL_INT, 0, vertices);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
}

-(void)openGLFlushBuffer {
    CGLError error;
    O2Surface_DIBSection *surface=[_backingContext surface];
   
    if(surface==nil){
        NSLog(@"no surface on %@",_backingContext);
        return ;
    }
    
   BOOL didCreate = [self createCGLContextObjIfNeeded];
   
    HDC dc=GetDC(_handle);

    opengl_wglMakeCurrent(dc,_hglrc);
    
    if(didCreate){
        const char *extensions=opengl_wglGetExtensionsStringARB(dc);

        _hasRenderTexture=(extensions==NULL)?NO:((strstr(extensions,"WGL_ARB_render_texture")==NULL)?NO:YES);
        _hasMakeCurrentRead=NO;//(extensions==NULL)?NO:((strstr(extensions,"WGL_ARB_make_current_read")==NULL)?NO:YES);
        _hasReadback=YES;
    }
    
    O2Surface *CGLGetSurface(CGLContextObj context);

// reshape
   size_t width=O2ImageGetWidth(surface);
   size_t height=O2ImageGetHeight(surface);

   glDisable(GL_DEPTH_TEST);
   glShadeModel(GL_FLAT);

// reshape
   glViewport(0,0,width,height);
   glMatrixMode(GL_PROJECTION);                      
   glLoadIdentity();
   glOrtho (0, width, 0, height, -1, 1);

// render
   glMatrixMode(GL_MODELVIEW);                                           
   glLoadIdentity();

   glClearColor(0, 0, 0, 0);
   glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
   
   glEnable( GL_TEXTURE_2D );
   glEnableClientState(GL_VERTEX_ARRAY);
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);

   glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

   glEnable (GL_BLEND);
   
   // background is copied on
   glBlendFunc(GL_ONE, GL_ZERO);

   glPushMatrix();

   GLint allTextures[1+_surfaceCount];
   
   glGenTextures(1+_surfaceCount,allTextures);
   
     CGFloat top,left,bottom,right;
       
     CGNativeBorderFrameWidthsForStyle([self styleMask],&top,&left,&bottom,&right);
     // this applies to all surfaces too too
     glTranslatef(-right,-bottom,0);

     [self flushSurface:surface flip:YES textureId:allTextures[0]];

     reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

    int i;
    
    CGLPBufferObj releasePbuffers[_surfaceCount];
    
    for(i=0;i<_surfaceCount;i++) {
        GLint size[2];
        GLint origin[2];
        GLint opacity=1;
        
        CGLPBufferObj CGLGetRetainedPBuffer(CGLContextObj context);
        
        releasePbuffers[i]=CGLGetRetainedPBuffer(_surfaces[i]);
        
        CGLGetParameter(_surfaces[i],kCGLCPSurfaceBackingSize,size);
        CGLGetParameter(_surfaces[i],kCGLCPSurfaceBackingOrigin,origin);
        CGLGetParameter(_surfaces[i],kCGLCPSurfaceOpacity,&opacity);

        if(opacity)
            glBlendFunc(GL_ONE, GL_ZERO);
        else
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
        if(_hasRenderTexture && releasePbuffers[i]!=NULL){
            CGLPBufferObj pBuffer=releasePbuffers[i];
            
            glBindTexture(GL_TEXTURE_2D, allTextures[1+i]);						
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            
            CGLTexImagePBuffer(NULL,pBuffer,WGL_FRONT_LEFT_ARB);

            glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);

            GLint vertices[4*2];
            GLint texture[4*2];
   
            vertices[0]=0;
            vertices[1]=0;
            vertices[2]=size[0];
            vertices[3]=0;
            vertices[4]=0;
            vertices[5]=size[1];
            vertices[6]=size[0];
            vertices[7]=size[1];

            texture[0]=0;
            texture[1]=0;
            texture[2]=1;
            texture[3]=0;
            texture[4]=0;
            texture[5]=1;
            texture[6]=1;
            texture[7]=1;

            glPushMatrix(); 
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glTranslatef(0,0,1);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glTranslatef((float)origin[0],(float)origin[1],0);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            
            glTexCoordPointer(2, GL_INT, 0, texture);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glVertexPointer(2, GL_INT, 0, vertices);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            
            glPopMatrix();
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            glBindTexture(GL_TEXTURE_2D, 0);						
        }
        else if(_hasMakeCurrentRead){
            HDC CGLGetDC(CGLContextObj context);
            
            opengl_wglMakeContextCurrentARB(dc,CGLGetDC(_surfaces[i]),_hglrc);

            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            
            glRasterPos3i(origin[0],origin[1],i);
            
        //    glReadBuffer(GL_FRONT);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
          //  glDrawBuffer(GL_FRONT);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
            
            glCopyPixels(0,0,size[0],size[1],GL_COLOR);
            reportGLErrorIfNeeded(__PRETTY_FUNCTION__,__LINE__);
        }
        else if(_hasReadback) {
            O2Surface *overlay=CGLGetSurface(_surfaces[i]);
        
            glPushMatrix();
            glTranslatef(0,0,1);
            glTranslatef((float)origin[0],(float)origin[1],0);
        
            [self flushSurface:overlay flip:NO textureId:allTextures[1+i]];
            glPopMatrix();
        }
    }
    
    glPopMatrix();
 
    glFinish();
    
    SwapBuffers(dc);
    
    for(i=0;i<_surfaceCount;i++)
        if(releasePbuffers[i]!=NULL){
            HPBUFFERARB CGLGetPBUFFER(CGLPBufferObj pbuffer);
            
            opengl_wglReleaseTexImageARB(CGLGetPBUFFER(releasePbuffers[i]),WGL_FRONT_LEFT_ARB);
            CGLReleasePBuffer(releasePbuffers[i]);
        }
        
    glDeleteTextures(1+_surfaceCount,allTextures);
        
    // restore previously set context
    CGLError _CGLSetCurrentContextFromThreadLocal(int);
    _CGLSetCurrentContextFromThreadLocal(1);

    ReleaseDC(_handle,dc);
}

-(void)updateLayeredWindow {
    O2Surface_DIBSection *surface=[self resultSurface];
    O2DeviceContext_gdi  *deviceContext=[surface deviceContext];
     
    BLENDFUNCTION blend;
    BYTE          constantAlpha=MAX(0,MIN(_alphaValue*255,255));
    
    blend.BlendOp=AC_SRC_OVER;
    blend.BlendFlags=0;
    blend.SourceConstantAlpha=constantAlpha;
    blend.AlphaFormat=AC_SRC_ALPHA;
    
    SIZE sizeWnd = {_frame.size.width, _frame.size.height};
    POINT ptSrc = {0, 0};
    DWORD flags=(_isOpaque && constantAlpha==255)?ULW_OPAQUE:ULW_ALPHA;
    
    UpdateLayeredWindow(_handle, NULL, NULL, &sizeWnd, [deviceContext dc], &ptSrc, 0, &blend, flags);
}

-(void)bitBltWindow {
    switch(_backingType){

        case CGSBackingStoreRetained:
        case CGSBackingStoreNonretained:
            break;
 
        case CGSBackingStoreBuffered:;
            O2Surface_DIBSection *surface=[self resultSurface];
            O2DeviceContext_gdi  *deviceContext=[surface deviceContext];
            int                  dstX=0;
            int                  dstY=0;
            int                  width=_frame.size.width;
            int                  height=_frame.size.height;
       
            CGFloat top,left,bottom,right;
       
            CGNativeBorderFrameWidthsForStyle([self styleMask],&top,&left,&bottom,&right);
    
            if(deviceContext!=nil){
                O2SurfaceLock(surface);
                BitBlt([_cgContext dc],0,0,width,height,[deviceContext dc],left,top,SRCCOPY);
                O2SurfaceUnlock(surface);
            }
            break;
        
    }
}

-(void)flushBuffer {
    [self lock];
   
    if(_disableFlushWindow){
        [self unlock];
        return;
    }

    if(_backingContext!=nil){
        if([self isLayeredWindow])
            [self updateLayeredWindow];
        else {
#if 1
            if(_surfaceCount>0)
                [self openGLFlushBuffer];
            else
#endif
                [self bitBltWindow];
        }
    }
    
    [self unlock];
}

-(CGPoint)convertPOINTLToBase:(POINTL)point {
   CGPoint result;

   result.x=point.x;
   result.y=point.y;
   result.y=GetSystemMetrics(SM_CYSCREEN)-result.y;

   return result;
}

-(CGPoint)mouseLocationOutsideOfEventStream {
   POINT   winPoint;

   GetCursorPos(&winPoint);

   return [self convertPOINTLToBase:winPoint];
}

-(void)adjustEventLocation:(CGPoint *)location {
   CGFloat top,left,bottom,right;
       
   CGNativeBorderFrameWidthsForStyle([self styleMask],&top,&left,&bottom,&right);
   location->x+=left;
   location->y+=top;
   
   location->y=(_frame.size.height-1)-location->y;
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

-(CGRect)queryFrame {
   RECT rect;
   
   if(GetWindowRect(_handle,&rect)==0){
    NSLog(@"GetWindowRect failed, handle=%p, %s %d",_handle,__FILE__,__LINE__);
    
    return CGRectMake(0,0,0,0);
   }
   
   return convertFrameFromWin32ScreenCoordinates(CGRectFromRECT(rect));
}

-(void)_GetWindowRectDidSize:(BOOL)didSize {
   CGRect frame=[self queryFrame];
   
    if(frame.size.width>0 && frame.size.height>0){
    [_delegate platformWindow:self frameChanged:frame didSize:didSize];
    }
}

-(int)WM_SIZE_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   CGSize contentSize={LOWORD(lParam),HIWORD(lParam)};

   if(contentSize.width>0 && contentSize.height>0){
       NSSize checkSize=[self queryFrame].size;
       
       if(NSEqualSizes(checkSize,_frame.size))
           return 0;
       
    [self invalidateContextsWithNewSize:checkSize];

    [self _GetWindowRectDidSize:YES];

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
   NSPoint checkOrigin=[self queryFrame].origin;
    
   if(NSEqualPoints(checkOrigin,_frame.origin))
    return 0;

    [_delegate platformWindowWillMove:self];
   [self _GetWindowRectDidSize:NO];
   [_delegate platformWindowDidMove:self];

   return 0;
}

-(int)WM_PAINT_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {    
   PAINTSTRUCT paintStruct;
   RECT        updateRECT;
//   CGRect      displayRect;

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
   RECT   rect=*(RECT *)lParam;
   CGSize size=NSMakeSize(rect.right-rect.left,rect.bottom-rect.top);

   if(!_sentBeginSizing){
    [_delegate platformWindowWillBeginSizing:self];
   }
   
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

   *(RECT *)lParam=rect;

   return 0;
}

-(int)WM_GETMINMAXINFO_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {
   MINMAXINFO *info=(MINMAXINFO *)lParam;

   if(_ignoreMinMaxMessage)
    return 0;

   info->ptMaxTrackSize.x=10000;
   info->ptMaxTrackSize.y=10000;

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
   
   if(_sentBeginSizing){
    [_delegate platformWindowDidEndSizing:self];
   }
   
   [_delegate platformWindowExitMove:self];

   _sentBeginSizing=NO;

   return 0;
}

-(int)WM_SYSCOMMAND_wParam:(WPARAM)wParam lParam:(LPARAM)lParam {

    switch(wParam&0xFFF0){
   
        case SC_MAXIMIZE:
            [_delegate platformWindowShouldZoom:self];
            return 0;
        
        case SC_MINIMIZE:
            _isMiniaturized=YES;
            return DefWindowProc(_handle,WM_SYSCOMMAND,wParam,lParam);
            
        case SC_RESTORE:
            _isMiniaturized=NO;
            return DefWindowProc(_handle,WM_SYSCOMMAND,wParam,lParam);
            
        default:
            return DefWindowProc(_handle,WM_SYSCOMMAND,wParam,lParam);
   }
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
    case WM_SYSCOMMAND:    return [self WM_SYSCOMMAND_wParam:wParam lParam:lParam];
    case WM_SYSCOLORCHANGE:
     [[Win32Display currentDisplay] invalidateSystemColors];
     [_delegate platformWindowStyleChanged:self];
     return 0;
    
    // This can avoid OpenGL flickering
    case WM_ERASEBKGND: return 1;

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
   Win32Window       *self=GetProp(handle,"Win32Window");
   LRESULT            result;

   if(self==nil)
    result=DefWindowProc(handle,message,wParam,lParam);
   else
    result=[self windowProcedure:message wParam:wParam lParam:lParam];

   [pool release];

   return result;
}

static void initializeWindowClass(WNDCLASS *class){
/* WS_EX_LAYERED windows can not use CS_OWNDC or CS_CLASSDC */
/* OpenGL windows want CS_OWNDC, so don't use OpenGL on a top level window */
   class->style=CS_HREDRAW|CS_VREDRAW|CS_DBLCLKS;
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
	NSString *name=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];
    NSString *path=[[NSBundle mainBundle] pathForResource:name ofType:@"ico"];
    HICON     icon=(path==nil)?NULL:LoadImage(NULL,[path fileSystemRepresentation],IMAGE_ICON,16,16,LR_DEFAULTCOLOR|LR_LOADFROMFILE);

    static WNDCLASS _standardWindowClass,_borderlessWindowClass,_borderlessWindowClassWithShadow;

    if(icon==NULL)
     icon=LoadImage(NULL,IDI_APPLICATION,IMAGE_ICON,0,0,LR_DEFAULTCOLOR|LR_SHARED);

    initializeWindowClass(&_standardWindowClass);
    initializeWindowClass(&_borderlessWindowClass);
    initializeWindowClass(&_borderlessWindowClassWithShadow);

    _standardWindowClass.lpszClassName="NSWin32StandardWindow";
    _standardWindowClass.hIcon=icon;
    
    _borderlessWindowClass.lpszClassName="Win32BorderlessWindow";
    
    _borderlessWindowClassWithShadow.lpszClassName="Win32BorderlessWindowWithShadow";
    
    if(NSPlatformGreaterThanOrEqualToWindowsXP())
     _borderlessWindowClassWithShadow.style|=CS_DROPSHADOW;
        
    if(RegisterClass(&_standardWindowClass)==0)
     NSLog(@"RegisterClass failed");

    if(RegisterClass(&_borderlessWindowClass)==0)
     NSLog(@"RegisterClass failed");
     
    if(RegisterClass(&_borderlessWindowClassWithShadow)==0)
     NSLog(@"RegisterClass failed");
   }
}

-(void)addCGLContext:(CGLContextObj)cglContext {
    [self lock];
    _surfaceCount++;
    _surfaces=NSZoneRealloc(NULL,_surfaces,sizeof(void *)*_surfaceCount);
    _surfaces[_surfaceCount-1]=cglContext;
    [self unlock];
}

-(void)removeCGLContext:(CGLContextObj)cglContext {
    int i;
    
    [self lock];
    for(i=0;i<_surfaceCount;i++)
        if(_surfaces[i]==cglContext){
            _surfaceCount--;
            break;
        }
    
    for(;i<_surfaceCount;i++)
        _surfaces[i]=_surfaces[i+1];

    [self unlock];
}

@end
