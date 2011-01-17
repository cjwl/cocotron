//
//  DemoJoinCapDash.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoJoinCapDash.h"


@implementation DemoJoinCapDash

static void drawLine(CGContextRef context){
   CGContextSetRGBStrokeColor(context,0,0,0,1);
   CGContextSetLineWidth(context,0.05);
   CGContextMoveToPoint(context,0.1,0.1);
   CGContextAddLineToPoint(context,0.5,0.5);
   CGContextAddLineToPoint(context,0.9,0.1);
   CGContextStrokePath(context);

   CGContextSetRGBStrokeColor(context,1,0,0,1);
   CGContextSetLineWidth(context,0.005);
   CGContextSetLineCap(context,kCGLineCapButt);
   CGContextSetLineJoin(context,kCGLineJoinMiter);
   CGContextMoveToPoint(context,0.1,0.1);
   CGContextAddLineToPoint(context,0.5,0.5);
   CGContextAddLineToPoint(context,0.9,0.1);
   CGContextStrokePath(context);
}

-(void)renderInContext:(CGContextRef)context {

   drawLine(context);
   CGContextTranslateCTM(context,0,0.1);
   
   CGContextSetLineCap(context,kCGLineCapRound);
   CGContextSetLineJoin(context,kCGLineJoinRound);
   drawLine(context);

   CGContextTranslateCTM(context,0,0.1);
   CGContextSetLineCap(context,kCGLineJoinBevel);
   CGContextSetLineJoin(context,kCGLineCapSquare);
   drawLine(context);

   CGContextTranslateCTM(context,0,0.1);
   CGFloat lengths[20];
   CGFloat delta=0.01;
   int i;
   
   for(i=0;i<20;i+=2){
    lengths[i]=delta/2;
    lengths[i+1]=delta;
    delta+=0.005;
   }
      
   CGContextSetLineDash(context,0,lengths,20);
   drawLine(context);
}

-(NSString *)description {
   return @"Join Cap Dash";
}

@end
