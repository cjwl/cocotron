//
//  DemoSoftMask.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoSoftMask.h"


@implementation DemoSoftMask

-init {
   _image=[self createImageWithName:@"stankard"];
    uint8_t          *bytes=malloc(1);
    
    bytes[0]=128;
         
    CGDataProviderRef provider=CGDataProviderCreateWithData(NULL,bytes,1,NULL);
    _mask=CGImageMaskCreate(1,1,8,8,1,provider,NULL,YES);
   _maskedImage=CGImageCreateWithMask(_image,_mask);
   
   return self;
}

-(void)renderInContext:(CGContextRef)context {
   CGContextSetInterpolationQuality(context,kCGInterpolationHigh);
   CGContextDrawImage(context,CGRectMake(0,0,0.5,1),_image);
   CGContextDrawImage(context,CGRectMake(0.5,0,0.5,1),_maskedImage);
}

-(NSString *)description {
   return @"Image with Soft Mask";
}

@end
