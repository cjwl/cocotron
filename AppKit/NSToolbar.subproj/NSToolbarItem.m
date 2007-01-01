/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarButton.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSStandardToolbarItems.h>
#import <AppKit/NSView.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSStringDrawer.h>

NSString *NSToolbarCustomizeToolbarItemIdentifier = @"NSToolbarCustomizeToolbarItem";
NSString *NSToolbarFlexibleSpaceItemIdentifier = @"NSToolbarFlexibleSpaceItem";
NSString *NSToolbarPrintItemIdentifier = @"NSToolbarPrintItem";
NSString *NSToolbarSeparatorItemIdentifier = @"NSToolbarSeparatorItem";
NSString *NSToolbarShowColorsItemIdentifier = @"NSToolbarShowColorsItem";
NSString *NSToolbarShowFontsItemIdentifier = @"NSToolbarShowFontsItem";
NSString *NSToolbarSpaceItemIdentifier = @"NSToolbarSpaceItem";

@implementation NSToolbarItem

extern NSSize _NSToolbarSizeRegular;
extern NSSize _NSToolbarSizeSmall;
extern NSSize _NSToolbarIconSizeRegular;
extern NSSize _NSToolbarIconSizeSmall;

-initWithItemIdentifier:(NSString *)identifier
{
    _itemIdentifier = [identifier retain];
        
    [self setView:[[[NSToolbarButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)] autorelease]];
        
    [self setEnabled:YES];
    
    return self;
}

- (void)dealloc
{
    [_itemIdentifier release];
    [_label release];
    [_paletteLabel release];
    
    [_menuFormRepresentation release];    
    [_view release];
    
    [super dealloc];
}

- copyWithZone:(NSZone *)zone
{
    NSToolbarItem *copy = NSCopyObject(self, 0, zone);

    copy->_itemIdentifier = [_itemIdentifier copy];
    copy->_image = [_image retain];
    copy->_label = [_label copy];
    copy->_paletteLabel = [_paletteLabel copy];
    
    copy->_menuFormRepresentation = nil;    // hmm? correct?
    copy->_view = [_view copy];
    
    return copy;
}

// i forsee a need for this..
- (void)_setToolbar:(NSToolbar *)toolbar
{
    _toolbar = toolbar;
}

- (NSString *)itemIdentifier
{
    return _itemIdentifier;
}

- (NSToolbar *)toolbar
{
    return _toolbar;
}

- (NSString *)label
{
    return _label;
}

- (NSString *)paletteLabel
{
    return _paletteLabel;
}

// By default, this method returns a singleton menu item with item label as the title.  For standard items, the target, action is set.
- (NSMenuItem *)menuFormRepresentation
{
    // FIX should update standard item for action/target/label changes?
    if (_menuFormRepresentation == nil && [self label] != nil) {
        _menuFormRepresentation = [[NSMenuItem alloc] initWithTitle:[self label] action:[self action] keyEquivalent:@""];
        [_menuFormRepresentation setImage:[self image]];
        [_menuFormRepresentation setTarget:[self target]];
        [_menuFormRepresentation setRepresentedObject:self];
    }
    
    return _menuFormRepresentation;
}

- (NSView *)view
{
    return _view;
}

- (NSSize)minSize
{
    NSSize size = _minSize;
    NSSize imageSize = [[self image] size];
    NSSize titleSize = [[self label] sizeWithAttributes:[NSToolbarView attributesWithSizeMode:[[self toolbar] sizeMode]]];
    float width = MAX(imageSize.width, titleSize.width);
    float height = MAX(imageSize.height, titleSize.height);
    
    size.width = MAX(_minSize.width, width);
    size.height = MAX(_minSize.height, height);

    return size;
}

- (NSSize)maxSize
{
    return _maxSize;
}

- (BOOL)allowsDuplicatesInToolbar
{
    return NO;
}

- (void)setLabel:(NSString *)label
{
    [_label release];
    _label = [label retain];

    // not standard, but makes sense...
    if ([_view respondsToSelector:@selector(setTitle:)])
        [_view setTitle:[self label]];
}

- (void)setPaletteLabel:(NSString *)label
{
    [_paletteLabel release];
    _paletteLabel = [label retain];
}

- (void)setMenuFormRepresentation:(NSMenuItem *)menuItem
{
    [_menuFormRepresentation release];
    _menuFormRepresentation = [menuItem retain];
}

- (void)setView:(NSView *)view
{
    [_view release];
    _view = [view retain];
}

- (void)setMinSize:(NSSize)size
{
    _minSize = size;
}


- (void)setMaxSize:(NSSize)size
{
    _maxSize = size;
}


- (NSSize)sizeForPalette
{
    NSSize size = [[self image] size];
    NSSize titleSize = [[self paletteLabel] sizeWithAttributes:[NSToolbarView attributesWithSizeMode:[[self toolbar] sizeMode]]];
    
    size.width = MAX(size.width, titleSize.width);
    if (size.height == 0)
        size.height = _NSToolbarIconSizeRegular.height;
    
    size.height += titleSize.height;
    
    return size;
}

- (NSImage *)image
{
    if ([_view respondsToSelector:@selector(image)])
        return [_view image];
    else
        return _image;
}

- target
{
    if ([_view respondsToSelector:@selector(target)])
        return [_view target];
    
    return nil;
}

- (SEL)action
{
    if ([_view respondsToSelector:@selector(action)])
        return [_view action];
    
    return NULL;
}

- (int)tag
{
    if ([_view respondsToSelector:@selector(tag)])
        return [_view tag];

    return 0;
}

- (BOOL)isEnabled
{
    if ([_view respondsToSelector:@selector(isEnabled)])
        return [_view isEnabled];
    
    return NO;
}

- (NSString *)toolTip 
{
    if ([_view respondsToSelector:@selector(toolTip)])
        return [_view toolTip];
    
    return nil;
}

- (void)setImage:(NSImage*)image
{
    [_image release];
    _image = [image retain];
    
    if ([_view respondsToSelector:@selector(setImage:)])
        [_view setImage:image];
}

- (void)setTarget:target
{
    if ([_view respondsToSelector:@selector(setTarget:)])
        [_view setTarget:target];
}

- (void)setAction:(SEL)action
{
    if ([_view respondsToSelector:@selector(setAction:)])
        [_view setAction:action];
}

- (void)setTag:(int)tag
{
    if ([_view respondsToSelector:@selector(setTag:)])
        [_view setTag:tag];
}


- (void)setEnabled:(BOOL)enabled
{
    if ([_view respondsToSelector:@selector(setEnabled:)])
        [_view setEnabled:enabled];
}

- (void)setToolTip:(NSString *)tip
{
    if ([_view respondsToSelector:@selector(setToolTip:)])
        [_view setToolTip:tip];
}

- (void)validate
{
    if ([[self target] respondsToSelector:[self action]])
        [self setEnabled:YES];
    else
        [self setEnabled:NO];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@[0x%lx] %@ label: \"%@\" image: %@ view: %@>",
        [self class], self, _itemIdentifier, _label, [_view image] ? [_view image] : _image, _view];
}

@end

