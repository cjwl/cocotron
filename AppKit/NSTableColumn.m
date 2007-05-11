/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
   Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <AppKit/AppKit.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

#import "NSKeyValueBinding/NSTableColumnBinder.h"
#import "NSKeyValueBinding/NSKVOBinder.h"

@implementation NSTableColumn

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    
    _identifier=[[keyed decodeObjectForKey:@"NSIdentifier"] retain];
    _headerCell=[[keyed decodeObjectForKey:@"NSHeaderCell"] retain];
    _dataCell=[[keyed decodeObjectForKey:@"NSDataCell"] retain];
    _width=[keyed decodeIntForKey:@"NSWidth"];
    _minWidth=[keyed decodeIntForKey:@"NSMinWidth"];
    _maxWidth=[keyed decodeIntForKey:@"NSMaxWidth"];
    _isResizable=[keyed decodeBoolForKey:@"NSIsResizeable"];
    _isEditable=[keyed decodeBoolForKey:@"NSIsEditable"];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }

   return self;
}

// NSOutlineView needs to programmatically instantiated as IB/WOF4 doesn't have an editor for it..
// also theoretically -dealloc could've crashed as the cell prototypes weren't initialized at all...
-(id)initWithIdentifier:(id)identifier {
        [self setIdentifier:identifier];

        _headerCell = [[NSTableHeaderCell alloc] initTextCell:@""];
        _dataCell = [[NSTextFieldCell alloc] initTextCell:@""];
    
    return self;
}

-(void)dealloc {
    [_identifier release];
    [_headerCell release];
    [_dataCell release];

    [super dealloc];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@ 0x%08lx identifier: \"%@\" headerCell: %@ dataCell: %@ width: %f minWidth: %f maxWidth: %f>",
        [self class], self, _identifier, _headerCell, _dataCell, _width, _minWidth, _maxWidth];
}

-(id)identifier {
    return _identifier;
}

-(NSTableView *)tableView {
    return _tableView;
}

-(NSCell *)headerCell {
    return _headerCell;
}

-(NSCell *)dataCell {
    return _dataCell;
}

-(float)width {
    return _width;
}

-(float)minWidth {
    return _minWidth;
}

-(float)maxWidth {
    return _maxWidth;
}

-(BOOL)isResizable {
    return _isResizable;
}

-(BOOL)isEditable {
    return _isEditable;
}

-(void)setIdentifier:(id)identifier {
    [_identifier release];
    _identifier = [identifier retain];
}

-(void)setTableView:(NSTableView *)tableView {
    _tableView = tableView;
}

-(void)setHeaderCell:(NSCell *)cell {
    [_headerCell release];
    _headerCell = [cell retain];
}

-(void)setDataCell:(NSCell *)cell {
    [_dataCell release];
    _dataCell = [cell retain];
}

-(void)setWidth:(float)width {
    if (width > _maxWidth)
        width = _maxWidth;
    else if (width < _minWidth)
        width = _minWidth;
    
    _width = width;
}

-(void)setMinWidth:(float)width {
    _minWidth = width;
}

-(void)setMaxWidth:(float)width {
    _maxWidth = width;
}

-(void)setResizable:(BOOL)flag {
    _isResizable = flag;
}

-(void)setEditable:(BOOL)flag {
    _isEditable = flag;
    [_dataCell setEditable:flag];
}

-(NSCell *)dataCellForRow:(int)row {
    return [self dataCell];
}

-(int)_rowCountFromBindings
{
	id binder=[self _binderForBinding:@"value" create:NO];
	if(!binder)
		return -1;
	return [binder count];
}

-(void)_boundValuesChanged
{
	id binders=[self _allUsedBinders];
	int count=[binders count];
	int i;
	for(i=0; i<count; i++)
	{
		id binder=[binders objectAtIndex:i];
		if([binder isKindOfClass:[_NSTableColumnBinder class]])
		{
			[binder updateRowValues];			
		}
	}	
}

-(void)prepareCell:(id)cell inRow:(int)row
{
	id binders=[self _allUsedBinders];
	int count=[binders count];
	int i;
	for(i=0; i<count; i++)
	{
		id binder=[binders objectAtIndex:i];
		if([binder isKindOfClass:[_NSTableColumnBinder class]])
		{
			[binder applyToCell:cell inRow:row];			
		}
	}	
}



+(Class)_binderClassForBinding:(id)binding
{
	if([binding isEqual:@"headerTitle"] ||
	   [binding isEqual:@"maxWidth"] ||
	   [binding isEqual:@"minWidth"] ||
	   [binding isEqual:@"width"])
		return [_NSKVOBinder class];
	return [_NSTableColumnBinder class];
}


@end
