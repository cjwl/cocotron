/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFScanner.h"
#import "KGPDFOperatorTable.h"
#import "KGPDFContentStream.h"
#import "KGPDFStream.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFObject_Boolean.h"
#import "KGPDFObject_Integer.h"
#import "KGPDFObject_Real.h"
#import "KGPDFObject_Name.h"
#import "KGPDFObject_const.h"
#import "KGPDFObject_const.h"
#import "KGPDFObject_identifier.h"
#import "KGPDFObject_R.h"
#import "KGPDFString.h"
#import "KGPDFxrefEntry.h"
#import "KGPDFxref.h"
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>

#import <stddef.h>

#define LF 10
#define FF 12
#define CR 13

typedef struct {
   unsigned       capacity;
   unsigned       length;
    char *bytes;
} KGPDFByteBuffer;

static inline KGPDFByteBuffer *KGPDFByteBufferCreate(){
   KGPDFByteBuffer *result=NSZoneMalloc(NULL,sizeof(KGPDFByteBuffer));
   
   result->capacity=0;
   result->length=0;
   result->bytes=NULL;
   
   return result;
}

static inline void KGPDFByteBufferFree(KGPDFByteBuffer *buffer){
   if(buffer->bytes!=NULL)
    NSZoneFree(NULL,buffer->bytes);
   NSZoneFree(NULL,buffer);
}

static inline void KGPDFByteBufferReset(KGPDFByteBuffer *buffer){
   buffer->length=0;
}

static inline void KGPDFByteBufferAppend(KGPDFByteBuffer *buffer,unsigned char c){
   if(buffer->length>=buffer->capacity){
    if(buffer->capacity==0){
     buffer->capacity=128;
     buffer->bytes=NSZoneMalloc(NULL,buffer->capacity);
    }
    else {
     buffer->capacity*=2;
     buffer->bytes=NSZoneRealloc(NULL,buffer->bytes,buffer->capacity);
    }
   }
   buffer->bytes[buffer->length++]=c;
}

static inline unsigned char KGPDFByteBufferDecodeNibble(unsigned char nibble){
   if(nibble>='a' && nibble<='f')
    return (nibble-'a')+10;
   else if(nibble>='A' && nibble<='F')
    return (nibble-'A')+10;
   else if(nibble>='0' && nibble<='9')
    return nibble-'0';

   return 0xFF;
}

static inline BOOL KGPDFByteBufferAppendHighNibble(KGPDFByteBuffer *buffer,unsigned char nibble){
   if((nibble=KGPDFByteBufferDecodeNibble(nibble))==0xFF)
    return NO;
    
   nibble<<=4;
   KGPDFByteBufferAppend(buffer,nibble);
   return YES;
}

static inline BOOL KGPDFByteBufferAppendLowNibble(KGPDFByteBuffer *buffer,unsigned char nibble){
   if((nibble=KGPDFByteBufferDecodeNibble(nibble))==0xFF)
    return NO;
    
   buffer->bytes[buffer->length]|=nibble;

   return YES;
}

static inline BOOL KGPDFByteBufferAppendOctal(KGPDFByteBuffer *buffer,char octal){
   octal-='0';
   KGPDFByteBufferAppend(buffer,octal);

   return YES;
}
static inline BOOL KGPDFByteBufferAddOctal(KGPDFByteBuffer *buffer,char octal){
   octal-='0';
   buffer->bytes[buffer->length]<<=3;
   buffer->bytes[buffer->length]|=octal;

   return YES;
}

static void debugTracev(const char *bytes,unsigned length,KGPDFInteger position,NSString *format,va_list arguments) {
   NSString *dump=[NSString stringWithCString:bytes+position length:MIN(80,(length-position))];
   
   NSLogv(format,arguments);
   NSLog(@"position=%d,dump=[%@]",position,dump);
}

static void debugTrace(const char *bytes,unsigned length,KGPDFInteger position,NSString *format,...) {
   va_list arguments;

   va_start(arguments,format);
   return;
   debugTracev(bytes,length,position,format,arguments);
}

static BOOL debugError(const char *bytes,unsigned length,KGPDFInteger position,NSString *format,...) {
   va_list arguments;

   va_start(arguments,format);
   debugTracev(bytes,length,position,format,arguments);
   [NSException raise:@"" format:@""];;
   return NO;
}

BOOL KGPDFScanBackwardsByLines(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,int delta) {
   enum {
    STATE_LF_OR_CR,
    STATE_CR_OR_LINE,
    STATE_LINE
   } state=STATE_LF_OR_CR;

   debugTrace(bytes,length,position,@"KGPDFScanBackwardsByLines %d",delta);
   
   while(--position>=0){
    char c=bytes[position];

    switch(state){

     case STATE_LF_OR_CR:
      if(c==LF)
       state=STATE_CR_OR_LINE;
      else
       state=STATE_LINE;
      break;
     
     case STATE_CR_OR_LINE:
      if(c==CR){
       state=STATE_LINE;
       break;
      }
      // fallthru
     case STATE_LINE:
      if(c==CR || c==LF){
       delta--;
       if(delta<=0){
        *lastPosition=position+1;
        return YES;
       }
       state=(c==CR)?STATE_LINE:STATE_CR_OR_LINE;
      }
      break;
    }

   }

   return NO;
}

#if 0
-(BOOL)scanData:(NSData *)data position:(KGPDFInteger)position lastPosition:(KGPDFInteger *)lastPosition linesForward:(int)delta {
   const char *bytes=[data bytes];
   unsigned    length=[bytes length];
   enum {
    STATE_LINE,
    STATE_CR
   } state=STATE_LINE;

   for(;position<length;position++){
    char c=byteAtOffset(bytes,position);
    switch(state){

     case STATE_LINE:
      if(c==CR)
       state=STATE_CR;
      else if(c==LF){
       *lastPosition=position++;
       return YES;
      }
      break;

     case STATE_CR:
      if(c==LF)
       *lastPosition=position++;
      return YES;
    }
   }
   return NO;
}
#endif

BOOL KGPDFScanVersion(const char *bytes,unsigned length,KGPDFString **versionp) {
   KGPDFInteger position=length;
   
   if(length<8)
    return NO;
   
   if(strncmp(bytes,"%PDF-",5)!=0)
    return debugError(bytes,length,position,@"Does not begin with %PDF-");
   
   *versionp=[KGPDFString pdfObjectWithBytes:bytes+5 length:3];
   
   if(!KGPDFScanBackwardsByLines(bytes,length,position,&position,1))
    return debugError(bytes,length,position,@"Unable to back up one line");
   
   if(strncmp(bytes+position,"%%EOF",5)!=0)
    return debugError(bytes,length,position,@"Does not end with %%EOF");

   return YES;
}

BOOL KGPDFScanObject(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFObject **objectp) {
   KGPDFInteger     currentSign=1,currentInt=0;
   KGPDFReal        currentReal=0,currentFraction=0;
   int              inlineLocation=0;
   KGPDFByteBuffer *byteBuffer=NULL;
   
   enum {
    STATE_SCANNING,
    STATE_COMMENT,
    STATE_INTEGER,
    STATE_REAL,
    STATE_STRING_NOFREE,
    STATE_STRING_FREE,
    STATE_STRING_ESCAPE,
    STATE_STRING_0XX,
    STATE_STRING_00X,
    STATE_OPEN_ANGLE,
    STATE_HEX_STRING_NIBBLE1,
    STATE_HEX_STRING_NIBBLE2,
    STATE_NAME,
    STATE_CLOSE_ANGLE,
    STATE_IDENTIFIER,
   } state=STATE_SCANNING;
   
    debugTrace(bytes,length,position,@"KGPDFScanObject");

   for(;position<length;position++){
    unsigned char code=bytes[position];
	
	      //NSLog(@"state=%d,code=%c",state,code);
	switch(state){
          
	 case STATE_SCANNING:
	  switch(code){
	  
	   case ' ':
	   case  CR:
	   case  FF:
	   case  LF:
	   case '\t':
	    break;
		
       case '%':
        state=STATE_COMMENT;
        break;

       case '-':
        state=STATE_INTEGER;
	    currentSign=-1;
	    currentInt=0;
        break;
        
       case '+':
        state=STATE_INTEGER;
	    currentSign=1;
	    currentInt=0;
        break;

       case '0': case '1': case '2': case '3': case '4':
       case '5': case '6': case '7': case '8': case '9':
        state=STATE_INTEGER;
	    currentSign=1;
	    currentInt=code-'0';
        break;

       case '.':
        state=STATE_REAL;
	    currentSign=1;
	    currentReal=0;
        currentFraction=0.1;
        break;

       case '(':
        inlineLocation=position+1;
        state=STATE_STRING_NOFREE;
        break;

       case '<':
        state=STATE_OPEN_ANGLE;
        break;

       case '/':
        state=STATE_NAME;
        inlineLocation=position+1;
        break;

       case '[':
        *objectp=[KGPDFObject_const pdfObjectArrayMark];
        *lastPosition=position+1;
        return YES;

       case ']':
        *objectp=[KGPDFObject_const pdfObjectArrayMarkEnd];
        *lastPosition=position+1;
        return YES;

       case '>':
        state=STATE_CLOSE_ANGLE;
        break;

       case ')':
       case '{':
       case '}':
        return debugError(bytes,length,position,@"Unexpected character \'%c\'",code);

       default:
        state=STATE_IDENTIFIER;
        inlineLocation=position;
        break;
	  }
	  break;
	  
     case STATE_COMMENT:
      if(code==CR || code==LF || code==FF)
       state=STATE_SCANNING;
      break;

     case STATE_INTEGER:
      if(code=='.'){
       state=STATE_REAL;
       currentReal=currentInt;
       currentFraction=0.1;
      }
      else if(code>='0' && code<='9')
       currentInt=currentInt*10+code-'0';
      else {
       *objectp=[KGPDFObject_Integer pdfObjectWithInteger:currentSign*currentInt];
       *lastPosition=position;
       return YES;
      }
      break;

     case STATE_REAL:
      if(code>='0' && code<='9'){
       currentReal+=currentFraction*(code-'0');
       currentFraction*=0.1;
      }
      else {
       *objectp=[KGPDFObject_Real pdfObjectWithReal:currentSign*currentReal];
       *lastPosition=position;
       return YES;
      }
      break;

     case STATE_STRING_NOFREE:
      if(code==')'){
       *objectp=[KGPDFString pdfObjectWithBytesNoCopyNoFree:bytes+inlineLocation length:position-inlineLocation];
       *lastPosition=position+1;
       return YES;
      }
      else if(code=='\\'){
       int pos;
       
       byteBuffer=KGPDFByteBufferCreate();
       for(pos=inlineLocation;pos<position;pos++)
        KGPDFByteBufferAppend(byteBuffer,bytes[pos]);
        
       state=STATE_STRING_ESCAPE;
       break;
      }
      break;
      
     case STATE_STRING_FREE:
      if(code==')'){
       *objectp=[KGPDFString pdfObjectWithBytes:byteBuffer->bytes length:byteBuffer->length];
       KGPDFByteBufferFree(byteBuffer);
       *lastPosition=position+1;
       return YES;
      }
      else if(code=='\\'){
       state=STATE_STRING_ESCAPE;
       break;
      }
      else {
       KGPDFByteBufferAppend(byteBuffer,bytes[position]);
      }
      break;

     case STATE_STRING_ESCAPE:
      if(code=='n'){
       KGPDFByteBufferAppend(byteBuffer,'\n');
       state=STATE_STRING_FREE;
      }
      else if(code=='r'){
       KGPDFByteBufferAppend(byteBuffer,'\r');
       state=STATE_STRING_FREE;
      }
      else if(code=='t'){
       KGPDFByteBufferAppend(byteBuffer,'\t');
       state=STATE_STRING_FREE;
      }
      else if(code=='b'){
       KGPDFByteBufferAppend(byteBuffer,'\b');
       state=STATE_STRING_FREE;
      }
      else if(code=='f'){
       KGPDFByteBufferAppend(byteBuffer,'\f');
       state=STATE_STRING_FREE;
      }
      else if(code=='\\'){
       KGPDFByteBufferAppend(byteBuffer,'\\');
       state=STATE_STRING_FREE;
      }
      else if(code=='('){
       KGPDFByteBufferAppend(byteBuffer,'(');
       state=STATE_STRING_FREE;
      }
      else if(code==')'){
       KGPDFByteBufferAppend(byteBuffer,')');
       state=STATE_STRING_FREE;
      }
      else if(code==CR)
       state=STATE_STRING_FREE;
      else if(code==LF)
       state=STATE_STRING_FREE;
      else if(code>='0' || code<='7'){
       KGPDFByteBufferAppendOctal(byteBuffer,code);
       state=STATE_STRING_0XX;
      }
      else{
       KGPDFByteBufferFree(byteBuffer);
       return debugError(bytes,length,position,@"Invalid escape sequence code=0x%02X",code);
      }
      break;

     case STATE_STRING_0XX:
      if(code>='0' || code<='7'){
       KGPDFByteBufferAddOctal(byteBuffer,code);
       state=STATE_STRING_00X;
      }
      else{
       position--;
       state=STATE_STRING_FREE;
      }
      break;

     case STATE_STRING_00X:
      if(code>='0' || code<='7')
       KGPDFByteBufferAddOctal(byteBuffer,code);
      else
       position--;
       
      state=STATE_STRING_FREE;
      break;

     case STATE_OPEN_ANGLE:
      if(code=='<'){
       *objectp=[KGPDFObject_const pdfObjectDictionaryMark];
       *lastPosition=position+1;
       return YES;
      }
      else {
       byteBuffer=KGPDFByteBufferCreate();
       if(KGPDFByteBufferAppendHighNibble(byteBuffer,code))
        state=STATE_HEX_STRING_NIBBLE2;
       else
        return debugError(bytes,length,position,@"Invalid hex character code=0x%02X",code);
      }
      break;

     case STATE_HEX_STRING_NIBBLE1:
     case STATE_HEX_STRING_NIBBLE2:
      if(code=='>'){
       *objectp=[KGPDFString pdfObjectWithBytes:byteBuffer->bytes length:byteBuffer->length];
       KGPDFByteBufferFree(byteBuffer);
       *lastPosition=position+1;
       return YES;
      }
      else if(code==' ' || code==CR || code==FF || code==LF || code=='\t' || code=='\0')
       break;
      else if(state==STATE_HEX_STRING_NIBBLE1){
       if(KGPDFByteBufferAppendHighNibble(byteBuffer,code)){
        state=STATE_HEX_STRING_NIBBLE2;
        break;
       }
      }
      else if(state==STATE_HEX_STRING_NIBBLE2){
       if(KGPDFByteBufferAppendLowNibble(byteBuffer,code)){
        state=STATE_HEX_STRING_NIBBLE1;
        break;
       }
      }
      KGPDFByteBufferFree(byteBuffer);
      return debugError(bytes,length,position,@"Invalid hex character code=0x%02X",code);

     case STATE_NAME:
      if(code==' ' || code==CR || code==FF || code==LF || code=='\t' || code=='\0' ||
         code=='%' || code=='(' || code==')' || code=='<' || code=='>' || code==']' ||
         code=='[' || code=='{' || code=='}' || code=='/'){
       if(inlineLocation==position)
        return debugError(bytes,length,position,@"Invalid character in name, code=0x%02X",code);

       *objectp=[KGPDFObject_Name pdfObjectWithBytes:bytes+inlineLocation length:(position-inlineLocation)];
       *lastPosition=position;
       return YES;
      }
      break;

     case STATE_CLOSE_ANGLE:
      if(code=='>'){
       *objectp=[KGPDFObject_const pdfObjectDictionaryMarkEnd];
       *lastPosition=position+1;
       return YES;
      }
      return debugError(bytes,length,position,@"Expecting > after first >, code=0x02X",code);

     case STATE_IDENTIFIER:
      if(code==' ' || code==CR || code==FF || code==LF || code=='\t' || code=='\0' ||
         code=='%' || code=='(' || code==')' || code=='<' || code=='>' || code==']' ||
         code=='[' || code=='{' || code=='}' || code=='/'){
       const char     *name=bytes+inlineLocation;
       unsigned        length=position-inlineLocation;
       KGPDFIdentifier identifier=KGPDFClassifyIdentifier(name,length);
       
       if(identifier==KGPDFIdentifier_true)
        *objectp=[KGPDFObject_Boolean pdfObjectWithTrue];
       else if(identifier==KGPDFIdentifier_false)
        *objectp=[KGPDFObject_Boolean pdfObjectWithFalse];
       else if(identifier==KGPDFIdentifier_null)
        *objectp=[KGPDFObject_const pdfObjectWithNull];
       else
        *objectp=[KGPDFObject_identifier pdfObjectWithIdentifier:identifier name:name length:length];

       *lastPosition=position;
       return YES;
      }
      break;
	}
   }
   
   if(byteBuffer!=NULL)
    KGPDFByteBufferFree(byteBuffer);
   return NO;
}

BOOL KGPDFScanIdentifier(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFObject_identifier **identifier) {
   KGPDFObject *object;
   
   if(!KGPDFScanObject(bytes,length,position,lastPosition,&object))
    return NO;
   
   if([object objectType]!=KGPDFObjectType_identifier)
    return NO;
   
   *identifier=(KGPDFObject_identifier *)object;
   return YES;
}

BOOL KGPDFScanInteger(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFInteger *value) {
   KGPDFObject *object;
   
   if(!KGPDFScanObject(bytes,length,position,lastPosition,&object))
    return NO;

   return [object checkForType:kKGPDFObjectTypeInteger value:value];
}


BOOL KGPDFParseObject(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFObject **objectp,KGPDFxref *xref) {
   NSMutableArray *stack=nil;
   KGPDFObject    *check;
   
   debugTrace(bytes,length,position,@"KGPDFParseObject");
   while(YES) {

    if(!KGPDFScanObject(bytes,length,position,&position,&check))
     return NO;
    
    debugTrace(bytes,length,position,@"check=%@",check);
    
    switch([check objectType]){
   
     case kKGPDFObjectTypeNull:
     case kKGPDFObjectTypeBoolean:
     case kKGPDFObjectTypeInteger:
     case kKGPDFObjectTypeReal:
     case kKGPDFObjectTypeName:
     case kKGPDFObjectTypeString:
      if(stack!=nil)
       [stack addObject:check];
      else {
       *objectp=check;
       *lastPosition=position;
       return YES;
      }
      break;
           
     case KGPDFObjectTypeMark_array_open:
     case KGPDFObjectTypeMark_dictionary_open:
       if(stack==nil)
        stack=[NSMutableArray array];
       [stack addObject:check];
       break;

     case KGPDFObjectTypeMark_array_close:{
       KGPDFArray *array=[KGPDFArray pdfArray];
       int         count=[stack count];
       int         index=count;
       NSRange     remove;
       
       while(--index>=0){
        KGPDFObject *check=[stack objectAtIndex:index];
        
        if([check objectTypeNoParsing]==KGPDFObjectTypeMark_array_open)
         break;
       }
       if(index<0)
        return debugError(bytes,length,position,@"array ] with no [");
        
       remove=NSMakeRange(index,count-index);
       index++;
       for(;index<count;index++)
        [array addObject:[stack objectAtIndex:index]];
        
       [stack removeObjectsInRange:remove];
       [stack addObject:array];

       if([stack count]==1){
        *objectp=(KGPDFObject *)array;
        *lastPosition=position;
        return YES;
       }
      }
      break;
      
     case KGPDFObjectTypeMark_dictionary_close:{
       KGPDFDictionary *dictionary=[KGPDFDictionary pdfDictionary];
       
       while((check=[stack lastObject])!=nil){
        const char *key;
             
        if([check objectTypeNoParsing]==KGPDFObjectTypeMark_dictionary_open){
         if([stack count]==1){
          *objectp=dictionary;
          *lastPosition=position;
          return YES;
         }
         else {
          [stack removeLastObject];
          [stack addObject:dictionary];
          break;
         }
        }
        
        [[check retain] autorelease];
        [stack removeLastObject];
        if(![[stack lastObject] checkForType:kKGPDFObjectTypeName value:&key])
         return debugError(bytes,length,position,@"Expecting name on stack for dictionary");
         
        [dictionary setObjectForKey:key value:check];
        [stack removeLastObject];
       }
       if([stack count]==0)
        return debugError(bytes,length,position,@"dictionary >> with no <<");
      }
      break;
      
     case KGPDFObjectType_identifier:{
       KGPDFIdentifier identifier=[(KGPDFObject_identifier *)check identifier];

       if(identifier==KGPDFIdentifier_R){
        KGPDFInteger generation;
        KGPDFInteger number;
        KGPDFObject *object;
        
        if(![[stack lastObject] checkForType:kKGPDFObjectTypeInteger value:&generation])
         return NO;
        [stack removeLastObject];
        if(![[stack lastObject] checkForType:kKGPDFObjectTypeInteger value:&number])
         return NO;
        [stack removeLastObject];
        
        object=[KGPDFObject_R pdfObjectWithNumber:number generation:generation xref:xref];
        
        if(stack!=nil)
         [stack addObject:object];
        else {
         *objectp=object;
         *lastPosition=position;
         return YES;
        }
       }
       else {
        if([stack count]>0)
         return debugError(bytes,length,position,@"stack size=%d,unexpected identifier %@",[stack count],check);
        *objectp=check;
        *lastPosition=position;
        return YES;
       }
      }
      break;
      
     default:
      return NO;
    }
   }
   
   return NO;
}

BOOL KGPDFParseDictionary(const char *bytes,unsigned length,KGPDFInteger position,KGPDFInteger *lastPosition,KGPDFDictionary **dictionaryp,KGPDFxref *xref) {
   KGPDFObject *object;
   
   if(!KGPDFParseObject(bytes,length,position,lastPosition,&object,xref))
    return NO;
   
   return [object checkForType:kKGPDFObjectTypeDictionary value:dictionaryp];
}

BOOL KGPDFParse_xrefAtPosition(NSData *data,KGPDFInteger position,KGPDFxref **xrefp) {
   const char             *bytes=[data bytes];
   unsigned                length=[data length];
   KGPDFxref         *table;
   KGPDFDictionary        *trailer;
   KGPDFObject_identifier *identifier;

   if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
    return debugError(bytes,length,position,@"Expecting xref identifier",identifier);

   if([identifier identifier]!=KGPDFIdentifier_xref)
    return debugError(bytes,length,position,@"Expecting xref, got %@",identifier);

   *xrefp=table=[[[KGPDFxref alloc] initWithData:data] autorelease];
   do {
    KGPDFObject *object;
    KGPDFInteger number;
    KGPDFInteger count;
    
    if(!KGPDFScanObject(bytes,length,position,&position,&object))
     return debugError(bytes,length,position,@"Expecting object");
    
    if([object objectType]==KGPDFObjectType_identifier){
     if([(KGPDFObject_identifier *)object identifier]!=KGPDFIdentifier_trailer)
      return debugError(bytes,length,position,@"Expecting trailer identifier,got %@",object);
     else {
      if(!KGPDFParseDictionary(bytes,length,position,&position,&trailer,table))
       return NO;
       
      [table setTrailer:trailer];
      return YES;
     }
    }
    
    if(![object checkForType:kKGPDFObjectTypeInteger value:&number])
     return debugError(bytes,length,position,@"Expecting integer,got %@",object);
    
    if(!KGPDFScanInteger(bytes,length,position,&position,&count))
     return debugError(bytes,length,position,@"Expecting integer");
    
    for(;--count>=0;number++){
     KGPDFInteger fieldOne,fieldTwo;
     
     if(!KGPDFScanInteger(bytes,length,position,&position,&fieldOne))
      return debugError(bytes,length,position,@"Expecting integer");
     if(!KGPDFScanInteger(bytes,length,position,&position,&fieldTwo))
      return debugError(bytes,length,position,@"Expecting integer");
     if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
      return debugError(bytes,length,position,@"Expecting identifier");
      
     switch([identifier identifier]){
     
      case KGPDFIdentifier_f:
       break;

      case KGPDFIdentifier_n:
       [table addEntry:[KGPDFxrefEntry xrefEntryWithPosition:fieldOne number:number generation:fieldTwo]];
       break;

      default:
       return debugError(bytes,length,position,@"Expecting f or n");
     }
     
    }
   }while(YES);
}

BOOL KGPDFParse_xref(NSData *data,KGPDFxref **xrefp) {
   const char             *bytes=[data bytes];
   unsigned                length=[data length];
   KGPDFInteger            position,ignore;
   KGPDFObject_identifier *identifier;
   KGPDFxref         *lastTable=nil;
    
   if(!KGPDFScanBackwardsByLines(bytes,length,length,&position,3))
    return debugError(bytes,length,position,@"Unable to back up 3 lines to find startxref");

   if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
    return debugError(bytes,length,position,@"Expecting startxref identifier");

   if([identifier identifier]!=KGPDFIdentifier_startxref)
    return debugError(bytes,length,position,@"Expecting startxref, got %@",identifier);

   if(!KGPDFScanInteger(bytes,length,position,&ignore,&position))
    return debugError(bytes,length,position,@"Expecting integer");
   
   do {
    KGPDFxref  *table;
    
    if(!KGPDFParse_xrefAtPosition(data,position,&table))
     return NO;
     
    if(lastTable==nil)
     *xrefp=table;
    else
     [lastTable setPreviousTable:table];
     
    lastTable=table;

    if(![[table trailer] getIntegerForKey:"Prev" value:&position])
     break;
     
   }while(YES);
   
   return YES;
}

BOOL KGPDFParseIndirectObject(NSData *data,KGPDFInteger position,KGPDFObject **objectp,KGPDFInteger number,KGPDFInteger generation,KGPDFxref *xref){
   const char             *bytes=[data bytes];
   unsigned                length=[data length];
   KGPDFInteger            check;
   KGPDFObject_identifier *identifier;
   KGPDFObject            *object;
   
   debugTrace(bytes,length,position,@"KGPDFParseIndirectObject");

   if(!KGPDFScanInteger(bytes,length,position,&position,&check))
    return debugError(bytes,length,position,@"Expecting integer");
   if(check!=number)
    return debugError(bytes,length,position,@"Object number %d does not match indirect reference %d",check,number);
    
   if(!KGPDFScanInteger(bytes,length,position,&position,&check))
    return debugError(bytes,length,position,@"Expecting integer");
   if(check!=generation)
    return debugError(bytes,length,position,@"Generation number %d does not match indirect reference %d",check,number);

   if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
    return debugError(bytes,length,position,@"Expecting obj identifier");
   if([identifier identifier]!=KGPDFIdentifier_obj)
    return debugError(bytes,length,position,@"Expecting obj identifier, got %@",identifier);
   
   if(!KGPDFParseObject(bytes,length,position,&position,&object,xref))
    return debugError(bytes,length,position,@"Expecting object");
   
   if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
    return debugError(bytes,length,position,@"Expecting identifier");
    
   if([identifier identifier]==KGPDFIdentifier_stream){
    KGPDFDictionary *dictionary;
    KGPDFInteger     streamLength;
    
    if(![object checkForType:kKGPDFObjectTypeDictionary value:&dictionary])
     return debugError(bytes,length,position,@"Expecting dictionary for stream, got %@",object);
    
    if(![dictionary getIntegerForKey:"Length" value:&streamLength])
     return debugError(bytes,length,position,@"stream dictionary does not contain /Length");
    
    if(bytes[position]==CR)
     position++;
    if(bytes[position]==LF)
     position++;
    
    object=[[[KGPDFStream alloc] initWithDictionary:dictionary xref:xref position:position] autorelease];

    position+=streamLength;

    if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
     return debugError(bytes,length,position,@"Expecting identifier");
    if([identifier identifier]!=KGPDFIdentifier_endstream)
     return debugError(bytes,length,position,@"Expecting endstream identifier, got %@",identifier);

    if(!KGPDFScanIdentifier(bytes,length,position,&position,&identifier))
     return debugError(bytes,length,position,@"Expecting identifier");
   }
   
   if([identifier identifier]!=KGPDFIdentifier_endobj)
    return debugError(bytes,length,position,@"Expecting endobj identifier, got %@",identifier);
    
   *objectp=object;
   return YES;
}

@implementation KGPDFScanner

-initWithContentStream:(KGPDFContentStream *)stream operatorTable:(KGPDFOperatorTable *)operatorTable info:(void *)info {
   _stack=[NSMutableArray new];
   _stream=[stream retain];
   _operatorTable=[operatorTable retain];
   _info=info;
   return self;
}

-(void)dealloc {
   [_stack release];
   [_stream release];
   [_operatorTable release];
   [super dealloc];
}

-(KGPDFContentStream *)contentStream {
   return _stream;
}

-(BOOL)popObject:(KGPDFObject **)value {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;
   
   [_stack removeLastObject];
   
   *value=lastObject;
   return YES;
}

-(BOOL)popBoolean:(KGPDFBoolean *)value {
   BOOL result=[[_stack lastObject] checkForType:kKGPDFObjectTypeBoolean value:value];
   
   [_stack removeLastObject];
   
   return result;
}

-(BOOL)popInteger:(KGPDFInteger *)value {
   BOOL result=[[_stack lastObject] checkForType:kKGPDFObjectTypeInteger value:value];
   
   [_stack removeLastObject];
   
   return result;
}

-(BOOL)popNumber:(KGPDFReal *)value {
   BOOL result=[[_stack lastObject] checkForType:kKGPDFObjectTypeReal value:value];

   [_stack removeLastObject];
   
   return result;
}

-(BOOL)popName:(const char **)value {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;

   [_stack removeLastObject];

   return [lastObject checkForType:kKGPDFObjectTypeName value:value];
}

-(BOOL)popString:(KGPDFString **)stringp {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;

   [_stack removeLastObject];

   return [lastObject checkForType:kKGPDFObjectTypeString value:stringp];
}

-(BOOL)popArray:(KGPDFArray **)arrayp {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;

   [_stack removeLastObject];

   return [lastObject checkForType:kKGPDFObjectTypeArray value:arrayp];
}

-(BOOL)popDictionary:(KGPDFDictionary **)dictionaryp {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;

   [_stack removeLastObject];

   return [lastObject checkForType:kKGPDFObjectTypeDictionary value:dictionaryp];
}

-(BOOL)popStream:(KGPDFStream **)streamp {
   id lastObject=[[[_stack lastObject] retain] autorelease];
   
   if(lastObject==nil)
    return NO;

   [_stack removeLastObject];

   return [lastObject checkForType:kKGPDFObjectTypeStream value:streamp];
}

-(BOOL)scanStream:(KGPDFStream *)stream {
   KGPDFxref   *xref=[stream xref];
   NSData      *data=[stream data];
   const char  *bytes=[data bytes];
   unsigned     length=[data length];
   KGPDFInteger position=0;
   
   //NSLog(@"data[%d]=%@",[data length],[[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease]);
   
   while(position<length) {
    KGPDFObject *object;
    
    if(!KGPDFParseObject(bytes,length,position,&position,&object,xref))
     return NO;

    if([object objectTypeNoParsing]!=KGPDFObjectType_identifier)
     [_stack addObject:object];
     else {
      KGPDFOperatorCallback callback=[_operatorTable callbackForName:[(KGPDFObject_identifier *)object name]];
      
      //NSLog(@"op=[%s]",[object name]);

      if(callback!=NULL){
       callback(self,_info);
      }
      else {
       NSLog(@"unhandled identifier %@",object);
       [NSException raise:@"" format:@""];
      }
     }
   }
   
   return YES;
}

-(BOOL)scan {
   BOOL     result=YES;
   NSArray *streams=[_stream streams];
   int      i,count=[streams count];
   
   for(i=0;(i<count) && result;i++){
    KGPDFObject *object=[streams objectAtIndex:i];
    KGPDFStream *scan;
    
    if(![object checkForType:kKGPDFObjectTypeStream value:&scan])
     return NO;

    if(![self scanStream:scan])
     return NO;
   }

   return result;
}

@end
