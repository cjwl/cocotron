//
//  DemoView.h
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Demo;

@interface DemoView : NSView {
   Demo *_demo;
}

-(void)setDemo:(Demo *)value;

@end
