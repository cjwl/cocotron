/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2ImageSource.h"
#import <Foundation/NSData.h>
#import "O2DataProvider.h"
#import "O2Exceptions.h"

NSString *kO2ImagePropertyDPIWidth=@"kCGImagePropertyDPIWidth";
NSString *kO2ImagePropertyDPIHeight=@"kCGImagePropertyDPIHeight";

@implementation O2ImageSource

+(O2ImageSource *)newImageSourceWithDataProvider:(O2DataProvider *)provider options:(NSDictionary *)options {
   NSString *classes[]={
    @"O2ImageSource_PNG",
    @"O2ImageSource_TIFF",
    @"O2ImageSource_JPEG",
    @"O2ImageSource_BMP",
    @"O2ImageSource_GIF",
    nil
   };
   int i;
   
   for(i=0;classes[i]!=nil;i++){
    Class cls=NSClassFromString(classes[i]);
   
    if([cls isPresentInDataProvider:provider]){
     [provider rewind];
     return [[cls alloc] initWithDataProvider:provider options:options];
    }
   }
       
   return nil;
}

+(O2ImageSource *)newImageSourceWithData:(NSData *)data options:(NSDictionary *)options {
   O2DataProvider *provider=[[O2DataProvider alloc] initWithData:data];
   O2ImageSource  *result=[self newImageSourceWithDataProvider:provider options:options];
   [provider release];
   return result;
}

+(O2ImageSource *)newImageSourceWitURL:(NSURL *)url options:(NSDictionary *)options {
   O2DataProvider *provider=[[O2DataProvider alloc] initWithURL:url];
   O2ImageSource  *result=[self newImageSourceWithDataProvider:provider options:options];
   [provider release];
   return result;
}

+(BOOL)isPresentInDataProvider:(O2DataProvider *)provider {
   return NO;
}

-initWithDataProvider:(O2DataProvider *)provider options:(NSDictionary *)options {
   _provider=[provider retain];
   _options=[options retain];
   return self;
}

-(unsigned)count {
   O2InvalidAbstractInvocation();
   return 0;
}

-(NSDictionary *)copyPropertiesAtIndex:(unsigned)index options:(NSDictionary *)options {
   return nil;
}

-(O2Image *)createImageAtIndex:(unsigned)index options:(NSDictionary *)options {
  O2InvalidAbstractInvocation();
  return nil;
}

@end
