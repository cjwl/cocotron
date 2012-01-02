
#import <AppKit/AppKit.h>
#import "NSColorPickerWheel.h"

@implementation NSColorPickerWheel

-initWithPickerMask:(NSUInteger)mask colorPanel:(NSColorPanel *)colorPanel {
	
	if ((self = [super initWithPickerMask:mask colorPanel:colorPanel])) {
	}
    return self;
}

- (void)awakeFromNib
{
	_subview = currentView;
	NSColor* color = [[self colorPanel] color];
	
	float hue, saturation, brightness, alpha;
	
	[color getHue: &hue saturation: &saturation brightness: &brightness alpha: &alpha];
	
	[_wheelView setHue: hue * 360];
	[_wheelView setSaturation: brightness * 100];
	[_wheelView setBrightness: brightness * 100];
	
	[valueSlider setFloatValue: brightness * 100];
}

- (NSImage *)provideNewButtonImage
{
    return [NSImage imageNamed:@"NSColorPickerWheelIcon"];
}

- (void)colorPickerWheelView:(NSColorPickerWheelView*)view didSelectHue:(CGFloat)hue saturation:(CGFloat)saturation andBrightness:(CGFloat)brightness
{

	[[self colorPanel] setColor:[NSColor colorWithCalibratedHue: hue/359.0
													 saturation: saturation/100.0
													 brightness: brightness/100.0
														  alpha:[[self colorPanel] alpha]]];
}

@end
