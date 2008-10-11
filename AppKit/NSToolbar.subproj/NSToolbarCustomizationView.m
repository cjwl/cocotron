/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSToolbarCustomizationView.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSStandardToolbarItems.h>
#import <AppKit/NSToolbarView.h>
#import <AppKit/NSToolbarButton.h>
#import <AppKit/NSToolbarButtonCell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSToolbar-Private.h>

#define ITEM_SPACING        4.0
#define ITEM_LINE_THRESHOLD   4

@interface NSToolbarItem (NSToolbarItem_private)
- (NSSize)sizeForPalette;
@end

@implementation NSToolbarCustomizationView

- (id)initWithFrame:(NSRect)frame toolbar:(NSToolbar *)toolbar isDefaultSetView:(BOOL)isDefaultSetView
{
    [super initWithFrame:frame];
    _toolbar = [toolbar retain];
        
    [self setDefaultSetView:isDefaultSetView];
    
    return self;
}

- (void)dealloc
{
    [_toolbar release];
    
    [super dealloc];
}

- (NSToolbar *)toolbar
{
    return _toolbar;
}

- (BOOL)isOpaque 
{
    return YES;
}

- (void)setDefaultSetView:(BOOL)flag
{
    _isDefaultSetView = flag;
}

- (BOOL)isDefaultSetView
{
    return _isDefaultSetView;
}

// Hmm. Well, for custom toolbar views, if the item's view provides a cell, it can use that to draw on the palette too.
- (void)drawRect:(NSRect)frame
{
    NSArray *items = [_toolbar _allowedToolbarItems];
    int i, count, thresholdCount = 0;
    float rowHeight = 0;
    NSRect itemFrame = NSInsetRect(frame, 1, 1);
        
    [[NSColor windowBackgroundColor] setFill];
    NSRectFill(frame);

    if ([self isDefaultSetView]) {
        [[NSColor blackColor] setStroke];
        NSFrameRect(frame);
        
        items = [_toolbar _defaultToolbarItems];
    }

    count = [items count];
    for (i = 0; i < count; ++i) {
        NSToolbarItem *item = [items objectAtIndex:i];
        id cell = nil;

        if ([[item view] respondsToSelector:@selector(cell)])
            cell = [[[(NSControl *)[item view] cell] copy] autorelease];
        else
            cell = [[[NSToolbarButtonCell alloc] init] autorelease];

        [cell setImage:[item image]];
       
       if ([self isDefaultSetView] == YES) {
            [cell setTitle:[item label]];
            itemFrame = [NSToolbarView constrainedToolbarItemFrame:itemFrame minSize:[item minSize] maxSize:[self bounds].size sizeMode:NSToolbarDisplayModeDefault displayMode:NSToolbarSizeModeDefault];
        }
        else  {
            [cell setTitle:[item paletteLabel]];
            itemFrame.size = [item sizeForPalette];
            itemFrame.size.width = [self frame].size.width / ITEM_LINE_THRESHOLD;
        }

        rowHeight = MAX(rowHeight, itemFrame.size.height);
                
        // we pass nil for controlView so that the cell will draw with the default settings.
        if ([self isDefaultSetView] && ([item isSpaceToolbarItem] || [item isFlexibleSpaceToolbarItem]))
            ;
        else
        {
            [cell drawWithFrame:itemFrame inView:nil];
        }
        
        if ([self isDefaultSetView] == YES)
            itemFrame.origin.x += itemFrame.size.width; // + ITEM_SPACING;
        else
            itemFrame.origin.x += [self frame].size.width / ITEM_LINE_THRESHOLD;

        thresholdCount++;
        
        if (thresholdCount == ITEM_LINE_THRESHOLD && [self isDefaultSetView] == NO) {
            itemFrame.origin.x = frame.origin.x + 2;
            itemFrame.origin.y += rowHeight + ITEM_SPACING;
            rowHeight = 0.0;
            thresholdCount = 0;
        }
    }        
}

- (void)sizeToFit
{
    NSSize viewSize = [self bounds].size;
    NSSize itemSize = NSMakeSize(0, 0);
    NSArray *items = [_toolbar _allowedToolbarItems];
    int i, count, thresholdCount = 0, rows = 0;
    float width = 0;
    
    if ([self isDefaultSetView])
        items = [_toolbar _defaultToolbarItems];
    
    count = [items count];
    for (i = 0; i < count; ++i) {
       NSToolbarItem *item = [items objectAtIndex:i];
       
        itemSize.width = MAX(itemSize.width, [item sizeForPalette].width);
        itemSize.height = MAX(itemSize.height, [item sizeForPalette].height);
        
        if ([self isDefaultSetView] == YES)
            width += [NSToolbarView constrainedToolbarItemFrame:NSMakeRect(0, 0, itemSize.width, itemSize.height) minSize:[item minSize] maxSize:[item maxSize] sizeMode:NSToolbarDisplayModeDefault displayMode:NSToolbarSizeModeDefault].size.width; // + ITEM_SPACING;
        else            
            width += [item sizeForPalette].width; // + ITEM_SPACING;
        
        if (++thresholdCount == ITEM_LINE_THRESHOLD && [self isDefaultSetView] == NO) {
            thresholdCount = 0;
            rows++;
        }
    }
    
    if (rows > 0) {
        viewSize.width = (itemSize.width /* + ITEM_SPACING */) * ITEM_LINE_THRESHOLD;
        viewSize.height = (itemSize.height + ITEM_SPACING) * rows;
    }
    else {
        viewSize.width = width;
    }
    
    // allow for black border!
    if ([self isDefaultSetView]) {
        viewSize.width += 4;
        viewSize.height += 2;
    }
    
    [self setBoundsSize:viewSize];
    [self setFrameSize:viewSize];
}

- (void)mouseDown:(NSEvent *)event 
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    
    if ([self isDefaultSetView]) {
        NSImage *image = [[[NSImage alloc] initWithSize:_bounds.size] autorelease];
        NSData *data = [NSArchiver archivedDataWithRootObject:[[_toolbar _defaultToolbarItems] valueForKey:@"itemIdentifier"]];
        
        [image setCachedSeparately:YES];
        [image lockFocus];
        [self drawRect:_bounds];        
        [image unlockFocus];
        
        [pasteboard declareTypes:[NSArray arrayWithObject:NSToolbarItemIdentifierPboardType] owner:nil];
        [pasteboard setData:data forType:NSToolbarItemIdentifierPboardType];
        
        [self dragImage:image at:NSMakePoint(0,0) offset:NSMakeSize(0,0) event:event pasteboard:pasteboard source:self slideBack:YES];
    }
    else {
        NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        NSArray *items = [_toolbar _allowedToolbarItems];
        int i, count, thresholdCount = 0;
        float rowHeight = 0;
        NSRect itemFrame = NSInsetRect(_bounds, 1, 1);
        
        count = [items count];
        for (i = 0; i < count; ++i) {
            NSToolbarItem *item = [items objectAtIndex:i];

            itemFrame.size = [item sizeForPalette];
            itemFrame.size.width = [self frame].size.width / ITEM_LINE_THRESHOLD;

            if (NSPointInRect(point, itemFrame)) {
                NSRect frame = NSMakeRect(0, 0, itemFrame.size.width + 4, itemFrame.size.height + 4);
                NSImage *image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
                NSData *data = [NSArchiver archivedDataWithRootObject:[item itemIdentifier]];
                id cell;
                
                if ([[item view] respondsToSelector:@selector(cell)])
                    cell = [[[(NSControl *)[item view] cell] copy] autorelease];
                else
                    cell = [[[NSToolbarButtonCell alloc] init] autorelease];
                
                [cell setImage:[item image]];
                [cell setTitle:[item paletteLabel]];
            
                [image setCachedSeparately:YES];
                [image lockFocus];
                [cell drawWithFrame:NSInsetRect(frame, 1, 1) inView:nil];
                [[NSColor blackColor] setStroke];
                NSFrameRect(frame);
                [image unlockFocus];
                
                [pasteboard declareTypes:[NSArray arrayWithObject:NSToolbarItemIdentifierPboardType] owner:nil];
                [pasteboard setData:data forType:NSToolbarItemIdentifierPboardType];
                
                [self dragImage:image 
                             at:NSMakePoint([[item image] size].width/2, [[item image] size].height/2)
                         offset:NSMakeSize(0,0)
                          event:event 
                     pasteboard:pasteboard 
                         source:self 
                      slideBack:YES];
                return;
            }

            rowHeight = MAX(rowHeight, itemFrame.size.height);            
            itemFrame.origin.x += [self frame].size.width / ITEM_LINE_THRESHOLD;
            thresholdCount++;
            
            if (thresholdCount == ITEM_LINE_THRESHOLD) {
                itemFrame.origin.x = _bounds.origin.x + 2;
                itemFrame.origin.y += rowHeight + ITEM_SPACING;
                rowHeight = 0.0;
                thresholdCount = 0;
            }
        }
    }
}
 
- (unsigned)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
{
    return NSDragOperationCopy;
}

@end

NSString *NSToolbarItemIdentifierPboardType = @"NSToolbarItemIdentifierPboardType";
