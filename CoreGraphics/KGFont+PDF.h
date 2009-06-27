#import "KGFont.h"

@class KGPDFObject,KGPDFContext;

@interface KGFont(PDF)
-(void)getBytes:(unsigned char *)bytes forGlyphs:(const CGGlyph *)glyphs length:(unsigned)length;
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context size:(CGFloat)size;
@end
