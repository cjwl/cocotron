/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>, David Young <daver@geeks.org>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSRaise.h>

@implementation NSInvocation

-(void)buildFrame {
   int      i,count=[_signature numberOfArguments];
   unsigned align;

   NSGetSizeAndAlignment([_signature methodReturnType],&_returnSize,&align);
   _returnValue=NSZoneCalloc([self zone],_returnSize,1);

   _argumentFrameSize=0;
   _argumentSizes=NSZoneCalloc([self zone],count,sizeof(unsigned));
   _argumentOffsets=NSZoneCalloc([self zone],count,sizeof(unsigned));

   for(i=0;i<count;i++){
    unsigned naturalSize;
    unsigned promotedSize;

    _argumentOffsets[i]=_argumentFrameSize;

    NSGetSizeAndAlignment([_signature getArgumentTypeAtIndex:i],&naturalSize,&align);
    promotedSize=((naturalSize+sizeof(int)-1)/sizeof(int))*sizeof(int);

    _argumentSizes[i]=naturalSize;
    _argumentFrameSize+=promotedSize;
   }
}

-initWithMethodSignature:(NSMethodSignature *)signature {
   _signature=[signature retain];

   [self buildFrame];

   _argumentFrame=NSZoneCalloc([self zone],_argumentFrameSize,1);

   return self;
}

-initWithMethodSignature:(NSMethodSignature *)signature
   arguments:(void *)arguments {
   unsigned       i;
   unsigned char *stackFrame=arguments;

   [self initWithMethodSignature:signature];

   for(i=0;i<_argumentFrameSize;i++)
    _argumentFrame[i]=stackFrame[i];

   return self;
}

-(void)dealloc {
    if (_retainArguments == YES) {
        int i, count = [_signature numberOfArguments];

        for (i = 0; i < count; ++i) {
            const char *type = [_signature getArgumentTypeAtIndex:i];

            switch (type[0]) {
                case '@': {
                    id object;

                    [self getArgument:&object atIndex:i];
                    [object release];
                    break;
                }

                case '*': {
                    char *ptr;

                    [self getArgument:&ptr atIndex:i];
                    NSZoneFree([self zone], ptr);
                    break;
                }

                default:
                    break;
            }
        }
    }

   NSZoneFree([self zone],_returnValue);
   NSZoneFree([self zone],_argumentSizes);
   NSZoneFree([self zone],_argumentOffsets);
   NSZoneFree([self zone],_argumentFrame);
   [_signature release];
   NSDeallocateObject(self);
}

static void *bufferForType(void *buffer,const char *type){
   unsigned size,align;

   NSGetSizeAndAlignment(type,&size,&align);
   if(buffer!=NULL)
    NSZoneFree(NULL,buffer);

   return NSZoneMalloc(NULL,size);
}

-initWithCoder:(NSCoder *)coder {
   const char *type;
   int         i,count;
   void       *buffer=NULL;

   _signature=[[coder decodeObject] retain];

   [self buildFrame];

   _argumentFrame=NSZoneCalloc([self zone],_argumentFrameSize,1);

   if([_signature methodReturnLength]>0){
    type=[_signature methodReturnType];
    buffer=bufferForType(buffer,type);
    [coder decodeValueOfObjCType:type at:buffer];
    [self setReturnValue:buffer];
   }

   count=[_signature numberOfArguments];
   for(i=0;i<count;i++){
    type=[_signature getArgumentTypeAtIndex:i];
    buffer=bufferForType(buffer,type);
    [coder decodeValueOfObjCType:type at:buffer];
    [self setArgument:buffer atIndex:i];
   }
   NSZoneFree(NULL,buffer);

   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   const char *type;
   int         i,count;
   void       *buffer=NULL;

   [coder encodeObject:_signature];

   if([_signature methodReturnLength]>0){
    type=[_signature methodReturnType];
    buffer=bufferForType(buffer,type);
    [self getReturnValue:buffer];
    [coder encodeValueOfObjCType:type at:buffer];
   }

   count=[_signature numberOfArguments];
   for(i=0;i<count;i++){
    type=[_signature getArgumentTypeAtIndex:i];
    buffer=bufferForType(buffer,type);
    [self getArgument:buffer atIndex:i];
    [coder encodeValueOfObjCType:type at:buffer];
   }
}

+(NSInvocation *)invocationWithMethodSignature:(NSMethodSignature *)signature {
   return [[[self allocWithZone:NULL] initWithMethodSignature:signature] autorelease];
}

+(NSInvocation *)invocationWithMethodSignature:(NSMethodSignature *)signature
   arguments:(void *)arguments {
   return [[[self allocWithZone:NULL] initWithMethodSignature:signature arguments:arguments] autorelease];
}

-(NSMethodSignature *)methodSignature {
   return _signature;
}

static void byteCopy(void *src,void *dst,unsigned length){
   int i;

   for(i=0;i<length;i++)
    ((char *)dst)[i]=((char *)src)[i];
}

-(void)getReturnValue:(void *)pointerToValue {
   byteCopy(_returnValue,pointerToValue,_returnSize);
}

-(void)setReturnValue:(void *)pointerToValue {
   byteCopy(pointerToValue,_returnValue,_returnSize);
}

-(void)getArgument:(void *)pointerToValue atIndex:(int)index {
   unsigned naturalSize=_argumentSizes[index];
   unsigned promotedSize=((naturalSize+sizeof(int)-1)/sizeof(int))*sizeof(int);
   
   if(naturalSize==promotedSize)
    byteCopy(_argumentFrame+_argumentOffsets[index],pointerToValue,naturalSize);
   else if(promotedSize==4){
    unsigned char promoted[promotedSize];
    
    byteCopy(_argumentFrame+_argumentOffsets[index],promoted,promotedSize);
    if(naturalSize==1)
     *((char *)pointerToValue)=*((int *)promoted);
    else if(naturalSize==2)
     *((short *)pointerToValue)=*((int *)promoted);
     
   }
   else
    [NSException raise:NSInvalidArgumentException format:@"Unable to convert naturalSize=%d to promotedSize=%d",naturalSize,promotedSize];
    
}

-(void)setArgument:(void *)pointerToValue atIndex:(int)index {
   unsigned naturalSize=_argumentSizes[index];
   unsigned promotedSize=((naturalSize+sizeof(int)-1)/sizeof(int))*sizeof(int);

   if(naturalSize==promotedSize)
    byteCopy(pointerToValue,_argumentFrame+_argumentOffsets[index],naturalSize);
   else if(promotedSize==4){
    unsigned char promoted[promotedSize];
    
    if(naturalSize==1)
     *((int *)promoted)=*((char *)pointerToValue);
    else if(naturalSize==2)
     *((int *)promoted)=*((short *)pointerToValue);

    byteCopy(promoted,_argumentFrame+_argumentOffsets[index],promotedSize);
   }
   else
    [NSException raise:NSInvalidArgumentException format:@"Unable to convert naturalSize=%d to promotedSize=%d",naturalSize,promotedSize];
}

-(void)retainArguments {
    if (_retainArguments == NO) {
        int i, count = [_signature numberOfArguments];
        
        _retainArguments=YES;
        for (i = 0; i < count; ++i) {
            const char *type = [_signature getArgumentTypeAtIndex:i];

            switch (type[0]) {
                case '@': {
                    id object;

                    [self getArgument:&object atIndex:i];
                    [object retain];
                    break;
                }
                    
                case '*': {
                    char *ptr, *copy, length;

                    [self getArgument:&ptr atIndex:i];
                    length = strlen(ptr);
                    copy = NSZoneCalloc([self zone], length+1, 1);
                    byteCopy(ptr, copy, length);
                    [self setArgument:&copy atIndex:i];
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
}

-(BOOL)argumentsRetained {
   return _retainArguments;
}

-(SEL)selector {
   SEL result;

   [self getArgument:&result atIndex:1];

   return result;
}

-(void)setSelector:(SEL)selector {
   [self setArgument:&selector atIndex:1];
}

-target {
   id result;

   [self getArgument:&result atIndex:0];

   return result;
}

-(void)setTarget:target {
   [self setArgument:&target atIndex:0];
}

-(void)invoke {
   [self invokeWithTarget:[self target]];
}

-(void)invokeWithTarget:target {
   const char *returnType=[_signature methodReturnType];
   void *msgSendv=objc_msg_sendv;

   switch(returnType[0]){
    case 'r':
    case 'n':
    case 'N':
    case 'o':
    case 'O':
    case 'R':
    case 'V':
     returnType++;
     break;
   }

   switch(returnType[0]){
    case 'c':
    case 'C': {
      char (*function)()=msgSendv;
      char value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 's':
    case 'S':{
      short (*function)()=msgSendv;
      short value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 'i':
    case 'I':
    case 'l':
    case 'L':{
      int (*function)()=msgSendv;
      int value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 'q':
    case 'Q':{
      long long (*function)()=msgSendv;
      long long value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 'f':{
      float (*function)()=msgSendv;
      float value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 'd':{
      double (*function)()=msgSendv;
      double value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    case 'v':{
      void (*function)()=msgSendv;

      function(target,[self selector],_argumentFrameSize,_argumentFrame);
     }
     break;

    case '*':
    case '@':
    case '#':
    case ':':{
      void *(*function)()=msgSendv;
      void *value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

      [self setReturnValue:&value];
     }
     break;

    default: {
     unsigned size,alignment;

      NSGetSizeAndAlignment(returnType,&size,&alignment);
      if(size<=sizeof(int)){
       int (*function)()=msgSendv;
       int value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

       [self setReturnValue:&value];
      }
      else if(size<=sizeof(long long)){
       long long (*function)()=msgSendv;
       long long value=function(target,[self selector],_argumentFrameSize,_argumentFrame);

       [self setReturnValue:&value];
      }
      else {
       struct structReturn {
        char result[size];
       } (*function)()=(struct structReturn (*)())msgSendv; // should be msgSend_stret
       struct structReturn value;

// FIX internal compiler error on windows
#ifndef WIN32
       value=function(target,[self selector],_argumentFrameSize,_argumentFrame);
#endif

       [self setReturnValue:&value];
      }
     }
     break;
   }
}

@end
