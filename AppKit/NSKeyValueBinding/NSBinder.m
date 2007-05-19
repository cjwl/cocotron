/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSBinder.h"
#import <AppKit/NSObject+BindingSupport.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSEnumerator.h>

#pragma mark -
#pragma mark Binding Option Strings

NSString *NSNoSelectionPlaceholderBindingOption=@"NSNoSelectionPlaceholder";
NSString *NSMultipleValuesPlaceholderBindingOption=@"NSMultipleValuesPlaceholder";
NSString *NSCreatesSortDescriptorBindingOption=@"NSCreatesSortDescriptors";
NSString *NSRaisesForNotApplicableKeysBindingOption=@"NSRaisesForNotApplicableKeys";

#pragma mark -
#pragma mark Binding Options

@implementation _NSBinder (BindingOptions)
-(BOOL)conditionallySetsEditable
{
	// FIX: needs to read from options
	if([source respondsToSelector:@selector(setEditable:)])
		return YES;
	return NO;
}

-(BOOL)conditionallySetsEnabled
{
	// FIX: needs to read from options
	if([source respondsToSelector:@selector(setEditable:)])
		return YES;
	return NO;
}

-(BOOL)allowsEditingMultipleValues
{
	// FIX: needs to read from options
	return YES;
}

-(BOOL)createsSortDescriptor
{
	return [[options objectForKey:NSCreatesSortDescriptorBindingOption] boolValue];
}


-(BOOL)raisesForNotApplicableKeys
{
	return [[options objectForKey:NSRaisesForNotApplicableKeysBindingOption] boolValue];
}
@end

#pragma mark -
#pragma mark Class implementation

@implementation _NSBinder

- (id)source {
    return [[source retain] autorelease];
}

- (void)setSource:(id)value {
    if (source != value) 
	{
        source = value;
		[self setBindingPath:[source _replacementKeyPathForBinding:binding]];
    }
}

- (id)destination 
{
    return [[destination retain] autorelease];
}

- (void)setDestination:(id)value 
{
    if (destination != value) 
	{
        destination = value;
    }
}

- (NSString*)keyPath {
    return [[keyPath retain] autorelease];
}

- (void)setKeyPath:(NSString*)value {
    if (keyPath != value) {
        [keyPath release];
        keyPath = [value copy];
    }
}

- (NSString*)binding {
    return [[binding retain] autorelease];
}

- (void)setBinding:(NSString*)value {
    if (binding != value) {
        [binding release];
        binding = [value copy];
		[self setBindingPath:[source _replacementKeyPathForBinding:binding]];
    }
}

-(id)defaultBindingOptionsForBinding:(id)thisBinding
{
	return [source _defaultBindingOptionsForBinding:thisBinding];
}

- (id)options {
    return [[options retain] autorelease];
}

- (void)setOptions:(id)value {
	[options release];
	options=[[self defaultBindingOptionsForBinding:binding] mutableCopy];
	if(value)
		[options setValuesForKeysWithDictionary:value];
}

- (id)bindingPath {
    return [[bindingPath retain] autorelease];
}

- (void)setBindingPath:(id)value {
    if (bindingPath != value) {
        [bindingPath release];
        bindingPath = [value copy];
    }
}

-(void)stopObservingChanges {
}

-(void)dealloc
{
	[self stopObservingChanges];
	[keyPath release];
	[binding release];
	[options release];
	[bindingPath release];
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
	return [binding compare:[other binding]];
}

-(id)peerBinders
{
	//NSRange numberAtEnd=[binding rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
	//											 options:NSBackwardsSearch|NSAnchoredSearch];
	// FIXME: total hack. assume only one digit at end, 1-9
	NSRange numberAtEnd=NSMakeRange([binding length]-1, 1);
	if([[binding substringWithRange:numberAtEnd] intValue]==0)
		return nil;
	
	if(numberAtEnd.location==NSNotFound)
		return nil;
	id baseName=[binding substringToIndex:numberAtEnd.location];
	
	id binders=[[source _allUsedBinders] objectEnumerator];
	id binder;
	id ret=[NSMutableArray array];
	while(binder=[binders nextObject])
	{
		if([[binder binding] hasPrefix:baseName])
			[ret addObject:binder];
	}
	return ret;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"%@: %@", [self className], binding];
}
@end


