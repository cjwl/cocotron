/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSButton.h>
#import <AppKit/NSMenuItem.h>

@interface NSPopUpButton : NSButton

-(id)initWithFrame:(NSRect)frame pullsDown:(BOOL)pullsDown;

-(BOOL)pullsDown;
-(NSMenu *)menu;
-(NSArray *)itemArray;
-(int)numberOfItems;

-(NSMenuItem *)itemAtIndex:(int)index;
-(NSMenuItem *)itemWithTitle:(NSString *)title;

-(int)indexOfItemWithTitle:(NSString *)title;
-(int)indexOfItemWithTag:(int)tag;

-(NSMenuItem *)selectedItem;
-(NSString *)titleOfSelectedItem;
-(int)indexOfSelectedItem;

-(void)setPullsDown:(BOOL)flag;
-(void)setMenu:(NSMenu *)menu;

-(void)addItemWithTitle:(NSString *)title;
-(void)addItemsWithTitles:(NSArray *)titles;

-(void)removeAllItems;
-(void)removeItemAtIndex:(int)index;

-(void)insertItemWithTitle:(NSString *)title atIndex:(int)index;

-(void)selectItemAtIndex:(int)index;
-(void)selectItemWithTitle:(NSString *)title;
-(BOOL)selectItemWithTag:(int)tag;

- (NSMenuItem *)lastItem;

@end
