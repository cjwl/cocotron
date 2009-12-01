#import <CoreGraphics/CGImageSource.h>
#import "O2ImageSource.h"

@interface _O2ImageSource : O2ImageSource
@end

CGImageSourceRef CGImageSourceCreateWithData(CFDataRef data,CFDictionaryRef options) {
   return (CGImageSourceRef)[O2ImageSource newImageSourceWithData:data options:options];
}

CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef self,size_t index,CFDictionaryRef options) {
   return [self createImageAtIndex:index options:options];
}

CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(CGImageSourceRef self, size_t index,CFDictionaryRef options) {
   return (CFDictionaryRef)[self copyPropertiesAtIndex:index options:options];
}
