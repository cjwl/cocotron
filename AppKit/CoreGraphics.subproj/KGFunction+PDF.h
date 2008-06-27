#import "KGFunction.h"

@class KGPDFArray,KGPDFDictionary,KGPDFObject,KGPDFContext;

@interface KGFunction(PDF)
-initWithDomain:(KGPDFArray *)domain range:(KGPDFArray *)range;  
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGFunction *)pdfFunctionWithDictionary:(KGPDFDictionary *)dictionary;
@end
