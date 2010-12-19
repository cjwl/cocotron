//
//  Quartz2DAppDelegate.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Quartz2DAppDelegate.h"
#import "Demo.h"
#import "DemoView.h"
#import <objc/runtime.h>

@implementation Quartz2DAppDelegate

@synthesize window;

NSArray *ClassGetSubclasses(Class parentClass){
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;

    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    NSInteger i;
    
    for ( i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil)
        {
            continue;
        }
        
        [result addObject:classes[i]];
    }

    free(classes);
    
    return result;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

   [_popupButton removeAllItems];
   
   NSArray *demoClasses=ClassGetSubclasses([Demo class]);

   NSMutableArray *demoInstances=[NSMutableArray array];
   
   for(Class demoClass in demoClasses)
    [demoInstances addObject:[[demoClass alloc] init]];
   
   _allDemos=[demoInstances copy];
   
   for(Demo *demo in _allDemos){
    [_popupButton addItemWithTitle:[demo title]];
   }
   
   [_demoView setDemo:[demoInstances objectAtIndex:0]];
}

-(void)selectDemo:sender {
   NSString *title=[sender titleOfSelectedItem];
   
   for(Demo *check in _allDemos)
    if([[check title] isEqual:title])
     [_demoView setDemo:check];
}


@end
