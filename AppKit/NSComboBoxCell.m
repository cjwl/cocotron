/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSComboBoxCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSComboBoxWindow.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSRaise.h>

@implementation NSComboBoxCell

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
    _dataSource=[keyed decodeObjectForKey:@"NSDataSource"];
    _objectValues=[[NSMutableArray alloc] initWithArray:[keyed decodeObjectForKey:@"NSPopUpListData"]];
    _numberOfVisibleItems=[keyed decodeIntForKey:@"NSVisibleItemCount"];
    _usesDataSource=[keyed decodeBoolForKey:@"NSUsesDataSource"];
    _hasVerticalScroller=[keyed decodeBoolForKey:@"NSHasVerticalScroller"];
    _completes=[keyed decodeBoolForKey:@"NSCompletes"];
    _isButtonBordered=YES;
    _buttonEnabled=YES;
    _buttonPressed=NO;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }

   return self;
}

-(void)dealloc {
   [_dataSource release];
   [_objectValues release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
    NSComboBoxCell *copy = [super copyWithZone:zone];

    copy->_objectValues=[_objectValues copy];

    return copy;
}

-dataSource {
   return _dataSource;
}

-(BOOL)usesDataSource {
   return _usesDataSource;
}

-(BOOL)isButtonBordered {
   return _isButtonBordered;
}

-(float)itemHeight {
   return _itemHeight;
}

-(BOOL)hasVerticalScroller {
   return _hasVerticalScroller;
}

-(NSSize)intercellSpacing {
   return _intercellSpacing;
}

-(BOOL)completes {
   return _completes;
}

-(int)numberOfVisibleItems {
   return _numberOfVisibleItems;
}

-(void)setDataSource:value {
   _dataSource=value;
}

-(void)setUsesDataSource:(BOOL)value {
   _usesDataSource=value;
}

-(void)setButtonBordered:(BOOL)value {
   _isButtonBordered=value;
}

-(void)setItemHeight:(float)value {
   _itemHeight=value;
}

-(void)setHasVerticalScroller:(BOOL)value {
   _hasVerticalScroller=value;
}

-(void)setIntercellSpacing:(NSSize)value {
   _intercellSpacing=value;
}

-(void)setCompletes:(BOOL)flag {
   _completes=flag;
}

-(void)setNumberOfVisibleItems:(int)value {
   _numberOfVisibleItems=value;
}

-(int)numberOfItems {
   return [_objectValues count];
}

-(NSArray *)objectValues {
   return _objectValues;
}

-itemObjectValueAtIndex:(int)index {
   return [_objectValues objectAtIndex:index];
}

-(int)indexOfItemWithObjectValue:(id)object {
   return [_objectValues indexOfObjectIdenticalTo:object];
}

-(void)addItemWithObjectValue:(id)object {
   [_objectValues addObject:object];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)addItemsWithObjectValues:(NSArray *)objects {
   [_objectValues addObjectsFromArray:objects];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)removeAllItems {
   [_objectValues removeAllObjects];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)removeItemAtIndex:(int)index {
   [_objectValues removeObjectAtIndex:index];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)removeItemWithObjectValue:value {
   [_objectValues removeObject:value];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(void)insertItemWithObjectValue:(id)object atIndex:(int)index {
   [_objectValues insertObject:object atIndex:index];
   _buttonEnabled=([_objectValues count]>0)?YES:NO;
}

-(int)indexOfSelectedItem {
   int index = [_objectValues indexOfObject:[self objectValue]];
   return (index != NSNotFound)?index:-1;
}

-objectValueOfSelectedItem {
   if (!_usesDataSource)
     return [self objectValue];
   else
   {
     NSLog(@"*** -[%@ %s] should not be called when usesDataSource is set to YES",isa,sel_getName(_cmd));
     return NULL;
   }
}

-(void)selectItemAtIndex:(int)index {
    if (index < 0 || index >= [_objectValues count])
        return;

    [self setObjectValue:[_objectValues objectAtIndex:index]];
}

-(void)selectItemWithObjectValue:value {
   if (!_usesDataSource)
   {
      int index = [_objectValues indexOfObject:value];
      [self selectItemAtIndex:(index != NSNotFound)?index:-1];
   }
   else
      NSLog(@"*** -[%@ %s] should not be called when usesDataSource is set to YES",isa,sel_getName(_cmd));
}

-(void)deselectItemAtIndex:(int)index {
   NSUnimplementedMethod();
}

-(void)scrollItemAtIndexToTop:(int)index {
   NSUnimplementedMethod();
}

-(void)scrollItemAtIndexToVisible:(int)index {
   NSUnimplementedMethod();
}

-(void)noteNumberOfItemsChanged {
   NSUnimplementedMethod();
}

-(void)reloadData {
   NSUnimplementedMethod();
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
   BOOL              saveSendsActionOnEndEditing = _sendsActionOnEndEditing;
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

    // the superclass NSTextFieldCell would send the action on endEditing
    // before our new value is set. Therefore _sendsActionOnEndEditing
    // should be temporarily set to NO
    _sendsActionOnEndEditing = NO;
    [control setObjectValue:[_objectValues objectAtIndex:selectedIndex]];
    _sendsActionOnEndEditing = saveSendsActionOnEndEditing; // restore _sendsActionOnEndEditing 
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

   [[controlView graphicsStyle] drawComboBoxButtonInRect:[self buttonRectForBounds:frame] enabled:_buttonEnabled bordered:_isButtonBordered pressed:_buttonPressed];
}

@end
