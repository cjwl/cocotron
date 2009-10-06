#import "KGFunction.h"

@class O2PDFArray,O2PDFDictionary,O2PDFObject,O2PDFContext;

@interface O2Function(PDF)
-initWithDomain:(O2PDFArray *)domain range:(O2PDFArray *)range;  
-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context;
+(O2Function *)pdfFunctionWithDictionary:(O2PDFDictionary *)dictionary;
@end
