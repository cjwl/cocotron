/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/CairoContext.h>
#import <AppKit/X11Display.h>
#import <AppKit/KGPath.h>
#import <AppKit/KGColor.h>
#import <Foundation/NSException.h>
#import <AppKit/KGGraphicsState.h>
#import <AppKit/TTFFont.h>
#import <AppKit/KGColorSpace.h>
#import <AppKit/KGSurface.h>
#import <AppKit/CairoCacheImage.h>
#import <Foundation/NSException.h>

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

-(id)initWithSize:(NSSize)size
{
   KGGraphicsState  *initialState=[[[KGGraphicsState alloc] initWithDeviceTransform:CGAffineTransformIdentity] autorelease];
   
   if(self=[super initWithGraphicsState:initialState])
   {
      _surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size.width, size.height);
      _context = cairo_create(_surface);
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

   switch(cairo_surface_get_type(_surface))
   {
      case CAIRO_SURFACE_TYPE_XLIB:
         cairo_xlib_surface_set_size(_surface, size.width, size.height);
         break;
      case CAIRO_SURFACE_TYPE_IMAGE:
         cairo_surface_destroy(_surface);
         _surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size.width, size.height);
      default:
         ;
   }
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
   

	cairo_transform(_context,&matrix);
}

-(void)synchronizeFontCTM
{
	CGAffineTransform ctm=[[self currentState] textMatrix];
   id font=[[self currentState] font];
	float size=12.0;
	if(font)
		size=[font pointSize];
	ctm = CGAffineTransformScale(ctm, size, -size);
	
	cairo_matrix_t matrix={ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty};

	cairo_set_font_matrix(_context, &matrix);
}


-(void)appendFlip
{
   cairo_matrix_t matrix={1, 0, 0, -1, 0, [self size].height};

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

-(NSSize)size {
   switch(cairo_surface_get_type(_surface))
   {
      case CAIRO_SURFACE_TYPE_XLIB:
         return NSMakeSize(cairo_xlib_surface_get_width(_surface), cairo_xlib_surface_get_height(_surface));
      case CAIRO_SURFACE_TYPE_IMAGE:
         return NSMakeSize(cairo_image_surface_get_width(_surface), cairo_image_surface_get_height(_surface));
      default:
         return NSZeroSize;
   }
}

-(KGImage *)createImage {
   NSSize size=[self size];
   cairo_surface_t* img=cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size.width, size.height);
   
   cairo_t *ctx=cairo_create(img);
   
   cairo_set_source_surface(ctx, _surface, 0, 0);
   cairo_fill(ctx);
   
   cairo_destroy(ctx);
   
   id ret=[[CairoCacheImage alloc] initWithSurface:img];
   [ret setSize:size];
   
   cairo_surface_destroy(img);
   return ret;
}

-(void)drawImage:(id)image inRect:(CGRect)rect {

   BOOL shouldFreeImage=NO;
   cairo_surface_t *img=NULL;
   
   if([image respondsToSelector:@selector(_cairoSurface)])
	{
		img=[image _cairoSurface];
	}
	else
	{
      shouldFreeImage=YES;
		img=cairo_image_surface_create_for_data((void*)[image directBytes],
                                              CAIRO_FORMAT_ARGB32,
                                              [image width],
                                              [image height],
                                              [image bytesPerRow]);
	}
   
   
   NSAssert(img, nil);
   cairo_identity_matrix(_context);
   [self appendFlip];
   [self appendCTM];
   
   cairo_new_path(_context);
	cairo_rectangle(_context,
                   rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);  
   cairo_clip(_context);
   
   cairo_set_source_rgb(_context, 1.0, 1.0, 0.1);
   cairo_paint(_context);

	cairo_set_source_surface(_context, img, 0.0, 0.0);

	cairo_paint(_context);   
   
   if(shouldFreeImage)
      cairo_surface_destroy(img);
}

-(void)deviceSelectFontWithName:(NSString *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
   
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   TTFFont *font=(TTFFont*)[[self currentState] font];
   int i;
   cairo_glyph_t *cg=alloca(sizeof(cairo_glyph_t)*count);
   BOOL nominal;

   float x=0, y=0;
   for(i=0; i<count; i++)
   {
      NSPoint pos=[font positionOfGlyph:glyphs[i] precededByGlyph:CGNullGlyph isNominal:&nominal];
      
      cg[i].x=x;
      cg[i].y=y+pos.y;
      cg[i].index=glyphs[i];
      x+=pos.x;
   }
   
   
   cairo_font_face_t *face=(cairo_font_face_t *)cairo_ft_font_face_create_for_ft_face([font face], NULL);
   cairo_set_font_face(_context, face);
   cairo_set_font_size(_context, [font pointSize]);
   
   cairo_identity_matrix(_context);
   cairo_reset_clip(_context);
   [self appendFlip];

   [self appendCTM];
   [self synchronizeFontCTM];
   [self setCurrentColor:[self fillColor]];
   cairo_move_to(_context, 0, 0);
   
   cairo_show_glyphs(_context, cg, count);
   
   cairo_font_face_destroy(face);
}

-(void)flush {
   cairo_surface_flush(_surface);
}

-(cairo_surface_t*)_cairoSurface {
   return _surface;
}

-(void)drawContext:(CairoContext*)other
{
   cairo_identity_matrix(_context);
   cairo_reset_clip(_context);
   cairo_set_source_surface (_context, [other _cairoSurface], 0, 0);
	cairo_paint(_context);
}
@end
