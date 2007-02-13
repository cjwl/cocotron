/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFxref.h"
#import "KGPDFxrefEntry.h"
#import "KGPDFObject_const.h"
#import "KGPDFDictionary.h"
#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>

@implementation KGPDFxref

-initWithData:(NSData *)data {
   _data=[data retain];
   _previous=nil;
   _numberToEntries=NSCreateMapTable(NSIntMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   _entryToObject=NSCreateMapTable(NSObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   _trailer=nil;   
   return self;
}

-(void)dealloc {
   [_data release];
   [_previous release];
   NSFreeMapTable(_numberToEntries);
   NSFreeMapTable(_entryToObject);
   [_trailer release];
   [super dealloc];
}

-(NSData *)data {
   return _data;
}

-(KGPDFxref *)previous {
   return _previous;
}

-(NSArray *)allEntries {
   NSMutableArray *result=[NSMutableArray array];
   NSMapEnumerator state=NSEnumerateMapTable(_numberToEntries);
   int             key;
   id              value;
   
   while(NSNextMapEnumeratorPair(&state,(void **)&key,(void **)&value)){
    if([value isKindOfClass:[NSArray class]])
     [result addObjectsFromArray:value];
    else
     [result addObject:value];
   }
   
   return result;
}


-(KGPDFxrefEntry *)entryWithNumber:(KGPDFInteger)number generation:(KGPDFInteger)generation {
   void *key=(void *)number;
   id    check=NSMapGet(_numberToEntries,key);
   
   if([check isKindOfClass:[NSArray class]]){
    NSArray *array=check;
    int      i,count=[check count];
    
    for(i=0;i<count;i++){
     KGPDFxrefEntry *entry=[array objectAtIndex:i];
     
     if([entry generation]==generation)
      return entry;
    }
   }
   
   return check;
}

-(KGPDFObject *)objectAtNumber:(KGPDFInteger)number generation:(KGPDFInteger)generation {
   KGPDFxrefEntry *lookup=[self entryWithNumber:number generation:generation];
   
   if(lookup==nil)
    return [KGPDFObject_const pdfObjectWithNull];
   else {
    KGPDFObject *result=NSMapGet(_entryToObject,lookup);

    if(result==nil){
     if(!KGPDFParseIndirectObject(_data,[lookup position],&result,number,generation,self))
      result=[KGPDFObject_const pdfObjectWithNull];
      
     NSMapInsert(_entryToObject,lookup,result);
    }
    
    return result;
   }
}

-(KGPDFDictionary *)trailer {
   return _trailer;
}

-(void)setPreviousTable:(KGPDFxref *)table {
   [_previous autorelease];
   _previous=[table retain];
}

-(void)addEntry:(KGPDFxrefEntry *)entry {
   void *key=(void *)[entry number];
   id    check=NSMapGet(_numberToEntries,key);
   
   if(check==nil)
    NSMapInsert(_numberToEntries,key,entry);
   if([check isKindOfClass:[NSMutableArray class]])
    [check addObject:entry];
   else if([check isKindOfClass:[KGPDFxrefEntry class]])
    NSMapInsert(_numberToEntries,key,[NSMutableArray arrayWithObject:entry]);
}

-(void)setTrailer:(KGPDFDictionary *)trailer {
   [_trailer autorelease];
   _trailer=[trailer retain];
}


@end
