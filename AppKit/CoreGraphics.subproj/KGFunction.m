/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGFunction.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <stddef.h>

@implementation KGFunction

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


@end
