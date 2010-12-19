//
//  Demo.h
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// all demos draw in a 1x1 box.

@interface Demo : NSObject {

}

-(CGImageRef)createImageWithName:(NSString *)name;

-(void)renderInContext:(CGContextRef)context;

-(NSString *)title;

@end
