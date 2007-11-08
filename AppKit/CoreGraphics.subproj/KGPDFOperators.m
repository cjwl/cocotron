/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFOperators.h"
#import "KGPDFOperatorTable.h"
#import "KGPDFScanner.h"
#import "KGPDFContentStream.h"
#import <AppKit/KGPDFObject.h>
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFString.h"
#import "KGDataProvider.h"
#import "KGPDFFunction_Type2.h"
#import "KGPDFFunction_Type3.h"

#import "KGContext.h"
#import "KGColor.h"
#import "KGColorSpace.h"
#import "KGImage.h"
#import "KGFunction.h"
#import "KGShading.h"
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

#import <stddef.h>

static KGContext *kgContextFromInfo(void *info) {
   return (KGContext *)info;
}

// closepath, fill, stroke
void KGPDF_render_b(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context closePath];
   [context fillAndStrokePath];
}

// fill, stroke
void KGPDF_render_B(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context fillAndStrokePath];
}

// closepath, eofill, stroke
void KGPDF_render_b_star(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context closePath];
   [context evenOddFillAndStrokePath];
}

// eofill, stroke
void KGPDF_render_B_star(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context evenOddFillAndStrokePath];
}

// Begin marked-content sequence with property list
void KGPDF_render_BDC(KGPDFScanner *scanner,void *info) {
   //NSLog(@"BDC");
}

// Begin inline image object
void KGPDF_render_BI(KGPDFScanner *scanner,void *info) {
   //NSLog(@"BI");
}

// Begin marked-content sequence
void KGPDF_render_BMC(KGPDFScanner *scanner,void *info) {
   //NSLog(@"BMC");
}

// Begin text object
void KGPDF_render_BT(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context setTextMatrix:CGAffineTransformIdentity];
   //NSLog(@"BT");
}

// Begin compatibility section
void KGPDF_render_BX(KGPDFScanner *scanner,void *info) {
   //NSLog(@"BX");
}

// curveto, Append curved segment to path, three control points
void KGPDF_render_c(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x1,y1,x2,y2,x3,y3;
   
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
void KGPDF_render_cm(KGPDFScanner *scanner,void *info) {
   KGContext        *context=kgContextFromInfo(info);
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


KGColorSpace *colorSpaceFromScannerInfo(KGPDFScanner *scanner,void *info,const char *name) {
   KGColorSpace *result=NULL;
   
   if(strcmp(name,"DeviceGray")==0)
    result=[[KGColorSpace alloc] initWithDeviceGray];
   else if(strcmp(name,"DeviceRGB")==0)
    result=[[KGColorSpace alloc] initWithDeviceRGB];
   else if(strcmp(name,"DeviceCMYK")==0)
    result=[[KGColorSpace alloc] initWithDeviceCMYK];
   else {
    KGPDFContentStream *content=[scanner contentStream];
    KGPDFObject        *object=[content resourceForCategory:"ColorSpace" name:name];
    
    if(object==nil){
     NSLog(@"Unable to find color space named %s",name);
     return NULL;
    }
   
    return [KGColorSpace colorSpaceFromPDFObject:object];
   }
   
   return result;
}

// setcolorspace, Set color space for stroking operations
void KGPDF_render_CS(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   const char     *name;
   KGColorSpace *colorSpace;
   
   if(![scanner popName:&name])
    return;
    
   colorSpace=colorSpaceFromScannerInfo(scanner,info,name);
   
   if(colorSpace!=NULL){
    [context setStrokeColorSpace:colorSpace];
    [colorSpace release];
   }
}

// setcolorspace, Set color space for nonstroking operations
void KGPDF_render_cs(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   const char     *name;
   KGColorSpace *colorSpace;
   
   if(![scanner popName:&name])
    return;
    
   colorSpace=colorSpaceFromScannerInfo(scanner,info,name);
   
   if(colorSpace!=NULL){
    [context setFillColorSpace:colorSpace];
    [colorSpace release];
   }
}

// setdash, Set line dash pattern
void KGPDF_render_d(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    phase;
   KGPDFArray  *array;
   int          i,count;
   
   if(![scanner popNumber:&phase])
    return;
   if(![scanner popArray:&array])
    return;
   count=[array count];
   {
    KGPDFReal lengths[count];
   
    for(i=0;i<count;i++)
     if(![array getNumberAtIndex:i value:lengths+i])
      return;
   
    [context setLineDashPhase:phase lengths:lengths count:count];
   }
}

// setcharwidth, Set glyph with in Type 3 font
void KGPDF_render_d0(KGPDFScanner *scanner,void *info) {
   //NSLog(@"d0");
}

// setcachedevice, Set glyph width and bounding box in Type 3 font
void KGPDF_render_d1(KGPDFScanner *scanner,void *info) {
   //NSLog(@"d1");
}

// Invoke named XObject
void KGPDF_render_Do(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFContentStream *content=[scanner contentStream];
   const char         *name;
   KGPDFObject        *resource;
   KGPDFStream        *stream;
   KGPDFDictionary    *dictionary;
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
    KGPDFDictionary    *resources;
    KGPDFContentStream *contentStream;
    KGPDFOperatorTable *operatorTable;
    KGPDFScanner       *doScanner;
    KGPDFDictionary    *group;
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
        
    contentStream=[[[KGPDFContentStream alloc] initWithStream:stream resources:resources parent:[scanner contentStream]] autorelease];
    operatorTable=[KGPDFOperatorTable renderingOperatorTable];
    doScanner=[[[KGPDFScanner alloc] initWithContentStream:contentStream operatorTable:operatorTable info:info] autorelease];

if(doIt)
    [doScanner scan];
   }
   else if(strcmp(subtype,"Image")==0){
    KGImage *image=[KGImage imageWithPDFObject:stream];
    
    if(image!=NULL)
     [context drawImage:image inRect:CGRectMake(0,0,1,1)];

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
void KGPDF_render_DP(KGPDFScanner *scanner,void *info) {
   //NSLog(@"DP");
}

// End inline image object
void KGPDF_render_EI(KGPDFScanner *scanner,void *info) {
   //NSLog(@"EI");
}

// End marked-content sequence
void KGPDF_render_EMC(KGPDFScanner *scanner,void *info) {
   //NSLog(@"EMC");
}

// End text object
void KGPDF_render_ET(KGPDFScanner *scanner,void *info) {
   //NSLog(@"ET");
}

// End compatibility section
void KGPDF_render_EX(KGPDFScanner *scanner,void *info) {
   //NSLog(@"EX");
}

// fill, fill path using nonzero winding number rule
void KGPDF_render_f(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context fillPath];
}

// fill, fill path using nonzero winding number rule (obsolete)
void KGPDF_render_F(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context fillPath];
}

// eofill, fill path using even-odd rule
void KGPDF_render_f_star(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context evenOddFillPath];
}

// setgray, set gray level for stroking operations
void KGPDF_render_G(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    gray;
   
   if(![scanner popNumber:&gray])
    return;
   
   [context setGrayStrokeColor:gray];
}

// setgray, set gray level for nonstroking operations
void KGPDF_render_g(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    gray;
   
   if(![scanner popNumber:&gray])
    return;
   
   [context setGrayFillColor:gray];
}

// Set parameters from graphics state parameter dictionary
void KGPDF_render_gs(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFContentStream *content=[scanner contentStream];
   KGPDFObject        *resource;
   KGPDFDictionary    *graphicsState;
   const char         *name;
   KGPDFReal           number;
   KGPDFInteger        integer;
   KGPDFArray         *array;
   KGPDFDictionary    *dictionary;
   KGPDFBoolean        boolean;
   
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
void KGPDF_render_h(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context closePath];
}

// setflat, Set flatness tolerance
void KGPDF_render_i(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    flatness;
   
   if(![scanner popNumber:&flatness])
    return;

   [context setFlatness:flatness];
}

// Begin inline image data
void KGPDF_render_ID(KGPDFScanner *scanner,void *info) {
   //NSLog(@"ID");
}

// setlinejoin, Set line join style
void KGPDF_render_j(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFInteger linejoin;
   
   if(![scanner popInteger:&linejoin])
    return;

   [context setLineJoin:linejoin];
}

// setlinecap, Set line cap style
void KGPDF_render_J(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFInteger linecap;
   
   if(![scanner popInteger:&linecap])
    return;

   [context setLineCap:linecap];
}

// setcmykcolor, Set CMYK color for stroking operations
void KGPDF_render_K(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    c,m,y,k;
   
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
void KGPDF_render_k(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    c,m,y,k;
   
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
void KGPDF_render_l(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
   
   [context addLineToPoint:x:y];
}

// moveto, Begin new subpath
void KGPDF_render_m(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
   
   [context moveToPoint:x:y];
}

// setmiterlimit, Set miter limit
void KGPDF_render_M(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    limit;
   
   if(![scanner popNumber:&limit])
    return;

   [context setMiterLimit:limit];
}

void KGPDF_render_MP(KGPDFScanner *scanner,void *info) {
  // NSLog(@"MP");
}

// End path without filling or stroking
void KGPDF_render_n(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context beginPath];
}

// gsave
void KGPDF_render_q(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context saveGState];
}

// grestore
void KGPDF_render_Q(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context restoreGState];
}

// Append rectangle to path
void KGPDF_render_re(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   NSRect     rect;

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
void KGPDF_render_RG(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    r,g,b;

   if(![scanner popNumber:&b])
    return;
   if(![scanner popNumber:&g])
    return;
   if(![scanner popNumber:&r])
    return;
   
   [context setRGBStrokeColor:r:g:b];
}

// setrgbcolor, Set RGB color for nonstroking operations
void KGPDF_render_rg(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    r,g,b;

   if(![scanner popNumber:&b])
    return;

   if(![scanner popNumber:&g])
    return;

   if(![scanner popNumber:&r])
    return;
   
   [context setRGBFillColor:r:g:b];
}

// name ri, Set color rendering intent
void KGPDF_render_ri(KGPDFScanner *scanner,void *info) {
   KGContext  *context=kgContextFromInfo(info);
   const char *name;
   
   if(![scanner popName:&name])
    return;
   
   [context setRenderingIntent:KGImageRenderingIntentWithName(name)];
}

// closepath stroke
void KGPDF_render_s(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context closePath];
   [context strokePath];
}

// stroke
void KGPDF_render_S(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context strokePath];
}

// setcolor, Set color for stroking operations
void KGPDF_render_SC(KGPDFScanner *scanner,void *info) {
   KGContext    *context=kgContextFromInfo(info);
   KGColor      *color=[context strokeColor];
   KGColorSpace *colorSpace=[color colorSpace];
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=[color alpha];
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in SC, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setStrokeColorWithComponents:components];
}

// setcolor, Set color for nonstroking operations
void KGPDF_render_sc(KGPDFScanner *scanner,void *info) {
   KGContext    *context=kgContextFromInfo(info);
   KGColor      *color=[context fillColor];
   KGColorSpace *colorSpace=[color colorSpace];
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=[color alpha];
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in sc, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setFillColorWithComponents:components];
}

// setcolor, Set color for stroking operations, ICCBased and special color spaces
void KGPDF_render_SCN(KGPDFScanner *scanner,void *info) {
   KGContext    *context=kgContextFromInfo(info);
   KGColor      *color=[context strokeColor];
   KGColorSpace *colorSpace=[color colorSpace];
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   float         components[count+1];
   
   components[count]=[color alpha];
   while(--count>=0)
    if(![scanner popNumber:components+count]){
     NSLog(@"underflow in SCN, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }
    
   [context setStrokeColorWithComponents:components];
}

// setcolor, Set color for nonstroking operations, ICCBased and special color spaces
void KGPDF_render_scn(KGPDFScanner *scanner,void *info) {
   KGContext    *context=kgContextFromInfo(info);
   KGColor      *color=[context fillColor];
   KGColorSpace *colorSpace=[color colorSpace];
   unsigned      numberOfComponents=[colorSpace numberOfComponents];
   int           count=numberOfComponents;
   KGPDFReal     components[count+1];
   
   components[count]=[color alpha];
   while(--count>=0)
    if(![scanner popNumber:&components[count]]){
     NSLog(@"underflow in scn, numberOfComponents=%d,count=%d",numberOfComponents,count);
     return;
    }

   [context setFillColorWithComponents:components];
}



// shfill, Paint area defined by shading pattern
void KGPDF_render_sh(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFContentStream *content=[scanner contentStream];
   KGPDFObject        *resource;
   const char         *name;
   KGPDFInteger        shadingType;
   KGPDFObject        *colorSpaceObject;
   KGColorSpace *colorSpace;
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
void KGPDF_render_T_star(KGPDFScanner *scanner,void *info) {
   NSLog(@"T*");
}

// Set character spacing
void KGPDF_render_Tc(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal  spacing;
   
   if(![scanner popNumber:&spacing])
    return;
   
   [context setCharacterSpacing:spacing];
}

// Move text position
void KGPDF_render_Td(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
    
   [context setTextPosition:x:y];
   
}

// Move text position and set leading
void KGPDF_render_TD(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x,y;
   
   if(![scanner popNumber:&y])
    return;
   if(![scanner popNumber:&x])
    return;
    
   [context setTextLeading:-y];
   [context setTextPosition:x:y];
}

// Set text font and size
void KGPDF_render_Tf(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFContentStream *content=[scanner contentStream];
   KGPDFReal        scale;
   const char      *name;
   const char      *subtype;
   KGPDFObject     *resource;
   KGPDFDictionary *dictionary;

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
void KGPDF_render_Tj(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFString *string;
   
   if(![scanner popString:&string])
    return;
   
   [context showText:[string bytes] length:[string length]];
}

// Show text, alowing individual glyph positioning
void KGPDF_render_TJ(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFArray  *array;
   int          i,count;
   
   if(![scanner popArray:&array])
    return;
    
   count=[array count];
   for(i=0;i<count;i++){
    KGPDFObject    *object;
    KGPDFReal       real;
    KGPDFString    *string;

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
void KGPDF_render_TL(KGPDFScanner *scanner,void *info) {
   //NSLog(@"TL");
}

// Set text matrix and text line matrix
void KGPDF_render_Tm(KGPDFScanner *scanner,void *info) {
   KGContext        *context=kgContextFromInfo(info);
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
void KGPDF_render_Tr(KGPDFScanner *scanner,void *info) {
   //NSLog(@"Tr");
}

// Set text rise
void KGPDF_render_Ts(KGPDFScanner *scanner,void *info) {
  // NSLog(@"Ts");
}

// Set word spacing
void KGPDF_render_Tw(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    spacing;

   if(![scanner popNumber:&spacing])
    return;
   
   [context setWordSpacing:spacing];
}

// Set horizontal text scaling
void KGPDF_render_Tz(KGPDFScanner *scanner,void *info) {
    // NSLog(@"Tz");
 
}

// curveto, Append curved segment to path, initial point replicated
void KGPDF_render_v(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x2,y2,x3,y3;
   
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
void KGPDF_render_w(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    width;

   if(![scanner popNumber:&width])
    return;
   
   [context setLineWidth:width];
}

// clip, Set clipping path using nonzero winding number rule
void KGPDF_render_W(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context clipToPath];
}

// eoclip, Set clipping path using even-odd rule
void KGPDF_render_W_star(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   
   [context evenOddClipToPath];
}

// curveto, Append curved segment to path, final point replicated
void KGPDF_render_y(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFReal    x1,y1,x3,y3;
   
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
void KGPDF_render_quote(KGPDFScanner *scanner,void *info) {   
   KGPDF_render_T_star(scanner,info);
   KGPDF_render_Tj(scanner,info);
}

// Set word and character spacing, move to next line, and show text
// same as w Tw c Tc string '
void KGPDF_render_dquote(KGPDFScanner *scanner,void *info) {
   KGContext *context=kgContextFromInfo(info);
   KGPDFString *string;
   KGPDFReal    cspacing;
   KGPDFReal    wspacing;
   
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

void KGPDF_render_populateOperatorTable(KGPDFOperatorTable *table) {
   struct {
    const char           *name;
    KGPDFOperatorCallback callback;
   } ops[]={
    { "b", KGPDF_render_b },
    { "B", KGPDF_render_B },
    { "b*", KGPDF_render_b_star },
    { "B*", KGPDF_render_B_star },
    { "BDC", KGPDF_render_BDC },
    { "BI", KGPDF_render_BI },
    { "BMC", KGPDF_render_BMC },
    { "BT", KGPDF_render_BT },
    { "BX", KGPDF_render_BX },
    { "c", KGPDF_render_c },
    { "cm", KGPDF_render_cm },
    { "CS", KGPDF_render_CS },
    { "cs", KGPDF_render_cs },
    { "d", KGPDF_render_d },
    { "d0", KGPDF_render_d0 },
    { "d1", KGPDF_render_d1 },
    { "Do", KGPDF_render_Do },
    { "DP", KGPDF_render_DP },
    { "EI", KGPDF_render_EI },
    { "EMC", KGPDF_render_EMC },
    { "ET", KGPDF_render_ET },
    { "EX", KGPDF_render_EX },
    { "f", KGPDF_render_f },
    { "F", KGPDF_render_F },
    { "f*", KGPDF_render_f_star },
    { "G", KGPDF_render_G },
    { "g", KGPDF_render_g },
    { "gs", KGPDF_render_gs },
    { "h", KGPDF_render_h },
    { "i", KGPDF_render_i },
    { "ID", KGPDF_render_ID },
    { "j", KGPDF_render_j },
    { "J", KGPDF_render_J },
    { "K", KGPDF_render_K },
    { "k", KGPDF_render_k },
    { "l", KGPDF_render_l },
    { "m", KGPDF_render_m },
    { "M", KGPDF_render_M },
    { "MP", KGPDF_render_MP },
    { "n", KGPDF_render_n },
    { "q", KGPDF_render_q },
    { "Q", KGPDF_render_Q },
    { "re", KGPDF_render_re },
    { "RG", KGPDF_render_RG },
    { "rg", KGPDF_render_rg },
    { "ri", KGPDF_render_ri },
    { "s", KGPDF_render_s },
    { "S", KGPDF_render_S },
    { "SC", KGPDF_render_SC },
    { "sc", KGPDF_render_sc },
    { "SCN", KGPDF_render_SCN },
    { "scn", KGPDF_render_scn },
    { "sh", KGPDF_render_sh },
    { "T*", KGPDF_render_T_star },
    { "Tc", KGPDF_render_Tc },
    { "Td", KGPDF_render_Td },
    { "TD", KGPDF_render_TD },
    { "Tf", KGPDF_render_Tf },
    { "Tj", KGPDF_render_Tj },
    { "TJ", KGPDF_render_TJ },
    { "TL", KGPDF_render_TL },
    { "Tm", KGPDF_render_Tm },
    { "Tr", KGPDF_render_Tr },
    { "Ts", KGPDF_render_Ts },
    { "Tw", KGPDF_render_Tw },
    { "Tz", KGPDF_render_Tz },
    { "v", KGPDF_render_v },
    { "w", KGPDF_render_w },
    { "W", KGPDF_render_W },
    { "W*", KGPDF_render_W_star },
    { "y", KGPDF_render_y },
    { "\'", KGPDF_render_quote },
    { "\"", KGPDF_render_dquote },
    { NULL, NULL }
   };
   int i;
   
   for(i=0;ops[i].name!=NULL;i++)
    [table setCallback:ops[i].callback forName:ops[i].name];
}

