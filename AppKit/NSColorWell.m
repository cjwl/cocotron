/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSColorPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSGraphicsStyle.h>
#import <Foundation/NSKeyValueObserving.h>

@implementation NSColorWell

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"color", @"something", nil]
 triggerChangeNotificationsForDependentKey:@"value"];
}

-(id)_replacementKeyPathForBinding:(id)binding
{
	if([binding isEqual:@"value"])
		return @"color";
	return binding;
}

// private
NSString *_NSColorWellDidBecomeExclusiveNotification=@"_NSColorWellDidBecomeExclusiveNotification";

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    _isEnabled=[keyed decodeBoolForKey:@"NSEnabled"];
    _isContinuous=![keyed decodeBoolForKey:@"NSIsNotContinuous"];
    _isBordered=[keyed decodeBoolForKey:@"NSIsBordered"];
    _color=[[keyed decodeObjectForKey:@"NSColor"] retain];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }
   return self;
}

-(id)initWithFrame:(NSRect)frame {
    [super initWithFrame:frame];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(colorPanelWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[NSColorPanel sharedColorPanel]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(colorWellDidBecomeExclusive:)
                                                     name:_NSColorWellDidBecomeExclusiveNotification
                                                   object:nil];

   [self registerForDraggedTypes:[NSArray arrayWithObject:NSColorPboardType]];

    return self;
}

-(void)awakeFromNib {
// this should be moved the nib initWithCoder:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorPanelWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[NSColorPanel sharedColorPanel]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorWellDidBecomeExclusive:)
                                                 name:_NSColorWellDidBecomeExclusiveNotification
                                               object:nil];
   [self registerForDraggedTypes:[NSArray arrayWithObject:NSColorPboardType]];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_color release];
    [super dealloc];
}

-(void)colorWellDidBecomeExclusive:(NSNotification *)note {
    if ([note object] != self)
        [self deactivate];
}

-(void)colorPanelWillClose:(NSNotification *)note {
    if ([self isActive])
        [self deactivate];
}

-(id)target {
    return _target;
}

-(void)setTarget:(id)target {
    _target = target;
}

-(SEL)action {
    return _action;
}

-(void)setAction:(SEL)action {
    _action = action;
}

-(BOOL)isEnabled {
   return _isEnabled;
}

-(void)setEnabled:(BOOL)flag {
   _isEnabled=flag;
   [self setNeedsDisplay:YES];
}

-(NSColor *)color {
   return _color;
}

-(BOOL)isBordered {
   return _isBordered;
}

-(BOOL)isActive {
    return _isActive && [self isEnabled];
}

-(void)setColor:(NSColor *)color {
	if(![color isKindOfClass:[NSColor class]])
		return [self setColor:[NSColor blackColor]];

   color=[color retain];
   [_color release];
   _color=color;
   [self setNeedsDisplay:YES];
}

-(void)setBordered:(BOOL)flag {
   _isBordered = flag;
}

-(void)activate:(BOOL)exclusive {
    if (exclusive) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:_NSColorWellDidBecomeExclusiveNotification object:self] postingStyle:NSPostNow coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }

    if ([self isActive])
        return;

    _isActive = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeColorWhenActive:)
                                                 name:NSColorPanelColorDidChangeNotification
                                               object:[NSColorPanel sharedColorPanel]];
    [self setNeedsDisplay:YES];
}

-(void)deactivate {
    if (![self isActive])
        return;
    
    _isActive = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSColorPanelColorDidChangeNotification
                                                  object:[NSColorPanel sharedColorPanel]];
    [self setNeedsDisplay:YES];
}

-(void)changeColorWhenActive:(NSNotification *)note {
   [self setColor:[[note object] color]];
   [self sendAction:_action to:_target];
}

-(BOOL)isOpaque {
   return YES;
}

-(void)drawWellInside:(NSRect)rect {
    [_color drawSwatchInRect:rect];
}

-(void)drawRect:(NSRect)rect {
   rect=_bounds;

   rect=[[self graphicsStyle] drawColorWellBorderInRect:rect enabled:[self isEnabled] bordered:[self isBordered] active:[self isActive]];

   [self drawWellInside:rect];
}

-(void)mouseDown:(NSEvent *)event {

   if(![self isEnabled])
    return;

   if ([self isBordered]) {        
    BOOL    wasActive=[self isActive];
    NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];
    BOOL    mouseInBorder=!NSMouseInRect(point,NSInsetRect(_bounds,8,8),[self isFlipped]);

    if(mouseInBorder){
     do {            
      point=[self convertPoint:[event locationInWindow] fromView:nil];
      mouseInBorder=!NSMouseInRect(point,NSInsetRect(_bounds,8,8),[self isFlipped]);

      if (mouseInBorder) {
       if (wasActive)
        [self deactivate];
       else
        [self activate:NO];
      }
      else {
       if (wasActive)
        [self activate:NO];
       else
        [self deactivate];
      }
            
      event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
     } while ([event type] != NSLeftMouseUp);

     if ([self isActive] == YES) {
      if (!([event modifierFlags] & NSShiftKeyMask))
       [self activate:YES];
      [[NSColorPanel sharedColorPanel] setColor:[self color]];
      [NSApp orderFrontColorPanel:self];
     }
     return;
    }
   }

   [NSColorPanel dragColor:_color withEvent:event fromView:self];
}

-(unsigned)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
   return NSDragOperationCopy;
}

-(unsigned)draggingEntered:(id <NSDraggingInfo>)sender {
   return NSDragOperationCopy;
}

-(unsigned)draggingUpdated:(id <NSDraggingInfo>)sender {
   return NSDragOperationCopy;
}

-(BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
   return YES;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
   NSPasteboard *pboard=[sender draggingPasteboard];
   NSColor      *color=[NSColor colorFromPasteboard:pboard];

   [self setColor:color];
   [self sendAction:_action to:_target];

   return YES;
}


@end
