//
//  DemoView.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoView.h"
#import "Demo.h"


@implementation DemoView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)setDemo:(Demo *)value {
   value=[value retain];
   [_demo release];
   _demo=value;
   [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   NSRect bounds=[self bounds];
   
   [[NSColor whiteColor] set];
   NSRectFill([self bounds]);
   
   CGContextSaveGState(context);
   
   CGContextScaleCTM(context,bounds.size.width,bounds.size.height);
   [_demo renderInContext:context];
   CGContextRestoreGState(context);
}

@end
