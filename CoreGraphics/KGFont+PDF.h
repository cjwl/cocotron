#import "KGFont.h"

@class O2PDFObject,O2PDFContext;

@interface O2Font(PDF)
-(void)getMacRomanBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length;
-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context size:(CGFloat)size;
@end
