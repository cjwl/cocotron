//
//  CairoContext.m
//  AppKit
//
//  Created by Johannes Fortmann on 15.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/CairoContext.h>
#import <AppKit/X11Display.h>
#import <AppKit/KGPath.h>
#import <AppKit/KGColor.h>
#import <Foundation/NSException.h>
#import <AppKit/KGGraphicsState.h>

@implementation CairoContext
-(id)initWithWindow:(X11Window*)w
{
   NSRect frame=[w frame];

   KGGraphicsState  *initialState=[[[KGGraphicsState alloc] initWithDeviceTransform:CGAffineTransformIdentity] autorelease];
   
   if(self=[super initWithGraphicsState:initialState])
   {
      Display *dpy=[(X11Display*)[NSDisplay currentDisplay] display];
      _surface = cairo_xlib_surface_create(dpy, [w drawable], [w visual], frame.size.width, frame.size.height);
      [self setSize:NSMakeSize(frame.size.width, frame.size.height)];
   }
   return self;
}

-(void)dealloc
{
   cairo_surface_destroy(_surface);
   cairo_destroy(_context);
   [super dealloc];
}

-(void)setSize:(NSSize)size
{
   if(_context)
      cairo_destroy(_context);
   cairo_xlib_surface_set_size(_surface, size.width, size.height);
   _context = cairo_create(_surface);
}


-(void)deviceClipReset {
   cairo_reset_clip(_context);  
}

-(void)setCurrentColor:(KGColor*)color
{
   float *c=[color components];
   int count=[color numberOfComponents];

	switch(count)
   {
      case 1:
         cairo_set_source_rgba(_context,
                            c[0],
                            c[0],
                            c[0],
                            1.0);
         break;
      case 2:
         cairo_set_source_rgba(_context,
                               c[0],
                               c[0],
                               c[0],
                               c[1]);
         break;
         
      case 3:
         cairo_set_source_rgba(_context,
                               c[0],
                               c[1],
                               c[2],
                               1.0);
         break;
      case 4:
         cairo_set_source_rgba(_context,
                               c[0],
                               c[1],
                               c[2],
                               c[3]);
         break;
      default:
         NSLog(@"color with %i components", count);
         cairo_set_source_rgba(_context,
                               1.0,
                               0.0,
                               1.0,
                               1.0);
         break;
	}   
}


-(void)appendCTM
{
	CGAffineTransform ctm=[self ctm];
	cairo_matrix_t matrix={ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty};
   
   NSLog(@"%f, %f, %f, %f, %f, %f", ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty);

	cairo_transform(_context,&matrix);
}

-(void)appendFlip
{
   cairo_matrix_t matrix={1, 0, 0, -1, 0, cairo_xlib_surface_get_height(_surface)};

	cairo_transform(_context,&matrix);
}

-(void)synchronizeLineAttributes
{

   /*
	int i;
	cairo_set_line_width(_context, _lineWidth);
	cairo_set_line_cap(_context, _lineCap);
	cairo_set_line_join(_context, _lineJoin);
	cairo_set_miter_limit(_context, _miterLimit);
	
	double dashLengths[_dashLengthsCount];
	double totalLength=0.0;
	for(i=0; i<_dashLengthsCount; i++)
	{
		dashLengths[i]=(double)_dashLengths[i];
		totalLength=(double)_dashLengths[i];
	}
	cairo_set_dash (_context, dashLengths, _dashLengthsCount, _dashPhase/totalLength);*/
}



-(void)setCurrentPath:(KGPath*)path
{
	unsigned             opCount=[path numberOfElements];
	const unsigned char *operators=[path elements];
	unsigned             pointCount=[path numberOfPoints];
	const NSPoint       *points=[path points];
	unsigned             i,pointIndex;
	cairo_identity_matrix(_context);
	cairo_new_path(_context);
   [self appendFlip];
	
	pointIndex=0;
	for(i=0;i<opCount;i++){
		switch(operators[i]){
            
			case kCGPathElementMoveToPoint:{
				NSPoint point=points[pointIndex++];

				cairo_move_to(_context,point.x,point.y);
			}
				break;
				
			case kCGPathElementAddLineToPoint:{
				NSPoint point=points[pointIndex++];
				
				cairo_line_to(_context,point.x,point.y);
			}
				break;
				
			case kCGPathElementAddCurveToPoint:{
				NSPoint cp1=points[pointIndex++];
				NSPoint cp2=points[pointIndex++];
				NSPoint end=points[pointIndex++];
				
				cairo_curve_to(_context,cp1.x,cp1.y,
                           cp2.x,cp2.y,
                           end.x,end.y);
			}
				break;
				
			case kCGPathElementAddQuadCurveToPoint:{
				NSPoint cp1=points[pointIndex++];
				NSPoint cp2=points[pointIndex++];
				NSPoint end=points[pointIndex++];
				
				cairo_curve_to(_context,cp1.x,cp1.y,
                           cp2.x,cp2.y,
                           end.x,end.y);
			}
				break;
				
			case kCGPathElementCloseSubpath:
				cairo_close_path(_context);
				break;
		}
	}
}

-(void)deviceClipToNonZeroPath:(KGPath*)path
{
	[self setCurrentPath:path];
	cairo_set_fill_rule(_context, CAIRO_FILL_RULE_WINDING);
	cairo_clip(_context);
}


-(void)drawPath:(CGPathDrawingMode)mode
{
	[self setCurrentPath:(KGPath*)_path];
   
	switch(mode)
	{
		case kCGPathStroke:
         [self setCurrentColor:[self strokeColor]];
			[self synchronizeLineAttributes];
			cairo_stroke(_context);
			break;
			
		case kCGPathFill:	
         [self setCurrentColor:[self fillColor]];
			cairo_set_fill_rule(_context, CAIRO_FILL_RULE_WINDING);
			cairo_fill(_context);
			break;
			
		case kCGPathEOFill:
         [self setCurrentColor:[self fillColor]];
			cairo_set_fill_rule(_context, CAIRO_FILL_RULE_EVEN_ODD);
			cairo_fill(_context);
			break;
			
			
		case kCGPathFillStroke:
         [self setCurrentColor:[self fillColor]];
			cairo_set_fill_rule(_context, CAIRO_FILL_RULE_WINDING);
			cairo_fill(_context);
         [self setCurrentColor:[self strokeColor]];
			[self synchronizeLineAttributes];
			cairo_stroke(_context);
			break;
			
		case kCGPathEOFillStroke:
         [self setCurrentColor:[self fillColor]];
			cairo_set_fill_rule(_context, CAIRO_FILL_RULE_EVEN_ODD);
			cairo_fill(_context);
         [self setCurrentColor:[self strokeColor]];
			[self synchronizeLineAttributes];
			cairo_stroke(_context);
			break;
	}
}

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect {
   cairo_identity_matrix(_context);
   [self appendFlip];
   [self appendCTM];
   
   cairo_set_source_rgba(_context, 1.0, 0.0, 0.0, 0.5);
   cairo_new_path(_context);
   cairo_rectangle(_context, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
   cairo_clip(_context);
   cairo_paint(_context);
   
}

-(void)deviceSelectFontWithName:(NSString *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
   
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   cairo_show_glyphs(_context, glyphs, count);
}

-(void)flush {
   cairo_surface_flush(_surface);
}
@end
