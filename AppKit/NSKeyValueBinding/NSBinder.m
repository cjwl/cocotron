/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSBinder.h"
#import "NSObject+BindingSupport.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSValueTransformer.h>
#import <AppKit/NSController.h>

#pragma mark -
#pragma mark Binding Options

@implementation _NSBinder (BindingOptions)
-(BOOL)conditionallySetsEditable
{
	return [[_options objectForKey:NSConditionallySetsEditableBindingOption] boolValue] && 
   [_source respondsToSelector:@selector(setEditable:)];
}

-(BOOL)conditionallySetsEnabled
{
	// FIX: needs to read from options
	if([_source respondsToSelector:@selector(setEnabled:)])
		return YES;
	return NO;
}

-(BOOL)allowsEditingMultipleValues
{
	return [[_options objectForKey:NSAllowsEditingMultipleValuesSelectionBindingOption] boolValue];
}

-(BOOL)createsSortDescriptor
{
	return [[_options objectForKey:NSCreatesSortDescriptorBindingOption] boolValue];
}


-(BOOL)raisesForNotApplicableKeys
{
	return [[_options objectForKey:NSRaisesForNotApplicableKeysBindingOption] boolValue];
}

-(id)multipleValuesPlaceholder
{
	id ret=[_options objectForKey:NSMultipleValuesPlaceholderBindingOption];
	if(!ret)
		return NSMultipleValuesMarker;
	return ret;
}

-(id)noSelectionPlaceholder
{
	id ret=[_options objectForKey:NSNoSelectionPlaceholderBindingOption];
	if(!ret)
		return NSNoSelectionMarker;
	return ret;
}

-(id)nullPlaceholder
{
	id ret=[_options objectForKey:NSNullPlaceholderBindingOption];
	if(!ret)
		return NSNoSelectionMarker;
	return ret;
}

-(id)valueTransformer
{
	id ret=[_options objectForKey:NSValueTransformerBindingOption];
	if(!ret)
	{
		ret=[_options objectForKey:NSValueTransformerNameBindingOption];
		if(!ret)
			return nil;
		ret=[NSValueTransformer valueTransformerForName:ret];
		[_options setObject:ret forKey:NSValueTransformerBindingOption];
	}
	return ret;	
}

-(id)transformedObject:(id)object
{
	id transformer=[self valueTransformer];
	if(!transformer)
		return object;
	return [transformer transformedValue:object];
}

-(id)reverseTransformedObject:(id)object
{
	id transformer=[self valueTransformer];
	if(!transformer)
		return object;
	return [transformer reverseTransformedValue:object];
}
@end

#pragma mark -
#pragma mark Class implementation

@implementation _NSBinder

- (id)source {
    return [[_source retain] autorelease];
}

- (void)setSource:(id)value {
    if (_source != value) 
	{
        _source = value;
		[self setBindingPath:[_source _replacementKeyPathForBinding:_binding]];
    }
}

- (id)destination 
{
    return [[_destination retain] autorelease];
}

- (void)setDestination:(id)value 
{
    if (_destination != value) 
	{
		[_destination release];
        _destination = [value retain];
    }
}

- (NSString*)keyPath {
    return [[_keyPath retain] autorelease];
}

- (void)setKeyPath:(NSString*)value {
    if (_keyPath != value) {
        [_keyPath release];
        _keyPath = [value copy];
    }
}

- (NSString*)binding {
    return [[_binding retain] autorelease];
}

- (void)setBinding:(NSString*)value {
    if (_binding != value) {
        [_binding release];
        _binding = [value copy];
		[self setBindingPath:[_source _replacementKeyPathForBinding:_binding]];
    }
}

-(id)defaultBindingOptionsForBinding:(id)thisBinding
{
	return [_source _defaultBindingOptionsForBinding:thisBinding];
}

- (id)options {
    return [[_options retain] autorelease];
}

- (void)setOptions:(id)value {
	[_options release];
	_options=[[self defaultBindingOptionsForBinding:_binding] mutableCopy];
	if(value)
		[_options setValuesForKeysWithDictionary:value];
}

- (id)bindingPath {
    return [[_bindingPath retain] autorelease];
}

- (void)setBindingPath:(id)value {
    if (_bindingPath != value) {
        [_bindingPath release];
        _bindingPath = [value copy];
    }
}

-(void)startObservingChanges {
   [_source addObserver:self
             forKeyPath:_bindingPath 
                options:0
                context:nil];   
}


-(void)stopObservingChanges {
   [_source removeObserver:self forKeyPath:_bindingPath];
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if(object==_source)
   {
      [self stopObservingChanges];

      //NSLog(@"bind event from %@.%@ alias %@ to %@.%@ (%@)", [_source className], _binding, _bindingPath, [_destination className], _keyPath, self);
      //NSLog(@"new value %@", [_source valueForKeyPath:_bindingPath]);
      
      [_destination setValue:[_source valueForKeyPath:_bindingPath]
                  forKeyPath:_keyPath];
      
      [self startObservingChanges];
   }
}

-(void)dealloc
{
	[self stopObservingChanges];
	[_keyPath release];
	[_binding release];
	[_options release];
	[_bindingPath release];
	[_destination retain];
	[super dealloc];
}

-(void)bind
{
}

-(void)unbind
{
}

-(NSComparisonResult)compare:(id)other
{
	// FIXME: needs to be a compare understanding that 11<20
	return [_binding compare:[other binding]];
}

-(id)peerBinders
{
	//NSRange numberAtEnd=[binding rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
	//											 options:NSBackwardsSearch|NSAnchoredSearch];
	// FIXME: total hack. assume only one digit at end, 1-9
	NSRange numberAtEnd=NSMakeRange([_binding length]-1, 1);
	if([[_binding substringWithRange:numberAtEnd] intValue]==0)
		return nil;
	
	if(numberAtEnd.location==NSNotFound)
		return nil;
	id baseName=[_binding substringToIndex:numberAtEnd.location];
	
	id binders=[[_source _allUsedBinders] objectEnumerator];
	id binder;
	id ret=[NSMutableArray array];
	while((binder=[binders nextObject])!=nil)
	{
		if([[binder binding] hasPrefix:baseName])
			[ret addObject:binder];
	}
	return ret;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"%@: %@, %@ -> %@", [self className], _binding, _source, _destination];
}
@end


