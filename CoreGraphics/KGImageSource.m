/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImageSource.h"
#import <Foundation/NSData.h>
#import "KGDataProvider.h"
#import "KGExceptions.h"

@implementation KGImageSource

+(KGImageSource *)newImageSourceWithDataProvider:(O2DataProvider *)provider options:(NSDictionary *)options {
   NSString *classes[]={
    @"KGImageSource_PNG",
    @"KGImageSource_TIFF",
    @"KGImageSource_JPEG",
    @"KGImageSource_BMP",
    @"KGImageSource_GIF",
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

+(KGImageSource *)newImageSourceWithData:(NSData *)data options:(NSDictionary *)options {
   O2DataProvider *provider=[[O2DataProvider alloc] initWithData:data];
   KGImageSource  *result=[self newImageSourceWithDataProvider:provider options:options];
   [provider release];
   return result;
}

+(KGImageSource *)newImageSourceWitURL:(NSURL *)url options:(NSDictionary *)options {
   O2DataProvider *provider=[[O2DataProvider alloc] initWithURL:url];
   KGImageSource  *result=[self newImageSourceWithDataProvider:provider options:options];
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
   KGInvalidAbstractInvocation();
   return 0;
}

-(NSDictionary *)copyPropertiesAtIndex:(unsigned)index options:(NSDictionary *)options {
   return nil;
}

-(O2Image *)createImageAtIndex:(unsigned)index options:(NSDictionary *)options {
  KGInvalidAbstractInvocation();
  return nil;
}

@end
