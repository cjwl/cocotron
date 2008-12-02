#import "KGFontState.h"

@class KGPDFObject,KGPDFContext;

@interface KGFontState(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
@end
