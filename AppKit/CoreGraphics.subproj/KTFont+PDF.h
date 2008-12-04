#import "KTFont.h"

@class KGPDFObject,KGPDFContext;

@interface KTFont(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
@end
