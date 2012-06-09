/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSMenuView.h>
#import <AppKit/NSMenuWindow.h>
#import <AppKit/NSRaise.h>

@implementation NSMenuView

-(void)dealloc
{
   [_visibleArray release];
   [super dealloc];
}

-(unsigned)itemIndexAtPoint:(NSPoint)point {
   NSInvalidAbstractInvocation();
   return NSNotFound;
}

-(unsigned)selectedItemIndex {
   return _selectedItemIndex;
}

-(void)setSelectedItemIndex:(unsigned)itemIndex {
	if (_selectedItemIndex != itemIndex) {
		_selectedItemIndex=itemIndex;
		[self setNeedsDisplay:YES];
	}
}

-(NSArray *)itemArray {
   return [[self menu] itemArray];
}

-(NSArray *)visibleItemArray
{
   NSArray * items = [[self menu] itemArray];
   
   // Construct a new array of just the visible items
   if( _visibleArray == NULL )
      _visibleArray = [[NSMutableArray init] alloc];
	
   [_visibleArray removeAllObjects];
   
   int i;
   for( i = 0; i < [items count]; i++ )
   {
      NSMenuItem *item = [items objectAtIndex: i];
	  if( ![item isHidden] )
	     [_visibleArray addObject: item];
   }
   
   return _visibleArray;
}

-(NSMenuItem *)itemAtSelectedIndex {
   NSArray *items=[self visibleItemArray];

   if(_selectedItemIndex<[items count])
    return [items objectAtIndex:_selectedItemIndex];

   return nil;
}

-(NSMenuView *)viewAtSelectedIndexPositionOnScreen:(NSScreen *)screen {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)rightMouseDown:(NSEvent *)event {
   // do nothing
}

-(NSScreen *)_screenForPoint:(NSPoint)point {
   NSArray *screens=[NSScreen screens];
   int      i,count=[screens count];

   for(i=0;i<count;i++){
    NSScreen *check=[screens objectAtIndex:i];

    if(NSPointInRect(point,[check frame]))
     return check;
   }

   return [screens objectAtIndex:0];// should not happen
}

-(NSMenuItem *)trackForEvent:(NSEvent *)event {
   NSMenuItem *item=nil;

   enum {
    STATE_FIRSTMOUSEDOWN,
    STATE_MOUSEDOWN,
    STATE_MOUSEUP,
    STATE_EXIT
   } state=STATE_FIRSTMOUSEDOWN;
   NSPoint point=[event locationInWindow];
   NSPoint firstPoint=point;
	NSTimeInterval firstTimestamp = [event timestamp];
   NSMutableArray *viewStack=[NSMutableArray array];
   BOOL oldAcceptsMouseMovedEvents = [[self window] acceptsMouseMovedEvents];
   [[self window] setAcceptsMouseMovedEvents:YES];

   [[self menu] update];

   [viewStack addObject:self];

   [event retain];
	
	BOOL cancelled = NO;
   do {
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    int                count=[viewStack count];
    NSScreen          *screen=[self _screenForPoint:[[event window] convertBaseToScreen:point]];

    point=[[event window] convertBaseToScreen:point];
    if(count==1)
     screen=[self _screenForPoint:point];

    while(--count>=0){
     NSMenuView *checkView=[viewStack objectAtIndex:count];
     NSPoint     checkPoint=[[checkView window] convertScreenToBase:point];

     checkPoint=[checkView convertPoint:checkPoint fromView:nil];

     if(NSMouseInRect(checkPoint,[checkView bounds],[checkView isFlipped])){
      unsigned itemIndex=[checkView itemIndexAtPoint:checkPoint];
		 
      if(itemIndex!=[checkView selectedItemIndex]){
       NSMenuView *branch;

       while(count+1<[viewStack count]){
        [[(NSView *)[viewStack lastObject] window] close];
        [viewStack removeLastObject];
       }
       [checkView setSelectedItemIndex:itemIndex];

       if((branch=[checkView viewAtSelectedIndexPositionOnScreen:screen])!=nil)
		   [viewStack addObject:branch];
	  }
      break;
	 } else {
		 if (checkView == [viewStack lastObject]) {
			 // The mouse is outside of the top menu - be sure no item is selected anymore
			 [checkView setSelectedItemIndex:NSNotFound];
		 }
	 }
	}

    if(count<0){
     [[viewStack lastObject] setSelectedItemIndex:NSNotFound];
    }

    [event release];
    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSMouseMovedMask|NSLeftMouseDraggedMask|NSAppKitDefinedMask];
    [event retain];
	   // We use this special AppKitDefined event to let the menu respond to the app deactivation - it *has*
	   // to be passed through the event system, unfortunately
	   if ([event type] == NSAppKitDefined) {
		   if ([event subtype] == NSApplicationDeactivated) {
			   cancelled = YES;
		   }
	   }
	   
	if (cancelled == NO && [event type] != NSAppKitDefined) {
		   
    point=[event locationInWindow];
	// Don't test for "== 0." - we tend to receive some delta with some .000000... values while the mouse doesn't move
	BOOL mouseMoved = ([event type] != NSAppKitDefined) && (fabs([event deltaX]) > .001 || fabs([event deltaY]) > .001);
    switch(state){
		case STATE_FIRSTMOUSEDOWN:
			item=[[viewStack lastObject] itemAtSelectedIndex];
			
			if([event type]==NSLeftMouseUp) {
				// The menu is really active after a mouse up (which means the menu will stay sticky)...
				if ([event timestamp] - firstTimestamp > .05 && [viewStack count]==1 && [item isEnabled] && ![item hasSubmenu]) {
					state=STATE_EXIT;
				} else {
					state=STATE_MOUSEUP;
				}
			} else if([event type]==NSLeftMouseDown || mouseMoved) {
				// .. Or a mouse down (second click after the sticky menu) or a real move
				state=STATE_MOUSEDOWN;
			}
			break;
			
		default:
			item=[[viewStack lastObject] itemAtSelectedIndex];
			if([event type]==NSLeftMouseUp){
				if(item == nil || ([viewStack count]<=2) || ([item isEnabled] && ![item hasSubmenu]))
					state=STATE_EXIT;
			}
			break;
    }
	   }
    [pool release];
   }while(cancelled == NO && state!=STATE_EXIT);
   [event release];

   if([viewStack count]>0)
    item=[[viewStack lastObject] itemAtSelectedIndex];

   while([viewStack count]>1){
    [[(NSView *)[viewStack lastObject] window] close];
    [viewStack removeLastObject];
   }
   [viewStack removeLastObject];

   _selectedItemIndex=NSNotFound;
   [[self window] setAcceptsMouseMovedEvents:oldAcceptsMouseMovedEvents];
   [self setNeedsDisplay:YES];

   return ([item isEnabled] && ![item hasSubmenu])?item:(NSMenuItem *)nil;
}

-(void)mouseDown:(NSEvent *)event {
   BOOL        didAccept=[[self window] acceptsMouseMovedEvents];
   NSMenuItem *item;

   [[self window] setAcceptsMouseMovedEvents:YES];
   item=[self trackForEvent:event];
   [[self window] setAcceptsMouseMovedEvents:didAccept];
   
   if(item!=nil)
    [NSApp sendAction:[item action] to:[item target] from:item];
}

@end
