/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGFunction.h"
#import "KGPDFFunction_Type2.h"
#import "KGPDFFunction_Type3.h"
#import "KGPDFArray.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFContext.h"
#import <stddef.h>

@implementation KGFunction

-initWithDomain:(KGPDFArray *)domain range:(KGPDFArray *)range {   
   if(![domain getNumbers:&_domain count:&_domainCount]){
    [self dealloc];
    return nil;
   }
   
   [range getNumbers:&_range count:&_rangeCount];
      
   return self;
}

-initWithInfo:(void *)info domainCount:(unsigned)domainCount domain:(const float *)domain rangeCount:(unsigned)rangeCount range:(const float *)range callbacks:(const CGFunctionCallbacks *)callbacks {
   int i;
   
   _info=info;
   
   _domainCount=domainCount;
   _domain=NSZoneMalloc(NULL,sizeof(float)*_domainCount);
   if(domain==NULL){
    for(i=0;i<_domainCount;i++)
     _domain[i]=i%2;
   }
   else {
    for(i=0;i<_domainCount;i++)
     _domain[i]=domain[i];
   }
      
   _rangeCount=rangeCount;
   _range=NSZoneMalloc(NULL,sizeof(float)*_rangeCount);
   if(range==NULL){
    for(i=0;i<_rangeCount;i++)
     _range[i]=i%2;
   }
   else {
    for(i=0;i<_rangeCount;i++)
     _range[i]=range[i];
   }
   
   _callbacks=*callbacks;
   return self;
}

-(void)dealloc {
   if(_domain!=NULL)
    NSZoneFree(NULL,_domain);
   if(_range!=NULL)
    NSZoneFree(NULL,_range);
   if(_callbacks.releaseInfo!=NULL)
    _callbacks.releaseInfo(_info);
   [super dealloc];
}

-(unsigned)domainCount {
   return _domainCount;
}

-(const float *)domain {
   return _domain;
}

-(unsigned)rangeCount {
   return _rangeCount;
}

-(const float *)range {
   return _range;
}

-(BOOL)isLinear {
   return NO;
}

-(void)evaluateInput:(float)x output:(float *)output {
  float inputs[1];
  int   i;

  if(x<_domain[0])
   x=_domain[0];
  else if(x>_domain[1])
   x=_domain[1];

  inputs[0]=x; 
  _callbacks.evaluate(_info,inputs,output);
  
  for(i=0;i<_rangeCount/2;i++){
   if(output[i]<_range[i*2])
    output[i]=_range[i*2];
   else if(output[i]>_range[i*2+1])
    output[i]=_range[i*2+1];
  }
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   int              i,numberOfSamples=1024,numberOfChannels=_rangeCount/2;
   KGPDFStream     *result=[KGPDFStream pdfStream];
   KGPDFDictionary *dictionary=[result dictionary];
   unsigned char    samples[numberOfSamples*numberOfChannels];
   
   [dictionary setIntegerForKey:"FunctionType" value:0];
   [dictionary setObjectForKey:"Domain" value:[KGPDFArray pdfArrayWithNumbers:_domain count:_domainCount]];
   [dictionary setObjectForKey:"Range" value:[KGPDFArray pdfArrayWithNumbers:_range count:_rangeCount]];
   [dictionary setObjectForKey:"Size" value:[KGPDFArray pdfArrayWithIntegers:&numberOfSamples count:1]];
   [dictionary setIntegerForKey:"BitsPerSample" value:8];
   [dictionary setIntegerForKey:"Order" value:1];
   for(i=0;i<numberOfSamples;i++){
    float x=_domain[0]+((float)i/(float)numberOfSamples)*(_domain[1]-_domain[0]);
    float output[numberOfChannels];
    int   j;
    
    [self evaluateInput:x output:output];
    
    for(j=0;j<numberOfChannels;j++){
     samples[i*numberOfChannels+j]=((output[j]-_range[j*2])/(_range[j*2+1]-_range[j*2]))*255;
    }
   }
   [[result mutableData] appendBytes:samples length:numberOfSamples*numberOfChannels];

   return [context encodeIndirectPDFObject:result];
}

+(KGFunction *)pdfFunctionWithDictionary:(KGPDFDictionary *)dictionary {
   KGPDFInteger type;
   KGPDFArray  *domain;
   KGPDFArray  *range;
   
   if(![dictionary getIntegerForKey:"FunctionType" value:&type]){
    NSLog(@"Function missing FunctionType");
    return nil;
   }
   
   if(![dictionary getArrayForKey:"Domain" value:&domain]){
    NSLog(@"Function missing Domain");
    return nil;
   }
   
   if(![dictionary getArrayForKey:"Range" value:&range])
    range=nil;
       
   if(type==0){
    NSLog(@"Sampled functions not implemented");
    return nil;
   }
   else if(type==2){
    KGPDFArray *C0;
    KGPDFArray *C1;
    KGPDFReal   N;
    
    if(![dictionary getArrayForKey:"C0" value:&C0]){
     NSLog(@"No C0");
     C0=nil;
    }
    if(![dictionary getArrayForKey:"C1" value:&C1]){
     NSLog(@"No C1");
     C1=nil;
    }
    if(![dictionary getNumberForKey:"N" value:&N]){
     NSLog(@"Type 2 function missing N");
     return nil;
    }

    return [[[KGPDFFunction_Type2 alloc] initWithDomain:domain range:range C0:C0 C1:C1 N:N] autorelease];
   }
   else if(type==3){
    KGPDFArray     *functionsArray;
    NSMutableArray *functions;
    int             i,count;
    KGPDFArray     *bounds;
    KGPDFArray     *encode;
    
    if(![dictionary getArrayForKey:"Functions" value:&functionsArray]){
     NSLog(@"Functions entry missing from stitching function");
     return nil;
    }
    count=[functionsArray count];
    functions=[NSMutableArray arrayWithCapacity:count];
    for(i=0;i<count;i++){
     KGPDFDictionary *subfnDictionary;
     KGFunction   *subfn;
     
     if(![functionsArray getDictionaryAtIndex:i value:&subfnDictionary]){
      NSLog(@"Functions[%d] not a dictionary",i);
      return nil;
     }
     
     if((subfn=[KGFunction pdfFunctionWithDictionary:subfnDictionary])==nil)
      return nil;
      
     [functions addObject:subfn];
    }
    
    if(![dictionary getArrayForKey:"Bounds" value:&bounds])
     return nil;
    if(![dictionary getArrayForKey:"Encode" value:&encode])
     return nil;
     
    return [[[KGPDFFunction_Type3 alloc] initWithDomain:domain range:range functions:functions bounds:bounds encode:encode] autorelease];
   }
   else if(type==4){
    NSLog(@"PostScript calculator functions not implemented");
    return nil;
   }
   
   return nil;
}

@end
