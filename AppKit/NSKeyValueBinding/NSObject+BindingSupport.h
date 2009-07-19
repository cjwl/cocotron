/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <AppKit/AppKitExport.h>

@class NSDictionary,NSArray,NSString;

@interface NSObject (BindingSupport)
-(void)bind:(id)binding toObject:(id)destination withKeyPath:(NSString*)keyPath options:(NSDictionary*)options;
-(NSDictionary *)infoForBinding:(id)binding;
-(void)unbind:(id)binding;
+(void)exposeBinding:(id)binding;
@end

@interface NSObject (InternalBindingSupport)
// returns a dictionary with the default options for the specified binding
// the dictionaries are stored on a per-class basis in defaultBindingOptions.plist
// the binding parameter is currently ignored
-(id)_defaultBindingOptionsForBinding:(id)binding;

// return the class of a suitable binder for the respective binding
+(Class)_binderClassForBinding:(id)binding;

// return the respective binder or nil if unbound
-(id)_binderForBinding:(id)binding;

// return a suitable binder for the binding. if create is NO, only returns a binder
// if the binding is actually in use
-(id)_binderForBinding:(id)binding create:(BOOL)create;

// return a key path suitable for KVO to replace the generic binding name
// e.g. "value" -> "color" on NSColorWell
-(id)_replacementKeyPathForBinding:(id)binding;

// returns all binders used by the object
-(NSArray*)_allUsedBinders;

// unbinds all bindings used; should be called in -dealloc
-(void)_unbindAllBindings;

// the currently set value is a placeholder and should be displayed accordingly
-(id)_setCurrentValueIsPlaceholder:(BOOL)isPlaceholder;
@end

@interface NSObject (NSEditor)
-(BOOL)commitEditing;
-(void)discardEditing;
@end

@interface NSObject (NSEditorRegistration)
-(void)objectDidBeginEditing:editor;
-(void)objectDidEndEditing:editor;
@end

APPKIT_EXPORT NSString* NSObservedObjectKey;
APPKIT_EXPORT NSString* NSObservedKeyPathKey;
APPKIT_EXPORT NSString* NSOptionsKey;

// Binding option keys
APPKIT_EXPORT NSString *NSNullPlaceholderBindingOption;
APPKIT_EXPORT NSString *NSNoSelectionPlaceholderBindingOption;
APPKIT_EXPORT NSString *NSMultipleValuesPlaceholderBindingOption;
APPKIT_EXPORT NSString *NSCreatesSortDescriptorBindingOption;
APPKIT_EXPORT NSString *NSRaisesForNotApplicableKeysBindingOption;
APPKIT_EXPORT NSString *NSAllowsEditingMultipleValuesSelectionBindingOption;
APPKIT_EXPORT NSString *NSValueTransformerNameBindingOption;
APPKIT_EXPORT NSString *NSValueTransformerBindingOption;
APPKIT_EXPORT NSString *NSConditionallySetsEnabledBindingOption;
APPKIT_EXPORT NSString *NSConditionallySetsEditableBindingOption;
APPKIT_EXPORT NSString *NSContinuouslyUpdatesValueBindingOption;

