
typedef struct _O2ImageDestination *CGImageDestinationRef;

#import <CoreGraphics/CGImage.h>
#import <CoreGraphics/CGImageSource.h>
#import <CoreGraphics/CGDataConsumer.h>
#import <CoreFoundation/CFURL.h>

const CFStringRef kCGImageDestinationLossyCompressionQuality;
const CFStringRef kCGImageDestinationBackgroundColor;

CFTypeID CGImageDestinationGetTypeID(void);

CFArrayRef CGImageDestinationCopyTypeIdentifiers(void);

CGImageDestinationRef CGImageDestinationCreateWithData(CFMutableDataRef data,CFStringRef type,size_t imageCount,CFDictionaryRef options);
CGImageDestinationRef CGImageDestinationCreateWithDataConsumer(CGDataConsumerRef dataConsumer,CFStringRef type,size_t imageCount,CFDictionaryRef options);
CGImageDestinationRef CGImageDestinationCreateWithURL(CFURLRef url,CFStringRef type,size_t imageCount,CFDictionaryRef options);

void CGImageDestinationSetProperties(CGImageDestinationRef self,CFDictionaryRef properties);

void CGImageDestinationAddImage(CGImageDestinationRef self,CGImageRef image,CFDictionaryRef properties);
void CGImageDestinationAddImageFromSource(CGImageDestinationRef self,CGImageSourceRef imageSource,size_t index,CFDictionaryRef properties);

bool CGImageDestinationFinalize(CGImageDestinationRef self);

