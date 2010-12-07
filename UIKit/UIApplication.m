#import <UIKit/UIApplication.h>
#import <UIKit/UINib.h>
#import <UIKit/UIEvent.h>

@implementation UIApplication

+(UIApplication *)sharedApplication {
   static id UIApp=nil;
   
   if(UIApp==nil){
    UIApp=[[self alloc] init]; // NSApp must be nil inside init
   }

   return UIApp;
}

-(void)reportException:(NSException *)exception {
   NSLog(@"NSApplication got exception: %@",exception);
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
   NSEvent *nextEvent=nil;
   
   do {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];

   NS_DURING
    [NSClassFromString(@"Win32RunningCopyPipe") performSelector:@selector(createRunningCopyPipe)];
    [[NSApp windows] makeObjectsPerformSelector:@selector(_makeSureIsOnAScreen)];
 
    [self _checkForReleasedWindows];
    [self _checkForAppActivation];
    [[NSApp windows] makeObjectsPerformSelector:@selector(displayIfNeeded)];

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

-(void)run {
    
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   [self finishLaunching];
   [pool release];
   
   _isRunning=YES;
   
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

int UIApplicationMain (int argc,char *argv[],NSString *applicationClassName,NSString *appDelegateClassName) {
   NSInitializeProcess(argc,(const char **)argv);
   {
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSBundle *bundle=[NSBundle mainBundle];
    Class     class=NSClassFromString(applicationClassName);
    NSString *nibName=[[bundle infoDictionary] objectForKey:@"NSMainNibFile"];
    UIApplication *app;
    
    if(class==Nil)
     class=[UIApplication class];

    app=[class sharedApplication];

    UINib *nib=[UINib nibWithNibName:nibName bundle:bundle];
    
    if(nib==nil)
     NSLog(@"Unable to load main nib file %@",nibName);

    if([nib instantiateWithOwner:app options:nil]==nil)
     NSLog(@"Unable to load main nib file %@",nibName);

    [pool release];

    [app run];
   }
   return 0;
}

@end

