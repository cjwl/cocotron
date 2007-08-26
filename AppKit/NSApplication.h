/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSResponder.h>
#import <AppKit/AppKitExport.h>

@class NSWindow,NSImage,NSMenu, NSPasteboard, NSDisplay;

APPKIT_EXPORT NSString *NSModalPanelRunLoopMode;
APPKIT_EXPORT NSString *NSEventTrackingRunLoopMode;

APPKIT_EXPORT NSString *NSApplicationWillFinishLaunchingNotification;
APPKIT_EXPORT NSString *NSApplicationDidFinishLaunchingNotification;

APPKIT_EXPORT NSString *NSApplicationDidBecomeActiveNotification;
APPKIT_EXPORT NSString *NSApplicationWillResignActiveNotification;

APPKIT_EXPORT id NSApp;

typedef id NSModalSession;

enum {
   NSRunStoppedResponse=-1000,
   NSRunAbortedResponse=-1001,
   NSRunContinuesResponse=-1002
};

typedef enum {
   NSTerminateCancel,
   NSTerminateNow,
} NSApplicationTerminateReply;


@interface NSApplication : NSResponder {
   NSDisplay      *_display;
   id              _delegate;
   NSMutableArray *_windows;
   NSMenu         *_mainMenu;
   NSMenu         *_windowsMenu;

   NSImage        *_applicationIconImage;

   BOOL            _isActive;
   NSEvent        *_currentEvent;

   NSMutableArray *_modalStack;
}

+(NSApplication *)sharedApplication;

-init;

-delegate;
-(NSArray *)windows;
-(NSMenu *)mainMenu;
-(NSMenu *)windowsMenu;
-(NSWindow *)mainWindow;
-(NSWindow *)keyWindow;
-(NSImage *)applicationIconImage;
-(BOOL)isActive;

-(void)setDelegate:delegate;
-(void)setMainMenu:(NSMenu *)menu;
-(void)setApplicationIconImage:(NSImage *)image;

-(void)setWindowsMenu:(NSMenu *)menu;
-(void)addWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)filename;
-(void)changeWindowsItem:(NSWindow *)window title:(NSString *)title filename:(BOOL)filename;
-(void)removeWindowsItem:(NSWindow *)window;

-(void)finishLaunching;
-(void)run;

-(void)sendEvent:(NSEvent *)event;

-(NSEvent *)nextEventMatchingMask:(unsigned int)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue;
-(NSEvent *)currentEvent;
-(void)discardEventsMatchingMask:(unsigned)mask beforeEvent:(NSEvent *)event;
-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart;

-targetForAction:(SEL)action;
-(BOOL)sendAction:(SEL)action to:target from:sender;

-(void)updateWindows;

-(void)activateIgnoringOtherApps:(BOOL)flag;

-(NSWindow *)modalWindow;
-(NSModalSession)beginModalSessionForWindow:(NSWindow *)window;
-(int)runModalSession:(NSModalSession)session;
-(void)endModalSession:(NSModalSession)session;
-(void)stopModalWithCode:(int)code;

-(int)runModalForWindow:(NSWindow *)window;
-(void)stopModal;
-(void)abortModal;

-(void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)window modalDelegate:modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;
-(void)endSheet:(NSWindow *)sheet returnCode:(int)returnCode;
-(void)endSheet:(NSWindow *)sheet;

-(void)reportException:(NSException *)exception;

-(void)runPageLayout:sender;
-(void)orderFrontColorPanel:sender;

-(void)hide:sender;
-(void)unhide:sender;
-(void)stop:sender;
-(void)terminate:sender;

-(void)arrangeInFront:sender;

-(NSMenu *)servicesMenu;
-(void)setServicesMenu:(NSMenu *)menu;
-servicesProvider;
-(void)setServicesProvider:provider;
-(void)registerServicesMenuSendTypes:(NSArray *)sendTypes returnTypes:(NSArray *)returnTypes;

-(void)orderFrontStandardAboutPanel:sender;
-(void)orderFrontStandardAboutPanelWithOptions:(NSDictionary *)options;

// private
-(void)_addWindow:(NSWindow *)window;
@end

@interface NSObject(NSApplication_serviceRequest)
-(BOOL)writeSelectionToPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types;
@end

@interface NSObject(NSApplication_notifications)
-(void)applicationWillFinishLaunching:(NSNotification *)note;
-(void)applicationDidFinishLaunching:(NSNotification *)note;
-(void)applicationDidBecomeActive:(NSNotification *)note;
@end

@interface NSObject(NSApplication_delegate)
-(BOOL)application:sender openFile:(NSString *)path;
-(BOOL)application:sender openTempFile:(NSString *)path;
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application;
@end

APPKIT_EXPORT int NSApplicationMain(int argc, const char *argv[]);

APPKIT_EXPORT void NSUpdateDynamicServices(void);
APPKIT_EXPORT BOOL NSPerformService(NSString *itemName, NSPasteboard *pasteboard);


