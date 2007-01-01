/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSStandardToolbarItems.h>
#import <AppKit/NSToolbarSeparatorItemView.h>
#import <AppKit/NSToolbarButtonCell.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSControl.h>

@implementation NSToolbarItem (NSStandardToolbarItems)

+ (NSToolbarItem *)standardToolbarItemWithIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:NSToolbarSeparatorItemIdentifier])
        return [NSToolbarItem separatorToolbarItem];
    else if ([identifier isEqualToString:NSToolbarSpaceItemIdentifier])
        return [NSToolbarItem spaceToolbarItem];
    else if ([identifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier])
        return [NSToolbarItem flexibleSpaceToolbarItem];
    else if ([identifier isEqualToString:NSToolbarShowColorsItemIdentifier])
        return [NSToolbarItem showColorsToolbarItem];
    else if ([identifier isEqualToString:NSToolbarShowFontsItemIdentifier])
        return [NSToolbarItem showFontsToolbarItem];
    else if ([identifier isEqualToString:NSToolbarCustomizeToolbarItemIdentifier])
        return [NSToolbarItem customizeToolbarToolbarItem];
    else if ([identifier isEqualToString:NSToolbarPrintItemIdentifier])
        return [NSToolbarItem printToolbarItem];
    
    return nil;
}

+ (NSToolbarItem *)separatorToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSeparatorItemIdentifier];
    NSSize size;
    
    [item setLabel:@"|"];
    [item setPaletteLabel:@"Separator"];
    [item setEnabled:NO];
    
    size = [item minSize];
    size.width = floor(size.width/2);
    [item setMinSize:size];
    size = [item maxSize];
    size.width = floor(size.width/2);
    [item setMaxSize:size];
    
    [item setView:[[[NSToolbarSeparatorItemView alloc] initWithFrame:[[item view] frame]] autorelease]];
    
    return [item autorelease];
}

- (BOOL)isSeparatorToolbarItem
{
    return [[self label] isEqualToString:@"|"];
}

+ (NSToolbarItem *)spaceToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSpaceItemIdentifier];
    NSSize size;
    
    [item setLabel:@""];
    [item setPaletteLabel:@"Space"];
    [item setEnabled:NO];

    size = [item minSize];
    size.width /= 2;
    [item setMinSize:size];
    size = [item maxSize];
    size.width /= 2;
    [item setMaxSize:size];
    
    [(NSControl *)[item view] setBordered:NO];
    [[(NSControl *)[item view] cell] setDrawsSpaceOutline:YES];
    
    return [item autorelease];
}

- (BOOL)isSpaceToolbarItem
{
    return ([[self label] isEqualToString:@""] && [[self paletteLabel] hasSuffix:@"Space"]);
}

+ (NSToolbarItem *)flexibleSpaceToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
    NSSize size;
    
    [item setLabel:@""];
    [item setPaletteLabel:@"Flexible Space"];
    [item setEnabled:NO];
    
    size = [item minSize];
    size.width /= 2;
    [item setMinSize:size];
    [item setMaxSize:NSMakeSize(-1, [item maxSize].height)];
    
    [(NSControl *)[item view] setBordered:NO];
    [[(NSControl *)[item view] cell] setDrawsSpaceOutline:YES];
    [[(NSControl *)[item view] cell] setDrawsFlexibleSpaceOutline:YES];
    
    return [item autorelease];
}

- (BOOL)isFlexibleSpaceToolbarItem
{
    if ([self maxSize].width == -1)
        return YES;
    
    return NO;
}

+ (NSToolbarItem *)showColorsToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarShowColorsItemIdentifier];
    
    [item setLabel:@"Colors"];
    [item setPaletteLabel:@"Show Colors"];
    [item setTarget:[NSApplication sharedApplication]];
    [item setAction:@selector(orderFrontColorPanel:)];
    [item setImage:[NSImage imageNamed:NSToolbarShowColorsItemIdentifier]];
    [item setToolTip:@"Show the Colors panel."];
    
    return [item autorelease];
}

+ (NSToolbarItem *)showFontsToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarShowFontsItemIdentifier];
    
    [item setLabel:@"Fonts"];
    [item setPaletteLabel:@"Show Fonts"];
    [item setTarget:[NSFontManager sharedFontManager]];
    [item setAction:@selector(orderFrontFontPanel:)];
    [item setImage:[NSImage imageNamed:NSToolbarShowFontsItemIdentifier]];
    [item setToolTip:@"Show the Fonts panel."];
    
    return [item autorelease];
}

+ (NSToolbarItem *)customizeToolbarToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarCustomizeToolbarItemIdentifier];
    
    [item setLabel:@"Customize"];
    [item setPaletteLabel:@"Customize"];
    [item setTarget:nil];
    [item setAction:@selector(runToolbarCustomizationPalette:)];
    [item setImage:[NSImage imageNamed:NSToolbarCustomizeToolbarItemIdentifier]];
    [item setToolTip:@"Customize this toolbar."];
    
    return [item autorelease];
}

+ (NSToolbarItem *)printToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarPrintItemIdentifier];
    
    [item setLabel:@"Print"];
    [item setPaletteLabel:@"Print Document"];
    [item setTarget:nil];
    [item setAction:@selector(printDocument:)];
    [item setImage:[NSImage imageNamed:NSToolbarPrintItemIdentifier]];
    [item setToolTip:@"Print this document."];

    return [item autorelease];
}

+ (NSToolbarItem *)overflowToolbarItem
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarOverflowItemIdentifier];
    
    [item setLabel:@""];
    [item setPaletteLabel:@"Overflow"];
    [item setTarget:nil];
    [item setAction:@selector(popUpOverflowMenu:)];
    
    return [item autorelease];
}

@end

NSString *NSToolbarOverflowItemIdentifier = @"NSToolbarOverflowItemIdentifier";

