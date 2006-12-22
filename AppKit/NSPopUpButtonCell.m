/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>, David Young <daver@geeks.org>
#import <AppKit/NSPopUpButtonCell.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPopUpWindow.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSPopUpButtonCell

-(void)encodeWithCoder:(NSCoder *)coder {
   [super encodeWithCoder:coder];
   [coder encodeBool:_pullsDown forKey:@"NSPopUpButtonCell pullsDown"];
   [coder encodeInt:_selectedIndex forKey:@"NSPopUpButtonCell selectedIndex"];
   [coder encodeObject:_menu forKey:@"NSPopUpButtonCell menu"];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
 
    _pullsDown=[coder decodeBoolForKey:@"NSPullDown"];
    _menu=[[coder decodeObjectForKey:@"NSMenu"] retain];
    _selectedIndex=[[_menu itemArray] indexOfObjectIdenticalTo:[coder decodeObjectForKey:@"NSMenuItem"]];
    
    if(_selectedIndex<0 && [_menu itemArray]>0)
     _selectedIndex=0;
   }
   else {
    _pullsDown=[coder decodeBoolForKey:@"NSPopUpButtonCell pullsDown"];
    _selectedIndex=[coder decodeIntForKey:@"NSPopUpButtonCell selectedIndex"];
    _menu=[[coder decodeObjectForKey:@"NSPopUpButtonCell menu"] retain];
   }
   return self;
}

-(void)awakeFromNib {
}


-copyWithZone:(NSZone *)zone {
    NSPopUpButtonCell *copy = [super copyWithZone:zone];

    copy->_menu = [_menu copy];

    return copy;
}

-initTextCell:(NSString *)string pullsDown:(BOOL)pullDown
{
    [super initTextCell:string];
    _menu = [[NSMenu alloc] initWithTitle:string];
    [_menu addItemWithTitle:string action:[self action] keyEquivalent:@""];
        
    [self setPullsDown:pullDown];
    
    return self;
}

-(void)dealloc {
   [_menu release];
   [super dealloc];
}

-(BOOL)pullsDown
{
    return _pullsDown;
}

-(NSMenu *)menu
{
    return _menu;
}

-(int)numberOfItems {
   return [_menu numberOfItems];
}

-(NSMenuItem *)itemAtIndex:(int)index {
   return [_menu itemAtIndex:index];
}

-(NSMenuItem *)itemWithTitle:(NSString *)title {
   return [_menu itemWithTitle:title];
}

-(int)indexOfItemWithTitle:(NSString *)title {
   return [_menu indexOfItemWithTitle:title];
}

-(int)indexOfItemWithTag:(int)tag {
   return [_menu indexOfItemWithTag:tag];
}

-(NSMenuItem *)selectedItem {
   return [_menu itemAtIndex:_selectedIndex];
}

-(NSString *)titleOfSelectedItem {
   return [[self selectedItem] title];
}

-(int)indexOfSelectedItem {
   return _selectedIndex;
}

-(void)setPullsDown:(BOOL)flag
{
    _pullsDown = flag;
}

-(void)setMenu:(NSMenu *)menu
{
    [_menu release];
    _menu = [_menu retain];
}

-(void)addItemWithTitle:(NSString *)title {
   [_menu addItemWithTitle:title action:NULL keyEquivalent:nil];
}

-(void)addItemsWithTitles:(NSArray *)titles {
   int i,count=[titles count];

   for(i=0;i<count;i++)
    [self addItemWithTitle:[titles objectAtIndex:i]];
}

-(void)removeAllItems {
   [_menu removeAllItems];
}

-(void)removeItemAtIndex:(int)index {
   [_menu removeItemAtIndex:index];
}

-(void)insertItemWithTitle:(NSString *)title atIndex:(int)index {
   NSUnimplementedMethod();
}

-(NSImage *)image {
   if(_pullsDown)
    return [NSImage imageNamed:@"NSPopUpButtonCellPullDown"];
   else
    return [NSImage imageNamed:@"NSPopUpButtonCellPopUp"];
}

-(void)selectItemAtIndex:(int)index {
   _selectedIndex=index;
}

-(void)selectItemWithTitle:(NSString *)title {
   [self selectItemAtIndex:[self indexOfItemWithTitle:title]];
}

-(NSCellImagePosition)imagePosition {
   return NSImageRight;
}

-(NSString *)title {
   NSArray *items=[_menu itemArray];

   if(_selectedIndex<0 || _selectedIndex>=[items count])
    return @"**ERROR**";

   if(_pullsDown)
    return [[items objectAtIndex:0] title];
   else
    return [[items objectAtIndex:_selectedIndex] title];
}

-(int)tag {
   return [[_menu itemAtIndex:_selectedIndex] tag];
}

-(BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
   NSPopUpWindow *window;
   NSPoint        origin=[controlView bounds].origin;

   origin=[controlView convertPoint:origin toView:nil];
   origin=[[controlView window] convertBaseToScreen:origin];

   window=[[NSPopUpWindow alloc] initWithFrame:NSMakeRect(origin.x,origin.y,
     cellFrame.size.width,cellFrame.size.height)];
   [window setMenu:_menu];
   if([self font]!=nil)
    [window setFont:[self font]];

   if(_pullsDown)
    [window selectItemAtIndex:0];
   else
    [window selectItemAtIndex:_selectedIndex];

   _selectedIndex=[window runTrackingWithEvent:event];
   [window close]; // release when closed=YES

   return YES;
}

- (void)moveUp:(id)sender {
    int index = [self indexOfSelectedItem];
    
    if (index > 0)
        [self selectItemAtIndex:index-1];
}

- (void)moveDown:(id)sender {
    int index = [self indexOfSelectedItem];
    
    if (index < [self numberOfItems]-1)
        [self selectItemAtIndex:index+1];
}

@end
