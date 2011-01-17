//
//  DemoWindingRules.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoWindingRules.h"


@implementation DemoWindingRules

-(void)renderInContext:(CGContextRef)context {
   int i,numberOfCircles=6;
   
   CGContextScaleCTM(context,1.5,1);
   
   CGFloat y=0,yDelta=1.0/(kCGPathEOFillStroke+1);
   CGPathDrawingMode mode;
   
   for(mode=kCGPathFill;mode<=kCGPathEOFillStroke;mode++){
    CGFloat x=0.1,delta=0.1;
   
    CGContextSetRGBFillColor(context,0.25,0.5,0,1);
    CGContextSetRGBStrokeColor(context,0.4,0.4,0.4,0.5);
    CGContextSetLineWidth(context,0.01);
    for(i=0;i<numberOfCircles;i++){
     CGContextAddEllipseInRect(context,CGRectMake(x,y,delta,yDelta-yDelta*0.1));
     x+=delta/1.5;
    }
    CGContextDrawPath(context,mode);
    
    y+=yDelta;
   }
   
}

-(NSString *)description {
   return @"Winding Rules";
}

@end
