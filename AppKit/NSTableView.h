/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSControl.h>
#import <AppKit/NSDragging.h>

@class NSTableHeaderView, NSTableColumn;

APPKIT_EXPORT NSString *NSTableViewSelectionIsChangingNotification;
APPKIT_EXPORT NSString *NSTableViewSelectionDidChangeNotification;
APPKIT_EXPORT NSString *NSTableViewColumnDidMoveNotification;		
APPKIT_EXPORT NSString *NSTableViewColumnDidResizeNotification;

enum {
   NSTableViewGridNone,
   NSTableViewSolidVerticalGridLineMask,
   NSTableViewSolidHorizontalGridLineMask
};

typedef enum { 
   NSTableViewDropOn, 
   NSTableViewDropAbove 
} NSTableViewDropOperation; 

@interface NSTableView : NSControl {
   id  _target;
   SEL _action;
   SEL _doubleAction;

   id  _delegate;
   id  _dataSource;

   NSTableHeaderView *_headerView;
   NSView 	         *_cornerView;
   NSMutableArray    *_tableColumns;

   float _rowHeight;
   NSColor *_backgroundColor;
   NSColor *_gridColor;
   BOOL _drawsGrid;
   BOOL _allowsColumnReordering;
   BOOL _allowsColumnResizing;
   BOOL _autoresizesAllColumnsToFit;
   BOOL _allowsMultipleSelection;
   BOOL _allowsEmptySelection;
   BOOL _allowsColumnSelection;
   NSSize _intercellSpacing;

   BOOL _alternatingRowBackground;
   unsigned int _gridStyleMask;

   // temp ivars
   int _numberOfRows;
   NSMutableArray *_selectedColumns;
   NSIndexSet *_selectedRowIndexes;
   int _clickedColumn, _clickedRow;
   int _editedColumn, _editedRow;
   id _editingCell;
   NSRect _editingFrame;
   NSArray* _sortDescriptors;

   int _draggingRow; 
}

-(SEL)doubleAction;

-dataSource;
-delegate;

-(NSView *)headerView;
-(NSView *)cornerView;

-(float)rowHeight;
-(NSSize)intercellSpacing;
-(NSColor *)backgroundColor;
-(NSColor *)gridColor;
-(NSString *)autosaveName;

-(BOOL)drawsGrid;
-(BOOL)allowsColumnReordering;
-(BOOL)allowsColumnResizing;
-(BOOL)autoresizesAllColumnsToFit;
-(BOOL)allowsMultipleSelection;
-(BOOL)allowsEmptySelection;
-(BOOL)allowsColumnSelection;
-(BOOL)autosaveTableColumns;

-(BOOL)usesAlternatingRowBackgroundColors;
-(unsigned int)gridStyleMask;

-(int)numberOfRows;
-(int)numberOfColumns;
-(NSArray *)tableColumns;
-(NSTableColumn *)tableColumnWithIdentifier:identifier;

-(NSRect)rectOfRow:(int)row;
-(NSRect)rectOfColumn:(int)column;
-(NSRange)rowsInRect:(NSRect)rect;
-(NSRange)columnsInRect:(NSRect)rect;
-(int)rowAtPoint:(NSPoint)point;
-(int)columnAtPoint:(NSPoint)point;
-(NSRect)frameOfCellAtColumn:(int)column row:(int)row;

-(void)setDoubleAction:(SEL)action;

-(void)setDataSource:dataSource;
-(void)setDelegate:delegate;

-(void)setHeaderView:(NSTableHeaderView *)headerView;
-(void)setCornerView:(NSView *)view;

-(void)setRowHeight:(float)height;
-(void)setIntercellSpacing:(NSSize)size;
-(void)setBackgroundColor:(NSColor *)color;
-(void)setGridColor:(NSColor *)color;
-(void)setAutosaveName:(NSString *)name;

-(void)setDrawsGrid:(BOOL)flag;
-(void)setAllowsColumnReordering:(BOOL)flag;
-(void)setAllowsColumnResizing:(BOOL)flag;
-(void)setAutoresizesAllColumnsToFit:(BOOL)flag;
-(void)setAllowsMultipleSelection:(BOOL)flag;
-(void)setAllowsEmptySelection:(BOOL)flag;
-(void)setAllowsColumnSelection:(BOOL)flag;
-(void)setAutosaveTableColumns:(BOOL)flag;

-(void)setUsesAlternatingRowBackgroundColors:(BOOL)flag;
-(void)setGridStyleMask:(unsigned int)gridStyle;

-(void)addTableColumn:(NSTableColumn *)column;
-(void)removeTableColumn:(NSTableColumn *)column;

-(int)editedRow;
-(int)editedColumn;
-(void)editColumn:(int)column row:(int)row withEvent:(NSEvent *)event select:(BOOL)select;

-(int)clickedRow;
-(int)clickedColumn;
-(int)selectedRow;
-(int)selectedColumn;
-(int)numberOfSelectedRows;
-(int)numberOfSelectedColumns;
-(BOOL)isColumnSelected:(int)row;
-(BOOL)isRowSelected:(int)row;
-(NSEnumerator *)selectedRowEnumerator;
-(NSEnumerator *)selectedColumnEnumerator;
-(NSIndexSet *)selectedColumnIndexes;

-(void)selectRow:(int)row byExtendingSelection:(BOOL)extend;
-(void)selectColumn:(int)column byExtendingSelection:(BOOL)extend;
-(void)deselectRow:(int)row;
-(void)deselectColumn:(int)column;

-(void)selectAll:sender;
-(void)deselectAll:sender;

-(void)scrollRowToVisible:(int)index;
-(void)scrollColumnToVisible:(int)index;

-(void)noteNumberOfRowsChanged;
-(void)reloadData;
-(void)tile;

-(void)sizeLastColumnToFit;

-(void)highlightSelectionInClipRect:(NSRect)rect;

-(void)drawRow:(int)row clipRect:(NSRect)rect;
-(void)drawGridInClipRect:(NSRect)rect;

- (NSIndexSet *)selectedRowIndexes;
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;

- (NSArray *)sortDescriptors;
- (void)setSortDescriptors:(NSArray *)value;
@end

@interface NSObject(NSTableView_dataSource)
-(int)numberOfRowsInTableView:(NSTableView *)tableView;
-tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
-(void)tableView:(NSTableView *)tableView setObjectValue:object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard;
-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedRow:(int)proposedRow proposedDropOperation:(NSTableViewDropOperation)dropOperation;
-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)draggingInfo row:(int)row dropOperation:(NSTableViewDropOperation)dropOperation;
@end

@interface NSObject(NSTableView_delegate)
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row;
-(BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView;
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
-(BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
-(void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
-(void)tableView:(NSTableView *)tableView willDisplayCell:cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end

@interface NSObject(NSTableView_notifications)
-(void)tableViewSelectionIsChanging:(NSNotification *)note;
-(void)tableViewSelectionDidChange:(NSNotification *)note;
-(void)tableViewColumnDidMove:(NSNotification *)note;
-(void)tableViewColumnDidResize:(NSNotification *)note;
@end

