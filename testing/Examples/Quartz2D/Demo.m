//
//  Demo.m
//  Quartz2D
//
//  Created by Christopher Lloyd on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Demo.h"


@implementation Demo

-(CGImageRef)createImageWithName:(NSString *)name {
   CGImageRef result;
   
   NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"png"];
   NSData   *data=[NSData dataWithContentsOfFile:path];
   
   CGImageSourceRef source=CGImageSourceCreateWithData((CFDataRef)data,nil);
   
   result=CGImageSourceCreateImageAtIndex(source,0,nil);
   
   CFRelease(source);
   
   return result;
}

-(void)renderInContext:(CGContextRef)context {
}

-(NSString *)title {
   return [self description];
}


@end
