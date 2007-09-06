/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// "Window" menu - David Young <daver@geeks.org>
// Original - Christopher Lloyd <cjwl@objc.net>
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
#import <AppKit/NSPlatform.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSSheetContext.h>

NSString *NSModalPanelRunLoopMode=@"NSModalPanelRunLoopMode";
NSString *NSEventTrackingRunLoopMode=@"NSEventTrackingRunLoopMode";

NSString *NSApplicationWillFinishLaunchingNotification=@"NSApplicationWillFinishLaunchingNotification";
NSString *NSApplicationDidFinishLaunchingNotification=@"NSApplicationDidFinishLaunchingNotification";

NSString *NSApplicationDidBecomeActiveNotification=@"NSApplicationDidBecomeActiveNotification";
NSString *NSApplicationWillResignActiveNotification=@"NSApplicationWillResignActiveNotification";

@implementation NSApplication

id NSApp=nil;

+(void)initialize {
   if(self==[NSApplication class]){
#ifdef WINDOWS
    Win32UseRunningCopyOfApplication();
#endif
   }
}

+(NSApplication *)sharedApplication {

   if(NSApp==nil){
    NSApp=[self alloc]; // NSApp must be valid inside init
    NSApp=[NSApp init];
   }

   return NSApp;
}

-init {
   _display=[[NSDisplay currentDisplay] retain];
   [_display showSplashImage];

   _windows=[NSMutableArray new];
   _mainMenu=nil;

   _modalStack=[NSMutableArray new];

   return self;
}

-delegate {
   return _delegate;
}

-(NSArray *)windows {
   return _windows;
}

-(NSMenu *)mainMenu {
   return _mainMenu;
}

-(NSMenu *)menu {
  return [self mainMenu];
}


-(NSMenu *)windowsMenu {
   if(_windowsMenu==nil)
    _windowsMenu=[[NSApp mainMenu] _menuWithName:@"_NSWindowsMenu"];
 
    return _windowsMenu;
}

-(NSWindow *)mainWindow {
   int i,count=[_windows count];

   for(i=0;i<count;i++)
    if([[_windows objectAtIndex:i] isMainWindow])
     return [_windows objectAtIndex:i];

   return nil;
}

-(NSWindow *)keyWindow {
   int i,count=[_windows count];

   for(i=0;i<count;i++)
    if([[_windows objectAtIndex:i] isKeyWindow])
     return [_windows objectAtIndex:i];

   return nil;
}

-(NSImage *)applicationIconImage {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)isActive {
   int count=[_windows count];

   while(--count>=0){
    NSWindow *check=[_windows objectAtIndex:count];

    if([check _isActive])
     return YES;
   }

   return NO;
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
   NSUnimplementedMethod();
}

-(void)setWindowsMenu:(NSMenu *)menu {
//NSLog(@"%s %@",SELNAME(_cmd),menu);
   [_windowsMenu autorelease];
   _windowsMenu=[menu retain];
}

-(void)addWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)isFilename {
    NSMenuItem *windowItem;
    
    if ([[self windowsMenu] indexOfItemWithTarget:window andAction:@selector(makeKeyAndOrderFront:)] != -1)
        return;

    // separator management... shouldn't +separatorItem be a singleton? i dunno..
    // e.g. here, lastObject] == [NSMenuItem separatorItem] ?
    windowItem = [[[self windowsMenu] itemArray] lastObject];
    if ([windowItem title] != nil && ![[windowItem target] isKindOfClass:[NSWindow class]])
        [[self windowsMenu] addItem:[NSMenuItem separatorItem]];

    if (isFilename)
        title = [NSString stringWithFormat:@"%@  --  %@", [title lastPathComponent],
            [title stringByDeletingLastPathComponent]];

    windowItem = [[[NSMenuItem alloc] initWithTitle:title
                                             action:@selector(makeKeyAndOrderFront:)
                                      keyEquivalent:@""] autorelease];
    [windowItem setTarget:window];

    [[self windowsMenu] addItem:windowItem];
    //NSLog(@"add: %@ %@ %@", [self windowsMenu], title, windowItem);
}

-(void)changeWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)isFilename {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:window
                                                    andAction:@selector(makeKeyAndOrderFront:)];

    if (itemIndex != -1) {
        NSMenuItem *windowItem = [[self windowsMenu] itemAtIndex:itemIndex];

        if (isFilename)
            title = [NSString stringWithFormat:@"%@  --  %@",
                [title lastPathComponent], [title stringByDeletingLastPathComponent]];

        [windowItem setTitle:title];
        [[self windowsMenu] itemChanged:windowItem];
    }
    else
        [self addWindowsItem:window title:title filename:isFilename];
}

-(void)removeWindowsItem:(NSWindow *)window {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:window
                                                    andAction:@selector(makeKeyAndOrderFront:)];
    if (itemIndex != -1) {
        [[self windowsMenu] removeItemAtIndex:itemIndex];

        // separator
        if ([[[[self windowsMenu] itemArray] lastObject] title] == nil)
            [[self windowsMenu] removeItem:[[[self windowsMenu] itemArray] lastObject]];
    }
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

   [_display closeSplashImage];

   if(_delegate==nil){
    id types=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDocumentTypes"];

    if([types count]>0)
     _delegate=[NSDocumentController sharedDocumentController];
   }

   if([_delegate respondsToSelector:@selector(application:openFile:)]){
    NSString *openFile=[[NSUserDefaults standardUserDefaults] stringForKey:@"NSOpen"];

    if([openFile length]>0){
     if([_delegate application:self openFile:openFile])
      needsUntitled=NO;
    }
   }

   if(needsUntitled && [_delegate isKindOfClass:[NSDocumentController class]])
    [_delegate newDocument:self];

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

    if([check retainCount]==1)
     [_windows removeObjectAtIndex:count];
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

   [self finishLaunching];

   do {
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSEvent           *event;

    //OBJCReportStatistics();

    event=[self nextEventMatchingMask:NSAnyEventMask
     untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];

    NS_DURING
     [self sendEvent:event];

    NS_HANDLER
     [self reportException:localException];
    NS_ENDHANDLER

    [self _checkForReleasedWindows];
    [self _checkForTerminate];

    [pool release];
   }while(YES);
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

-(NSEvent *)nextEventMatchingMask:(unsigned int)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   NSEvent           *nextEvent;

   NS_DURING
    [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(createRunningCopyPipe)];
    [[NSApp windows] makeObjectsPerformSelector:@selector(_makeSureIsOnAScreen)];
 
    [self _checkForReleasedWindows];
    [self _checkForAppActivation];
    [[NSApp windows] makeObjectsPerformSelector:@selector(displayIfNeeded)];

    nextEvent=[_display nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue];

    [_currentEvent release];
    _currentEvent=[nextEvent retain];
   NS_HANDLER
    [self reportException:localException];
   NS_ENDHANDLER

   [pool release];

   return [[_currentEvent retain] autorelease];
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

-targetForAction:(SEL)action {
   NSWindow    *window;
   NSResponder *check;

   window=[self keyWindow];

   for(check=[window firstResponder];check!=nil;check=[check nextResponder]){
    if([check respondsToSelector:action])
     return check;
   }

   if([window respondsToSelector:action])
    return window;

   if([[window delegate] respondsToSelector:action])
    return [window delegate];

   window=[self mainWindow];

   for(check=[window firstResponder];check!=nil;check=[check nextResponder]){
    if([check respondsToSelector:action])
     return check;
   }

   if([window respondsToSelector:action])
    return window;

   if([[window delegate] respondsToSelector:action])
    return [window delegate];

   if([self respondsToSelector:action])
    return self;

   if([[self delegate] respondsToSelector:action])
    return [self delegate];

   return nil;
}

-(BOOL)sendAction:(SEL)action to:target from:sender {

//NSLog(@"%s %s %@ %@",SELNAME(_cmd),action,target,sender);

   if(target!=nil){
    if([target respondsToSelector:action]){
     [target performSelector:action withObject:sender];
     return YES;
    }
   }
   else if((target=[self targetForAction:action])!=nil){
    [target performSelector:action withObject:sender];
    return YES;
   }

   return NO;
}

-(void)updateWindows {
   [_windows makeObjectsPerformSelector:@selector(update)];
}

-(void)activateIgnoringOtherApps:(BOOL)flag {
   NSUnimplementedMethod();
}

-(NSWindow *)modalWindow {
   return [[_modalStack lastObject] modalWindow];
}

-(NSModalSession)beginModalSessionForWindow:(NSWindow *)window {
   NSModalSessionX *session=[NSModalSessionX sessionWithWindow:window];

   [_modalStack addObject:session];

   [window center];
   [window makeKeyAndOrderFront:self];

   return session;
}

-(int)runModalSession:(NSModalSession)session {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   NSDate            *future=[NSDate distantFuture];
   NSEvent           *event=[self nextEventMatchingMask:NSAnyEventMask
      untilDate:future inMode:NSModalPanelRunLoopMode dequeue:YES];
   NSWindow          *window=[event window];

   // in theory this could get weird, but all we want is the ESC-cancel keybinding, afaik NSApp doesn't respond to any other doCommandBySelectors...
   if([event type]==NSKeyDown && window == [session modalWindow])
       [self interpretKeyEvents:[NSArray arrayWithObject:event]];
   
   if(window==[session modalWindow] || [window worksWhenModal])
    [self sendEvent:event];
   else if([event type]==NSLeftMouseDown)
    [[session modalWindow] makeKeyAndOrderFront:self];

   [pool release];

   return [session stopCode];
}

-(void)endModalSession:(NSModalSession)session {
   [_modalStack removeLastObject];
}

-(void)stopModalWithCode:(int)code {
   if([_modalStack lastObject]==nil)
    [NSException raise:NSInvalidArgumentException
                format:@"-[%@ %s] no modal session running",isa,SELNAME(_cmd)];

   [[_modalStack lastObject] stopModalWithCode:code];
}

-(int)runModalForWindow:(NSWindow *)window {
   NSModalSession session=[self beginModalSessionForWindow:window];
   int result;


   while((result=[NSApp runModalSession:session])==NSRunContinuesResponse)
    ;

   [self endModalSession:session];

   return result;
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
//    // Hmmm
#if 1
    if ([sheet styleMask] != NSDocModalWindowMask)
        [sheet _setStyleMask:NSDocModalWindowMask];
#endif
//    if ([sheet styleMask] != NSBorderlessWindowMask)
//        [sheet _setStyleMask:NSBorderlessWindowMask];
   
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

     function=objc_msg_lookup([context modalDelegate],[context didEndSelector]);
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

-(void)runPageLayout:sender {
   [[NSPageLayout pageLayout] runModal];
}

-(void)orderFrontColorPanel:(id)sender {
   [[NSColorPanel sharedColorPanel] orderFront:sender];
}

-(void)hide:sender {
   NSUnimplementedMethod();
}

-(void)unhide:sender {
   NSUnimplementedMethod();
}

-(void)stop:sender {
   NSUnimplementedMethod();
}

-(void)terminate:sender {
   if([_delegate respondsToSelector:@selector(applicationShouldTerminate:)]){
    if(![_delegate applicationShouldTerminate:self]){
     return;
    }
   }

   [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(invalidateRunningCopyPipe)];

   exit(0);
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

-(void)showHelp:sender {
   NSUnimplementedMethod();
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

-(void)orderFrontStandardAboutPanel:sender {
   [self orderFrontStandardAboutPanelWithOptions:nil];
}

-(void)orderFrontStandardAboutPanelWithOptions:(NSDictionary *)options {
   NSUnimplementedMethod();
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

