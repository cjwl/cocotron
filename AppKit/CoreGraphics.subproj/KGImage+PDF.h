#import "KGImage.h"

@class KGColorSpace,KGDataProvider,KGPDFObject,KGPDFContext;

@interface KGImage(PDF)

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGImage *)imageWithPDFObject:(KGPDFObject *)object;

@end
