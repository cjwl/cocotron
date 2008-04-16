/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>, David Young <daver@geeks.org>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSStringHashing.h>
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation NSMethodSignature

static unsigned stringHash(NSMapTable *table,const void *data){
   const char *s=data;

   if(s!=NULL)
    return NSStringHashZeroTerminatedASCII(s);

   return 0;
}

static BOOL stringIsEqual(NSMapTable *tabl,const void *data1,const void *data2){
    if (data1 == data2)
        return YES;

    if (!data1)
        return ! strlen ((char *) data2);

    if (!data2)
        return ! strlen ((char *) data1);

    if (((char *) data1)[0] != ((char *) data2)[0])
        return NO;

    return (strcmp ((char *) data1, (char *) data2)) ? NO : YES;
}

static NSMapTableKeyCallBacks keyCallBacks = {
  stringHash,stringIsEqual,NULL,NULL,NULL,NULL
};

static NSMapTable *_cache=NULL;

+(void)initialize {
   if(self==[NSMethodSignature class])
    _cache=NSCreateMapTable(keyCallBacks,NSObjectMapValueCallBacks,0);
}

-initWithTypes:(const char *)types {
   const char *next=types,*last=types;
   unsigned    size,align;
   BOOL        first=YES;

   _typesCString=types;
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
   [_returnType release];
   [_types release];
   [super dealloc];
}

NSMethodSignature *NSMethodSignatureWithTypes(const char *types) {
   NSMethodSignature *entry;
   char              *typesCopy;
      
   if(_cache==NULL)
    [NSMethodSignature class]; // initialize

   entry=NSMapGet(_cache,types);

   if(entry==nil){
    entry=[[NSMethodSignature allocWithZone:NULL] initWithTypes:types];

    // not guaranteed that types is static
    typesCopy=NSZoneMalloc(NULL,strlen(types)+1);
    strcpy(typesCopy,types);

    NSMapInsert(_cache,typesCopy,entry);

    [entry release];
   }

   return entry;
}

// This is private but needs to stay this name for compatibility 
+(NSMethodSignature *)signatureWithObjCTypes:(const char *)types {
   return NSMethodSignatureWithTypes(types);
}


-(NSString *)description {
   return [NSString stringWithFormat:@"<NSMethodSignature: -(%@)%@>",_returnType,_types];
}

-(unsigned)hash {
   return stringHash(NULL,_typesCString);
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

-(unsigned)frameLength {
   unsigned result=0;
   int      i,count=[self numberOfArguments];

   for(i=0;i<count;i++){
    unsigned align;
    unsigned naturalSize;
    unsigned promotedSize;

    NSGetSizeAndAlignment([self getArgumentTypeAtIndex:i],&naturalSize,&align);
    promotedSize=((naturalSize+sizeof(int)-1)/sizeof(int))*sizeof(int);

    result+=promotedSize;
   }
   return result;
}

-(unsigned)methodReturnLength {
   unsigned size,align;

   NSGetSizeAndAlignment([_returnType cString],&size,&align);

   return size;
}

-(const char *)methodReturnType {
   return [_returnType cString];
}

-(unsigned)numberOfArguments {
   return [_types count];
}

-(const char *)getArgumentTypeAtIndex:(unsigned)index {
   return [[_types objectAtIndex:index] cString];
}

@end
