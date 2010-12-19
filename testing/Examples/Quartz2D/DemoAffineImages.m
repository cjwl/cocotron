//
//  DemoAffineImages.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoAffineImages.h"


@implementation DemoAffineImages

-init {
   _image=[self createImageWithName:@"pattern"];
   
   return self;
}

-(void)renderInContext:(CGContextRef)context {
   CGContextTranslateCTM(context,0.5,0.5);
   int i,numberOfImages=11;
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

   
   for(i=0;i<numberOfImages;i++){
    CGRect rect=CGRectMake(0.1,0.1,0.25+i*0.01,0.25-i*0.01);
    
    CGContextSetBlendMode(context,kCGBlendModeNormal);
    CGContextRotateCTM(context,(M_PI*2)/numberOfImages);
    CGContextSetRGBFillColor(context,i/(CGFloat)numberOfImages,0.7,1,0.5);
    CGContextFillRect(context,rect);
    rect=CGRectInset(rect,0.02,0.02);
    CGContextDrawImage(context,rect,_image);
   }
}

-(NSString *)description {
  return @"Affine Images";
}

@end
