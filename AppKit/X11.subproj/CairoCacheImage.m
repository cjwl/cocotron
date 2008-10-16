//
//  CairoCacheImage.m
//  AppKit
//
//  Created by Johannes Fortmann on 16.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/CairoCacheImage.h>


@implementation CairoCacheImage
-(id)initWithSurface:(cairo_surface_t*)surf
{
   if(self=[super init])
   {
      _surface=surf;
      cairo_surface_reference(_surface);
   }
   return self;
}

-(float)width
{
   return _size.width;
}

-(float)height
{
   return _size.height;
}

-(cairo_surface_t*)_cairoSurface
{
   return _surface;  
}

@synthesize size=_size;
@end
