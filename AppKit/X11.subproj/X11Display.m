/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "X11Display.h"
#import "X11Window.h"
#import <AppKit/NSScreen.h>
#import <AppKit/NSApplication.h>
#import <AppKit/X11InputSource.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/TTFFont.h>
#import <AppKit/NSRaise.h>
#import <AppKit/O2Font_FT.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSFontTypeface.h>
#import <fcntl.h>
#import <fontconfig.h>

@implementation NSDisplay(X11)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([X11Display class],0,NULL);
}

@end

@implementation X11Display

static int errorHandler(Display* display,
                        XErrorEvent* errorEvent) {
   return [(X11Display*)[X11Display currentDisplay] handleError:errorEvent];
}

-(id)init
{
   if(self=[super init])
   {
      _display=XOpenDisplay(NULL);
      if(!_display)
         _display=XOpenDisplay(":0");

      if(!_display) {
         [self release];
         return nil;
      }
      
      if(NSDebugEnabled)
         XSynchronize(_display, True);
      XSetErrorHandler(errorHandler);
      _windowsByID=[NSMutableDictionary new];
      [self performSelector:@selector(setupEventHandling) withObject:nil afterDelay:0.0];
   }
   return self;
}

-(void)dealloc
{
   if(_display)
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
      return [NSColor lightGrayColor];
   if([colorName isEqual:@"controlShadowColor"])
      return [NSColor darkGrayColor];
   if([colorName isEqual:@"selectedControlColor"])
      return [NSColor blueColor];
   if([colorName isEqual:@"controlBackgroundColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"controlLightHighlightColor"])
      return [NSColor lightGrayColor];

   if([colorName isEqual:@"textBackgroundColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"textColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"menuItemTextColor"])
      return [NSColor blackColor];
   if([colorName isEqual:@"selectedMenuItemTextColor"])
      return [NSColor whiteColor];
   if([colorName isEqual:@"selectedMenuItemColor"])
      return [NSColor blueColor];
   if([colorName isEqual:@"selectedControlTextColor"])
      return [NSColor blackColor];
   
   NSLog(@"%@", colorName);
   
   return [NSColor redColor];
   
}

-(void)_addSystemColor:(NSColor *) result forName:(NSString *)colorName {
   NSUnimplementedMethod();
}

-(NSTimeInterval)textCaretBlinkInterval {
   return 0.5;
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
   XBell(_display, 100);
}

-(NSSet *)allFontFamilyNames {
   int i;
   FcPattern *pat=FcPatternCreate();
   FcObjectSet *props=FcObjectSetBuild(FC_FAMILY, NULL);
   
   FcFontSet *set = FcFontList (O2FontSharedFontConfig(), pat, props);
   NSMutableSet* ret=[NSMutableSet set];
   
   for(i = 0; i < set->nfont; i++)
   {
      FcChar8 *family;
      if (FcPatternGetString (set->fonts[i], FC_FAMILY, 0, &family) == FcResultMatch) {
         [ret addObject:[NSString stringWithUTF8String:(char*)family]];
      }
   }
   
   FcPatternDestroy(pat);
   FcObjectSetDestroy(props);
   FcFontSetDestroy(set);
   return ret;
}

-(NSArray *)fontTypefacesForFamilyName:(NSString *)familyName {
   int i;
   FcPattern *pat=FcPatternCreate();
   FcPatternAddString(pat, FC_FAMILY, (unsigned char*)[familyName UTF8String]);
   FcObjectSet *props=FcObjectSetBuild(FC_FAMILY, FC_STYLE, FC_SLANT, FC_WIDTH, FC_WEIGHT, NULL);

   FcFontSet *set = FcFontList (O2FontSharedFontConfig(), pat, props);
   NSMutableArray* ret=[NSMutableArray array];
   
   for(i = 0; i < set->nfont; i++)
   {
      FcChar8 *typeface;
      FcPattern *p=set->fonts[i];
      if (FcPatternGetString (p, FC_STYLE, 0, &typeface) == FcResultMatch) {
         NSString* traitName=[NSString stringWithUTF8String:(char*)typeface];
         FcChar8* pattern=FcNameUnparse(p);
         NSString* name=[NSString stringWithUTF8String:(char*)pattern];
         FcStrFree(pattern);
         
         NSFontTraitMask traits=0;
         int slant, width, weight;
         
         FcPatternGetInteger(p, FC_SLANT, FC_SLANT_ROMAN, &slant);
         FcPatternGetInteger(p, FC_WIDTH, FC_WIDTH_NORMAL, &width);
         FcPatternGetInteger(p, FC_WEIGHT, FC_WEIGHT_REGULAR, &weight);

         switch(slant) {
            case FC_SLANT_OBLIQUE:
            case FC_SLANT_ITALIC:
               traits|=NSItalicFontMask;
               break;
            default:
               traits|=NSUnitalicFontMask;
               break;
         }
         
         if(weight<=FC_WEIGHT_LIGHT)
            traits|=NSUnboldFontMask;
         else if(weight>=FC_WEIGHT_SEMIBOLD)
            traits|=NSBoldFontMask;
         
         if(width<=FC_WIDTH_SEMICONDENSED)
            traits|=NSNarrowFontMask;
         else if(width>=FC_WIDTH_SEMIEXPANDED)
            traits|=NSExpandedFontMask;
         
         NSFontTypeface *face=[[NSFontTypeface alloc] initWithName:name traitName:traitName traits:traits];
         [ret addObject:face];
         [face release];
      }
   }
   
   FcPatternDestroy(pat);
   FcObjectSetDestroy(props);
   FcFontSetDestroy(set);
   return ret;
}

-(float)scrollerWidth {
   return 15.0;
}

-(float)doubleClickInterval {
   return 1.0;
}


-(void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo {
   NSUnimplementedMethod();
}

-(int)runModalPrintPanelWithPrintInfoDictionary:(NSMutableDictionary *)attributes {
   NSUnimplementedMethod();
   return 0;
}

-(O2Context *)graphicsPortForPrintOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo pageRange:(NSRange)pageRange {
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

-(void)setupEventHandling {
   [X11InputSource addInputSourceWithDisplay:self];
}

-(NSEvent *)nextEventMatchingMask:(unsigned)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue;
{
   [self processX11Event];
   return [super nextEventMatchingMask:mask untilDate:untilDate inMode:mode dequeue:dequeue];
}

-(BOOL)processX11Event {
   XEvent e;
   int i;
   int numEvents;
   BOOL ret=NO;
   int connectionNumber=ConnectionNumber(_display);
   int flags=fcntl(connectionNumber, F_GETFL);
   flags&=~O_NONBLOCK;
   fcntl(connectionNumber, F_SETFL, flags | O_NONBLOCK);
   
   NSMutableSet *windowsUsed=[NSMutableSet set];
   
   while(numEvents=XEventsQueued(_display, QueuedAfterFlush)) {
      XNextEvent(_display, &e);
      
      id window=[self windowForID:e.xany.window];
      [window handleEvent:&e fromDisplay:self];
      [windowsUsed addObject:window];
      ret=YES;
   }
   
   fcntl(connectionNumber, F_SETFL, flags & ~O_NONBLOCK);


   return ret;
}

-(int)handleError:(XErrorEvent*)errorEvent {
   NSLog(@"************** ERROR");
   return 0;
}
@end

#import <AppKit/NSGraphicsStyle.h>

@implementation NSGraphicsStyle (Overrides) 
-(void)drawMenuBranchArrowAtPoint:(NSPoint)point selected:(BOOL)selected {
   NSImage* arrow=[NSImage imageNamed:@"NSMenuArrow"];
   point.y+=5;
   point.x-=2;
   [arrow compositeToPoint:point operation:NSCompositeSourceOver];
}

@end