/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "X11Display.h"
#import "X11Window.h"
#import <AppKit/NSScreen.h>
#import <AppKit/NSApplication.h>

@implementation X11Display

-(id)init
{
   if(self=[super init])
   {
      XInitThreads();
      _display=XOpenDisplay(NULL);
      _windowsByID=[NSMutableDictionary new];
      [self performSelector:@selector(setupEventThread) withObject:nil afterDelay:0.0];
      [[NSRunLoop currentRunLoop] addInputSource:self forMode:NSDefaultRunLoopMode];
   }
   return self;
}

-(void)dealloc
{
   XCloseDisplay(_display);
   [_windowsByID release];
   [super dealloc];
}

-(CGWindow *)windowWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
	return [[[X11Window alloc] initWithFrame:frame styleMask:styleMask isPanel:NO backingType:backingType] autorelease];
}


-(CGWindow *)panelWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
	return [[[X11Window alloc] initWithFrame:frame styleMask:styleMask isPanel:YES backingType:backingType] autorelease];
}


-(Display*)display
{
   return _display;
}

-(NSString *)menuFontNameAndSize:(float *)pointSize {
   *pointSize=12.0;
   return @"Vera";
}

-(NSArray *)screens {
   NSRect frame=NSMakeRect(0, 0,
                           DisplayWidth(_display, DefaultScreen(_display)),
                           DisplayHeight(_display, DefaultScreen(_display)));
   return [NSArray arrayWithObject:[[[NSScreen alloc] initWithFrame:frame visibleFrame:frame] autorelease]];
}

-(NSPasteboard *)pasteboardWithName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(NSDraggingManager *)draggingManager {
//   NSUnimplementedMethod();
   return nil;
}



-(NSColor *)colorWithName:(NSString *)colorName {
   
   if([colorName isEqual:@"controlColor"])
      return [NSColor lightGrayColor];
   if([colorName isEqual:@"disabledControlTextColor"])
      return [NSColor grayColor];
   if([colorName isEqual:@"controlTextColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"menuBackgroundColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"controlShadowColor"])
      return [NSColor darkGrayColor];
   if([colorName isEqual:@"selectedControlColor"])
      return [NSColor blueColor];

   
   
 //  NSLog(@"%@", colorName);
   
   return [NSColor redColor];
   
}

-(void)_addSystemColor:(NSColor *) result forName:(NSString *)colorName {
   NSUnimplementedMethod();
}

-(NSTimeInterval)textCaretBlinkInterval {
   return 1;
}

-(void)hideCursor {
   NSUnimplementedMethod();
}

-(void)unhideCursor {
   NSUnimplementedMethod();
}

// Arrow, IBeam, HorizontalResize, VerticalResize
-(id)cursorWithName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(void)setCursor:(id)cursor {
   NSUnimplementedMethod();
}

-(void)beep {
   NSUnimplementedMethod();
}

-(NSSet *)allFontFamilyNames {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)fontTypefacesForFamilyName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(float)scrollerWidth {
   NSUnimplementedMethod();
   return 0;
}

-(void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo {
   NSUnimplementedMethod();
}

-(int)runModalPrintPanelWithPrintInfoDictionary:(NSMutableDictionary *)attributes {
   NSUnimplementedMethod();
   return 0;
}

-(KGContext *)graphicsPortForPrintOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo pageRange:(NSRange)pageRange {
   NSUnimplementedMethod();
   return nil;
}

-(int)savePanel:(NSSavePanel *)savePanel runModalForDirectory:(NSString *)directory file:(NSString *)file {
   NSUnimplementedMethod();
   return 0;
}

-(int)openPanel:(NSOpenPanel *)openPanel runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types {
   NSUnimplementedMethod();
   return 0;
}

-(NSPoint)mouseLocation {
   NSUnimplementedMethod();
   return NSMakePoint(0,0);
}

-(void)setWindow:(id)window forID:(XID)i
{
   if(window)
      [_windowsByID setObject:window forKey:[NSNumber numberWithUnsignedLong:(unsigned long)i]];
   else
      [_windowsByID removeObjectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)i]];
}

-(id)windowForID:(XID)i
{
   return [_windowsByID objectForKey:[NSNumber numberWithUnsignedLong:i]];
}

-(void)handleEvent:(NSData*)data {
   XEvent e;
   [data getBytes:&e length:sizeof(XEvent)];
   
   switch(e.type) {
      case DestroyNotify:
      {
         id window=[self windowForID:e.xdestroywindow.window];
         [window invalidate];
         break;
      }
      case ConfigureNotify:
      {
         id window=[self windowForID:e.xconfigure.window];
         [window frameChanged];
         [[window delegate] platformWindow:window frameChanged:[window frame]];
         break;
      }
      case Expose:
      {
         id window=[self windowForID:e.xexpose.window];
         NSRect rect=NSMakeRect(e.xexpose.x, e.xexpose.y, e.xexpose.width, e.xexpose.height);
         [[window delegate] platformWindow:window needsDisplayInRect:[window transformFrame:rect]];
         break;
      }
      case ButtonPress:
      {
         id window=[self windowForID:e.xbutton.window];
         NSPoint pos=[window transformPoint:NSMakePoint(e.xbutton.x, e.xbutton.y)];
         id ev=[NSEvent mouseEventWithType:NSLeftMouseDown
                                  location:pos
                             modifierFlags:0
                                    window:[window delegate]
                                clickCount:1];
         [self postEvent:ev atStart:NO];
         break;
      }
      case ButtonRelease:
      {
         id window=[self windowForID:e.xbutton.window];
         NSPoint pos=[window transformPoint:NSMakePoint(e.xbutton.x, e.xbutton.y)];
         id ev=[NSEvent mouseEventWithType:NSLeftMouseUp
                                  location:pos
                             modifierFlags:0
                                    window:[window delegate]
                                clickCount:1];
         [self postEvent:ev atStart:NO];
         break;
      }
      case MotionNotify:
      {
         id window=[self windowForID:e.xmotion.window];
         NSPoint pos=[window transformPoint:NSMakePoint(e.xbutton.x, e.xbutton.y)];
         id ev=[NSEvent mouseEventWithType:NSLeftMouseDragged
                                  location:pos
                             modifierFlags:0
                                    window:[window delegate]
                                clickCount:1];
         [self postEvent:ev atStart:NO];
         break;
      }
      case ClientMessage:
      {
         id window=[self windowForID:e.xclient.window];
         if(e.xclient.format=32 &&
            e.xclient.data.l[0]==XInternAtom(_display, "WM_DELETE_WINDOW", False))
            [[window delegate] platformWindowWillClose:window];
         break;
      }
      case KeyPress:
      {
         id window=[self windowForID:e.xkey.window];
         char buf[128]={0};
         XLookupString(&e, buf, 128, NULL, NULL);
         id str=[[NSString alloc] initWithCString:buf encoding:NSISOLatin1StringEncoding];
         NSPoint pos=[window transformPoint:NSMakePoint(e.xbutton.x, e.xbutton.y)];
         
         e.xkey.state=0;
         XLookupString(&e, buf, 128, NULL, NULL);
         id strIg=[[NSString alloc] initWithCString:buf encoding:NSISOLatin1StringEncoding];
         
         id ev=[NSEvent keyEventWithType:NSKeyDown 
                                location:pos 
                           modifierFlags:0 
                                  window:[window delegate] 
                              characters:str
             charactersIgnoringModifiers:strIg
                               isARepeat:NO keyCode:e.xkey.keycode];
         [self postEvent:ev atStart:NO];
         
         [str release];
         [strIg release];
         break;
      }
      default:
         NSLog(@"type %i", e.type);
         break;
   }
}


-(void)eventThread {
   XEvent e;
   int s=DefaultScreen(_display);

   while(1) {
      id pool=[NSAutoreleasePool new];
      XNextEvent(_display, &e);
      [self performSelectorOnMainThread:@selector(handleEvent:)
                             withObject:[NSData dataWithBytes:&e 
                                                       length:sizeof(XEvent)]
                          waitUntilDone:YES
                                  modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil]];
      [pool drain];
   }
}


-(void)setupEventThread {
   [NSThread detachNewThreadSelector:@selector(eventThread) toTarget:self withObject:nil];  
}

-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart {
   [super postEvent:event atStart:atStart];
   [[NSPlatform currentPlatform] cancelForRunloopMode:[[NSRunLoop currentRunLoop] currentMode]];
}

@end
