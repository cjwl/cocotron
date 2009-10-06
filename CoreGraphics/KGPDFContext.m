/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFContext.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFPage.h"
#import "KGPDFContext.h"
#import "KGPDFxref.h"
#import "KGPDFxrefEntry.h"
#import "KGPDFObject_R.h"
#import "KGPDFObject_Name.h"
#import "KGPDFStream.h"
#import "KGPDFString.h"
#import "KGShading+PDF.h"
#import "KGImage+PDF.h"
#import "KGFont+PDF.h"
#import "O2MutablePath.h"
#import "O2Color.h"
#import "O2ColorSpace+PDF.h"
#import "KGGraphicsState.h"
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSPathUtilities.h>
#import "KGExceptions.h"

@implementation O2PDFContext

-initWithConsumer:(KGDataConsumer *)consumer mediaBox:(const CGRect *)mediaBox auxiliaryInfo:(NSDictionary *)auxiliaryInfo {
   [super init];
   
   _dataConsumer=[consumer retain];
   _mutableData=[[consumer mutableData] retain];
   _fontCache=[NSMutableDictionary new];
   _objectToRef=NSCreateMapTable(NSObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   _indirectObjects=[NSMutableArray new];
   _indirectEntries=[NSMutableArray new];
   _nextNumber=1;
   _xref=[[O2PDFxref alloc] initWithData:nil];
   [_xref setTrailer:[O2PDFDictionary pdfDictionary]];
   
   [self appendCString:"%PDF-1.3\n"];
   
   _info=[[O2PDFDictionary pdfDictionary] retain];
   [_info setObjectForKey:"Author" value:[O2PDFString pdfObjectWithString:NSFullUserName()]];
   [_info setObjectForKey:"Creator" value:[O2PDFString pdfObjectWithString:[[NSProcessInfo processInfo] processName]]];
   [_info setObjectForKey:"Producer" value:[O2PDFString pdfObjectWithCString:"THE COCOTRON http://www.cocotron.org O2PDFContext"]];
   [[_xref trailer] setObjectForKey:"Info" value:_info];
   
   _catalog=[[O2PDFDictionary pdfDictionary] retain];
   [[_xref trailer] setObjectForKey:"Root" value:_catalog];
   
   _pages=[[O2PDFDictionary pdfDictionary] retain];
   [_catalog setNameForKey:"Type" value:"Catalog"];
   [_catalog setObjectForKey:"Pages" value:_pages];
   [_pages setIntegerForKey:"Count" value:0];
   
   _kids=[[O2PDFArray pdfArray] retain];
   [_pages setNameForKey:"Type" value:"Pages"];
   [_pages setObjectForKey:"Kids" value:_kids];
   
   _page=nil;
   _categoryToNext=[NSMutableDictionary new];
   _contentStreamStack=[NSMutableArray new];
   
   NSString *title=[auxiliaryInfo objectForKey:kCGPDFContextTitle];
   
   if(title==nil)
    title=@"Untitled";
    
   [_info setObjectForKey:"Title" value:[O2PDFString pdfObjectWithString:title]];
    
   [self referenceForObject:_catalog];
   [self referenceForObject:_info];

   return self;
}

-(void)dealloc {
   [_dataConsumer release];
   [_mutableData release];
   [_fontCache release];
   NSFreeMapTable(_objectToRef);
   [_indirectObjects release];
   [_indirectEntries release];
   [_xref release];
   [_info release];
   [_catalog release];
   [_pages release];
   [_kids release];
   [_page release];
   [_categoryToNext release];
   [_textStateStack release];
   [_contentStreamStack release];
   [super dealloc];
}

-(unsigned)length {
   return [_mutableData length];
}

-(NSData *)data {
   return _mutableData;
}

-(void)appendData:(NSData *)data {
   [_mutableData appendData:data];
}

-(void)appendBytes:(const void *)ptr length:(unsigned)length {
   [_mutableData appendBytes:ptr length:length];
}

-(void)appendCString:(const char *)cString {
   [_mutableData appendBytes:cString length:strlen(cString)];
}

-(void)appendString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSASCIIStringEncoding];
   
   [_mutableData appendData:data];
}

-(void)appendFormat:(NSString *)format,... {
   NSString *string;
   va_list   arguments;

   va_start(arguments,format);
   
   string=[[NSString alloc] initWithFormat:format arguments:arguments];
   [self appendString:string];
   [string release];

   va_end(arguments);
}

-(void)appendPDFStringWithBytes:(const void *)bytesV length:(unsigned)length mutableData:(NSMutableData *)data {
   const unsigned char *bytes=bytesV;
   BOOL hex=NO;
   int  i;
   
   for(i=0;i<length;i++)
    if(bytes[i]<' ' || bytes[i]>=127 || bytes[i]=='(' || bytes[i]==')'){
     hex=YES;
     break;
    }
   
   if(hex){
    const char *hex="0123456789ABCDEF";
    int         i,bufCount,bufSize=256;
    char        buf[bufSize];
    
    [data appendBytes:"<" length:1];
    bufCount=0;
    for(i=0;i<length;i++){
     buf[bufCount++]=hex[bytes[i]>>4];
     buf[bufCount++]=hex[bytes[i]&0xF];
     
     if(bufCount==bufSize){
      [data appendBytes:buf length:bufCount];
      bufCount=0;
     }
    }
    [data appendBytes:buf length:bufCount];
    [data appendBytes:"> " length:2];
   }
   else {
    [data appendBytes:"(" length:1];
    [data appendBytes:bytes length:length];
    [data appendBytes:") " length:2];
   }
}

-(void)appendPDFStringWithBytes:(const void *)bytes length:(unsigned)length {
   [self appendPDFStringWithBytes:bytes length:length mutableData:_mutableData];
}

-(BOOL)hasReferenceForObject:(O2PDFObject *)object {
   O2PDFObject *result=NSMapGet(_objectToRef,object);
   
   return (result==nil)?NO:YES;
}

-(O2PDFObject *)referenceForObject:(O2PDFObject *)object {
   O2PDFObject *result=NSMapGet(_objectToRef,object);
   
   if(result==nil){
    O2PDFxrefEntry *entry=[O2PDFxrefEntry xrefEntryWithPosition:0 number:_nextNumber generation:0];

    result=[O2PDFObject_R pdfObjectWithNumber:_nextNumber generation:0 xref:_xref];
    NSMapInsert(_objectToRef,object,result);
    
    [_xref addEntry:entry object:object];
    [_indirectObjects addObject:object];
    [_indirectEntries addObject:entry];

    _nextNumber++;
   }
   
   return result;
}

-(void)encodePDFObject:(O2PDFObject *)object {
   if(![object isByReference] && ![self hasReferenceForObject:object])
    [object encodeWithPDFContext:self];
   else {
    O2PDFObject *ref=[self referenceForObject:object];
    
    [ref encodeWithPDFContext:self];
   }
}

-(O2PDFObject *)encodeIndirectPDFObject:(O2PDFObject *)object {
   O2PDFObject *result=[self referenceForObject:object];
   
   
   return result;
}

-(void)contentWithString:(NSString *)string {
   NSData *data=[string dataUsingEncoding:NSASCIIStringEncoding];
   
   [[[_contentStreamStack lastObject] mutableData] appendData:data];
}

-(void)contentWithFormat:(NSString *)format,... {
   NSString *string;
   va_list   arguments;

   va_start(arguments,format);
   
   string=[[NSString alloc] initWithFormat:format arguments:arguments];
   [self contentWithString:string];
   [string release];

   va_end(arguments);
}

-(void)contentPDFStringWithBytes:(const void *)bytes length:(unsigned)length {
   [self appendPDFStringWithBytes:bytes length:length mutableData:[[_contentStreamStack lastObject] mutableData]];
}

-(O2PDFObject *)referenceForFontWithName:(NSString *)name size:(float)size {
   return [(NSDictionary *)[_fontCache objectForKey:name] objectForKey:[NSNumber numberWithFloat:size]];
}

-(void)setReference:(O2PDFObject *)reference forFontWithName:(NSString *)name size:(float)size {
   NSMutableDictionary *sizes=[_fontCache objectForKey:name];
   
   if(sizes==nil){
    sizes=[NSMutableDictionary dictionary];
    [_fontCache setObject:sizes forKey:name];
   }
   
   [sizes setObject:reference forKey:[NSNumber numberWithFloat:size]];
}

-(O2PDFObject *)nameForResource:(O2PDFObject *)pdfObject inCategory:(const char *)categoryName {
   O2PDFDictionary *resources;
   O2PDFDictionary *category;
   
   if(![_page getDictionaryForKey:"Resources" value:&resources]){
    resources=[O2PDFDictionary pdfDictionary];
    [_page setObjectForKey:"Resources" value:resources];
   }
   
   if(![resources getDictionaryForKey:categoryName value:&category]){
    category=[O2PDFDictionary pdfDictionary];
    [resources setObjectForKey:categoryName value:category];
   }
   
   NSString *key=[NSString stringWithCString:categoryName];
   NSNumber *next=[_categoryToNext objectForKey:key];
   
   next=[NSNumber numberWithInt:(next==nil)?0:[next intValue]+1];
   [_categoryToNext setObject:next forKey:key];
   
   const char *objectName=[[NSString stringWithFormat:@"%s%d",categoryName,[next intValue]] cString];
   [category setObjectForKey:objectName value:pdfObject];
   
   return [O2PDFObject_Name pdfObjectWithCString:objectName];
}

-(void)beginPath {
   if(!O2PathIsEmpty(_path))
    [self contentWithString:@"n "];
   [super beginPath];
}

-(void)closePath {
   [super closePath];
   [self contentWithString:@"h "];
}

-(void)moveToPoint:(float)x:(float)y {
   [super moveToPoint:x:y];
   [self contentWithFormat:@"%g %g m ",x,y];
}

-(void)addLineToPoint:(float)x:(float)y {
   [super addLineToPoint:x:y];
   [self contentWithFormat:@"%g %g l ",x,y];
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   [super addCurveToPoint:cx1:cy1:cx2:cy2:x:y];
   [self contentWithFormat:@"%g %g %g %g %g %g c ",cx1,cy1,cx2,cy2,x,y];
}

-(void)addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y {
   [super addQuadCurveToPoint:(float)cx1:(float)cy1:(float)x:(float)y];
   [self contentWithFormat:@"%g %g %g %g v ",cx1,cy1,x,y];
}

-(void)addLinesWithPoints:(const CGPoint *)points count:(unsigned)count {
   [super addLinesWithPoints:points count:count];
   
   int i;
   
   for(i=0;i<count;i++)
    [self contentWithFormat:@"%g %g l ",points[i].x,points[i].y];
}

-(void)addRects:(const CGRect *)rects count:(unsigned)count {
   [super addRects:rects count:count];
   
   int i;
   
   for(i=0;i<count;i++)
    [self contentWithFormat:@"%g %g %g %g re ",rects[i].origin.x,rects[i].origin.y,rects[i].size.width,rects[i].size.height];
}

-(void)_pathContentFromOperator:(int)start {
   int                  i,numberOfElements=[_path numberOfElements];
   const unsigned char *elements=[_path elements];
   const CGPoint       *points=[_path points];
   int                  pi=0;
   CGAffineTransform    invertUserSpaceTransform=CGAffineTransformInvert([[self currentState] userSpaceTransform]);
   
   for(i=0;i<numberOfElements;i++){
    switch(elements[i]){
    
     case kCGPathElementMoveToPoint:{
       CGPoint point=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       
       if(i>=start)
        [self contentWithFormat:@"%g %g m ",point.x,point.y];
      }
      break;
      
     case kCGPathElementAddLineToPoint:{
       CGPoint point=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g l ",point.x,point.y];
      }
      break;

     case kCGPathElementAddCurveToPoint:{
       CGPoint c1=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint c2=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint end=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g %g %g %g %g c ",c1.x,c1.y,c2.x,c2.y,end.x,end.y];
      }
      break;
      
     case kCGPathElementCloseSubpath:
      [self contentWithString:@"h "];
      break;
      
     case kCGPathElementAddQuadCurveToPoint:{
       CGPoint c1=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);
       CGPoint end=CGPointApplyAffineTransform(points[pi++],invertUserSpaceTransform);

       if(i>=start)
        [self contentWithFormat:@"%g %g %g %g v ",c1.x,c1.y,end.x,end.y];
      }
      break;
    }
   }
   
}

-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   int start=[_path numberOfElements];
   
   [super addArc:x:y:radius:startRadian:endRadian:clockwise];
   [self _pathContentFromOperator:start];
}

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
   int start=[_path numberOfElements];
   [super addArcToPoint:x1:y1:x2:y2:radius];
   [self _pathContentFromOperator:start];
}

-(void)addEllipseInRect:(CGRect)rect {
   int start=[_path numberOfElements];
   [super addEllipseInRect:rect];
   [self _pathContentFromOperator:start];
}

-(void)addPath:(O2Path *)path {
   int start=[_path numberOfElements];
   [super addPath:path];
   [self _pathContentFromOperator:start];
   
}

-(void)saveGState {
   [super saveGState];
   [self contentWithString:@"q "];
}

-(void)restoreGState {
   [super restoreGState];
   [self contentWithString:@"Q "];
}

-(void)setCTM:(CGAffineTransform)matrix {
   [super setCTM:matrix];
   KGUnimplementedMethod();
}

-(void)concatCTM:(CGAffineTransform)matrix {
   [super concatCTM:matrix];
   [self contentWithFormat:@"%g %g %g %g %g %g cm ",matrix.a,matrix.b,matrix.c,matrix.d,matrix.tx,matrix.ty];
}

-(void)clipToPath {
   [super clipToPath];
   [self contentWithString:@"W "];
}

-(void)evenOddClipToPath {
   [super evenOddClipToPath];
   [self contentWithString:@"W* "];
}

-(void)clipToMask:(O2Image *)image inRect:(CGRect)rect {
   O2PDFObject *pdfObject=[image encodeReferenceWithContext:self];
   O2PDFObject *name=[self nameForResource:pdfObject inCategory:"XObject"];
   
   [self contentWithString:@"q "];
   [self translateCTM:rect.origin.x:rect.origin.y];
   [self scaleCTM:rect.size.width:rect.size.height];
   [self contentWithFormat:@"%@ Do ",name];
   [self contentWithString:@"Q "];
}

-(void)clipToRects:(const CGRect *)rects count:(unsigned)count {
   [self beginPath];
   [self addRects:rects count:count];
   [self clipToPath];
}

-(void)setStrokeColor:(O2Color *)color {
   const float *components=O2ColorGetComponents(color);
   
   switch([O2ColorGetColorSpace(color) type]){
   
    case O2ColorSpaceDeviceGray:
     [self contentWithFormat:@"%f G ",components[0]];
     break;
     
    case O2ColorSpaceDeviceRGB:
    case O2ColorSpacePlatformRGB:
     [self contentWithFormat:@"%f %f %f RG ",components[0],components[1],components[2]];
     break;
     
    case O2ColorSpaceDeviceCMYK:
     [self contentWithFormat:@"%f %f %f %f K ",components[0],components[1],components[2],components[3]];
     break;
   }
}

-(void)setFillColor:(O2Color *)color {
   const float *components=O2ColorGetComponents(color);
   
   switch([O2ColorGetColorSpace(color) type]){
   
    case O2ColorSpaceDeviceGray:
     [self contentWithFormat:@"%f g ",components[0]];
     break;
     
    case O2ColorSpaceDeviceRGB:
    case O2ColorSpacePlatformRGB:
     [self contentWithFormat:@"%f %f %f rg ",components[0],components[1],components[2]];
     break;
     
    case O2ColorSpaceDeviceCMYK:
     [self contentWithFormat:@"%f %f %f %f k ",components[0],components[1],components[2],components[3]];
     break;
   }
}

-(void)setPatternPhase:(CGSize)phase {
   [super setPatternPhase:phase];
}

-(void)setStrokePattern:(KGPattern *)pattern components:(const float *)components {
   [super setStrokePattern:pattern components:components];
}

-(void)setFillPattern:(KGPattern *)pattern components:(const float *)components {
   [super setFillPattern:pattern components:components];
}

-(void)setCharacterSpacing:(float)spacing {
   [super setCharacterSpacing:spacing];
   [self contentWithFormat:@"%g Tc ",spacing];
}

-(void)setTextDrawingMode:(int)textMode {
   [super setTextDrawingMode:textMode];   
}

-(void)setLineWidth:(float)width {
   [super setLineWidth:width];
   [self contentWithFormat:@"%g w ",width];
}

-(void)setLineCap:(int)lineCap {
   [super setLineCap:lineCap];
   [self contentWithFormat:@"%d J ",lineCap];
}

-(void)setLineJoin:(int)lineJoin {
   [super setLineJoin:lineJoin];
   [self contentWithFormat:@"%d j ",lineJoin];
}

-(void)setMiterLimit:(float)limit {
   [super setMiterLimit:limit];
   [self contentWithFormat:@"%g M ",limit];
}

-(void)setLineDashPhase:(float)phase lengths:(const float *)lengths count:(unsigned)count {
   [super setLineDashPhase:phase lengths:lengths count:count];
   
   O2PDFArray *array=[O2PDFArray pdfArray];
   int         i;
   
   for(i=0;i<count;i++)
    [array addNumber:lengths[i]];
   
   [self contentWithFormat:@"%@ %g d ",array,phase];
}

-(void)setRenderingIntent:(CGColorRenderingIntent)intent {
   [super setRenderingIntent:intent];
   
   const char *name;
   
   switch(intent){
   
    case kCGRenderingIntentAbsoluteColorimetric:
     name="AbsoluteColorimetric";
     break;
     
    default:
    case kCGRenderingIntentRelativeColorimetric:
     name="RelativeColorimetric";
     break;

    case kCGRenderingIntentSaturation:
     name="Saturation";
     break;
     
    case kCGRenderingIntentPerceptual:
     name="Perceptual";
     break;
   }
   [self contentWithFormat:@"/%s ri ",name];
}

-(void)setBlendMode:(int)mode {
   [super setBlendMode:mode];
   
}

-(void)setFlatness:(float)flatness {
   [super setFlatness:flatness];
   
   [self contentWithFormat:@"%g i ",flatness];
}

-(void)setInterpolationQuality:(CGInterpolationQuality)quality {
   [super setInterpolationQuality:quality];
}

-(void)setShadowOffset:(CGSize)offset blur:(float)blur color:(O2Color *)color {
   [super setShadowOffset:offset blur:blur color:color];
   
}

-(void)setShadowOffset:(CGSize)offset blur:(float)blur {
   [super setShadowOffset:offset blur:blur];
   
}

-(void)setShouldAntialias:(BOOL)yesOrNo {
   [super setShouldAntialias:yesOrNo];
   
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   switch(pathMode){
   
    case kCGPathFill:
     [self contentWithString:@"f "];
     break;
     
    case kCGPathEOFill:
     [self contentWithString:@"f* "];
     break;
     
    case kCGPathStroke:
     [self contentWithString:@"S "];
     break;

    case kCGPathFillStroke:
     [self contentWithString:@"B "];
     break;

    case kCGPathEOFillStroke:
     [self contentWithString:@"B* "];
     break;
         
   }
   O2PathReset(_path);
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
    unsigned char bytes[count];

   [[[self currentState] font] getMacRomanBytes:bytes forGlyphs:glyphs length:count];
   [self showText:bytes length:count];
}

-(void)showText:(const char *)text length:(unsigned)length {
   [self contentWithString:@"BT "];
   
   O2GState *state=[self currentState];
   O2PDFObject *pdfObject=[[state font] encodeReferenceWithContext:self size:[state pointSize]];
   O2PDFObject *name=[self nameForResource:pdfObject inCategory:"Font"];

   [self contentWithFormat:@"%@ %g Tf ",name,[[self currentState] pointSize]];

   CGAffineTransform matrix=[self textMatrix];
   [self contentWithFormat:@"%g %g %g %g %g %g Tm ",matrix.a,matrix.b,matrix.c,matrix.d,matrix.tx,matrix.ty];
   
   [self contentPDFStringWithBytes:text length:length];
   [self contentWithString:@" Tj "];
   
   [self contentWithString:@"ET "];
}

-(void)drawShading:(KGShading *)shading {
   O2PDFObject *pdfObject=[shading encodeReferenceWithContext:self];
   O2PDFObject *name=[self nameForResource:pdfObject inCategory:"Shading"];
    
   [self contentWithFormat:@"%@ sh ",name];
}

-(void)drawImage:(O2Image *)image inRect:(CGRect)rect {
   O2PDFObject *pdfObject=[image encodeReferenceWithContext:self];
   O2PDFObject *name=[self nameForResource:pdfObject inCategory:"XObject"];
   
   [self contentWithString:@"q "];
   [self translateCTM:rect.origin.x:rect.origin.y];
   [self scaleCTM:rect.size.width:rect.size.height];
   [self contentWithFormat:@"%@ Do ",name];
   [self contentWithString:@"Q "];
}

-(void)drawLayer:(KGLayer *)layer inRect:(CGRect)rect {
}

-(void)beginPage:(const CGRect *)mediaBox {
   O2PDFObject *stream;
   
   _page=[[O2PDFDictionary pdfDictionary] retain];
   
   [_page setNameForKey:"Type" value:"Page"];
   [_page setObjectForKey:"MediaBox" value:[O2PDFArray pdfArrayWithRect:*mediaBox]];

   stream=[O2PDFStream pdfStream];
   [_page setObjectForKey:"Contents" value:stream];
   [_contentStreamStack addObject:stream];
   
   [_page setObjectForKey:"Parent" value:[self referenceForObject:_pages]];
   
   [self referenceForObject:_page];
}

-(void)internIndirectObjects {
   int i;

   for(i=0;i<[_indirectObjects count];i++){ // do not cache 'count', can grow during encoding
    O2PDFxrefEntry *entry=[_indirectEntries objectAtIndex:i];
    O2PDFObject    *object=[_indirectObjects objectAtIndex:i];
    unsigned        position=[_mutableData length];
    
    [entry setPosition:position];
    [self appendFormat:@"%d %d obj\n",[entry number],[entry generation]];
    [object encodeWithPDFContext:self];
    [self appendFormat:@"endobj\n"];
   }
   [_indirectObjects removeAllObjects];
   [_indirectEntries removeAllObjects];
}

-(void)endPage {
   O2PDFInteger pageCount=0;
   
   [_contentStreamStack removeLastObject];
      
   [_kids addObject:_page];
   
   [_pages getIntegerForKey:"Count" value:&pageCount];
   pageCount++;
   [_pages setIntegerForKey:"Count" value:pageCount];
   
   [_page release];
   _page=nil;
   
   // Do not invoke [self internIndirectObjects], it's too early: do it only after -endPrinting,
   // else subsequent pages are not saved, because the 'Kids' array has already been encoded!
}

-(void)close {
   [self internIndirectObjects];
   [self encodePDFObject:(id)_xref];
}

-(void)deviceClipReset {
}

@end
