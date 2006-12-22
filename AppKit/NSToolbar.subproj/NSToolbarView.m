/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSToolbarCustomizationView.h>
#import <AppKit/NSStandardToolbarItems.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSText.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuWindow.h>
#import <AppKit/NSMenuView.h>

extern NSSize _NSToolbarSizeRegular;
extern NSSize _NSToolbarSizeSmall;
extern NSSize _NSToolbarIconSizeRegular;
extern NSSize _NSToolbarIconSizeSmall;

@implementation NSToolbarView

+ (NSRect)viewFrameWithWindowContentSize:(NSSize)contentSize sizeMode:(NSToolbarSizeMode)sizeMode displayMode:(NSToolbarDisplayMode)displayMode minYMargin:(float)minYMargin
{
    NSSize size = NSMakeSize(0, 0);
    NSRect frame = NSMakeRect(0, 0, contentSize.width, contentSize.height);
        
    frame = [NSToolbarView constrainedToolbarItemFrame:frame minSize:size maxSize:size sizeMode:sizeMode displayMode:displayMode];
    
    frame.size.width = contentSize.width;
    frame.size.height += minYMargin;
    
    return frame;
}

+ (NSDictionary *)attributesWithSizeMode:(NSToolbarSizeMode)sizeMode
{
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    
    [style setLineBreakMode:NSLineBreakByClipping];
    [style setAlignment:NSCenterTextAlignment];
 
    switch (sizeMode) {
        case NSToolbarSizeModeSmall:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:10.0], NSFontAttributeName,
                style, NSParagraphStyleAttributeName,
                nil];
            
        case NSToolbarSizeModeRegular:
        case NSToolbarSizeModeDefault:
        default:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                style, NSParagraphStyleAttributeName,
                nil];
    }        
}

+ (NSRect)constrainedToolbarItemFrame:(NSRect)frame minSize:(NSSize)minSize maxSize:(NSSize)maxSize sizeMode:(NSToolbarSizeMode)sizeMode displayMode:(NSToolbarDisplayMode)displayMode
{
    NSString *string = @"Item";
    
    switch (sizeMode) {
        case NSToolbarSizeModeSmall:
            frame.size = _NSToolbarSizeSmall;
            break;
            
        case NSToolbarSizeModeRegular:
        case NSToolbarSizeModeDefault:
        default:
            frame.size = _NSToolbarSizeRegular;
            break;
    }        
    
    if (frame.size.width < minSize.width && minSize.width > 0)
        frame.size.width = minSize.width;
    if (frame.size.height < minSize.height && minSize.height > 0)
        frame.size.height = minSize.height;
    if (frame.size.width > maxSize.width && maxSize.width > 0)
        frame.size.width = maxSize.width;
    if (frame.size.height > maxSize.height && maxSize.height > 0)
        frame.size.height = maxSize.height;
    
    switch (displayMode) {
        case NSToolbarDisplayModeIconOnly:
            break;
            
        case NSToolbarDisplayModeLabelOnly:
            frame.size.height = [string sizeWithAttributes:[NSToolbarView attributesWithSizeMode:sizeMode]].height;
            break;

        case NSToolbarDisplayModeIconAndLabel: 
        case NSToolbarDisplayModeDefault:
        default:
            frame.size.height += [string sizeWithAttributes:[NSToolbarView attributesWithSizeMode:sizeMode]].height;
            break;
    }

    return frame;
}

- (id)initWithFrame:(NSRect)frame
{
    [super initWithFrame:frame];
    _overflowMenu = [[NSMenu alloc] initWithTitle:@"Overflow"];
    _overflowItem = [[NSToolbarItem overflowToolbarItem] retain];
    [_overflowItem setTarget:self];
        
    _visibleItems = [[NSMutableArray alloc] init];
        
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSToolbarItemIdentifierPboardType]];
    
    return self;
}

- (void)dealloc
{
    [_overflowMenu release];
    [_overflowItem release];
    [_visibleItems release];
    
    [super dealloc];
}

- (BOOL)isOpaque 
{
    return YES;
}

- (NSToolbar *)toolbar
{
    return _toolbar;
}

- (void)setToolbar:(NSToolbar *)toolbar
{
    _toolbar = toolbar;
}

- (NSBorderType)borderType
{
    return _borderType;
}

/* Funny story: Way back when I was first looking into NeXT computers (thanks to my friend Mark Miller, who was studying at Purdue at the time), I remember someone had given me an account on this vegetarian dude's computer called vegiwopr.cs.calpoly.edu (at the time vegetarianism wasn't so accepted)... I was browsing the APIs for NeXTSTEP 3.x, and I remember thinking that the ability to set the border types for views was just the coolest thing an API could have. Not long thereafter, I had a mono slab, then a TurboColor, then a Turbo Dimension Cube, then NS/Intel, and the rest, well... */
- (void)setBorderType:(NSBorderType)borderType
{
    _borderType = borderType;
    [self setNeedsDisplay:YES];
}

- (NSArray *)visibleItems
{
    return _visibleItems;
}

- (void)drawRect:(NSRect)rect
{
    [_toolbar _reloadToolbarIfNeeded];
    
    [[NSColor windowBackgroundColor] set];
    NSRectFill(rect);
    
    [super drawRect:rect];
    
    switch(_borderType){
        case NSNoBorder:
            break;
            
        case NSLineBorder:
            rect.size.height = 1;
            [[NSColor blackColor] set];
            NSFrameRect(rect);
            break;
            
        case NSBezelBorder:                 // looks like crap
            rect.size.height = 2;
            NSDrawGrayBezel(rect,rect);
            break;
            
        case NSGrooveBorder:
            rect.size.height = 2;
            NSDrawGroove(rect,rect);
            break;
    }
}

- (float)minXMargin 
{
    return _minXMargin;
}

- (void)setMinXMargin:(float)margin 
{
    _minXMargin = margin;
    [self sizeToFit];
}

- (float)minYMargin
{
    return _minYMargin;
}

- (void)setMinYMargin:(float)margin
{
    NSRect frame = [self frame];
    
    frame.size.height += margin - _minYMargin;
    _minYMargin = margin;
    
    [self setFrame:frame];
    [self sizeToFit];
}

- (NSImage *)overflowImage 
{
    if ([[self window] isKeyWindow])
        return [NSImage imageNamed:@"NSMenuViewDoubleRightArrow"];
    else
        return [NSImage imageNamed:@"NSMenuViewDoubleRightArrowGray"];
}

- (void)sizeToFit
{
    int i, count;
    unsigned int resizingMask = NSViewMaxXMargin;
    unsigned numberOfFlexibleSpaces = 0;
    unsigned flexibleSpaceCount = 0;
    NSRect frame = NSMakeRect(_minXMargin, _minYMargin, 0, 0);
    float totalInflexiblePixels = 0.0;
    float flexibleSpaceWidth = 0.0;
    
    count = [[_toolbar items] count];

    [_visibleItems removeAllObjects];
    [_overflowMenu removeAllItems];
    
    if ([[_overflowItem view] superview] != nil)
        [[_overflowItem view] removeFromSuperview];
    
    // this might be inefficient, but i think i need to use two loops here
    for (i = 0; i < count; ++i) {
        NSToolbarItem *item = [[_toolbar items] objectAtIndex:i];

        if ([item isFlexibleSpaceToolbarItem])
            numberOfFlexibleSpaces++;
        else
            totalInflexiblePixels += [NSToolbarView constrainedToolbarItemFrame:frame minSize:[item minSize] maxSize:[item maxSize] sizeMode:[_toolbar sizeMode] displayMode:[_toolbar displayMode]].size.width;
    }
    
    // now we know how wide these flexible space(s) should be.
    flexibleSpaceWidth = [self frame].size.width - (totalInflexiblePixels + _minXMargin);
    flexibleSpaceWidth /= numberOfFlexibleSpaces;
    
    // items' autoresizing behavior will change depending on the number of flexible spaces (if any) in the toolbar...
    for (i = 0; i < count; ++i) {
        NSToolbarItem *item = [[_toolbar items] objectAtIndex:i];
        
        frame = [NSToolbarView constrainedToolbarItemFrame:frame minSize:[item minSize] maxSize:[item maxSize] sizeMode:[_toolbar sizeMode] displayMode:[_toolbar displayMode]];
        
        if ([item isFlexibleSpaceToolbarItem] && flexibleSpaceWidth > 0) {
            [[item view] setAutoresizingMask:NSViewWidthSizable];
            
            flexibleSpaceCount++;
            frame.size.width = flexibleSpaceWidth;

            if (flexibleSpaceCount < numberOfFlexibleSpaces)
                resizingMask = NSViewMinXMargin|NSViewMaxXMargin;
            else
                resizingMask = NSViewMinXMargin;
        }
        else
            [[item view] setAutoresizingMask:resizingMask];

        [[item view] removeFromSuperview];
        [[item view] setFrame:frame];

        // check for overflow.
        if (flexibleSpaceWidth < 0 && NSMaxX(frame) > ([self frame].size.width - [_overflowItem minSize].width)) {            
            if ([[_overflowItem view] superview] == nil) {
                [_overflowItem setImage:[self overflowImage]];
                
                frame.size.width = [_overflowItem minSize].width;
                frame.origin.x = [self frame].size.width - frame.size.width - 3.0;
                
                if ([_toolbar displayMode] == NSToolbarDisplayModeLabelOnly)
                    [_overflowItem setLabel:@">>"];
                else {
                    [_overflowItem setLabel:@""];
                }

                [[_overflowItem view] setFrame:frame];
                
                [self addSubview:[_overflowItem view]];
            }
            
            if ([item isSpaceToolbarItem] == NO && [item isSeparatorToolbarItem] == NO)             
                [_overflowMenu addItem:[item menuFormRepresentation]];
        }
        else {
            [self addSubview:[item view]];
            [_visibleItems addObject:item];
            frame.origin.x += frame.size.width;
        }
    }
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize 
{
    [super resizeWithOldSuperviewSize:oldSize];
    
    [self sizeToFit];
}

- (void)popUpOverflowMenu:(id)sender
{
    NSMenuWindow *window;
    NSMenuItem *item;
    NSRect menuFrame = [self frame];
    int i;
    
    for (i = 0; i < [_overflowMenu numberOfItems]; ++i) {
        NSToolbarItem *item = [[_overflowMenu itemAtIndex:i] representedObject];
        
        if ([[item label] sizeWithAttributes:nil].width > menuFrame.size.width)
            menuFrame.size.width = [[item label] sizeWithAttributes:nil].width + 20.0;  // argh
    }
    
    window=[[NSMenuWindow alloc] initWithMenu:_overflowMenu];

    menuFrame.origin.x = NSMaxX([self frame]);
    menuFrame.origin.y = [self frame].origin.y + [self frame].size.height/2;
    menuFrame.origin = [[self window] convertBaseToScreen:menuFrame.origin];

    menuFrame.origin.y -= [[window menuView] frame].size.height;

    [window setFrameOrigin:menuFrame.origin];
    [window orderFront:nil];
    item = [[window menuView] trackForEvent:[[self window] currentEvent]];
    [window close];
    
    if (item != nil)
        [NSApp sendAction:[item action] to:[item target] from:[item representedObject]];
}

// NSView dragging destination settings.
// - as drop target: if decoded object is an item, then insert; if NSArray, then replace all
- (unsigned)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([_toolbar customizationPaletteIsRunning]) {
        id droppedObject = [NSUnarchiver unarchiveObjectWithData:[[NSPasteboard pasteboardWithName:NSDragPboard] dataForType:NSToolbarItemIdentifierPboardType]];
        
        if ([droppedObject isKindOfClass:[NSString class]]) {
            NSToolbarItem *item;
            
            item = [NSToolbarItem standardToolbarItemWithIdentifier:droppedObject];
            if (item == nil)
                item = [[_toolbar delegate] toolbar:_toolbar itemForItemIdentifier:droppedObject willBeInsertedIntoToolbar:NO];

            if ([[_toolbar itemIdentifiers] containsObject:droppedObject] &&
                [item allowsDuplicatesInToolbar] == NO)
                return NSDragOperationNone;
        }

        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

// It'd be nice to do the OSX-style visual toolbar item insertion stuff
- (unsigned)draggingUpdated:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    
    if ([_toolbar customizationPaletteIsRunning]) {
        if ([[pasteboard types] containsObject:NSToolbarItemIdentifierPboardType]) {
            id droppedObject = [NSUnarchiver unarchiveObjectWithData:[pasteboard dataForType:NSToolbarItemIdentifierPboardType]];
            
            if ([droppedObject isKindOfClass:[NSArray class]]) {
                [_toolbar setItemsWithIdentifiersFromArray:droppedObject];
            }
            else {
                NSPoint location = [self convertPoint:[sender draggingLocation] fromView:nil];
                NSArray *subviews = [self subviews];
                int i, count = [subviews count];
                
                // Figure out what this drop "means". I figure:
                // [ Item 0 ] [ Item 1 ] [ Item 2 ]
                //  0 ] [ Insert 1 ] [ Insert 2 ] ... etc
                for (i = 0; i < count; ++i) {
                    NSRect frame = [[subviews objectAtIndex:i] frame];
                    
                    frame.origin.x -= floor(frame.size.width/2);
                    
                    if (NSPointInRect(location, frame))
                        break;
                }
                
                [_toolbar insertItemWithItemIdentifier:droppedObject atIndex:i];
            }
            
            return YES;
        }
    }
    
    return NO;
}

- (unsigned)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
{
    return NSDragOperationCopy;
}

- (void)mouseDown:(NSEvent *)event
{
    if ([_toolbar customizationPaletteIsRunning]) {
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        NSView *subview = [self hitTest:[event locationInWindow]];
        int index = [[self subviews] indexOfObject:subview];
        NSToolbarItem *item = [[[_toolbar items] objectAtIndex:index] retain];
        NSRect frame = NSMakeRect(0, 0, [subview frame].size.width + 4, [subview frame].size.height + 4);
        NSImage *image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
        NSData *data = [NSArchiver archivedDataWithRootObject:[item itemIdentifier]];
        // FIX, shouldn't need cast
        id cell = [(NSControl *)[item view] cell];
                        
        [image setCachedSeparately:YES];
        [image lockFocus];
        [cell drawWithFrame:NSInsetRect(frame, 1, 1) inView:nil];
        [[NSColor blackColor] set];
        NSFrameRect(frame);
        [image unlockFocus];
        
        [pasteboard declareTypes:[NSArray arrayWithObject:NSToolbarItemIdentifierPboardType] owner:nil];
        [pasteboard setData:data forType:NSToolbarItemIdentifierPboardType];
        
        [_toolbar removeItemAtIndex:index];
        
        [self dragImage:image 
                     at:NSMakePoint([[item image] size].width/2, [[item image] size].height/2)
                 offset:NSMakeSize(0,0)
                  event:event 
             pasteboard:pasteboard 
                 source:self 
              slideBack:YES];
        
        [item release];
        return;
    }
    else
        [super mouseDown:event];
}

@end
