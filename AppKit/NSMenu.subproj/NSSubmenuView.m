/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSSubmenuView.h>
#import <AppKit/NSMenuWindow.h>
#import <AppKit/NSGraphicsStyle.h>

@implementation NSSubmenuView

#define TITLE_TOP_MARGIN 2
#define TITLE_BOTTOM_MARGIN 2
#define TITLE_KEY_GAP 8
#define RIGHT_ARROW_LEFT_MARGIN 0
#define RIGHT_ARROW_RIGHT_MARGIN 2
#define WINDOW_BORDER_THICKNESS 3

-(NSSize)sizeForMenuItemTitle:(NSMenuItem *)item {
   NSString     *title=[item title];
   NSSize        size=[title sizeWithAttributes: _itemBlackAttributes];

   size.height+=TITLE_TOP_MARGIN+TITLE_BOTTOM_MARGIN;

   return size;
}

-(NSSize)sizeForMenuItemKeyEquivalent:(NSMenuItem *)item {
   NSString     *keyString=[item _keyEquivalentDescription];

   if([[item keyEquivalent] length]==0)
    return NSZeroSize;

   return [keyString sizeWithAttributes: _itemBlackAttributes];
}

-(NSSize)separatorSize {
// the separator is two pixels high with 3 pixels on top, 4 on bottom
  return NSMakeSize(0,9);
}

-(NSSize)checkMarkSize {
// not implemented
// The width is icon width + margins
// The height is the height of the actual icon
   return NSMakeSize(17,7);
}

-(NSSize)rightArrowSize {
   NSSize result=[[self graphicsStyle] sizeOfMenuBranchArrow];
 
   result.height+=TITLE_TOP_MARGIN+TITLE_BOTTOM_MARGIN;
   result.width+=RIGHT_ARROW_LEFT_MARGIN;
   result.width+=RIGHT_ARROW_RIGHT_MARGIN;

   return result;
}

-(NSSize)titleSizeForMenuItem:(NSMenuItem *)item {
   if([item isSeparatorItem])
    return [self separatorSize];
   else {
    NSSize checkMarkSize=[self checkMarkSize];
    NSSize rightArrowSize=[self rightArrowSize];
    NSSize titleSize=[self sizeForMenuItemTitle:item];
    NSSize keySize=[self sizeForMenuItemKeyEquivalent:item];
    float  height=MAX(titleSize.height,keySize.height);

    height=MAX(height,checkMarkSize.height);

    if([item hasSubmenu])
     height=MAX(height,rightArrowSize.height);

    return NSMakeSize(titleSize.width,height);
   }
}

-(NSSize)titleAreaSizeWithMenuItems:(NSArray *)items {
   int      i,count=[items count];
   NSSize   result=NSZeroSize;

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];
    NSSize      size=[self titleSizeForMenuItem:item];

    result.height+=size.height;
    result.width=MAX(result.width,size.width);
   }

   return result;
}

-(NSSize)sizeForMenuItems:(NSArray *)items {
   NSSize   result=NSZeroSize;
   NSSize   checkMarkSize=[self checkMarkSize];
   NSSize   rightArrowSize=[self rightArrowSize];
   int      i,count=[items count];
   NSSize   titleAreaSize=[self titleAreaSizeWithMenuItems:items];
   float    keysWidth=0;

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];
    NSSize      size=[self sizeForMenuItemKeyEquivalent:item];

    keysWidth=MAX(keysWidth,size.width);
   }

   result.height=titleAreaSize.height;
   result.width=checkMarkSize.width;
   result.width+=titleAreaSize.width;
   result.width+= TITLE_KEY_GAP;
   result.width+=keysWidth;
   result.width+=rightArrowSize.width;

// border
   result.width+=6;
   result.height+=6;

   return result;
}

-initWithMenu:(NSMenu *)menu {
   NSRect frame=NSZeroRect;

   [self initWithFrame:frame];

   _menu=[menu retain];
   _selectedItemIndex=NSNotFound;

   _itemFont=[[NSFont menuFontOfSize:0] retain];
   _itemBlackAttributes=[[NSDictionary dictionaryWithObjectsAndKeys:
     _itemFont,NSFontAttributeName,
     [NSColor menuItemTextColor],NSForegroundColorAttributeName,
     nil] retain];
   _itemWhiteAttributes=[[NSDictionary dictionaryWithObjectsAndKeys:
     _itemFont,NSFontAttributeName,
     [NSColor selectedControlTextColor],NSForegroundColorAttributeName,
     nil] retain];
   _itemGrayAttributes=[[NSDictionary dictionaryWithObjectsAndKeys:
     _itemFont,NSFontAttributeName,
     [NSColor disabledControlTextColor],NSForegroundColorAttributeName,
     nil] retain];

   frame.size=[self sizeForMenuItems:[self itemArray]];
   [self setFrame:frame];

   return self;
}

-(void)dealloc {
   // [_menu release]; NSView does this
   [_itemFont release];
   [_itemBlackAttributes release];
   [_itemWhiteAttributes release];
   [_itemGrayAttributes release];
   [super dealloc];
}

-(BOOL)isFlipped {
   return YES;
}

static NSRect boundsToTitleAreaRect(NSRect rect){
   return NSInsetRect(rect, WINDOW_BORDER_THICKNESS, WINDOW_BORDER_THICKNESS);
}

static NSRect drawSubmenuBackground(NSRect rect){
   NSRect   rects[7];
   NSColor *colors[7];

   rects[0]=rect;
   colors[0]=[NSColor controlColor];

   rects[1]=rect;
   rects[1].origin.y=NSMaxY(rect)-1;
   rects[1].size.height=1;
   colors[1]=[NSColor blackColor];

   rects[2]=rect;
   rects[2].origin.x=NSMaxX(rect)-1;
   rects[2].size.width=1;
   colors[2]=[NSColor blackColor];  

   rects[3]=rect;
   rects[3].origin.x+=1;
   rects[3].size.width=1;
   rects[3].origin.y+=1;
   rects[3].size.height-=2;
   colors[3]=[NSColor whiteColor];

   rects[4]=rect;
   rects[4].origin.x+=2;
   rects[4].size.width-=4;
   rects[4].origin.y+=1;
   rects[4].size.height=1;
   colors[4]=[NSColor whiteColor];

   rects[5]=rect;
   rects[5].origin.x+=1;
   rects[5].size.width-=2;
   rects[5].origin.y=NSMaxY(rect)-2;
   rects[5].size.height=1;
   colors[5]=[NSColor darkGrayColor];

   rects[6]=rect;
   rects[6].origin.x=NSMaxX(rect)-2;
   rects[6].size.width=1;
   rects[6].origin.y=1;
   rects[6].size.height-=2;
   colors[6]=[NSColor darkGrayColor];

   NSRectFillListWithColors(rects,colors,7);

   return boundsToTitleAreaRect(rect);
}

-(float)drawSeparatorItemAtPoint:(NSPoint)point width:(float)width {   
   point.x+=1;
   point.y+=3;
   width-=2;

   [[self graphicsStyle] drawMenuSeparatorInRect:NSMakeRect(point.x,point.y,width,2)];
   
   return [self separatorSize].height;
}

-(void)drawRect:(NSRect)rect {
   NSRect   itemArea=drawSubmenuBackground([self bounds]);
   NSArray *items=[self itemArray];
   unsigned i,count=[items count];
   NSSize   titleAreaSize=[self titleAreaSizeWithMenuItems:items];
   NSPoint  origin=itemArea.origin;

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];

    if([item isSeparatorItem]){
     origin.y+=[self drawSeparatorItemAtPoint:origin width:itemArea.size.width];
    }
    else {
     BOOL          selected=(i==_selectedItemIndex)?YES:NO;
     NSPoint       point=origin;
     NSDictionary *attributes=selected?_itemWhiteAttributes:_itemBlackAttributes;
     NSString     *title=[item title];
     NSString     *keyString=[item _keyEquivalentDescription];
     float         itemHeight=[title sizeWithAttributes:attributes].height+TITLE_TOP_MARGIN+TITLE_BOTTOM_MARGIN;

     if(selected){
      NSRect fill=NSMakeRect(origin.x,origin.y,itemArea.size.width,itemHeight);
      [[NSColor selectedControlColor] set];
      NSRectFill(fill);
     }

     point.x+=[self checkMarkSize].width;
     point.y+=TITLE_TOP_MARGIN;

     if([item isEnabled] || [item hasSubmenu])
      [title drawAtPoint:point withAttributes:attributes];
     else {
      if(!selected)
       [title drawAtPoint:NSMakePoint(point.x+1,point.y+1) withAttributes:_itemWhiteAttributes];

      [title drawAtPoint:point withAttributes:_itemGrayAttributes];
     }

     if([[item keyEquivalent] length]>0){
      point.x+=titleAreaSize.width+TITLE_KEY_GAP;
      if([item isEnabled] || [item hasSubmenu])
       [keyString drawAtPoint:point withAttributes:attributes];
      else {
       if(!selected)
        [keyString drawAtPoint:NSMakePoint(point.x+1,point.y+1) withAttributes:_itemWhiteAttributes];

       [keyString drawAtPoint:point withAttributes:_itemGrayAttributes];
      }
     }

     if([item hasSubmenu]){
      NSSize size=[[self graphicsStyle] sizeOfMenuBranchArrow];

      point.x=NSMaxX(itemArea)-RIGHT_ARROW_RIGHT_MARGIN-size.width;
      [[self graphicsStyle] drawMenuBranchArrowAtPoint:point selected:selected];
     }

     origin.y+=[title sizeWithAttributes:attributes].height+TITLE_TOP_MARGIN+TITLE_BOTTOM_MARGIN;
    }
   }
}

-(float)heightOfMenuItem:(NSMenuItem *)item {
   NSSize titleSize=[self titleSizeForMenuItem:item];

   return titleSize.height;
}

-(unsigned)itemIndexAtPoint:(NSPoint)point {
   NSArray *items=[[self menu] itemArray];
   unsigned i,count=[items count];
   NSRect   check=boundsToTitleAreaRect([self bounds]);

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];

    check.size.height=[self heightOfMenuItem:item];

    if(NSMouseInRect(point,check,[self isFlipped]))
     return i;

    check.origin.y+=check.size.height;
   }

   return NSNotFound;
}

-(void)positionBranchForSelectedItem:(NSWindow *)branch screen:(NSScreen *)screen {
   NSRect   branchFrame=[branch frame];
   NSRect   screenVisible=[screen visibleFrame];
   NSArray *items=[[self menu] itemArray];
   unsigned i,count=[items count];
   NSRect   itemRect=boundsToTitleAreaRect([self bounds]);
   NSPoint  topLeft=NSZeroPoint;

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];

    itemRect.size.height=[self heightOfMenuItem:item];

    if(i==_selectedItemIndex){
     topLeft=itemRect.origin;

     topLeft.x+=itemRect.size.width;
     topLeft.y-=WINDOW_BORDER_THICKNESS;

     break;
    }

    itemRect.origin.y+=itemRect.size.height;
   }

   topLeft=[self convertPoint:topLeft toView:nil];
   topLeft=[[self window] convertBaseToScreen:topLeft];

   if(topLeft.y-branchFrame.size.height<NSMinY(screenVisible)){
    topLeft=itemRect.origin;

    topLeft.x+=itemRect.size.width;
    topLeft.y+=itemRect.size.height;
    topLeft.y+=WINDOW_BORDER_THICKNESS;

    topLeft=[self convertPoint:topLeft toView:nil];
    topLeft=[[self window] convertBaseToScreen:topLeft];

    topLeft.y+=branchFrame.size.height;
   }

   if(topLeft.x+branchFrame.size.width>NSMaxX(screenVisible)){
    NSPoint redo=itemRect.origin;

    redo=[self convertPoint:redo toView:nil];
    redo=[[self window] convertBaseToScreen:redo];
    redo.x-=branchFrame.size.width;

    topLeft.x=redo.x;
   }

   [branch setFrameTopLeftPoint:topLeft];
}

-(NSMenuView *)viewAtSelectedIndexPositionOnScreen:(NSScreen *)screen {
   NSArray *items=[self itemArray];

   if(_selectedItemIndex<[items count]){
    NSMenuItem *item=[items objectAtIndex:_selectedItemIndex];

    if([item hasSubmenu]){
     NSMenuWindow *branch=[[NSMenuWindow alloc] initWithMenu:[item submenu]];

     [self positionBranchForSelectedItem:branch screen:screen];

     [branch orderFront:nil];
     return [branch menuView];
    }
   }
   return nil;
}


@end
