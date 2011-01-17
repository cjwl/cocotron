//
//  DemoGradient.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoGradient.h"


@implementation DemoGradient

void blackToRed(void *info,const float *in, float *output) {
   float C0[4]={0,0,0,1};
   float C1[4]={1,0,0,1};
   float x=in[0];
   int   i;
   
    for(i=0;i<4;i++)
     output[i]=C0[i]+x*(C1[i]-C0[i]);
}

void blackToGreen(void *info,const float *in, float *output) {
   float C0[4]={00,0,1,0.9};
   float C1[4]={0  ,1,0  ,0.1};
   float x=in[0];
   int   i;
   
    for(i=0;i<4;i++)
     output[i]=C0[i]+x*(C1[i]-C0[i]);
}

-(void)renderInContext:(CGContextRef)context {
   float         domain[2]={0,1};
   float         range[8]={0,1,0,1,0,1,0,1};
   CGFunctionCallbacks axialCallbacks={0,blackToRed,NULL};
   CGFunctionCallbacks radialCallbacks={0,blackToGreen,NULL};
   CGFunctionRef axialFunction=CGFunctionCreate(self,1,domain,4,range,&axialCallbacks);
   CGFunctionRef radialFunction=CGFunctionCreate(self,1,domain,4,range,&radialCallbacks);
   CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
   
   CGShadingRef  axial=CGShadingCreateAxial(colorSpace,CGPointMake(0,0),
      CGPointMake(1,1),axialFunction,YES,YES);
   CGShadingRef  radial=CGShadingCreateRadial(colorSpace,CGPointMake(0.5,0.75),0,
       CGPointMake(0.5,0.5),0.3,radialFunction,YES,YES);
       
       
   CGContextDrawShading(context,axial);
   CGContextDrawShading(context,radial);
   
   CGFunctionRelease(axialFunction);
   CGFunctionRelease(radialFunction);
   CGColorSpaceRelease(colorSpace);
   CGShadingRelease(radial);
   CGShadingRelease(axial);
}

-(NSString *)description {
   return @"Gradients";
}

@end
