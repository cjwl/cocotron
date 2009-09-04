#import "KGImage.h"

@class O2ColorSpace,KGDataProvider,KGPDFObject,KGPDFContext;

@interface KGImage(PDF)

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGImage *)imageWithPDFObject:(KGPDFObject *)object;

@end
