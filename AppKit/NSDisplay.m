/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSPlatform.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSEvent_periodic.h>
#import <AppKit/NSApplication.h>

@implementation NSDisplay

+(void)initialize {
   if(self==[NSDisplay class]){
    NSDictionary *map=[NSDictionary dictionaryWithObjectsAndKeys:
     @"Command",@"LeftControl",
     @"Alt",@"LeftAlt",
     @"Control",@"RightControl",
     @"Alt",@"RightAlt",
     nil];
    NSDictionary *modifierMapping=[NSDictionary dictionaryWithObject:map forKey:@"NSModifierFlagMapping"];

    [[NSUserDefaults standardUserDefaults] registerDefaults:modifierMapping];
   }
}

+(NSDisplay *)currentDisplay {
   return NSThreadSharedInstance([[NSPlatform currentPlatform] displayClassName]);
}

-init {
   _fontCacheCapacity=4;
   _fontCacheSize=0;
   _fontCache=NSZoneMalloc([self zone],sizeof(NSFont *)*_fontCacheCapacity);
   _eventMask=0;
   _eventQueue=[NSMutableArray new];
   _periodicTimer=nil;
   return self;
}

-(void)showSplashImage {
   NSInvalidAbstractInvocation();
}

-(void)closeSplashImage {
   NSInvalidAbstractInvocation();
}

-(NSArray *)screens {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSPasteboard *)pasteboardWithName:(NSString *)name {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSDraggingManager *)draggingManager {
   NSInvalidAbstractInvocation();
   return nil;
}

-(CGWindow *)windowWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
   NSInvalidAbstractInvocation();
   return nil;
}

-(CGWindow *)panelWithFrame:(NSRect)frame styleMask:(unsigned)styleMask backingType:(unsigned)backingType {
   NSInvalidAbstractInvocation();
   return nil;
}

-(CGRenderingContext *)bitmapRenderingContextWithSize:(NSSize)size {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSColor *)colorWithName:(NSString *)colorName {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSString *)menuFontNameAndSize:(float *)pointSize {
   NSInvalidAbstractInvocation();
   return nil;
}

-(unsigned)_cacheIndexOfFontWithName:(NSString *)name size:(float)size {
   unsigned i;

   for(i=0;i<_fontCacheSize;i++){
    NSFont *check=_fontCache[i];

    if(check!=nil && [[check fontName] isEqualToString:name] && [check pointSize]==size)
     return i;
   }

   return NSNotFound;
}

-(NSFont *)cachedFontWithName:(NSString *)name size:(float)size {
   unsigned i=[self _cacheIndexOfFontWithName:name size:size];

   return (i==NSNotFound)?nil:_fontCache[i];
}

-(void)addFontToCache:(NSFont *)font {
   unsigned i;

   for(i=0;i<_fontCacheSize;i++){
    if(_fontCache[i]==nil){
     _fontCache[i]=font;
     return;
    }
   }

   if(_fontCacheSize>=_fontCacheCapacity){
    _fontCacheCapacity*=2;
    _fontCache=NSZoneRealloc([self zone],_fontCache,sizeof(NSFont *)*_fontCacheCapacity);
   }
   _fontCache[_fontCacheSize++]=font;
}

-(void)removeFontFromCache:(NSFont *)font {
   unsigned i=[self _cacheIndexOfFontWithName:[font fontName] size:[font pointSize]];

   if(i!=NSNotFound)
    _fontCache[i]=nil;
}

-(NSTimeInterval)textCaretBlinkInterval {
   NSInvalidAbstractInvocation();
   return 1;
}

-(void)hideCursor {
   NSInvalidAbstractInvocation();
}

-(void)unhideCursor {
   NSInvalidAbstractInvocation();
}

// Arrow, IBeam, HorizontalResize, VerticalResize
-(id)cursorWithName:(NSString *)name {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)setCursor:(id)cursor {
   NSInvalidAbstractInvocation();
}

-(NSEvent *)nextEventMatchingMask:(unsigned)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue {
   NSEvent *result;

   _eventMask=mask;

   [[NSRunLoop currentRunLoop] runMode:mode beforeDate:untilDate];

   if([_eventQueue count]==0)
    result=[[[NSEvent alloc] initWithType:NSAppKitSystem location:NSMakePoint(0,0) modifierFlags:0 window:nil] autorelease];
   else {
    result=[[[_eventQueue objectAtIndex:0] retain] autorelease];

    if(dequeue)
     [_eventQueue removeObjectAtIndex:0];
   }

   return result;
}

-(void)discardEventsMatchingMask:(unsigned)mask beforeEvent:(NSEvent *)event {
   int count=[_eventQueue count];

   while(--count>=0){
    NSEvent *check=[_eventQueue objectAtIndex:count];

    if(check==event)
     break;
   }

   while(--count>=0){
    if(NSEventMaskFromType([event type])&mask)
     [_eventQueue removeObjectAtIndex:count];
   }
}

-(void)postEvent:(NSEvent *)event atStart:(BOOL)atStart {
   if(atStart)
    [_eventQueue insertObject:event atIndex:0];
   else
    [_eventQueue addObject:event];
}

-(BOOL)containsAndRemovePeriodicEvents {
   BOOL result=NO;
   int  count=[_eventQueue count];

   while(--count>=0){
    if([[_eventQueue objectAtIndex:count] type]==NSPeriodic){
     result=YES;
     [_eventQueue removeObjectAtIndex:count];
    }
   }

   return result;
}

-(BOOL)hasEventsMatchingMask {
   return [_eventQueue count]>0;
}

-(void)_periodicDelay:(NSTimer *)timer {
   NSTimeInterval period=[[timer userInfo] doubleValue];

   [_periodicTimer invalidate];
   [_periodicTimer release];

   _periodicTimer=[[NSTimer timerWithTimeInterval:period
     target:self selector:@selector(_periodicEvent:) userInfo:nil
     repeats:YES] retain];

   [[NSRunLoop currentRunLoop] addTimer:_periodicTimer forMode:NSEventTrackingRunLoopMode];
}

-(void)_periodicEvent:(NSTimer *)timer {
   NSEvent *event=[[[NSEvent_periodic alloc] initWithType:NSPeriodic location:NSMakePoint(0,0) modifierFlags:0 window:nil] autorelease];

   [self postEvent:event atStart:NO];
   [self discardEventsMatchingMask:NSPeriodicMask beforeEvent:event];
}

-(void)startPeriodicEventsAfterDelay:(NSTimeInterval)delay withPeriod:(NSTimeInterval)period {
   NSNumber *userInfo=[NSNumber numberWithDouble:period];

   if(_periodicTimer!=nil)
     [NSException raise:NSInternalInconsistencyException format:@"periodic events already enabled"];

   _periodicTimer=[[NSTimer timerWithTimeInterval:delay
     target:self selector:@selector(_periodicDelay:) userInfo:userInfo
     repeats:NO] retain];

   [[NSRunLoop currentRunLoop] addTimer:_periodicTimer forMode:NSEventTrackingRunLoopMode];
}

-(void)stopPeriodicEvents {
   [_periodicTimer invalidate];
   [_periodicTimer release];
   _periodicTimer=nil;
}

-(unsigned)modifierForDefault:(NSString *)key:(unsigned)standard {
   NSDictionary *modmap=[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"NSModifierFlagMapping"];
   NSString     *remap=[modmap objectForKey:key];

   if([remap isEqualToString:@"Command"])
    return NSCommandKeyMask;
   if([remap isEqualToString:@"Alt"])
    return NSAlternateKeyMask;
   if([remap isEqualToString:@"Control"])
    return NSControlKeyMask;

   return standard;
}

-(void)beep {
   NSInvalidAbstractInvocation();
}

-(NSSet *)allFontFamilyNames {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSArray *)fontTypefacesForFamilyName:(NSString *)name {
   NSInvalidAbstractInvocation();
   return nil;
}

-(float)scrollerWidth {
   NSInvalidAbstractInvocation();
   return 0;
}

-(void)metricsForFontWithName:(NSString *)name pointSize:(float)pointSize metrics:(NSFontMetrics *)metrics {
   NSInvalidAbstractInvocation();
}

-(void)loadGlyphRangeTable:(NSGlyphRangeTable *)table fontName:(NSString *)name range:(NSRange)range {
   NSInvalidAbstractInvocation();
}

-(void)fetchAdvancementsForFontWithName:(NSString *)name pointSize:(float)pointSize glyphRanges:(NSGlyphRangeTable *)table infoSet:(NSGlyphInfoSet *)infoSet forGlyph:(NSGlyph)glyph {
   NSInvalidAbstractInvocation();
}

-(void)fetchGlyphKerningForFontWithName:(NSString *)name pointSize:(float)pointSize glyphRanges:(NSGlyphRangeTable *)table infoSet:(NSGlyphInfoSet *)infoSet {
   NSInvalidAbstractInvocation();
}

-(void)runModalWithPrintInfo:(NSPrintInfo *)printInfo {
   NSInvalidAbstractInvocation();
}

-(CGContext *)graphicsPortForPrintOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo pageRange:(NSRange)pageRange {
   NSInvalidAbstractInvocation();
   return nil;
}

-(int)savePanel:(NSSavePanel *)savePanel runModalForDirectory:(NSString *)directory file:(NSString *)file {
   NSInvalidAbstractInvocation();
   return 0;
}

-(int)openPanel:(NSOpenPanel *)openPanel runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types {
   NSInvalidAbstractInvocation();
   return 0;
}

@end
