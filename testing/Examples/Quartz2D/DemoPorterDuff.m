//
//  DemoPorterDuff.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoPorterDuff.h"


@implementation DemoPorterDuff

-(void)renderInContext:(CGContextRef)context {
   int i,numberOfModes=11;
   CGBlendMode modes[]={
    kCGBlendModeNormal,
    kCGBlendModeClear,
    kCGBlendModeCopy,
    kCGBlendModeSourceIn,	
    kCGBlendModeSourceOut,		
    kCGBlendModeSourceAtop,
    kCGBlendModeDestinationOver,
    kCGBlendModeDestinationIn,
    kCGBlendModeDestinationOut,
    kCGBlendModeDestinationAtop,
    kCGBlendModeXOR,
   };
   
   CGFloat height=1.0/numberOfModes;
   
   CGContextClearRect(context,CGRectMake(0,0,1,1));
   
   for(i=0;i<numberOfModes;i++){

    CGFloat j,numberOfBars=10;
    CGFloat barHeight=height/numberOfBars;
    CGFloat barWidth=1.0/numberOfBars;
    
    CGContextSetBlendMode(context,kCGBlendModeCopy);
    for(j=0;j<numberOfBars;j++){
     CGContextSetRGBFillColor(context,j/numberOfBars*0.7,j/numberOfBars*0.8,j/numberOfBars*0.9,j/numberOfBars);
     CGContextFillRect(context,CGRectMake(0,i*height+j*barHeight,1,barHeight));
    }
    
    CGContextSetBlendMode(context,modes[i]);
    for(j=0;j<numberOfBars;j++){
     CGContextSetRGBFillColor(context,j/numberOfBars*0.9,j/numberOfBars*0.7,j/numberOfBars*0.8,j/numberOfBars);
     CGContextFillRect(context,CGRectMake(j*barWidth,i*height,barWidth,height));
    }
   }
   
}

-(NSString *)description {
   return @"Porter Duff";
}

@end
