/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFOperators.h"
#import "KGPDFOperatorTable.h"
#import "KGPDFScanner.h"
#import "KGPDFContentStream.h"
#import "KGPDFObject.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFString.h"
#import "KGDataProvider.h"
#import "KGPDFFunction_Type2.h"
#import "KGPDFFunction_Type3.h"

#import "KGContext.h"
#import "O2Color.h"
#import "O2ColorSpace+PDF.h"
#import "KGImage+PDF.h"
#import "KGFunction+PDF.h"
#import "KGShading+PDF.h"
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

#import <stddef.h>

static O2Context *kgContextFromInfo(void *info) {
   return (O2Context *)info;
}

// closepath, fill, stroke
void O2PDF_render_b(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context closePath];
   [context fillAndStrokePath];
}

// fill, stroke
void O2PDF_render_B(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context fillAndStrokePath];
}

// closepath, eofill, stroke
void O2PDF_render_b_star(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context closePath];
   [context evenOddFillAndStrokePath];
}

// eofill, stroke
void O2PDF_render_B_star(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context evenOddFillAndStrokePath];
}

// Begin marked-content sequence with property list
void O2PDF_render_BDC(O2PDFScanner *scanner,void *info) {
   //NSLog(@"BDC");
}

// Begin inline image object
void O2PDF_render_BI(O2PDFScanner *scanner,void *info) {
   //NSLog(@"BI");
}

// Begin marked-content sequence
void O2PDF_render_BMC(O2PDFScanner *scanner,void *info) {
   //NSLog(@"BMC");
}

// Begin text object
void O2PDF_render_BT(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context setTextMatrix:CGAffineTransformIdentity];
   //NSLog(@"BT");
}

// Begin compatibility section
void O2PDF_render_BX(O2PDFScanner *scanner,void *info) {
   //NSLog(@"BX");
}

// curveto, Append curved segment to path, three control points
void O2PDF_render_c(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x1,y1,x2,y2,x3,y3;
   
   if(![scanner popNumber:&y3])
    return;
   if(![scanner popNumber:&x3])
    return;
   if(![scanner popNumber:&y2])
    return;
   if(![scanner popNumber:&x2])
    return;
   if(![scanner popNumber:&y1])
    return;
   if(![scanner popNumber:&x1])
    return;
   
   [context addCurveToPoint:x1:y1:x2:y2:x3:y3];
}

// concat, Concatenate matrix to current transformation matrix
void O2PDF_render_cm(O2PDFScanner *scanner,void *info) {
   O2Context        *context=kgContextFromInfo(info);
   CGAffineTransform matrix;
   
   if(![scanner popNumber:&matrix.ty])
    return;
   if(![scanner popNumber:&matrix.tx])
    return;
   if(![scanner popNumber:&matrix.d])
    return;
   if(![scanner popNumber:&matrix.c])
    return;
   if(![scanner popNumber:&matrix.b])
    return;
   if(![scanner popNumber:&matrix.a])
    return;
  
   [context concatCTM:matrix];
}


O2ColorSpaceRef colorSpaceFromScannerInfo(O2PDFScanner *scanner,void *info,const char *name) {
   O2ColorSpaceRef result=NULL;
   
   if(strcmp(name,"DeviceGray")==0)
    result=[[O2ColorSpace alloc] initWithDeviceGray];
   else if(strcmp(name,"DeviceRGB")==0)
    result=[[O2ColorSpace alloc] initWithDeviceRGB];
   else if(strcmp(name,"DeviceCMYK")==0)
    result=[[O2ColorSpace alloc] initWithDeviceCMYK];
   else {
    O2PDFContentStream *content=[scanner contentStream];
    O2PDFObject        *object=[content resourceForCategory:"ColorSpace" name:name];
    
    if(object==nil){
     NSLog(@"Unable to find color space named %s",name);
     return NULL;
    }
   
    return [O2ColorSpace colorSpaceFromPDFObject:object];
   }
   
   return result;
}

// setcolorspace, Set color space for stroking operations
void O2PDF_render_CS(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   const char     *name;
   O2ColorSpaceRef colorSpace;
   
   if(![scanner popName:&name])
    return;
    
   colorSpace=colorSpaceFromScannerInfo(scanner,info,name);
   
   if(colorSpace!=NULL){
    [context setStrokeColorSpace:colorSpace];
    [colorSpace release];
   }
}

// setcolorspace, Set color space for nonstroking operations
void O2PDF_render_cs(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   const char     *name;
   O2ColorSpaceRef colorSpace;
   
   if(![scanner popName:&name])
    return;
    
   colorSpace=colorSpaceFromScannerInfo(scanner,info,name);
   
   if(colorSpace!=NULL){
    [context setFillColorSpace:colorSpace];
    [colorSpace release];
   }
}

// setdash, Set line dash pattern
void O2PDF_render_d(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    phase;
   O2PDFArray  *array;
   int          i,count;
   
   if(![scanner popNumber:&phase])
    return;
   if(![scanner popArray:&array])
    return;
   count=[array count];
   {
    O2PDFReal lengths[count];
   
    for(i=0;i<count;i++)
     if(![array getNumberAtIndex:i value:lengths+i])
      return;
   
    [context setLineDashPhase:phase lengths:lengths count:count];
   }
}

// setcharwidth, Set glyph with in Type 3 font
void O2PDF_render_d0(O2PDFScanner *scanner,void *info) {
   //NSLog(@"d0");
}

// setcachedevice, Set glyph width and bounding box in Type 3 font
void O2PDF_render_d1(O2PDFScanner *scanner,void *info) {
   //NSLog(@"d1");
}

// Invoke named XObject
void O2PDF_render_Do(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFContentStream *content=[scanner contentStream];
   const char         *name;
   O2PDFObject        *resource;
   O2PDFStream        *stream;
   O2PDFDictionary    *dictionary;
   const char         *subtype;
   
   if(![scanner popName:&name])
    return;

   if((resource=[content resourceForCategory:"XObject" name:name])==nil)
    return;
  // NSLog(@"name=%s",name);
   
   if(![resource checkForType:kKGPDFObjectTypeStream value:&stream])
    return;
   
   dictionary=[stream dictionary];
   
   if([dictionary getNameForKey:"Type" value:&name])
    if(strcmp(name,"XObject")!=0)
     return;

   if(![dictionary getNameForKey:"Subtype" value:&subtype])
    return;
    
   if(strcmp(subtype,"Form")==0){
    O2PDFDictionary    *resources;
    O2PDFContentStream *contentStream;
    O2PDFOperatorTable *operatorTable;
    O2PDFScanner       *doScanner;
    O2PDFDictionary    *group;
    BOOL doIt=YES;
    
    if(![dictionary getDictionaryForKey:"Resources" value:&resources])
     resources=nil;
    
    if([dictionary getDictionaryForKey:"Group" value:&group]){
     const char *name;
     
     if([group getNameForKey:"S" value:&name]){
      if(strcmp(name,"Transparency")==0){
       ;//doIt=NO;
       //NSLog(@"dictionry=%@",dictionary);
      }
     }
    }
        
    contentStream=[[[O2PDFContentStream alloc] initWithStream:stream resources:resources parent:[scanner contentStream]] autorelease];
    operatorTable=[O2PDFOperatorTable renderingOperatorTable];
    doScanner=[[[O2PDFScanner alloc] initWithContentStream:contentStream operatorTable:operatorTable info:info] autorelease];

if(doIt)
    [doScanner scan];
   }
   else if(strcmp(subtype,"Image")==0){
    O2Image *image=[O2Image imageWithPDFObject:stream];
    
    if(image!=NULL){
     [context drawImage:image inRect:CGRectMake(0,0,1,1)];
    }

    if(image!=NULL)
     [image release];
   }
   else if(strcmp(subtype,"PS")==0){
    NSLog(@"PS");
   }
   else {
    NSLog(@"Unknown subtype %s",subtype);
   }
}

// Define marked-content point with property list
void O2PDF_render_DP(O2PDFScanner *scanner,void *info) {
   //NSLog(@"DP");
}

// End inline image object
void O2PDF_render_EI(O2PDFScanner *scanner,void *info) {
   //NSLog(@"EI");
}

// End marked-content sequence
void O2PDF_render_EMC(O2PDFScanner *scanner,void *info) {
   //NSLog(@"EMC");
}

// End text object
void O2PDF_render_ET(O2PDFScanner *scanner,void *info) {
   //NSLog(@"ET");
}

// End compatibility section
void O2PDF_render_EX(O2PDFScanner *scanner,void *info) {
   //NSLog(@"EX");
}

// fill, fill path using nonzero winding number rule
void O2PDF_render_f(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context fillPath];
}

// fill, fill path using nonzero winding number rule (obsolete)
void O2PDF_render_F(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context fillPath];
}

// eofill, fill path using even-odd rule
void O2PDF_render_f_star(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context evenOddFillPath];
}

// setgray, set gray level for stroking operations
void O2PDF_render_G(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    gray;
   
   if(![scanner popNumber:&gray])
    return;
   
   [context setGrayStrokeColor:gray];
}

// setgray, set gray level for nonstroking operations
void O2PDF_render_g(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    gray;
   
   if(![scanner popNumber:&gray])
    return;
   
   [context setGrayFillColor:gray];
}

// Set parameters from graphics state parameter dictionary
void O2PDF_render_gs(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFContentStream *content=[scanner contentStream];
   O2PDFObject        *resource;
   O2PDFDictionary    *graphicsState;
   const char         *name;
   O2PDFReal           number;
   O2PDFInteger        integer;
   O2PDFArray         *array;
   O2PDFDictionary    *dictionary;
   O2PDFBoolean        boolean;
   
   if(![scanner popName:&name])
    return;
    
   if((resource=[content resourceForCategory:"ExtGState" name:name])==nil)
    return;
   
   if(![resource checkForType:kKGPDFObjectTypeDictionary value:&graphicsState])
    return;
   
   //NSLog(@"gs=%@",graphicsState);
   
   if([graphicsState getNameForKey:"Type" value:&name])
    if(strcmp(name,"ExtGState")!=0)
     return;

   if([graphicsState getNumberForKey:"LW" value:&number])
    [context setLineWidth:number];
   if([graphicsState getIntegerForKey:"LC" value:&integer])
    [context setLineCap:integer];
   if([graphicsState getIntegerForKey:"LJ" value:&integer])
    [context setLineJoin:integer];
   if([graphicsState getNumberForKey:"ML" value:&number])
    [context setMiterLimit:number];
   if([graphicsState getArrayForKey:"D" value:&array]){
   }
   if([graphicsState getNameForKey:"RI" value:&name]){
   }
   if([graphicsState getBooleanForKey:"OP" value:&boolean]){
   }
   if([graphicsState getBooleanForKey:"op" value:&boolean]){
   }
   if([graphicsState getIntegerForKey:"OPM" value:&integer]){
   }
   if([graphicsState getArrayForKey:"Font" value:&array]){
   }
   if([graphicsState getDictionaryForKey:"BG" value:&dictionary]){ // functions are streams too
   }
   
   if([graphicsState getNameForKey:"BM" value:&name]){
    if(strcmp(name,"Normal")==0)
     [context setBlendMode:kCGBlendModeNormal];
    else if(strcmp(name,"Multiply")==0)
     [context setBlendMode:kCGBlendModeMultiply];
    else if(strcmp(name,"Screen")==0)
     [context setBlendMode:kCGBlendModeScreen];
    else if(strcmp(name,"Overlay")==0)
     [context setBlendMode:kCGBlendModeOverlay];
    else if(strcmp(name,"Darken")==0)
     [context setBlendMode:kCGBlendModeDarken];
    else if(strcmp(name,"Lighten")==0)
     [context setBlendMode:kCGBlendModeLighten];
    else if(strcmp(name,"ColorDodge")==0)
     [context setBlendMode:kCGBlendModeColorDodge];
    else if(strcmp(name,"ColorBurn")==0)
     [context setBlendMode:kCGBlendModeColorBurn];
    else if(strcmp(name,"HardLight")==0)
     [context setBlendMode:kCGBlendModeHardLight];
    else if(strcmp(name,"SoftLight")==0)
     [context setBlendMode:kCGBlendModeSoftLight];
    else if(strcmp(name,"Difference")==0)
     [context setBlendMode:kCGBlendModeDifference];
    else if(strcmp(name,"Exclusion")==0)
     [context setBlendMode:kCGBlendModeExclusion];
    else if(strcmp(name,"Hue")==0)
     [context setBlendMode:kCGBlendModeHue];
    else if(strcmp(name,"Saturation")==0)
     [context setBlendMode:kCGBlendModeSaturation];
    else if(strcmp(name,"Color")==0)
     [context setBlendMode:kCGBlendModeColor];
    else if(strcmp(name,"Luminosity")==0)
     [context setBlendMode:kCGBlendModeLuminosity];
    else
     NSLog(@"Unknown blend mode %s",name);
   }
   
   if([graphicsState getNumberForKey:"FL" value:&number]){
   }
   if([graphicsState getNumberForKey:"SM" value:&number]){
   }
   if([graphicsState getBooleanForKey:"SA" value:&boolean]){
   }
   if([graphicsState getNumberForKey:"CA" value:&number]){
    [context setStrokeAlpha:number];
   }
   if([graphicsState getNumberForKey:"ca" value:&number]){
    [context setFillAlpha:number];
   }
}

// closepath
void O2PDF_render_h(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context closePath];
}

// setflat, Set flatness tolerance
void O2PDF_render_i(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    flatness;
   
   if(![scanner popNumber:&flatness])
    return;

   [context setFlatness:flatness];
}

// Begin inline image data
void O2PDF_render_ID(O2PDFScanner *scanner,void *info) {
   //NSLog(@"ID");
}

// setlinejoin, Set line join style
void O2PDF_render_j(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFInteger linejoin;
   
   if(![scanner popInteger:&linejoin])
    return;

   [context setLineJoin:linejoin];
}

// setlinecap, Set line cap style
void O2PDF_render_J(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFInteger linecap;
   
   if(![scanner popInteger:&linecap])
    return;

   [context setLineCap:linecap];
}

// setcmykcolor, Set CMYK color for stroking operations
void O2PDF_render_K(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    c,m,y,k;
   
   if(![scanner popNumber:&k])
    return;
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&m])
    return;
   if(![scanner popNumber:&c])
    return;
    
   [context setCMYKStrokeColor:c:m:y:k];
}

// setcmykcolor, Set CMYK color for nonstroking operations
void O2PDF_render_k(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    c,m,y,k;
   
   if(![scanner popNumber:&k])
    return;
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&m])
    return;
   if(![scanner popNumber:&c])
    return;
   
   [context setCMYKFillColor:c:m:y:k];
}

// lineto, Append straight line segment to path
void O2PDF_render_l(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
   
   [context addLineToPoint:x:y];
}

// moveto, Begin new subpath
void O2PDF_render_m(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
   
   [context moveToPoint:x:y];
}

// setmiterlimit, Set miter limit
void O2PDF_render_M(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    limit;
   
   if(![scanner popNumber:&limit])
    return;

   [context setMiterLimit:limit];
}

void O2PDF_render_MP(O2PDFScanner *scanner,void *info) {
  // NSLog(@"MP");
}

// End path without filling or stroking
void O2PDF_render_n(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context beginPath];
}

// gsave
void O2PDF_render_q(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context saveGState];
}

// grestore
void O2PDF_render_Q(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context restoreGState];
}

// Append rectangle to path
void O2PDF_render_re(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   CGRect     rect;

   if(![scanner popNumber:&rect.size.height])
    return;
   if(![scanner popNumber:&rect.size.width])
    return;
   if(![scanner popNumber:&rect.origin.y])
    return;
   if(![scanner popNumber:&rect.origin.x])
    return;

   [context addRect:rect];
}

// setrgbcolor, Set RGB color for stroking operations
void O2PDF_render_RG(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    r,g,b;

   if(![scanner popNumber:&b])
    return;
   if(![scanner popNumber:&g])
    return;
   if(![scanner popNumber:&r])
    return;
   
   [context setRGBStrokeColor:r:g:b];
}

// setrgbcolor, Set RGB color for nonstroking operations
void O2PDF_render_rg(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    r,g,b;

   if(![scanner popNumber:&b])
    return;

   if(![scanner popNumber:&g])
    return;

   if(![scanner popNumber:&r])
    return;
   
   [context setRGBFillColor:r:g:b];
}

// name ri, Set color rendering intent
void O2PDF_render_ri(O2PDFScanner *scanner,void *info) {
   O2Context  *context=kgContextFromInfo(info);
   const char *name;
   
   if(![scanner popName:&name])
    return;
   
   [context setRenderingIntent:KGImageRenderingIntentWithName(name)];
}

// closepath stroke
void O2PDF_render_s(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context closePath];
   [context strokePath];
}

// stroke
void O2PDF_render_S(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context strokePath];
}

// setcolor, Set color for stroking operations
void O2PDF_render_SC(O2PDFScanner *scanner,void *info) {
   O2Context    *context=kgContextFromInfo(info);
   O2Color      *color=[context strokeColor];
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace(color);
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=O2ColorGetAlpha(color);
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in SC, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setStrokeColorWithComponents:components];
}

// setcolor, Set color for nonstroking operations
void O2PDF_render_sc(O2PDFScanner *scanner,void *info) {
   O2Context    *context=kgContextFromInfo(info);
   O2Color      *color=[context fillColor];
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace(color);
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=O2ColorGetAlpha(color);
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in sc, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setFillColorWithComponents:components];
}

// setcolor, Set color for stroking operations, ICCBased and special color spaces
void O2PDF_render_SCN(O2PDFScanner *scanner,void *info) {
   O2Context    *context=kgContextFromInfo(info);
   O2Color      *color=[context strokeColor];
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace(color);
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=O2ColorGetAlpha(color);
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in SCN, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setStrokeColorWithComponents:components];
}

// setcolor, Set color for nonstroking operations, ICCBased and special color spaces
void O2PDF_render_scn(O2PDFScanner *scanner,void *info) {
   O2Context    *context=kgContextFromInfo(info);
   O2Color      *color=[context fillColor];
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace(color);
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   O2PDFReal     components[count+1];
   
   components[count]=O2ColorGetAlpha(color);
   while(--count>=0)
    if(![scanner popNumber:&components[count]]){
     NSLog(@"underflow in scn, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }

   [context setFillColorWithComponents:components];
}



// shfill, Paint area defined by shading pattern
void O2PDF_render_sh(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFContentStream *content=[scanner contentStream];
   O2PDFObject        *resource;
   const char         *name;
   KGShading *shading=NULL;
   
   if(![scanner popName:&name])
    return;
    
   if((resource=[content resourceForCategory:"Shading" name:name])==nil)
    return;
   
   shading=[KGShading shadingWithPDFObject:resource];
   
   if(shading!=NULL){
    [context drawShading:shading];
    [shading release];
   }
}

// Move to start of next text line
void O2PDF_render_T_star(O2PDFScanner *scanner,void *info) {
   NSLog(@"T*");
}

// Set character spacing
void O2PDF_render_Tc(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal  spacing;
   
   if(![scanner popNumber:&spacing])
    return;
   
   [context setCharacterSpacing:spacing];
}

// Move text position
void O2PDF_render_Td(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
    
   [context setTextPosition:x:y];
   
}

// Move text position and set leading
void O2PDF_render_TD(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
    
   [context setTextLeading:-y];
   [context setTextPosition:x:y];
}

// Set text font and size
void O2PDF_render_Tf(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFContentStream *content=[scanner contentStream];
   O2PDFReal        scale;
   const char      *name;
   const char      *subtype;
   O2PDFObject     *resource;
   O2PDFDictionary *dictionary;

   if(![scanner popNumber:&scale])
    return;
   if(![scanner popName:&name])
    return;
       
   if((resource=[content resourceForCategory:"Font" name:name])==nil)
    return;
   
   if(![resource checkForType:kKGPDFObjectTypeDictionary value:&dictionary])
    return;
    
   if([dictionary getNameForKey:"Type" value:&name])
    if(strcmp(name,"Font")!=0)
     return;

   if(![dictionary getNameForKey:"Subtype" value:&subtype])
    return;

   [context setTextMatrix:CGAffineTransformIdentity];
   
   if(strcmp(subtype,"Type0")==0){
    NSLog(@"Font subtype %s not implemented",subtype);
   }
   else if(strcmp(subtype,"Type1")==0){
    const char *baseFont;
    
    if(![dictionary getNameForKey:"BaseFont" value:&baseFont])
     return;
//NSLog(@"Type1 baseFont=%s,scale=%f",baseFont,scale);
    [context selectFontWithName:baseFont size:scale encoding:0];
   }
   else if(strcmp(subtype,"MMType1")==0){
    NSLog(@"Font subtype %s not implemented",subtype);
   }
   else if(strcmp(subtype,"Type3")==0){
    NSLog(@"Font subtype %s not implemented",subtype);
   }
   else if(strcmp(subtype,"TrueType")==0){
    const char *baseFont;
    
    if(![dictionary getNameForKey:"BaseFont" value:&baseFont])
     return;
//NSLog(@"Type1 baseFont=%s,scale=%f",baseFont,scale);
    [context selectFontWithName:baseFont size:scale encoding:0];
   }
   else if(strcmp(subtype,"CIDFontType0")==0){
    NSLog(@"Font subtype %s not implemented",subtype);
   }
   else if(strcmp(subtype,"CIDFontType2")==0){
    NSLog(@"Font subtype %s not implemented",subtype);
   }
   
  // NSLog(@"Tf=%@",dictionary);
}

// show
void O2PDF_render_Tj(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFString *string;
   
   if(![scanner popString:&string])
    return;
   
   [context showText:[string bytes] length:[string length]];
}

// Show text, alowing individual glyph positioning
void O2PDF_render_TJ(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFArray  *array;
   int          i,count;
   
   if(![scanner popArray:&array])
    return;
    
   count=[array count];
   for(i=0;i<count;i++){
    O2PDFObject    *object;
    O2PDFReal       real;
    O2PDFString    *string;

    if(![array getObjectAtIndex:i value:&object])
     return;

    if([object checkForType:kKGPDFObjectTypeReal value:&real]){
     // translate text matrix, change position
    }
    else if([object checkForType:kKGPDFObjectTypeString value:&string]){
     [context showText:[string bytes] length:[string length]];
    }
    else
     return;
   } 
}

// Set text leading
void O2PDF_render_TL(O2PDFScanner *scanner,void *info) {
   //NSLog(@"TL");
}

// Set text matrix and text line matrix
void O2PDF_render_Tm(O2PDFScanner *scanner,void *info) {
   O2Context        *context=kgContextFromInfo(info);
   CGAffineTransform matrix;
   
   if(![scanner popNumber:&matrix.ty])
    return;
   if(![scanner popNumber:&matrix.tx])
    return;
   if(![scanner popNumber:&matrix.d])
    return;
   if(![scanner popNumber:&matrix.c])
    return;
   if(![scanner popNumber:&matrix.b])
    return;
   if(![scanner popNumber:&matrix.a])
    return;
     
   //NSLog(@"%f %f %f %f %f %f",matrix.a,matrix.b,matrix.c,matrix.d,matrix.tx,matrix.ty);
   [context setTextMatrix:matrix];
}

// Set text rendering mode
void O2PDF_render_Tr(O2PDFScanner *scanner,void *info) {
   //NSLog(@"Tr");
}

// Set text rise
void O2PDF_render_Ts(O2PDFScanner *scanner,void *info) {
  // NSLog(@"Ts");
}

// Set word spacing
void O2PDF_render_Tw(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    spacing;

   if(![scanner popNumber:&spacing])
    return;
   
   [context setWordSpacing:spacing];
}

// Set horizontal text scaling
void O2PDF_render_Tz(O2PDFScanner *scanner,void *info) {
    // NSLog(@"Tz");
 
}

// curveto, Append curved segment to path, initial point replicated
void O2PDF_render_v(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x2,y2,x3,y3;
   
   if(![scanner popNumber:&y3])
    return;
   if(![scanner popNumber:&x3])
    return;
   if(![scanner popNumber:&y2])
    return;
   if(![scanner popNumber:&x2])
    return;
   
   [context addQuadCurveToPoint:x2:y2:x3:y3];
}

// setlinewidth, Set line width
void O2PDF_render_w(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    width;

   if(![scanner popNumber:&width])
    return;
   
   [context setLineWidth:width];
}

// clip, Set clipping path using nonzero winding number rule
void O2PDF_render_W(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context clipToPath];
}

// eoclip, Set clipping path using even-odd rule
void O2PDF_render_W_star(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   
   [context evenOddClipToPath];
}

// curveto, Append curved segment to path, final point replicated
void O2PDF_render_y(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFReal    x1,y1,x3,y3;
   
   if(![scanner popNumber:&y3])
    return;
   if(![scanner popNumber:&x3])
    return;
   if(![scanner popNumber:&y1])
    return;
   if(![scanner popNumber:&x1])
    return;
   
   [context addCurveToPoint:x1:y1:x3:y3:x3:y3];
}

// Move to next line and show text
// T*string Tj
void O2PDF_render_quote(O2PDFScanner *scanner,void *info) {   
   O2PDF_render_T_star(scanner,info);
   O2PDF_render_Tj(scanner,info);
}

// Set word and character spacing, move to next line, and show text
// same as w Tw c Tc string '
void O2PDF_render_dquote(O2PDFScanner *scanner,void *info) {
   O2Context *context=kgContextFromInfo(info);
   O2PDFString *string;
   O2PDFReal    cspacing;
   O2PDFReal    wspacing;
   
   if(![scanner popString:&string])
    return;
   if(![scanner popNumber:&cspacing])
    return;
   if(![scanner popNumber:&wspacing])
    return;
   
   [context setWordSpacing:wspacing];
   [context setCharacterSpacing:cspacing];
   [context showText:[string bytes] length:[string length]];
}

void O2PDF_render_populateOperatorTable(O2PDFOperatorTable *table) {
   struct {
    const char           *name;
    O2PDFOperatorCallback callback;
   } ops[]={
    { "b", O2PDF_render_b },
    { "B", O2PDF_render_B },
    { "b*", O2PDF_render_b_star },
    { "B*", O2PDF_render_B_star },
    { "BDC", O2PDF_render_BDC },
    { "BI", O2PDF_render_BI },
    { "BMC", O2PDF_render_BMC },
    { "BT", O2PDF_render_BT },
    { "BX", O2PDF_render_BX },
    { "c", O2PDF_render_c },
    { "cm", O2PDF_render_cm },
    { "CS", O2PDF_render_CS },
    { "cs", O2PDF_render_cs },
    { "d", O2PDF_render_d },
    { "d0", O2PDF_render_d0 },
    { "d1", O2PDF_render_d1 },
    { "Do", O2PDF_render_Do },
    { "DP", O2PDF_render_DP },
    { "EI", O2PDF_render_EI },
    { "EMC", O2PDF_render_EMC },
    { "ET", O2PDF_render_ET },
    { "EX", O2PDF_render_EX },
    { "f", O2PDF_render_f },
    { "F", O2PDF_render_F },
    { "f*", O2PDF_render_f_star },
    { "G", O2PDF_render_G },
    { "g", O2PDF_render_g },
    { "gs", O2PDF_render_gs },
    { "h", O2PDF_render_h },
    { "i", O2PDF_render_i },
    { "ID", O2PDF_render_ID },
    { "j", O2PDF_render_j },
    { "J", O2PDF_render_J },
    { "K", O2PDF_render_K },
    { "k", O2PDF_render_k },
    { "l", O2PDF_render_l },
    { "m", O2PDF_render_m },
    { "M", O2PDF_render_M },
    { "MP", O2PDF_render_MP },
    { "n", O2PDF_render_n },
    { "q", O2PDF_render_q },
    { "Q", O2PDF_render_Q },
    { "re", O2PDF_render_re },
    { "RG", O2PDF_render_RG },
    { "rg", O2PDF_render_rg },
    { "ri", O2PDF_render_ri },
    { "s", O2PDF_render_s },
    { "S", O2PDF_render_S },
    { "SC", O2PDF_render_SC },
    { "sc", O2PDF_render_sc },
    { "SCN", O2PDF_render_SCN },
    { "scn", O2PDF_render_scn },
    { "sh", O2PDF_render_sh },
    { "T*", O2PDF_render_T_star },
    { "Tc", O2PDF_render_Tc },
    { "Td", O2PDF_render_Td },
    { "TD", O2PDF_render_TD },
    { "Tf", O2PDF_render_Tf },
    { "Tj", O2PDF_render_Tj },
    { "TJ", O2PDF_render_TJ },
    { "TL", O2PDF_render_TL },
    { "Tm", O2PDF_render_Tm },
    { "Tr", O2PDF_render_Tr },
    { "Ts", O2PDF_render_Ts },
    { "Tw", O2PDF_render_Tw },
    { "Tz", O2PDF_render_Tz },
    { "v", O2PDF_render_v },
    { "w", O2PDF_render_w },
    { "W", O2PDF_render_W },
    { "W*", O2PDF_render_W_star },
    { "y", O2PDF_render_y },
    { "\'", O2PDF_render_quote },
    { "\"", O2PDF_render_dquote },
    { NULL, NULL }
   };
   int i;
   
   for(i=0;ops[i].name!=NULL;i++)
    [table setCallback:ops[i].callback forName:ops[i].name];
}

