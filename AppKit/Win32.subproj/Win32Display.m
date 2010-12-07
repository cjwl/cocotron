/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/Win32Display.h>
#import <AppKit/Win32Event.h>
#import <AppKit/Win32Window.h>
#import <AppKit/Win32Cursor.h>
#import <AppKit/O2Context_gdi.h>
#import <AppKit/Win32DeviceContextWindow.h>
#import <Onyx2D/O2GraphicsState.h>
#import <AppKit/Win32EventInputSource.h>

#import <AppKit/NSScreen.h>
#import <AppKit/NSEvent_CoreGraphics.h>
#import <AppKit/NSGraphicsContext.h>

#import <AppKit/Win32GeneralPasteboard.h>
#import <AppKit/Win32Pasteboard.h>
#import <Foundation/NSSet.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColor_CGColor.h>
#import <Onyx2D/O2ColorSpace.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSSavePanel-Win32.h>
#import <AppKit/NSOpenPanel-Win32.h>
#import <windows.h>
#import <windowsx.h>
#import <winuser.h>
#import <commdlg.h>
#import <malloc.h>

#import <AppKit/NSFontTypeface.h>
#import <AppKit/NSFontMetric.h>

@implementation NSDisplay(windows)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([Win32Display class],0,NULL);
}

@end

@implementation Win32Display

//#define WAITCURSOR

#ifdef WAITCURSOR

static DWORD   mainThreadId;
static HANDLE  waitCursorStop;
static HANDLE  waitCursorStart;
static HCURSOR waitCursorHandle;

static DWORD WINAPI runWaitCursor(LPVOID arg){
   waitCursorHandle=LoadCursor(NULL,IDC_WAIT);

   AttachThreadInput(GetCurrentThreadId(),mainThreadId,TRUE);

   while(YES){
    WaitForSingleObject(waitCursorStart,INFINITE);

    if(WaitForSingleObject(waitCursorStop,500)==WAIT_TIMEOUT){
     SetCursor(waitCursorHandle);

     WaitForSingleObject(waitCursorStop,INFINITE);
    }
   }
}
#endif

+(void)initialize {
   if(self==[Win32Display class]){
#ifdef WAITCURSOR
    mainThreadId=GetCurrentThreadId();
    waitCursorStop=CreateEvent(NULL,FALSE,FALSE,NULL);
    waitCursorStart=CreateEvent(NULL,FALSE,FALSE,NULL);
    CreateThread(NULL,0,runWaitCursor,0,0,&threadID);
#endif
   }
}

+(Win32Display *)currentDisplay {
   return (Win32Display *)[super currentDisplay];
}

-(void)loadPrivateFontPaths:(NSArray *)paths {
   for(NSString *path in paths){
    const uint16_t *rep=[path fileSystemRepresentationW];
#if 0
    typedef WINGDIAPI int WINAPI (*ftype)(LPCWSTR);

    HANDLE library=LoadLibrary("GDI32");
    
    ftype  function=(ftype)GetProcAddress(library,"AddFontResourceW");
    if(function==NULL)
     NSLog(@"GetProcAddress(\"GDI32\",\"AddFontResourceW\") failed");
    else {
     if(function(rep)==0){
      NSLog(@"AddFontResourceW failed for %@",path);
     }
    }
#else
#ifndef FR_PRIVATE
#define FR_PRIVATE 0x10
#endif
    typedef WINGDIAPI int WINAPI (*ftype)(LPCWSTR,DWORD,PVOID);

    HANDLE library=LoadLibrary("GDI32");
    
    ftype  function=(ftype)GetProcAddress(library,"AddFontResourceExW");
    if(function==NULL)
     NSLog(@"GetProcAddress(\"GDI32\",\"AddFontResourceExW\") failed");
    else {
     if(function(rep,FR_PRIVATE,0)==0){
      NSLog(@"AddFontResourceExW failed for %@",path);
     }
    }
#endif
   }
}

-(void)loadPrivateFonts {
  NSArray *ttf=[[NSBundle mainBundle] pathsForResourcesOfType:@"ttf" inDirectory:nil];

  [self loadPrivateFontPaths:ttf];
}

-(id)init {
   self=[super init];
   if (self!=nil){
    _eventInputSource=[Win32EventInputSource new];

    _generalPasteboard=nil;
    _pasteboards=[NSMutableDictionary new];

    _nameToColor=[NSMutableDictionary new];

    _cursorDisplayCount=1;
    _cursorCache=[NSMutableDictionary new];
	_pastLocation = NSMakePoint(FLT_MAX, FLT_MAX);
    
    [self loadPrivateFonts];
   }
   return self;
}

static BOOL CALLBACK monitorEnumerator(HMONITOR hMonitor,HDC hdcMonitor,LPRECT rect,LPARAM dwData) {
	static FARPROC  getMonitorInfo = NULL;
	
	if (NULL == getMonitorInfo) {
		HANDLE library = LoadLibrary("USER32");
		getMonitorInfo = GetProcAddress(library,"GetMonitorInfoA");
	}

	NSMutableArray *array= (id)dwData;
  
	MONITORINFOEX info;
	info.cbSize = sizeof(info);
	getMonitorInfo(hMonitor,&info);
	
	NSRect frame = CGRectFromRECT( info.rcMonitor );
	NSRect visibleFrame = CGRectFromRECT( info.rcWork );

	CGFloat bottom = GetSystemMetrics( SM_YVIRTUALSCREEN ) + GetSystemMetrics( SM_CYVIRTUALSCREEN );
	frame.origin.y = bottom - (frame.origin.y + frame.size.height);
	visibleFrame.origin.y = bottom - (visibleFrame.origin.y + visibleFrame.size.height);

	NSScreen *screen=[[[NSScreen alloc] initWithFrame:frame visibleFrame:visibleFrame] autorelease];

   if (info.dwFlags & MONITORINFOF_PRIMARY) [array insertObject:screen atIndex:0];
   else [array addObject:screen];

   return TRUE;
}

-(NSArray *)screens {
	static FARPROC enumDisplayMonitors = NULL;
	if (NULL == enumDisplayMonitors) {
		HANDLE  library = LoadLibrary( "USER32" );
		enumDisplayMonitors = GetProcAddress(library,"EnumDisplayMonitors");
	}
	
	if(enumDisplayMonitors != NULL){
		NSMutableArray *result = [NSMutableArray array];
		enumDisplayMonitors( NULL, NULL, monitorEnumerator, result );
		return result;
	} else {
		NSRect frame=NSMakeRect(0,0,GetSystemMetrics(SM_CXSCREEN),GetSystemMetrics(SM_CYSCREEN));

		return [NSArray arrayWithObject:[[[NSScreen alloc] initWithFrame:frame visibleFrame:frame] autorelease]];
   }
}

-(NSPasteboard *)pasteboardWithName:(NSString *)name {
   if([name isEqualToString:NSGeneralPboard]){
    if(_generalPasteboard==nil)
     _generalPasteboard=[[Win32GeneralPasteboard alloc] init];

    return _generalPasteboard;
   }
   else if([name isEqualToString:NSDragPboard])
    return [[[Win32Pasteboard alloc] init] autorelease];
   else {
    NSPasteboard *result=[_pasteboards objectForKey:name];

    if(result==nil){
     result=[[[Win32Pasteboard alloc] init] autorelease];
     [_pasteboards setObject:result forKey:name];
    }

    return result;
   }
}

-(NSDraggingManager *)draggingManager {
   return NSThreadSharedInstance(@"Win32DraggingManager");
}

-(CGWindow *)windowWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
   return [[[Win32Window alloc] initWithFrame:frame styleMask:styleMask isPanel:NO backingType:backingType] autorelease];
}

-(CGWindow *)panelWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
   return [[[Win32Window alloc] initWithFrame:frame styleMask:styleMask isPanel:YES backingType:backingType] autorelease];
}

-(void)invalidateSystemColors {
   [_nameToColor removeAllObjects];
}

-(void)buildSystemColors {
   struct {
    NSString *name;
    int       value;
   } table[]={
    { @"controlBackgroundColor", COLOR_WINDOW },
    { @"controlColor", COLOR_3DFACE },
    { @"controlDarkShadowColor", COLOR_3DDKSHADOW },
    { @"controlHighlightColor", COLOR_3DLIGHT },
    { @"controlLightHighlightColor", COLOR_3DHILIGHT },
    { @"controlShadowColor", COLOR_3DSHADOW },
    { @"controlTextColor", COLOR_BTNTEXT },
  //  { @"disabledControlTextColor", COLOR_3DSHADOW },
    { @"disabledControlTextColor", COLOR_GRAYTEXT },
    { @"highlightColor", COLOR_3DHILIGHT },
    { @"knobColor", COLOR_3DFACE },
    { @"scrollBarColor", COLOR_SCROLLBAR },
    { @"selectedControlColor", COLOR_HIGHLIGHT },
    { @"selectedControlTextColor", COLOR_HIGHLIGHTTEXT },
    { @"selectedKnobColor", COLOR_HIGHLIGHT },
    { @"selectedTextBackgroundColor", COLOR_HIGHLIGHT },
    { @"selectedTextColor", COLOR_HIGHLIGHTTEXT },
    { @"shadowColor", COLOR_3DDKSHADOW },
    { @"textBackgroundColor", COLOR_WINDOW },
    { @"textColor", COLOR_WINDOWTEXT },
    { @"gridColor", COLOR_INACTIVEBORDER },		// what should this be?
    { @"headerColor", COLOR_3DFACE },		// these do not appear in the user-space System color list,
    { @"headerTextColor", COLOR_BTNTEXT },	// probably because Apple builds that off System.clr
   { @"alternateSelectedControlColor", COLOR_WINDOW }, // FIXME:
   { @"alternateSelectedControlTextColor", COLOR_WINDOWTEXT }, // FIXME:
   { @"secondarySelectedControlColor", COLOR_HIGHLIGHT }, // FIXME:
   { @"keyboardFocusIndicatorColor", COLOR_ACTIVEBORDER }, // FIXME:
   { @"windowFrameColor", COLOR_WINDOWFRAME }, // FIXME:
   { @"selectedMenuItemColor", 29 /* COLOR_MENUHILIGHT */ }, // FIXME:
   { @"selectedMenuItemTextColor", COLOR_HIGHLIGHTTEXT }, // FIXME:
// extensions
    { @"menuBackgroundColor", COLOR_MENU },
	{ @"mainMenuBarColor", 30 },
    { @"menuItemTextColor", COLOR_MENUTEXT },
     { @"_sourceListBackgroundColor", COLOR_WINDOW },
 
    { nil, 0 }
   };
   int i;
   CGColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithPlatformRGB];

   for(i=0;table[i].name!=nil;i++){
    LOGBRUSH   contents;
    CGColorRef colorRef;
    CGFloat    components[4];
    NSColor   *color;

    GetObject(GetSysColorBrush(table[i].value),sizeof(LOGBRUSH),&contents);

    components[0]=GetRValue(contents.lbColor)/255.0;
    components[1]=GetGValue(contents.lbColor)/255.0;
    components[2]=GetBValue(contents.lbColor)/255.0;
    components[3]=1;
    
    colorRef=CGColorCreate(colorSpace,components);

    color=[NSColor_CGColor colorWithColorRef:colorRef spaceName:NSDeviceRGBColorSpace];
    CGColorRelease(colorRef);
    [_nameToColor setObject:color forKey:table[i].name];
   }
   
   CGColorSpaceRelease(colorSpace);
}

-(NSColor *)colorWithName:(NSString *)colorName {
   if([_nameToColor count]==0)
    [self buildSystemColors];

   return [_nameToColor objectForKey:colorName];
}

-(void) _addSystemColor: (NSColor *) color forName: (NSString *) name {
   if([_nameToColor count]==0)
    [self buildSystemColors];
   [_nameToColor setObject: color forKey: name];
}

-(NSTimeInterval)textCaretBlinkInterval {
   return ((float)GetCaretBlinkTime())/1000.0;
}

-(void)hideCursor {
   _cursorDisplayCount=ShowCursor(FALSE);
}

-(void)unhideCursor {
   _cursorDisplayCount=ShowCursor(TRUE);
}

-(void)_unhideCursorForMouseMove {
   while(_cursorDisplayCount<=0)
    [self unhideCursor];
}

-cursorWithName:(NSString *)name {
   id result=[_cursorCache objectForKey:name];

   if(result==nil){
    result=[[[Win32Cursor alloc] initWithName:name] autorelease];
    [_cursorCache setObject:result forKey:name];
   }

   return result;
}

-(void)setCursor:(id)cursor {
   HCURSOR handle=[cursor cursorHandle];
   // HCURSOR current=GetCursor();

   [_cursor autorelease];
   _cursor=[cursor retain];

 //  if(current!=handle)
    SetCursor(_lastCursor=handle);
}

-(void)stopWaitCursor {
#ifdef WAITCURSOR
   SetEvent(waitCursorStop);

   if(_lastCursor!=NULL)
    SetCursor(_lastCursor);
   else {
    POINT pt;
    GetCursorPos(&pt);
    SetCursorPos(pt.x, pt.y);
  //  _lastCursor=GetCursor();
   }
#endif
}

-(void)startWaitCursor {
#ifdef WAITCURSOR
   ResetEvent(waitCursorStop);
   SetEvent(waitCursorStart);
#endif
}

-(NSEvent *)nextEventMatchingMask:(unsigned)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue {
   NSEvent *result;

   [[NSRunLoop currentRunLoop] addInputSource:_eventInputSource forMode:mode];
   [self stopWaitCursor];
   result=[super nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue];
   [self startWaitCursor];
   [[NSRunLoop currentRunLoop] removeInputSource:_eventInputSource forMode:mode];

   return result;
}

/* Windows does not use different scan codes for keypad keys, there is a seperate bit in lParam to distinguish this. YellowBox does not pass this extra bit of information on via NSEvent which is a real nuisance if you actually need it. This remaps the extended keys to the keyCode's used on NEXTSTEP/OPENSTEP.

The values should be upgraded to something which is more generic to implement, perhaps passing the windows values through.
 
 */
// FIX
-(unsigned)keyCodeForLParam:(LPARAM)lParam isKeypad:(BOOL *)isKeypad{
   unsigned keyCode=(lParam>>16)&0xFF;

   *isKeypad=NO;

   if(lParam&0x01000000){
    *isKeypad=YES;

    switch(keyCode){
     case 0x35: keyCode=0x63; break; // /
     case 0x1C: keyCode=0x62; break; // Enter

     case 0x52: keyCode=0x68; break; // Insert
     case 0x47: keyCode=0x6C; break; // Home
     case 0x49: keyCode=0x6A; break; // PageUp

     case 0x53: keyCode=0x69; break; // Delete
     case 0x4F: keyCode=0x6D; break; // End
     case 0x51: keyCode=0x6b; break; // PageDown

     case 0x48: keyCode=0x64; break; // Up
     case 0x4B: keyCode=0x66; break; // Left
     case 0x50: keyCode=0x65; break; // Down
     case 0x4D: keyCode=0x67; break; // Right

     case 0x38: keyCode=0x61; break; // Right Alternate
     case 0x1D: keyCode=0x60; break; // Right Control
    }
   }

   return keyCode;
}

-(BOOL)postKeyboardMSG:(MSG)msg type:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window {
   unichar        buffer[256],ignoringBuffer[256];
   NSString      *characters;
   NSString      *charactersIgnoringModifiers;
   BOOL           isARepeat=NO;
   unsigned short keyCode;
   int            bufferSize=0,ignoringBufferSize=0;
   BYTE           keyState[256];

   GetKeyboardState(keyState);
   bufferSize=ToUnicode(msg.wParam,msg.lParam>>16,keyState,buffer,256,0);

   keyState[VK_CONTROL]=0x00;
   keyState[VK_LCONTROL]=0x00;
   keyState[VK_RCONTROL]=0x00;
   keyState[VK_CAPITAL]=0x00;

   keyState[VK_MENU]=0x00;
   keyState[VK_LMENU]=0x00;
   keyState[VK_RMENU]=0x00;
   ignoringBufferSize=ToUnicode(msg.wParam,msg.lParam>>16,keyState,ignoringBuffer,256,0);

   if(bufferSize==0){

    switch(msg.wParam){
     case VK_LBUTTON: break;
     case VK_RBUTTON: break;
     case VK_CANCEL:  break;
     case VK_MBUTTON: break;

     case VK_BACK:    break;
     case VK_TAB:     buffer[bufferSize++]='\t';                     break;

     case VK_CLEAR:   buffer[bufferSize++]=NSClearDisplayFunctionKey;break;
     case VK_RETURN:  break;

     case VK_SHIFT:
     case VK_CONTROL:
     case VK_MENU:
      buffer[bufferSize++]=' '; // lame
      type=NSFlagsChanged;
      break;

     case VK_PAUSE:    buffer[bufferSize++]=NSPauseFunctionKey;       break;
     case VK_CAPITAL:  break;

     case VK_ESCAPE:   buffer[bufferSize++]='\x1B';                   break;
     case VK_SPACE:    buffer[bufferSize++]=' ';                      break;
     case VK_PRIOR:    buffer[bufferSize++]=NSPageUpFunctionKey;      break;
     case VK_NEXT:     buffer[bufferSize++]=NSPageDownFunctionKey;    break;
     case VK_END:      buffer[bufferSize++]=NSEndFunctionKey;         break;
     case VK_HOME:     buffer[bufferSize++]=NSHomeFunctionKey;        break;
     case VK_LEFT:     buffer[bufferSize++]=NSLeftArrowFunctionKey;   break;
     case VK_UP:       buffer[bufferSize++]=NSUpArrowFunctionKey;     break;
     case VK_RIGHT:    buffer[bufferSize++]=NSRightArrowFunctionKey;  break;
     case VK_DOWN:     buffer[bufferSize++]=NSDownArrowFunctionKey;   break;
     case VK_SELECT:   buffer[bufferSize++]=NSSelectFunctionKey;      break;
     case VK_PRINT:    buffer[bufferSize++]=NSPrintFunctionKey;       break;
     case VK_EXECUTE:  buffer[bufferSize++]=NSExecuteFunctionKey;     break;
     case VK_SNAPSHOT: buffer[bufferSize++]=NSPrintScreenFunctionKey; break;
     case VK_INSERT:   buffer[bufferSize++]=NSInsertFunctionKey;      break;
     case VK_DELETE:   buffer[bufferSize++]=NSDeleteFunctionKey;      break;
     case VK_HELP:     buffer[bufferSize++]=NSHelpFunctionKey;        break;

     case '0': case '1': case '2': case '3': case '4':
     case '5': case '6': case '7': case '8': case '9':
      buffer[bufferSize++]=msg.wParam;
      break;

     case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': 
     case 'G': case 'H': case 'I': case 'J': case 'K': case 'L': 
     case 'M': case 'N': case 'O': case 'P': case 'Q': case 'R': 
     case 'S': case 'T': case 'U': case 'V': case 'W': case 'X': 
     case 'Y': case 'Z':
      buffer[bufferSize++]=msg.wParam;
      break;
 
     case VK_LWIN:     break;
     case VK_RWIN:     break;
     case VK_APPS:     break;

     case VK_NUMPAD0:  buffer[bufferSize++]='0'; break;
     case VK_NUMPAD1:  buffer[bufferSize++]='1'; break;
     case VK_NUMPAD2:  buffer[bufferSize++]='2'; break;
     case VK_NUMPAD3:  buffer[bufferSize++]='3'; break;
     case VK_NUMPAD4:  buffer[bufferSize++]='4'; break;
     case VK_NUMPAD5:  buffer[bufferSize++]='5'; break;
     case VK_NUMPAD6:  buffer[bufferSize++]='6'; break;
     case VK_NUMPAD7:  buffer[bufferSize++]='7'; break;
     case VK_NUMPAD8:  buffer[bufferSize++]='8'; break;
     case VK_NUMPAD9:  buffer[bufferSize++]='9'; break;
     case VK_MULTIPLY: buffer[bufferSize++]='*'; break;
     case VK_ADD:      buffer[bufferSize++]='+'; break;
     case VK_SEPARATOR:break;
     case VK_SUBTRACT: break;
     case VK_DECIMAL:  break;
     case VK_DIVIDE:   break;

     case VK_F1:       buffer[bufferSize++]=NSF1FunctionKey; break;
     case VK_F2:       buffer[bufferSize++]=NSF2FunctionKey; break;
     case VK_F3:       buffer[bufferSize++]=NSF3FunctionKey; break;
     case VK_F4:       buffer[bufferSize++]=NSF4FunctionKey; break;
     case VK_F5:       buffer[bufferSize++]=NSF5FunctionKey; break;
     case VK_F6:       buffer[bufferSize++]=NSF6FunctionKey; break;
     case VK_F7:       buffer[bufferSize++]=NSF7FunctionKey; break;
     case VK_F8:       buffer[bufferSize++]=NSF8FunctionKey; break;
     case VK_F9:       buffer[bufferSize++]=NSF9FunctionKey; break;
     case VK_F10:      buffer[bufferSize++]=NSF10FunctionKey; break;
     case VK_F11:      buffer[bufferSize++]=NSF11FunctionKey; break;
     case VK_F12:      buffer[bufferSize++]=NSF12FunctionKey; break;
     case VK_F13:      buffer[bufferSize++]=NSF13FunctionKey; break;
     case VK_F14:      buffer[bufferSize++]=NSF14FunctionKey; break;
     case VK_F15:      buffer[bufferSize++]=NSF15FunctionKey; break;
     case VK_F16:      buffer[bufferSize++]=NSF16FunctionKey; break;
     case VK_F17:      buffer[bufferSize++]=NSF17FunctionKey; break;
     case VK_F18:      buffer[bufferSize++]=NSF18FunctionKey; break;
     case VK_F19:      buffer[bufferSize++]=NSF19FunctionKey; break;
     case VK_F20:      buffer[bufferSize++]=NSF20FunctionKey; break;
     case VK_F21:      buffer[bufferSize++]=NSF21FunctionKey; break;
     case VK_F22:      buffer[bufferSize++]=NSF22FunctionKey; break;
     case VK_F23:      buffer[bufferSize++]=NSF23FunctionKey; break;
     case VK_F24:      buffer[bufferSize++]=NSF24FunctionKey; break;

     case VK_NUMLOCK:  break;
     case VK_SCROLL:   buffer[bufferSize++]=NSScrollLockFunctionKey; break;

/* these constants are only useful with GetKeyboardState 
     case VK_LSHIFT:   NSLog(@"VK_LSHIFT"); break;
     case VK_RSHIFT:   NSLog(@"VK_RSHIFT"); break;
     case VK_LCONTROL: NSLog(@"VK_LCONTROL"); break;
     case VK_RCONTROL: NSLog(@"VK_RCONTROL"); break;
     case VK_LMENU:    NSLog(@"VK_LMENU"); break;
     case VK_RMENU:    NSLog(@"VK_RMENU"); break;
 */

     case VK_ATTN: break;
     case VK_CRSEL: break;
     case VK_EXSEL: break;
     case VK_EREOF: break;
     case VK_PLAY: break;
     case VK_ZOOM: break;
     case VK_NONAME: break;
     case VK_PA1: break;
     case VK_OEM_CLEAR: break;
    }

   }

   if(ignoringBufferSize==0)
    for(ignoringBufferSize=0;ignoringBufferSize<bufferSize;ignoringBufferSize++)
     ignoringBuffer[ignoringBufferSize]=buffer[ignoringBufferSize];
   
   if(bufferSize>0){
    NSEvent *event;
    BOOL     isKeypad;

    characters=[NSString stringWithCharacters:buffer length:bufferSize];
    charactersIgnoringModifiers=[NSString stringWithCharacters:ignoringBuffer length:ignoringBufferSize];

    keyCode=[self keyCodeForLParam:msg.lParam isKeypad:&isKeypad];
    if(isKeypad)
     modifierFlags|=NSNumericPadKeyMask;

    event=[NSEvent keyEventWithType:type location:location modifierFlags:modifierFlags timestamp:[NSDate timeIntervalSinceReferenceDate] windowNumber:[window windowNumber] context:nil characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:keyCode];
    [self postEvent:event atStart:NO];
    return YES;
   }

   return NO;
}

-(BOOL)postMouseMSG:(MSG)msg type:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window {
	NSEvent *event;

	if (((type == NSLeftMouseDragged) || (type == NSRightMouseDragged)) && (_pastLocation.x != FLT_MAX))
		event = [NSEvent mouseEventWithType:type location:location modifierFlags:modifierFlags window:window clickCount:_clickCount deltaX:location.x - _pastLocation.x deltaY:-(location.y - _pastLocation.y)];
	else
		event = [NSEvent mouseEventWithType:type location:location modifierFlags:modifierFlags window:window clickCount:_clickCount deltaX:0.0 deltaY:0.0];
	
	if ((type == NSLeftMouseDragged) || (type == NSRightMouseDragged))
		_pastLocation = location;
	
	if ((type == NSLeftMouseUp) || (type == NSRightMouseUp))
		_pastLocation = NSMakePoint(FLT_MAX, FLT_MAX);
	
	[self postEvent:event atStart:NO];
	
	return YES;
}

-(BOOL)postScrollWheelMSG:(MSG)msg type:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window {
   NSEvent *event;
   float deltaY=((short)HIWORD(msg.wParam));

   deltaY/=WHEEL_DELTA;

   event=[NSEvent mouseEventWithType:type location:location modifierFlags:modifierFlags window:window deltaY:deltaY];
   [self postEvent:event atStart:NO];
   return YES;
}

-(unsigned)currentModifierFlags {
   unsigned result=0;
   BYTE     keyState[256];

   if(!GetKeyboardState(keyState))
    return result;

   if(keyState[VK_LSHIFT]&0x80)
    result|=NSShiftKeyMask;
   if(keyState[VK_RSHIFT]&0x80)
    result|=NSShiftKeyMask;

   if(keyState[VK_CAPITAL]&0x80)
    result|=NSAlphaShiftKeyMask;

   if(keyState[VK_LCONTROL]&0x80)
    result|=[self modifierForDefault:@"LeftControl":NSControlKeyMask];
   if(keyState[VK_RCONTROL]&0x80)
    result|=[self modifierForDefault:@"RightControl":NSControlKeyMask];

   if(keyState[VK_LMENU]&0x80)
    result|=[self modifierForDefault:@"LeftAlt":NSAlternateKeyMask];
   if(keyState[VK_RMENU]&0x80)
    result|=[self modifierForDefault:@"RightAlt":NSAlternateKeyMask];


   if(keyState[VK_NUMPAD0]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD1]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD2]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD3]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD4]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD5]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD6]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD7]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD8]&0x80)
    result|=NSNumericPadKeyMask;
   if(keyState[VK_NUMPAD9]&0x80)
    result|=NSNumericPadKeyMask;

   return result;
}

-(BOOL)postMSG:(MSG)msg {
   NSEventType  type;
   id           platformWindow=(id)GetProp(msg.hwnd,"self");
   NSWindow    *window=nil;
   POINT        deviceLocation;
   NSPoint      location;
   unsigned     modifierFlags;
   DWORD        tickCount=GetTickCount();
   int          lastClickCount=_clickCount;

   if([platformWindow respondsToSelector:@selector(appkitWindow)])
    window=[platformWindow performSelector:@selector(appkitWindow)];

   if(![window isKindOfClass:[NSWindow class]])
    window=nil;

   if(window==nil) // not one of our events
    return NO;

   if(msg.message==WM_LBUTTONDBLCLK || msg.message==WM_RBUTTONDBLCLK){
    if(msg.lParam==_lastPosition && _lastTickCount+GetDoubleClickTime()>=tickCount)
      _clickCount=lastClickCount+1;
    else
      _clickCount=2;
    _lastTickCount=tickCount;
    _lastPosition=msg.lParam;
   }
   else if(msg.message==WM_LBUTTONDOWN || msg.message==WM_RBUTTONDOWN){
    if(msg.lParam==_lastPosition && _lastTickCount+GetDoubleClickTime()>=tickCount)
      _clickCount=lastClickCount+1;
    else
      _clickCount=1;
    _lastTickCount=tickCount;
    _lastPosition=msg.lParam;
   }

   switch(msg.message){

     case WM_KEYDOWN:
     case WM_SYSKEYDOWN:
      type=NSKeyDown;
      break;

     case WM_KEYUP:
     case WM_SYSKEYUP:
      type=NSKeyUp;
      break;

     case WM_MOUSEMOVE:
      [self _unhideCursorForMouseMove];
      
      if(msg.wParam&MK_LBUTTON)
       type=NSLeftMouseDragged;
      else if(msg.wParam&MK_RBUTTON)
       type=NSRightMouseDragged;
      else {
       if(window!=nil && [window acceptsMouseMovedEvents])
        type=NSMouseMoved;
       else
        return YES;
      }
      break;

     case WM_LBUTTONDOWN:
     case WM_LBUTTONDBLCLK:
      type=NSLeftMouseDown;
      SetCapture([platformWindow windowHandle]);
      break;

     case WM_LBUTTONUP:
      type=NSLeftMouseUp;
      ReleaseCapture();
      break;

     case WM_RBUTTONDOWN:
     case WM_RBUTTONDBLCLK:
      type=NSRightMouseDown;
      break;

     case WM_RBUTTONUP:
      type=NSRightMouseUp;
      break;

     case WM_MOUSEWHEEL:
      type=NSScrollWheel;
      break;

     case WM_NCMOUSEMOVE:
     case WM_NCLBUTTONDOWN:
     case WM_NCLBUTTONUP:
     case WM_NCLBUTTONDBLCLK:
     case WM_NCRBUTTONDOWN:
     case WM_NCRBUTTONUP:
     case WM_NCRBUTTONDBLCLK:
     case WM_NCMBUTTONDOWN:
     case WM_NCMBUTTONUP:
     case WM_NCMBUTTONDBLCLK:
      {
       Win32Event *cgEvent=[Win32Event eventWithMSG:msg];
       NSEvent    *event=[[[NSEvent_CoreGraphics alloc] initWithCoreGraphicsEvent:cgEvent window:window] autorelease];
       [self postEvent:event atStart:NO];
      }
      return YES;

     default:
      return NO;
    }

    deviceLocation.x=GET_X_LPARAM(msg.lParam);
    deviceLocation.y=GET_Y_LPARAM(msg.lParam);

    location.x=deviceLocation.x;
    location.y=deviceLocation.y;
    if(msg.hwnd!=[platformWindow windowHandle]){
     RECT child={0},parent={0};

// There is no way to get a child's frame inside the parent, you have to get
// them both in screen coordinates and do a delta
// GetClientRect always returns 0,0 for top,left which makes it useless     
     GetWindowRect(msg.hwnd,&child);
     GetWindowRect([platformWindow windowHandle],&parent);
     location.x+=child.left-parent.left;
     location.y+=child.top-parent.top;
    }
     
    [platformWindow adjustEventLocation:&location];
    
    modifierFlags=[self currentModifierFlags];

    switch(type){
     case NSLeftMouseDown:
     case NSLeftMouseUp:
     case NSRightMouseDown:
     case NSRightMouseUp:
     case NSMouseMoved:
     case NSLeftMouseDragged:
     case NSRightMouseDragged:
     case NSMouseEntered:
     case NSMouseExited:
      return [self postMouseMSG:msg type:type location:location modifierFlags:modifierFlags window:window];

     case NSKeyDown:
     case NSKeyUp:
     case NSFlagsChanged:
      return [self postKeyboardMSG:msg type:type location:location modifierFlags:modifierFlags window:window];

     case NSScrollWheel:
      return [self postScrollWheelMSG:msg type:type location:location modifierFlags:modifierFlags window:window];

     default:
      return NO;
    }

   return NO;
}

-(void)beep {
   MessageBeep(MB_OK);
}

static int CALLBACK buildFamily(const LOGFONTA *lofFont_old,
   const TEXTMETRICA *textMetric_old,DWORD fontType,LPARAM lParam){
   LPENUMLOGFONTEX  logFont=(LPENUMLOGFONTEX)lofFont_old;
//   NEWTEXTMETRICEX *textMetric=(NEWTEXTMETRICEX *)textMetric_old;
   NSMutableSet *set=(NSMutableSet *)lParam;
//   NSString     *name=[NSString stringWithCString:logFont->elfFullName];
   NSString     *name=[NSString stringWithCString:logFont->elfLogFont.lfFaceName];

   [set addObject:name];

   return 1;
}

-(NSSet *)allFontFamilyNames {
   NSMutableSet *result=[[[NSMutableSet alloc] init] autorelease];
   HDC           dc=GetDC(NULL);
   LOGFONT       logFont;

   logFont.lfCharSet=DEFAULT_CHARSET;
   strcpy(logFont.lfFaceName,"");
   logFont.lfPitchAndFamily=0;

   if(!EnumFontFamiliesExA(dc,&logFont,buildFamily,(LPARAM)result,0))
    NSLog(@"EnumFontFamiliesExA failed %d",__LINE__);

   ReleaseDC(NULL,dc);
   return result;
}

static NSFontMetric *fontMetricWithLogicalAndMetric(const ENUMLOGFONTEX *logFont,
   const NEWTEXTMETRICEX *textMetric) {
   NSSize size=NSMakeSize(logFont->elfLogFont.lfWidth,logFont->elfLogFont.lfHeight);
   float  ascender=textMetric->ntmTm.tmAscent;
   float  descender=-((float)textMetric->ntmTm.tmDescent);

   return [[[NSFontMetric alloc]
       initWithSize:size 
           ascender:ascender
          descender:descender] autorelease];
}

static int CALLBACK buildTypeface(const LOGFONTA *lofFont_old,
   const TEXTMETRICA *textMetric_old,DWORD fontType,LPARAM lParam){
   NSMutableDictionary *result=(NSMutableDictionary *)lParam;
   LPENUMLOGFONTEX  logFont=(LPENUMLOGFONTEX)lofFont_old;
   NEWTEXTMETRICEX *textMetric=(NEWTEXTMETRICEX *)textMetric_old;
   NSString        *name=[NSString stringWithCString:(char *)(logFont->elfFullName)];
   NSString        *traitName=[NSString stringWithCString:(char *)logFont->elfStyle];
  // NSString       *encoding=[NSString stringWithCString:logFont->elfScript];
   NSFontTypeface  *typeface=[result objectForKey:name];

   if(typeface==nil){
    NSFontTraitMask traits=0;

    if(textMetric->ntmTm.ntmFlags&NTM_ITALIC)
     traits|=NSItalicFontMask;
    if(textMetric->ntmTm.ntmFlags&NTM_BOLD)
     traits|=NSBoldFontMask;

    typeface=[[[NSFontTypeface alloc] initWithName:name traitName:traitName traits:traits] autorelease];

    [result setObject:typeface forKey:name];
   }

   [typeface addMetric:fontMetricWithLogicalAndMetric(logFont,textMetric)];

   return 1;
}

-(NSArray *)fontTypefacesForFamilyName:(NSString *)name {
   NSMutableDictionary *result=[NSMutableDictionary dictionary];
   HDC             dc=GetDC(NULL);
   LOGFONT         logFont;

   logFont.lfCharSet=DEFAULT_CHARSET;
   logFont.lfPitchAndFamily=0;

   [name getCString:logFont.lfFaceName maxLength:LF_FACESIZE-1];

   if(!EnumFontFamiliesExA(dc,&logFont,buildTypeface,(LPARAM)result,0))
    NSLog(@"EnumFontFamiliesExA failed %d",__LINE__);

   ReleaseDC(NULL,dc);
   
   return [result allValues];
}

-(float)scrollerWidth {
   return GetSystemMetrics(SM_CXHTHUMB);
}

-(void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo {
   PAGESETUPDLG setup;

   setup.lStructSize=sizeof(PAGESETUPDLG);
   setup.hwndOwner=[(Win32Window *)[[NSApp mainWindow] platformWindow] windowHandle];
   setup.hDevMode=NULL;
   setup.hDevNames=NULL;
   setup.Flags=0;
   //setup.ptPaperSize=0;
   //setup.rtMinMargin=0;

   [self stopWaitCursor];
   PageSetupDlg(&setup);
   [self startWaitCursor];
}

-(int)runModalPrintPanelWithPrintInfoDictionary:(NSMutableDictionary *)attributes {
   NSView             *view=[attributes objectForKey:@"_NSView"];
   PRINTDLG            printProperties;
   int                 check;

   printProperties.lStructSize=sizeof(PRINTDLG);
   printProperties.hwndOwner=[(Win32Window *)[[view window] platformWindow] windowHandle];
   printProperties.hDevMode=NULL;
   printProperties.hDevNames=NULL;
   printProperties.hDC=NULL;
   printProperties.Flags=PD_RETURNDC|PD_COLLATE;

   printProperties.nFromPage=[[attributes objectForKey:NSPrintFirstPage] intValue]; 
   printProperties.nToPage=[[attributes objectForKey:NSPrintLastPage] intValue]; 
   printProperties.nMinPage=[[attributes objectForKey:NSPrintFirstPage] intValue]; 
   printProperties.nMaxPage=[[attributes objectForKey:NSPrintLastPage] intValue];
   printProperties.nCopies=[[attributes objectForKey:NSPrintCopies] intValue]; 
   printProperties.hInstance=NULL; 
   printProperties.lCustData=0; 
   printProperties.lpfnPrintHook=NULL; 
   printProperties.lpfnSetupHook=NULL; 
   printProperties.lpPrintTemplateName=NULL; 
   printProperties.lpSetupTemplateName=NULL; 
   printProperties.hPrintTemplate=NULL; 
   printProperties.hSetupTemplate=NULL; 

   [self stopWaitCursor];
   check=PrintDlg(&printProperties);
   [self startWaitCursor];

   if(check==0)
    return NSCancelButton;
   else {
    NSDictionary *auxiliaryInfo=[NSDictionary dictionaryWithObject:[attributes objectForKey:@"_title"] forKey:(id)kCGPDFContextTitle];
    O2Context_gdi *context=[[[O2Context_gdi alloc] initWithPrinterDC:printProperties.hDC auxiliaryInfo:auxiliaryInfo] autorelease];
    NSRect imageable;
    
    if([context getImageableRect:&imageable])
     [attributes setObject:[NSValue valueWithRect:imageable] forKey:@"_imageableRect"];
     
    [attributes setObject:context forKey:@"_KGContext"];
    
    [attributes setObject:[NSValue valueWithSize:[context pointSize]] forKey:NSPrintPaperSize];
   }
     
   return NSOKButton;
}

-(int)savePanel:(NSSavePanel *)savePanel runModalForDirectory:(NSString *)directory file:(NSString *)file {
   return [savePanel _GetOpenFileName];
}

-(int)openPanel:(NSOpenPanel *)openPanel runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types {
   if([openPanel canChooseDirectories])
    return [openPanel _SHBrowseForFolder:types];
   else
    return [openPanel _GetOpenFileNameForTypes:types];
}

-(float)primaryScreenHeight {
   return GetSystemMetrics(SM_CYSCREEN);
}

-(NSPoint)mouseLocation {
   POINT   winPoint;
   NSPoint point;

   GetCursorPos(&winPoint);

   point.x=winPoint.x;
   point.y=winPoint.y;
   point.y=[self primaryScreenHeight]-point.y;

   return point;
}

@end
