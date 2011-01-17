//
//  DemoPattern.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DemoPattern.h"


@implementation DemoPattern

-init {
   _image=[self createImageWithName:@"stankard"];

   return self;
}

static void drawPattern(void *info, CGContextRef ctxt){
   DemoPattern *self=(DemoPattern *)info;
   
   CGContextSetRGBFillColor(ctxt,1,0,0,0.5);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0,0,.5,.5));
   CGContextSetRGBFillColor(ctxt,1,0,1,0.5);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0.5,0.5,0.3,0.3));
   CGContextSetRGBFillColor(ctxt,0,0,1,0.5);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0.2,0.2,0.6,0.6));
   CGContextSetRGBFillColor(ctxt,0,1,1,0.5);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0,0.6,0.4,0.4));
   CGContextDrawImage(ctxt,CGRectMake(0.25,0.25,0.5,0.5),self->_image);
}

-(void)renderInContext:(CGContextRef)context {
   CGPatternCallbacks callbacks={0,drawPattern,NULL};
   CGPatternRef pattern=CGPatternCreate(self,CGRectMake(0,0,1,1),CGAffineTransformMakeScale(100,100),0.5,0.5,kCGPatternTilingNoDistortion,YES,&callbacks);
   CGColorSpaceRef colorSpace=CGColorSpaceCreatePattern(NULL);
   CGFloat components[1]={1};
   CGColorRef color=CGColorCreateWithPattern(colorSpace,pattern,components);

   CGContextSaveGState(context);

   CGContextSetFillColorWithColor(context,color);
   CGContextFillRect(context,CGRectMake(0,0,1,1));
   CGContextRestoreGState(context);

   CGColorRelease(color);
   CGColorSpaceRelease(colorSpace);
   CGPatternRelease(pattern);
}

-(NSString *)title {
   return @"CGPattern";
}

-(NSString *)description {
   return @"Overlapping function based pattern composed of ellipses and image";
}


@end
