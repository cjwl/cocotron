#import "KGShading.h"

@class O2PDFObject,O2PDFContext;

@interface KGShading(PDF)
-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context;
+(KGShading *)shadingWithPDFObject:(O2PDFObject *)object;
@end
