/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSObjectController.h>
#import <Foundation/NSString.h>
#import <Foundation/NSKeyedUnarchiver.h>
#import <Foundation/NSKeyValueObserving.h>
#import "NSControllerSelectionProxy.h"

@interface NSObjectController(forward)
-(void)_selectionMayHaveChanged;
@end

@implementation NSObjectController
+(void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"editable", nil]
triggerChangeNotificationsForDependentKey:@"canAdd"];
	[self setKeys:[NSArray arrayWithObjects:@"editable", nil]
triggerChangeNotificationsForDependentKey:@"canInsert"];
	[self setKeys:[NSArray arrayWithObjects:@"editable", @"selection", nil]
triggerChangeNotificationsForDependentKey:@"canRemove"];
}

-(id)initWithCoder:(NSCoder*)coder
{
	if(self=[super init])
	{
		_objectClassName=[[coder decodeObjectForKey:@"NSObjectClassName"] retain];
		_editable = [coder decodeBoolForKey:@"NSEditable"];
		_automaticallyPreparesContent = [coder decodeBoolForKey:@"NSAutomaticallyPreparesContent"];
	}
	return self;
}

- (id)content {
    return [[_content retain] autorelease];
}

- (void)setContent:(id)value {
    if (_content != value) {
        [_content release];
        _content = [value copy];
		[self _selectionMayHaveChanged];
    }
}

-(NSArray *)selectedObjects
{
	return [NSArray arrayWithObject:_content];
}

-(id)selection
{
	return _selection;
}

-(id)_defaultNewObject
{
	return [[NSClassFromString(_objectClassName) alloc] init];

}

-(id)newObject
{
	return [self _defaultNewObject];
}


-(void)_selectionMayHaveChanged
{
	[self willChangeValueForKey:@"selection"];
	[_selection autorelease];
	_selection=[[NSControllerSelectionProxy alloc] initWithController:self];
	[self didChangeValueForKey:@"selection"];	
}
 
-(void)dealloc
{
	[_selection release];
	[_objectClassName release];
	[_content release];
	[super dealloc];
}


-(BOOL)canAdd;
{
	return [self isEditable];
}

-(BOOL)canInsert;
{
	return [self isEditable];
}

-(BOOL)canRemove;
{
	return [self isEditable] && [[self selectedObjects] count];
}

- (BOOL)isEditable
{
	return _editable;
}

-(void)setEditable:(BOOL)value
{
	_editable=value;
}

- (BOOL)automaticallyPreparesContent {
    return _automaticallyPreparesContent;
}

- (void)setAutomaticallyPreparesContent:(BOOL)value {
	_automaticallyPreparesContent = value;
}
@end
