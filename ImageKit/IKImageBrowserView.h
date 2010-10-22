#import <AppKit/AppKit.h>
#import <ImageKit/ImageKitExport.h>

@class IKImageBrowserCell;

IMAGEKIT_EXPORT NSString * const IKImageBrowserQuickLookPathRepresentationType;

IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupRangeKey;
IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupTitleKey;
IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupStyleKey;

IMAGEKIT_EXPORT NSString * const IKImageBrowserBackgroundColorKey;


enum {
   IKGroupBezelStyle,
   IKGroupDisclosureStyle,
};

enum {
   IKCellsStyleNone              =0,
   IKCellsStyleShadowed          =1,
   IKCellsStyleOutlined          =2,
   IKCellsStyleTitled            =4,
   IKCellsStyleSubtitled         =8
};

typedef enum {
   IKImageBrowserDropOn=0,
   IKImageBrowserDropBefore=1,
} IKImageBrowserDropOperation;

@interface IKImageBrowserView : NSView {
   id _delegate;
   id _dataSource;
   NSUInteger _numberOfColumns;
   NSUInteger _numberOfRows;
   NSSize _cellSize;
   NSSize _intercellSpacing;
   NSColor *_backgroundColor;
   float _zoomValue;
   BOOL _allowsDroppingOnItems;
   BOOL _allowsEmptySelection;
   BOOL _allowsMultipleSelection;
   BOOL _allowsReordering;
   BOOL _animates;
   BOOL _canControlQuickLookPanel;
   
}

-initWithFrame:(NSRect)frame;

-delegate;
-dataSource;

-(NSSize)intercellSpacing;

-(BOOL)allowsDroppingOnItems;
-(BOOL)allowsEmptySelection;

-(BOOL)allowsMultipleSelection;

-(BOOL)allowsReordering;

-(BOOL)animates;

-(CALayer *)backgroundLayer;

-(BOOL)canControlQuickLookPanel;

-(IKImageBrowserCell *)cellForItemAtIndex:(NSUInteger)index;

-(NSSize)cellSize;

-(NSUInteger)cellsStyleMask;

-(void)collapseGroupAtIndex:(NSUInteger)index;

-(NSIndexSet *)columnIndexesInRect:(NSRect)rect;

-(BOOL)constrainsToOriginalSize;

-(NSUInteger)contentResizingMask;



-draggingDestinationDelegate;

-(IKImageBrowserDropOperation)dropOperation;

-(void)expandGroupAtIndex:(NSUInteger)index;

-(CALayer *)foregroundLayer;

-(NSUInteger)indexAtLocationOfDroppedItem;

-(NSInteger)indexOfItemAtPoint:(NSPoint)point;
-(BOOL)isGroupExpandedAtIndex:(NSUInteger)index;

-(NSRect)itemFrameAtIndex:(NSInteger)index;

-(IKImageBrowserCell *)newCellForRepresentedItem:(id)anItem;

-(NSUInteger)numberOfColumns;

-(NSUInteger)numberOfRows;

-(NSRect)rectOfColumn:(NSUInteger)columnIndex;

-(NSRect)rectOfRow:(NSUInteger)rowIndex;

-(void)reloadData;

-(NSIndexSet *)rowIndexesInRect:(NSRect)rect;

-(void)scrollIndexToVisible:(NSInteger)index;

-(NSIndexSet *)selectionIndexes;

-(void)setAllowsDroppingOnItems:(BOOL)flag;

-(void)setAllowsEmptySelection:(BOOL)flag;

-(void)setAllowsMultipleSelection:(BOOL)flag;

-(void)setAllowsReordering:(BOOL)flag;

-(void)setAnimates:(BOOL)flag;

-(void)setBackgroundLayer:(CALayer *)aLayer;

-(void)setCanControlQuickLookPanel:(BOOL)flag;

-(void)setCellSize:(NSSize)size;

-(void)setCellsStyleMask:(NSUInteger)mask;

-(void)setConstrainsToOriginalSize:(BOOL)flag;

-(void)setContentResizingMask:(NSUInteger)mask;

-(void)setDataSource:source;

-(void)setDelegate:delegate;

-(void)setDraggingDestinationDelegate:(id)delegate;

-(void)setForegroundLayer:(CALayer *)aLayer;

-(void)setIntercellSpacing:(NSSize)value;

-(void)setSelectionIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extendSelection;

-(NSIndexSet *)visibleItemIndexes;

-(float)zoomValue;
-(void)setZoomValue:(float)value; 

@end
