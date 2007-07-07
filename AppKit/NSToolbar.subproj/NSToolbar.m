/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSStandardToolbarItems.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSToolbarCustomizationPalette.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSWindowBackgroundView.h>
#import <AppKit/NSApplication.h>

NSSize _NSToolbarSizeRegular = { 40, 40 };
NSSize _NSToolbarSizeSmall = { 32, 32 };
NSSize _NSToolbarIconSizeRegular = { 32, 32 };
NSSize _NSToolbarIconSizeSmall = { 24, 24 };

#define MIN_Y_MARGIN    2.0
#define MIN_X_MARGIN    6.0

NSString *NSToolbarWillAddItemNotification = @"NSToolbarWillAddItemNotification";
NSString *NSToolbarDidRemoveItemNotification = @"NSToolbarDidRemoveItemNotification";

NSString *NSToolbarDidChangeNotification = @"NSToolbarDidChangeNotification";

@implementation NSToolbar

- initWithIdentifier:(NSString *)identifier
{
     _identifier = [identifier retain];
        
     _items = [[NSMutableArray alloc] init];
     _identifiers = [[NSMutableArray alloc] init];

     _view = [[NSToolbarView alloc] initWithFrame:[NSToolbarView viewFrameWithWindowContentSize:[[_window contentView] frame].size sizeMode:_sizeMode displayMode:_displayMode minYMargin:MIN_Y_MARGIN]];

     _visible=YES;
     _allowsUserCustomization = YES;
     _isLoadingConfiguration = NO;
        
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolbarDidChange:) name:NSToolbarDidChangeNotification object:nil];
            
     [_view setAutoresizesSubviews:YES];
     [_view setMinXMargin:MIN_X_MARGIN];
     [_view setMinYMargin:MIN_Y_MARGIN];
     [_view setToolbar:self];
        
     [_view setBorderType:NSGrooveBorder];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_identifier release];
    [_items release];
    [_identifiers release];
    [_view release];

    [super dealloc];
}

- (NSToolbarView *)_view
{
    return _view;
}

- (BOOL)loadConfiguration
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"NSToolbar Configuration %@", _identifier]];
    
    if (dictionary != nil) {
        _isLoadingConfiguration = YES;
        [self setConfigurationFromDictionary:dictionary];        
        _isLoadingConfiguration = NO;
        
        return YES;
    }
    
    return NO;
}

- (void)saveConfiguration
{    
    if (_isLoadingConfiguration == NO) {
        [[NSUserDefaults standardUserDefaults] setObject:[self configurationDictionary] forKey:[NSString stringWithFormat:@"NSToolbar Configuration %@", _identifier]];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)identifier
{
    return _identifier;
}

- delegate
{
    return _delegate;
}

- (BOOL)isVisible
{
    return _visible;
}

- (NSToolbarSizeMode)sizeMode
{
    return _sizeMode;
}

- (NSToolbarDisplayMode)displayMode
{
    return _displayMode;
}

- (NSArray *)items
{
    return _items;
} 

- (NSArray *)visibleItems
{
    return [_view visibleItems];
}

- (NSDictionary *)configurationDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:_displayMode], @"displayMode",
        [NSNumber numberWithInt:_sizeMode], @"sizeMode",
        [NSNumber numberWithBool:_visible], @"isVisible",
        [NSNumber numberWithBool:_autosavesConfiguration], @"autosavesConfiguration",
        _identifiers ? _identifiers : [NSArray array], @"itemIdentifiers",
        nil];    
        
    return dictionary;
}

- (BOOL)autosavesConfiguration
{
    return _autosavesConfiguration;
}

- (BOOL)allowsUserCustomization
{
    return _allowsUserCustomization;
}

- (void)insertItemWithItemIdentifier:(NSString *)identifier atIndex:(int)index
{
    NSToolbarItem *item;
    
    item = [NSToolbarItem standardToolbarItemWithIdentifier:identifier];
    if (item == nil)
        item = [_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarWillAddItemNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:item, @"item", nil]];
        
    [_identifiers insertObject:identifier atIndex:index];

    _reloadOnNextDisplay = YES;
    [_view setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];
    
    if ([self autosavesConfiguration])
        [self saveConfiguration];
}

- (void)removeItemAtIndex:(int)index
{
    NSString *identifier = [_identifiers objectAtIndex:index];
    NSToolbarItem *item;
    
    item = [NSToolbarItem standardToolbarItemWithIdentifier:identifier];
    if (item == nil)
        item = [_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidRemoveItemNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:item, @"item", nil]];

    [_identifiers removeObjectAtIndex:index];
    
    _reloadOnNextDisplay = YES;
    [_view setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];

    if ([self autosavesConfiguration])
        [self saveConfiguration];
}

- (void)setItemsWithIdentifiersFromArray:(NSArray *)identifiers
{
    [_identifiers removeAllObjects];
    [_identifiers addObjectsFromArray:identifiers];

    _reloadOnNextDisplay = YES;
    [_view setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];

    if ([self autosavesConfiguration])
        [self saveConfiguration];
}

- (void)_reloadToolbar
{
    int i, count;
   
    if (_delegate == nil)
        return;
    
    if ([_identifiers count] == 0) {
        [_identifiers release];
        _identifiers = [[_delegate toolbarDefaultItemIdentifiers:self] mutableCopy];
    }
    
    [[_view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_items removeAllObjects];    

    count = [_identifiers count];
    for (i = 0; i < count; ++i) {
        NSString *identifier = [_identifiers objectAtIndex:i];
        NSToolbarItem *item;
        
        item = [NSToolbarItem standardToolbarItemWithIdentifier:identifier];
        if (item == nil)
            item = [_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES];
        
        if (item == nil)
            [NSException raise:NSInvalidArgumentException
                        format:@"_delegate %@ returned nil toolbar item returned for identifier %@", _delegate, identifier];
        
        [_items addObject:item];
        
        // we're not actually adding the space/flexible space views to the toolbar; they're merely placeholders.
        if ([item isSpaceToolbarItem] == NO && [item isFlexibleSpaceToolbarItem] == NO)
            [_view addSubview:[item view]];
    }
    
    [_view sizeToFit];
}

- (void)_reloadToolbarIfNeeded
{
    if (_reloadOnNextDisplay == YES) {
        _reloadOnNextDisplay = NO;
        [self _reloadToolbar];
    }
}

- (void)toolbarDidChange:(NSNotification *)note
{
    NSToolbar *toolbar = [note object];
    
    if ([[toolbar identifier] isEqualToString:_identifier]) {
        NSRect frame = [_view frame];
        NSRect newFrame = [NSToolbarView viewFrameWithWindowContentSize:[[_window contentView] frame].size sizeMode:_sizeMode displayMode:_displayMode minYMargin:MIN_Y_MARGIN];
        float deltaY = frame.size.height - newFrame.size.height;
        
        frame.size.height = newFrame.size.height;
        
        [_view setFrame:frame];
        
        if ([self isVisible] && deltaY != 0) {
            frame = [_window frame];
            frame.size.height -= deltaY;
            
            [_view setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];
            _maskCache = [[_window contentView] autoresizingMask];
            [[_window contentView] setAutoresizingMask:NSViewNotSizable];
            
            [_window setFrame:frame display:YES animate:YES];
        }
        
        // do stuff..
        [self _reloadToolbarIfNeeded];
    }
}

- (void)setDelegate:delegate
{
    struct {
        NSString *name;
        SEL       selector;
    } notes[] = {
        { NSToolbarWillAddItemNotification, @selector(toolbarWillAddItem:) },
        { NSToolbarDidRemoveItemNotification, @selector(toolbarDidRemoveItem:) },
        { nil, NULL }
    };
    int i;
    
    if (_delegate != nil)
        for (i = 0; notes[i].name != nil; i++)
            [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:notes[i].name object:self];
    
    _delegate = delegate;
    
    for (i = 0; notes[i].name != nil; i++)
        if ([_delegate respondsToSelector:notes[i].selector])
            [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:notes[i].selector name:notes[i].name object:self];
    
    _reloadOnNextDisplay = YES;
//    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];
}

-(void)_setVisible:(BOOL)flag { 

    if (_window==[_view window]) {
        NSRect frame = [_window frame];

        [_view removeFromSuperview];
        
        frame.size.height -= [_view frame].size.height;
        _maskCache = [[_window contentView] autoresizingMask];
        [[_window contentView] setAutoresizingMask:NSViewNotSizable];
        [_window setFrame:frame display:YES animate:YES];
    }
    else {
        NSRect frame = [_view frame];

        frame.size.width = [[_window contentView] frame].size.width;
        frame.origin.y = [[_window contentView] frame].size.height;

        [_view setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];
        [_view setFrame:frame];
        
        [[_window _backgroundView] addSubview:_view];
                
        frame = [_window frame];
        frame.size.height += [_view frame].size.height;
        _maskCache = [[_window contentView] autoresizingMask];
        [[_window contentView] setAutoresizingMask:NSViewNotSizable];
        [_window setFrame:frame display:YES animate:YES];
    }

    _visible = flag;
    if ([self autosavesConfiguration])
        [self saveConfiguration];
}

- (void)setVisible:(BOOL)flag
{
    if (_visible == flag)
        return;
    [self _setVisible:flag];
}

- (void)setSizeMode:(NSToolbarSizeMode)mode
{
    _sizeMode = mode;
    if ([self autosavesConfiguration])
        [self saveConfiguration];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];
}

- (void)setDisplayMode:(NSToolbarDisplayMode)mode
{
    _displayMode = mode;
    if ([self autosavesConfiguration])
        [self saveConfiguration];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSToolbarDidChangeNotification object:self];    
}

- (void)setConfigurationFromDictionary:(NSDictionary *)dictionary
{
    int displayMode = [[dictionary objectForKey:@"displayMode"] intValue];
    int sizeMode = [[dictionary objectForKey:@"sizeMode"] intValue];
    BOOL visible = [[dictionary objectForKey:@"isVisible"] intValue];
    BOOL autosavesConfiguration = [[dictionary objectForKey:@"autosavesConfiguration"] intValue];
    NSArray *identifiers = [dictionary objectForKey:@"itemIdentifiers"];
    
    [self setDisplayMode:displayMode];
    [self setSizeMode:sizeMode];
    
    _identifiers = [identifiers mutableCopy];

    [self setVisible:visible];
    [self setAutosavesConfiguration:autosavesConfiguration];
}

- (void)setAutosavesConfiguration:(BOOL)flag
{
    _autosavesConfiguration = flag;
}

- (void)setAllowsUserCustomization:(BOOL)flag
{
    _allowsUserCustomization = flag;
}

- (void)validateVisibleItems
{
    int i, count = [[self visibleItems] count];
    
    for (i = 0; i < count; ++i)
        [[[self visibleItems] objectAtIndex:i] validate];
}

- (BOOL)customizationPaletteIsRunning;
{
    return _palette != nil;
}

- (void)runCustomizationPalette:sender;
{
    if (_palette != nil || _allowsUserCustomization == NO || _visible == NO)
        return;
    
    _palette = [[NSToolbarCustomizationPalette alloc] initWithToolbar:self];
    
    [NSApp beginSheet:_palette modalForWindow:_window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)windowDidAnimate:(NSNotification *)note
{
    [_view setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
    
    [[_window contentView] setAutoresizingMask:_maskCache];
}


- (void)_setWindow:(NSWindow *)window
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidAnimateNotification object:_window];
    
    _window = window;

    if (_window != nil) 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidAnimate:) name:NSWindowDidAnimateNotification object:_window];

    // do this here since _window must be initialized for this to work...
    if ([self loadConfiguration])
        [self _reloadToolbar];

    [self _setVisible:_visible];
}

- (NSArray *)itemIdentifiers
{
    return _identifiers;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [_palette orderOut:nil];
    [_palette release];
    _palette = nil;
}

@end

