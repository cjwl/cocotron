/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSWindow.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSWindowBackgroundView.h>
#import <AppKit/NSMainMenuView.h>
#import <AppKit/NSSheetContext.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSEvent_CoreGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/CGWindow.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSView.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSDraggingManager.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSCursorRect.h>
#import <AppKit/NSTrackingRect.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSWindowAnimationContext.h>
#import <AppKit/NSToolTipWindow.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSRaise.h>

NSString *NSWindowDidBecomeKeyNotification=@"NSWindowDidBecomeKeyNotification";
NSString *NSWindowDidResignKeyNotification=@"NSWindowDidResignKeyNotification";
NSString *NSWindowDidBecomeMainNotification=@"NSWindowDidBecomeMainNotification";
NSString *NSWindowDidResignMainNotification=@"NSWindowDidResignMainNotification";
NSString *NSWindowWillMiniaturizeNotification=@"NSWindowWillMiniaturizeNotification";
NSString *NSWindowDidMiniaturizeNotification=@"NSWindowDidMiniaturizeNotification";
NSString *NSWindowDidDeminiaturizeNotification=@"NSWindowDidDeminiaturizeNotification";
NSString *NSWindowDidMoveNotification=@"NSWindowDidMoveNotification";
NSString *NSWindowDidResizeNotification=@"NSWindowDidResizeNotification";
NSString *NSWindowDidUpdateNotification=@"NSWindowDidUpdateNotification";
NSString *NSWindowWillCloseNotification=@"NSWindowWillCloseNotification";
NSString *NSWindowWillMoveNotification=@"NSWindowWillMoveNotification";

NSString *NSWindowWillAnimateNotification=@"NSWindowWillAnimateNotification";
NSString *NSWindowAnimatingNotification=@"NSWindowAnimatingNotification";
NSString *NSWindowDidAnimateNotification=@"NSWindowDidAnimateNotification";


@interface NSToolbar (NSToolbar_privateForWindow)
- (void)_setWindow:(NSWindow *)window;
- (NSView *)_view;
-(CGFloat)visibleHeight;
-(void)layoutFrameSizeWithWidth:(CGFloat)width;
@end

@implementation NSWindow

+(NSWindowDepth)defaultDepthLimit {
   return 0;
}

+(NSRect)frameRectForContentRect:(NSRect)contentRect styleMask:(unsigned)styleMask {
   if(styleMask!=0)
    contentRect.size.height+=[NSMainMenuView menuHeight];
   return contentRect;
}

+(NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(unsigned)styleMask {
   if(styleMask!=0)
    frameRect.size.height-=[NSMainMenuView menuHeight];
   return frameRect;
}

+(float)minFrameWidthWithTitle:(NSString *)title styleMask:(unsigned)styleMask {
   NSUnimplementedMethod();
   return 0;
}

+(void)removeFrameUsingName:(NSString *)name {
   NSUnimplementedMethod();
}

+(NSButton *)standardWindowButton:(NSWindowButton)button forStyleMask:(unsigned)styleMask {
   NSUnimplementedMethod();
   return nil;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
  [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   return self;
}

-initWithContentRect:(NSRect)contentRect styleMask:(unsigned)styleMask backing:(unsigned)backing defer:(BOOL)defer {
   NSRect backgroundFrame={{0,0},contentRect.size};
   NSRect contentViewFrame={{0,0},contentRect.size};

   _frame=[[self class] frameRectForContentRect:contentRect styleMask:styleMask];

   _styleMask=styleMask;
   _backingType=backing;

   _minSize=NSMakeSize(0,0);
   _maxSize=NSMakeSize(0,0);

   _title=@"";
   _miniwindowTitle=@"";

   _menu=nil;
   if(![self isKindOfClass:[NSPanel class]] && styleMask>0){
    NSRect frame=NSMakeRect(0,contentRect.size.height,contentRect.size.width,[NSMainMenuView menuHeight]);

    _menu=[[NSApp mainMenu] copy];

    _menuView=[[NSMainMenuView alloc] initWithFrame:frame menu:_menu];
    [_menuView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];

    backgroundFrame.size.height+=[_menuView frame].size.height;
   }

   _backgroundView=[[NSWindowBackgroundView alloc] initWithFrame:backgroundFrame];
   [_backgroundView setAutoresizesSubviews:YES];
   [_backgroundView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
   [_backgroundView _setWindow:self];
   [_backgroundView setNextResponder:self];

   _contentView=[[NSView alloc] initWithFrame:contentViewFrame];
   [_contentView setAutoresizesSubviews:YES];
   [_contentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

   _backgroundColor=[[NSColor windowBackgroundColor] copy];

   _delegate=nil;
   _firstResponder=self;
   _fieldEditor=nil;
   _draggedTypes=nil;

   _cursorRects=[NSMutableArray new];
   _invalidatedCursorRectViews=
              NSCreateHashTable(NSNonOwnedPointerHashCallBacks,0);

   _trackingRects=[NSMutableArray new];
   _nextTrackingRectTag=1;

   _sheetContext=nil;

   _isVisible=NO;
   _isDocumentEdited=NO;

   _makeSureIsOnAScreen=YES;
   _excludedFromWindowsMenu=NO;

   _acceptsMouseMovedEvents=NO;
   _excludedFromWindowsMenu=NO;
   _isDeferred=defer;
   _isOneShot=NO;
   _useOptimizedDrawing=NO;
   _releaseWhenClosed=YES;
   _hidesOnDeactivate=NO;
   _viewsNeedDisplay=YES;
   _flushNeeded=YES;

   _autosaveFrameName=nil;

   _platformWindow=nil;

   if(_menuView!=nil)
    [_backgroundView addSubview:_menuView];

   [_backgroundView addSubview:_contentView];

   [[NSApplication sharedApplication] _addWindow:self];

   return self;
}

-initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(unsigned)backing defer:(BOOL)defer screen:(NSScreen *)screen {
// FIX, relocate contentRect
   return [self initWithContentRect:contentRect styleMask:styleMask backing:backing defer:defer];
}

-(void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   
   [_title release];
   [_miniwindowTitle release];
   [_miniwindowImage release];
   [_backgroundView _setWindow:nil];
   [_backgroundView release];
   [_menu release];
   [_menuView release];
   [_contentView release];
   [_backgroundColor release];
   [_fieldEditor release];
   [_draggedTypes release];
   [_cursorRects release];
   NSFreeHashTable(_invalidatedCursorRectViews);
   [_trackingRects release];
   [_autosaveFrameName release];
   [_platformWindow invalidate];
   [_platformWindow release];
   _platformWindow=nil;
   [_undoManager release];
   [super dealloc];
}

-(void)_updatePlatformWindowTitle {
   NSString *title;

   if([self isMiniaturized])
    title=[self miniwindowTitle];
   else
    title=[self title];

   if(_isDocumentEdited)
    title=[@"* " stringByAppendingString:title];

   [_platformWindow setTitle:title];
}

-(CGWindow *)platformWindow {
   if(_platformWindow==nil){
    if([self isKindOfClass:[NSPanel class]])
     _platformWindow=[[[NSDisplay currentDisplay] panelWithFrame: _frame styleMask:_styleMask backingType:_backingType] retain];
    else
     _platformWindow=[[[NSDisplay currentDisplay] windowWithFrame: _frame styleMask:_styleMask backingType:_backingType] retain];

    [_platformWindow setDelegate:self];

    [self _updatePlatformWindowTitle];

    [[NSDraggingManager draggingManager] registerWindow:self dragTypes:nil];
   }

   return _platformWindow;
}

-(CGContextRef)cgContext {
   return [[self platformWindow] cgContext];
}

-(void)_setStyleMask:(unsigned)mask
{
    if (_platformWindow == nil)
        _styleMask = mask;
    else
        [NSException raise:NSInternalInconsistencyException format:@"-[NSWindow _setStyleMask:] platformWindow already created, cannot change style mask"];
}

-(void)postNotificationName:(NSString *)name {
   [[NSNotificationCenter defaultCenter] postNotificationName:name
     object:self];
}

-(NSGraphicsContext *)graphicsContext { 
   return [NSGraphicsContext graphicsContextWithWindow:self]; 
} 

-(NSDictionary *)deviceDescription {
   NSValue *resolution=[NSValue valueWithSize:NSMakeSize(72.0,72.0)];
   NSValue *size=[NSValue valueWithSize:[self frame].size];
   
   return [NSDictionary dictionaryWithObjectsAndKeys:
    resolution,NSDeviceResolution,
    NSDeviceRGBColorSpace,NSDeviceColorSpaceName,
    [NSNumber numberWithInt:8],NSDeviceBitsPerSample,
    [NSNumber numberWithBool:YES],NSDeviceIsScreen,
    size,NSDeviceSize,
    nil];
}

-contentView {
   return _contentView;
}

-delegate {
   return _delegate;
}

-(NSString *)title {
   return _title;
}

-(NSString *)representedFilename {
   return _representedFilename;
}

-(int)level {
   return _level;
}

-(NSRect)frame {
   return _frame;
}

-(unsigned)styleMask {
   return _styleMask;
}

-(NSBackingStoreType)backingType {
   return _backingType;
}

-(NSSize)minSize {
   return _minSize;
}

-(NSSize)maxSize {
   return _maxSize;
}

-(NSSize)contentMinSize {
   return _contentMinSize;
}

-(NSSize)contentMaxSize {
   return _contentMaxSize;
}

-(BOOL)isOneShot {
   return _isOneShot;
}

-(BOOL)isOpaque {
   return _isOpaque;
}

-(BOOL)hasDynamicDepthLimit {
   return _dynamicDepthLimit;
}

-(BOOL)isReleasedWhenClosed {
   return _releaseWhenClosed;
}

-(BOOL)hidesOnDeactivate {
   return _hidesOnDeactivate;
}

-(BOOL)worksWhenModal {
   return NO;
}

-(BOOL)isSheet {
  return (_styleMask&NSDocModalWindowMask)?YES:NO;
}

-(BOOL)acceptsMouseMovedEvents {
   return _acceptsMouseMovedEvents;
}

-(BOOL)isExcludedFromWindowsMenu {
   return _excludedFromWindowsMenu;
}

-(BOOL)isAutodisplay {
   return _isAutodisplay;
}

-(BOOL)isFlushWindowDisabled {
   return _isFlushWindowDisabled;
}

-(NSString *)frameAutosaveName {
   return _autosaveFrameName;
}

-(BOOL)hasShadow {
   return _hasShadow;
}

-(BOOL)ignoresMouseEvents {
   return _ignoresMouseEvents;
}

-(NSSize)aspectRatio {
   return _aspectRatio;
}

-(NSSize)contentAspectRatio {
   return _contentAspectRatio;
}

-(BOOL)autorecalculatesKeyViewLoop {
   return _autorecalculatesKeyViewLoop;
}

-(BOOL)canHide {
   return _canHide;
}

-(BOOL)canStoreColor {
   return _canStoreColor;
}

-(BOOL)showsResizeIndicator {
   return _showsResizeIndicator;
}

-(BOOL)showsToolbarButton {
   return _showsToolbarButton;
}

-(BOOL)displaysWhenScreenProfileChanges {
   return _displaysWhenScreenProfileChanges;
}

-(BOOL)isMovableByWindowBackground {
   return _isMovableByWindowBackground;
}

-(BOOL)allowsToolTipsWhenApplicationIsInactive {
   return _allowsToolTipsWhenApplicationIsInactive;
}

-(NSImage *)miniwindowImage {
   return _miniwindowImage;
}

-(NSString *)miniwindowTitle {
   return _miniwindowTitle;
}

-(NSColor *)backgroundColor {
   return _backgroundColor;
}

-(float)alphaValue {
   return _alphaValue;
}

-(NSWindowDepth)depthLimit {
   return 0;
}

-(NSSize)resizeIncrements {
   return _resizeIncrements;
}

-(NSSize)contentResizeIncrements {
   return _contentResizeIncrements;
}

-(BOOL)preservesContentDuringLiveResize {
   return _preservesContentDuringLiveResize;
}

-(NSToolbar *)toolbar {
    return _toolbar;
}

-(NSView *)initialFirstResponder {
   return _initialFirstResponder;
}

-(void)removeObserver:(NSString *)name selector:(SEL)selector {
    if([_delegate respondsToSelector:selector]){
     [[NSNotificationCenter defaultCenter] removeObserver:_delegate
       name:name object:self];
    }
}

-(void)addObserver:(NSString *)name selector:(SEL)selector {
    if([_delegate respondsToSelector:selector]){
     [[NSNotificationCenter defaultCenter] addObserver:_delegate
       selector:selector name:name object:self];
    }
}

-(void)setDelegate:delegate {
   struct {
    NSString *name;
    SEL       selector;
   } notes[]={
    { NSWindowDidBecomeKeyNotification,@selector(windowDidBecomeKey:) },
    { NSWindowDidBecomeMainNotification,@selector(windowDidBecomeMain:) },
    { NSWindowDidDeminiaturizeNotification,@selector(windowDidDeminiaturize:) },
    { NSWindowDidMiniaturizeNotification,@selector(windowDidMiniaturize:) },
    { NSWindowDidMoveNotification,@selector(windowDidMove:) },
    { NSWindowDidResignKeyNotification,@selector(windowDidResignKey:) },
    { NSWindowDidResignMainNotification,@selector(windowDidResignMain:) },
    { NSWindowDidResizeNotification,@selector(windowDidResize:) },
    { NSWindowDidUpdateNotification,@selector(windowDidUpdate:) },
    { NSWindowWillCloseNotification,@selector(windowWillClose:) },
    { NSWindowWillMiniaturizeNotification,@selector(windowWillMiniaturize:) },
    { NSWindowWillMoveNotification,@selector(windowWillMove:) },
    { nil, NULL }
   };
   int i;

   if(_delegate!=nil)
    for(i=0;notes[i].name!=nil;i++)
     [self removeObserver:notes[i].name selector:notes[i].selector];

   _delegate=delegate;

   for(i=0;notes[i].name!=nil;i++)
    [self addObserver:notes[i].name selector:notes[i].selector];
}

-(void)_makeSureIsOnAScreen {
#if 1
   if(_makeSureIsOnAScreen && [self isVisible] && ![self isMiniaturized]){
    NSRect   frame=_frame;
    NSArray *screens=[NSScreen screens];
    int      i,count=[screens count];
    NSRect   virtual=NSZeroRect;
    BOOL     changed=NO;

    BOOL     tooFarLeft=YES,tooFarRight=YES,tooFarUp=YES,tooFarDown=YES;
    float    leastX=0,maxX=0,leastY=0,maxY=0;

    for(i=0;i<count;i++){
     NSRect check=[[screens objectAtIndex:i] frame];

     if(NSMaxX(frame)>check.origin.x+20)
      tooFarLeft=NO;
     if(frame.origin.x<NSMaxX(check)-20)
      tooFarRight=NO;
     if(frame.origin.y<NSMaxY(check)-20)
      tooFarUp=NO;
     if(NSMaxY(frame)>check.origin.y+20)
      tooFarDown=NO;

     if(check.origin.x<leastX)
      leastX=check.origin.x;
     if(check.origin.y<leastY)
      leastY=check.origin.y;
     if(NSMaxX(check)>maxX)
      maxX=NSMaxX(check);
     if(NSMaxY(check)>maxY)
      maxY=NSMaxY(check);
    }

    if(tooFarLeft){
     frame.origin.x=(leastX+20)-frame.size.width;
     changed=YES;
    }
    if(tooFarRight){
     frame.origin.x=maxX-20;
     changed=YES;
    }
    if(tooFarUp){
     frame.origin.y=(maxY-20)-frame.size.height;
     changed=YES;
    }
    if(tooFarDown){
     changed=YES;
     frame.origin.y=(leastY+20)-frame.size.height;
    }

    if(changed)
     [self setFrame:frame display:YES];

    _makeSureIsOnAScreen=NO;
   }
#else
   if(_makeSureIsOnAScreen && [self isVisible] && ![self isMiniaturized]){
    NSRect   frame=_frame;
    NSArray *screens=[NSScreen screens];
    int      i,count=[screens count];
    NSRect   virtual=NSZeroRect;
    BOOL     changed=NO;

    for(i=0;i<count;i++){
     NSRect screen=[[screens objectAtIndex:i] frame];

     virtual=NSUnionRect(virtual,screen);
    }

    virtual=NSInsetRect(virtual,20,20);

    if(NSMaxX(frame)<virtual.origin.x){
     frame.origin.x=virtual.origin.x-frame.size.width;
     changed=YES;
    }
    if(frame.origin.x>NSMaxX(virtual)){
     frame.origin.x=NSMaxX(virtual);
     changed=YES;
    }

    if(NSMaxY(frame)>NSMaxY(virtual)){
     frame.origin.y=NSMaxY(virtual)-frame.size.height;
     changed=YES;
    }
    if(NSMaxY(frame)<virtual.origin.y){
     changed=YES;
     frame.origin.y=virtual.origin.y-frame.size.height;
    }

    if(changed)
     [self setFrame:frame display:YES];

    _makeSureIsOnAScreen=NO;
   }
#endif
}

-(void)setFrame:(NSRect)frame display:(BOOL)display {
   _frame=frame;
   _makeSureIsOnAScreen=YES;

   [_backgroundView setFrameSize:_frame.size];
   [[self platformWindow] setFrame:_frame];

   [self resetCursorRects];

   if(display)
    [self display];
}

- (void)_animateWithContext:(NSWindowAnimationContext *)context
{
    NSRect frame = [self frame];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:context, @"NSWindowAnimationContext", nil];
    
    if (_animationContext == nil)
        _animationContext = [context retain];
    
    if (_animationContext != context) 
        [NSException raise:NSInvalidArgumentException
                    format:@"-[%@ %@]: attempt to animate frame while animation still in progress",
            [self class], NSStringFromSelector(_cmd)];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillAnimateNotification object:self userInfo:userInfo];
    
    [context decrement];
    
    if ([context stepCount] > 0) {
        frame.origin.x += [context stepRect].origin.x;
        frame.origin.y += [context stepRect].origin.y;
        frame.size.width += [context stepRect].size.width;
        frame.size.height += [context stepRect].size.height;
    }
    else
        frame = [context targetRect];
    
    [self setFrame:frame display:[context display]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowAnimatingNotification object:self userInfo:userInfo];
    
    if ([context stepCount] > 0) {
        [self performSelector:_cmd withObject:context afterDelay:[context stepInterval]];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidAnimateNotification object:self userInfo:userInfo];
        
        [_animationContext release];
        _animationContext = nil;
#if 0
        if ([_backgroundView cachesImageForAnimation])
            [_backgroundView invalidateCachedImage];
#endif
    }
}

- (NSWindowAnimationContext *)_animationContext
{
    return _animationContext;
}

-(void)setFrame:(NSRect)newFrame display:(BOOL)display animate:(BOOL)animate 
{
    NSWindowAnimationContext *context;
    
    // no fun at all!
    if (animate == NO) {
        [self setFrame:newFrame display:display];
        return;
    }

    context = [NSWindowAnimationContext contextToTransformWindow:self startRect:[self frame] targetRect:newFrame resizeTime:[self animationResizeTime:newFrame] display:display];

// FIX
#if 0
    [_backgroundView setCachesImageForAnimation:NO];    // re-enable
    if ([_backgroundView cachedImageIsValid] == NO)
        [_backgroundView cacheImageForAnimation];
#endif

    [self _animateWithContext:context];
}

-(void)setContentSize:(NSSize)size {
   NSRect frame,content=[[self class] contentRectForFrameRect:[self frame] styleMask:_styleMask];

   content.size=size;

   frame=[[self class] frameRectForContentRect:content styleMask:_styleMask];

   [self setFrame:frame display:YES];
}

-(void)setFrameOrigin:(NSPoint)point {
   NSRect frame=[self frame];

   frame.origin=point;
   [self setFrame:frame display:YES];
}

-(void)setFrameTopLeftPoint:(NSPoint)point {
   NSRect frame=[self frame];

   frame.origin.x=point.x;
   frame.origin.y=point.y-frame.size.height;
   [self setFrame:frame display:YES];
}

-(void)setMinSize:(NSSize)size {
   _minSize=size;
}

-(void)setMaxSize:(NSSize)size {
   _maxSize=size;
}

-(void)setContentMinSize:(NSSize)value {
   _contentMinSize=value;
   NSUnimplementedMethod();
}

-(void)setContentMaxSize:(NSSize)value {
   _contentMaxSize=value;
   NSUnimplementedMethod();
}

-(void)setBackingType:(NSBackingStoreType)value {
   _backingType=value;
   NSUnimplementedMethod();
}

-(void)setDynamicDepthLimit:(BOOL)value {
   _dynamicDepthLimit=value;
}

-(void)setOneShot:(BOOL)flag {
   _isOneShot=flag;
}

-(void)setReleasedWhenClosed:(BOOL)flag {
   _releaseWhenClosed=flag;
}

-(void)setHidesOnDeactivate:(BOOL)flag {
   _hidesOnDeactivate=flag;
}

-(void)setAcceptsMouseMovedEvents:(BOOL)flag {
   _acceptsMouseMovedEvents=flag;
}

-(void)setExcludedFromWindowsMenu:(BOOL)value {
   _excludedFromWindowsMenu=value;
}

-(void)setAutodisplay:(BOOL)value {
   _isAutodisplay=value;
}

-(void)setTitle:(NSString *)title {
   title=[title copy];
   [_title release];
   _title=title;

   [_miniwindowTitle release];
   _miniwindowTitle=[title copy];

   [self _updatePlatformWindowTitle];

   if (![self isKindOfClass:[NSPanel class]] && [self isVisible] && ![self isExcludedFromWindowsMenu])
       [NSApp changeWindowsItem:self title:title filename:NO];
}

-(void)setTitleWithRepresentedFilename:(NSString *)filename {
   [self setTitle:[NSString stringWithFormat:@"%@  --  %@",
      [filename lastPathComponent],
      [filename stringByDeletingLastPathComponent]]];

    if (![self isKindOfClass:[NSPanel class]] && [self isVisible] && ![self isExcludedFromWindowsMenu])
        [NSApp changeWindowsItem:self title:filename filename:YES];
}

-(void)setContentView:(NSView *)view {
   view=[view retain];
   [view setFrame:[_contentView frame]];

   [_contentView removeFromSuperview];
   [_contentView release];
   
   _contentView=view;

   [_backgroundView addSubview:_contentView];
}

-(void)setInitialFirstResponder:(NSView *)view {
    _initialFirstResponder = view;
}

-(void)setMiniwindowImage:(NSImage *)image {
   image=[image retain];
   [_miniwindowImage release];
   _miniwindowImage=image;
}

-(void)setMiniwindowTitle:(NSString *)title {
   title=[title copy];
   [_miniwindowTitle release];
   _miniwindowTitle=title;

   [self _updatePlatformWindowTitle];
}

-(void)setBackgroundColor:(NSColor *)color {
   color=[color copy];
   [_backgroundColor release];
   _backgroundColor=color;
}

-(void)setAlphaValue:(float)value {
   _alphaValue=value;
   NSUnimplementedMethod();
}

-(void)_toolbarSizeDidChangeFromOldHeight:(CGFloat)oldHeight {
   CGFloat    newHeight,contentHeightDelta;
   NSView    *toolbarView=[_toolbar _view];
   NSUInteger mask=[[self contentView] autoresizingMask];
   NSRect     frame=[self frame];
   
   [_toolbar layoutFrameSizeWithWidth:NSWidth([[self _backgroundView] bounds])];
   newHeight=(_toolbar==nil)?0:[_toolbar visibleHeight];
   contentHeightDelta=newHeight-oldHeight;

   frame.size.height+=contentHeightDelta;
   frame.origin.y-=contentHeightDelta;
   
   NSPoint toolbarOrigin;
   NSRect backgroundBounds=[self _backgroundView].bounds;
   toolbarOrigin.x=backgroundBounds.origin.x;
   toolbarOrigin.y=NSMaxY([[self contentView] frame])-contentHeightDelta;
   [toolbarView setFrameOrigin:toolbarOrigin];

   [[self contentView] setAutoresizingMask:NSViewNotSizable];
   [self setFrame:frame display:NO animate:NO];
   
   [[self contentView] setAutoresizingMask:mask];
}

-(void)setToolbar:(NSToolbar *)toolbar {
   if(toolbar!=_toolbar){
    CGFloat oldHeight=0;
   
    toolbar=[toolbar retain];
   
    if(_toolbar!=nil){
     oldHeight=[_toolbar visibleHeight];
     [_toolbar _setWindow:nil];
     [[_toolbar _view] removeFromSuperview];
     [_toolbar release];
    }
   
    _toolbar = toolbar;
   
    if(_toolbar!=nil){
     [_toolbar _setWindow:self];
     [[self _backgroundView] addSubview:[_toolbar _view]];
    }
   
    [self _toolbarSizeDidChangeFromOldHeight:oldHeight];
   }
}

- (void)setDefaultButtonCell:(NSButtonCell *)buttonCell {
    [_defaultButtonCell autorelease];
    _defaultButtonCell = [buttonCell retain];
    [_defaultButtonCell setKeyEquivalent:@"\r"];
    [[_defaultButtonCell controlView] setNeedsDisplay:YES];
}

-(void)setWindowController:(NSWindowController *)value {
   _windowController=value;
}

-(void)setDocumentEdited:(BOOL)flag {
   _isDocumentEdited=flag;
   [self _updatePlatformWindowTitle];
}

-(void)setContentAspectRatio:(NSSize)value {
   _useAspectRatio=YES;
   _aspectRatioIsContent=YES;
   _aspectRatio=value;
   NSUnimplementedMethod();
}

-(void)setHasShadow:(BOOL)value {
   _hasShadow=value;
   NSUnimplementedMethod();
}

-(void)setIgnoresMouseEvents:(BOOL)value {
   _ignoresMouseEvents=value;
}

-(void)setAspectRatio:(NSSize)value {
   _useAspectRatio=YES;
   _aspectRatioIsContent=NO;
   _aspectRatio=value;
   NSUnimplementedMethod();
}

-(void)setAutorecalculatesKeyViewLoop:(BOOL)value {
   _autorecalculatesKeyViewLoop=value;
}

-(void)setCanHide:(BOOL)value {
   _canHide=value;
}

-(void)setLevel:(int)value {
   _level=value;
   NSUnimplementedMethod();
}

-(void)setOpaque:(BOOL)value {
   _isOpaque=value;
}

-(void)setParentWindow:(NSWindow *)value {
   _parentWindow=value;
}

-(void)setPreservesContentDuringLiveResize:(BOOL)value {
   _preservesContentDuringLiveResize=value;
}

-(void)setRepresentedFilename:(NSString *)value {
   value=[value copy];
   [_representedFilename release];
   _representedFilename=value;
}

-(void)setResizeIncrements:(NSSize)value {
   _resizeIncrements=value;
}

-(void)setShowsResizeIndicator:(BOOL)value {
   _showsResizeIndicator=value;
   NSUnimplementedMethod();
}

-(void)setShowsToolbarButton:(BOOL)value {
  _showsToolbarButton=value;
   NSUnimplementedMethod();
}

-(void)setContentResizeIncrements:(NSSize)value {
   _contentResizeIncrements=value;
}

-(void)setDepthLimit:(NSWindowDepth)value {
   NSUnimplementedMethod();
}

-(void)setDisplaysWhenScreenProfileChanges:(BOOL)value {
   _displaysWhenScreenProfileChanges=value;
}

-(void)setMovableByWindowBackground:(BOOL)value {
   _isMovableByWindowBackground=value;
}

-(void)setAllowsToolTipsWhenApplicationIsInactive:(BOOL)value {
   _allowsToolTipsWhenApplicationIsInactive=value;
}

-(NSString *)_autosaveFrameKeyWithName:(NSString *)name {
   return [NSString stringWithFormat:@"NSWindow frame %@ %@",name, NSStringFromRect([[self screen] frame])];
}

-(BOOL)setFrameUsingName:(NSString *)name {
   return [self setFrameUsingName:name force:NO];
}

-(BOOL)setFrameUsingName:(NSString *)name force:(BOOL)force {
   NSString *key=[self _autosaveFrameKeyWithName:name];
   NSString *value=[[NSUserDefaults standardUserDefaults] objectForKey:key];
   
   if([value length]==0)
    return NO;
    
   [self setFrameFromString:value];

   return YES;
}

-(BOOL)setFrameAutosaveName:(NSString *)name {
   name=[name copy];
   [_autosaveFrameName release];
   _autosaveFrameName=name;
   // check if this name is in use by any other windows
   [self saveFrameUsingName:_autosaveFrameName];
   return YES;
}

-(void)saveFrameUsingName:(NSString *)name {
   if([name length]>0){
    NSString *key=[self _autosaveFrameKeyWithName:name];
    NSString *value=[self stringWithSavedFrame];
    
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
   }
}

-(void)setFrameFromString:(NSString *)value {
   NSRect rect=NSRectFromString(value);

   if(!NSIsEmptyRect(rect)){   
    [self setFrame:rect display:YES];
   }
}

-(NSString *)stringWithSavedFrame {
   return NSStringFromRect([self frame]);
}

-(int)resizeFlags {
   NSUnimplementedMethod();
   return 0;
}

-(float)userSpaceScaleFactor {
   return 1.0;
}

-(NSResponder *)firstResponder {
   return _firstResponder;
}

-(NSButton *)standardWindowButton:(NSWindowButton)value {
   NSUnimplementedMethod();
   return nil;
}

-(NSButtonCell *)defaultButtonCell {
    return _defaultButtonCell;
}

-(NSWindow *)attachedSheet {
   return [_sheetContext sheet];
}

-(NSWindowController *)windowController {
   return _windowController;
}

-(NSArray *)drawers {
    return _drawers;
}

-(int)windowNumber {
   return (int)self;
}

-(int)gState {
   NSUnimplementedMethod();
   return 0;
}

-(NSScreen *)screen {
   NSArray  *screens=[NSScreen screens];
   int       i,count=[screens count];
   NSRect    mostRect=NSZeroRect;
   NSScreen *mostScreen=nil;

   for(i=0;i<count;i++){
    NSScreen *check=[screens objectAtIndex:i];
    NSRect    intersect=NSIntersectionRect([check frame],_frame);

    if(intersect.size.width*intersect.size.height>mostRect.size.width*mostRect.size.height){
     mostRect=intersect;
     mostScreen=check;
    }
   }

   return mostScreen;
}

-(NSScreen *)deepestScreen {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isDocumentEdited {
   return _isDocumentEdited;
}

-(BOOL)isZoomed {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isVisible {
   return _isVisible;
}

-(BOOL)isKeyWindow {
   return _isKeyWindow;
}

-(BOOL)isMainWindow {
   return _isMainWindow;
}

-(BOOL)isMiniaturized {
   return [_platformWindow isMiniaturized];
}

-(BOOL)canBecomeKeyWindow {
   return YES;
}

-(BOOL)canBecomeMainWindow {
   return YES;
}

-(NSPoint)convertBaseToScreen:(NSPoint)point {
   NSRect frame=[self frame];

   point.x+=frame.origin.x;
   point.y+=frame.origin.y;

   return point;
}

-(NSPoint)convertScreenToBase:(NSPoint)point {
   NSRect frame=[self frame];

   point.x-=frame.origin.x;
   point.y-=frame.origin.y;

   return point;
}

-(NSRect)frameRectForContentRect:(NSRect)rect {
   return [isa frameRectForContentRect:rect styleMask:[self styleMask]];
}

-(NSRect)contentRectForFrameRect:(NSRect)rect {
   return [isa contentRectForFrameRect:rect styleMask:[self styleMask]];
}

-(NSRect)constrainFrameRect:(NSRect)rect toScreen:(NSScreen *)screen {
   NSUnimplementedMethod();
   return NSMakeRect(0,0,0,0);
}

-(NSWindow *)parentWindow {
   return _parentWindow;
}

-(NSArray *)childWindows {
   return _childWindows;
}

-(void)addChildWindow:(NSWindow *)child ordered:(NSWindowOrderingMode)ordered {
   NSUnimplementedMethod();
}

-(void)removeChildWindow:(NSWindow *)child {
   NSUnimplementedMethod();
}

-(BOOL)acceptsFirstResponder {
   return YES;
}

-(BOOL)makeFirstResponder:(NSResponder *)responder {
   NSResponder *previous=_firstResponder;

   if(responder==nil)
    responder=self;

   if(_firstResponder==responder)
    return YES;

   if(![responder acceptsFirstResponder])
    return NO;

/* the firstResponder needs to be set here because
   resignFirstResponder may nest makeFirstResponder's e.g. 
     field editor <tab>
     makeFirstResponder:[self window]
      field editor resignFirstResponder
       textDidEnd:
        field editor assigned to nextKeyView
         makeFirstResponder:field editor  */
   _firstResponder=responder;

   if(previous!=nil){
    if(![previous resignFirstResponder]){
     _firstResponder=previous;
     return NO;
    }
   }

   if([_firstResponder becomeFirstResponder])
    return YES;

   _firstResponder=self;
   return NO;
}

-(void)makeKeyWindow {
   [[self platformWindow] makeKey];
    [self makeFirstResponder:[self initialFirstResponder]];
}

-(void)makeMainWindow {
   [self becomeMainWindow];
}

-(void)becomeKeyWindow {
   [[NSApp keyWindow] resignKeyWindow];
   _isKeyWindow=YES;

   if(_firstResponder!=self && [_firstResponder respondsToSelector:_cmd])
    [_firstResponder performSelector:_cmd];
 
   [self postNotificationName:NSWindowDidBecomeKeyNotification];
}

-(void)resignKeyWindow {
   _isKeyWindow=NO;

   if(_firstResponder!=self && [_firstResponder respondsToSelector:_cmd])
    [_firstResponder performSelector:_cmd];

   [self postNotificationName:NSWindowDidResignKeyNotification];
}

-(void)becomeMainWindow {
   [[NSApp mainWindow] resignMainWindow];
   _isMainWindow=YES;
   [self postNotificationName:NSWindowDidBecomeMainNotification];
}

-(void)resignMainWindow {
   _isMainWindow=NO;
   [self postNotificationName:NSWindowDidResignMainNotification];
}

- (NSTimeInterval)animationResizeTime:(NSRect)frame {
    return 0.20;
}

-(void)selectNextKeyView:sender {
   if([_firstResponder isKindOfClass:[NSView class]]){
    NSView *view=(NSView *)_firstResponder;

    [self selectKeyViewFollowingView:view];
   }
}

-(void)selectPreviousKeyView:sender {
   if([_firstResponder isKindOfClass:[NSView class]]){
    NSView *view=(NSView *)_firstResponder;

    [self selectKeyViewPrecedingView:view];
   }
}

-(void)selectKeyViewFollowingView:(NSView *)view {
   NSView *next=[view nextValidKeyView];
   [self makeFirstResponder:next];
}

-(void)selectKeyViewPrecedingView:(NSView *)view {
   NSView *next=[view previousValidKeyView];

   [self makeFirstResponder:next];
}

-(void)recalculateKeyViewLoop {
   NSUnimplementedMethod();
}

-(NSSelectionDirection)keyViewSelectionDirection {
   NSUnimplementedMethod();
   return 0;
}


- (void)disableKeyEquivalentForDefaultButtonCell {
    _defaultButtonCellKeyEquivalentDisabled = YES;
}

- (void)enableKeyEquivalentForDefaultButtonCell {
    _defaultButtonCellKeyEquivalentDisabled = NO;
}

-(NSText *)fieldEditor:(BOOL)create forObject:object {
   if(create && _fieldEditor==nil){
    _fieldEditor=[[NSTextView alloc] init];
   }

   [_fieldEditor setHorizontallyResizable:NO];
   [_fieldEditor setVerticallyResizable:NO];
   [_fieldEditor setFieldEditor:YES];
   [_fieldEditor setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

   return _fieldEditor;
}

-(void)endEditingFor:object {
   if((NSResponder *)_fieldEditor==_firstResponder){
    _firstResponder=self;
    [_fieldEditor resignFirstResponder];
   }
   [_fieldEditor setDelegate:nil];
   [_fieldEditor removeFromSuperview];
   [_fieldEditor setString:@""];
}

-(void)disableScreenUpdatesUntilFlush {
   NSUnimplementedMethod();
}

-(void)useOptimizedDrawing:(BOOL)flag {
   // do nothing
}

-(BOOL)viewsNeedDisplay {
   return _viewsNeedDisplay;
}

-(void)setViewsNeedDisplay:(BOOL)flag {
   _viewsNeedDisplay=flag;
}

-(void)disableFlushWindow {
   _flushDisabled++;
}

-(void)enableFlushWindow {
   _flushDisabled--;
}

-(void)flushWindow {
   if(_flushDisabled>0)
    _flushNeeded=YES;
   else {
    _flushNeeded=NO;
    [[self platformWindow] flushBuffer];
   }
}

-(void)flushWindowIfNeeded {
   if(_flushNeeded)
    [self flushWindow];
}

-(void)resetInvalidatedCursorRectsInView:(NSView *)view {
   if(NSCountHashTable(_invalidatedCursorRectViews)>0){
    NSArray *subviews=[view subviews];
    int      i,count=[subviews count];
 
    for(i=0;i<count;i++)
     [self resetInvalidatedCursorRectsInView:[subviews objectAtIndex:i]];

    if(NSHashGet(_invalidatedCursorRectViews,view)!=NULL)
     [view resetCursorRects];
   }
}

-(void)resetInvalidatedCursorRects {
   [self resetInvalidatedCursorRectsInView:_backgroundView];
   NSResetHashTable(_invalidatedCursorRectViews);
}

-(void)displayIfNeeded {
   if([self isVisible] && ![self isMiniaturized] && [self viewsNeedDisplay]){
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    [self disableFlushWindow];
    [_backgroundView displayIfNeeded];
    [self enableFlushWindow];
    [self flushWindowIfNeeded];
    [self setViewsNeedDisplay:NO];
    [self resetInvalidatedCursorRects];
    [pool release];
   }
}

-(void)display {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   [self disableFlushWindow];
   [_backgroundView display];
   [self enableFlushWindow];
   [self flushWindowIfNeeded];
   [pool release];
}

-(void)invalidateShadow {
   NSUnimplementedMethod();
}

-(void)cacheImageInRect:(NSRect)rect {
   NSUnimplementedMethod();
}

-(void)restoreCachedImage {
   NSUnimplementedMethod();
}

-(void)discardCachedImage {
   NSUnimplementedMethod();
}

-(BOOL)areCursorRectsEnabled {
   return (_cursorRectsDisabled<=0)?YES:NO;
}

-(void)disableCursorRects {
   _cursorRectsDisabled++;
}

-(void)enableCursorRects {
   _cursorRectsDisabled--;
}

-(void)discardCursorRects {
   [_cursorRects removeAllObjects];
}

-(void)resetCursorRectsInView:(NSView *)view {
   NSArray *subviews=[view subviews];
   int      i,count=[subviews count];

   for(i=0;i<count;i++)
    [self resetCursorRectsInView:[subviews objectAtIndex:i]];

   [view resetCursorRects];
}

-(void)resetCursorRects {
   [self discardCursorRects];
   [self resetCursorRectsInView: _backgroundView];
}

-(void)invalidateCursorRectsForView:(NSView *)view {
   [view discardCursorRects];
   NSHashInsert(_invalidatedCursorRectViews,view);
}

-(void)close {   
/*
  I am not sure if orderOut comes before the notification or not.
  If we order out after the notification, Windows sends the window a bunch of messages from the HIDE, and we
  end up potentially drawing, updating a window when it is not supposed to be, especially if the delegate has 
  already released objects that will be messaged during a draw/update.

  We either orderOut: before the notification, or have an _isClosed flag which causes
  some platformWindow messages to be ignored. Ones that would crash the app.
 */
   [self orderOut:nil];

   if ([_drawers count] > 0)
       [_drawers makeObjectsPerformSelector:@selector(parentWindowDidClose:) withObject:self];

   [self postNotificationName:NSWindowWillCloseNotification];

   if(_releaseWhenClosed)
    [self autorelease];
}

-(void)center {
   NSRect    frame=[self frame];
   NSScreen *screen=[self screen];
   NSRect    screenFrame;

   if(screen==nil)
    screen=[[NSScreen screens] objectAtIndex:0];

   screenFrame=[screen frame];

   frame.origin.x=floor(screenFrame.origin.x+screenFrame.size.width/2-frame.size.width/2);
   frame.origin.y=floor(screenFrame.origin.y+screenFrame.size.height/2-frame.size.height/2);

   [self setFrame:frame display:YES];
}

-(void)orderWindow:(NSWindowOrderingMode)place relativeTo:(int)relativeTo {
// The move notifications are sent under unknown conditions around orderFront: in the Apple AppKit, we do them all the time here until it's figured out. I suspect it is a side effect of off-screen windows being at off-screen coordinates (as opposed to just being hidden)

   [self postNotificationName:NSWindowWillMoveNotification];

   switch(place){
    case NSWindowAbove:
     [self update];

     _isVisible=YES;
     [[self platformWindow] placeAboveWindow:[(NSWindow *)relativeTo platformWindow]];
/* In some instances when a COMMAND is issued from a menu item to bring a
   window front, the window is not displayed right (black, incomplete). This
   may be the right place to do this, maybe not, further investigation is
   required
 */
     [self displayIfNeeded];
     // this is here since it would seem that doing this any earlier will not work.
     if(![self isKindOfClass:[NSPanel class]] && ![self isExcludedFromWindowsMenu])
         [NSApp changeWindowsItem:self title:_title filename:NO];
     break;

    case NSWindowBelow:
     [self update];

     _isVisible=YES;
     [[self platformWindow] placeBelowWindow:[(NSWindow *)relativeTo platformWindow]];
/* In some instances when a COMMAND is issued from a menu item to bring a
   window front, the window is not displayed right (black, incomplete). This
   may be the right place to do this, maybe not, further investigation is
   required
 */
     [self displayIfNeeded];
     // this is here since it would seem that doing this any earlier will not work.
     if(![self isKindOfClass:[NSPanel class]] && ![self isExcludedFromWindowsMenu])
         [NSApp changeWindowsItem:self title:_title filename:NO];
     break;

    case NSWindowOut:   
     _isVisible=NO;
     [[self platformWindow] hideWindow];
     if (![self isKindOfClass:[NSPanel class]])
      [NSApp removeWindowsItem:self];
     break;
   }

   [self postNotificationName:NSWindowDidMoveNotification];
}

-(void)orderFrontRegardless {
   NSUnimplementedMethod();
}

-(NSPoint)mouseLocationOutsideOfEventStream {
   NSPoint point=[_platformWindow mouseLocationOutsideOfEventStream];

   return [self convertScreenToBase:point];
}

-(NSEvent *)currentEvent {
    return [NSApp currentEvent];
}

-(NSEvent *)nextEventMatchingMask:(unsigned int)mask {
   return [self nextEventMatchingMask:mask untilDate:[NSDate distantFuture]
      inMode:NSEventTrackingRunLoopMode dequeue:YES];
}

-(NSEvent *)nextEventMatchingMask:(unsigned int)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue {
   NSEvent *event;

// this should get migrated down into event queue

   [[self platformWindow] captureEvents];

   do {
    event=[NSApp nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue];

   }while(!(mask&NSEventMaskFromType([event type])));

   return event;
}

-(void)discardEventsMatchingMask:(unsigned)mask beforeEvent:(NSEvent *)event {
   NSUnimplementedMethod();
}

-(void)sendEvent:(NSEvent *)event {
    if (_sheetContext != nil) {
        NSView *view = [_backgroundView hitTest:[event locationInWindow]];

        // Pretend that the event goes to the toolbar's view, no matter where it really is.
        // Could cause problems if custom views wanted to do something while the palette is running;
        // however they shouldn't be doing that!
        if ([[self toolbar] customizationPaletteIsRunning] &&
            (view == [[self toolbar] _view] || [[[[self toolbar] _view] subviews] containsObject:view])) {
            switch ([event type]) {
                case NSLeftMouseDown:
                    [[[self toolbar] _view] mouseDown:event];
                    break;
                    
                case NSLeftMouseUp:
                    [[[self toolbar] _view] mouseUp:event];
                    break;

                case NSLeftMouseDragged:
                    [[[self toolbar] _view] mouseDragged:event];
                    break;
                                        
                default:
                    break;
            }
        }
        else if ([event type] == NSPlatformSpecific){
            //[self _setSheetOriginAndFront];
            [_platformWindow sendEvent:[(NSEvent_CoreGraphics *)event coreGraphicsEvent]];
        }

        return;
    }

   switch([event type]){

    case NSLeftMouseDown:{
      NSView *view=[_backgroundView hitTest:[event locationInWindow]];

      [self makeFirstResponder:view];
// Doing this again seems correct for control cells which put a field editor up when they become first responder but I'm not sure
      view=[_backgroundView hitTest:[event locationInWindow]];
      [view mouseDown:event];
     }
     break;

    case NSLeftMouseUp:
     [[_backgroundView hitTest:[event locationInWindow]] mouseUp:event];
     break;

    case NSRightMouseDown:
     [[_backgroundView hitTest:[event locationInWindow]] rightMouseDown:event];
     break;

    case NSRightMouseUp:
     [[_backgroundView hitTest:[event locationInWindow]] rightMouseUp:event];
     break;

    case NSMouseMoved:
     [[_backgroundView hitTest:[event locationInWindow]] mouseMoved:event];
     break;

    case NSLeftMouseDragged:
     [[_backgroundView hitTest:[event locationInWindow]] mouseDragged:event];
     break;

    case NSRightMouseDragged:
     [[_backgroundView hitTest:[event locationInWindow]] rightMouseDragged:event];
     break;

    case NSMouseEntered:
     [[_backgroundView hitTest:[event locationInWindow]] mouseEntered:event];
     break;

    case NSMouseExited:
     [[_backgroundView hitTest:[event locationInWindow]] mouseExited:event];
     break;

    case NSKeyDown:
     [_firstResponder keyDown:event];
     break;

    case NSKeyUp:
     [_firstResponder keyUp:event];
     break;

    case NSFlagsChanged:
     [_firstResponder flagsChanged:event];
     break;

    case NSPlatformSpecific:
     [_platformWindow sendEvent:[(NSEvent_CoreGraphics *)event coreGraphicsEvent]];
     break;

    case NSScrollWheel:
     [_firstResponder scrollWheel:event];
     break;

    default:
     NSUnimplementedMethod();
     break;
   }
}

-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart {
   [NSApp postEvent:event atStart:atStart];
}

-(BOOL)tryToPerform:(SEL)selector with:object {   
   if([super tryToPerform:selector with:object])
    return YES;
   
   if([_delegate respondsToSelector:selector]){
    [_delegate performSelector:selector withObject:object];
    return YES;
   }
   
   return NO;
}

-(NSPoint)cascadeTopLeftFromPoint:(NSPoint)topLeftPoint {
   NSSize  screenSize = [[self screen] frame].size;
   NSRect  frame = [self frame];

   if (topLeftPoint.x + topLeftPoint.y == 0.0 || topLeftPoint.x > 0.5*screenSize.width || topLeftPoint.y < 0.5*screenSize.height)
   {
      topLeftPoint.x = frame.origin.x;
      topLeftPoint.y = frame.origin.y + frame.size.height;
   }
   
   else
   {
      topLeftPoint.x += 18;
      topLeftPoint.y -= 21;
      frame.origin.x=topLeftPoint.x;
      frame.origin.y=topLeftPoint.y - frame.size.height;
      [self setFrame:frame display:YES];
   }
   
   return topLeftPoint;
}

-(NSData *)dataWithEPSInsideRect:(NSRect)rect {
   return [_backgroundView dataWithEPSInsideRect:rect];
}

-(NSData *)dataWithPDFInsideRect:(NSRect)rect {
   return [_backgroundView dataWithPDFInsideRect:rect];
}

-(void)registerForDraggedTypes:(NSArray *)types {
   _draggedTypes=[types copy];
}

-(void)unregisterDraggedTypes {
   [_draggedTypes release];
   _draggedTypes=nil;
}

-(void)dragImage:(NSImage *)image at:(NSPoint)location offset:(NSSize)offset event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard source:source slideBack:(BOOL)slideBack {
   [[NSDraggingManager draggingManager] dragImage:image at:location offset:offset event:event pasteboard:pasteboard source:source slideBack:slideBack];
}

-validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
   NSUnimplementedMethod();
   return nil;
}

-(void)update {
   [[NSNotificationCenter defaultCenter]
       postNotificationName:NSWindowDidUpdateNotification
                     object:self];
}

-(void)makeKeyAndOrderFront:sender {
   if ([self isMiniaturized])
    [_platformWindow deminiaturize];

   [self makeKeyWindow];

   if(![self isKindOfClass:[NSPanel class]])
    [self makeMainWindow];

   [self orderWindow:NSWindowAbove relativeTo:0];
}

-(void)orderFront:sender {
   [self orderWindow:NSWindowAbove relativeTo:0];
}

-(void)orderBack:sender {
   [self orderWindow:NSWindowBelow relativeTo:0];
}

-(void)orderOut:sender {
   [self orderWindow:NSWindowOut relativeTo:0];
}

-(void)performClose:sender {
   if([_delegate respondsToSelector:@selector(windowShouldClose:)])
    if(![_delegate windowShouldClose:self])
     return;

   [self close];
}

-(void)performMiniaturize:sender {
   [self miniaturize:sender];
}

-(void)performZoom:sender {
   NSUnimplementedMethod();
}

-(void)zoom:sender {
   NSUnimplementedMethod();
}

-(void)miniaturize:sender {
   [[self platformWindow] miniaturize];
}

-(void)deminiaturize:sender {
   [[self platformWindow] deminiaturize];
}

-(void)print:sender {
   [_backgroundView print:sender];
}

-(void)toggleToolbarShown:sender {    
    [_toolbar setVisible:![_toolbar isVisible]];
    [sender setTitle:[NSString stringWithFormat:@"%@ Toolbar", [_toolbar isVisible] ? @"Hide" : @"Show"]];
}

-(void)runToolbarCustomizationPalette:sender {
    [_toolbar runCustomizationPalette:sender];
}

- (void)keyDown:(NSEvent *)event {
    if ([self performKeyEquivalent:event] == NO)
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)doCommandBySelector:(SEL)selector {
    if ([_delegate respondsToSelector:selector])
        [_delegate performSelector:selector withObject:nil];
    else
        [super doCommandBySelector:selector];
}

- (void)insertTab:sender {
    [self selectNextKeyView:nil];
}

- (void)insertBacktab:sender {
    [self selectPreviousKeyView:nil];
}

- (void)insertNewline:sender {
    if (_defaultButtonCell != nil)
        [(NSControl *)[_defaultButtonCell controlView] performClick:nil];
}


-(void)_addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor view:(NSView *)view {
   NSCursorRect *cursorRect=[NSCursorRect cursorRectWithRect:rect flipped:[view isFlipped] cursor:cursor view:view];
   [_cursorRects addObject:cursorRect];
}

-(void)_removeCursorRect:(NSRect)rect cursor:(NSCursor *)cursor view:(NSView *)view {
   int count=[_cursorRects count];

   while(--count>=0){
    NSCursorRect *check=[_cursorRects objectAtIndex:count];

    if(([check view]==view) && ([check cursor]==cursor) & NSEqualRects([check rect],rect))
     [_cursorRects removeObjectAtIndex:count];
   }
}

-(void)_discardCursorRectsForView:(NSView *)view {
   int count=[_cursorRects count];

   while(--count>=0){
    NSCursorRect *check=[_cursorRects objectAtIndex:count];

    if([check view]==view)
     [_cursorRects removeObjectAtIndex:count];
   }
}

-(NSTrackingRectTag)_addTrackingRect:(NSRect)rect view:(NSView *)view flipped:(BOOL)flipped owner:owner userData:(void *)userData assumeInside:(BOOL)assumeInside isToolTip:(BOOL)isToolTip {
   NSTrackingRect *tracking=[[[NSTrackingRect alloc] initWithRect:rect view:view flipped:flipped owner:owner userData:userData assumeInside:assumeInside isToolTip:isToolTip] autorelease];

   [tracking setTag:_nextTrackingRectTag++];
   [_trackingRects addObject:tracking];

   return [tracking tag];
}

-(void)_removeTrackingRect:(NSTrackingRectTag)tag {
   int count=[_trackingRects count];

   while(--count>=0){
    if([[_trackingRects objectAtIndex:count] tag]==tag)
     [_trackingRects removeObjectAtIndex:count];
   }
}

-(void)_discardTrackingRectsForView:(NSView *)view toolTipsOnly:(BOOL)toolTipsOnly {
    int count=[_trackingRects count];
    
    while(--count>=0) {
        NSTrackingRect *trackingRect = [_trackingRects objectAtIndex:count];
        
        if (toolTipsOnly == YES && [trackingRect isToolTip] == NO)
            continue;
        
        if ([trackingRect view] == view)
            [_trackingRects removeObjectAtIndex:count];
    }
}

-(void)_removeAllToolTips {
    int count=[_trackingRects count];
    
    while(--count>=0)
        if([[_trackingRects objectAtIndex:count] isToolTip])
            [_trackingRects removeObjectAtIndex:count];
}

-(void)_showForActivation {
   if(_hiddenForDeactivate){
    _hiddenForDeactivate=NO;
    [[self platformWindow] showWindowForAppActivation:_frame];
   }
}

-(void)_hideForDeactivation {
   if([self hidesOnDeactivate] && [self isVisible] && ![self isMiniaturized]){
    _hiddenForDeactivate=YES;
    [[self platformWindow] hideWindowForAppDeactivation:_frame];
   }
}

-(void)_forcedHideForDeactivation {
	if([self isVisible]){
		_hiddenForDeactivate=YES;
		//_hiddenKeyWindow=[self isKeyWindow];
		[[self platformWindow] hideWindowForAppDeactivation:_frame];
	}
}




-(BOOL)performKeyEquivalent:(NSEvent *)event {
   return [_backgroundView performKeyEquivalent:event];
}

#if 0
-(void)keyDown:(NSEvent *)event {
   if(![self performKeyEquivalent:event]){
    NSString *characters=[event charactersIgnoringModifiers];

    if([characters isEqualToString:@" "])
     [_firstResponder tryToPerform:@selector(performClick:) with:nil];
    else if([characters isEqualToString:@"\t"]){
     if([event modifierFlags]&NSShiftKeyMask)
      [self selectPreviousKeyView:nil];
     else
      [self selectNextKeyView:nil];
    }
   }
}
#endif

-(void)setMenu:(NSMenu *)menu {
   if(_menuView!=nil){
    NSSize  oldSize=[_menuView frame].size,newSize;
    NSSize  backSize=[_backgroundView frame].size;
    NSRect  frame;

    [_menuView setMenu:menu];

    newSize=[_menuView frame].size;
   
    backSize.height+=(newSize.height-oldSize.height);
    [_backgroundView setAutoresizesSubviews:NO];
    [_backgroundView setFrameSize:backSize];
    [_backgroundView setAutoresizesSubviews:YES];

    frame=[self frame];
    frame.size.height+=(newSize.height-oldSize.height);
    // no display because setMenu: is called before awakeFromNib
    [self setFrame:frame display:NO];
    // do we even need this?
    [_backgroundView setNeedsDisplay:YES]; 
   }

   _menu=[menu copy];
}

-(NSMenu *)menu {
   return _menu;
}

-(BOOL)_isActive {
   return _isActive;
}

// default NSDraggingDestination
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
   return NSDragOperationNone;
}

-(NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
   return [sender draggingSourceOperationMask];
}

-(void)draggingExited:(id <NSDraggingInfo>)sender {
   // do nothing
}

-(BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
   return NO;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
   return NO;
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)sender {
   // do nothing
}


-(NSArray *)_draggedTypes {
   return _draggedTypes;
}

-(void)_setSheetOrigin {
   NSWindow *sheet=[_sheetContext sheet];
   NSRect    sheetFrame=[sheet frame];
   NSRect    frame=[self frame];
   NSPoint   origin;

   origin.y=frame.origin.y+(frame.size.height-sheetFrame.size.height);
   origin.x=frame.origin.x+floor((frame.size.width-sheetFrame.size.width)/2);

   
   if ([self toolbar] != nil) {
       if (_menuView != nil)
           origin.y -= [_menuView frame].size.height;
       
       origin.y -= [[[self toolbar] _view] frame].size.height;
       
       // Depending on the final border types used on the toolbar and the sheets, the sheet placement
       // sometimes looks better with a little "adjustment"....
       origin.y++;
   }

   [sheet setFrameOrigin:origin];
}

-(void)_setSheetOriginAndFront {
   if(_sheetContext!=nil){
    [self _setSheetOrigin];

    [[_sheetContext sheet] orderFront:nil];
   }
}

-(void)_attachSheetContextOrderFrontAndAnimate:(NSSheetContext *)sheetContext {
    NSWindow *sheet = [sheetContext sheet];
    NSRect sheetFrame;

    [_sheetContext autorelease];
   _sheetContext=[sheetContext retain];

   [self _setSheetOrigin];
   sheetFrame = [sheet frame];
   
   [(NSWindowBackgroundView *)[sheet _backgroundView] setBorderType:NSButtonBorder];
   [[sheet contentView] setAutoresizesSubviews:NO];
   [[sheet contentView] setAutoresizingMask:NSViewNotSizable];
   
//   [(NSWindowBackgroundView *)[sheet _backgroundView] cacheImageForAnimation];
   
   [sheet setFrame:NSMakeRect(sheetFrame.origin.x, NSMaxY([self frame]), sheetFrame.size.width, 0) display:YES];
   [self _setSheetOriginAndFront];
   
   [sheet setFrame:sheetFrame display:YES animate:YES];
}

-(NSSheetContext *)_sheetContext {
   return _sheetContext;
}

-(void)_sheetDidFinishAnimating:(NSNotification *)note {
    NSWindow *sheet = [_sheetContext sheet];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidAnimateNotification object:sheet];
    
    [sheet orderOut:nil];
    [sheet setFrame:[_sheetContext frame] display:NO animate:NO];
    
    [_sheetContext release];
    _sheetContext=nil;
}

-(void)_detachSheetContextAnimateAndOrderOut {
    NSWindow *sheet = [_sheetContext sheet];
    NSRect frame = [sheet frame];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sheetDidFinishAnimating:) name:NSWindowDidAnimateNotification object:sheet];

    frame.origin.y = NSMaxY(frame) - 2;
    frame.size.height = 2;
 
    [sheet setFrame:frame display:YES animate:YES];
}

-(void)platformWindowActivated:(CGWindow *)window {
   [NSApp _windowWillBecomeActive:self];
   
   [self _setSheetOriginAndFront];
   if ([_drawers count] > 0)
       [_drawers makeObjectsPerformSelector:@selector(parentWindowDidActivate:) withObject:self];

   _isActive=YES;
   if([self canBecomeKeyWindow] && ![self isKeyWindow])
    [self becomeKeyWindow];
   if([self canBecomeMainWindow] && ![self isMainWindow])
    [self becomeMainWindow];

   [_menuView setNeedsDisplay:YES];
   [self displayIfNeeded];

   [NSApp _windowDidBecomeActive:self];
   
   [NSApp updateWindows];
}

-(void)platformWindowDeactivated:(CGWindow *)window checkForAppDeactivation:(BOOL)checkForAppDeactivation {
   [NSApp _windowWillBecomeDeactive:self];
   
   if ([_drawers count] > 0)
       [_drawers makeObjectsPerformSelector:@selector(parentWindowDidDeactivate:) withObject:self];

   _isActive=NO;

   if([self isKeyWindow])
    [self resignKeyWindow];

   [_menuView setNeedsDisplay:YES];
   [self displayIfNeeded];

   if(checkForAppDeactivation)
    [NSApp performSelector:@selector(_checkForAppActivation)];

   [NSApp _windowDidBecomeDeactive:self];
   
   [NSApp updateWindows];
}

-(void)platformWindowDeminiaturized:(CGWindow *)window {
   [self _updatePlatformWindowTitle];
   [self postNotificationName:NSWindowDidDeminiaturizeNotification];
   [NSApp updateWindows];
}

-(void)platformWindowMiniaturized:(CGWindow *)window {
   _isActive=NO;

   [self _updatePlatformWindowTitle];
   [self postNotificationName:NSWindowDidMiniaturizeNotification];

   if([self isKeyWindow])
    [self resignKeyWindow];

   if([self isMainWindow])
    [self resignMainWindow];

   if ([_drawers count] > 0)
       [_drawers makeObjectsPerformSelector:@selector(parentWindowDidMiniaturize:) withObject:self];

   [NSApp updateWindows];
}

-(void)platformWindow:(CGWindow *)window frameChanged:(NSRect)frame {
   _frame=frame;
   _makeSureIsOnAScreen=YES;

   [self _setSheetOriginAndFront];
   if ([_drawers count] > 0)
       [_drawers makeObjectsPerformSelector:@selector(parentWindowDidChangeFrame:) withObject:self];

   [_backgroundView setFrameSize:_frame.size];
   [_backgroundView setNeedsDisplay:YES];

   [self saveFrameUsingName:_autosaveFrameName];
   [self resetCursorRects];
}

-(void)platformWindowExitMove:(CGWindow *)window {
   [self _setSheetOriginAndFront];
    if ([_drawers count] > 0)
        [_drawers makeObjectsPerformSelector:@selector(parentWindowDidExitMove:) withObject:self];
}

-(NSSize)platformWindow:(CGWindow *)window frameSizeWillChange:(NSSize)size {
   if([_delegate respondsToSelector:@selector(windowWillResize:toSize:)])
    size=[_delegate windowWillResize:self toSize:size];

   return size;
}

-(void)platformWindowWillBeginSizing:(CGWindow *)window {
   [_backgroundView viewWillStartLiveResize];
}

-(void)platformWindowDidEndSizing:(CGWindow *)window {
   [_backgroundView viewDidEndLiveResize];
}

-(void)platformWindow:(CGWindow *)window needsDisplayInRect:(NSRect)rect {
    [self display];
}

-(void)platformWindowStyleChanged:(CGWindow *)window {
    [self display];
}

-(void)platformWindowWillClose:(CGWindow *)window {
   if([NSApp modalWindow]==self)
    [NSApp stopModalWithCode:NSRunAbortedResponse];

   [self performClose:nil];
}

-(void)platformWindowWillMove:(CGWindow *)window {
   [self postNotificationName:NSWindowWillMoveNotification];
}

-(void)platformWindowDidMove:(CGWindow *)window {
   [self postNotificationName:NSWindowDidMoveNotification];
}

-(BOOL)platformWindowIgnoreModalMessages:(CGWindow *)window {
   if([NSApp modalWindow]==nil)
    return NO;

   if([self worksWhenModal])
    return NO;

   return ([NSApp modalWindow]==self)?NO:YES;
}

-(BOOL)platformWindowSetCursorEvent:(CGWindow *)window {
   BOOL didSetCursor=NO;

   if(_sheetContext!=nil)
    return NO;

   if([self areCursorRectsEnabled]){
    NSPoint point=[self mouseLocationOutsideOfEventStream];
    BOOL    isFlipped=[_backgroundView isFlipped];
    BOOL    didTrackRect=NO;

    point=[_backgroundView convertPoint:point fromView:nil];

    if(NSMouseInRect(point,[_backgroundView frame],isFlipped)){
     int i,count=[_cursorRects count];

     for(i=0;i<count;i++){
      NSCursorRect *check=[_cursorRects objectAtIndex:i];
      NSRect        rect=[check rect];

      if(![[check view] isHidden] && NSMouseInRect(point,rect,isFlipped)){
       [[check cursor] set];
       didSetCursor=YES;
       break;
      }
     }

     count=[_trackingRects count];
     for(i=0;i<count;i++){
      NSTrackingRect *check=[_trackingRects objectAtIndex:i];

                if(![[check view] isHidden] && NSMouseInRect(point,[check rect],isFlipped)){
                    if([check isToolTip]) {
                        NSString *toolTip;
                        NSPoint locationOnScreen=NSMakePoint(NSMaxX([[check view] bounds]) + 5.0, NSMinY([[check view] bounds]) - 5.0);
                        
                        locationOnScreen=[[check view] convertPoint:locationOnScreen toView:nil];
                        locationOnScreen=[[[check view] window] convertBaseToScreen:locationOnScreen];
                        
                        if ([[check owner] respondsToSelector:@selector(view:stringForToolTip:point:userData:)])
                            toolTip = [[check owner] view:[check view] stringForToolTip:[check tag] point:point userData:[check userData]];
                        else
                            toolTip = [[check owner] description];
                        
                        if ([[[NSToolTipWindow sharedToolTipWindow] toolTip] isEqualToString:toolTip] == NO) {
                            [[NSToolTipWindow sharedToolTipWindow] setToolTip:toolTip];
                            [[NSToolTipWindow sharedToolTipWindow] setLocationOnScreen:locationOnScreen];
                            
                            [[NSToolTipWindow sharedToolTipWindow] performSelector:@selector(orderFront:) withObject:nil afterDelay:0.5];
                        }
                    }
                    else
                        [[check owner] mouseEntered:[NSEvent mouseEventWithType:NSMouseEntered location:point modifierFlags:0 window:self clickCount:0]];
                    
                    [_trackedRect release];
                    _trackedRect = [check retain];
                    
                    didTrackRect = YES;
                }
     }
    }
        if (didTrackRect == NO && _trackedRect != nil) {
            if ([_trackedRect isToolTip])
                [[NSToolTipWindow sharedToolTipWindow] orderOut:nil];
            else
                [[_trackedRect owner] mouseExited:[NSEvent mouseEventWithType:NSMouseExited location:point modifierFlags:0 window:self clickCount:0]];
            
            [_trackedRect release];
            _trackedRect = nil;
        }        
   }
   return didSetCursor;
}

-(NSUndoManager *)undoManager {
    if ([_delegate respondsToSelector:@selector(windowWillReturnUndoManager:)])
        return [_delegate windowWillReturnUndoManager:self];
    
    //  If the delegate does not implement this method, the NSWindow creates an NSUndoManager for the window and all its views. -- seems like some duplication vs. NSDocument, but oh well..
    if (_undoManager == nil){
        _undoManager = [[NSUndoManager alloc] init];
        [_undoManager setRunLoopModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode,nil]];
    }

    return _undoManager;
}

-(void)_attachDrawer:(NSDrawer *)drawer {
    if (_drawers == nil)
        _drawers = [[NSMutableArray alloc] init];
    
    [_drawers addObject:drawer];
}

-(void)_detachDrawer:(NSDrawer *)drawer {
    [_drawers removeObject:drawer];
}

-(NSView *)_backgroundView {
    return _backgroundView;
}

@end

