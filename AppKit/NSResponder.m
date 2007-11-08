/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSResponder.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSKeyBindingManager.h>
#import <AppKit/NSKeyBinding.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSGraphics.h>

@implementation NSResponder

-(void)encodeWithCoder:(NSCoder *)encoder {
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    // NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    //; _nextResponder=[keyed decodeObjectForKey:@"NSNextResponder"]; 
   }
   return self;
}

-(NSResponder *)nextResponder {
   return _nextResponder;
}

-(NSMenu *)menu {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSUndoManager *)undoManager {
    return [_nextResponder performSelector:_cmd];
}

-(void)setNextResponder:(NSResponder *)responder {
   _nextResponder=responder;
}

-(void)setMenu:(NSMenu *)menu {
   NSInvalidAbstractInvocation();
}

-validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
   NSUnimplementedMethod();
   return nil;
}

-(void)doCommandBySelector:(SEL)selector {
   //NSLog(@"checking %@...",  self);
    if([self respondsToSelector:selector]) {
      // NSLog(@"...%@ responds to %@", self, NSStringFromSelector(selector));
        [self performSelector:selector withObject:nil];
    }
    else
        [_nextResponder doCommandBySelector:selector];
}

-(void)interpretKeyEvents:(NSArray *)events {
   int i,count=[events count];

   for(i=0;i<count;i++){
    NSEvent      *event=[events objectAtIndex:i];
    NSString     *string=[event charactersIgnoringModifiers];
    NSKeyBinding *keyBinding=[[NSKeyBindingManager defaultKeyBindingManager] keyBindingWithString:string modifierFlags:[event modifierFlags]];
    NSArray      *selectorNames=[keyBinding selectorNames];

    if(selectorNames!=nil){
     int i = 0, count = [selectorNames count];

     for (i = 0; i < count; ++i) {
      //  NSLog(@"doing %@ for %@", [selectorNames objectAtIndex:i], keyBinding);
      [self doCommandBySelector:NSSelectorFromString([selectorNames objectAtIndex:i])];
     }
    }
    else if([self respondsToSelector:@selector(insertText:)]){
     string=[event characters];
 
     if([string length]>0){ // FIX THIS IN APPKIT shouldnt get 0 length 

      unsigned i,length=[string length];
      unichar  buffer[length];

      [string getCharacters:buffer];
      for(i=0;i<length;i++){
       unichar check=buffer[i];

       if(check>=NSUpArrowFunctionKey)
        check=' ';
       else if(check<' ')
        check=' ';

       buffer[i]=check;
      }
      string=[NSString stringWithCharacters:buffer length:length];
      [self insertText:string];
     }
    }
   }
}

-(BOOL)performKeyEquivalent:(NSEvent *)event {
   return NO;
}

-(BOOL)tryToPerform:(SEL)action with:object {
   if([self respondsToSelector:action]){
    [self performSelector:action withObject:object];
    return YES;
   }

   return [_nextResponder tryToPerform:action with:object];
}

-(void)noResponderFor:(SEL)action {
   if(action==@selector(keyDown:))
    NSBeep();
}

-(BOOL)acceptsFirstResponder {
   return NO;
}

-(BOOL)becomeFirstResponder {
   return YES;
}

-(BOOL)resignFirstResponder {
   return YES;
}

-(void)flagsChanged:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)keyUp:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)keyDown:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)scrollWheel:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseUp:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseDown:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseMoved:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseEntered:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseExited:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)mouseDragged:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)rightMouseUp:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)rightMouseDown:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)rightMouseDragged:(NSEvent *)event {
   [_nextResponder performSelector:_cmd withObject:event];
}

-(void)noop:sender {
}

@end
