/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSOpenGLPixelFormat.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>

@implementation NSOpenGLPixelFormat

static inline BOOL attributeHasArgument(NSOpenGLPixelFormatAttribute attribute){
   switch(attribute){
    case NSOpenGLPFAAuxBuffers:
    case NSOpenGLPFAColorSize:
    case NSOpenGLPFAAlphaSize:
    case NSOpenGLPFADepthSize:
    case NSOpenGLPFAStencilSize:
    case NSOpenGLPFAAccumSize:
    case NSOpenGLPFARendererID:
    case NSOpenGLPFAScreenMask:
     return YES;
   }
   return NO;
}

-initWithAttributes:(NSOpenGLPixelFormatAttribute *)attributes {
   int count;
   
   for(count=0;attributes[count]!=0;count++)
    if(attributeHasArgument(attributes[count]))
     count++;
        
   _attributes=NSZoneMalloc(NULL,sizeof(NSOpenGLPixelFormatAttribute)*(count+1));
   for(count=0;(_attributes[count]=attributes[count])!=0;count++)
    ;

   return self;
}

-(void)dealloc {
   NSZoneFree(NULL,_attributes);
   [super dealloc];
}

-initWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
    NSData                      *data=[coder decodeObjectForKey:@"NSPixelAttributes"];
    unsigned                     i,length=[data length];
    const unsigned char         *bytes=[data bytes];
    NSOpenGLPixelFormatAttribute attributes[length/4];
    unsigned                     a=0;
    
    if(length%4>0){
     NSLog(@"NSPixelAttributes is not a multiple of 4, length=%d",length);
     return nil;
    }
    
    for(i=0;i<length;){
     unsigned value;
     
     value=bytes[i++];
     value<<=8;
     value|=bytes[i++];
     value<<=8;
     value|=bytes[i++];
     value<<=8;
     value|=bytes[i++];
     attributes[a++]=value;
    }
     
    return [self initWithAttributes:attributes];
   }
   else
    NSUnimplementedMethod();

   return self;
}

-(void *)CGLPixelFormatObj {
   NSUnimplementedMethod();
}

-(int)numberOfVirtualScreens {
   NSUnimplementedMethod();
}

-(void)getValues:(long *)values forAttribute:(NSOpenGLPixelFormatAttribute)attribute forVirtualScreen:(int)screen {
   int i;
   
   for(i=0;_attributes[i]!=0;i++){
    BOOL hasArgument=attributeHasArgument(_attributes[i]);
    
    if(_attributes[i]==attribute){
     if(hasArgument)
      *values=_attributes[i+1];
     else
      *values=1;
     
     return;
    }
    
    if(hasArgument)
     i++;
   }
   *values=0;
}

@end
