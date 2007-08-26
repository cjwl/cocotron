/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSButton.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>

@implementation NSButton

+(Class)cellClass {
   return [NSButtonCell class];
}

-(BOOL)resignFirstResponder {
   [self setNeedsDisplay:YES];
   return [super resignFirstResponder];
}

-(BOOL)isOpaque {
   return ![_cell isTransparent] && [_cell isBordered];
}

-(BOOL)isTransparent {
   return [_cell isTransparent];
}

-(NSString *)keyEquivalent {
   return [_cell keyEquivalent];
}

-(NSImage *)image {
   return [_cell image];
}

-(NSCellImagePosition)imagePosition {
   return [_cell imagePosition];
}

-(NSString *)title {
   return [_cell title];
}

-(int)state {
   return [_cell state];
}

-(BOOL)allowsMixedState {
   return [_cell allowsMixedState];
}

-(NSSound *)sound {
   return [_cell sound];
}

-(void)setTransparent:(BOOL)flag {
   [_cell setTransparent:flag];
   [self setNeedsDisplay:YES];
}

-(void)setKeyEquivalent:(NSString *)keyEquivalent {
   [_cell setKeyEquivalent:keyEquivalent];
}

-(void)setImage:(NSImage *)image {
   [_cell setImage:image];
   [self setNeedsDisplay:YES];
}

-(void)setImagePosition:(NSCellImagePosition)position {
   [_cell setImagePosition:position];
   [self setNeedsDisplay:YES];
}

-(void)setTitle:(NSString *)title {
   [_cell setTitle:title];
   [self setNeedsDisplay:YES];
}

-(void)setState:(int)value {
   [_cell setState:value];
   [self setNeedsDisplay:YES];
}

-(void)setNextState {
   [_cell setNextState];
   [self setNeedsDisplay:YES];
}

-(void)setAllowsMixedState:(BOOL)flag {
   [_cell setAllowsMixedState:flag];
}

-(void)setSound:(NSSound *)sound {
   [_cell setSound:sound];
}

-(unsigned)keyEquivalentModifierMask {
   return [_cell keyEquivalentModifierMask];
}

-(void)setKeyEquivalentModifierMask:(unsigned)mask {
   [_cell setKeyEquivalentModifierMask:mask];
}

-(BOOL)performKeyEquivalent:(NSEvent *)event {
   NSString *characters=[event charactersIgnoringModifiers];
   unsigned  modifiers=[event modifierFlags];

   if(![self isEnabled])
    return NO;

   if((modifiers&(NSCommandKeyMask|NSAlternateKeyMask))==[self keyEquivalentModifierMask]){
    NSString *key=[self keyEquivalent];

    if([key isEqualToString:characters]){
     [self performClick:nil];
     return YES;
    }
   }

   return NO;
}

-(void)performClick:sender {
   [self lockFocus];
   [_cell highlight:YES withFrame:[self bounds] inView:self];
   [self unlockFocus];
   [[self window] flushWindow];

   [[self cell] setState:[[self cell] nextState]];

   [self sendAction:[self action] to:[self target]];

   [self lockFocus];
   [_cell highlight:NO withFrame:[self bounds] inView:self];
   [self unlockFocus];
   [[self window] flushWindow];
}

-(void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

@end
