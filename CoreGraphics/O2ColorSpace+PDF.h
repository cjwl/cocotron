#import "O2ColorSpace.h"

@class O2PDFObject,O2PDFContext;

@interface O2ColorSpace(PDF)
-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context;
+(O2ColorSpaceRef)colorSpaceFromPDFObject:(O2PDFObject *)object;
@end
