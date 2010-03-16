/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSKVOBinder.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <AppKit/NSObject+BindingSupport.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSEnumerator.h>

static NSMutableDictionary *bindersForObjects=nil;
static NSDictionary *defaultBindingOptions=nil;
static NSMutableDictionary *defaultBindingOptionsCache=nil;

NSString * const NSObservedObjectKey=@"NSObservedObject";
NSString * const NSObservedKeyPathKey=@"NSObservedKeyPath";
NSString * const NSOptionsKey=@"NSOptions";

NSString * const NSNullPlaceholderBindingOption=@"NSNullPlaceholder"; // Do not change.
NSString * const NSNoSelectionPlaceholderBindingOption=@"NSNoSelectionPlaceholder";
NSString * const NSMultipleValuesPlaceholderBindingOption=@"NSMultipleValuesPlaceholder";
NSString * const NSCreatesSortDescriptorBindingOption=@"NSCreatesSortDescriptors";
NSString * const NSRaisesForNotApplicableKeysBindingOption=@"NSRaisesForNotApplicableKeys";
NSString * const NSAllowsEditingMultipleValuesSelectionBindingOption=@"NSAllowsEditingMultipleValuesSelection";
NSString * const NSValueTransformerNameBindingOption=@"NSValueTransformerName"; // Do not change.
NSString * const NSValueTransformerBindingOption=@"NSValueTransformerBinding";
NSString * const NSConditionallySetsEnabledBindingOption=@"NSConditionallySetsEnabled"; // Do not change.
NSString * const NSConditionallySetsEditableBindingOption=@"NSConditionallySetsEditable"; // Do not change.
NSString * const NSContinuouslyUpdatesValueBindingOption=@"NSContinuouslyUpdatesValue"; // Do not change.
NSString * const NSDisplayPatternBindingOption=@"NSDisplayPattern"; // Do not change.


@implementation NSObject (BindingSupport)

+(NSDictionary *)_defaultBindingOptionsForBinding:(NSString *)binding {

   if(defaultBindingOptions==nil) {
    NSBundle *bundle=[NSBundle bundleForClass:[_NSKVOBinder class]];
    NSString *path=[bundle pathForResource:@"defaultBindingOptions" ofType:@"plist"];
    
    if((defaultBindingOptions=[[NSDictionary alloc] initWithContentsOfFile:path])==nil)
     defaultBindingOptions=[NSDictionary new];
   }
   
   NSString     *className=NSStringFromClass(self);
   NSString     *bindingKey=[[className stringByAppendingString:@"."] stringByAppendingString:binding];
   NSDictionary *defaults=[defaultBindingOptionsCache objectForKey:bindingKey];
   
   if(defaults==nil){
    NSMutableDictionary *values;

   	if(self==[NSObject class])
     values=[NSMutableDictionary dictionary];
    else
     values=[[[[self superclass] _defaultBindingOptionsForBinding:binding] mutableCopy] autorelease];

    [values addEntriesFromDictionary:[defaultBindingOptions objectForKey:bindingKey]];
    
    if(defaultBindingOptionsCache==nil)
     defaultBindingOptionsCache=[NSMutableDictionary new];
     
    [defaultBindingOptionsCache setObject:values forKey:bindingKey];
    defaults=values;
   }

   return defaults;
}

-(NSDictionary *)_defaultBindingOptionsForBinding:(NSString *)binding {
	return [isa _defaultBindingOptionsForBinding:binding];
}


+(Class)_binderClassForBinding:(id)binding
{
	//return [_NSBinder class];
	return [_NSKVOBinder class];
}

-(id)_binderForBinding:(id)binding;
{
	return [self _binderForBinding:binding create:NO];
}

-(id)_binderForBinding:(id)binding create:(BOOL)create
{
	if(!bindersForObjects)
		bindersForObjects=[NSMutableDictionary new];
	
	id key = [NSValue valueWithNonretainedObject:self];
	id ownBinders = [bindersForObjects objectForKey:key];
	
	if(!ownBinders)
	{
		ownBinders = [NSMutableDictionary dictionary];
		[bindersForObjects setObject:ownBinders forKey:key];
	}
	
	id binder=[ownBinders objectForKey:binding];
	
	if(!binder && create)
	{
		binder = [[[isa _binderClassForBinding:binding] new] autorelease];
		[ownBinders setObject:binder forKey:binding];
	}

	return binder;
}

-(id)_replacementKeyPathForBinding:(id)binding
{
	if([binding isEqual:@"value"])
		return @"objectValue";
   // FIX: actually try and detect these
	if([binding hasPrefix:@"displayPatternValue"])
		return @"objectValue";

	return binding;
}

-(void)bind:(id)binding toObject:(id)destination withKeyPath:(NSString*)keyPath options:(NSDictionary*)options
{
	if(![isa _binderClassForBinding:binding]){
		return;
    }

	id binder=[self _binderForBinding:binding create:NO];

	if(binder)
		[binder unbind];
	else
		binder=[self _binderForBinding:binding create:YES];
	
	[binder setSource:self];
	[binder setDestination:destination];
	[binder setKeyPath:keyPath];
	[binder setBinding:binding];
	[binder setOptions:options];
	
	[binder bind];
}

-(void)unbind:(id)binding
{
	id key = [NSValue valueWithNonretainedObject:self];
	id ownBinders = [bindersForObjects objectForKey:key];
	
	id binder=[ownBinders objectForKey:binding];
	[binder unbind];
	
	[ownBinders removeObjectForKey:binding];
	if([ownBinders count]==0)
		[bindersForObjects removeObjectForKey:key];
}

-(void)_unbindAllBindings
{
	id key = [NSValue valueWithNonretainedObject:self];
	id ownBinders = [bindersForObjects objectForKey:key];
	id binder=nil;
	id en=[[ownBinders allValues] objectEnumerator];
	while((binder=[en nextObject]))
	{
		[binder unbind];
	}

	[bindersForObjects removeObjectForKey:key];
}

-(NSDictionary *)infoForBinding:(id)binding {
   _NSBinder    *binder=[self _binderForBinding:binding create:NO];
   NSDictionary *result=[NSDictionary dictionaryWithObjectsAndKeys:
      [binder destination],NSObservedObjectKey,
      [binder keyPath],NSObservedKeyPathKey,
      [binder options],NSOptionsKey,
      nil];
      
	return result;	
}

+(void)exposeBinding:(id)binding
{
	
}

-(NSArray *)_allUsedBinders {
   NSValue      *key=[NSValue valueWithNonretainedObject:self];
   NSDictionary *ownBinders=[bindersForObjects objectForKey:key];
   
   return [ownBinders allValues];
}

@end
