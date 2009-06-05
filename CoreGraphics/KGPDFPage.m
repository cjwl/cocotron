/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFPage.h"
#import "KGPDFContentStream.h"
#import "KGPDFOperatorTable.h"
#import "KGPDFScanner.h"
#import "KGPDFDocument.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"

@implementation KGPDFPage

-initWithDocument:(KGPDFDocument *)document pageNumber:(int)pageNumber dictionary:(KGPDFDictionary *)dictionary {
   _document=[document retain];
   _pageNumber=pageNumber;
   _dictionary=[dictionary retain];
   return self;
}

-(void)dealloc {
   [_document release];
   [_dictionary release];
   [super dealloc];
}

+(KGPDFPage *)pdfPageWithDocument:(KGPDFDocument *)document pageNumber:(int)pageNumber dictionary:(KGPDFDictionary *)dictionary {
   return [[[self alloc] initWithDocument:document pageNumber:pageNumber dictionary:dictionary] autorelease];
}

-(KGPDFDocument *)document {
   return _document;
}

-(int)pageNumber {
   return _pageNumber;
}

-(KGPDFDictionary *)dictionary {
   return _dictionary;
}

BOOL KGPDFGetPageObjectForKey(KGPDFPage *page,const char *key,KGPDFObject **object){
   KGPDFDictionary *dictionary=[page dictionary];
   
   do{
    KGPDFObject *check;
    
    if([dictionary getObjectForKey:key value:&check]){
     *object=check;
     return YES;
    }
    
   }while([dictionary getDictionaryForKey:"Parent" value:&dictionary]);
   
   return NO;
}

BOOL KGPDFGetPageArrayForKey(KGPDFPage *page,const char *key,KGPDFArray **arrayp){
   KGPDFObject *check;
   
   if(!KGPDFGetPageObjectForKey(page,key,&check))
    return NO;
    
   return [check checkForType:kKGPDFObjectTypeArray value:arrayp];
}

-(BOOL)getRect:(CGRect *)rect forBox:(CGPDFBox)box {
   const char *string=NULL;
   KGPDFArray *array;
   KGPDFReal  *numbers;
   unsigned    count;
   
   switch(box){
    case kCGPDFMediaBox: string="MediaBox"; break;
    case kCGPDFCropBox:  string="CropBox"; break;
    case kCGPDFBleedBox: string="BleedBox"; break;
    case kCGPDFTrimBox:  string="TrimBox"; break;
    case kCGPDFArtBox:   string="ArtBox"; break;
   }
   
   if(string==NULL)
    return NO;
   if(!KGPDFGetPageArrayForKey(self,string,&array))
    return NO;
   
   if(![array getNumbers:&numbers count:&count])
    return NO;
    
   if(count!=4){
    NSZoneFree(NULL,numbers);
    return NO;
   }
   
   rect->origin.x=numbers[0];
   rect->origin.y=numbers[1];
   rect->size.width=numbers[2]-numbers[0];
   rect->size.height=numbers[3]-numbers[1];
   
   NSZoneFree(NULL,numbers);
   
   return YES;
}

-(int)rotationAngle {
   return 0;
}


-(CGAffineTransform)drawingTransformForBox:(CGPDFBox)box inRect:(CGRect)rect rotate:(int)degrees preserveAspectRatio:(BOOL)preserveAspectRatio {
   CGAffineTransform result=CGAffineTransformIdentity;
   CGRect boxRect;
   
   if([self getRect:&boxRect forBox:box]){   
    result=CGAffineTransformTranslate(result,-boxRect.origin.x,-boxRect.origin.y);
    result=CGAffineTransformTranslate(result,rect.origin.x,rect.origin.y);
    result=CGAffineTransformScale(result,rect.size.width/boxRect.size.width,rect.size.height/boxRect.size.height);
   }
   
   return result;
}

-(void)drawInContext:(KGContext *)context {
   KGPDFContentStream *contentStream=[[[KGPDFContentStream alloc] initWithPage:self] autorelease];
   KGPDFOperatorTable *operatorTable=[KGPDFOperatorTable renderingOperatorTable];
   KGPDFScanner       *scanner=[[[KGPDFScanner alloc] initWithContentStream:contentStream operatorTable:operatorTable info:context] autorelease];

   [scanner scan];
}

@end
