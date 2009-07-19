/* Copyright (c) 2009 Andy Balholm
   Portions copyright (c) 2007 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSCachingBinder.h"

#import <Foundation/Foundation.h>
#import <AppKit/NSController.h>
#import <AppKit/NSControl.h>
#import "NSObject+BindingSupport.h"

static void * NSCachingBinderChangeContext = (void *)@"NSCachingBinderChangeContext";

@implementation _NSCachingBinder

- (void)startObservingChanges
{
  [_destination addObserver:self
                 forKeyPath:_keyPath
                    options:0
                    context:NSCachingBinderChangeContext];
}

- (void)stopObservingChanges
{
  if (_bound)
    [_destination removeObserver:self forKeyPath:_keyPath];
}

- (void)dealloc
{
  [_cachedValue release];
  
  [super dealloc];
}

- (id)cachedValue
{
  return [[_cachedValue retain] autorelease];
}

- (void)setCachedValue:(id)value
{
  if (_cachedValue != value)
    {
      [_cachedValue release];
      _cachedValue = [value retain];
    }
}

- (void)showValue:(id)newValue
{
  if (![_cachedValue isEqual:newValue])
    {
      [self setCachedValue:newValue];
      
      BOOL editable=YES;
      BOOL isPlaceholder=NO;
      if(newValue==NSMultipleValuesMarker)
        {
          newValue=[self multipleValuesPlaceholder];
          if(![self allowsEditingMultipleValues])
            editable=NO;
          isPlaceholder=YES;
        }
      else if(newValue==NSNoSelectionMarker)
        {
          newValue=[self noSelectionPlaceholder];
          editable=NO;
          isPlaceholder=YES;
        }
      else if(!newValue || newValue==[NSNull null])
        {
          newValue=[self nullPlaceholder];
          isPlaceholder=YES;
        }
      
      if([self conditionallySetsEditable])
        [_source setEditable:editable];
      if([self conditionallySetsEnabled])
        [_source setEnabled:editable];
      
      [_source setValue:newValue
             forKeyPath:_bindingPath];
      
      if(isPlaceholder && [_source respondsToSelector:@selector(_setCurrentValueIsPlaceholder:)])
        [_source _setCurrentValueIsPlaceholder:YES];  
    }
}

- (void)applyValue:(id)newValue
{
  if (![_cachedValue isEqual:newValue])
    {
      [self setCachedValue:newValue];
      [_destination setValue:newValue forKeyPath:_keyPath];
    }
}

- (void)applyDisplayedValue
{
  [self applyValue:[_source valueForKeyPath:_bindingPath]];
}

- (id)destinationValue
{
  @try
  {
    return [_destination valueForKeyPath:_keyPath];
  }
  @catch(id ex)
  {
    if ([self raisesForNotApplicableKeys])
      [ex raise];
    else
      return NSNotApplicableMarker;
  }
  return nil; // To avoid compiler warnings
}

- (void)observeValueForKeyPath:(NSString *)kp 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  if (context == NSCachingBinderChangeContext)
    {
      [self showValue:[self destinationValue]];
    }
}

- (void)syncUp
{
  [self showValue:[self destinationValue]];
}

- (void)bind
{
	[self syncUp];
	[self startObservingChanges];
  _bound = YES;
}

- (void)unbind
{
	[self stopObservingChanges];
  _bound = NO;
}

@end
