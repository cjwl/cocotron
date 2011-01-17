#import <ImageKit/IKImageBrowserView.h>
#import <AppKit/NSRaise.h>

NSString * const IKImageBrowserQuickLookPathRepresentationType=@"IKImageBrowserQuickLookPathRepresentationType";

NSString * const IKImageBrowserGroupRangeKey=@"IKImageBrowserGroupRangeKey";
NSString * const IKImageBrowserGroupTitleKey=@"IKImageBrowserGroupTitleKey";
NSString * const IKImageBrowserGroupStyleKey=@"IKImageBrowserGroupStyleKey";

NSString * const IKImageBrowserBackgroundColorKey=@"backgroundColor";

@implementation IKImageBrowserView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _backgroundColor=[[NSColor whiteColor] copy];
   return self;
}

-(void)dealloc {
   [_backgroundColor release];
   [super dealloc];
}

-dataSource {
   return _dataSource;
}

-delegate {
   return _delegate;
}

-(NSSize)intercellSpacing {
   return _intercellSpacing;
}

-(BOOL)allowsDroppingOnItems {
   return _allowsDroppingOnItems;
}

-(BOOL)allowsEmptySelection {
   return _allowsEmptySelection;
}


-(BOOL)allowsMultipleSelection {
   return _allowsMultipleSelection;
}


-(BOOL)allowsReordering {
   return _allowsReordering;
}


-(BOOL)animates {
   return _animates;
}


-(CALayer *)backgroundLayer {
   NSUnimplementedMethod();
   return 0;
}


-(BOOL)canControlQuickLookPanel {
   return _canControlQuickLookPanel;
}


-(IKImageBrowserCell *)cellForItemAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
   return 0;
}


-(NSSize)cellSize {
   return _cellSize;
}


-(NSUInteger)cellsStyleMask {
   NSUnimplementedMethod();
   return 0;
}


-(void)collapseGroupAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
}


-(NSIndexSet *)columnIndexesInRect:(NSRect)rect {
   NSUnimplementedMethod();
   return 0;
}


-(BOOL)constrainsToOriginalSize {
   NSUnimplementedMethod();
   return 0;
}


-(NSUInteger)contentResizingMask {
   NSUnimplementedMethod();
   return 0;
}


-draggingDestinationDelegate {
   NSUnimplementedMethod();
   return 0;
}


-(IKImageBrowserDropOperation)dropOperation {
   NSUnimplementedMethod();
   return 0;
}


-(void)expandGroupAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
}


-(CALayer *)foregroundLayer {
   NSUnimplementedMethod();
   return 0;
}


-(NSUInteger)indexAtLocationOfDroppedItem {
   NSUnimplementedMethod();
   return 0;
}


-(NSInteger)indexOfItemAtPoint:(NSPoint)point {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)isGroupExpandedAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
   return 0;
}


-(NSRect)itemFrameAtIndex:(NSInteger)index {
   NSUnimplementedMethod();
   return NSZeroRect;
}


-(IKImageBrowserCell *)newCellForRepresentedItem:anItem {
   NSUnimplementedMethod();
   return 0;
}


-(NSUInteger)numberOfColumns {
   return _numberOfColumns;
}


-(NSUInteger)numberOfRows {
   return _numberOfRows;
}


-(NSRect)rectOfColumn:(NSUInteger)columnIndex {
   NSUnimplementedMethod();
   return NSZeroRect;
}


-(NSRect)rectOfRow:(NSUInteger)rowIndex {
   NSUnimplementedMethod();
   return NSZeroRect;
}


-(void)reloadData {
   NSUnimplementedMethod();
}


-(NSIndexSet *)rowIndexesInRect:(NSRect)rect {
   NSUnimplementedMethod();
   return 0;
}


-(void)scrollIndexToVisible:(NSInteger)index {
   NSUnimplementedMethod();
}


-(NSIndexSet *)selectionIndexes {
   NSUnimplementedMethod();
   return 0;
}


-(void)setAllowsDroppingOnItems:(BOOL)value {
   _allowsDroppingOnItems=value;
}


-(void)setAllowsEmptySelection:(BOOL)value {
   _allowsEmptySelection=value;
}


-(void)setAllowsMultipleSelection:(BOOL)value {
   _allowsMultipleSelection=value;
}


-(void)setAllowsReordering:(BOOL)value {
   _allowsReordering=value;
}


-(void)setAnimates:(BOOL)value {
   _animates=value;
}


-(void)setBackgroundLayer:(CALayer *)aLayer {
   NSUnimplementedMethod();
}


-(void)setCanControlQuickLookPanel:(BOOL)value {
   _canControlQuickLookPanel=value;
}

-(void)_tile {
   NSUnimplementedMethod();
}

-(void)setCellSize:(NSSize)size {
   _cellSize=size;
   [self _tile];
}


-(void)setCellsStyleMask:(NSUInteger)mask {
   NSUnimplementedMethod();
}


-(void)setConstrainsToOriginalSize:(BOOL)flag {
   NSUnimplementedMethod();
}


-(void)setContentResizingMask:(NSUInteger)mask {
   NSUnimplementedMethod();
}


-(void)setDataSource:source {
  _dataSource=source;
}


-(void)setDelegate:delegate {
   _delegate=delegate;
}


-(void)setDraggingDestinationDelegate:delegate {
   NSUnimplementedMethod();
}


-(void)setForegroundLayer:(CALayer *)aLayer {
   NSUnimplementedMethod();
}


-(void)setIntercellSpacing:(NSSize)value {
   _intercellSpacing=value;
   [self _tile];
}


-(void)setSelectionIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extendSelection {
   NSUnimplementedMethod();
}


-(NSIndexSet *)visibleItemIndexes {
   NSUnimplementedMethod();
   return 0;
}


-(float)zoomValue {
   return _zoomValue;
}

-(void)setZoomValue:(float)value {
   _zoomValue=value;
   [self setNeedsDisplay:YES];
}

// This is exposed through  key value coding
-(void)setBackgroundColor:(NSColor *)color {
   color=[color copy];
   [_backgroundColor release];
   _backgroundColor=color;
}

-(void)drawRect:(NSRect)rect {
   [_backgroundColor setFill];
   NSRectFill([self bounds]);
   
}

@end
