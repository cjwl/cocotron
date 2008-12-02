#import "KGFontState+PDF.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFContext.h"
#import <Foundation/NSArray.h>

@implementation KGFontState(PDF)

-(KGPDFArray *)_pdfWidths {
   KGPDFArray   *result=[KGPDFArray pdfArray];
   unsigned char bytes[256];
   CGGlyph       glyphs[256];
   CGSize        advancements[256];
   int           i;
   
   for(i=0;i<256;i++)
    bytes[i]=i;
    
   [self getGlyphs:glyphs forBytes:bytes length:256];
   [self getAdvancements:advancements forGlyphs:glyphs count:256];

// FIX, probably not entirely accurate, you can get precise widths out of the TrueType data
   for(i=0;i<255;i++){
    KGPDFReal width=(advancements[i].width/_size)*1000;
    
    [result addNumber:width];
   }
   
   return result;
}

-(const char *)pdfFontName {
   return [[[_name componentsSeparatedByString:@" "] componentsJoinedByString:@","] cString];
}

-(KGPDFDictionary *)_pdfFontDescriptor {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

   [result setNameForKey:"Type" value:"FontDescriptor"];
   [result setNameForKey:"FontName" value:[self pdfFontName]];
   [result setIntegerForKey:"Flags" value:4];
   
   KGPDFReal bbox[4];
   
   bbox[0]=_metrics.boundingRect.origin.x;
   bbox[1]=_metrics.boundingRect.origin.y;
   bbox[2]=_metrics.boundingRect.size.width;
   bbox[3]=_metrics.boundingRect.size.height;
   [result setObjectForKey:"FontBBox" value:[KGPDFArray pdfArrayWithNumbers:bbox count:4]];
   [result setIntegerForKey:"ItalicAngle" value:_metrics.italicAngle];
   [result setIntegerForKey:"Ascent" value:_metrics.ascender];
   [result setIntegerForKey:"Descent" value:_metrics.descender];
   [result setIntegerForKey:"CapHeight" value:_metrics.capHeight];
   [result setIntegerForKey:"StemV" value:_metrics.stemV];
   [result setIntegerForKey:"StemH" value:_metrics.stemH];
   
   return result;
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFObject *reference=[context referenceForFontWithName:_name size:_size];
   
   if(reference==nil){
    KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

    [result setNameForKey:"Type" value:"Font"];
    [result setNameForKey:"Subtype" value:"TrueType"];
    [result setNameForKey:"BaseFont" value:[self pdfFontName]];
    [result setIntegerForKey:"FirstChar" value:0];
    [result setIntegerForKey:"LastChar" value:255];
    [result setObjectForKey:"Widths" value:[context encodeIndirectPDFObject:[self _pdfWidths]]];
    [result setObjectForKey:"FontDescriptor" value:[context encodeIndirectPDFObject:[self _pdfFontDescriptor]]];

    [result setNameForKey:"Encoding" value:"WinAnsiEncoding"];

    reference=[context encodeIndirectPDFObject:result];
    [context setReference:reference forFontWithName:_name size:_size];
   }
   
   return reference;
}

@end
