/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSStringHashing.h>
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation NSMethodSignature

-initWithTypes:(const char *)types {
   const char *next,*last;
   NSUInteger    size,align;
   BOOL        first=YES;

    // not guaranteed that types is static
   _typesCString=NSZoneMalloc(NULL,strlen(types)+1);
   strcpy(_typesCString,types);
   next=last=_typesCString;
   _returnType=nil;
   _types=[[NSMutableArray allocWithZone:NULL] init];

   while((next=NSGetSizeAndAlignment(next,&size,&align))!=last){
    NSString *string=[NSString stringWithCString:last length:next-last];

    if(first)
     _returnType=[string copy];
    else
     [_types addObject:string];

    first=NO;

    while((*next>='0' && *next<='9') || *next=='+' || *next=='-' || *next=='?')
     next++; 

    if(*next=='\0')
      break;

    last=next;
   }

   return self;
}

-(void)dealloc {
   NSZoneFree(NULL,_typesCString);
   [_returnType release];
   [_types release];
	if([self respondsToSelector:@selector(_deallocateClosure)])
		[self performSelector:@selector(_deallocateClosure)];
   [super dealloc];
}

+(NSMethodSignature *)signatureWithObjCTypes:(const char *)types {
   return [[[NSMethodSignature allocWithZone:NULL] initWithTypes:types] autorelease];
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<NSMethodSignature: -(%@)%@>",_returnType,_types];
}

-(NSUInteger)hash {
   return NSStringHashZeroTerminatedASCII(_typesCString);
}

-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[NSMethodSignature class]]){
    NSMethodSignature *other=otherObject;

    return (strcmp(_typesCString,other->_typesCString)==0)?YES:NO;
   }

   return NO;
}

-(BOOL)isOneway {
   return [_returnType hasPrefix:@"V"];
}

-(NSUInteger)frameLength {
   NSUInteger result=0;
   NSInteger      i,count=[self numberOfArguments];

   for(i=0;i<count;i++){
    NSUInteger align;
    NSUInteger naturalSize;
    NSUInteger promotedSize;

    NSGetSizeAndAlignment([self getArgumentTypeAtIndex:i],&naturalSize,&align);
    promotedSize=((naturalSize+sizeof(long)-1)/sizeof(long))*sizeof(long);

    result+=promotedSize;
   }
   return result;
}

-(NSUInteger)methodReturnLength {
   NSUInteger size,align;

   NSGetSizeAndAlignment([_returnType cString],&size,&align);

   return size;
}

-(const char *)methodReturnType {
   return [_returnType cString];
}

-(NSUInteger)numberOfArguments {
   return [_types count];
}

-(const char *)getArgumentTypeAtIndex:(NSUInteger)index {
   return [[_types objectAtIndex:index] cString];
}

@end
