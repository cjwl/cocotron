/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImageSource_GIF.h"
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGImage.h"
#import "gif_lib.h"

@implementation KGImageSource_GIF

+(BOOL)isPresentInDataProvider:(KGDataProvider *)provider {
   enum { signatureLength=4 };
   unsigned char signature[signatureLength] = { 'G','I','F','8' };
   unsigned char check[signatureLength];
   NSInteger     i,size=[provider getBytes:check range:NSMakeRange(0,signatureLength)];
   
   if(size!=signatureLength)
    return NO;
    
   for(i=0;i<signatureLength;i++)
    if(signature[i]!=check[i])
     return NO;
     
   return YES;
}

-initWithDataProvider:(KGDataProvider *)provider options:(NSDictionary *)options {
   [super initWithDataProvider:provider options:options];
   
   return self;
}

-(void)dealloc {
   [_provider release];
   [super dealloc];
}

-(unsigned)count {
   return 0;
}

-(NSDictionary *)copyPropertiesAtIndex:(unsigned)index options:(NSDictionary *)options {
   return nil;
}


-(KGImage *)imageAtIndex:(unsigned)index options:(NSDictionary *)options {
   return nil;
}

@end
