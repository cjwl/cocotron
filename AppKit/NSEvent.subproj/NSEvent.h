/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/AppKitExport.h>

@class NSWindow,NSGraphicsContext;

typedef enum {
   NSLeftMouseDown=1,
   NSLeftMouseUp,
   NSRightMouseDown,
   NSRightMouseUp,
   NSMouseMoved,
   NSLeftMouseDragged,
   NSRightMouseDragged,
   NSMouseEntered,
   NSMouseExited,
   NSKeyDown,
   NSKeyUp,
   NSFlagsChanged,
   NSPeriodic,
   NSCursorUpdate,
   NSPlatformSpecific,
   NSAppKitSystem,
   NSScrollWheel
} NSEventType;

enum {
   NSLeftMouseDownMask=1<<NSLeftMouseDown,
   NSLeftMouseUpMask=1<<NSLeftMouseUp,
   NSRightMouseDownMask=1<<NSRightMouseDown,
   NSRightMouseUpMask=1<<NSRightMouseUp,
   NSMouseMovedMask=1<<NSMouseMoved,
   NSLeftMouseDraggedMask=1<<NSLeftMouseDragged,
   NSRightMouseDraggedMask=1<<NSRightMouseDragged,
   NSMouseEnteredMask=1<<NSMouseEntered,
   NSMouseExitedMask=1<<NSMouseExited,
   NSKeyDownMask=1<<NSKeyDown,
   NSKeyUpMask=1<<NSKeyUp,
   NSFlagsChangedMask=1<<NSFlagsChanged,
   NSPeriodicMask=1<<NSPeriodic,
   NSCursorUpdateMask=1<<NSCursorUpdate,
   NSScrollWheelMask=1<<NSScrollWheel,
   NSAnyEventMask=0xffffffff
};

enum {
   NSAlphaShiftKeyMask=1<<16,
   NSShiftKeyMask=1<<17,
   NSControlKeyMask=1<<18,
   NSAlternateKeyMask=1<<19,
   NSCommandKeyMask=1<<20,
   NSNumericPadKeyMask=1<<21,
   NSHelpKeyMask=1<<22,
   NSFunctionKeyMask=1<<23
};

enum {
   NSUpArrowFunctionKey=0xF700,
   NSDownArrowFunctionKey=0xF701,
   NSLeftArrowFunctionKey=0xF702,
   NSRightArrowFunctionKey=0xF703,
   NSF1FunctionKey=0xF704,
   NSF2FunctionKey=0xF705,
   NSF3FunctionKey=0xF706,
   NSF4FunctionKey=0xF707,
   NSF5FunctionKey=0xF708,
   NSF6FunctionKey=0xF709,
   NSF7FunctionKey=0xF70A,
   NSF8FunctionKey=0xF70B,
   NSF9FunctionKey=0xF70C,
   NSF10FunctionKey=0xF70D,
   NSF11FunctionKey=0xF70E,
   NSF12FunctionKey=0xF70F,
   NSF13FunctionKey=0xF710,
   NSF14FunctionKey=0xF711,
   NSF15FunctionKey=0xF712,
   NSF16FunctionKey=0xF713,
   NSF17FunctionKey=0xF714,
   NSF18FunctionKey=0xF715,
   NSF19FunctionKey=0xF716,
   NSF20FunctionKey=0xF717,
   NSF21FunctionKey=0xF718,
   NSF22FunctionKey=0xF719,
   NSF23FunctionKey=0xF71A,
   NSF24FunctionKey=0xF71B,
   NSF25FunctionKey=0xF71C,
   NSF26FunctionKey=0xF71D,
   NSF27FunctionKey=0xF71E,
   NSF28FunctionKey=0xF71F,
   NSF29FunctionKey=0xF720,
   NSF30FunctionKey=0xF721,
   NSF31FunctionKey=0xF722,
   NSF32FunctionKey=0xF723,
   NSF33FunctionKey=0xF724,
   NSF34FunctionKey=0xF725,
   NSF35FunctionKey=0xF726,
   NSInsertFunctionKey=0xF727,
   NSDeleteFunctionKey=0xF728,
   NSHomeFunctionKey=0xF729,
   NSBeginFunctionKey=0xF72A,
   NSEndFunctionKey=0xF72B,
   NSPageUpFunctionKey=0xF72C,
   NSPageDownFunctionKey=0xF72D,
   NSPrintScreenFunctionKey=0xF72E,
   NSScrollLockFunctionKey=0xF72F,
   NSPauseFunctionKey=0xF730,
   NSSysReqFunctionKey=0xF731,
   NSBreakFunctionKey=0xF732,
   NSResetFunctionKey=0xF733,
   NSStopFunctionKey=0xF734,
   NSMenuFunctionKey=0xF735,
   NSUserFunctionKey=0xF736,
   NSSystemFunctionKey=0xF737,
   NSPrintFunctionKey=0xF738,
   NSClearLineFunctionKey=0xF739,
   NSClearDisplayFunctionKey=0xF73A,
   NSInsertLineFunctionKey=0xF73B,
   NSDeleteLineFunctionKey=0xF73C,
   NSInsertCharFunctionKey=0xF73D,
   NSDeleteCharFunctionKey=0xF73E,
   NSPrevFunctionKey=0xF73F,
   NSNextFunctionKey=0xF740,
   NSSelectFunctionKey=0xF741,
   NSExecuteFunctionKey=0xF742,
   NSUndoFunctionKey=0xF743,
   NSRedoFunctionKey=0xF744,
   NSFindFunctionKey=0xF745,
   NSHelpFunctionKey=0xF746,
   NSModeSwitchFunctionKey=0xF747
};

@interface NSEvent : NSObject {
   int       _type;
   NSTimeInterval _timestamp;
   NSPoint   _locationInWindow;
   unsigned  _modifierFlags;
   NSWindow *_window;
}

+(NSPoint)mouseLocation;

-initWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window;

+(NSEvent *)mouseEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned int)modifierFlags window:(NSWindow *)window clickCount:(int)clickCount;

+(NSEvent *)mouseEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned)modifierFlags window:(NSWindow *)window deltaY:(float)deltaY;

+(NSEvent *)keyEventWithType:(NSEventType)type location:(NSPoint)location modifierFlags:(unsigned int)modifierFlags timestamp:(NSTimeInterval)timestamp windowNumber:(int)windowNumber context:(NSGraphicsContext *)context characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers isARepeat:(BOOL)isARepeat keyCode:(unsigned short)keyCode;

-(NSEventType)type;
-(NSTimeInterval)timestamp;
-(NSPoint)locationInWindow;
-(unsigned)modifierFlags;
-(NSWindow *)window;

-(int)clickCount;
-(float)deltaX;
-(float)deltaY;
-(float)deltaZ;

-(NSString *)characters;
-(NSString *)charactersIgnoringModifiers;
-(unsigned short)keyCode;

+(void)startPeriodicEventsAfterDelay:(NSTimeInterval)delay withPeriod:(NSTimeInterval)period;
+(void)stopPeriodicEvents;

@end

APPKIT_EXPORT unsigned NSEventMaskFromType(NSEventType type);

