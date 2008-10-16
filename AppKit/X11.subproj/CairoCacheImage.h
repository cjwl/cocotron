//
//  CairoCacheImage.h
//  AppKit
//
//  Created by Johannes Fortmann on 16.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <cairo.h>


@interface CairoCacheImage : NSObject {
   cairo_surface_t *_surface;
   NSSize _size;
}
@property (assign) NSSize size;
-(id)initWithSurface:(cairo_surface_t*)surf;
-(cairo_surface_t*)_cairoSurface;
@end
