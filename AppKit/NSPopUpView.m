/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Keyboard movement - David Young <daver@geeks.org>
// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSPopUpView.h>
#import <AppKit/NSStringDrawer.h>

enum {
    KEYBOARD_INACTIVE,
    KEYBOARD_ACTIVE,
    KEYBOARD_OK,
    KEYBOARD_CANCEL
};

@implementation NSPopUpView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _cellSize=frame.size;
   _font=[[NSFont messageFontOfSize:12] retain];
   _selectedIndex=NSNotFound;
   _pullsDown=NO;
   return self;
}

-(void)dealloc {
   [_font release];
   [super dealloc];
}

-(BOOL)isFlipped {
   return YES;
}

-(void)setFont:(NSFont *)font {
   [_font autorelease];
   _font=[font retain];
}

-(BOOL)pullsDown {
   return _pullsDown;
}

-(void)setPullsDown:(BOOL)pullsDown {
   _pullsDown=pullsDown;
}

-(void)selectItemAtIndex:(int)index {
   _selectedIndex=index;
}

-(NSDictionary *)itemAttributes {
   return [NSDictionary dictionaryWithObjectsAndKeys:
    _font,NSFontAttributeName,
    nil];
}

-(NSDictionary *)selectedItemAttributes {
   return [NSDictionary dictionaryWithObjectsAndKeys:
    _font,NSFontAttributeName,
    [NSColor selectedTextColor],NSForegroundColorAttributeName,
    nil];
}

-(NSSize)sizeForContents {
   NSArray      *items=[_menu itemArray];
   int           count=[items count];
   NSSize        result=NSMakeSize([self bounds].size.width,4);

   result.height+=count*_cellSize.height;

   return result;
}

-(unsigned)itemIndexForPoint:(NSPoint)point {
   unsigned result;

   point.y-=2;
   result=floor(point.y/_cellSize.height);

   if(result>=[[_menu itemArray] count])
    result=NSNotFound;

   return result;
}

-(NSRect)rectForItemAtIndex:(unsigned)index {
   NSRect result=NSMakeRect(2,2,_cellSize.width,_cellSize.height);

   result.size.width-=4;
   result.origin.y+=index*_cellSize.height;

   return result;
}

-(NSRect)rectForSelectedItem {
   if(_pullsDown)
    return [self rectForItemAtIndex:0];
   else if(_selectedIndex==NSNotFound)
    return [self rectForItemAtIndex:0];
   else
    return [self rectForItemAtIndex:_selectedIndex];
}

-(void)drawItemAtIndex:(unsigned)index {
   NSMenuItem   *item=[_menu itemAtIndex:index];
   NSDictionary *attributes;

   if(index==_selectedIndex)
    attributes=[self selectedItemAttributes];
   else
    attributes=[self itemAttributes];

   if([item isSeparatorItem]){
   }
   else {
    NSString *string=[item title];
    NSSize    size=[string sizeWithAttributes:attributes];
    NSRect    itemRect=[self rectForItemAtIndex:index];

    if(index==_selectedIndex){
     [[NSColor selectedTextBackgroundColor] set];
     NSRectFill(itemRect);
    }
    else {
     [[NSColor controlColor] set];
     NSRectFill(itemRect);
    }

    itemRect=NSInsetRect(itemRect,2,2);
    itemRect.origin.y+=floor((_cellSize.height-size.height)/2);
    itemRect.size.height=size.height;
     
    [string _clipAndDrawInRect:itemRect withAttributes:attributes];
   }
}

-(void)drawRect:(NSRect)rect {
   NSArray      *items=[_menu itemArray];
   int           i,count=[items count];

   NSDrawButton([self bounds],[self bounds]);

   for(i=0;i<count;i++){
    [self drawItemAtIndex:i];
   }
}

-(void)rightMouseDown:(NSEvent *)event {
   // do nothing
}

// DWY: trying to do keyboard navigation with as little impact on the rest of the code as possible...
-(int)runTrackingWithEvent:(NSEvent *)event {
   enum {
    STATE_FIRSTMOUSEDOWN,
    STATE_MOUSEDOWN,
    STATE_MOUSEUP,
    STATE_EXIT
   } state=STATE_FIRSTMOUSEDOWN;
   NSPoint firstLocation,point=[event locationInWindow];
   unsigned initialSelectedIndex = _selectedIndex;

// point comes in on controls window
   point=[[event window] convertBaseToScreen:point];
   point=[[self window] convertScreenToBase:point];
   point=[self convertPoint:point fromView:nil];
   firstLocation=point;

   [self lockFocus];
   [self drawRect:[self bounds]];

   do {
    unsigned index=[self itemIndexForPoint:point];
    NSRect   screenVisible;

    if(index!=NSNotFound && _keyboardUIState == KEYBOARD_INACTIVE){
     if(_selectedIndex!=index){
      unsigned previous=_selectedIndex;

      _selectedIndex=index;

      if(previous!=NSNotFound)
       [self drawItemAtIndex:previous];

      [self drawItemAtIndex:_selectedIndex];
     }
    }
    [[self window] flushWindow];

    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSKeyDownMask];
    if ([event type] == NSKeyDown) {
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
        switch (_keyboardUIState) {
            case KEYBOARD_INACTIVE:
                _keyboardUIState = KEYBOARD_ACTIVE;
                continue;

            case KEYBOARD_ACTIVE:
                break;
                
            case KEYBOARD_CANCEL:
                _selectedIndex = initialSelectedIndex;
            case KEYBOARD_OK:
                state=STATE_EXIT;
                break;
        }
    }
    else
        _keyboardUIState = KEYBOARD_INACTIVE;
    
    point=[event locationInWindow];
    point=[[event window] convertBaseToScreen:point];
    screenVisible=NSInsetRect([[[self window] screen] visibleFrame],4,4);
    if(NSPointInRect(point,[[self window] frame]) && !NSPointInRect(point,screenVisible)){
     NSPoint origin=[[self window] frame].origin;
     BOOL    change=NO;

     if(point.y<NSMinY(screenVisible)){
      origin.y+=_cellSize.height;
      change=YES;
     }

     if(point.y>NSMaxY(screenVisible)){
      origin.y-=_cellSize.height;
      change=YES;
     }

     if(change)
      [[self window] setFrameOrigin:origin];
    }

    point=[self convertPoint:[event locationInWindow] fromView:nil];

    switch(state){
     case STATE_FIRSTMOUSEDOWN:
      if(NSEqualPoints(firstLocation,point)){
       if([event type]==NSLeftMouseUp)
        state=STATE_MOUSEUP;
      }
      else
       state=STATE_MOUSEDOWN;      
      break;

     default:
      if([event type]==NSLeftMouseUp)
       state=STATE_EXIT;
      break;
    }

   }while(state!=STATE_EXIT);

   [self unlockFocus];

   _keyboardUIState = KEYBOARD_INACTIVE;
   
   return _selectedIndex;
}

- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)moveUp:(id)sender {
    int previous = _selectedIndex;
    
    _selectedIndex--;
    if ((int)_selectedIndex < 0)
        _selectedIndex = 0;

    if (previous != NSNotFound)
        [self drawItemAtIndex:previous];

    [self drawItemAtIndex:_selectedIndex];
}

- (void)moveDown:(id)sender {
    int previous = _selectedIndex;
    
    _selectedIndex++;
    if (_selectedIndex >= [[_menu itemArray] count])
        _selectedIndex = [[_menu itemArray] count]-1;

    if (previous != NSNotFound)
        [self drawItemAtIndex:previous];

    [self drawItemAtIndex:_selectedIndex];
}

- (void)cancel:(id)sender {
    _keyboardUIState = KEYBOARD_CANCEL;
}

- (void)insertNewline:(id)sender {
    _keyboardUIState = KEYBOARD_OK;
}

@end
