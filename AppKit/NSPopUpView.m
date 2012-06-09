/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSPopUpView.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSMenuItem.h>
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

-(NSDictionary *)disabledItemAttributes {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			_font,NSFontAttributeName,
			[NSColor grayColor],NSForegroundColorAttributeName,
			nil];
}

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _cellSize=frame.size;
   _font=[[NSFont messageFontOfSize:12] retain];
   _selectedIndex=-1;
   _pullsDown=NO;

   NSSize sz = [@"ABCxyzgjX" sizeWithAttributes: [self itemAttributes] ];
   _cellSize.height = sz.height + ITEM_MARGIN + ITEM_MARGIN;
   
   return self;
}

-(void)dealloc {
	[_cachedOffsets release];
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
		  NSAttributedString* aTitle = [item attributedTitle];
		  if (aTitle != nil && [aTitle length] > 0) {
			  // The user is using an attributed title - so respect that when calc-ing the height and width
			  NSSize size = [aTitle size];
			  result.height += MAX(_cellSize.height, size.height);
			  size.width += [item indentationLevel] * 5;
			  result.width = MAX(result.width, size.width);
		  } else {
				result.height += _cellSize.height;

			  NSSize titleSize = [[item title] sizeWithAttributes: attributes ];

			  titleSize.width += [item indentationLevel] * 5;

			 if( result.width < titleSize.width )
				result.width = titleSize.width;
		  }
	  }
   }
   
   return result;
}

- (void)_buildCachedOffsets
{
	NSRect result=NSMakeRect(2,2,[self bounds].size.width,_cellSize.height);
	
	NSArray * items=[_menu itemArray];
	int i, count = [items count];
	
	_cachedOffsets = [[NSMutableArray arrayWithCapacity: count] retain];
	
	CGFloat yOffset = 0;
	
	// First offset is 0 of course
	[_cachedOffsets addObject: [NSNumber numberWithFloat: 0]];
	
	// Stop one before the end because we're just figuring how far down each one is based on the preceding
	// entries.
	for( i = 0; i < count - 1; i++ )
	{
		NSMenuItem* item = [items objectAtIndex: i];
		
		if( [item isHidden ] ) {
			continue;
		}
		
		NSAttributedString* aTitle = [item attributedTitle];
		if (aTitle != nil && [aTitle length] > 0) {
			NSSize size = [aTitle size];
			yOffset += MAX(_cellSize.height, size.height);
		} else {
			yOffset += _cellSize.height;
		}
		[_cachedOffsets addObject: [NSNumber numberWithFloat: yOffset]];
	}
}

// For attributed strings - precalcing the the offsets makes performance much faster.
- (NSArray*)_cachedOffsets
{
	if (_cachedOffsets == nil) {
		[self _buildCachedOffsets];
	}
	return _cachedOffsets;
}

-(NSRect)rectForItemAtIndex:(NSInteger)index {
   NSRect result=NSMakeRect(2,2,[self bounds].size.width,_cellSize.height);

   result.size.width-=4;

	result.origin.y = [[[self _cachedOffsets] objectAtIndex: index] floatValue];

	NSArray * items=[_menu itemArray];
	NSMenuItem* item = [items objectAtIndex: index];

	NSAttributedString* aTitle = [item attributedTitle];
	// Fix up the cell height if needed
	if (aTitle != nil && [aTitle length] > 0) {
		NSSize size = [aTitle size];
		result.size.height = MAX(_cellSize.height, size.height);
	}
	
   return result;
}

-(NSRect)rectForSelectedItem {
   if(_pullsDown)
    return [self rectForItemAtIndex:0];
   else if(_selectedIndex==-1)
    return [self rectForItemAtIndex:0];
   else
    return [self rectForItemAtIndex:_selectedIndex];
}

-(void)drawItemAtIndex:(NSInteger)index {
   NSMenuItem   *item=[_menu itemAtIndex:index];
   NSDictionary *attributes;
   NSRect    itemRect=[self rectForItemAtIndex:index];

   if( [item isHidden] )
      return;

	[[NSColor controlBackgroundColor] setFill];
	NSRectFill(itemRect);

   if([item isSeparatorItem]){
		NSRect r = itemRect;
		r.origin.y += r.size.height / 2 - 1;
		r.size.height = 2;
		[[self graphicsStyle] drawMenuSeparatorInRect:r];
   }
   else {
	   
	   if(index==_selectedIndex && [item isEnabled]){
		   [[NSColor selectedTextBackgroundColor] setFill];
		   NSRectFill(itemRect);
	   }

	   // Accommodate indentation level
	   itemRect = NSOffsetRect(itemRect, [item indentationLevel] * 5, 0);

	   // Check for an Attributed title first
	   NSAttributedString* aTitle = [item attributedTitle];
	   if (aTitle != nil && [aTitle length] > 0) {
		   itemRect=NSInsetRect(itemRect,2,2);
			[aTitle _clipAndDrawInRect: itemRect];
	   } else {
		   if(index==_selectedIndex && [item isEnabled]) {
			   attributes=[self selectedItemAttributes];
		   } else if ([item isEnabled] == NO) {
			   attributes = [self disabledItemAttributes];
		   } else {
			   attributes=[self itemAttributes];
		   }
		   NSString *string=[item title];
		   NSSize    size=[string sizeWithAttributes:attributes];
		   
		   itemRect=NSInsetRect(itemRect,2,2);
		   itemRect.origin.y+=floor((_cellSize.height-size.height)/2);
		   itemRect.size.height=size.height;
		   
		   [string _clipAndDrawInRect:itemRect withAttributes:attributes];
	   }
   }
}

/*
 * Returns NSNotFound if the point is outside of the menu
 * Returns -1 if the point is inside the menu but on a disabled or separator item
 * Returns a usable index if the point is on a selectable item
 */
-(NSInteger)itemIndexForPoint:(NSPoint)point {
	NSInteger result;
	NSArray * items=[_menu itemArray];
	int i, count = [items count];
	
	point.y-=2;
	
	if( point.y < 0 ) {
		return NSNotFound;
	}
	
	for( i = 0; i < count; i++ )
	{
		if( [[items objectAtIndex: i] isHidden ] )
			continue;
		
		NSRect itemRect = [self rectForItemAtIndex: i];
		if (NSPointInRect( point, itemRect)) {
			if (([[items objectAtIndex: i] isEnabled] == NO) ||
				([[items objectAtIndex: i] isSeparatorItem])) {
				return -1;
			}
			return i;
		}
	}
	return NSNotFound;
}


-(void)drawRect:(NSRect)rect {
   NSArray      *items=[_menu itemArray];
   int           i,count=[items count];

   [[self graphicsStyle] drawPopUpButtonWindowBackgroundInRect: rect];

   for(i=0;i<count;i++){
	   NSRect itemRect = [self rectForItemAtIndex: i];
	   if (NSIntersectsRect(rect, itemRect)) {
		   [self drawItemAtIndex:i];
	   }
   }
}

-(void)rightMouseDown:(NSEvent *)event {
   // do nothing
}

/*
 * This method may return NSNotFound when the view positioned outside the initial tracking area due to preferredEdge settings and the user clicks the mouse.
 * The NSPopUpButtonCell code deals with it. It might make sense for this to return the previous value.
 */
-(int)runTrackingWithEvent:(NSEvent *)event {
	enum {
    STATE_FIRSTMOUSEDOWN,
    STATE_MOUSEDOWN,
    STATE_MOUSEUP,
    STATE_EXIT
   } state=STATE_FIRSTMOUSEDOWN;
   NSPoint firstLocation,point=[event locationInWindow];
   NSInteger initialSelectedIndex = _selectedIndex;

   // Make sure we get mouse moved events, too, so we can respond apporpiately to
   // click-click actions as well as of click-and-drag
   BOOL oldAcceptsMouseMovedEvents = [[self window] acceptsMouseMovedEvents];
   [[self window] setAcceptsMouseMovedEvents:YES];

// point comes in on controls window
   point=[[event window] convertBaseToScreen:point];
   point=[[self window] convertScreenToBase:point];
   point=[self convertPoint:point fromView:nil];
   firstLocation=point;

	// Make sure we know if the user clicks away from the app in the middle of this
	BOOL cancelled = NO;	
	
   do {
    NSInteger index=[self itemIndexForPoint:point];
    NSRect   screenVisible;

/*
  If the popup is activated programmatically with performClick: index may be NSNotFound because the mouse starts out
  outside the view. We don't change _selectedIndex in this case.   
 */
    if(index!= NSNotFound && _keyboardUIState == KEYBOARD_INACTIVE){
     if(_selectedIndex!=index){
      NSInteger previous=_selectedIndex;
		 if (previous != -1) {
			 NSRect itemRect = [self rectForItemAtIndex: previous];
			 [self setNeedsDisplayInRect: itemRect];
		 }
      _selectedIndex=index;
		 if (_selectedIndex != -1) {
			 NSRect itemRect = [self rectForItemAtIndex: _selectedIndex];
			 [self setNeedsDisplayInRect: itemRect];
		 }
     }
    }
    
    [[self window] flushWindow];

    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSMouseMovedMask|NSLeftMouseDraggedMask|NSKeyDownMask|NSAppKitDefinedMask];
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
 
	   if ([event type] == NSAppKitDefined) {
		   if ([event subtype] == NSApplicationDeactivated) {
			   cancelled = YES;
		   }
	   }
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
    } else {
		_selectedIndex == -1;
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
			if([event type]==NSLeftMouseUp) {
				// If the user clicked outside of the window - then they want
				// to dismiss it without changing anything
				NSPoint winPoint=[event locationInWindow];
				winPoint=[[event window] convertBaseToScreen:winPoint];
				if (NSPointInRect(winPoint,[[self window] frame]) == NO) {
					_selectedIndex = -1;
				}
				state=STATE_EXIT;
			}
      break;
    }

   }while(cancelled == NO && state!=STATE_EXIT);

   [[self window] setAcceptsMouseMovedEvents: oldAcceptsMouseMovedEvents];

   _keyboardUIState = KEYBOARD_INACTIVE;
   
	return (_selectedIndex == -1) ? NSNotFound : _selectedIndex;
}

- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)moveUp:(id)sender {
    NSInteger previous = _selectedIndex;

	// Find the previous visible item
	NSArray *items = [_menu itemArray];
	if( _selectedIndex == -1 )
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
    NSInteger previous = _selectedIndex;
    
	// Find the next visible item
	NSArray *items = [_menu itemArray];
	NSInteger searchIndex = _selectedIndex;
		
	do
	{
		searchIndex++;
	} while( searchIndex < [items count] && ( [[items objectAtIndex: searchIndex] isHidden] ||
									             [[items objectAtIndex: searchIndex] isSeparatorItem] )  );

	if (searchIndex >= [items count]) {
        _selectedIndex = previous;
	}
	
    [self setNeedsDisplay:YES];
}

- (void)cancel:(id)sender {
    _keyboardUIState = KEYBOARD_CANCEL;
}

- (void)insertNewline:(id)sender {
    _keyboardUIState = KEYBOARD_OK;
}

@end
