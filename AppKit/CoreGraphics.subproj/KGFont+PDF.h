#import "KGFont.h"

@class KGPDFObject,KGPDFContext;

@interface KGFont(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
@end
