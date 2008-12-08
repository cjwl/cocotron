/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSView.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSTrackingRect.h>
#import <AppKit/NSCursorRect.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSDraggingManager.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSObject+BindingSupport.h>
#import <Foundation/NSRaise.h>

NSString *NSViewFrameDidChangeNotification=@"NSViewFrameDidChangeNotification";
NSString *NSViewBoundsDidChangeNotification=@"NSViewBoundsDidChangeNotification";
NSString *NSViewFocusDidChangeNotification=@"NSViewFocusDidChangeNotification";

@interface NSView(NSView_forward)
-(CGAffineTransform)transformFromWindow;
-(CGAffineTransform)transformToWindow;
@end

@implementation NSView

+(NSView *)focusView {
   return [NSCurrentFocusStack() lastObject];
}

+(NSMenu *)defaultMenu {
   return nil;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned           vFlags=[keyed decodeIntForKey:@"NSvFlags"];
    
    _frame=NSZeroRect;
    if([keyed containsValueForKey:@"NSFrame"])
     _frame=[keyed decodeRectForKey:@"NSFrame"];
    else if([keyed containsValueForKey:@"NSFrameSize"])
     _frame.size=[keyed decodeSizeForKey:@"NSFrameSize"];
    
    _bounds.origin=NSMakePoint(0,0);
    _bounds.size=_frame.size;
    _window=nil;
    _superview=nil;
    _subviews=[NSMutableArray new];
    _postsNotificationOnFrameChange=YES;
    _postsNotificationOnBoundsChange=YES;
    _autoresizesSubviews=YES;
    _autoresizingMask=vFlags&0x3F;
    _tag=-1;
    if([keyed containsValueForKey:@"NSTag"])
     _tag=[keyed decodeIntForKey:@"NSTag"];
    [_subviews addObjectsFromArray:[keyed decodeObjectForKey:@"NSSubviews"]];
    [_subviews makeObjectsPerformSelector:@selector(_setSuperview:) withObject:self];
    _invalidRect=_bounds;
    _defaultToolTipTag=-1;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }

   return self;
}

-init {
   return [self initWithFrame:NSMakeRect(0,0,1,1)];
}

-initWithFrame:(NSRect)frame {
   _frame=frame;
   _bounds.origin=NSMakePoint(0,0);
   _bounds.size=frame.size;
   _window=nil;
   _menu=nil;
   _superview=nil;
   _subviews=[NSMutableArray new];
   _postsNotificationOnFrameChange=YES;
   _postsNotificationOnBoundsChange=YES;
   _autoresizesSubviews=YES;
   _autoresizingMask=NSViewNotSizable;
   _tag=-1;
   _invalidRect=_bounds;
   _defaultToolTipTag=-1;

   _validTransforms=NO;
   _transformFromWindow=CGAffineTransformIdentity;
   _transformToWindow=CGAffineTransformIdentity;

   return self;
}

-(void)dealloc {
   _window=nil;
   [_menu release];

   _superview=nil;
   [_subviews makeObjectsPerformSelector:@selector(_setSuperview:) withObject:nil];

   [_subviews release];
   [_draggedTypes release];
	[self _unbindAllBindings];

   [super dealloc];
}

-(void)invalidateTransform {
   _validTransforms=NO;
   [_subviews makeObjectsPerformSelector:_cmd];
   [[self window] invalidateCursorRectsForView:self];
}

-(CGAffineTransform)createTransformToWindow {
   CGAffineTransform result;
   NSRect            bounds=[self bounds];
   NSRect            frame=[self frame];

   if([self superview]==nil)
    result=CGAffineTransformIdentity;
   else
    result=[[self superview] transformToWindow];

   result=CGAffineTransformTranslate(result,frame.origin.x,frame.origin.y);

   if([self isFlipped]!=[[self superview] isFlipped]){
    CGAffineTransform flip=CGAffineTransformMake(1,0,0,-1,0,bounds.size.height);

    result=CGAffineTransformConcat(flip,result);
   }
   result=CGAffineTransformTranslate(result,-bounds.origin.x,-bounds.origin.y);

   return result;
}

-(NSRect)calculateVisibleRect {
   if([self superview]==nil)
    return [self bounds];
   else {
    NSRect result=[[self superview] visibleRect];

    result=[self convertRect:result fromView:[self superview]];

    result=NSIntersectionRect(result,[self bounds]);

    return result;
   }
}

static inline void buildTransformsIfNeeded(NSView *self) {
   if(!self->_validTransforms){
    self->_transformToWindow=[self createTransformToWindow];
    self->_transformFromWindow=CGAffineTransformInvert(self->_transformToWindow);
    self->_validTransforms=YES;

    self->_visibleRect=[self calculateVisibleRect];
   }
}

-(CGAffineTransform)transformFromWindow {
   buildTransformsIfNeeded(self);

   return _transformFromWindow;
}

-(CGAffineTransform)transformToWindow {
   buildTransformsIfNeeded(self);

   return _transformToWindow;
}


-(NSRect)frame {
   return _frame;
}

-(NSRect)bounds {
   return _bounds;
}

-(BOOL)postsFrameChangedNotifications {
   return _postsNotificationOnFrameChange;
}

-(BOOL)postsBoundsChangedNotifications {
   return _postsNotificationOnBoundsChange;
}

-(NSWindow *)window {
   return _window;
}

-superview {
   return _superview;
}

-(BOOL)isDescendantOf:(NSView *)other {
   NSView *check=self;
   
   do {
    if(check==other)
     return YES;
     
    check=[check superview];
   }while(check!=nil);
   
   return NO;
}

-(NSScrollView *)enclosingScrollView {
   id result=[self superview];

   for(;result!=nil;result=[result superview])
    if([result isKindOfClass:[NSScrollView class]])
     return result;

   return nil;
}

-(NSArray *)subviews {
   return [[_subviews copy] autorelease];
}

-(BOOL)autoresizesSubviews {
   return _autoresizesSubviews;
}

-(unsigned)autoresizingMask {
   return _autoresizingMask;
}

-(int)tag {
   return _tag;
}

-(BOOL)isFlipped {
   return NO;
}

-(BOOL)isOpaque {
   return NO;
}

-(int)gState {
   return 0;
}

-(NSRect)visibleRect {
   buildTransformsIfNeeded(self);

   return _visibleRect;
}

-(BOOL)isHidden {
   return _isHidden;
}

-(void)setHidden:(BOOL)flag {
   _isHidden=flag;
   if(_isHidden)
    NSUnimplementedMethod();
}

-(NSView *)nextKeyView {
   return _nextKeyView;
}

-(NSView *)nextValidKeyView {
   NSView *result=[self nextKeyView];

   while(result!=nil && ![result acceptsFirstResponder])
    result=[result nextKeyView];

   return result;
}

-(NSView *)previousKeyView {
   return _previousKeyView;
}

-(NSView *)previousValidKeyView {
   NSView *result=[self previousKeyView];

   while(result!=nil && ![result acceptsFirstResponder])
    result=[result previousKeyView];

   return result;
}

-(NSMenu *)menu {
   return _menu;
}

-(NSMenu *)menuForEvent:(NSEvent *)event {
   NSMenu *result=[self menu];
   
   if(result==nil) {
    result=[isa defaultMenu];

    if(result) {
     NSArray *itemArray=[result itemArray];
     int i,count=[itemArray count];
     for(i=0;i<count;i++) {
      NSMenuItem *item = [itemArray objectAtIndex:i];
      [item setTarget:self];
     }
    }
   }

   return result;
}

- (NSString *)toolTip
{
    return _toolTip;
}

-viewWithTag:(int)tag {
   int i,count=[_subviews count];

   if(_tag==tag)
    return self;

   for(i=0;i<count;i++){
    NSView *view=[[_subviews objectAtIndex:i] viewWithTag:tag];

    if(view!=nil)
     return view;
   }

   return nil;
}

-(NSView *)hitTest:(NSPoint)point {
   point=[self convertPoint:point fromView:[self superview]];

   if(!NSMouseInRect(point,[self visibleRect],[self isFlipped]))
    return nil;
   else {
    NSArray *subviews=[self subviews];
    int      count=[subviews count];

    while(--count>=0){ // front to back
     NSView *check=[subviews objectAtIndex:count];
     NSView *hit=[check hitTest:point];

     if(hit!=nil)
      return hit;
    }
    return self;
   }
}


-(NSPoint)convertPoint:(NSPoint)point fromView:(NSView *)viewOrNil {
   NSView           *fromView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[fromView transformToWindow];
   CGAffineTransform fromWindow=[self transformFromWindow];

   return CGPointApplyAffineTransform(CGPointApplyAffineTransform(point,toWindow),fromWindow);
}

-(NSPoint)convertPoint:(NSPoint)point toView:(NSView *)viewOrNil {
   NSView           *toView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[self transformToWindow];
   CGAffineTransform fromWindow=[toView transformFromWindow];

   return CGPointApplyAffineTransform(CGPointApplyAffineTransform(point,toWindow),fromWindow);
}

-(NSSize)convertSize:(NSSize)size fromView:(NSView *)viewOrNil {
   NSView           *fromView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[fromView transformToWindow];
   CGAffineTransform fromWindow=[self transformFromWindow];

   return CGSizeApplyAffineTransform(CGSizeApplyAffineTransform(size,toWindow),fromWindow);
}

-(NSSize)convertSize:(NSSize)size toView:(NSView *)viewOrNil {
   NSView           *toView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[self transformToWindow];
   CGAffineTransform fromWindow=[toView transformFromWindow];

   return CGSizeApplyAffineTransform(CGSizeApplyAffineTransform(size,toWindow),fromWindow);
}

-(NSRect)convertRect:(NSRect)rect fromView:(NSView *)viewOrNil {
   NSView           *fromView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[fromView transformToWindow];
   CGAffineTransform fromWindow=[self transformFromWindow];
   NSPoint           point1=rect.origin;
   NSPoint           point2=NSMakePoint(NSMaxX(rect),NSMaxY(rect));

   point1= CGPointApplyAffineTransform(CGPointApplyAffineTransform(point1,toWindow),fromWindow);
   point2= CGPointApplyAffineTransform(CGPointApplyAffineTransform(point2,toWindow),fromWindow);
   if(point2.y<point1.y){
    float temp=point2.y;
    point2.y=point1.y;
    point1.y=temp;
   }

   return NSMakeRect(point1.x,point1.y,point2.x-point1.x,point2.y-point1.y);
}

-(NSRect)convertRect:(NSRect)rect toView:(NSView *)viewOrNil {
   NSView           *toView=(viewOrNil!=nil)?viewOrNil:[[self window] _backgroundView];
   CGAffineTransform toWindow=[self transformToWindow];
   CGAffineTransform fromWindow=[toView transformFromWindow];
   NSPoint           point1=rect.origin;
   NSPoint           point2=NSMakePoint(NSMaxX(rect),NSMaxY(rect));

   point1= CGPointApplyAffineTransform(CGPointApplyAffineTransform(point1,toWindow),fromWindow);
   point2= CGPointApplyAffineTransform(CGPointApplyAffineTransform(point2,toWindow),fromWindow);
   if(point2.y<point1.y){
    float temp=point2.y;
    point2.y=point1.y;
    point1.y=temp;
   }

   return NSMakeRect(point1.x,point1.y,point2.x-point1.x,point2.y-point1.y);
}

-(NSRect)centerScanRect:(NSRect)rect {
   float minx=floor(NSMinX(rect)+0.5);
   float miny=floor(NSMinY(rect)+0.5);
   float maxx=floor(NSMaxX(rect)+0.5);
   float maxy=floor(NSMaxY(rect)+0.5);

   return NSMakeRect(minx,miny,maxx-minx,maxy-miny);
}


-(void)setFrame:(NSRect)frame {
   NSSize oldSize=_bounds.size;

   [self invalidateTransform];

   _frame=frame;
   _bounds.size=frame.size;
   if(_autoresizesSubviews)
    [self resizeSubviewsWithOldSize:oldSize];

   if(_postsNotificationOnFrameChange)
    [[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:self];
}

-(void)setFrameSize:(NSSize)size {
   NSRect frame=_frame;

   frame.size=size;
   [self setFrame:frame];
}

-(void)setFrameOrigin:(NSPoint)origin {
   NSRect frame=[self frame];

   frame.origin=origin;
   [self setFrame:frame];
}

-(void)setBounds:(NSRect)bounds {
    _bounds=bounds;
    [self invalidateTransform];

   if(_postsNotificationOnBoundsChange)
    [[NSNotificationCenter defaultCenter] postNotificationName:NSViewBoundsDidChangeNotification object:self];
}

-(void)setBoundsSize:(NSSize)size {
   NSRect bounds=[self bounds];

   bounds.size=size;

   [self setBounds:bounds];
}

-(void)setBoundsOrigin:(NSPoint)origin {
   NSRect bounds=[self bounds];

   bounds.origin=origin;

   [self setBounds:bounds];
}

-(void)setPostsFrameChangedNotifications:(BOOL)flag {
   _postsNotificationOnFrameChange=flag;
}

-(void)setPostsBoundsChangedNotifications:(BOOL)flag {
   _postsNotificationOnBoundsChange=flag;
}

-(void)_setWindow:(NSWindow *)window {
   if([_window firstResponder]==self)
    [_window makeFirstResponder:nil];

   [self viewWillMoveToWindow:window];

   _window=window;
   [_subviews makeObjectsPerformSelector:_cmd withObject:window];
}

-(void)_setSuperview:superview {
   _superview=superview;
   [self setNextResponder:superview];
}

-(void)_setupToolTipRectIfNeeded {
    if(_window != nil && [self toolTip] != nil) {
        if (_defaultToolTipTag > 0)
            [self removeToolTip:_defaultToolTipTag];
        
        _defaultToolTipTag = [self addToolTipRect:[self bounds] owner:self userData:nil];
    }
}

-(void)_insertSubview:(NSView *)view atIndex:(unsigned)index {

   [view retain];
    if([view superview]==self)
     [_subviews removeObjectIdenticalTo:view];
    else{
     [view removeFromSuperview];

     [view _setWindow:_window];

     [view viewWillMoveToSuperview:self];
     [view _setSuperview:self];
    }

    if(index==NSNotFound)
     [_subviews addObject:view];
    else
     [_subviews insertObject:view atIndex:index];
   [view release];

   [self invalidateTransform]; // subview may affect transform (e.g. clipview)

   [view _setupToolTipRectIfNeeded];
   [self setNeedsDisplay:YES];
}

-(void)addSubview:(NSView *)view {
   [self _insertSubview:view atIndex:NSNotFound];
}

-(void)addSubview:(NSView *)view positioned:(NSWindowOrderingMode)ordering relativeTo:(NSView *)relativeTo {
   unsigned index=[_subviews indexOfObjectIdenticalTo:relativeTo];
   
   if(index==NSNotFound)
    index=(ordering==NSWindowBelow)?0:NSNotFound;
   else
    index=(ordering==NSWindowBelow)?index:((index+1==[_subviews count])?NSNotFound:index+1);
    
   [self _insertSubview:view atIndex:index];
}

-(void)replaceSubview:(NSView *)oldView with:(NSView *)newView {
   unsigned index=[_subviews indexOfObjectIdenticalTo:oldView];

   [oldView removeFromSuperview];
   [self _insertSubview:newView atIndex:index];
}

-(void)setAutoresizesSubviews:(BOOL)flag {
   _autoresizesSubviews=flag;
}

-(void)setAutoresizingMask:(unsigned int)mask {
   _autoresizingMask=mask;
}

-(void)setTag:(int)tag {
   _tag=tag;
}

-(void)_setPreviousKeyView:(NSView *)previous {
   _previousKeyView=previous;
}

-(void)setNextKeyView:(NSView *)next {
   _nextKeyView=next;
   [_nextKeyView _setPreviousKeyView:self];
}

- (void)setToolTip:(NSString *)string
{
    [_toolTip release];
    _toolTip = [string retain];
    
    [self _setupToolTipRectIfNeeded];
}

- (NSToolTipTag)addToolTipRect:(NSRect)rect owner:object userData:(void *)userData
{
    if ([self window] == nil)
        [NSException raise:NSInvalidArgumentException format:@"%@ cannot add tool tip rect before view is added to view hierarchy", NSStringFromSelector(_cmd)];
    
    rect=[self convertRect:rect toView:nil];
    return [[self window] _addTrackingRect:rect view:self flipped:[self isFlipped] owner:object userData:userData assumeInside:NO isToolTip:YES];
}

- (void)removeToolTip:(NSToolTipTag)tag
{
    [self removeTrackingRect:tag];
}

- (void)removeAllToolTips
{
    [[self window] _removeAllToolTips];
}

-(void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor {
   rect=[self convertRect:rect toView:nil];
   [[self window] _addCursorRect:rect cursor:cursor view:self];
}

-(void)removeCursorRect:(NSRect)rect cursor:(NSCursor *)cursor {
   rect=[self convertRect:rect toView:nil];
   [[self window] _removeCursorRect:rect cursor:cursor view:self];
}

-(void)discardCursorRects {
   [[self window] _discardCursorRectsForView:self];

   [[self subviews] makeObjectsPerformSelector:_cmd];
}

-(void)resetCursorRects {
   // do nothing
}

-(NSTrackingRectTag)addTrackingRect:(NSRect)rect owner:owner userData:(void *)userData assumeInside:(BOOL)assumeInside {
   rect=[self convertRect:rect toView:nil];

   return [[self window] _addTrackingRect:rect view:self flipped:[self isFlipped] owner:owner userData:userData assumeInside:assumeInside isToolTip:NO];
}

-(void)removeTrackingRect:(NSTrackingRectTag)tag {
   [[self window] _removeTrackingRect:tag];
}

-(void)registerForDraggedTypes:(NSArray *)types {
   _draggedTypes=[types copy];
}

-(void)unregisterDraggedTypes {
   [_draggedTypes release];
   _draggedTypes=nil;
}

-(void)removeView:(NSView *)view  {
   [_subviews removeObjectIdenticalTo:view];

   [self setNeedsDisplay:YES];
}

-(void)removeFromSuperview {
   NSView *removeFrom=_superview;

   [self discardCursorRects];
   [[self window] _discardTrackingRectsForView:self toolTipsOnly:YES];

   [self _setSuperview:nil];
   [self _setWindow:nil];

   [removeFrom removeView:self];
}

-(void)removeViewWithoutDisplay:(NSView *)view  {
   [_subviews removeObjectIdenticalTo:view];
}

-(void)removeFromSuperviewWithoutNeedingDisplay {
   NSView *removeFrom=_superview;

   [self discardCursorRects];
   [[self window] _discardTrackingRectsForView:self toolTipsOnly:YES];

   [self _setSuperview:nil];
   [self _setWindow:nil];

   [removeFrom removeViewWithoutDisplay:self];
}

-(void)viewWillMoveToWindow:(NSWindow *)window {

}

-(void)viewWillMoveToSuperview:(NSView *)view {
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize {
   int i,count=[_subviews count];

   for(i=0;i<count;i++)
    [[_subviews objectAtIndex:i] resizeWithOldSuperviewSize:oldSize];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize {
   NSRect superFrame=[_superview frame];
   NSRect frame=[self frame];
   BOOL   originChanged=NO,sizeChanged=NO;

   if(_autoresizingMask&NSViewMinXMargin){
    if(_autoresizingMask&NSViewWidthSizable){
     if(_autoresizingMask&NSViewMaxXMargin){
      frame.origin.x+=((superFrame.size.width-oldSize.width)/3);
      frame.size.width+=((superFrame.size.width-oldSize.width)/3);
     }
     else {
      frame.origin.x+=((superFrame.size.width-oldSize.width)/2);
      frame.size.width+=((superFrame.size.width-oldSize.width)/2);
     }
     originChanged=YES;
     sizeChanged=YES;
    }
    else if(_autoresizingMask&NSViewMaxXMargin){
     frame.origin.x+=((superFrame.size.width-oldSize.width)/2);
     originChanged=YES;
    }
    else{
     frame.origin.x+=superFrame.size.width-oldSize.width;
     originChanged=YES;
    }
   }
   else if(_autoresizingMask&NSViewWidthSizable){
    if(_autoresizingMask&NSViewMaxXMargin)
     frame.size.width+=((superFrame.size.width-oldSize.width)/2);
    else
     frame.size.width+=superFrame.size.width-oldSize.width;
    sizeChanged=YES;
   }
   else if(_autoresizingMask&NSViewMaxXMargin){
    // don't move or resize
   }


   if(_autoresizingMask& NSViewMinYMargin){
    if(_autoresizingMask& NSViewHeightSizable){
     if(_autoresizingMask& NSViewMaxYMargin){
      frame.origin.y+=((superFrame.size.height-oldSize.height)/3);
      frame.size.height+=((superFrame.size.height-oldSize.height)/3);
     }
     else {
      frame.origin.y+=((superFrame.size.height-oldSize.height)/2);
      frame.size.height+=((superFrame.size.height-oldSize.height)/2);
     }
     originChanged=YES;
     sizeChanged=YES;
    }
    else if(_autoresizingMask& NSViewMaxYMargin){
     frame.origin.y+=((superFrame.size.height-oldSize.height)/2);
     originChanged=YES;
    }
    else {
     frame.origin.y+=superFrame.size.height-oldSize.height;
     originChanged=YES;
    }
   }
   else if(_autoresizingMask&NSViewHeightSizable){
    if(_autoresizingMask& NSViewMaxYMargin)
     frame.size.height+=((superFrame.size.height-oldSize.height)/2);
    else
     frame.size.height+=superFrame.size.height-oldSize.height;
    sizeChanged=YES;
   }

   if(originChanged || sizeChanged)
    [self setFrame:frame];
}

-(BOOL)inLiveResize {
   return _inLiveResize;
}

-(void)viewWillStartLiveResize {
   _inLiveResize=YES;
   [self setNeedsDisplay:YES];
   [_subviews makeObjectsPerformSelector:_cmd];
}

-(void)viewDidEndLiveResize {
   _inLiveResize=NO;
   [self setNeedsDisplay:YES];
   [_subviews makeObjectsPerformSelector:_cmd];
}

-(NSClipView *)_enclosingClipView {
   id result=[self superview];

   for(;result!=nil;result=[result superview])
    if([result isKindOfClass:[NSClipView class]])
     return result;

   return nil;
}

-(void)scrollPoint:(NSPoint)point {
   NSClipView *clipView=[self _enclosingClipView];

   if(clipView!=nil){
    NSPoint origin=[self convertPoint:point toView:clipView];

    [clipView scrollToPoint:origin];
   }
}

-(BOOL)scrollRectToVisible:(NSRect)rect {
    NSClipView *clipView=[self _enclosingClipView];
    NSRect      vRect=[self visibleRect];
    NSPoint     sPoint;

    if(NSPointInRect(rect.origin,vRect) && NSPointInRect(NSMakePoint(NSMaxX(rect),NSMaxY(rect)),vRect))
     return NO;

    if(!NSIntersectsRect(rect,vRect)){
     if(rect.size.height<vRect.size.height){
      float delta=vRect.size.height-rect.size.height;
 
      rect.origin.y-=delta/2;
      rect.size.height+=delta;     
     }
     else {
      float delta=rect.size.height-vRect.size.height;

      rect.origin.y+=delta/2;
      rect.size.height-=delta;
     }

#if 0 // this doesn't work well for NSOutlineView, probably a bug in NSOutlineView
     if(rect.size.width<vRect.size.width){
      float delta=vRect.size.width-rect.size.width;

      rect.origin.x-=delta/2;
      rect.size.width+=delta;
     }
     else {
      float delta=rect.size.width-vRect.size.width;

      rect.origin.x+=delta/2;
      rect.size.width-=delta;
     }
#endif
    }

    rect=NSIntersectionRect(rect,[self bounds]); // necessary

    if(clipView!=nil && !NSIsEmptyRect(vRect)) {
     if(NSMinX(rect)<=NSMinX(vRect))
      sPoint.x=NSMinX(rect);
     else if(NSMaxX(rect)>NSMaxX(vRect))
      sPoint.x=NSMinX(vRect)+(NSMaxX(rect)-NSMaxX(vRect));
     else
      sPoint.x=NSMinX(vRect);

     if(NSMinY(rect)<=NSMinY(vRect))
      sPoint.y=NSMinY(rect);
     else if(NSMaxY(rect)>NSMaxY(vRect))
      sPoint.y=NSMinY(vRect)+(NSMaxY(rect)-NSMaxY(vRect));
     else
      sPoint.y=NSMinY(vRect);

     if(sPoint.x!=NSMinX(vRect) || sPoint.y!=NSMinY(vRect)){
      [clipView scrollToPoint:[self convertPoint:sPoint toView:clipView]];
      return YES;
     }
    }
    
    return NO;
}

-(BOOL)mouse:(NSPoint)point inRect:(NSRect)rect {
   return NSMouseInRect(point, rect, [self isFlipped]);
}

-(void)allocateGState {
   // unimplemented
}

-(void)releaseGState {
   // unimplemented
}

-(void)setUpGState {
   // do nothing
}

-(BOOL)needsDisplay {
   return !NSIsEmptyRect(_invalidRect);
}

-(void)setNeedsDisplayInRect:(NSRect)rect {
   if(NSIsEmptyRect(_invalidRect))
    _invalidRect=rect;
   else
    _invalidRect=NSUnionRect(_invalidRect,rect);
   [[self window] setViewsNeedDisplay:YES];
}

-(void)setNeedsDisplay:(BOOL)flag {
   [self setNeedsDisplayInRect:[self bounds]];
}

-(BOOL)canDraw {
   return (_window!=nil)?YES:NO;
}

-(void)lockFocus {
   NSGraphicsContext *context=[[self window] graphicsContext];
   CGContextRef       graphicsPort=[context graphicsPort];

   [NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:context];
   
   [NSCurrentFocusStack() addObject:self];

   CGContextSaveGState(graphicsPort);
   CGContextResetClip(graphicsPort);
   CGContextSetCTM(graphicsPort,[self transformToWindow]);
   CGContextClipToRect(graphicsPort,[self visibleRect]);

   [self setUpGState];
}

-(BOOL)lockFocusIfCanDraw {
   if([self canDraw]){
    [self lockFocus];
    return YES;
   }
   return NO;
}

-(void)unlockFocus {
   NSGraphicsContext *context=[[self window] graphicsContext];
   CGContextRef       graphicsPort=[context graphicsPort];

   CGContextRestoreGState(graphicsPort);
   [NSCurrentFocusStack() removeLastObject];
   [NSGraphicsContext restoreGraphicsState];
}

-(NSView *)opaqueAncestor {
   if([self isOpaque])
    return self;

   return [[self superview] opaqueAncestor];
}

-(void)display {
   [self displayRect:[self visibleRect]];
}

-(void)displayIfNeeded {
   if([self needsDisplay])
    [self display];
   else {
    int i,count=[_subviews count];

    for(i=0;i<count;i++) // back to front
     [[_subviews objectAtIndex:i] displayIfNeeded];
   }
}

-(void)displayIfNeededInRect:(NSRect)rect {
   if([self needsDisplay])
    [self displayRect:rect];
   else {
    int i,count=[_subviews count];

    for(i=0;i<count;i++){ // back to front
     NSView *child=[_subviews objectAtIndex:i];
     NSRect  converted=NSIntersectionRect([self convertRect:rect toView:child],[child bounds]);
   
     if(!NSIsEmptyRect(converted))
      [child displayIfNeededInRect:converted];
    }
   }
}

-(void)displayIfNeededInRectIgnoringOpacity:(NSRect)rect {
   if([self needsDisplay])
    [self displayRectIgnoringOpacity:rect];
   else {
    int i,count=[_subviews count];

    for(i=0;i<count;i++){ // back to front
     NSView *child=[_subviews objectAtIndex:i];
     NSRect  converted=NSIntersectionRect([self convertRect:rect toView:child],[child bounds]);
   
     if(!NSIsEmptyRect(converted))
      [child displayIfNeededInRectIgnoringOpacity:converted];
    }
   }
}

-(void)displayIfNeededIgnoringOpacity {
   if([self needsDisplay])
    [self displayRectIgnoringOpacity:[self bounds]];
   else {
    int i,count=[_subviews count];

    for(i=0;i<count;i++) // back to front
     [[_subviews objectAtIndex:i] displayIfNeededIgnoringOpacity];
   }
}

-(void)displayRect:(NSRect)rect {
   NSView *opaque=[self opaqueAncestor];

   if(opaque!=self)
    rect=[self convertRect:rect toView:opaque];

   [opaque displayRectIgnoringOpacity:rect];
}

-(void)displayRectIgnoringOpacity:(NSRect)rect {
   int i,count=[_subviews count];

   if(!NSIsEmptyRect(_invalidRect)){
    rect=NSUnionRect(rect,_invalidRect);
    _invalidRect=NSZeroRect;
   }

   rect=NSIntersectionRect(rect,[self visibleRect]);

   if([self canDraw]){
    [self lockFocus];
// rect should be expanded to completely cover all the non-opaque subviews invalid rects
// We may not completely erase the background of a non-opaque view
    [self drawRect:rect];

    for(i=0;i<count;i++){
     NSView *view=[_subviews objectAtIndex:i];
     NSRect  check=[self convertRect:rect toView:view];

     if(NSIntersectsRect(check,[view bounds])){
      check=NSIntersectionRect(check,[view visibleRect]);
      [view displayRectIgnoringOpacity:check];
     }
    }
    [self unlockFocus];
   }

// FIX, move this
   [[self window] flushWindow];
}

-(void)drawRect:(NSRect)rect {
   // do nothing
}

-(BOOL)autoscroll:(NSEvent *)event {
   return [[self superview] autoscroll:event];
}

-(void)scrollRect:(NSRect)rect by:(NSSize)delta {
   NSPoint point=rect.origin;

   point.x+=delta.width;
   point.y+=delta.height;

   if([self lockFocusIfCanDraw]){
    NSCopyBits([self gState],rect,point);
    [self unlockFocus];
   }
}

-(void)print:sender {
   [[NSPrintOperation printOperationWithView:self] runOperation];
}

-(void)beginDocument {
}

-(void)endDocument {
}

-(void)beginPageInRect:(NSRect)rect atPlacement:(NSPoint)placement {
   CGContextRef      graphicsPort=NSCurrentGraphicsPort();
   CGRect            mediaBox=NSMakeRect(0,0,rect.size.width,rect.size.height);
   NSPrintInfo      *printInfo=[[NSPrintOperation currentOperation] printInfo];
   NSRect            imageableRect=[printInfo imageablePageBounds];
   CGAffineTransform transform=CGAffineTransformIdentity;

   [NSCurrentFocusStack() addObject:self];

   CGContextBeginPage(graphicsPort,&mediaBox);
   CGContextSaveGState(graphicsPort);
   
   transform=CGAffineTransformTranslate(transform,imageableRect.origin.x,imageableRect.origin.y);
   if([self isFlipped]){
    CGAffineTransform flip={1,0,0,-1,0,imageableRect.size.height};
     
    transform=CGAffineTransformConcat(flip,transform);
   }

   transform=CGAffineTransformTranslate(transform,-rect.origin.x,-rect.origin.y);

   CGContextConcatCTM(graphicsPort,transform);

   [self setUpGState];
}

-(void)endPage {
   CGContextRef graphicsPort=NSCurrentGraphicsPort();

   CGContextRestoreGState(graphicsPort);
   CGContextEndPage(graphicsPort);
   [NSCurrentFocusStack() removeLastObject];
}

-(float)widthAdjustLimit {
   return 0.5;
}

-(float)heightAdjustLimit {
   return 0.5;
}

-(void)adjustPageWidthNew:(float *)adjusted left:(float)left right:(float)right limit:(float)limit {
// FIX, give subviews a chance
}

-(void)adjustPageHeightNew:(float *)adjust top:(float)top bottom:(float)bottom limit:(float)limit {
// FIX, give subviews a chance
}

-(BOOL)knowsPageRange:(NSRange *)range {
   return NO;
}

-(NSPoint)locationOfPrintRect:(NSRect)rect {
   return NSZeroPoint;
}

-(NSRect)rectForPage:(int)page {
   return NSZeroRect;
}

-(NSData *)dataWithEPSInsideRect:(NSRect)rect {
   NSMutableData    *result=[NSMutableData data];
   NSPrintOperation *operation=[NSPrintOperation EPSOperationWithView:self insideRect:rect toData:result];
   
   [operation runOperation];
   
   return result;
}

-(NSData *)dataWithPDFInsideRect:(NSRect)rect {
   NSMutableData    *result=[NSMutableData data];
   NSPrintOperation *operation=[NSPrintOperation PDFOperationWithView:self insideRect:rect toData:result];
   
   [operation runOperation];
   
   return result;
}

-(void)writeEPSInsideRect:(NSRect)rect toPasteboard:(NSPasteboard *)pasteboard {
   NSData *data=[self dataWithEPSInsideRect:rect];
   
   [pasteboard declareTypes:[NSArray arrayWithObject:NSPostScriptPboardType] owner:nil];
   [pasteboard setData:data forType:NSPostScriptPboardType];
}

-(void)writePDFInsideRect:(NSRect)rect toPasteboard:(NSPasteboard *)pasteboard {
   NSData *data=[self dataWithPDFInsideRect:rect];

   [pasteboard declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
   [pasteboard setData:data forType:NSPDFPboardType];
}

-(void)dragImage:(NSImage *)image at:(NSPoint)location offset:(NSSize)offset event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard source:source slideBack:(BOOL)slideBack {
   [[NSDraggingManager draggingManager] dragImage:image at:location offset:offset event:event pasteboard:pasteboard source:source slideBack:slideBack];
}

-(BOOL)dragFile:(NSString *)path fromRect:(NSRect)rect slideBack:(BOOL)slideBack event:(NSEvent *)event {
   NSUnimplementedMethod();
   return NO;
}

-(BOOL)acceptsFirstResponder {
   return NO;
}

-(void)scrollWheel:(NSEvent *)event {
   NSScrollView *scrollView=[self enclosingScrollView];

   if(scrollView!=nil){
    NSRect bounds=[self bounds];
    NSRect visible=[self visibleRect];
    float  direction=[self isFlipped]?-1:1;

    visible.origin.y+=[event deltaY]*direction*[scrollView verticalLineScroll]*3;

// Something equivalent to this should be in scrollRectToVisible:
    if(visible.origin.y<bounds.origin.y)
     visible.origin.y=bounds.origin.y;
    if(NSMaxY(visible)>NSMaxY(bounds))
     visible.origin.y=NSMaxY(bounds)-visible.size.height;

    [self scrollRectToVisible:visible];
   }
}

-(BOOL)performKeyEquivalent:(NSEvent *)event {
   int i,count=[_subviews count];

   for(i=0;i<count;i++){
    NSView *check=[_subviews objectAtIndex:i];

    if([check performKeyEquivalent:event])
     return YES;
   }
   return NO;
}

-(void)setMenu:(NSMenu *)menu {
   menu=[menu copy];
   [_menu release];
   _menu=menu;
}

-(void)rightMouseDown:(NSEvent *)event {
   [NSMenu popUpContextMenu:[self menuForEvent:event] withEvent:event forView:self];
}


// default NSDraggingDestination
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
   return NSDragOperationNone;
}

-(NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
   return [sender draggingSourceOperationMask];
}

-(void)draggingExited:(id <NSDraggingInfo>)sender {
   // do nothing
}

-(BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
   return NO;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
   return NO;
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)sender {
   // do nothing
}

-(NSArray *)_draggedTypes {
   return _draggedTypes;
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data
{
    if (view == self && tag == _defaultToolTipTag)
        return [self toolTip];
    
    return nil;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] frame: %@>", [self class], self, NSStringFromRect(_frame)];
}

@end

