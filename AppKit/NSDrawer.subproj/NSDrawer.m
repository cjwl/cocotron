/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSDrawer.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSDrawerWindow.h>

NSString *NSDrawerWillOpenNotification = @"NSDrawerWillOpenNotification";
NSString *NSDrawerDidOpenNotification = @"NSDrawerDidOpenNotification";
NSString *NSDrawerWillCloseNotification = @"NSDrawerWillCloseNotification";
NSString *NSDrawerDidCloseNotification = @"NSDrawerDidCloseNotification";

@implementation NSDrawer

// - modify the leading/trailing offset portions of the drawer's geometry.
// - constrain the "expandable" portion of the drawer to the min/max content sizes.
+ (NSRect)drawerFrameWithContentSize:(NSSize)contentSize parentWindow:(NSWindow *)parentWindow leadingOffset:(float)leadingOffset trailingOffset:(float)trailingOffset edge:(NSRectEdge)edge state:(NSDrawerState)state {
    NSRect frame;
    
    frame = [parentWindow frame];
    
    if (edge == NSMinXEdge || edge == NSMaxXEdge) {
        frame.origin.y += trailingOffset;
        frame.size.height -= trailingOffset;
        
        frame.size.width = contentSize.width;        
        frame.size.height -= leadingOffset;
    }
    else {
        frame.origin.x += leadingOffset;
        frame.size.width -= leadingOffset;
        
        frame.size.height = contentSize.height;
        frame.size.width -= trailingOffset;
    }
    
    // Initially I was only computing the open-state frame. Code added to compute closed state...
    switch (edge) {
        case NSMinXEdge:
            if (state != NSDrawerClosedState)
                frame.origin.x -= frame.size.width;
            break;
            
        case NSMaxXEdge:
            frame.origin.x += [parentWindow frame].size.width;
            if (state == NSDrawerClosedState)
                frame.origin.x -= frame.size.width;
                break;
            
        case NSMinYEdge:
            if (state != NSDrawerClosedState)
                frame.origin.y -= frame.size.height;
            break;
            
        case NSMaxYEdge:
            frame.origin.y += [parentWindow frame].size.height;
            if (state == NSDrawerClosedState)
                frame.origin.y -= frame.size.height;
                break;
            
        default:
            break;
    }
    
    return frame;
}

// compute the proper edge on which to open based upon the dimensions of the parent window, its screen, the drawer and its preferred edge. choose the preferred edge if possible, then the opposite edge if possible, then the preferred edge if neither is possible.
+ (NSRectEdge)visibleEdgeWithPreferredEdge:(NSRectEdge)preferredEdge parentWindow:(NSWindow *)parentWindow drawerWindow:(NSWindow *)drawerWindow {
    NSRect screenRect = [[parentWindow screen] visibleFrame];
    NSRect parentRect = [parentWindow frame];
    NSRect drawerRect = [drawerWindow frame];
    
    switch (preferredEdge) {
        case NSMinXEdge:
            if (parentRect.origin.x - screenRect.origin.x < drawerRect.size.width)
                if (NSMaxX(screenRect) - NSMaxX(parentRect) > drawerRect.size.width)
                    return NSMaxXEdge;
            
            return NSMinXEdge;
            
        case NSMaxXEdge:
            if (NSMaxX(screenRect) - NSMaxX(parentRect) < drawerRect.size.width)
                if (parentRect.origin.x - screenRect.origin.x > drawerRect.size.width)
                    return NSMinXEdge;
            
            return NSMaxXEdge;
            
        case NSMinYEdge:
            if (parentRect.origin.y - screenRect.origin.y < drawerRect.size.height)
                if (NSMaxY(screenRect) - NSMaxY(parentRect) > drawerRect.size.height)
                    return NSMaxYEdge;
            
            return NSMinYEdge;
            
        case NSMaxYEdge:
            if (NSMaxY(screenRect) - NSMaxY(parentRect) < drawerRect.size.height)
                if (parentRect.origin.y - screenRect.origin.y > drawerRect.size.height)
                    return NSMinYEdge;
            
            return NSMinXEdge;
            
        default:
            return NSMaxXEdge;
    }
}

- initWithContentSize:(NSSize)contentSize preferredEdge:(NSRectEdge)edge {
    _contentSize = contentSize;
    _drawerWindow = [[NSDrawerWindow alloc] initWithContentRect:NSMakeRect(0, 0, _contentSize.width, _contentSize.height) styleMask:NSDrawerWindowMask backing:NSBackingStoreBuffered defer:NO];
    [_drawerWindow setDrawer:self];
        
    [self setContentSize:contentSize];	// maybe not
    [self setPreferredEdge:edge];

    return self;
}

- (void)dealloc {
    [_drawerWindow release];
    [_parentWindow release];
    
    [super dealloc];
}

- delegate {
    return _delegate;
}

- (NSWindow *)parentWindow {
    return _parentWindow;
}

- (NSView *)contentView {
    return [_drawerWindow contentView];
}

- (NSSize)contentSize {
    return [[self contentView] frame].size;
}

- (NSSize)minContentSize {
    return _minContentSize;
}

- (NSSize)maxContentSize {
    return _maxContentSize;
}

- (float)leadingOffset {
    return _leadingOffset;
}

- (float)trailingOffset {
    return _trailingOffset;
}

- (NSRectEdge)preferredEdge {
    return _preferredEdge;
}

- (int)state {
    return _state;
}

- (NSRectEdge)edge {
    return _edge;
}

- (void)setDelegate:delegate {
    struct {
        NSString *name;
        SEL       selector;
    } notes[]={
        { NSDrawerDidCloseNotification,@selector(drawerDidClose:) },
        { NSDrawerDidOpenNotification ,@selector(drawerDidOpen:) },
        { NSDrawerWillCloseNotification,@selector(drawerWillClose:) },
        { NSDrawerWillOpenNotification,@selector(drawerWillOpen:) },
        { nil, NULL }
    };

    int i;
    
    if(_delegate!=nil)
        for (i = 0; notes[i].name != nil; i++)
            [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:notes[i].name object:self];
    
    _delegate = delegate;
    
    for (i = 0; notes[i].name != nil; i++)
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:notes[i].selector name:notes[i].name object:self];
}

- (void)setNextParentWindow {
    [_parentWindow _detachDrawer:self];
    [_parentWindow release];
    _parentWindow = [_nextParentWindow retain];
    [_parentWindow _attachDrawer:self];

    _nextParentWindow = nil;
}

- (void)setParentWindow:(NSWindow *)window {
    _nextParentWindow = window;
    
    if (_state == NSDrawerClosedState)
        [self setNextParentWindow];
}

- (void)setContentView:(NSView *)view {
    NSArray *subviews = [[_drawerWindow contentView] subviews];
    
    if ([subviews count] > 0)
        [[subviews objectAtIndex:0] removeFromSuperview];
    
    if (view != nil)
        [[_drawerWindow contentView] addSubview:view];
}

- (void)setContentSize:(NSSize)size {
    [[self contentView] setFrameSize:size];
}

- (void)setMinContentSize:(NSSize)size {
    _minContentSize = size;
}

- (void)setMaxContentSize:(NSSize)size {
    _maxContentSize = size;
}

- (void)setPreferredEdge:(NSRectEdge)edge {
    _preferredEdge = edge;
}

- (void)setLeadingOffset:(float)offset {
    _leadingOffset = offset;
}

- (void)setTrailingOffset:(float)offset {
    _trailingOffset = offset;
}

- (void)open {
    [self openOnEdge:[[self class] visibleEdgeWithPreferredEdge:_preferredEdge parentWindow:_parentWindow drawerWindow:_drawerWindow]];
}

- (void)_resetWindowOrdering:sender {
    [_drawerWindow orderWindow:NSWindowAbove relativeTo:[_parentWindow windowNumber]];
    [_drawerWindow orderWindow:NSWindowBelow relativeTo:[_parentWindow windowNumber]];
}

- (void)openOnEdge:(NSRectEdge)edge {
    NSRect start, frame;

    if ([self state] != NSDrawerClosedState)
        return;
    
    // if we've moved to a different edge, recompute...
    if (_edge != edge)
        _contentSize = [self drawerWindow:_drawerWindow constrainSize:_contentSize edge:edge];
    
    _edge = edge;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSDrawerWillOpenNotification object:self];

    frame = [[self class] drawerFrameWithContentSize:_contentSize parentWindow:[self parentWindow] leadingOffset:_leadingOffset trailingOffset:_trailingOffset edge:_edge state:NSDrawerOpenState];
    _contentSize = frame.size;

    // OK. setup and slide the drawer out
    start = [[self class] drawerFrameWithContentSize:_contentSize parentWindow:[self parentWindow] leadingOffset:_leadingOffset trailingOffset:_trailingOffset edge:_edge state:NSDrawerClosedState];
    
    frame.size = start.size = [self drawerWindow:_drawerWindow constrainSize:frame.size edge:_edge];
//    frame.size = [self drawerWindow:_drawerWindow constrainSize:frame.size];
//    start.size = [self drawerWindow:_drawerWindow constrainSize:start.size];
    [_drawerWindow setFrame:start display:YES animate:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawerDidOpen:) name:NSWindowDidAnimateNotification object:_drawerWindow];
    _state = NSDrawerOpeningState;
    [self _resetWindowOrdering:nil];
    [_drawerWindow setFrame:frame display:YES animate:YES];
}

// a bit easier time of it as the much of the setup is already done.
// FIX in general either make sure contentSize stays in sync, or do this from the open frame...
- (void)close {
    NSRect frame;
    
    if ([self state] != NSDrawerOpenState)
        return;
    
    frame = [[self class] drawerFrameWithContentSize:_contentSize parentWindow:[self parentWindow] leadingOffset:_leadingOffset trailingOffset:_trailingOffset edge:_edge state:NSDrawerClosedState];
    frame.size = [self drawerWindow:_drawerWindow constrainSize:frame.size edge:_edge];    

    [[NSNotificationCenter defaultCenter] postNotificationName:NSDrawerWillCloseNotification object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawerDidClose:) name:NSWindowDidAnimateNotification object:_drawerWindow];
    _state = NSDrawerClosingState;
    
    [_drawerWindow setFrame:frame display:YES animate:YES];
}

- (void)open:sender {
    if ([_delegate respondsToSelector:@selector(drawerShouldOpen:)])
        if ([_delegate drawerShouldOpen:self] == NO)
            return;
    
    [self open];
}

- (void)close:sender {
    if ([_delegate respondsToSelector:@selector(drawerShouldClose:)])
        if ([_delegate drawerShouldClose:self] == NO)
            return;

    [self close];
}

// FIX add support for transient states
- (void)toggle:sender {
    switch ([self state]) {
        case NSDrawerOpenState:     [self close];   break;
        case NSDrawerClosedState:   [self open];    break;
            
        case NSDrawerOpeningState:
        case NSDrawerClosingState:
        default:
            break;
    }
}

- (void)parentWindowDidActivate:(NSWindow *)window {
    if (_state == NSDrawerOpenState)
        [self _resetWindowOrdering:nil];
}

- (void)parentWindowDidChangeFrame:(NSWindow *)window {
    if (_state == NSDrawerOpenState) {
        NSRect frame = [[self class] drawerFrameWithContentSize:_contentSize parentWindow:[self parentWindow] leadingOffset:_leadingOffset trailingOffset:_trailingOffset edge:_edge state:_state];

        if (_edge == NSMinXEdge || _edge == NSMaxXEdge) {
            if (frame.size.width > _maxContentSize.width && _maxContentSize.width > 0)
                frame.size.width = _maxContentSize.width;
        }
        else {
            if (frame.size.height > _maxContentSize.height && _maxContentSize.height > 0)
                frame.size.height = _maxContentSize.height;
        }
        
        [_drawerWindow setFrame:frame display:YES];
    }
}

- (void)parentWindowDidExitMove:(NSWindow *)window {
    if (_state == NSDrawerOpenState)
        [self _resetWindowOrdering:nil];
}

- (void)parentWindowDidMiniaturize:(NSWindow *)window {
    if (_state == NSDrawerOpenState)
        [_drawerWindow orderOut:nil];
}

- (void)parentWindowDidDeminiaturize:(NSWindow *)window {
    // ... otherwise the drawer is visible before Windows finishes its animation, heh
    [self performSelector:@selector(_resetWindowOrdering:) withObject:window afterDelay:0.5];
}

- (void)drawerWindowDidActivate:(NSDrawerWindow *)window {
    [self _resetWindowOrdering:nil];
}

- (NSSize)drawerWindow:(NSDrawerWindow *)window constrainSize:(NSSize)size edge:(NSRectEdge)edge {
    if (edge == NSMinXEdge || edge == NSMaxXEdge) {
        if (size.width > _maxContentSize.width && _maxContentSize.width > 0)
            size.width = _maxContentSize.width;
        
        size.height = _contentSize.height;
    }
    else {
        if (size.height > _maxContentSize.height && _maxContentSize.height > 0)
            size.height = _maxContentSize.height;
        
        size.width = _contentSize.width;
    }
    
    _contentSize = size;
    
    return size;
}

// close the drawer when size < minContentSize. reset _contentSize for the next go
- (void)drawerWindowDidResize:(NSDrawerWindow *)window {
    NSSize size = [window frame].size;
    
    [self _resetWindowOrdering:nil];

    if (_edge == NSMinXEdge || _edge == NSMaxXEdge) {
        if (size.width < _minContentSize.width) {
            [self close];
            _contentSize.width = _minContentSize.width;
        }
    }
    else {
        if (size.height < _minContentSize.height) {
            [self close];
            _contentSize.height = _minContentSize.height;
        }
    }
}

// ?
- (void)drawerDidOpen:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _state = NSDrawerOpenState;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSDrawerDidOpenNotification object:self];
}

- (void)drawerDidClose:(NSNotification *)nilObject {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_drawerWindow orderOut:nil];        
    _state = NSDrawerClosedState;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSDrawerDidCloseNotification object:self];

    if (_nextParentWindow != nil)
        [self setNextParentWindow];    
}

@end

