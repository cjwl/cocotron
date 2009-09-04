#import "O2ColorSpace.h"

@class KGPDFObject,KGPDFContext;

@interface O2ColorSpace(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(O2ColorSpaceRef)colorSpaceFromPDFObject:(KGPDFObject *)object;
@end
