/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import <AppKit/KGPDFObject.h>
#import <Foundation/NSMapTable.h>

@class KGPDFObject,KGPDFArray,KGPDFStream,KGPDFString;

@interface KGPDFDictionary : KGPDFObject {
   NSMapTable *_table;
}

+(KGPDFDictionary *)pdfDictionary;

-(void)setObjectForKey:(const char *)key value:(KGPDFObject *)object;
-(void)setBooleanForKey:(const char *)key value:(KGPDFBoolean)value;
-(void)setIntegerForKey:(const char *)key value:(KGPDFInteger)value;
-(void)setNumberForKey:(const char *)key value:(KGPDFReal)value;
-(void)setNameForKey:(const char *)key value:(const char *)value;

-(KGPDFObject *)inheritedForCStringKey:(const char *)cStringKey
   typecheck:(KGPDFObjectType)aType;

-(BOOL)getObjectForKey:(const char *)key value:(KGPDFObject **)objectp;
-(BOOL)getNullForKey:(const char *)key;
-(BOOL)getBooleanForKey:(const char *)key value:(KGPDFBoolean *)valuep;
-(BOOL)getIntegerForKey:(const char *)key value:(KGPDFInteger *)valuep;
-(BOOL)getNumberForKey:(const char *)key value:(KGPDFReal *)valuep;
-(BOOL)getNameForKey:(const char *)key value:(const char **)namep;
-(BOOL)getStringForKey:(const char *)key value:(KGPDFString **)stringp;
-(BOOL)getArrayForKey:(const char *)key value:(KGPDFArray **)arrayp;
-(BOOL)getDictionaryForKey:(const char *)key value:(KGPDFDictionary **)dictionaryp;
-(BOOL)getStreamForKey:(const char *)key value:(KGPDFStream **)streamp;

@end

unsigned KGPDFHashCString(NSMapTable *table,const void *data);
BOOL KGPDFIsEqualCString(NSMapTable *table,const void *data1,const void *data2);
void KGPDFFreeCString(NSMapTable *table,void *data);
NSMapTableKeyCallBacks KGPDFOwnedCStringKeyCallBacks;
