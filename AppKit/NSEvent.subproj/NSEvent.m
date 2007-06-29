/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSEvent.h>
#import <AppKit/NSEvent_mouse.h>
#import <AppKit/NSEvent_keyboard.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSDisplay.h>

@implementation NSEvent

+(NSPoint)mouseLocation {
   return [[NSDisplay currentDisplay] mouseLocation];
}

-initWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window {
   _type=type;
   _locationInWindow=location;
   _modifierFlags=modifierFlags;
   _window=window;
   return self;
}

-(void)dealloc {
   _window=nil;
   [super dealloc];
}

+(NSEvent *)mouseEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window clickCount:(int)clickCount {
   return [[[NSEvent_mouse alloc] initWithType:type location:location modifierFlags:modifierFlags window:window clickCount:clickCount] autorelease];
}

+(NSEvent *)mouseEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window deltaZ:(float)deltaZ {
   return [[[NSEvent_mouse alloc] initWithType:type location:location modifierFlags:modifierFlags window:window deltaZ:deltaZ] autorelease];
}

+(NSEvent *)keyEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers isARepeat:(BOOL)isARepeat keyCode:(unsigned short)keyCode {
   return [[[NSEvent_keyboard alloc] initWithType:type location:location modifierFlags:modifierFlags window:window characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:keyCode] autorelease];
}

+(NSEvent *)keyEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned int)modifierFlags timestamp:(NSTimeInterval)timestamp windowNumber:(int)windowNumber context:(NSGraphicsContext *)context characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers isARepeat:(BOOL)isARepeat keyCode:(unsigned short)keyCode {
   return [[[NSEvent_keyboard alloc] initWithType:type location:location modifierFlags:modifierFlags window:(id)windowNumber characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:keyCode] autorelease];
}

-(NSEventType)type {
   return _type;
}

-(NSPoint)locationInWindow {
   return _locationInWindow;
}

-(unsigned)modifierFlags {
   return _modifierFlags;
}

-(NSWindow *)window {
   return _window;
}

-(int)clickCount {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(float)deltaX {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(float)deltaY {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(float)deltaZ {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

-(NSString *)characters {
   [self doesNotRecognizeSelector:_cmd];
   return nil;
}

-(NSString *)charactersIgnoringModifiers {
   [self doesNotRecognizeSelector:_cmd];
   return nil;
}

-(unsigned short)keyCode {
   [self doesNotRecognizeSelector:_cmd];
   return 0xFFFF;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] type: %d>", [self class], self, _type];
}

+(void)startPeriodicEventsAfterDelay:(NSTimeInterval)delay withPeriod:(NSTimeInterval)period {
   [[NSDisplay currentDisplay] startPeriodicEventsAfterDelay:delay withPeriod:period];
}

+(void)stopPeriodicEvents {
   [[NSDisplay currentDisplay] stopPeriodicEvents];
}

@end

unsigned NSEventMaskFromType(NSEventType type){
   return 1<<type;
}

