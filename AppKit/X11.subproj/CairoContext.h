//
//  CairoContext.h
//  AppKit
//
//  Created by Johannes Fortmann on 15.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/KGContext.h>
#import <cairo.h>
#import <X11/Xlib.h>
#import <cairo-xlib.h>
#import <AppKit/X11Window.h>

@interface CairoContext : KGContext {
   cairo_surface_t *_surface;
   cairo_t *_context;
}
-(id)initWithWindow:(X11Window*)w;
-(void)setSize:(NSSize)size;
@end
