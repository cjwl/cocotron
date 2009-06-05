#import "KGShading.h"

@class KGPDFObject,KGPDFContext;

@interface KGShading(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGShading *)shadingWithPDFObject:(KGPDFObject *)object;
@end
