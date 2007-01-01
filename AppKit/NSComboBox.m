/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSComboBox.h>
#import <AppKit/NSComboBoxCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTextView.h>

@implementation NSComboBox

-(void)addItemWithObjectValue:(id)object {
   [[self cell] addItemWithObjectValue:object];
}

-(void)addItemsWithObjectValues:(NSArray *)objects {
   [[self cell] addItemsWithObjectValues:objects];
}

-(void)removeAllItems {
   [[self cell] removeAllItems];
}

-(int)indexOfItemWithObjectValue:(id)object {
   return [_cell indexOfItemWithObjectValue:object];
}

-(void)scrollItemAtIndexToVisible:(int)index {
   [[self cell] scrollItemAtIndexToVisible:index];
}

-(void)selectItemAtIndex:(int)index {
   [[self cell] selectItemAtIndex:index];
}

-(BOOL)completes {
   return [[self cell] completes];
}

-(void)setCompletes:(BOOL)completes {
   [[self cell] setCompletes:completes];
}

-(void)mouseDown:(NSEvent *)event {
   if(![[self cell] trackMouse:event inRect:[self bounds] ofView:self untilMouseUp:YES])
    [super mouseDown:event];
}

// hrm.. since the field editor has focus, we can use this delegate method to effect keyboard
// navigation.
// ...i also thought it might be fun to preserve the half-typed text in objectValue index 0...
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    int index = [[self cell] indexOfItemWithObjectValue:[self objectValue]];
    id objectCache = nil;

    if ([textView rangeForUserCompletion].location != NSNotFound)
        return NO;

    if (index == NSNotFound) {
        objectCache = [[self objectValue] retain];
        index = -1;
    }
    
    if (selector == @selector(moveUp:)) {
        [[self cell] selectItemAtIndex:index-1];
        [_currentEditor setString:[[self cell] objectValue]];
        if (objectCache != nil)
            [[self cell] insertItemWithObjectValue:[objectCache autorelease] atIndex:0];
        return YES;
    }
    else if (selector == @selector(moveDown:)) {
        [[self cell] selectItemAtIndex:index+1];
        [_currentEditor setString:[[self cell] objectValue]];
        if (objectCache != nil)
            [[self cell] insertItemWithObjectValue:[objectCache autorelease] atIndex:0];
        return YES;
    }

    return NO;
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)range indexOfSelectedItem:(int *)index {
    NSString *string = [[self cell] completedString:[[textView string] substringWithRange:range]];

//    NSLog(@"NSComboBox delegate OK: %@", string);

    if (string != nil) {
        *index = 0;
        return [NSArray arrayWithObject:string];
    }
    else {
        *index = -1;
        return nil;
    }
}

@end
