/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGShading.h"
#import "KGColorSpace.h"
#import "KGFunction.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"
#import "KGPDFContext.h"
#import <Foundation/NSString.h>

@implementation KGShading

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd domain:(float[])domain {
   _colorSpace=[colorSpace retain];
   _startPoint=startPoint;
   _endPoint=endPoint;
   _function=[function retain];
   _extendStart=extendStart;
   _extendEnd=extendEnd;
   _isRadial=NO;
   _domain[0]=domain[0];
   _domain[1]=domain[1];
   return self;
}

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint startRadius:(float)startRadius endPoint:(NSPoint)endPoint endRadius:(float)endRadius function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd domain:(float[])domain {
   _colorSpace=[colorSpace retain];
   _startPoint=startPoint;
   _endPoint=endPoint;
   _function=[function retain];
   _extendStart=extendStart;
   _extendEnd=extendEnd;
   _isRadial=YES;
   _startRadius=startRadius;
   _endRadius=endRadius;
   _domain[0]=domain[0];
   _domain[1]=domain[1];
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_function release];
   [super dealloc];
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(NSPoint)startPoint {
   return _startPoint;
}

-(NSPoint)endPoint {
   return _endPoint;
}

-(float)startRadius {
   return _startRadius;
}

-(float)endRadius {
   return _endRadius;
}

-(BOOL)extendStart {
   return _extendStart;
}

-(BOOL)extendEnd {
   return _extendEnd;
}

-(KGFunction *)function {
   return _function;
}

-(BOOL)isAxial {
   return _isRadial?NO:YES;
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];
   int              type;
   float            coords[6];
   int              coordsCount;
   
   if([self isAxial]){
    type=2;
    coords[0]=_startPoint.x;
    coords[1]=_startPoint.y;
    coords[2]=_endPoint.x;
    coords[3]=_endPoint.y;
    coordsCount=4;
   }
   else {
    type=3;
    coords[0]=_startPoint.x;
    coords[1]=_startPoint.y;
    coords[2]=_startRadius;
    coords[3]=_endPoint.x;
    coords[4]=_endPoint.y;
    coords[5]=_endRadius;
    coordsCount=6;
   }
   [result setIntegerForKey:"ShadingType" value:type];
   [result setObjectForKey:"Coords" value:[KGPDFArray pdfArrayWithNumbers:coords count:coordsCount]];

   [result setObjectForKey:"Domain" value:[KGPDFArray pdfArrayWithNumbers:_domain count:2]];
   [result setObjectForKey:"ColorSpace" value:[_colorSpace encodeReferenceWithContext:context]];
   [result setObjectForKey:"Function" value:[_function encodeReferenceWithContext:context]];
   KGPDFArray *extend=[KGPDFArray pdfArray];
   
   [extend addBoolean:_extendStart];
   [extend addBoolean:_extendEnd];
   [result setObjectForKey:"Extend" value:extend];

   return [context encodeIndirectPDFObject:result];
}

KGShading *axialShading(KGPDFDictionary *dictionary,KGColorSpace *colorSpace){
   KGPDFArray *coordsArray;
   KGPDFArray *domainArray;
   float       domain[2]={0,1};
   KGPDFDictionary *fnDictionary;
   KGPDFArray *extendArray;
   NSPoint     start;
   NSPoint     end;
   KGFunction *function;
   KGPDFBoolean extendStart=NO;
   KGPDFBoolean extendEnd=NO;
   
//NSLog(@"axialShading=%@",dictionary);

   if(![dictionary getArrayForKey:"Coords" value:&coordsArray]){
    NSLog(@"No Coords entry in axial shader");
    return NULL;
   }
   else {    
    if(![coordsArray getNumberAtIndex:0 value:&start.x]){
     NSLog(@"No real at Coords[0]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:1 value:&start.y]){
     NSLog(@"No real at Coords[1]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:2 value:&end.x]){
     NSLog(@"No real at Coords[2]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:3 value:&end.y]){
     NSLog(@"No real at Coords[3]");
     return NULL;
    }
   }
   
   if(![dictionary getArrayForKey:"Domain" value:&domainArray])
    domainArray=nil;
   else {
    if(![domainArray getNumberAtIndex:0 value:&(domain[0])]){
     NSLog(@"No real at Domain[0]");
     return NULL;
    }
    if(![domainArray getNumberAtIndex:1 value:&(domain[1])]){
     NSLog(@"No real at Domain[1]");
     return NULL;
    }
   }

   if(![dictionary getDictionaryForKey:"Function" value:&fnDictionary]){
    NSLog(@"No Function entry in axial shader");
    return NULL;
   }
   if((function=[KGFunction pdfFunctionWithDictionary:fnDictionary])==NULL)
    return NULL;
    
   if([dictionary getArrayForKey:"Extend" value:&extendArray]){
    if(![extendArray getBooleanAtIndex:0 value:&extendStart]){
     NSLog(@"Extend dictionary missing boolean at 0");
     return NULL;
    }
    if(![extendArray getBooleanAtIndex:1 value:&extendEnd]){
     NSLog(@"Extend dictionary missing boolean at 1");
     return NULL;
    }
   }
   
   return [[KGShading alloc] initWithColorSpace:colorSpace startPoint:start endPoint:end function:function extendStart:extendStart extendEnd:extendEnd domain:domain];    
}

KGShading *radialShading(KGPDFDictionary *dictionary,KGColorSpace *colorSpace){
   KGPDFArray *coordsArray;
   KGPDFArray *domainArray;
   float       domain[2]={0,1};
   KGPDFDictionary *fnDictionary;
   KGPDFArray *extendArray;
   NSPoint     start;
   KGPDFReal    startRadius;
   NSPoint     end;
   KGPDFReal    endRadius;
   KGFunction *function;
   KGPDFBoolean extendStart=NO;
   KGPDFBoolean extendEnd=NO;
   
//NSLog(@"axialShading=%@",dictionary);

   if(![dictionary getArrayForKey:"Coords" value:&coordsArray]){
    NSLog(@"No Coords entry in radial shader");
    return NULL;
   }
   else {    
    if(![coordsArray getNumberAtIndex:0 value:&start.x]){
     NSLog(@"No real at Coords[0]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:1 value:&start.y]){
     NSLog(@"No real at Coords[1]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:2 value:&startRadius]){
     NSLog(@"No real at Coords[2]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:3 value:&end.x]){
     NSLog(@"No real at Coords[3]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:4 value:&end.y]){
     NSLog(@"No real at Coords[4]");
     return NULL;
    }
    if(![coordsArray getNumberAtIndex:5 value:&endRadius]){
     NSLog(@"No real at Coords[5]");
     return NULL;
    }
   }
   
   if(![dictionary getArrayForKey:"Domain" value:&domainArray])
    domainArray=nil;
   else {
    if(![domainArray getNumberAtIndex:0 value:&(domain[0])]){
     NSLog(@"No real at Domain[0]");
     return NULL;
    }
    if(![domainArray getNumberAtIndex:1 value:&(domain[1])]){
     NSLog(@"No real at Domain[1]");
     return NULL;
    }
   }

   if(![dictionary getDictionaryForKey:"Function" value:&fnDictionary]){
    NSLog(@"No Function entry in radial shader");
    return NULL;
   }
   if((function=[KGFunction pdfFunctionWithDictionary:fnDictionary])==NULL)
    return NULL;
    
   if([dictionary getArrayForKey:"Extend" value:&extendArray]){
    if(![extendArray getBooleanAtIndex:0 value:&extendStart]){
     NSLog(@"Extend dictionary missing boolean at 0");
     return NULL;
    }
    if(![extendArray getBooleanAtIndex:1 value:&extendEnd]){
     NSLog(@"Extend dictionary missing boolean at 1");
     return NULL;
    }
   }
   
   return [[KGShading alloc] initWithColorSpace:colorSpace startPoint:start startRadius:startRadius endPoint:end endRadius:endRadius function:function extendStart:extendStart extendEnd:extendEnd domain:domain];        
}

+(KGShading *)shadingWithPDFObject:(KGPDFObject *)object {
   KGPDFDictionary *dictionary;
   KGShading       *result=nil;
   KGPDFObject     *colorSpaceObject;
   KGColorSpace    *colorSpace;
   KGPDFInteger     shadingType;
   
   if(![object checkForType:kKGPDFObjectTypeDictionary value:&dictionary])
    return nil;
   
  // NSLog(@"sh=%@",dictionary);
   if(![dictionary getIntegerForKey:"ShadingType" value:&shadingType]){
    NSLog(@"required ShadingType missing");
    return nil;
   }
   if(![dictionary getObjectForKey:"ColorSpace" value:&colorSpaceObject]){
    NSLog(@"required ColorSpace missing");
    return nil;
   }
   if((colorSpace=[KGColorSpace colorSpaceFromPDFObject:colorSpaceObject])==nil)
    return;
    
   switch(shadingType){
    case 1: // Function-base shading
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 2: // Axial shading
     result=axialShading(dictionary,colorSpace);
     break;
    case 3: // Radial shading
     result=radialShading(dictionary,colorSpace);
     break;
    case 4: // Free-form Gouraud-shaded triangle mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 5: // Lattice-form Gouraud-shaded triangle mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 6: // Coons patch mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    case 7: // Tensor-product patch mesh
     NSLog(@"Unsupported shading type %d",shadingType);
     break;
    default: // unknown
     NSLog(@"Unknown shading type %d",shadingType);
     break;
   }
   
   return result;
}

@end
