/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSControl.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSClipView.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSRaise.h>
#import <AppKit/NSObject+BindingSupport.h>

NSString * const NSControlTextDidBeginEditingNotification=@"NSControlTextDidBeginEditingNotification";
NSString * const NSControlTextDidChangeNotification=@"NSControlTextDidChangeNotification";
NSString * const NSControlTextDidEndEditingNotification=@"NSControlTextDidEndEditingNotification";

@implementation NSControl

static NSMutableDictionary *cellClassDictionary = nil;

+(void)initialize {
    if (cellClassDictionary == nil)
        cellClassDictionary = [[NSMutableDictionary alloc] init];
}

+(Class)cellClass {
    if ([cellClassDictionary objectForKey:[[self class] description]] == nil)
        [self setCellClass:[NSCell class]];

    return [cellClassDictionary objectForKey:[[self class] description]];
}

+(void)setCellClass:(Class)aClass {
    [cellClassDictionary setObject:aClass forKey:[[self class] description]];
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [super encodeWithCoder:coder];
   [coder encodeObject:_cell forKey:@"NSControl cell"];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
	[self setCell:[keyed decodeObjectForKey:@"NSCell"]];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }

   return self;
}

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
// FIX, verify in subclasses
	[self setCell:[[[[[self class] cellClass] alloc] init] autorelease]];
   return self;
}

-(void)dealloc {

	// Don't do anything with the cell until we've cleared the bindings!
	[self _unbindAllBindings];
	
   [_cell release];
   [super dealloc];
}

-cell {
   return _cell;
}

-target {
   return [_cell target];
}

-(SEL)action {
   return [_cell action];
}

-(int)tag {
   return _tag;
}

-(NSFont *)font {
   return [_cell font];
}

-(NSImage *)image {
   return [[self cell] image];
}

-(NSTextAlignment)alignment {
   return [_cell alignment];
}

-(BOOL)isEnabled {
   return [_cell isEnabled];
}

-(BOOL)isEditable {
   return [_cell isEditable];
}

-(BOOL)isSelectable {
   return [_cell isSelectable];
}

-(BOOL)isScrollable {
   return [_cell isScrollable];
}

-(BOOL)isBordered {
   return [_cell isBordered];
}

-(BOOL)isBezeled {
   return [_cell isBezeled];
}

-(BOOL)isContinuous {
   return [_cell isContinuous];
}

-(BOOL)refusesFirstResponder {
   return [_cell refusesFirstResponder];
}

-(id)formatter {
   return [_cell formatter];
}

-objectValue {
   return [[self selectedCell] objectValue];
}

-(NSString *)stringValue {
   return [[self selectedCell] stringValue];
}

-(NSAttributedString *)attributedStringValue {
   return [[self selectedCell] attributedStringValue];
}

-(int)intValue {
   return [[self selectedCell] intValue];
}

-(float)floatValue {
   return [[self selectedCell] floatValue];
}

-(double)doubleValue {
   return [[self selectedCell] doubleValue];
}

-(NSInteger)integerValue {
   return [[self selectedCell] integerValue];
}

-selectedCell {
   return _cell;
}

-(int)selectedTag {
   return [[self selectedCell] tag];
}

-(void)setCell:(NSCell *)cell {
   cell=[cell retain];
   [_cell release];
   _cell=cell;
}

-(void)setTarget:target {
   [_cell setTarget:target];
}

-(void)setAction:(SEL)action {
   [_cell setAction:action];
}

-(void)setTag:(int)tag {
   _tag=tag;
}

-(void)setFont:(NSFont *)font {
   [_cell setFont:font];
   [self setNeedsDisplay:YES];
}

-(void)setImage:(NSImage *)image {
   [[self cell] setImage:image];
   [self setNeedsDisplay:YES];
}

-(void)setAlignment:(NSTextAlignment)alignment {
   [_cell setAlignment:alignment];
   [self setNeedsDisplay:YES];
}

-(void)setFloatingPointFormat:(BOOL)fpp left:(unsigned)left right:(unsigned)right {
   [_cell setFloatingPointFormat:fpp left:left right:right];
}

-(void)setEnabled:(BOOL)flag {
   [_cell setEnabled:flag];
   [self setNeedsDisplay:YES];
}

-(void)setEditable:(BOOL)flag {
   [_cell setEditable:flag];
}

-(void)setSelectable:(BOOL)flag {
   [_cell setSelectable:flag];
}

-(void)setScrollable:(BOOL)flag {
   [_cell setScrollable:flag];
}

-(void)setBordered:(BOOL)flag {
   [_cell setBordered:flag];
   [self setNeedsDisplay:YES];
}

-(void)setBezeled:(BOOL)flag {
   [_cell setBezeled:flag];
   [self setNeedsDisplay:YES];
}

-(void)setContinuous:(BOOL)flag {
   [_cell setContinuous:flag];
}

-(void)setRefusesFirstResponder:(BOOL)flag {
   [_cell setRefusesFirstResponder:flag];
}

-(void)setFormatter:(NSFormatter *)formatter {
   [_cell setFormatter:formatter];
   [self setNeedsDisplay:YES];
}

-(void)setObjectValue:(id <NSCopying>)object {
// FIX protocol does not implement isEqual
   if(![(id)object isEqual:[[self selectedCell] objectValue]]){
    [self abortEditing];
    [(NSCell *)[self selectedCell] setObjectValue:object];
    [self setNeedsDisplay:YES];
   }
}

-(void)setStringValue:(NSString *)value {
   [self setObjectValue:value];
}

-(void)setIntValue:(int)value {
   [self setObjectValue:[NSNumber numberWithInt:value]];
}

-(void)setFloatValue:(float)value {
   [self setObjectValue:[NSNumber numberWithFloat:value]];
}

-(void)setDoubleValue:(double)value {
   [self setObjectValue:[NSNumber numberWithDouble:value]];
}

-(void)setIntegerValue:(NSInteger)value {
   [self setObjectValue:[NSNumber numberWithInteger:value]];
}

-(void)setAttributedStringValue:(NSAttributedString *)value {
   [self setObjectValue:value];
}

-(void)takeObjectValueFrom:sender {
   [self setObjectValue:[sender objectValue]];
}

-(void)takeStringValueFrom:sender {
   [self setStringValue:[sender stringValue]];
}

-(void)takeIntValueFrom:sender {
   [self setIntValue:[sender intValue]];
}

-(void)takeFloatValueFrom:sender {
   [self setFloatValue:[sender floatValue]];
}

-(void)takeDoubleValueFrom:sender {
   [self setDoubleValue:[sender doubleValue]];
}

-(void)takeIntegerValueFrom:sender {
   [self setIntegerValue:[sender integerValue]];
}

-(void)selectCell:(NSCell *)cell {
    if (_cell == cell) {
        [_cell setState:YES];
        [self setNeedsDisplay:YES];
    }
}

-(void)drawCell:(NSCell *)cell {
    if (_cell == cell){
        [_cell setControlView:self];
        [_cell drawWithFrame:_bounds inView:self];
    }
}

-(void)drawCellInside:(NSCell *)cell {
    if (_cell == cell)
        [_cell drawInteriorWithFrame:_bounds inView:self];
}

-(void)updateCell:(NSCell *)cell {
    if (_cell == cell)
	{
		[self willChangeValueForKey:@"objectValue"];
		[self didChangeValueForKey:@"objectValue"];
        [self setNeedsDisplay:YES];
	}
}


-(void)updateCellInside:(NSCell *)cell {
    if (_cell == cell)
        [self setNeedsDisplay:YES];
}

// Hmm, shouldn't this just noop?
-(void)performClick:sender {
//   NSUnimplementedMethod();
}

-(BOOL)sendAction:(SEL)action to:target {
   return [NSApp sendAction:action to:target from:self];
}

-(NSText *)currentEditor {
   return _currentEditor;
}

-(void)validateEditing {
   NSUnimplementedMethod();
}

-(BOOL)abortEditing {
   if(_currentEditor!=nil){
// this may be invalid after endEditingFor: if we dont retain it
    NSView *superview=[[[_currentEditor superview] retain] autorelease];

// we don't want delegate messages when aborting
    [_currentEditor setDelegate:nil];
    
    [[self window] endEditingFor:self];

    if([superview isKindOfClass:[NSClipView class]])
     [superview removeFromSuperview];

    [_currentEditor release];
    _currentEditor=nil;
   }
   return NO;
}

-(void)calcSize {
   // do nothing
}

-(void)sizeToFit {
   NSSize cellSize=[[self cell] cellSize];
   
   [self setFrameSize:cellSize];
}

-(void)setNeedsDisplay {
   [self setNeedsDisplay:YES];
}

-(BOOL)acceptsFirstResponder {
   return ![self refusesFirstResponder];
}

-(void)lockFocus {
   [self calcSize];
   [super lockFocus];
}

-(void)textDidBeginEditing:(NSNotification *)note {
   if([note object]!=_currentEditor)
    return;

   [[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidBeginEditingNotification
     object:self userInfo:[NSDictionary dictionaryWithObject:[note object] forKey:@"NSFieldEditor"]];
  
   // If this control's value is bound to an object that conforms to NSEditorRegistration, register as an editor.
   NSDictionary * bindingInfo = [self infoForBinding:@"value"];
   if (bindingInfo)
     {
       id observedObject = [bindingInfo objectForKey:NSObservedObjectKey];
       if ([observedObject respondsToSelector:@selector(objectDidBeginEditing:)])
         [observedObject objectDidBeginEditing:self];
     }
}

-(void)textDidChange:(NSNotification *)note {
   if([note object]!=_currentEditor)
    return;

// FIX, Add formatter logic here
   [[self selectedCell] setStringValue:[[note object] string]];

   [[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification
     object:self userInfo:[NSDictionary dictionaryWithObject:[note object] forKey:@"NSFieldEditor"]];
}

-(void)textDidEndEditing:(NSNotification *)note {
// It is possible for an NSControl subclass to be the delegate of another text view
	if([note object]!=_currentEditor)
    return;

   [[self selectedCell] endEditing:_currentEditor];
   [self abortEditing];

   [[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidEndEditingNotification
     object:self userInfo:[NSDictionary dictionaryWithObject:[note object] forKey:@"NSFieldEditor"]];

   // If this control's value is bound to an object that conforms to NSEditorRegistration, unregister as an editor.
   NSDictionary * bindingInfo = [self infoForBinding:@"value"];
   if (bindingInfo)
     {
       id observedObject = [bindingInfo objectForKey:NSObservedObjectKey];
       if ([observedObject respondsToSelector:@selector(objectDidEndEditing:)])
         [observedObject objectDidEndEditing:self];
     }
  
   [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)rect {
   [_cell setControlView:self];
   [_cell drawWithFrame:_bounds inView:self];
}

-(void)mouseDown:(NSEvent *)event {
   BOOL sendAction=NO;

   if(![self isEnabled])
    return;

   [self lockFocus];

   do {
    NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];

    if(NSMouseInRect(point,[self bounds],[self isFlipped])){
     [_cell highlight:YES withFrame:[self bounds] inView:self];
     [self setNeedsDisplay:YES];

     if([_cell trackMouse:event inRect:[self bounds] ofView:self untilMouseUp: [[_cell class] prefersTrackingUntilMouseUp]]){
      [_cell setState:![_cell state]];
      [self setNeedsDisplay:YES];
      sendAction=YES;
      break;
     }

     [_cell highlight:NO withFrame:[self bounds] inView:self];
     [self setNeedsDisplay:YES];
    }

    [[self window] flushWindow];
    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
   }while([event type]!=NSLeftMouseUp);

   [self unlockFocus];

   if(sendAction){
    [self sendAction:[self action] to:[self target]];
    [self lockFocus];
    [_cell highlight:NO withFrame:[self bounds] inView:self];
    [self unlockFocus];
    [self setNeedsDisplay:YES];
   }
}

// NSEditor methods

-(BOOL)commitEditing {
  [self validateEditing];
  return YES;
}

- (void)discardEditing {
  [self abortEditing];
}

@end
