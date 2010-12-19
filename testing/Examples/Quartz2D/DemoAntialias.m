//
//  DemoAntialias.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoAntialias.h"


@implementation DemoAntialias

-(void)renderInContext:(CGContextRef)context {
   CGContextTranslateCTM(context,0.5,0.5);
   
   int i,numberOfRays=256;
   
   for(i=0;i<numberOfRays;i++){
    CGFloat fraction=i/(CGFloat)numberOfRays;
    
    CGContextRotateCTM(context,(M_PI*2)/numberOfRays);
    CGContextSetRGBStrokeColor(context,0,0,0,1);
    CGContextSetLineWidth(context,0.001);
    CGContextMoveToPoint(context,0,0);
    CGContextAddLineToPoint(context,0.5,1);
    CGContextStrokePath(context);
   }
}

-(NSString *)description {
   return @"Antialias Radial Pattern";
}


@end
