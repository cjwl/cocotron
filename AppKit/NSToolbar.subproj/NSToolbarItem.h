/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

@class NSString;
@class NSImage, NSView, NSMenuItem;
@class NSToolbar;

APPKIT_EXPORT NSString *NSToolbarCustomizeToolbarItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarFlexibleSpaceItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarPrintItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarSeparatorItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowColorsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarShowFontsItemIdentifier;
APPKIT_EXPORT NSString *NSToolbarSpaceItemIdentifier;


@interface NSToolbarItem : NSObject <NSCopying>  // <NSValidatedUserInterfaceItem>
{
   NSString   *_itemIdentifier;
   NSToolbar  *_toolbar;
    
   NSImage    *_image;
   NSString   *_label;
   NSString   *_paletteLabel;
    
   NSMenuItem *_menuFormRepresentation;
    
   id _view; 
    
   NSSize _minSize;
   NSSize _maxSize;
}

-initWithItemIdentifier:(NSString *)identifier;

-(NSString *)itemIdentifier;
-(NSToolbar *)toolbar;

-(NSString *)label;
-(NSString *)paletteLabel;
-(NSMenuItem *)menuFormRepresentation;
-(NSView *)view;
-(NSSize)minSize;
-(NSSize)maxSize;
-(BOOL)allowsDuplicatesInToolbar;

-(void)setLabel:(NSString *)label;
-(void)setPaletteLabel:(NSString *)label;
-(void)setMenuFormRepresentation:(NSMenuItem *)menuItem;
-(void)setView:(NSView *)view;
-(void)setMinSize:(NSSize)size;
-(void)setMaxSize:(NSSize)size;

-(NSImage *)image;
-target;
-(SEL)action;
-(int)tag;
-(BOOL)isEnabled;
-(NSString *)toolTip;

-(void)setImage:(NSImage*)image;
-(void)setTarget:target;
-(void)setAction:(SEL)action;
-(void)setTag:(int)tag;  
-(void)setEnabled:(BOOL)enabled;
-(void)setToolTip:(NSString *)tip;

-(void)validate;

@end

@interface NSObject(NSToolbarItem_validation)
-(BOOL)validateToolbarItem:(NSToolbarItem *)item;
@end

