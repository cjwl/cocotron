#import "CoreGraphicsExport.h"

@class KGImageSource;
typedef KGImageSource *CGImageSourceRef;

#import "CGImage.h"

COREGRAPHICS_EXPORT CGImageSourceRef CGImageSourceCreateWithData(id data,id options);

COREGRAPHICS_EXPORT CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef self,size_t index,id options);
