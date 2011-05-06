/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSModalSessionX.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSColorPanel.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSSheetContext.h>
#import <AppKit/NSSystemInfoPanel.h>
#import <AppKit/NSAlert.h>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSDockTile.h>
#import <CoreGraphics/CGWindow.h>
#import <AppKit/NSRaise.h>
#import <objc/message.h>

NSString * const NSModalPanelRunLoopMode=@"NSModalPanelRunLoopMode";
NSString * const NSEventTrackingRunLoopMode=@"NSEventTrackingRunLoopMode";

NSString * const NSApplicationWillFinishLaunchingNotification=@"NSApplicationWillFinishLaunchingNotification";
NSString * const NSApplicationDidFinishLaunchingNotification=@"NSApplicationDidFinishLaunchingNotification";

NSString * const NSApplicationWillBecomeActiveNotification=@"NSApplicationWillBecomeActiveNotification";
NSString * const NSApplicationDidBecomeActiveNotification=@"NSApplicationDidBecomeActiveNotification";
NSString * const NSApplicationWillResignActiveNotification=@"NSApplicationWillResignActiveNotification";
NSString * const NSApplicationDidResignActiveNotification=@"NSApplicationDidResignActiveNotification";

NSString * const NSApplicationWillUpdateNotification=@"NSApplicationWillUpdateNotification";
NSString * const NSApplicationDidUpdateNotification=@"NSApplicationDidUpdateNotification";

NSString * const NSApplicationWillHideNotification=@"NSApplicationWillHideNotification";
NSString * const NSApplicationDidHideNotification=@"NSApplicationDidHideNotification";
NSString * const NSApplicationWillUnhideNotification=@"NSApplicationWillUnhideNotification";
NSString * const NSApplicationDidUnhideNotification=@"NSApplicationDidUnhideNotification";

NSString * const NSApplicationWillTerminateNotification=@"NSApplicationWillTerminateNotification";

NSString * const NSApplicationDidChangeScreenParametersNotification=@"NSApplicationDidChangeScreenParametersNotification";

@interface NSDocumentController(forward) 
-(void)_updateRecentDocumentsMenu; 
@end 

@interface NSMenu(private)
-(NSMenu *)_menuWithName:(NSString *)name;
@end

@interface NSDockTile(private)
-initWithOwner:owner;
@end

@implementation NSApplication

id NSApp=nil;

+(void)initialize {
   if(self==[NSApplication class]){

    [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(startRunningCopyPipe)];
   }
}

+(NSApplication *)sharedApplication {

   if(NSApp==nil){
      [[self alloc] init]; // NSApp must be nil inside init
   }

   return NSApp;
}

+(void)detachDrawingThread:(SEL)selector toTarget:target withObject:object {
   NSUnimplementedMethod();
}

-(void)_showSplashImage {
   NSImage *image=[NSImage imageNamed:@"splash"];

   if(image!=nil){
    NSSize    imageSize=[image size];
    NSWindow *splash=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,imageSize.width,imageSize.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [splash setLevel:NSFloatingWindowLevel];
    
    NSImageView *view=[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,imageSize.width,imageSize.height)];
    
    [view setImage:image];
    [splash setContentView:view];
    [view release];
    [splash setReleasedWhenClosed:YES];
    [splash center];
    [splash orderFront:nil];
    [splash display];
   }
}

-(void)_closeSplashImage {
   int i;
   
   for(i=0;i<[_windows count];i++){
    NSWindow *check=[_windows objectAtIndex:i];
    NSView   *contentView=[check contentView];
    
    if([contentView isKindOfClass:[NSImageView class]])
     if([[[(NSImageView *)contentView image] name] isEqual:@"splash"]){
      [check close];
      return;
     }
   }
}

-init {
   if(NSApp)
      NSAssert(!NSApp, @"NSApplication is a singleton");
   NSApp=self;
   _display=[[NSDisplay currentDisplay] retain];

   _windows=[NSMutableArray new];
   _mainMenu=nil;
      
   _dockTile=[[NSDockTile alloc] initWithOwner:self];
   _modalStack=[NSMutableArray new];
      
   [self _showSplashImage];
   
   return NSApp;
}

-(NSGraphicsContext *)context {
   NSUnimplementedMethod();
   return nil;
}

-delegate {
   return _delegate;
}

-(NSArray *)windows {
   return _windows;
}

-(NSWindow *)windowWithWindowNumber:(NSInteger)number {
   int i,count=[_windows count];
   
   for(i=0;i<count;i++){
    NSWindow *check=[_windows objectAtIndex:i];
    
    if([check windowNumber]==number)
     return check;
   }
   
   return nil;
}

-(NSMenu *)mainMenu {
   return _mainMenu;
}

-(NSMenu *)menu {
  return [self mainMenu];
}

-(NSMenu *)windowsMenu {
   if(_windowsMenu==nil) {
    _windowsMenu=[[NSApp mainMenu] _menuWithName:@"_NSWindowsMenu"];
    if (_windowsMenu && ![[[_windowsMenu itemArray] lastObject] isSeparatorItem])
     [_windowsMenu addItem:[NSMenuItem separatorItem]];
   }

   return _windowsMenu;
}

-(NSWindow *)mainWindow {
   return _mainWindow;
}

-(void)_setMainWindow:(NSWindow *)window {
   _mainWindow=window;
}

-(NSWindow *)keyWindow {
   return _keyWindow;
}

-(void)_setKeyWindow:(NSWindow *)window {
   _keyWindow=window;
}

-(NSImage *)applicationIconImage {
   return _applicationIconImage;
}

-(BOOL)isActiveExcludingWindow:(NSWindow *)exclude {
   int count=[_windows count];

   while(--count>=0){
    NSWindow *check=[_windows objectAtIndex:count];

    if(check==exclude)
     continue;
     
    if([check _isActive])
     return YES;
   }

   return NO;
}

-(BOOL)isActive {
   return [self isActiveExcludingWindow:nil];
}

-(BOOL)isHidden {
	return _isHidden;
}

-(BOOL)isRunning {
   return _isRunning;
}

-(NSWindow *)makeWindowsPerform:(SEL)selector inOrder:(BOOL)inOrder {
   NSUnimplementedMethod();
   return nil;
}

-(void)miniaturizeAll:sender {
   int count=[_windows count];
   
   while(--count>=0)
    [[_windows objectAtIndex:count] miniaturize:sender];
}

-(NSArray *)orderedDocuments {
   NSMutableArray *result=[NSMutableArray array];
   NSArray        *orderedWindows=[self orderedWindows];
   
   for(NSWindow *checkWindow in orderedWindows){
    NSDocument *checkDocument=[[checkWindow windowController] document];
    
    if(checkDocument!=nil)
     [result addObject:checkDocument];
   }
   
   return result;
}

-(NSArray *)orderedWindows {
  extern NSArray *CGSOrderedWindowNumbers();
  
  NSMutableArray *result=[NSMutableArray array];
  NSArray *numbers=CGSOrderedWindowNumbers();
  
  for(NSNumber *number in numbers){
   NSWindow *window=[self windowWithWindowNumber:[number integerValue]];
   
   if(window!=nil && ![window isKindOfClass:[NSPanel class]])
    [result addObject:window];
  }
  
  return result;
}

-(void)preventWindowOrdering {
   NSUnimplementedMethod();
}

-(void)registerDelegate {
    if([_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)]){
     [[NSNotificationCenter defaultCenter] addObserver:_delegate
       selector:@selector(applicationWillFinishLaunching:)
        name:NSApplicationWillFinishLaunchingNotification object:self];
    }
    if([_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]){
     [[NSNotificationCenter defaultCenter] addObserver:_delegate
       selector:@selector(applicationDidFinishLaunching:)
        name:NSApplicationDidFinishLaunchingNotification object:self];
    }
    if([_delegate respondsToSelector:@selector(applicationDidBecomeActive:)]){
     [[NSNotificationCenter defaultCenter] addObserver:_delegate
       selector:@selector(applicationDidBecomeActive:)
        name: NSApplicationDidBecomeActiveNotification object:self];
    }
   if([_delegate respondsToSelector:@selector(applicationWillTerminate:)]){
      [[NSNotificationCenter defaultCenter] addObserver:_delegate
                                               selector:@selector(applicationWillTerminate:)
                                                   name: NSApplicationWillTerminateNotification object:self];
   }
   
}

-(void)setDelegate:delegate {
   _delegate=delegate;
   [self registerDelegate];
}

-(void)setMainMenu:(NSMenu *)menu {
   int i,count=[_windows count];

   [_mainMenu autorelease];
   _mainMenu=[menu copy];

   for(i=0;i<count;i++){
    NSWindow *window=[_windows objectAtIndex:i];

    if(![window isKindOfClass:[NSPanel class]])
     [window setMenu:_mainMenu];
   }
}

-(void)setMenu:(NSMenu *)menu {
   [self setMainMenu:menu];
}

-(void)setApplicationIconImage:(NSImage *)image {
   image=[image retain];
   [_applicationIconImage release];
   _applicationIconImage=image;
   
   NSUnimplementedMethod();
}

-(void)setWindowsMenu:(NSMenu *)menu {
   [_windowsMenu autorelease];
   _windowsMenu=[menu retain];
}


-(void)addWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)isFilename {
    NSMenuItem *item;
    
    if ([[self windowsMenu] indexOfItemWithTarget:window andAction:@selector(makeKeyAndOrderFront:)] != -1)
        return;

    if (isFilename)
        title = [NSString stringWithFormat:@"%@  --  %@", [title lastPathComponent],[title stringByDeletingLastPathComponent]];

    item = [[[NSMenuItem alloc] initWithTitle:title action:@selector(makeKeyAndOrderFront:) keyEquivalent:@""] autorelease];
    [item setTarget:window];

    [[self windowsMenu] addItem:item];
}

-(void)changeWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)isFilename {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:window andAction:@selector(makeKeyAndOrderFront:)];

    if (itemIndex != -1) {
        NSMenuItem *item = [[self windowsMenu] itemAtIndex:itemIndex];

        if (isFilename)
            title = [NSString stringWithFormat:@"%@  --  %@",[title lastPathComponent], [title stringByDeletingLastPathComponent]];

        [item setTitle:title];
        [[self windowsMenu] itemChanged:item];
    }
    else
        [self addWindowsItem:window title:title filename:isFilename];
}

-(void)removeWindowsItem:(NSWindow *)window {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:window andAction:@selector(makeKeyAndOrderFront:)];
    
    if (itemIndex != -1) {
        [[self windowsMenu] removeItemAtIndex:itemIndex];

        if ([[[[self windowsMenu] itemArray] lastObject] isSeparatorItem]){
            [[self windowsMenu] removeItem:[[[self windowsMenu] itemArray] lastObject]];
          }
    }
}

-(void)updateWindowsItem:(NSWindow *)window {
#if 0
    NSUnimplementedMethod();
#else
   NSMenu *menu=[self windowsMenu];
   int     itemIndex=[[self windowsMenu] indexOfItemWithTarget:window andAction:@selector(makeKeyAndOrderFront:)];
   
   if(itemIndex!=-1){
    NSMenuItem *item=[menu itemAtIndex:itemIndex];
    
   }
#endif
}

-(void)finishLaunching {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   BOOL               needsUntitled=YES;

   NS_DURING
    [[NSNotificationCenter defaultCenter] postNotificationName: NSApplicationWillFinishLaunchingNotification object:self];
   NS_HANDLER
    [self reportException:localException];
   NS_ENDHANDLER

// Give us a first event
   [NSTimer scheduledTimerWithTimeInterval:0.1 target:nil
     selector:NULL userInfo:nil repeats:NO];

   [self _closeSplashImage];

   NSDocumentController *controller = nil;
   id types=[[[NSBundle mainBundle]
		 infoDictionary]
		objectForKey:@"CFBundleDocumentTypes"];
   if([types count] > 0)
       controller = [NSDocumentController sharedDocumentController];
   
   if(_delegate && [_delegate respondsToSelector: @selector(application:openFile:)]) {
       NSString *openFile = [[NSUserDefaults standardUserDefaults]
				stringForKey:@"NSOpen"];

       if([openFile length] > 0) {
	   if([_delegate application: self openFile: openFile])
	       needsUntitled = NO;
       }
   }

   if(needsUntitled && _delegate &&
      [_delegate respondsToSelector: @selector(applicationShouldOpenUntitledFile:)]) {
       needsUntitled = [_delegate applicationShouldOpenUntitledFile: self];
   }

   if(needsUntitled && _delegate && [_delegate respondsToSelector: @selector(applicationOpenUntitledFile:)]) {
     needsUntitled = ![_delegate applicationOpenUntitledFile: self];
   }

   if(needsUntitled && controller && ![controller documentClassForType:[controller defaultType]]) {
       needsUntitled = NO;
   }

   if(needsUntitled && controller) {
       [controller _updateRecentDocumentsMenu]; 
       [controller newDocument: self];
   }
   
   NS_DURING
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidFinishLaunchingNotification object:self];
   NS_HANDLER
    [self reportException:localException];
   NS_ENDHANDLER

   [pool release];
}

-(void)_checkForReleasedWindows {
   int  count=[_windows count];

   while(--count>=0){
    NSWindow *check=[_windows objectAtIndex:count];

    if([check retainCount]==1){
    
     if(check==_keyWindow)
      _keyWindow=nil;
      
     if(check==_mainWindow)
      _mainWindow=nil;
      
     [_windows removeObjectAtIndex:count];
   }
}
}

-(void)_checkForTerminate {
   int  count=[_windows count];

   while(--count>=0){
    NSWindow *check=[_windows objectAtIndex:count];

    if(![check isKindOfClass:[NSPanel class]] && [check isVisible]){
     return;
    }
   }

   [self terminate:self];
}

-(void)_checkForAppActivation {
#if 1
   if([self isActive])
    [_windows makeObjectsPerformSelector:@selector(_showForActivation)];
   else
    [_windows makeObjectsPerformSelector:@selector(_hideForDeactivation)];
#endif
}

-(void)run {
    
  static BOOL didlaunch = NO;
  NSAutoreleasePool *pool;

  _isRunning=YES;

  if (!didlaunch) {
    didlaunch = YES;
    pool=[NSAutoreleasePool new];
    [self finishLaunching];
    [pool release];
  }
   
   do {
       pool = [NSAutoreleasePool new];
       NSEvent           *event;

    event=[self nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];

    NS_DURING
     [self sendEvent:event];

    NS_HANDLER
     [self reportException:localException];
    NS_ENDHANDLER

    [self _checkForReleasedWindows];
    [self _checkForTerminate];

    [pool release];
   }while(_isRunning);
}

-(BOOL)_performKeyEquivalent:(NSEvent *)event {
   if([[self mainMenu] performKeyEquivalent:event])
    return YES;
   if([[self keyWindow] performKeyEquivalent:event])
    return YES;
   if([[self mainWindow] performKeyEquivalent:event])
    return YES;
// documentation says to send it to all windows
   return NO;
}

-(void)sendEvent:(NSEvent *)event {
   if([event type]==NSKeyDown){
    unsigned modifierFlags=[event modifierFlags];

    if(modifierFlags&(NSCommandKeyMask|NSAlternateKeyMask))
     if([self _performKeyEquivalent:event])
      return;
   }

   [[event window] sendEvent:event];
}

// This method is used by NSWindow
-(void)_displayAllWindowsIfNeeded {
   [[NSApp windows] makeObjectsPerformSelector:@selector(displayIfNeeded)];
}

-(NSEvent *)nextEventMatchingMask:(unsigned int)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue {
   NSEvent *nextEvent=nil;
   
   do {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];

   NS_DURING
    [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(createRunningCopyPipe)];

       // This should happen before _makeSureIsOnAScreen so we don't reposition done windows
    [self _checkForReleasedWindows];

    [[NSApp windows] makeObjectsPerformSelector:@selector(_makeSureIsOnAScreen)];
 
    [self _checkForAppActivation];
     [self _displayAllWindowsIfNeeded];

     nextEvent=[[_display nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue] retain];

     if([nextEvent type]==NSAppKitSystem){
      [nextEvent release];
      nextEvent=nil;
     }
     
   NS_HANDLER
    [self reportException:localException];
   NS_ENDHANDLER

   [pool release];
   }while(nextEvent==nil && [untilDate timeIntervalSinceNow]>0);

   if(nextEvent!=nil){
    [_currentEvent release];
    _currentEvent=[nextEvent retain];
}

   return [nextEvent autorelease];
}

-(NSEvent *)currentEvent {
   return _currentEvent;
}

-(void)discardEventsMatchingMask:(unsigned)mask beforeEvent:(NSEvent *)event {
   [_display discardEventsMatchingMask:mask beforeEvent:event];
}

-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart {
   [_display postEvent:event atStart:atStart];
}

-_searchForAction:(SEL)action responder:target {
  // Search a responder chain 

   while (target != nil) {

    if ([target respondsToSelector:action])
     return target;
          
    if([target respondsToSelector:@selector(nextResponder)])
     target = [target nextResponder];
    else
     break;
   }
  
   return nil;
}

-_searchForAction:(SEL)action window:(NSWindow *)window {
 // Search a windows responder chain and window
 // The window check is done seperately from the responder chain
 // in case the responder chain is broken

// FIXME: should a windows delegate and windowController be checked if a window is found in a responder chain too ?
// Document based facts:
//  An NSWindow's next responder should be the window controller
//  An NSWindow's delegate should be the document
// - This probably means the windowController check is duplicative, but need to make the next responder is window controller

   id check=[self _searchForAction:action responder:[window firstResponder]];
   
   if(check!=nil)
    return check;

   if ([[window delegate] respondsToSelector:action])
    return [window delegate];
    
   if ([[window windowController] respondsToSelector:action])
    return [window windowController];

   return nil;
}

-targetForAction:(SEL)action {
  return [self targetForAction:action to:nil from:nil];
}

-targetForAction:(SEL)action to:target from:sender {
  if (target == nil) 
    {
      target = [self _searchForAction:action window:[self keyWindow]];
      if (target)
        return target;
      
      if ([self mainWindow] != [self keyWindow]) 
        {
          target = [self _searchForAction:action window:[self mainWindow]];
          if (target)
            return target;
        }
    }
  else 
    {
      target = [self _searchForAction:action responder:target];
      if (target)
        return target;
    }
  
  NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
  if ([[documentController currentDocument] respondsToSelector:action])
    return [documentController currentDocument];
  
  if([self respondsToSelector:action])
    return self;
  
  if([[self delegate] respondsToSelector:action])
    return [self delegate];
  
  if([documentController respondsToSelector:action])
    return documentController;
  
  return nil; 
}

-(BOOL)sendAction:(SEL)action to:target from:sender {
  if([target respondsToSelector:action])
    {
      [target performSelector:action withObject:sender];
      return YES;
    }
  
  target=[self targetForAction:action to:target from:sender];
  if (target != nil) 
    {
      [target performSelector:action withObject:sender];
      return YES;
    }
  
  return NO;
}

-(BOOL)tryToPerform:(SEL)selector with:object {
  if ([self respondsToSelector:selector]) 
    {
      [self performSelector:selector withObject:object];
      return YES;
    }
  
  if ([[self delegate] respondsToSelector:selector]) 
    {
      [[self delegate] performSelector:selector withObject:object];
      return YES;
    }
  
  return NO;
}

-(void)setWindowsNeedUpdate:(BOOL)value {
   _windowsNeedUpdate=value;
   NSUnimplementedMethod();
}

-(void)updateWindows {
   [_windows makeObjectsPerformSelector:@selector(update)];
}

-(void)activateIgnoringOtherApps:(BOOL)flag {
   NSUnimplementedMethod();
}

-(void)deactivate {
   NSUnimplementedMethod();
}

-(NSWindow *)modalWindow {
   return [[_modalStack lastObject] modalWindow];
}

-(NSModalSession)beginModalSessionForWindow:(NSWindow *)window {
   NSModalSessionX *session=[NSModalSessionX sessionWithWindow:window];

   [_modalStack addObject:session];

   [window _hideMenuViewIfNeeded];
   if(![window isVisible]){
    [window center];
   }
   [window makeKeyAndOrderFront:self];

   return session;
}

-(int)runModalSession:(NSModalSession)session {

   while([session stopCode]==NSRunContinuesResponse) {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSEvent           *event=[self nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate date] inMode:NSModalPanelRunLoopMode dequeue:YES];
        
    if(event==nil)
     break;
     
   NSWindow          *window=[event window];

   // in theory this could get weird, but all we want is the ESC-cancel keybinding, afaik NSApp doesn't respond to any other doCommandBySelectors...
   if([event type]==NSKeyDown && window == [session modalWindow])
       [self interpretKeyEvents:[NSArray arrayWithObject:event]];
   
   if(window==[session modalWindow] || [window worksWhenModal])
    [self sendEvent:event];
   else if([event type]==NSLeftMouseDown)
    [[session modalWindow] makeKeyAndOrderFront:self];

   [pool release];
   }

   return [session stopCode];
}

-(void)endModalSession:(NSModalSession)session {
   if(session!=[_modalStack lastObject])   
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] modal session %@ is not the current one %@",isa,sel_getName(_cmd),session,[_modalStack lastObject]];

   [[session modalWindow] _showMenuViewIfNeeded];
   [_modalStack removeLastObject];
}

-(void)stopModalWithCode:(int)code {
    // This should silently ignore any attempt to end a session when there is none.
   [[_modalStack lastObject] stopModalWithCode:code];
}

-(void)_mainThreadRunModalForWindow:(NSMutableDictionary *)values {
   NSWindow *window=[values objectForKey:@"NSWindow"];
   
   NSModalSession session=[self beginModalSessionForWindow:window];
   int result;

   while((result=[NSApp runModalSession:session])==NSRunContinuesResponse){
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
   }
   
   [self endModalSession:session];

   [values setObject:[NSNumber numberWithInteger:result] forKey:@"result"];
}

-(int)runModalForWindow:(NSWindow *)window {
   NSMutableDictionary *values=[NSMutableDictionary dictionary];
   
   [values setObject:window forKey:@"NSWindow"];
   
   [self performSelectorOnMainThread:@selector(_mainThreadRunModalForWindow:) withObject:values waitUntilDone:YES modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
   
   NSNumber *result=[values objectForKey:@"result"];
   
   return [result integerValue];
}


-(void)stopModal {
   [self stopModalWithCode:NSRunStoppedResponse];
}

-(void)abortModal {
   [self stopModalWithCode:NSRunAbortedResponse];
}

// cancel modal windows
-(void)cancel:sender {
    if ([self modalWindow] != nil)
        [self abortModal];
}

-(void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)window modalDelegate:modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
    NSSheetContext *context=[NSSheetContext sheetContextWithSheet:sheet modalDelegate:modalDelegate didEndSelector:didEndSelector contextInfo:contextInfo frame:[sheet frame]];

   [window _attachSheetContextOrderFrontAndAnimate:context];
}

-(void)endSheet:(NSWindow *)sheet returnCode:(int)returnCode {
   int count=[_windows count];

   while(--count>=0){
    NSWindow       *check=[_windows objectAtIndex:count];
    NSSheetContext *context=[check _sheetContext];
    IMP             function;
    
    if([context sheet]==sheet){
     [[context retain] autorelease];

     [check _detachSheetContextAnimateAndOrderOut];

     function=[[context modalDelegate] methodForSelector:[context didEndSelector]];
     
     if(function!=NULL)
      function([context modalDelegate],[context didEndSelector],sheet,returnCode,[context contextInfo]);

     return;
    }
   }
}

-(void)endSheet:(NSWindow *)sheet {
   [self endSheet:sheet returnCode:0];
}

-(void)reportException:(NSException *)exception {
   NSLog(@"NSApplication got exception: %@",exception);
}

-(void)_attentionTimer:(NSTimer *)timer {
   [_windows makeObjectsPerformSelector:@selector(_flashWindow)];
}

-(int)requestUserAttention:(NSRequestUserAttentionType)attentionType {
   [_attentionTimer invalidate];
   _attentionTimer=[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(_attentionTimer:) userInfo:nil repeats:YES];

   return 0;
}

-(void)cancelUserAttentionRequest:(int)requestNumber {
   NSUnimplementedMethod();
}

-(void)runPageLayout:sender {
   [[NSPageLayout pageLayout] runModal];
}

-(void)orderFrontColorPanel:(id)sender {
   [[NSColorPanel sharedColorPanel] orderFront:sender];
}

-(void)orderFrontCharacterPalette:sender {
   NSUnimplementedMethod();
}

-(void)hide:sender {//deactivates the application and hides all windows
	if (!_isHidden)
	{
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationWillHideNotification object:self];
		[_windows makeObjectsPerformSelector:@selector(_forcedHideForDeactivation)];//do no use orderOut here ist causes the application to quit if no window is visible
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationDidHideNotification object:self];
	}
	_isHidden=YES;
	
}

-(void)hideOtherApplications:sender {
   NSUnimplementedMethod();
}

-(void)unhide:sender 
{
	
	if (_isHidden)
	{
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationWillUnhideNotification object:self];
		[_windows makeObjectsPerformSelector:@selector(_showForActivation)];//only shows previously hidden windows
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationDidUnhideNotification object:self];
	}
	_isHidden=NO;
	//[self activateIgnoringOtherApps:NO]
	
}

-(void)unhideAllApplications:sender {
   NSUnimplementedMethod();
}

-(void)unhideWithoutActivation {
	if (_isHidden)
	{
		
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationWillUnhideNotification object:self];
		[_windows makeObjectsPerformSelector:@selector(_showForActivation)];//only shows previously hidden windows
		[[NSNotificationCenter defaultCenter]postNotificationName:NSApplicationDidUnhideNotification object:self];
	}
	_isHidden=NO;
}

-(void)stop:sender {
   if([_modalStack lastObject]!=nil){
    [self stopModal];
    return;
   }
   
   _isRunning=NO;
}

-(void)terminate:sender 
{
  [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self 
                                                             didCloseAllSelector:@selector(_documentController:didCloseAll:contextInfo:)
                                                                     contextInfo:NULL];
}

-(void)_documentController:(NSDocumentController *)docController didCloseAll:(BOOL)didCloseAll contextInfo:(void *)info
{
  // callback method for terminate:
  if (didCloseAll)
    {
      if ([_delegate respondsToSelector:@selector(applicationShouldTerminate:)])
        [self replyToApplicationShouldTerminate:[_delegate applicationShouldTerminate:self]];
      else
        [self replyToApplicationShouldTerminate:YES];
    }
}

-(void)replyToApplicationShouldTerminate:(BOOL)terminate 
{
  if (terminate == NSTerminateNow)
    {
      [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillTerminateNotification object:self];
      
      [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(invalidateRunningCopyPipe)];
      
      exit(0);
    }
}

-(void)replyToOpenOrPrint:(NSApplicationDelegateReply)reply {
   NSUnimplementedMethod();
}

-(void)arrangeInFront:sender {
#define CASCADE_DELTA	20		// ? isn't there a call for this?
    NSMutableArray *visibleWindows = [NSMutableArray new];
    NSRect rect=[[[NSScreen screens] objectAtIndex:0] frame], winRect;
    NSArray *windowsItems = [[self windowsMenu] itemArray];
    int i, count=[windowsItems count];

    for (i = 0 ; i < count; ++i) {
        id target = [[windowsItems objectAtIndex:i] target];

        if ([target isKindOfClass:[NSWindow class]])
            [visibleWindows addObject:target];
    }

    count = [visibleWindows count];
    if (count == 0)
        return;

    // find screen center.
    // subtract window w,h /2
    winRect = [[visibleWindows objectAtIndex:0] frame];
    rect.origin.x = (rect.size.width/2) - (winRect.size.width/2);
    rect.origin.x -= count*CASCADE_DELTA/2;
    rect.origin.x=floor(rect.origin.x);

    rect.origin.y = (rect.size.height/2) + (winRect.size.height/2);
    rect.origin.y += count*CASCADE_DELTA/2;
    rect.origin.y=floor(rect.origin.y);

    for (i = 0; i < count; ++i) {
        [[visibleWindows objectAtIndex:i] setFrameTopLeftPoint:rect.origin];
        [[visibleWindows objectAtIndex:i] orderFront:nil];

        rect.origin.x += CASCADE_DELTA;
        rect.origin.y -= CASCADE_DELTA;
    }
}

-(NSMenu *)servicesMenu {
   return [[NSApp mainMenu] _menuWithName:@"_NSServicesMenu"];
}

-(void)setServicesMenu:(NSMenu *)menu {
   NSUnimplementedMethod();
}

-servicesProvider {
   return nil;
}

-(void)setServicesProvider:provider {
}

-(void)registerServicesMenuSendTypes:(NSArray *)sendTypes returnTypes:(NSArray *)returnTypes {
   //tiredofthesewarnings NSUnsupportedMethod();
}

-validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
   NSUnimplementedMethod();
   return nil;
}


-(void)orderFrontStandardAboutPanel:sender {
   [self orderFrontStandardAboutPanelWithOptions:nil];
}

-(void)orderFrontStandardAboutPanelWithOptions:(NSDictionary *)options {
    NSSystemInfoPanel *standardAboutPanel = [[NSSystemInfoPanel 
standardAboutPanel] retain]; 
   [standardAboutPanel showInfoPanel:self withOptions:options]; 

}

-(void)activateContextHelpMode:sender {
   NSUnimplementedMethod();
}

-(void)showHelp:sender {
   NSString *helpBookFolder = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleHelpBookFolder"];
   if(helpBookFolder != nil) {
    BOOL isDir;
    NSString *folder = [[NSBundle mainBundle] pathForResource:helpBookFolder ofType:nil];
    if(folder != nil && [[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&isDir] && isDir) {
     NSString *helpBookName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleHelpBookName"];
     if(helpBookName != nil) {
      NSString *filePath = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.html", helpBookName]];
      if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
       if([[NSWorkspace sharedWorkspace] openFile:filePath withApplication:@"Help Viewer"]==YES) {
        return;
       }
      }
     }
     NSString *filePath = [folder stringByAppendingPathComponent:@"index.html"];
     if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      if([[NSWorkspace sharedWorkspace] openFile:filePath withApplication:@"Help Viewer"]==YES) {
       return;
      }
     }
    }
   }

   NSString *processName = [[NSProcessInfo processInfo] processName];
   NSAlert *alert = [[NSAlert alloc] init];
   [alert setMessageText:@"Help"];
   [alert setInformativeText:[NSString stringWithFormat:@"Help isn't available for %@.", processName]];
   [alert runModal];
   [alert release];
}

-(NSDockTile *)dockTile {
   return _dockTile;
}

- (void)doCommandBySelector:(SEL)selector {
    if ([_delegate respondsToSelector:selector])
        [_delegate performSelector:selector withObject:nil];
    else
        [super doCommandBySelector:selector];
}

-(void)_addWindow:(NSWindow *)window {
   [_windows addObject:window];
}

-(void)_windowWillBecomeActive:(NSWindow *)window {
   [_attentionTimer invalidate];
   _attentionTimer=nil;
   
   if(![self isActive]){
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillBecomeActiveNotification object:self];
   }
}

-(void)_windowDidBecomeActive:(NSWindow *)window {
   if(![self isActiveExcludingWindow:window]){
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidBecomeActiveNotification object:self];
   }
}

-(void)_windowWillBecomeDeactive:(NSWindow *)window {
   if(![self isActiveExcludingWindow:window]){
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillResignActiveNotification object:self];
   }
}

-(void)_windowDidBecomeDeactive:(NSWindow *)window {
   if(![self isActive]){
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidResignActiveNotification object:self];
   }
}
  //private method called when the application is reopened
-(void)_reopen
{
	BOOL doReopen=YES;
	if ([_delegate respondsToSelector:@selector(applicationShouldHandleReopen:hasVisibleWindows:)])
	doReopen=	[_delegate applicationShouldHandleReopen:self hasVisibleWindows:!_isHidden];
	if(!doReopen) return;
	if(_isHidden) [self unhide:nil];
	
}

@end

int NSApplicationMain(int argc, const char *argv[]) {
   NSInitializeProcess(argc,(const char **)argv);
   {
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSBundle *bundle=[NSBundle mainBundle];
    Class     class=[bundle principalClass];
    NSString *nibFile=[[bundle infoDictionary] objectForKey:@"NSMainNibFile"];

    if(class==Nil)
     class=[NSApplication class];

    [class sharedApplication];

    nibFile=[nibFile stringByDeletingPathExtension];

    if(![NSBundle loadNibNamed:nibFile owner:NSApp])
     NSLog(@"Unable to load main nib file %@",nibFile);

    [pool release];

    [NSApp run];
   }
   return 0;
}

void NSUpdateDynamicServices(void) {
   NSUnimplementedFunction();
}

BOOL NSPerformService(NSString *itemName, NSPasteboard *pasteboard) {
   NSUnimplementedFunction();
   return NO;
}

