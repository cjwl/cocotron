#import "KGColorSpace.h"

@class KGPDFObject,KGPDFContext;

@interface KGColorSpace(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGColorSpace *)colorSpaceFromPDFObject:(KGPDFObject *)object;
@end
