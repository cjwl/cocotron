/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSPopUpButton.h>	// for indexOfSelectedItem definition
#import <AppKit/NSNibKeyedUnarchiver.h>

@interface NSTabViewItem(NSTabViewItem_private)
-(void)setTabView:(NSTabView *)tabView;
-(void)setTabState:(NSTabState)tabState;
@end

@implementation NSTabView

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    _items=[[NSMutableArray alloc] initWithArray:[keyed decodeObjectForKey:@"NSTabViewItems"]];
    _selectedItem=[keyed decodeObjectForKey:@"NSSelectedTabViewItem"];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }

   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _items=[NSMutableArray new];
   _selectedItem=nil;
// should probably be boldUserFont
   _font=[[NSFont boldSystemFontOfSize:0] retain];
   _type=NSTopTabsBezelBorder;
   _allowsTruncatedLabels=NO;
   return self;
}

-(void)dealloc {
   [_items release];
   _selectedItem=nil;
   [_font release];
   [super dealloc];
}

-delegate {
   return _delegate;
}

-(NSSize)minimumSize {
    switch (_type) {
        case NSTopTabsBezelBorder:
        case NSLeftTabsBezelBorder:
        case NSBottomTabsBezelBorder:
        case NSRightTabsBezelBorder: {
            NSSize finalSize;
            int i, count=[_items count];

            if (count == 0)
                break;
            
            finalSize = [[_items objectAtIndex:0] sizeOfLabel:_allowsTruncatedLabels];
            for (i = 1; i < count; ++i)
                finalSize.width += [[_items objectAtIndex:i] sizeOfLabel:_allowsTruncatedLabels].width;

            return finalSize;
        }

        case NSNoTabsBezelBorder:
        case NSNoTabsLineBorder:
        case NSNoTabsNoBorder:
        default:
            break;
    }

    return NSMakeSize(0,0);	// correct?
}

-(NSRect)rectForBorder {
    NSRect result=[self bounds];

    switch (_type) {
        case NSTopTabsBezelBorder:
        case NSLeftTabsBezelBorder:
        case NSBottomTabsBezelBorder:
        case NSRightTabsBezelBorder:
            result.size.height-=24;
            break;

        case NSNoTabsBezelBorder:
        case NSNoTabsLineBorder:
        case NSNoTabsNoBorder:
        default:
            break;
    }

    return result;
}

-(NSRect)contentRect {
   NSRect result=[self rectForBorder];

    switch (_type) {
        case NSTopTabsBezelBorder:
        case NSLeftTabsBezelBorder:
        case NSBottomTabsBezelBorder:
        case NSRightTabsBezelBorder:
        case NSNoTabsBezelBorder:
            return NSInsetRect(result,2,2);

        case NSNoTabsLineBorder:
            return NSInsetRect(result,1,1);

        case NSNoTabsNoBorder:
        default:
            return result;
    }
}

-(NSFont *)font {
   return _font;
}

-(NSTabViewType)tabViewType {
    return _type;
}

-(BOOL)drawsBackground {
    return _drawsBackground;
}

-(BOOL)allowsTruncatedLabels {
    return _allowsTruncatedLabels;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setFont:(NSFont *)font {
   font=[font retain];
   [_font release];
   _font=font;
}

-(void)setTabViewType:(NSTabViewType)type {
    _type = type;
    [self setNeedsDisplay:YES];
}

-(void)setDrawsBackground:(BOOL)flag {
    _drawsBackground = flag;
    [self setNeedsDisplay:YES];
}

-(void)setAllowsTruncatedLabels:(BOOL)flag {
    _allowsTruncatedLabels = flag;
    [self setNeedsDisplay:YES];
}

-(int)numberOfTabViewItems {
    return [_items count];
}

-(NSArray *)tabViewItems {
    return _items;
}
	
-(NSTabViewItem *)tabViewItemAtIndex:(int)index {
    return [_items objectAtIndex:index];
}

-(NSRect)rectForItemLabelAtIndex:(unsigned)index {
   int            i,count=[_items count];
   NSPoint        base=NSMakePoint(0,[self bounds].size.height-22);
   NSSize         size;

    base.x+=6;
    for(i=0;i<count && i<index;i++){
     size=[[_items objectAtIndex:i] sizeOfLabel:NO];

     base.x+=size.width;
     base.x+=8;
    }

    size=[[_items objectAtIndex:index] sizeOfLabel:NO];

    return NSMakeRect(base.x,base.y,size.width,size.height);
}

-(NSTabViewItem *)tabViewItemAtPoint:(NSPoint)point {
   int i,count=[_items count];

   for(i=0;i<count;i++){
    NSTabViewItem *item=[_items objectAtIndex:i];
    NSRect         rect=[self rectForItemLabelAtIndex:i];

    if(NSMouseInRect(point,rect,[self isFlipped]))
     return item;
   }

   return nil;
}

-(int)indexOfTabViewItem:(NSTabViewItem *)item {
    return [_items indexOfObject:item];
}

-(int)indexOfTabViewItemWithIdentifier:identifier {
    int i, count=[_items count];

    for (i = 0; i < count; ++i)
        if ([[(NSTabViewItem *)[_items objectAtIndex:i] identifier] isEqual:identifier])
            return i;

    return NSNotFound;
}

-(void)addTabViewItem:(NSTabViewItem *)item {
   [_items addObject:item];
   if(_selectedItem==nil)
    [self selectTabViewItem:item];
   [item setTabView:self];

   if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
       [_delegate tabViewDidChangeNumberOfTabViewItems:self];

   [self setNeedsDisplay:YES];
}

-(void)removeTabViewItem:(NSTabViewItem *)item {
    [_items removeObject:item];

    if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];

    [self setNeedsDisplay:YES];
}

-(void)insertTabViewItem:(NSTabViewItem *)item atIndex:(int)index {
    [_items insertObject:item atIndex:index];
    if (_selectedItem==nil)
        [self selectTabViewItem:item];
    [item setTabView:self];

    if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];

    [self setNeedsDisplay:YES];
}

-(NSTabViewItem *)selectedTabViewItem {
   return _selectedItem;
}

// delegate methods go here
-(void)selectTabViewItem:(NSTabViewItem *)item {
    if(item!=_selectedItem) {
        BOOL selectItem=YES;

        if ([_delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
            selectItem=[_delegate tabView:self shouldSelectTabViewItem:item];        

        if (selectItem) {
            if ([_delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
                [_delegate tabView:self willSelectTabViewItem:item];
            
            [[_selectedItem view] removeFromSuperview];
            if([item view]!=nil){
             [self addSubview:[item view]];
             [[item view] setFrame:[self contentRect]];
            }
            _selectedItem=item;

            if ([item initialFirstResponder])
                [[self window] makeFirstResponder:[item initialFirstResponder]];

            if ([_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
                [_delegate tabView:self didSelectTabViewItem:item];
        }
// Since we're not opaque, we need to redraw the superview too
// Shouldn't the view machinery do this automatically?? it might now
       [[self superview] setNeedsDisplay:YES];
    }
}

-(void)selectTabViewItemAtIndex:(int)index {
    [self selectTabViewItem:[_items objectAtIndex:index]];
}

-(void)selectTabViewItemWithIdentifier:identifier {
    [self selectTabViewItemAtIndex:[self indexOfTabViewItemWithIdentifier:identifier]];
}

-(void)selectFirstTabViewItem:sender {
   [self selectTabViewItem:([_items count]==0)?nil:[_items objectAtIndex:0]];
}

-(void)takeSelectedTabViewItemFromSender:sender {
    if ([sender respondsToSelector:@selector(indexOfSelectedItem)])
        [self selectTabViewItemAtIndex:[sender indexOfSelectedItem]];
    else if ([sender isKindOfClass:[NSMatrix class]])
        [self selectTabViewItemAtIndex:[[sender cells] indexOfObject:[sender selectedCell]]];
}

-(NSRect)rectForItemBorderAtIndex:(unsigned)index {
   NSRect result=[self rectForItemLabelAtIndex:index];

   result=NSInsetRect(result,-4,0);
   result.origin.y=[self bounds].size.height-24;
   result.size.height=24;

   return result;
}

// only works in un-flipped systems
void _NSDrawTab(NSRect rect, NSColor *tabColor, NSRect clipRect,BOOL selected) {
    NSRect rects[8];
    NSColor *colors[8];
    int i;

    if(selected){
       rect.origin.x-=2;
       rect.size.width+=3;
    }
    else {
     rect.size.height-=2;
    }

    for(i=0; i<8; i++)
        rects[i]=rect;

    colors[0]=[NSColor controlColor];
    if(selected){
     rects[0].origin.y-=1;
     rects[0].size.height+=1;
    }
    colors[1]=tabColor;
    rects[1]=NSInsetRect(rect,1,1);
    colors[2]=[NSColor whiteColor];
    rects[2].size.width=1;
    rects[2].size.height-=2;
    if(selected){
     rects[2].origin.y-=1;
     rects[2].size.height+=1;
    }
    colors[3]=[NSColor whiteColor];
    rects[3].origin.x+=1;
    rects[3].origin.y+=rect.size.height-2;
    rects[3].size.width=1;
    rects[3].size.height=1;
    colors[4]=[NSColor whiteColor];
    rects[4].origin.x+=2;
    rects[4].origin.y+=rect.size.height-1;
    rects[4].size.width=rect.size.width-4;
    rects[4].size.height=1;
    colors[5]=[NSColor blackColor];
    rects[5].origin.x+=rect.size.width-2;
    rects[5].origin.y+=rect.size.height-2;
    rects[5].size.width=1;
    rects[5].size.height=1;
    colors[6]=[NSColor controlShadowColor];
    rects[6].origin.x+=rect.size.width-2;
    rects[6].size.width=1;
    rects[6].size.height-=2;
    colors[7]=[NSColor blackColor];
    rects[7].origin.x+=rect.size.width-1;
    rects[7].size.width=1;
    rects[7].size.height-=2;
    if(selected){
     rects[7].origin.y-=1;
     rects[7].size.height+=1;
    }

    for(i=0; i<8; i++) {
        [colors[i] set];
        NSRectFill(rects[i]);
    }
}

-(void)drawRect:(NSRect)rect {

    switch (_type) {
        case NSTopTabsBezelBorder:
        case NSLeftTabsBezelBorder:
        case NSBottomTabsBezelBorder:
        case NSRightTabsBezelBorder: {
            int    i,count=[_items count];
            NSRect erase;

            for(i=0;i<count;i++){
                NSTabViewItem *item=[_items objectAtIndex:i];

                // defer selected item for overlap
                if (item != _selectedItem) {
                    _NSDrawTab([self rectForItemBorderAtIndex:i],[item color],rect,NO);
                    [item drawLabel:_allowsTruncatedLabels inRect:[self rectForItemLabelAtIndex:i]];
                }
            }

            NSDrawButton([self rectForBorder],rect);

            if((i=[_items indexOfObjectIdenticalTo:_selectedItem])!=NSNotFound){
                // now do selected item
                i = [_items indexOfObject:_selectedItem];

                _NSDrawTab([self rectForItemBorderAtIndex:i],[_selectedItem color],rect,YES);
              {
               NSRect labelRect=[self rectForItemLabelAtIndex:i];
               labelRect.origin.y+=2;

                [_selectedItem drawLabel:_allowsTruncatedLabels inRect: labelRect];

                if ([[self window] firstResponder] == self)
                    NSDottedFrameRect(NSInsetRect(labelRect,-1,0));
              }

                // erase touch-up
                [[NSColor controlColor] set];
                erase=[self rectForItemBorderAtIndex:i];
                erase.size.height=2;
                erase=NSInsetRect(erase,1,0);
                NSRectFill(erase);
            }
            break;
        }
            
        case NSNoTabsBezelBorder:
            NSDrawButton([self rectForBorder],rect);
            break;
            
        case NSNoTabsLineBorder:
            [[NSColor blackColor] set];
            NSFrameRect([self rectForBorder]);
            break;
            
        case NSNoTabsNoBorder:
            if (_drawsBackground) {
                [[NSColor controlColor] set];
                NSRectFill([self rectForBorder]);
            }
            break;
            
        default:
            break;
    }
}

-(void)mouseDown:(NSEvent *)event {
    NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];
    NSTabViewItem *item=[self tabViewItemAtPoint:point];

    if(item!=nil) {
        [_selectedItem setTabState:NSBackgroundTab];
        [self selectTabViewItem:item];

        // item is "pressed" until mouse up. this correct? docs unclear
        // IB 4.x "selects" immediately (at least visually)
        [_selectedItem setTabState:NSPressedTab];

// Since we're not opaque, we need to redraw the superview too
// Shouldn't the view machinery do this automatically?? it might now
       [[self superview] setNeedsDisplay:YES];
        do {
            event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
        } while([event type]!=NSLeftMouseUp);
        
        [_selectedItem setTabState:NSSelectedTab];
    }
    [[self superview] setNeedsDisplay:YES];
}

@end
