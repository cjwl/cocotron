//
//  NSUserDefaultsControllerProxy.m
//  AppKit
//
//  Created by Johannes Fortmann on 26.09.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/NSUserDefaultsControllerProxy.h>
#import <AppKit/NSUserDefaultsController.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSKeyValueObserving.h>

@implementation NSUserDefaultsControllerProxy

-(id)initWithController:(NSUserDefaultsController*)controller {
   if(self=[super init])
   {
      _controller = controller;
      _cachedValues=[NSMutableDictionary new];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:[_controller defaults]];
   }
   return self;
}

-(void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [_cachedValues release];
   [super dealloc];
}

-(id)valueForKey:(NSString*)key
{
   id value=[_cachedValues objectForKey:key];
   if(!value)
   {
      value=[[_controller defaults] objectForKey:key];
      if(!value)
         value=[[_controller initialValues] objectForKey:key];
      
      if(value)
         [_cachedValues setObject:value forKey:key];
   }
   return value;
}

-(void)setValue:(id)value forKey:(NSString*)key
{
   [self willChangeValueForKey:key];
   [_cachedValues setObject:value forKey:key];
   [[_controller defaults] setObject:value forKey:key];
   [self didChangeValueForKey:key];
}

-(void)userDefaultsDidChange:(id)notification
{
   id defaults=[_controller defaults];
   for(NSString *key in [_cachedValues allKeys])
   {
      id val=[_cachedValues objectForKey:key];
      id newVal=[defaults objectForKey:key];
      if(![val isEqual:newVal])
      {
         [self willChangeValueForKey:key];
         
         [_cachedValues setObject:newVal forKey:key];

         [self didChangeValueForKey:key];
      }      
   }
}

@end
