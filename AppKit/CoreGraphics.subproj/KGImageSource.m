/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImageSource.h"
#import <Foundation/NSData.h>
#import "KGExceptions.h"

@implementation KGImageSource

+(KGImageSource *)newImageSourceWithData:(NSData *)data options:(NSDictionary *)options {
   static NSString *classes[]={
    @"KGImageSource_PNG",
    @"KGImageSource_TIFF",
    @"KGImageSource_JPEG",
    @"KGImageSource_BMP",
    nil
   };
   int i;
   
   for(i=0;classes[i]!=nil;i++){
    Class cls=NSClassFromString(classes[i]);
   
    if([cls isTypeOfData:data])
     return [[cls alloc] initWithData:data options:options];
   }
       
   return nil;
}

+(BOOL)isTypeOfData:(NSData *)data {
   KGInvalidAbstractInvocation();
   return NO;
}

-initWithData:(NSData *)data options:(NSDictionary *)options {
  KGInvalidAbstractInvocation();
  return nil;
}

-initWithURL:(NSURL *)url options:(NSDictionary *)options {
   NSData *data=[NSData dataWithContentsOfURL:url];
   
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithData:data options:options];
}

-(unsigned)count {
   KGInvalidAbstractInvocation();
   return 0;
}

-(NSDictionary *)propertiesAtIndex:(unsigned)index options:(NSDictionary *)options {
   return nil;
}

-(KGImage *)imageAtIndex:(unsigned)index options:(NSDictionary *)options {
  KGInvalidAbstractInvocation();
  return nil;
}

@end
