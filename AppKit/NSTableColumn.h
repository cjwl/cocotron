/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

@class NSTableView, NSCell;

@interface NSTableColumn : NSObject {
   id           _identifier;
   NSTableView *_tableView;
   NSCell      *_headerCell;
   NSCell      *_dataCell;
   float        _width;
   float        _minWidth;
   float        _maxWidth;
   BOOL         _isResizable;
   BOOL         _isEditable;
}

-initWithIdentifier:identifier;

-identifier;
-(NSTableView *)tableView;
-(NSCell *)headerCell;
-(NSCell *)dataCell;

-(float)width;
-(float)minWidth;
-(float)maxWidth;
-(BOOL)isResizable;
-(BOOL)isEditable;

-(void)setIdentifier:identifier;
-(void)setTableView:(NSTableView *)tableView;
-(void)setHeaderCell:(NSCell *)cell;
-(void)setDataCell:(NSCell *)cell;

-(void)setWidth:(float)width;
-(void)setMinWidth:(float)width;
-(void)setMaxWidth:(float)width;
-(void)setResizable:(BOOL)flag;
-(void)setEditable:(BOOL)flag;

-(NSCell *)dataCellForRow:(int)row;

// internal
-(void)prepareCell:(id)cell inRow:(int)row;
-(int)_rowCountFromBindings;
-(void)_boundValuesChanged;

@end
