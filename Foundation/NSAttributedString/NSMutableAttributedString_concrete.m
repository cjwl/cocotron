/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSMutableAttributedString_concrete.h>
#import <Foundation/NSMutableString_proxyToMutableAttributedString.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSDictionary.h>

@implementation NSMutableAttributedString_concrete

-initWithString:(NSString *)string {
   _string=[string mutableCopy];
   _rangeToAttributes=NSCreateRangeToCopiedObjectEntries(0);
   NSRangeEntryInsert(_rangeToAttributes,NSMakeRange(0,[_string length]),[NSDictionary dictionary]);
   return self;
}

-(void)dealloc {
   [_string release];
   NSFreeRangeEntries(_rangeToAttributes);
   NSDeallocateObject(self);
   return;
   [super dealloc];
}

-(NSString *)string {
   return _string;
}

-(NSDictionary *)attributesAtIndex:(unsigned)location
   effectiveRange:(NSRangePointer)effectiveRangep {
   NSDictionary *result;

   if(location>=[self length])
    NSRaiseException(NSRangeException,self,_cmd,@"index %d beyond length %d",location,[self length]);

   if((result=NSRangeEntryAtIndex(_rangeToAttributes,location,effectiveRangep))==nil)
    result=[NSDictionary dictionary];

   if(effectiveRangep!=NULL && effectiveRangep->length==NSNotFound)
    effectiveRangep->length=[self length]-effectiveRangep->location;

   return result;
}

-(void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
   int delta=[string length]-range.length;

   [_string replaceCharactersInRange:range withString:string];
   NSRangeEntriesExpandAndWipe(_rangeToAttributes,range,delta);
   if(NSCountRangeEntries(_rangeToAttributes)==0)
    NSRangeEntryInsert(_rangeToAttributes,NSMakeRange(0,[_string length]),[NSDictionary dictionary]);

NSRangeEntriesVerify(_rangeToAttributes,[self length]);
}

-(void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
   if(attributes==nil)
    attributes=[NSDictionary dictionary];

   if([_string length]==0){
    NSResetRangeEntries(_rangeToAttributes);
    NSRangeEntryInsert(_rangeToAttributes,range,attributes);
   }
   else if(range.length>0){
    NSRangeEntriesDivideAndConquer(_rangeToAttributes,range);
    NSRangeEntryInsert(_rangeToAttributes,range,attributes);
   }

NSRangeEntriesVerify(_rangeToAttributes,[self length]);
}

-(NSMutableString *)mutableString {
   return [[[NSMutableString_proxyToMutableAttributedString allocWithZone:NULL] initWithMutableAttributedString:self] autorelease];
}

-(void)fixAttributesAfterEditingRange:(NSRange)range {
}


@end
