/* Copyright (c) 2008 Sijmen Mulder

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSGradient.h"
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSRaise.h>

void _NSGradientInterpolator(void *info, float const *inData, float *outData)
{
	NSGradient *gradient = (NSGradient *)info;
	int stepCount = [gradient numberOfColorStops];
	
	CGFloat prevPoint = 0, nextPoint = 1;
	NSColor *prevColor = nil, *nextColor = nil;
	
	int i;
	for (i = 0; i < stepCount; i++)
	{
		prevPoint = nextPoint;
		prevColor = nextColor;
		
		[gradient getColor:&nextColor location:&nextPoint atIndex:i];
		
		if (nextPoint > inData[0])
			break;
	}
	
	NSColor *outColor;
	if (!prevColor || nextPoint < inData[0])
	{
		outColor = nextColor;
	}
	else
	{
		CGFloat fraction = (inData[0] - prevPoint) / nextPoint;
		outColor = [prevColor blendedColorWithFraction:fraction ofColor:nextColor];
	}

	outData[0] = [outColor redComponent];
	outData[1] = [outColor greenComponent];
	outData[2] = [outColor blueComponent];
	outData[3] = [outColor alphaComponent];
}


@implementation NSGradient

- (void)dealloc
{
	[_colors release];
	[_stops release];
	
	[super dealloc];
}

#pragma mark Initialization

- (id)initWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor
{
	return [self initWithColors:[NSArray arrayWithObjects:startingColor, endingColor, nil]];
}

- (id)initWithColors:(NSArray *)colors
{
	self = [super init];
	if (!self)
		return nil;
		
	_colors = [colors retain];
	
	int colorCount = [colors count];
	_stops = [[NSMutableArray alloc] initWithCapacity:colorCount];
	
	int i;
	for (i = 0; i < colorCount; i++)
	{
		CGFloat stop = i / (CGFloat)1.0 * (colorCount - 1);
		[_stops addObject:[NSNumber numberWithFloat:stop]];
	}
	
	return self;
}

- (id)initWithColorsAndLocations:(NSColor *)firstColor, ...
{
	self = [super init];
	if (!self)
		return nil;
	
	_colors = [[NSMutableArray alloc] init];
	_stops = [[NSMutableArray alloc] init];
	
	va_list ap;
	va_start(ap, firstColor);
	BOOL first = YES;
	
	while (1)
	{
		NSColor *color;
		if (first)
		{
			color = firstColor;
			first = NO;
		}
		else
		{
			color = va_arg(ap, NSColor *);
		}
		
		if (!color)
			break;
		
		CGFloat stop = (CGFloat)va_arg(ap, double);
		
		[_colors addObject:color];
		[_stops addObject:[NSNumber numberWithFloat:stop]];
	}
	
	va_end(ap);
	
	return self;
}

-initWithColors:(NSArray *)colors atLocations:(const CGFloat *)locations colorSpace:(NSColorSpace *)colorSpace {
	NSUnimplementedMethod();
	return nil;
}

#pragma mark Primitive Drawing Methods

- (void)drawFromPoint:(NSPoint)startingPoint toPoint:(NSPoint)endingPoint options:(NSGradientDrawingOptions)options
{
	NSUnimplementedMethod();
}

- (void)drawFromCenter:(NSPoint)startCenter radius:(CGFloat)startRadius toCenter:(NSPoint)endCenter radius:(CGFloat)endRadius options:(NSGradientDrawingOptions)options
{
	NSUnimplementedMethod();
}

#pragma mark Drawing Linear Gradients

- (void)drawInRect:(NSRect)rect angle:(CGFloat)angle
{
	if ([_colors count] < 2 || 0 == rect.size.width)
		return;

	CGPoint start; //start coordinate of gradient
	CGPoint end; //end coordinate of gradient
	//tanSize is the rectangle size for atan2 operation. It is the size of the rect in relation to the offset start point
	CGPoint tanSize; 

	angle = (CGFloat)fmod(angle, 360);
	
	if (angle < 90)
	{
		start = CGPointMake(rect.origin.x, rect.origin.y);
		tanSize = CGPointMake(rect.size.width, rect.size.height);
	}
	else if (angle < 180)
	{
		start = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
		tanSize = CGPointMake(-rect.size.width, rect.size.height);
	}
	else if (angle < 270)
	{
		start = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
		tanSize = CGPointMake(-rect.size.width, -rect.size.height);
	}
	else
	{
		start = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
		tanSize = CGPointMake(rect.size.width, -rect.size.height);
	}
	
	
	CGFloat radAngle = angle / 180 * M_PI; //Angle in radians
	//The trig for this is difficult to describe without an illustration, so I'm attaching an illustration
	//to Cocotron issue number 438 along with this patch
	CGFloat distanceToEnd = cos(atan2(tanSize.y,tanSize.x) - radAngle) * 
		sqrt(rect.size.width * rect.size.width + rect.size.height * rect.size.height);
	end = CGPointMake(cos(radAngle) * distanceToEnd + start.x, sin(radAngle) * distanceToEnd + start.y);
		
	CGFunctionCallbacks callbacks = { 0, &_NSGradientInterpolator, NULL }; 
	CGFunctionRef function = CGFunctionCreate(self, 1, NULL, 4, NULL, &callbacks);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGShadingRef shading = CGShadingCreateAxial(colorSpace, start, end, function, NO, NO);
	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	CGContextClipToRect(context, rect);
	CGContextDrawShading(context, shading);
	CGContextRestoreGState(context);
	
	CGFunctionRelease(function);
	CGColorSpaceRelease(colorSpace);
	CGShadingRelease(shading);
}

- (void)drawInBezierPath:(NSBezierPath *)path angle:(CGFloat)angle
{
   NSRect rect=[path bounds];
   [NSGraphicsContext saveGraphicsState];

   [path addClip];
   [self drawInRect:rect angle:angle];  

   [NSGraphicsContext restoreGraphicsState];
}

#pragma mark Drawing Radial Gradients

- (void)drawInRect:(NSRect)rect relativeCenterPosition:(NSPoint)center
{
	NSUnimplementedMethod();
}

- (void)drawInBezierPath:(NSBezierPath *)path relativeCenterPosition:(NSPoint)center
{
	NSUnimplementedMethod();
}

#pragma mark Getting Gradient Properties

- (NSColorSpace *)colorSpace
{
	NSUnimplementedMethod();
	return nil;
}

- (int)numberOfColorStops
{
	return [_colors count];
}

- (void)getColor:(NSColor **)color location:(CGFloat *)location atIndex:(NSInteger)index
{
	if (location) *location = [[_stops objectAtIndex:index] floatValue];
	if (color)    *color = [[[_colors objectAtIndex:index] retain] autorelease];
}

@end
