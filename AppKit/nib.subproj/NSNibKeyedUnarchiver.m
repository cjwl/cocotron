/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSNibKeyedUnarchiver.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSException.h>

@implementation NSNibKeyedUnarchiver

-initForReadingWithData:(NSData *)data externalNameTable:(NSDictionary *)table {
   [super initForReadingWithData:data];
   _nameTable=[table retain];
   return self;
}

-(void)dealloc {
   [_nameTable release];
   [super dealloc];
}

-(NSDictionary *)externalNameTable {
   return _nameTable;
}

-(NSArray *)allObjects {
   NSMutableArray *result=[NSMutableArray array];
   NSMapEnumerator state=NSEnumerateMapTable(_uidToObject);
   void           *key,*value;
   
   while(NSNextMapEnumeratorPair(&state,&key,&value))
    if(value!=NULL)
     [result addObject:(id)value];
     
   return result;
}


-(NSArray *)decodeArrayOfUidsForKey:(NSString *)key {
   NSMutableArray *result=[NSMutableArray array];
   id              plist=[[_plistStack lastObject] objectForKey:key];
   int             i,count;
   
   if(plist==nil)
    return nil;
   
   if(![plist isKindOfClass:[NSDictionary class]])
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] expecting dictionary plist, got %@",isa,sel_getName(_cmd),[plist class]];
   
   plist=[_objects objectAtIndex:[[plist objectForKey:@"CF$UID"] intValue]];
   plist=[plist objectForKey:@"NS.objects"];
   
   if(![plist isKindOfClass:[NSArray class]]){
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] expecting array plist, got %@",isa,sel_getName(_cmd),[plist class]];
    return nil;
   }
   count=[plist count];
   for(i=0;i<count;i++){
    NSDictionary *check=[plist objectAtIndex:i];
    NSNumber     *uid;
    
    if(![check isKindOfClass:[NSDictionary class]])
     [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] expecting dictionary plist, got %@",isa,sel_getName(_cmd),[plist class]];
    
    uid=[check objectForKey:@"CF$UID"];
    
    if(![uid isKindOfClass:[NSNumber class]])
     [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] expecting number, got %@",isa,sel_getName(_cmd),[plist class]];
    
    [result addObject:uid];
   }
   
   return result;
}

-(void)replaceObject:object atUid:(int)uid {
   NSMapInsert(_uidToObject,(void *)uid,object);
}

@end
