//
//  Quartz2DAppDelegate.h
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DemoView;

@interface Quartz2DAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSArray  *_allDemos;
    IBOutlet NSPopUpButton *_popupButton;
    IBOutlet DemoView *_demoView;
}

@property (assign) IBOutlet NSWindow *window;

-(void)selectDemo:sender;

@end
