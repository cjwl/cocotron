#import <CoreGraphics/CGImageDestination.h>
#import "O2ImageDestination.h"
#import "O2ImageSource.h"

const CFStringRef kCGImageDestinationLossyCompressionQuality=(CFStringRef)@"kCGImageDestinationLossyCompressionQuality";
const CFStringRef kCGImageDestinationBackgroundColor=(CFStringRef)@"kCGImageDestinationLossyCompressionQuality";

CFTypeID CGImageDestinationGetTypeID(void) {
   return O2ImageDestinationGetTypeID();
}

CFArrayRef CGImageDestinationCopyTypeIdentifiers(void) {
   return O2ImageDestinationCopyTypeIdentifiers();
}

CGImageDestinationRef CGImageDestinationCreateWithData(CFMutableDataRef data,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   return O2ImageDestinationCreateWithData(data,type,imageCount,options);
}

CGImageDestinationRef CGImageDestinationCreateWithDataConsumer(CGDataConsumerRef dataConsumer,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   return O2ImageDestinationCreateWithDataConsumer(dataConsumer,type,imageCount,options);
}

CGImageDestinationRef CGImageDestinationCreateWithURL(CFURLRef url,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   return O2ImageDestinationCreateWithURL(url,type,imageCount,options);
}

void CGImageDestinationSetProperties(CGImageDestinationRef self,CFDictionaryRef properties) {
   O2ImageDestinationSetProperties(self,properties);
}

void CGImageDestinationAddImage(CGImageDestinationRef self,CGImageRef image,CFDictionaryRef properties) {
   O2ImageDestinationAddImage(self,image,properties);
}

void CGImageDestinationAddImageFromSource(CGImageDestinationRef self,CGImageSourceRef imageSource,size_t index,CFDictionaryRef properties) {
   O2ImageDestinationAddImageFromSource(self,imageSource,index,properties);
}


bool CGImageDestinationFinalize(CGImageDestinationRef self) {
   return O2ImageDestinationFinalize(self);
}


