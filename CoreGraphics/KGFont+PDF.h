#import "KGFont.h"

@class KGPDFObject,KGPDFContext;

@interface KGFont(PDF)
-(void)getMacRomanBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length;
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context size:(CGFloat)size;
@end
