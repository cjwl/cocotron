/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSToolbarCustomizationPalette.h>
#import <AppKit/NSToolbarCustomizationView.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSButton.h>

#define VIEW_X_OFFSET   4.0
#define VIEW_Y_OFFSET   7.0

@implementation NSToolbarCustomizationPalette

- (id)_initWithToolbar:(NSToolbar *)toolbar
{
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    int index = [_displayModePopUp indexOfItemWithTag:[toolbar displayMode]];
    float maxWidth = 0;

    if (index == -1)
        index = 0;
    
    [_displayModePopUp selectItemAtIndex:index];
    [self _setStyleMask:NSBorderlessWindowMask];    
    _toolbar = [toolbar retain];
    
    switch ([_toolbar sizeMode]) {
        case NSToolbarSizeModeSmall:
            [_smallSizeModeButton setState:NSOnState];
            break;
            
        case NSToolbarSizeModeRegular:
        case NSToolbarSizeModeDefault:
        default:
            [_smallSizeModeButton setState:NSOffState];
            break;
    }

    frame = [NSToolbarView constrainedToolbarItemFrame:[_defaultItemsTextField frame] minSize:NSMakeSize(0,0) maxSize:NSMakeSize(0,0) sizeMode:NSToolbarSizeModeDefault displayMode:NSToolbarDisplayModeDefault];
    
    _defaultItemsView = [[NSToolbarCustomizationView alloc] initWithFrame:frame toolbar:_toolbar isDefaultSetView:YES];
    [_defaultItemsView setAutoresizingMask:NSViewNotSizable];
    [_defaultItemsView sizeToFit];

    frame = [NSToolbarView constrainedToolbarItemFrame:[_allowedItemsTextField frame] minSize:NSMakeSize(0,0) maxSize:NSMakeSize(0,0) sizeMode:NSToolbarSizeModeDefault displayMode:NSToolbarDisplayModeDefault];
    
    _allowedItemsView = [[NSToolbarCustomizationView alloc] initWithFrame:frame toolbar:_toolbar isDefaultSetView:NO];
    [_allowedItemsView setAutoresizingMask:NSViewNotSizable];
    [_allowedItemsView sizeToFit];
    
    maxWidth = MAX([_defaultItemsView frame].size.width, [_allowedItemsView frame].size.width);

    frame = [_defaultItemsView frame];
    frame.origin.x += VIEW_X_OFFSET;
    frame.origin.y -= frame.size.height + VIEW_Y_OFFSET;
    [_defaultItemsView setFrame:frame];
    
    frame = [_allowedItemsView frame];
    frame.origin.x += VIEW_X_OFFSET;
    frame.origin.y -= frame.size.height + VIEW_Y_OFFSET;
    frame.size.width = maxWidth;
    [_allowedItemsView setFrame:frame];

    [[self contentView] addSubview:_defaultItemsView];
    [[self contentView] addSubview:_allowedItemsView];
    
    // Hmmm.
    frame = [self frame];
    
    frame.size.width = maxWidth + (([_defaultItemsView frame].origin.x + VIEW_X_OFFSET) * 2);
    [self setFrame:frame display:NO];
    
    [self setDefaultButtonCell:[_button cell]];
    
    return self;
}    

- (id)initWithToolbar:(NSToolbar *)toolbar
{
    [NSBundle loadNibNamed:@"NSToolbarCustomizationPalette" owner:self];
    if (self = [_palette retain]) { 
        [self _initWithToolbar:toolbar];
    }
    
    return self;
}

- (void)dealloc
{
    [_allowedItemsView release];
    [_defaultItemsView release];
    
    [super dealloc];
}

- (NSToolbar *)toolbar
{
    return _toolbar;
}

- (void)settingsChanged:(id)sender
{
    NSToolbarDisplayMode displayMode = [[_displayModePopUp selectedCell] tag];
    NSToolbarSizeMode sizeMode = [_smallSizeModeButton state] ? NSToolbarSizeModeSmall : NSToolbarSizeModeRegular;
    
    [_toolbar setDisplayMode:displayMode];
    [_toolbar setSizeMode:sizeMode];
}

- (void)customizationPaletteDidFinish:(id)sender
{
    [NSApp endSheet:self returnCode:NSAlertDefaultReturn];
}

@end
