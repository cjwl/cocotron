/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Completion - David Young <daver@geeks.org>
// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSComboBoxCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSComboBoxWindow.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSGraphicsStyle.h>

@implementation NSComboBoxCell

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    _objectValues=[[NSMutableArray alloc] initWithArray:[keyed decodeObjectForKey:@"NSPopUpListData"]];
    _numberOfVisibleItems=[keyed decodeIntForKey:@"NSVisibleItemCount"];
    _completes=[keyed decodeBoolForKey:@"NSCompletes"];
    _buttonBordered=YES;
    _buttonEnabled=YES;
    _buttonPressed=NO;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }

   return self;
}

-(void)dealloc {
   [_objectValues release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
    NSComboBoxCell *copy = [super copyWithZone:zone];

    copy->_objectValues=[_objectValues copy];

    return copy;
}

-(void)addItemWithObjectValue:(id)object {
   [_objectValues addObject:object];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)addItemsWithObjectValues:(NSArray *)objects {
   [_objectValues addObjectsFromArray:objects];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

- (void)insertItemWithObjectValue:(id)object atIndex:(int)index {
    [_objectValues insertObject:object atIndex:index];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)removeAllItems {
   [_objectValues removeAllObjects];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(int)indexOfItemWithObjectValue:(id)object {
   return [_objectValues indexOfObjectIdenticalTo:object];
}

-(void)scrollItemAtIndexToVisible:(int)index {
}

-(void)selectItemAtIndex:(int)index {
    if (index < 0 || index >= [_objectValues count])
        return;

    [self setObjectValue:[_objectValues objectAtIndex:index]];
}

-(BOOL)completes {
   return _completes;
}

-(void)setCompletes:(BOOL)flag {
   _completes=flag;
}

- (NSString *)completedString:(NSString *)string {
    int i, count = [_objectValues count];
    
    if (_usesDataSource == YES)		// not supported yet, well...
        if ([_dataSource respondsToSelector:@selector(comboBoxCell:completedString:)] == YES)
            return [_dataSource comboBoxCell:self completedString:string];

    for (i = 0; i < count; ++i) {
        NSString *stringValue;

//        NSLog(@"checking %@",  [_objectValues objectAtIndex:i]);
        if ([[_objectValues objectAtIndex:i] isKindOfClass:[NSString class]])
            stringValue = [_objectValues objectAtIndex:i];
        else
            stringValue = [[_objectValues objectAtIndex:i] stringValue];
        
        if ([stringValue hasPrefix:string])
            return stringValue;
    }

    return nil;
}

-(NSRect)buttonRectForBounds:(NSRect)rect {
   rect.origin.x=(rect.origin.x+rect.size.width)-rect.size.height;
   rect.size.width=rect.size.height;
   return NSInsetRect(rect,2,2);
}

-(BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
   NSComboBoxWindow *window;
   NSPoint           origin=[controlView bounds].origin;
   NSPoint           check=[controlView convertPoint:[event locationInWindow] fromView:nil];
   unsigned          selectedIndex;

   if([_objectValues count]==0)
    return NO;

   if(!NSMouseInRect(check,[self buttonRectForBounds:cellFrame],[controlView isFlipped]))
    return NO;

   origin.y+=[controlView bounds].size.height;
   origin=[controlView convertPoint:origin toView:nil];
   origin=[[controlView window] convertBaseToScreen:origin];

   window=[[NSComboBoxWindow alloc] initWithFrame:NSMakeRect(origin.x,origin.y,
     cellFrame.size.width,cellFrame.size.height)];

   [window setObjectArray:_objectValues];
   if([self font]!=nil)
    [window setFont:[self font]];

   _buttonPressed=YES;
   [controlView setNeedsDisplay:YES];
   selectedIndex=[window runTrackingWithEvent:event];
   [window close]; // release when closed=YES
   _buttonPressed=NO;
   [controlView setNeedsDisplay:YES];

   if(selectedIndex!=NSNotFound){
    NSControl *control=(NSControl *)controlView;

    [control setObjectValue:[_objectValues objectAtIndex:selectedIndex]];
    [control sendAction:[control action] to:[control target]];
   }

   return YES;
}

-(NSRect)titleRectForBounds:(NSRect)rect {
   rect=[super titleRectForBounds:rect];

   rect.size.width-=rect.size.height;

   return rect;
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
   [super drawWithFrame:frame inView:controlView];

   [[controlView graphicsStyle] drawComboBoxButtonInRect:[self buttonRectForBounds:frame] enabled:_buttonEnabled bordered:_buttonBordered pressed:_buttonPressed];
}

@end
