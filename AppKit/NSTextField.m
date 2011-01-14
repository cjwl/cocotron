/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSDragging.h>
#import "NSKeyValueBinding/NSTextFieldBinder.h"
#import "NSKeyValueBinding/NSObject+BindingSupport.h"

@implementation NSTextField

+(Class)cellClass {
   return [NSTextFieldCell class];
}

+(Class)_binderClassForBinding:(id)binding
{
  if ([binding isEqual:@"value"])
    return [_NSTextFieldBinder class];
  else
    return [super _binderClassForBinding:binding];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];
   [self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
   return self;
}

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
// Default for a NSTextFieldCell is NOT the same as NSTextField
   [_cell setEditable:YES];
   [_cell setSelectable:YES];
   [_cell setBezeled:YES];
   [self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
   return self;
}

-(BOOL)isFlipped { return YES; }

-(BOOL)isOpaque {
   return [_cell drawsBackground] || [_cell isBezeled];
}

-(void)resetCursorRects {
   [_cell resetCursorRect:[self bounds] inView:self];
}

-delegate {
   return _delegate;
}

-(void)setDelegate:delegate {
   NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
   struct {
    SEL       selector;
    NSString *name;
   } notes[]={
    { @selector(controlTextDidBeginEditing:), NSControlTextDidBeginEditingNotification },
    { @selector(controlTextDidChange:), NSControlTextDidChangeNotification },
    { @selector(controlTextDidEndEditing:), NSControlTextDidEndEditingNotification },
    { NULL, nil }
   };
   int i;

   if(_delegate!=nil)
    for(i=0;notes[i].selector!=NULL;i++)
     [center removeObserver:_delegate name:notes[i].name object:self];

   _delegate=delegate;

   for(i=0;notes[i].selector!=NULL;i++)
    if([_delegate respondsToSelector:notes[i].selector])
     [center addObserver:_delegate selector:notes[i].selector name:notes[i].name object:self];
}

-(NSColor *)backgroundColor {
   return [_cell backgroundColor];
}

-(NSColor *)textColor {
   return [_cell textColor];
}

-(BOOL)drawsBackground {
   return [_cell drawsBackground];
}

-(void)setBackgroundColor:(NSColor *)color {
   [_cell setBackgroundColor:color];
   [self setNeedsDisplay:YES];
}

-(void)setTextColor:(NSColor *)color {
   [_cell setTextColor:color];
   [self setNeedsDisplay:YES];
}

-(void)setDrawsBackground:(BOOL)flag {
   [_cell setDrawsBackground:flag];
   [self setNeedsDisplay:YES];
}

-(BOOL)acceptsFirstResponder {
   return YES;
}

-(BOOL)becomeFirstResponder {
   [self selectText:nil];
   return YES;
}

-(void)_selectTextWithRange:(NSRange)range {
   NSTextFieldCell *cell=[self selectedCell];

   if(![cell isEnabled])
    return;

   if([cell isEditable] || [cell isSelectable]){
    if(_currentEditor==nil){
     _currentEditor=[[self window] fieldEditor:YES forObject:self];
     _currentEditor=[cell setUpFieldEditorAttributes:_currentEditor];

     [_currentEditor retain];
    }

    [cell selectWithFrame:[self bounds] inView:self editor:_currentEditor delegate:self start:range.location length:range.length];
   }
}

-(void)selectText:sender {
   [self _selectTextWithRange:NSMakeRange(0,[[self stringValue] length])];
}


-(void)setPreviousText:text {
// FIX, not sure how to implement this
//   [self setPreviousKeyView:text];
}

-(void)setNextText:text {
   [self setNextKeyView:text];
}

-previousText {
   return [self previousKeyView];
}

-nextText {
   return [self nextKeyView];
}

-(void)textDidEndEditing:(NSNotification *)note {
   int movement=[[[note userInfo] objectForKey:@"NSTextMovement"] intValue];

   [super textDidEndEditing:note];

   if(movement==NSReturnTextMovement || [[self selectedCell] sendsActionOnEndEditing])
    [self sendAction:[self action] to:[self target]];

   if(movement==NSTabTextMovement)
    [[self window] selectKeyViewFollowingView:self];
    
   if (movement == NSBacktabTextMovement)
    [[self window] selectKeyViewPrecedingView:self];
}

// FIX do we need this? selectText: seems to do the job for us
-(void)mouseDown:(NSEvent *)event {
   NSTextFieldCell *cell=[self selectedCell];

   if(![cell isEnabled])
    return;

   NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];
   NSRect  editingFrame=[cell titleRectForBounds:[self bounds]];
   
   if(!NSMouseInRect(point,editingFrame,[self isFlipped]))
    [super mouseDown:event];
   else {
   if([cell isEditable] || [cell isSelectable]){
    if(_currentEditor==nil){
     _currentEditor=[[self window] fieldEditor:YES forObject:self];
     _currentEditor=[cell setUpFieldEditorAttributes:_currentEditor];
     [_currentEditor retain];
    }

    [cell editWithFrame:[self bounds] inView:self editor:_currentEditor delegate:self event:event];
   }
}
}

-(BOOL)textShouldBeginEditing:(NSText *)text {
   if ([_delegate respondsToSelector:@selector(control:textShouldBeginEditing:)])
     if ([_delegate control:self textShouldBeginEditing:text] == NO) {
       NSBeep();
       return NO;
     }
   return YES;
}

-(BOOL)textShouldEndEditing:(NSText *)text {
   if ([_delegate respondsToSelector:@selector(control:textShouldEndEditing:)])
     if ([_delegate control:self textShouldEndEditing:text] == NO) {
       NSBeep();
       return NO;
     }
   return YES;
}

-(void)setEditable:(BOOL)flag {
  [super setEditable:flag];
  [_currentEditor setEditable:[self isEditable]];
}

-(void)setSelectable:(BOOL)flag {
  [super setSelectable:flag];
  [_currentEditor setSelectable:[self isSelectable]];
}

-(void)setStringValue:(NSString *)value {
  [super setStringValue:value];
  [_currentEditor setString:[self stringValue]];
}

-(void)setFont:(NSFont *)font {
  [super setFont:font];
  [_currentEditor setFont:[self font]];
}

-(void)setAlignment:(NSTextAlignment)alignment {
  [super setAlignment:alignment];
  [_currentEditor setAlignment:[self alignment]];
}

-(void)setRefusesFirstResponder:(BOOL)flag {
   [_cell setRefusesFirstResponder:flag];
}

-(void)doCommandBySelector:(SEL)selector {
   BOOL didSelector=NO;
   
   if([_delegate respondsToSelector:@selector(control:textView:doCommandBySelector:)])
    didSelector=[_delegate control:self textView:(NSTextView *)_currentEditor doCommandBySelector:selector];
   
   if(!didSelector)
    [super doCommandBySelector:selector];
}

-(void)setTitleWithMnemonic:(NSString *)value {
   [self setStringValue:value];
}

@end
