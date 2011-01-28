/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSPopUpView.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSGraphicsStyle.h>

enum {
    KEYBOARD_INACTIVE,
    KEYBOARD_ACTIVE,
    KEYBOARD_OK,
    KEYBOARD_CANCEL
};

#define ITEM_MARGIN 2

@implementation NSPopUpView

// Note: moved these above init to avoid compiler warnings
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

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _cellSize=frame.size;
   _font=[[NSFont messageFontOfSize:12] retain];
   _selectedIndex=NSNotFound;
   _pullsDown=NO;

   NSSize sz = [@"ABCxyzgjX" sizeWithAttributes: [self itemAttributes] ];
   _cellSize.height = sz.height + ITEM_MARGIN + ITEM_MARGIN;
   
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

-(NSSize)sizeForContents {
   NSArray      *items=[_menu itemArray];
   int           i, count=[items count];
   NSSize        result=NSMakeSize([self bounds].size.width,4);
   NSDictionary *attributes = [self itemAttributes];

   for( i = 0; i < count; i++ )
   {
      NSMenuItem * item = [items objectAtIndex: i];
      if( ![item isHidden ] )
	  {
	     result.height += _cellSize.height;
		 NSSize titleSize = [[item title] sizeWithAttributes: attributes ];

		 if( result.width < titleSize.width )
			result.width = titleSize.width;
	  }
   }
   
   return result;
}

-(unsigned)itemIndexForPoint:(NSPoint)point {
   unsigned result;
   NSArray * items=[_menu itemArray];
   int i, count = [items count];
   
   point.y-=2;

   if( point.y < 0 )
      return NSNotFound;
	
   for( i = 0; i < count; i++ )
   {
      if( [[items objectAtIndex: i] isHidden ] )
	     continue;
      if( point.y < _cellSize.height )
	     return i;
	  point.y -= _cellSize.height;
   }
   return NSNotFound;
}

-(NSRect)rectForItemAtIndex:(unsigned)index {
   NSRect result=NSMakeRect(2,2,[self bounds].size.width,_cellSize.height);

   result.size.width-=4;
   
   NSArray * items=[_menu itemArray];
   int i, count = [items count];
   
   for( i = 0; i < index; i++ )
   {
      if( [[items objectAtIndex: i] isHidden ] )
	     continue;
	  result.origin.y += _cellSize.height;
   }

   return result;
}

-(NSRect)rectForSelectedItem {
   if(_pullsDown)
    return [self rectForItemAtIndex:0];
   else if(_selectedIndex==NSNotFound || _selectedIndex==-1)
    return [self rectForItemAtIndex:0];
   else
    return [self rectForItemAtIndex:_selectedIndex];
}

-(void)drawItemAtIndex:(unsigned)index {
   NSMenuItem   *item=[_menu itemAtIndex:index];
   NSDictionary *attributes;
   NSRect    itemRect=[self rectForItemAtIndex:index];

   if( [item isHidden] )
      return;
	
   if(index==_selectedIndex)
    attributes=[self selectedItemAttributes];
   else
    attributes=[self itemAttributes];

   if([item isSeparatorItem]){
	NSRect r = itemRect;
	r.origin.y += r.size.height / 2 - 1;
	r.size.height = 2;
	[[self graphicsStyle] drawMenuSeparatorInRect:r];
   }
   else {
    NSString *string=[item title];
    NSSize    size=[string sizeWithAttributes:attributes];

    if(index==_selectedIndex){
     [[NSColor selectedTextBackgroundColor] setFill];
     NSRectFill(itemRect);
    }
    else {
     [[NSColor controlColor] setFill];
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

   [[self graphicsStyle] drawPopUpButtonWindowBackgroundInRect:[self bounds]];

   for(i=0;i<count;i++){
    [self drawItemAtIndex:i];
   }
}

-(void)rightMouseDown:(NSEvent *)event {
   // do nothing
}

/*
 This method may return NSNotFound when the view positioned outside the initial tracking area due to preferredEdge settings and the user clicks the mouse. The NSPopUpButtonCell code deals with it. It might make sense for this to return the previous value.
 */
-(int)runTrackingWithEvent:(NSEvent *)event {
   enum {
    STATE_FIRSTMOUSEDOWN,
    STATE_MOUSEDOWN,
    STATE_MOUSEUP,
    STATE_EXIT
   } state=STATE_FIRSTMOUSEDOWN;
   NSPoint firstLocation,point=[event locationInWindow];
   unsigned initialSelectedIndex = _selectedIndex;

   // Make sure we get mouse moved events, too, so we can respond apporpiately to
   // click-click actions as well as of click-and-drag
   BOOL oldAcceptsMouseMovedEvents = [[self window] acceptsMouseMovedEvents];
   [[self window] setAcceptsMouseMovedEvents:YES];

// point comes in on controls window
   point=[[event window] convertBaseToScreen:point];
   point=[[self window] convertScreenToBase:point];
   point=[self convertPoint:point fromView:nil];
   firstLocation=point;

   do {
    unsigned index=[self itemIndexForPoint:point];
    NSRect   screenVisible;

    if(/*index!=NSNotFound && */_keyboardUIState == KEYBOARD_INACTIVE){
     if(_selectedIndex!=index){
      unsigned previous=_selectedIndex;

      _selectedIndex=index;
     }
    }
    [self setNeedsDisplay:YES];
    [[self window] flushWindow];

    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSMouseMovedMask|NSLeftMouseDraggedMask|NSKeyDownMask];
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

   [[self window] setAcceptsMouseMovedEvents: oldAcceptsMouseMovedEvents];

   _keyboardUIState = KEYBOARD_INACTIVE;
   
   return _selectedIndex;
}

- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)moveUp:(id)sender {
    int previous = _selectedIndex;

	// Find the previous visible item
	NSArray *items = [_menu itemArray];
	if( _selectedIndex == NSNotFound )
		_selectedIndex = [items count];

	do
	{
		_selectedIndex--;
	} while( (int)_selectedIndex >= 0 && ( [[items objectAtIndex: _selectedIndex] isHidden] ||
									  [[items objectAtIndex: _selectedIndex] isSeparatorItem] ) );
	
    if ((int)_selectedIndex < 0)
        _selectedIndex = previous;

    [self setNeedsDisplay:YES];
}

- (void)moveDown:(id)sender {
    int previous = _selectedIndex;
    
	// Find the next visible item
	NSArray *items = [_menu itemArray];
	if( _selectedIndex == NSNotFound )
		_selectedIndex = -1;
		
	do
	{
		_selectedIndex++;
	} while( _selectedIndex < [items count] && ( [[items objectAtIndex: _selectedIndex] isHidden] ||
									             [[items objectAtIndex: _selectedIndex] isSeparatorItem] )  );

   if (_selectedIndex >= [items count])
        _selectedIndex = previous;

    [self setNeedsDisplay:YES];
}

- (void)cancel:(id)sender {
    _keyboardUIState = KEYBOARD_CANCEL;
}

- (void)insertNewline:(id)sender {
    _keyboardUIState = KEYBOARD_OK;
}

@end
