/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/AppKit.h>
#import <AppKit/NSTableCornerView.h>
#import <Foundation/NSKeyedUnarchiver.h>
#import "NSKeyValueBinding/NSMultipleValueBinder.h"
#import "NSKeyValueBinding/NSKVOBinder.h"
#import <AppKit/NSRaise.h>

NSString *NSTableViewSelectionIsChangingNotification=@"NSTableViewSelectionIsChangingNotification";
NSString *NSTableViewSelectionDidChangeNotification=@"NSTableViewSelectionDidChangeNotification";
NSString *NSTableViewColumnDidMoveNotification=@"NSTableViewColumnDidMoveNotification";
NSString *NSTableViewColumnDidResizeNotification=@"NSTableViewColumnDidResizeNotification";


@interface NSTableView(NSTableView_notifications)

-(BOOL)delegateShouldSelectTableColumn:(NSTableColumn *)tableColumn ;
-(BOOL)delegateShouldSelectRow:(int)row;
-(BOOL)delegateShouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row;
-(BOOL)delegateSelectionShouldChange;
-(void)noteSelectionIsChanging;
-(void)noteSelectionDidChange;
-(void)noteColumnDidResizeWithOldWidth:(float)oldWidth;
-(BOOL)dataSourceCanSetObjectValue;
-(void)dataSourceSetObjectValue:object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end

@implementation NSTableView

-(id)_replacementKeyPathForBinding:(id)binding
{
    if([binding isEqual:@"selectionIndexes"])
        return @"selectedRowIndexes";
   return [super _replacementKeyPathForBinding:binding];
}

+(Class)_binderClassForBinding:(id)binding
{
    if([binding isEqual:@"content"])
       return [_NSTableViewContentBinder class];
    return [_NSKVOBinder class];
}

-(void)_boundValuesChanged
{
    [_tableColumns makeObjectsPerformSelector:@selector(_boundValuesChanged)];
    [self reloadData];
}

-(void)_establishBindingsWithDestinationIfUnbound:(id)destination
{
    // this method is called after table column bindings have been established.
    // if the table view doesn't have any bindings at this point, it needs to have
    // its content, sortDescriptors and selectedIndexes bindings established
    if([[self _allUsedBinders] count]==0)
    {
        [self bind:@"content" 
          toObject:destination 
       withKeyPath:@"arrangedObjects"
           options:nil];
        [self bind:@"sortDescriptors" 
          toObject:destination 
       withKeyPath:@"sortDescriptors"
           options:nil];
        [self bind:@"selectionIndexes" 
          toObject:destination 
       withKeyPath:@"selectionIndexes"
           options:nil];
    }
}


-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    unsigned              flags=[keyed decodeIntForKey:@"NSTvFlags"];
    
    _headerView=[[keyed decodeObjectForKey:@"NSHeaderView"] retain];
    [_headerView setTableView:self];
    _cornerView=[[keyed decodeObjectForKey:@"NSCornerView"] retain];
    _tableColumns=[[NSMutableArray alloc] initWithArray:[keyed decodeObjectForKey:@"NSTableColumns"]];
    [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];
    _backgroundColor=[[keyed decodeObjectForKey:@"NSBackgroundColor"] retain];
    _gridColor=[[keyed decodeObjectForKey:@"NSGridColor"] retain];
    _rowHeight=[keyed decodeFloatForKey:@"NSRowHeight"];
    _drawsGrid=(flags&0x20000000)?YES:NO;
    _allowsColumnReordering=(flags&0x80000000)?YES:NO;
    _allowsColumnResizing=(flags&0x40000000)?YES:NO;
    _autoresizesAllColumnsToFit=(flags&0x00008000)?YES:NO;
    _allowsMultipleSelection=(flags&0x08000000)?YES:NO;
    _allowsEmptySelection=(flags&0x10000000)?YES:NO;
    _allowsColumnSelection=(flags&0x04000000)?YES:NO;
    _intercellSpacing = NSMakeSize(3.0,2.0);
    _selectedRowIndexes = [[NSIndexSet alloc] init];
    _selectedColumns = [[NSMutableArray alloc] init];
    _editedColumn = -1;
    _editedRow = -1;
    _numberOfRows = -1;

    // row background and grid attributes for OS X >= 10.3
    _alternatingRowBackground=(flags&0x00800000)?YES:NO;
    if ([keyed containsValueForKey:@"NSGridStyleMask"])
       _gridStyleMask=[keyed decodeIntForKey:@"NSGridStyleMask"];
    else
       _gridStyleMask=NSTableViewGridNone;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }
   return self;
}


-initWithFrame:(NSRect)frame {
    [super initWithFrame:frame];
    // Returns the height of each row in the receiver. The default row height is 16.0.
    _rowHeight = 16.0;
    _intercellSpacing = NSMakeSize(3.0,2.0);
    _selectedRowIndexes = [[NSIndexSet alloc] init];
    _selectedColumns = [[NSMutableArray alloc] init];
    _editedColumn = -1;
    _editedRow = -1;
    _numberOfRows = -1;

    _allowsColumnReordering = YES;
    _allowsColumnResizing = YES;
    _autoresizesAllColumnsToFit = NO; // the default isn't actually given in the spec, but this seems more like default behavior
    _allowsMultipleSelection = NO;
    _allowsEmptySelection = YES;
    _allowsColumnSelection = YES;

    _headerView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0,0,[self bounds].size.width,_rowHeight+_intercellSpacing.height)];
    [_headerView setTableView:self];

    _cornerView = [[NSTableCornerView alloc] initWithFrame:NSMakeRect(0,0,_rowHeight,_rowHeight)];

    _tableColumns = [[NSMutableArray alloc] init];
    _backgroundColor = [[NSColor controlBackgroundColor] retain];
    _gridColor = [[NSColor gridColor] retain];

    // row background and grid attributes for OS X >= 10.3
    _alternatingRowBackground = NO;
    _gridStyleMask = 0;

    return self;
}

-(void)dealloc {
   [_headerView release];
   [_cornerView release];
   [_tableColumns release];
   [_backgroundColor release];
   [_gridColor release];
   [_selectedRowIndexes release];
   [_selectedColumns release];
   [_sortDescriptors release];
   [super dealloc];
}

-target {
   return _target;
}

-(SEL)action {
   return _action;
}

-(SEL)doubleAction {
   return _doubleAction;
}

-dataSource {
   return _dataSource;
}

-delegate {
   return _delegate;
}

-(NSView *)headerView {
    return _headerView;
}

-(NSView *)cornerView {
    return _cornerView;
}

-(float)rowHeight {
    return _rowHeight;
}

-(NSSize)intercellSpacing {
    return _intercellSpacing;
}

-(NSColor *)backgroundColor {
   return _backgroundColor;
}

-(NSColor *)gridColor {
   return _gridColor;
}

-(NSString *)autosaveName {
   NSUnimplementedMethod();
   return nil;
}

// deprecated in OS X >= 10.3
// use gridStyleMask instead
-(BOOL)drawsGrid {
    return _gridStyleMask != NSTableViewGridNone;
}

-(BOOL)allowsColumnReordering {
    return _allowsColumnReordering;
}

-(BOOL)allowsColumnResizing {
    return _allowsColumnResizing;
}

-(BOOL)autoresizesAllColumnsToFit {
    return _autoresizesAllColumnsToFit;
}

-(BOOL)allowsMultipleSelection {
    return _allowsMultipleSelection;
}

-(BOOL)allowsEmptySelection {
    return _allowsEmptySelection;
}

-(BOOL)allowsColumnSelection {
    return _allowsColumnSelection;
}

-(BOOL)autosaveTableColumns {
   NSUnimplementedMethod();
   return NO;
}

// row background and grid attributes for OS X >= 10.3
-(BOOL)usesAlternatingRowBackgroundColors {
   return _alternatingRowBackground;
}

-(unsigned int)gridStyleMask {
   return _gridStyleMask;
}

-(NSInteger)numberOfRows {

   if (_numberOfRows < 0) {
    id binding=[self _binderForBinding:@"content"];

    if(binding)
     _numberOfRows=[binding numberOfRows];

    if (_numberOfRows < 0)
     _numberOfRows = [_dataSource numberOfRowsInTableView:self];
   }
   
   return _numberOfRows;
}

-(NSUInteger)numberOfColumns {
    return [_tableColumns count];
}

-(NSArray *)tableColumns {
   return _tableColumns;
}

-(NSTableColumn *)tableColumnWithIdentifier:identifier {
    NSEnumerator *tableColumnEnumerator = [_tableColumns objectEnumerator];
    NSTableColumn *column;

    while ((column = [tableColumnEnumerator nextObject])!=nil) 
        if ([[column identifier] isEqual:identifier])
            return column;

    return nil;
}

-(NSRect)rectOfRow:(NSInteger)row {
    NSRect rect = _bounds;
    NSInteger i = 0;

    if (row < 0 || row >= [self numberOfRows]) {
        return NSZeroRect;
    }

    rect.size.width = 0;
    while (i < [_tableColumns count])
        rect.size.width += [[_tableColumns objectAtIndex:i++] width] + _intercellSpacing.width;

    rect.origin.y += (row * (_rowHeight + _intercellSpacing.height));
    rect.size.height = _rowHeight + _intercellSpacing.height;

    return rect;
}

-(NSRect)rectOfColumn:(NSInteger)column {
    NSRect rect = _bounds;
    NSInteger i = 0;

    if (column < 0 || column >= [_tableColumns count]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"rectOfColumn: invalid index %d (valid {%d, %d})", column, 0, [_tableColumns count]];
    }
    
    while (i < column)
        rect.origin.x += [[_tableColumns objectAtIndex:i++] width] + _intercellSpacing.width;

    rect.size.width = [[_tableColumns objectAtIndex:column] width] + _intercellSpacing.width;
    rect.size.height = MAX([self numberOfRows] * (_rowHeight + _intercellSpacing.height), [[self superview] bounds].size.height); 

    return rect;
}

-(NSRange)rowsInRect:(NSRect)rect {
    NSRange range = NSMakeRange(0, 0);
    NSInteger numberOfRows=[self numberOfRows];
    
    for (range.location = 0; range.location < numberOfRows; ++range.location) {
        if (NSIntersectsRect([self rectOfRow:range.location], rect)) {
            while(NSMaxRange(range) < numberOfRows && NSIntersectsRect([self rectOfRow:range.location+range.length], rect))
                range.length++;
            break;
        }
    }

#if 0 // semibroken
    range.location = [self rowAtPoint:rect.origin]; // first row...
    range.length = [self rowAtPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];   // last row
    range.length -= range.location;
    range.length++;

    if (range.location == NSNotFound)
        range.location = 0;
    if (range.length == 0)
        range.length = numberOfRows;

    NSLog(@"rowsInRect %@: %@", NSStringFromRect(rect), NSStringFromRange(range));
    NSLog(@"max point at %@", NSStringFromPoint(NSMakePoint(NSMaxX(rect), NSMaxY(rect))));
#endif
    
    return range; // returns 0,0 if not found, not NSNotFound
}

-(NSRange)columnsInRect:(NSRect)rect {
    NSRange range = NSMakeRange(0, 0);

    for (range.location = 0; range.location < [_tableColumns count]; ++range.location) {
        if (NSIntersectsRect([self rectOfColumn:range.location], rect)) {
            while(NSMaxRange(range) < [_tableColumns count] &&
                  NSIntersectsRect([self rectOfColumn:range.location+range.length], rect))
                range.length++;
            break;
        }
    }

    if (range.length == 0) // not found
        range = NSMakeRange(NSNotFound, 0);

#if 0 // semibroken
    range.location = [self columnAtPoint:rect.origin];  // first column...
    range.length = [self columnAtPoint:NSMakePoint(NSMaxX(rect), _bounds.origin.y)];    // last column
    range.length -= range.location;
    range.length++;

    if (range.location == NSNotFound)
        range.location = 0;
    if (range.length == 0)
        range.length = [_tableColumns count];

    NSLog(@"columnsInRect %@: %@", NSStringFromRect(rect), NSStringFromRange(range));
    NSLog(@"maxPoint at %@", NSStringFromPoint(NSMakePoint(NSMaxX(rect), NSMaxY(rect))));
#endif

    return range;
}

-(int)rowAtPoint:(NSPoint)point {
    NSInteger i,numberOfRows=[self numberOfRows];

    for (i = 0; i < numberOfRows; ++i)
        if (NSMouseInRect(point, [self rectOfRow:i],[self isFlipped]))
            return i;

    return -1;
}

-(int)columnAtPoint:(NSPoint)point {
    int i;

    for (i = 0; i < [_tableColumns count]; ++i) {
        if (NSMouseInRect(point, [self rectOfColumn:i],[self isFlipped]))
            return i;
    }

    return -1;
}

-(NSRect)frameOfCellAtColumn:(int)column row:(int)row {
    NSRect rect = NSIntersectionRect([self rectOfColumn:column], [self rectOfRow:row]);

    return rect;
}

-(void)setTarget:target {
   _target=target;
}

-(void)setAction:(SEL)action {
   _action=action;
}

-(void)setDoubleAction:(SEL)action {
   _doubleAction=action;
}

-(void)setDataSource:dataSource {
    if (dataSource)
    {
        if(([dataSource respondsToSelector:@selector(numberOfRowsInTableView:)] == NO) ||
           ([dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)] == NO)) {
            // Apple AppKit only logs here, so we do the same
            NSLog(@"data source %@ does not respond to numberOfRowsInTableView: or tableView:objectValueForTableColumn:row:", dataSource);
            // data source is set no matter what in AppKit. Fall through.
        }
    }
    _dataSource=dataSource;
}

-(void)setDelegate:delegate {
    struct {
        NSString *name;
        SEL selector;
    } notes [] = {
      { NSTableViewSelectionDidChangeNotification, @selector(tableViewSelectionDidChange:) },
      { NSTableViewColumnDidMoveNotification, @selector(tableViewColumnDidMove:) },
      { NSTableViewColumnDidResizeNotification, @selector(tableViewColumnDidResize:) },
      { NSTableViewSelectionIsChangingNotification, @selector(tableViewSelectionIsChanging:) },
      { nil, NULL }
    };
    int i;

    if (_delegate != nil)
        for (i = 0; notes[i].name != nil; ++i)
            [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:notes[i].name object:self];

    _delegate=delegate;

    for (i = 0; notes[i].name != nil; ++i)
        if ([_delegate respondsToSelector:notes[i].selector])
            [[NSNotificationCenter defaultCenter] addObserver:_delegate
                                                     selector:notes[i].selector
                                                         name:notes[i].name
                                                       object:self];
}

-(void)setHeaderView:(NSTableHeaderView *)headerView {
    [headerView retain];
    [_headerView release];
    _headerView = headerView;
    [_headerView setTableView:self];
    [[self enclosingScrollView] tile];
}

-(void)setCornerView:(NSView *)view {
    [view retain];
    [_cornerView release];
    _cornerView = view;
    [[self enclosingScrollView] tile];
}

-(void)setRowHeight:(float)height {
    _rowHeight = height;
    [self tile];
}

-(void)setIntercellSpacing:(NSSize)size {
    _intercellSpacing = size;
    [self setNeedsDisplay:YES];
}

-(void)setBackgroundColor:(NSColor *)color {
   color=[color retain];
   [_backgroundColor release];
   _backgroundColor=color;
}

-(void)setGridColor:(NSColor *)color {
   color=[color retain];
   [_gridColor release];
   _gridColor=color;
}

-(void)setAutosaveName:(NSString *)name {
   NSUnimplementedMethod();
}

// deprecated in OS X >= 10.3
// use setGridStyleMask instead
-(void)setDrawsGrid:(BOOL)flag {
    if (flag)
       _gridStyleMask = NSTableViewSolidVerticalGridLineMask + NSTableViewSolidHorizontalGridLineMask;
    else
       _gridStyleMask = NSTableViewGridNone;
}

-(void)setAllowsColumnReordering:(BOOL)flag {
    _allowsColumnReordering = flag;
}

-(void)setAllowsColumnResizing:(BOOL)flag {
    _allowsColumnResizing = flag;
}

-(void)setAutoresizesAllColumnsToFit:(BOOL)flag {
    _autoresizesAllColumnsToFit = flag;
}

-(void)setAllowsMultipleSelection:(BOOL)flag {
    _allowsMultipleSelection = flag;
}

-(void)setAllowsEmptySelection:(BOOL)flag {
    _allowsEmptySelection = flag;
}

-(void)setAllowsColumnSelection:(BOOL)flag {
    _allowsColumnSelection = flag;
}

-(void)setAutosaveTableColumns:(BOOL)flag {
   NSUnimplementedMethod();
}

// row background and grid attributes for OS X >= 10.3
-(void)setUsesAlternatingRowBackgroundColors:(BOOL)flag {
   _alternatingRowBackground = flag;
}

-(void)setGridStyleMask:(unsigned int)gridStyle {
   _gridStyleMask = gridStyle;
}

// the appkit dox are pretty vague on these two. should they trigger a redraw or reloadData?
// also.. i wonder if remove should use an isEqual method in NSTableColumn, or removeObjectIdenticalTo...
-(void)addTableColumn:(NSTableColumn *)column {
    [_tableColumns addObject:column];
    [column setTableView:self];
    [self reloadData];
    [_headerView setNeedsDisplay:YES];
}

-(void)removeTableColumn:(NSTableColumn *)column {
    [column setTableView:nil];
    [_tableColumns removeObject:column];
    [self reloadData];
    [_headerView setNeedsDisplay:YES];
}

-(int)editedRow {
    return _editedRow;
}

-(int)editedColumn {
    return _editedColumn;
}

-dataSourceObjectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return [_dataSource tableView:self objectValueForTableColumn:tableColumn row:row];
}

- (NSRect)_adjustedFrame:(NSRect)frame forCell:(NSCell *)dataCell
{
   frame.origin.x    += _intercellSpacing.width  - 1;
   frame.origin.y    += _intercellSpacing.height;
   frame.size.width  -= _intercellSpacing.width;
   frame.size.height -= _intercellSpacing.height;
   if ([dataCell isKindOfClass:[NSTextFieldCell class]])
   {
      frame.origin.y++;
      frame.size.height--;
   }
   return frame;
}

-(void)editColumn:(int)column row:(int)row withEvent:(NSEvent *)event select:(BOOL)select {
   NSCell        *editingCell;
   NSTableColumn *editingColumn = [_tableColumns objectAtIndex:column];
   NSInteger      numberOfRows=[self numberOfRows];
   
   // light sanity check; invalid columns caught above in objectAtIndex:
   if (row < 0 || row >= numberOfRows)
      [NSException raise:NSInvalidArgumentException
                  format:@"invalid row in %@", NSStringFromSelector(_cmd)];
   
   if (![editingColumn isEditable])
      return;
   
   if ([self delegateShouldEditTableColumn:editingColumn row:row] == NO)
      return;
   
   if ([self dataSourceCanSetObjectValue] == NO && [[editingColumn _binderForBinding:@"value" create:NO] allowsEditingForRow:row] == NO)
      [NSException raise:NSInternalInconsistencyException
                  format:@"data source does not respond to tableView:setObjectValue:forTableColumn:row: and binding is read-only"];
   
   editingCell = [[editingColumn dataCellForRow:row] copy];
   _editedColumn = column;
   _editedRow = row;
   _editingFrame  = [self frameOfCellAtColumn:column row:row];
   _editingBorder = _editingFrame; _editingBorder.size.width++; _editingBorder.size.height++; 
   _editingFrame  = [self _adjustedFrame:_editingFrame forCell:editingCell];
   if ([editingCell isKindOfClass:[NSTextFieldCell class]])
   {
      _editingCell = editingCell;
      [_editingCell setDrawsBackground:YES];
      [_editingCell setBackgroundColor:_backgroundColor];
      [(NSCell *)_editingCell setObjectValue:[self dataSourceObjectValueForTableColumn:editingColumn row:row]];
      
      [editingColumn prepareCell:_editingCell inRow:row];
      
      _currentEditor=[[self window] fieldEditor:YES forObject:self];
      _currentEditor=[_editingCell setUpFieldEditorAttributes:_currentEditor];
      [_currentEditor retain];
      
      if (select == YES)
         [_editingCell selectWithFrame:_editingFrame inView:self editor:_currentEditor delegate:self start:0 length:[[_editingCell stringValue] length]];
      else
         [_editingCell editWithFrame:_editingFrame inView:self editor:_currentEditor delegate:self event:event];
      
      [self setNeedsDisplay:YES];
   }
}

-(int)clickedRow {
    return _clickedRow;
}

-(int)clickedColumn {
    return _clickedColumn;
}

- (NSArray *)sortDescriptors {
    if(!_sortDescriptors)
        _sortDescriptors=[NSArray new];
    return [[_sortDescriptors retain] autorelease];
}

- (void)setSortDescriptors:(NSArray *)value {
    if (_sortDescriptors != value) {
        [_sortDescriptors release];
        _sortDescriptors = [value copy];
    }
}

- (NSIndexSet *)selectedRowIndexes {
    return [[_selectedRowIndexes retain] autorelease];
}

// That's the setter for _selectedRowIndexes.
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
        unsigned index;
   NSIndexSet * newIndexes;
   NSInteger i, last, try;
   BOOL changed = NO;
   
   // Mac OS X doesn't raise an exception if one of the indices
   // is out of range. Instead, the selection is left untouched.
   if ([indexes firstIndex] < 0 || [indexes lastIndex] >= [self numberOfRows])
    return;

   // Selecting a row deselects all columns.
   if ([_selectedColumns count]) {
    [_selectedColumns removeAllObjects];
    [_headerView setNeedsDisplay:YES];
    changed = YES;
   }

   if (extend) {
    NSMutableIndexSet * mutableIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:_selectedRowIndexes];
    [mutableIndexes addIndexes:indexes];
    newIndexes = [[NSIndexSet alloc] initWithIndexSet:mutableIndexes];
    [mutableIndexes release];     
   } else
    newIndexes = [indexes retain];

   // Find the changed rows and mark them for redraw.
   i = [_selectedRowIndexes firstIndex];
   if (i == NSNotFound)
    i = [newIndexes firstIndex];
   else {
    try = [newIndexes firstIndex];
    if (try != NSNotFound && try < i)
     i = try;
   }
   last = [_selectedRowIndexes lastIndex];
   if (last == NSNotFound)
    last = [newIndexes lastIndex];
   else {
    try = [newIndexes lastIndex];
   if (try != NSNotFound && try > last)
    last = try;
   }
   if (i != NSNotFound) // If i is valid, last is valid as well.
    for ( ; i <= last; i++)
     if ([_selectedRowIndexes containsIndex:i] != [newIndexes containsIndex:i]) {
      [self setNeedsDisplayInRect:[self rectOfRow:i]];
      changed = YES;
      // NSLog(@"NSTableView row %d for redraw.", i);
     }

   [_selectedRowIndexes autorelease];
   _selectedRowIndexes = newIndexes;

   if (changed)
    [self noteSelectionDidChange];
}

-(int)selectedRow {
   NSInteger row = [_selectedRowIndexes firstIndex];

   if (row == NSNotFound)
    return -1;

   return row;
}

-(int)selectedColumn {
    if([_selectedColumns count]==0)
     return -1;

    return [_tableColumns indexOfObject:[_selectedColumns objectAtIndex:0]];
}

-(int)numberOfSelectedRows {
    return [_selectedRowIndexes count];
}

-(int)numberOfSelectedColumns {
    return [_selectedColumns count];
}

-(BOOL)isRowSelected:(int)row {
    return [_selectedRowIndexes containsIndex:row];
}

-(BOOL)isColumnSelected:(int)col {
    return [_selectedColumns containsObject:[_tableColumns objectAtIndex:col]];
}

-(NSEnumerator *)selectedColumnEnumerator {
    return [_selectedColumns objectEnumerator];
}

-(NSIndexSet *)selectedColumnIndexes {
   NSMutableIndexSet *result=[NSMutableIndexSet indexSet];
   int i,count=[_selectedColumns count];
   
   for(i=0;i<count;i++){
    unsigned index=[_tableColumns indexOfObjectIdenticalTo:[_selectedColumns objectAtIndex:i]];
    [result addIndex:index];
   }
   
   return result;
}

-(NSEnumerator *)selectedRowEnumerator {
    NSUnimplementedMethod();
    return nil;
}

// Deprecated since Mac OS X 10.3.
-(void)selectRow:(int)row byExtendingSelection:(BOOL)extend  {

   if (extend)
    [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self selectedRow], row)] byExtendingSelection:NO];
   else
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

-(void)selectColumn:(int)column byExtendingSelection:(BOOL)extend {
    NSTableColumn *tableColumn = [_tableColumns objectAtIndex:column];
    
    // selecting a column deselects all rows
    [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    
    if (extend == NO)
        [_selectedColumns removeAllObjects];

    if ([_selectedColumns containsObject:tableColumn] == NO) {
        if ([self delegateShouldSelectTableColumn:tableColumn] == YES)
            [_selectedColumns addObject:tableColumn];
    }

    [self noteSelectionDidChange];
    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
}

-(void)deselectRow:(int)row {
    NSIndexSet* selectedRowIndexes=[self selectedRowIndexes];

    if ([selectedRowIndexes containsIndex:row]) {
     NSMutableIndexSet *newSelection=[[selectedRowIndexes mutableCopy] autorelease];
     
     [newSelection removeIndex:row];
     [self selectRowIndexes:newSelection byExtendingSelection:NO];
    }
}

-(void)deselectColumn:(int)column  {
    if ([_selectedColumns containsObject:[_tableColumns objectAtIndex:column]]) {
        [_selectedColumns removeObject:[_tableColumns objectAtIndex:column]];
        [self setNeedsDisplayInRect:[self rectOfColumn:column]];
        [_headerView setNeedsDisplay:YES];
    }
}

-(void)selectAll:sender {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])] byExtendingSelection:NO];
}

-(void)deselectAll:sender  {
    [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [_selectedColumns removeAllObjects];
}


-(void)scrollRowToVisible:(int)index {
    [self scrollRectToVisible:[self rectOfRow:index]];
}

-(void)scrollColumnToVisible:(int)index {
    [self scrollRectToVisible:[self rectOfColumn:index]];
}

-(void)noteNumberOfRowsChanged {
    NSSize size = [self frame].size;
    NSSize headerSize = [_headerView frame].size;

    _numberOfRows = -1;
    NSInteger numberOfRows = [self numberOfRows];

    // if there's any editing going on, we'd better stop it.
    if (_editingCell != nil)
     [self abortEditing];

    if (numberOfRows > 0){
        size.width = [self rectOfRow:0].size.width;
    }
    if ([_tableColumns count] > 0)
        size.height = [self rectOfColumn:0].size.height;

    headerSize.width = size.width;

    [self setFrameSize:size];
    [_headerView setFrameSize:headerSize];
}

-(void)reloadData {
    [self noteNumberOfRowsChanged];
    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
}

-(void)tile {
    NSRect rect;

    [self sizeLastColumnToFit];
    [self noteNumberOfRowsChanged];
    rect=[_headerView frame];
    rect.size.width=[self frame].size.width;
    [_headerView setFrameSize:rect.size];

    [[self enclosingScrollView] setVerticalLineScroll:_rowHeight + _intercellSpacing.height];

    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
}

-(void)sizeLastColumnToFit {
    NSClipView *clipView = [self superview];
        
    if ([clipView isKindOfClass:[NSClipView class]]) {
        NSSize size = [clipView bounds].size;
        int i, count = [_tableColumns count];
        float lastWidth = size.width - (count * _intercellSpacing.width);
        NSTableColumn *lastColumn = [_tableColumns lastObject];

        for (i = 0; i < count-1; ++i)
            lastWidth -= [[_tableColumns objectAtIndex:i] width];

        if (lastWidth > 0)
            [lastColumn setWidth:lastWidth];
        else if (lastWidth < 0)
            [lastColumn setWidth:[lastColumn width]+lastWidth];

        [self setNeedsDisplay:YES];
    }
}

-(void)drawHighlightedSelectionForColumn:(int)column row:(int)row inRect:(NSRect)rect
{
    [[NSColor selectedControlColor] setFill];
    NSRectFill(rect);
}

-(void)highlightSelectionInClipRect:(NSRect)rect {
    NSInteger row, column;
    NSInteger numberOfRows=[self numberOfRows];
    
    for (column = 0; column < [_tableColumns count]; ++column)
        for (row = 0; row < numberOfRows; ++row)
            if ([self isColumnSelected:column] || [self isRowSelected:row])
               if (!(row == _editedRow && column == _editedColumn))
                  [self drawHighlightedSelectionForColumn:column row:row inRect:[self frameOfCellAtColumn:column row:row]];
}

- (NSCell *)preparedCellAtColumn:(NSInteger)columnNumber row:(NSInteger)row {
   NSTableColumn *column = [_tableColumns objectAtIndex:columnNumber];
   NSCell *dataCell = [column dataCellForRow:row];
   [dataCell setObjectValue:[self dataSourceObjectValueForTableColumn:column row:row]];
   
   if ([dataCell respondsToSelector:@selector(setTextColor:)]) {
      if ([self isRowSelected:row] || [self isColumnSelected:columnNumber])
         [(NSTextFieldCell *)dataCell setTextColor:[NSColor selectedTextColor]];
      else 
         [(NSTextFieldCell *)dataCell setTextColor:[NSColor textColor]];
   }
   
   [column prepareCell:dataCell inRow:row];
   
   return dataCell;
}

- (void)drawRow:(int)row clipRect:(NSRect)clipRect {
    // draw only visible columns.
    NSRange visibleColumns = [self columnsInRect:clipRect];
    int drawThisColumn = visibleColumns.location;
    NSInteger numberOfRows=[self numberOfRows];

    if (row < 0 || row >= numberOfRows)
        [NSException raise:NSInvalidArgumentException
                    format:@"invalid row in drawRow:clipRect:"];

    while (drawThisColumn < NSMaxRange(visibleColumns)) {
       if (!(row == _editedRow && drawThisColumn == _editedColumn)) {
          NSCell *dataCell=[self preparedCellAtColumn:drawThisColumn row:row];
          NSTableColumn *column = [_tableColumns objectAtIndex:drawThisColumn];
          NSRect cellRect = [self _adjustedFrame:[self frameOfCellAtColumn:drawThisColumn row:row] forCell:dataCell];
          if ([_delegate respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)])
             [_delegate tableView:self willDisplayCell:dataCell forTableColumn:column row:row];
          
          [dataCell drawWithFrame:cellRect inView:self];
       }
       drawThisColumn++;
    }
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
   NSArray *rowColors   = [NSColor controlAlternatingRowBackgroundColors];
   int      colorCount  = [rowColors count];
   if (colorCount == 0 || !_alternatingRowBackground)
   {
      [_backgroundColor setFill];
      NSRectFill(clipRect);
   }
   
   else if (colorCount == 1)
   {
      [(NSColor *)[rowColors objectAtIndex:0] setFill];
      NSRectFill(clipRect);
   }
   
   else
   {
      float  y            = _bounds.origin.y;
      float  rowHeight    = _rowHeight + _intercellSpacing.height;
      NSRect rect         = clipRect; rect.size.height = rowHeight;
      int i, numberOfRows = ceilf((y + clipRect.origin.y + clipRect.size.height)/rowHeight);
      
      for (i = 0; i < numberOfRows; i++)
      {
         if (clipRect.origin.y < y + rowHeight && y < clipRect.origin.y + clipRect.size.height)
         {
            rect.origin.y = y;
            [(NSColor *)[rowColors objectAtIndex:i%colorCount] setFill];
            NSRectFill(rect);
         }
         y += rowHeight;
      }
   }
}

- (void)drawGridInClipRect:(NSRect)clipRect
{
   float  x            = _bounds.origin.x;
   float  y            = _bounds.origin.y;
   float  rowHeight    = _rowHeight + _intercellSpacing.height;
   int i, numberOfRows = ceilf((y + clipRect.origin.y + clipRect.size.height)/rowHeight);
   
   NSPoint pt0, pt1;
   NSBezierPath *line = [NSBezierPath bezierPath];
   [_gridColor setStroke];
   
   if (_gridStyleMask & NSTableViewSolidVerticalGridLineMask == NSTableViewSolidVerticalGridLineMask)
   {
      // vertical ruling
      pt0.y = clipRect.origin.y;
      pt1.y = clipRect.origin.y + clipRect.size.height;
      for (i = 0; i < [_tableColumns count]; i++)
      {
         x += [[_tableColumns objectAtIndex:i] width] + _intercellSpacing.width;
         if (clipRect.origin.x < x && x <= clipRect.origin.x + clipRect.size.width)
         {
            pt0.x = pt1.x = x;
            [line moveToPoint:pt0];
            [line lineToPoint:pt1];
         }
      }
   }
   
   if (_gridStyleMask & NSTableViewSolidHorizontalGridLineMask == NSTableViewSolidHorizontalGridLineMask)
   {
      // horizontal ruling
      pt0.x = clipRect.origin.x;
      pt1.x = clipRect.origin.x +  + clipRect.size.width;
      for (i = 0; i < numberOfRows; i++)
      {
         y += rowHeight;
         if (clipRect.origin.y < y && y <= clipRect.origin.y + clipRect.size.height)
         {
            pt0.y = pt1.y = y;
            [line moveToPoint:pt0];
            [line lineToPoint:pt1];
         }
      }
   }
   
   [line stroke];
}

// can't use rectOfRow because empty tableviews will explode!
-(float)_displayWidthOfColumns {
    int i, count = [_tableColumns count];
    float result = 0;

    for (i = 0; i < count; ++i)
        result += [[_tableColumns objectAtIndex:i] width] + _intercellSpacing.width;

    return result;
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    NSSize size=[self frame].size;

    if(size.width<[[self superview] bounds].size.width){
     size.width=[[self superview] bounds].size.width;
     [self setFrameSize:size];
    }

    if (_autoresizesAllColumnsToFit) {
        float delta = [[self enclosingScrollView] contentSize].width - [self _displayWidthOfColumns];
        int i, count = [_tableColumns count];

        for (i = 0; i < count; ++i) {
            NSTableColumn *column = [_tableColumns objectAtIndex:i];
            [column setWidth:[column width] + floor((delta/count))];
        }

    }
    else
        [self sizeLastColumnToFit];

   [self tile];
}


-(BOOL)isOpaque {
    return NO;
}

-(BOOL)isFlipped {
   return YES;
}


-(BOOL)delegateShouldSelectTableColumn:(NSTableColumn *)tableColumn {
    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectTableColumn:)])
        return [_delegate tableView:self shouldSelectTableColumn:tableColumn];

    return YES;
}

-(BOOL)delegateShouldSelectRow:(int)row
{
    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)])
        return [_delegate tableView:self shouldSelectRow:row];

    return YES;
}


-(void)dataSourceSetObjectValue:object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    [_dataSource tableView:self setObjectValue:object forTableColumn:tableColumn row:row];
}

-(BOOL)abortEditing {
    [super abortEditing];
    [_editingCell release];
    _editingCell = nil;
    [self setNeedsDisplayInRect:_editingFrame];
    _editingFrame = NSMakeRect(-1,-1,-1,-1);
    _editedRow=-1;
    _editedColumn=-1;
    return NO;
}

-(void)textDidEndEditing:(NSNotification *)note {
    NSTableColumn *editedColumn = [_tableColumns objectAtIndex:_editedColumn];
    int textMovement = [[[note userInfo] objectForKey:@"NSTextMovement"] intValue];
    NSInteger numberOfRows=[self numberOfRows];
    
    [_editingCell endEditing:_currentEditor];

    if (_editedRow >= 0 && _editedRow < numberOfRows)
    {
        if([self dataSourceCanSetObjectValue])
        {
            [self dataSourceSetObjectValue:[_editingCell objectValue] forTableColumn:editedColumn row:_editedRow];
        }
        else
        {
            [[editedColumn _binderForBinding:@"value" create:NO] applyFromCell:_editingCell inRow:_editedRow];
        }
    }

    [self abortEditing];

// NSReturnTextMovement has lousy behaviour , fix.
// don't really need any of the text movement stuff, so we ignore it for now
    textMovement= NSIllegalTextMovement ;

    if (textMovement == NSReturnTextMovement) {
        int nextRow = _editedRow+1;

        if (nextRow >= numberOfRows)
            nextRow = 0;

        [self selectRow:nextRow byExtendingSelection:NO];
        [self editColumn:_editedColumn row:nextRow withEvent:[[self window] currentEvent] select:YES];
    }
    else if (textMovement == NSTabTextMovement) {
        int nextColumn = _editedColumn;
        int nextRow = _editedRow;

        do {
         nextColumn++;
         if(nextColumn>=[_tableColumns count]){
          nextColumn=0;
          nextRow++;
          if(nextRow>=numberOfRows)
           nextRow=0;
         }

         if([[_tableColumns objectAtIndex:nextColumn] isEditable])
          break;
        }while(YES);

        [self selectRow:nextRow byExtendingSelection:NO];
        [self editColumn:nextColumn row:nextRow withEvent:[[self window] currentEvent] select:YES];
    }
    else if (textMovement == NSBacktabTextMovement) {
        int prevColumn = _editedColumn-1;
        int prevRow = _editedRow;

        if (prevColumn < 0) {
            prevColumn = [_tableColumns count] - 1;
            prevRow -= 1;
            if (prevRow < 0)
                prevRow = numberOfRows - 1;
        }

        [self selectRow:prevRow byExtendingSelection:NO];
        [self editColumn:prevColumn row:prevRow withEvent:[[self window] currentEvent] select:YES];
    }
    else {
        _editedColumn = -1;
        _editedRow = -1;
    }
}

- (BOOL)delegateShouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if ([_delegate respondsToSelector:@selector(tableView:shouldEditTableColumn:row:)])
        return [_delegate tableView:self shouldEditTableColumn:tableColumn row:row];

    return YES;
}

-(void)updateCell:(NSCell *)sender {
    //blank
}

-(void)updateCellInside:(NSCell *)cell {
    //blank
}


-(void)drawRect:(NSRect)clipRect {
   NSRange visibleRows;
   NSInteger drawThisRow, numberOfRows=[self numberOfRows];
   
   [self drawBackgroundInClipRect:clipRect];
   
   if (numberOfRows > 0) {
      [self highlightSelectionInClipRect:clipRect];
      
      visibleRows = [self rowsInRect:clipRect];
      if(visibleRows.length>0){
         drawThisRow = visibleRows.location;
         while (drawThisRow < NSMaxRange(visibleRows) && drawThisRow<numberOfRows)
            [self drawRow:drawThisRow++ clipRect:clipRect];
      }     
   }
   
   if ([self drawsGrid])
      [self drawGridInClipRect:clipRect];
   
   if (_editingCell != nil && _editedColumn != -1 && _editedRow != -1)
   {
      [_backgroundColor setFill];
      NSRectFill(_editingBorder);
      [_editingCell drawWithFrame:_editingFrame inView:self];
      [[NSColor keyboardFocusIndicatorColor] setStroke];
      NSFrameRectWithWidth(_editingBorder, 2.0);
   }
   
   if(_draggingRow >= 0)
   {
      NSRect rowRect;
      [[NSColor blackColor] setStroke];
      if([self numberOfRows] == 0)
         [NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint([self bounds].size.width, 0)];
      else
      {
         if(_draggingRow == [self numberOfRows])
         {
            rowRect = NSIntersectionRect([self rectOfRow: _draggingRow-1],[self visibleRect]);
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0, rowRect.origin.y+_rowHeight) toPoint:NSMakePoint(rowRect.size.width, rowRect.origin.y+_rowHeight)];
         }
         else
         {
            rowRect = NSIntersectionRect([self rectOfRow: _draggingRow],[self visibleRect]);
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0, rowRect.origin.y) toPoint:NSMakePoint(rowRect.size.width, rowRect.origin.y)];
         }
      }
   }
}

-(BOOL)delegateSelectionShouldChange
{
    if ([_delegate respondsToSelector:@selector(selectionShouldChangeInTableView:)])
        return [_delegate selectionShouldChangeInTableView:self];
    
    return YES;
}

-(void)noteSelectionIsChanging {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionIsChangingNotification
                                                        object:self];
}

-(void)noteSelectionDidChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                        object:self];
}

-(void)noteColumnDidResizeWithOldWidth:(float)oldWidth
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewColumnDidResizeNotification
            object:self
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithFloat:oldWidth], @"NSOldWidth", nil]];
}

-(BOOL)dataSourceCanSetObjectValue
{
    return [_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)];
}

-(void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger numberOfRows=[self numberOfRows];
    
    _clickedColumn = [self columnAtPoint:location];
    _clickedRow = [self rowAtPoint:location];
    
    if (_clickedRow < 0) { // click beyond the end of the table
        [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [_selectedColumns removeAllObjects];
        return;
    }

    NSTableColumn *clickedColumnObject = [_tableColumns objectAtIndex:_clickedColumn];
    NSCell *clickedCell = [clickedColumnObject dataCellForRow:_clickedRow];
    if ([clickedCell isKindOfClass:[NSButtonCell class]])
    {
       [clickedCell setObjectValue:[self dataSourceObjectValueForTableColumn:clickedColumnObject row:_clickedRow]];
       [clickedCell setNextState];
       [self dataSourceSetObjectValue:[NSNumber numberWithInt:[clickedCell state]] forTableColumn:clickedColumnObject row:_clickedRow];
       [self setNeedsDisplay:YES];

       return;
    }

    // NSLog(@"click in col %d row %d", _clickedColumn, _clickedRow);
    // single click behavior
    if ([event clickCount] < 2) {
        if ([self delegateSelectionShouldChange] == NO) // provide delegate opportunity
            return;
        
        if ([event modifierFlags] & NSAlternateKeyMask) {       // extend/change selection
            if ([self isRowSelected:_clickedRow]) {         // deselect previously selected?
                if ([self allowsEmptySelection] || [self numberOfSelectedColumns] > 1)
                    [self deselectRow:_clickedRow];
            }
            else if ([self allowsMultipleSelection]) {
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:_clickedRow] byExtendingSelection:YES];  // add to selection
            }
        }
        else if ([event modifierFlags] & NSShiftKeyMask) {
            if ([self allowsMultipleSelection] && [self selectedRow] != -1) {
                NSInteger startRow = [self selectedRow];
                NSInteger endRow = _clickedRow;

                if (_clickedRow < startRow) {
                    endRow = startRow;
                    startRow = _clickedRow;
                }

                [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startRow, endRow)] byExtendingSelection:NO];
            }
            else
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:_clickedRow] byExtendingSelection:NO];
        }
        else {                              // normal selection, allow for dragging
                        BOOL dragging = NO; 
                        if([_dataSource respondsToSelector:@selector(tableView:writeRowsWithIndexes:toPasteboard:)]) 
                        { 
                                NSPoint currentPoint; 
                                do { 
                                        event = [_window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO]; 
                                        if([event type] == NSLeftMouseDragged) 
                                                event = [_window nextEventMatchingMask:NSLeftMouseUpMask| NSLeftMouseDraggedMask]; 
                                        else 
                                                break; 
                                        currentPoint = [self convertPoint:[event locationInWindow] fromView:nil]; 
                                        if(abs(location.x - currentPoint.x) > 5 || abs(location.y - currentPoint.y) > 5) 
                                        { 
                                                dragging = YES; 
                                                break; 
                                        } 
                                } while([event type] != NSLeftMouseUp); 
                        } 
                        if(dragging) 
                        { 
                                NSIndexSet *rowIndexes = [self selectedRowIndexes]; 
                                if([rowIndexes containsIndex: _clickedRow] == NO) 
                                        rowIndexes = [NSIndexSet indexSetWithIndex: _clickedRow]; 

                                NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard]; 
                                if([_dataSource tableView:self writeRowsWithIndexes:rowIndexes toPasteboard:pasteboard] == NO) 
                                        dragging = NO; 
                                else 
                                { 
                                        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(0,0)] autorelease]; 
                                        [self dragImage:image 
                                                                 at:NSMakePoint(0,0) 
                                                         offset:NSMakeSize(0,0) 
                                                          event:event 
                                                 pasteboard:pasteboard 
                                                         source:self 
                                                  slideBack:YES]; 
                                } 
                        } 

                        if(dragging == NO) 
                        { 
                                // normal selection, allow for dragging 
                                int firstClickedRow = _clickedRow; 

                                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:_clickedRow] byExtendingSelection:NO];
                                if ([self allowsMultipleSelection] == YES) { 
                                        do { 
                                                NSPoint point; 
                                                int row; 

                                                event = [_window nextEventMatchingMask:NSLeftMouseUpMask| NSLeftMouseDraggedMask]; 
                                                point=[self convertPoint:[event locationInWindow] fromView:nil]; 

                                                row = [self rowAtPoint:point]; 
                                                if (row != -1) { 
                                                        // we need to smooth out the selection granularity. on my slow system, the mouse moves 
                                                        // too quickly for the NSEvents to show up for each row.. 
                                                        int startRow, endRow, i; 

                                                        if (firstClickedRow > row) { 
                                                                endRow = firstClickedRow; 
                                                                startRow = row; 
                                                        } 
                                                        else { 
                                                                startRow = firstClickedRow; 
                                                                endRow = row; 
                                                        } 

                                                        for (i = 0; i < numberOfRows; i++) { 
                                                                if (i >= startRow && i <= endRow) 
                                                                        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:YES];
                                                                else 
                                                                        [self deselectRow:i]; 
                                                        } 
                                                } 

                                                [self noteSelectionIsChanging]; 
                                        } while([event type] != NSLeftMouseUp); 
                                } 
                        } 
        }                 

        [self sendAction:[self action] to:[self target]];
    }
    else if ([event clickCount] == 2) { 
       // nb this logic was backwards previously 
       
       id binder=[[_tableColumns objectAtIndex:_clickedColumn] _binderForBinding:@"value" create:NO];
       BOOL interpretedAsEdit=NO;
       if ([[_tableColumns objectAtIndex:_clickedColumn] isEditable])
       {
          if ([self dataSourceCanSetObjectValue] ||
              [binder allowsEditingForRow:_clickedRow]) {
             if (_clickedColumn != -1 && _clickedRow != -1) {
                if([self delegateShouldEditTableColumn:[_tableColumns objectAtIndex:_clickedColumn]
                                                   row:_clickedRow]) {
                   interpretedAsEdit=YES;
                   [self editColumn:[self clickedColumn] row:_clickedRow withEvent:event select:YES];
                }
             }
          }
       }
       if(!interpretedAsEdit)
          [self sendAction:[self doubleAction] to:[self target]];
    }
}

-(void)_tightenUpColumn:(NSTableColumn *)column {
    NSInteger i,numberOfRows=[self numberOfRows];
    float minWidth = 0.0, width;

    for (i = 0; i < numberOfRows; ++i) {
        NSCell *dataCell = [column dataCellForRow:i];
        
        [dataCell setObjectValue:[self dataSourceObjectValueForTableColumn:column row:i]];
        width = [[dataCell attributedStringValue] size].width;
        if (width > minWidth)
            minWidth = width;
    }
    width = [[[column headerCell] attributedStringValue] size].width;
    if (width > minWidth)
        minWidth = width;

    [column setMinWidth:minWidth];
}

-(void)sizeToFit {
    int i, count=[_tableColumns count];

    for (i = 0; i < count; ++i) {
        NSTableColumn *column = [_tableColumns objectAtIndex:i];
        
        [self _tightenUpColumn:column];
        [column setWidth:[column minWidth]];
    }

    [self tile];
}

- (unsigned)draggingSourceOperationMaskForLocal:(BOOL)isLocal { 
        return NSDragOperationCopy; 

} 

- (int)_getDraggedRow:(id <NSDraggingInfo>)info { 
        NSPoint point = [self convertPoint:[info draggingLocation] fromView:nil]; 
        int row = point.y / _rowHeight; 
        if((int) point.y % (int) _rowHeight > (_rowHeight / 2)) 
                row++; 

        row = MIN([self numberOfRows], row); 

        return row; 

} 

- (unsigned)_validateDraggedRow:(id <NSDraggingInfo>)info { 
        BOOL result; 
        int proposedRow = [self _getDraggedRow:info]; 
        if((result = [_dataSource tableView:self validateDrop:info proposedRow:proposedRow proposedDropOperation:NSTableViewDropAbove])) 
                _draggingRow = proposedRow; 
        else 
                _draggingRow = -1; 
        [self display]; 

        return result; 

} 

- (unsigned)draggingEntered:(id <NSDraggingInfo>)sender { 
        int i; 
        for(i = 0; i < [[self _draggedTypes] count]; i++) 
        { 
                if ([[[sender draggingPasteboard] types] containsObject:[[self _draggedTypes] objectAtIndex: i]]) 
                        return [self _validateDraggedRow:sender]; 
        } 
        return NSDragOperationNone; 

} 

- (unsigned)draggingUpdated:(id <NSDraggingInfo>)sender { 
        int i; 
        for(i = 0; i < [[self _draggedTypes] count]; i++) 
        { 
                if ([[[sender draggingPasteboard] types] containsObject:[[self _draggedTypes] objectAtIndex: i]]) 
                        return [self _validateDraggedRow:sender]; 
        } 
        return NSDragOperationNone; 

} 

- (void)draggingExited:(id <NSDraggingInfo>)sender 
{ 
        _draggingRow = -1; 
        [self display]; 
} 

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender { 
        _draggingRow = -1; 
        [self display]; 
    return YES; 
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender { 
        return [_dataSource tableView:self acceptDrop:sender row:[self _getDraggedRow:sender] dropOperation:NSTableViewDropAbove]; 
} 

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@ %0x08lx tableColumns: %@>",
        [self class], self, _tableColumns];
}

-(void)_moveUp:(BOOL)up extend:(BOOL)extend {
    
    NSInteger rowToSelect = -1;
    
    if ([_selectedRowIndexes count] == 0)
        rowToSelect = 0;
    else if (up)
    {
        int first = [_selectedRowIndexes firstIndex];
        if (first > 0)
            rowToSelect = first-1;
        else if (!extend)
            rowToSelect = first;
    }
    else
    {
        int last = [_selectedRowIndexes lastIndex];
        if (last < [self numberOfRows]-1)
            rowToSelect = last+1;
        else if (!extend)
            rowToSelect = last;
    }
    
    if (rowToSelect != -1)
    {
        [self selectRow:rowToSelect byExtendingSelection:extend];   
        [self scrollRowToVisible:rowToSelect];
    }
}

-(void)moveUp:sender {
   [self _moveUp:YES extend:NO];
}

-(void)moveUpAndModifySelection:sender {
   [self _moveUp:YES extend:YES];
}

-(void)moveDown:sender {
   [self _moveUp:NO extend:NO];
}

-(void)moveDownAndModifySelection:sender {
   [self _moveUp:NO extend:YES];
}

@end
