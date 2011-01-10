#import <AppKit/AppKit.h>
#import <ImageKit/ImageKitExport.h>

@class IKImageBrowserCell;

IMAGEKIT_EXPORT NSString * const IKImageBrowserQuickLookPathRepresentationType;

IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupRangeKey;
IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupTitleKey;
IMAGEKIT_EXPORT NSString * const IKImageBrowserGroupStyleKey;

IMAGEKIT_EXPORT NSString * const IKImageBrowserBackgroundColorKey;

IMAGEKIT_EXPORT NSString * const IKImageBrowserPathRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserNSURLRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserNSImageRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserCGImageRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserCGImageSourceRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserNSDataRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserNSBitmapImageRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserQTMovieRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserQTMoviePathRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserQCCompositionRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserQCCompositionPathRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserQuickLookPathRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserIconRefPathRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserIconRefRepresentationType;
IMAGEKIT_EXPORT NSString * const IKImageBrowserPDFPageRepresentationType;

enum {
   IKGroupBezelStyle,
   IKGroupDisclosureStyle,
};

enum {
   IKCellsStyleNone              =0,
   IKCellsStyleShadowed          =1,
   IKCellsStyleOutlined          =2,
   IKCellsStyleTitled            =4,
   IKCellsStyleSubtitled         =8,
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
-(BOOL)canControlQuickLookPanel;
-(BOOL)constrainsToOriginalSize;
-(NSSize)cellSize;

-(NSUInteger)cellsStyleMask;

-(CALayer *)backgroundLayer;
-(CALayer *)foregroundLayer;

-(void)setAllowsDroppingOnItems:(BOOL)value;
-(void)setAllowsEmptySelection:(BOOL)value;
-(void)setAllowsMultipleSelection:(BOOL)value;
-(void)setAllowsReordering:(BOOL)value;
-(void)setAnimates:(BOOL)value;
-(void)setCanControlQuickLookPanel:(BOOL)value;
-(void)setCellSize:(NSSize)value;
-(void)setCellsStyleMask:(NSUInteger)value;
-(void)setConstrainsToOriginalSize:(BOOL)value;
-(void)setContentResizingMask:(NSUInteger)value;

-(void)setBackgroundLayer:(CALayer *)aLayer;

-(void)setDataSource:source;

-(void)setDelegate:delegate;

-(void)setDraggingDestinationDelegate:delegate;

-(void)setForegroundLayer:(CALayer *)layer;

-(void)setIntercellSpacing:(NSSize)value;



-(IKImageBrowserCell *)cellForItemAtIndex:(NSUInteger)index;


-(void)collapseGroupAtIndex:(NSUInteger)index;

-(NSIndexSet *)columnIndexesInRect:(NSRect)rect;


-(NSUInteger)contentResizingMask;

-draggingDestinationDelegate;

-(IKImageBrowserDropOperation)dropOperation;

-(void)expandGroupAtIndex:(NSUInteger)index;


-(NSUInteger)indexAtLocationOfDroppedItem;

-(NSInteger)indexOfItemAtPoint:(NSPoint)point;
-(BOOL)isGroupExpandedAtIndex:(NSUInteger)index;

-(NSRect)itemFrameAtIndex:(NSInteger)index;

-(IKImageBrowserCell *)newCellForRepresentedItem:item;

-(NSUInteger)numberOfRows;
-(NSUInteger)numberOfColumns;


-(NSRect)rectOfColumn:(NSUInteger)column;
-(NSRect)rectOfRow:(NSUInteger)rowIndex;

-(void)reloadData;

-(NSIndexSet *)rowIndexesInRect:(NSRect)rect;


-(NSIndexSet *)selectionIndexes;


-(void)setSelectionIndexes:(NSIndexSet *)value byExtendingSelection:(BOOL)extendSelection;

-(void)scrollIndexToVisible:(NSInteger)index;

-(NSIndexSet *)visibleItemIndexes;

-(float)zoomValue;
-(void)setZoomValue:(float)value; 

@end

@interface NSObject(IKImageBrowserItem)
- (id) imageRepresentation;
- (NSString *) imageRepresentationType;
- (NSString *) imageSubtitle;
- (NSString *) imageTitle;
- (NSString *) imageUID;
- (NSUInteger) imageVersion;
- (BOOL) isSelectable;

@end

@interface NSObject(IKImageBrowserDelegate)

-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)browser;

-(void)imageBrowser:(IKImageBrowserView *)browser backgroundWasRightClickedWithEvent:(NSEvent *)event;
-(void)imageBrowser:(IKImageBrowserView *)browser cellWasRightClickedAtIndex:(NSUInteger)index withEvent:(NSEvent *)event;
-(void)imageBrowser:(IKImageBrowserView *)browser cellWasDoubleClickedAtIndex:(NSUInteger)index;
@end

@interface NSObject(IKImageBrowserDataSource)

-(NSDictionary *)imageBrowser:(IKImageBrowserView *)browser groupAtIndex:(NSUInteger)index;
-imageBrowser:(IKImageBrowserView *)browser itemAtIndex:(NSUInteger)index;

-(BOOL)imageBrowser:(IKImageBrowserView *)browser moveItemsAtIndexes: (NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex;
-(void)imageBrowser:(IKImageBrowserView *)browser removeItemsAtIndexes:(NSIndexSet *)indexes;
-(NSUInteger)imageBrowser:(IKImageBrowserView *)browser writeItemsAtIndexes:(NSIndexSet *)itemIndexes toPasteboard:(NSPasteboard *)pasteboard;
-(NSUInteger)numberOfGroupsInImageBrowser:(IKImageBrowserView *)browser;
-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser;


@end











