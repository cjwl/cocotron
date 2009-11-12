#import <CoreGraphics/CGImageSource.h>
#import "KGImageSource.h"

CGImageSourceRef CGImageSourceCreateWithData(CFDataRef data,CFDictionaryRef options) {
   return [KGImageSource newImageSourceWithData:(NSData *)data options:(NSDictionary *)options];
}

CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef self,size_t index,CFDictionaryRef options) {
   return [self createImageAtIndex:index options:(NSDictionary *)options];
}

CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(CGImageSourceRef self, size_t index,CFDictionaryRef options) {
   return (CFDictionaryRef)[self copyPropertiesAtIndex:index options:(NSDictionary *)options];
}

COREGRAPHICS_EXPORT void CGImageSourceRelease(CGImageSourceRef self) {
   [self release];
}

