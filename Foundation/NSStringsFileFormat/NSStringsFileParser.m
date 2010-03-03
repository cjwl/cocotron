/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSStringsFileParser.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString_cString.h>

static inline unsigned short SwapWord(unsigned short w){
   unsigned short hi=w>>8;
   unsigned short lo=w&0xFF;
   
   return (lo<<8)|hi;
}

static inline unsigned short PickWord(unsigned short w){
 return w;
}

static NSArray *error(NSArray *array,unichar *buffer,NSString *fmt,...) {
   va_list list;
   va_start(list,fmt);

   [array release];
   if(buffer!=NULL)
    NSZoneFree(NSZoneFromPointer(buffer),buffer);

   NSLogv(fmt,list);
   va_end(list);
   
   return nil;
}

static NSArray *stringListFromBytes(const unichar unicode[],NSInteger length){
   NSMutableArray *array=[[NSMutableArray allocWithZone:NULL] initWithCapacity:1024];
   NSInteger  index;
   NSUInteger bufferCount=0,bufferCapacity=2048;
   unichar   *buffer=NSZoneMalloc(NSDefaultMallocZone(),bufferCapacity*sizeof(unichar));
   
   enum {
    STATE_WHITESPACE,
    STATE_COMMENT_SLASH,
    STATE_COMMENT,
    STATE_COMMENT_STAR,
    STATE_STRING,
    STATE_STRING_KEY,
    STATE_STRING_SLASH,
    STATE_STRING_SLASH_X00,
    STATE_STRING_SLASH_XX0
   } state=STATE_WHITESPACE;
   enum {
    EXPECT_KEY,
    EXPECT_EQUAL_SEMI,
    EXPECT_VAL,
    EXPECT_SEMI
   } expect=EXPECT_KEY;

   unichar (*mapUC)(unichar);
   if (unicode[0]==0xFFFE){
    // reverse endianness
    mapUC=SwapWord;
    index=1;
   }
   else if (unicode[0]==0xFEFF){
    // native endianness
    mapUC=PickWord;
    index=1;
   }
   else{
    // no BOM, assume native endianness
    mapUC=PickWord;
    index=0;
   }
   if(mapUC(unicode[(length>>=1)-1])==0x0A)
    length--;
   for(;index<length;index++){
    unichar code=mapUC(unicode[index]);
         
    switch(state){

     case STATE_WHITESPACE:
      if(code=='/')
       state=STATE_COMMENT_SLASH;
      else if(code=='='){
       if(expect==EXPECT_EQUAL_SEMI)
        expect=EXPECT_VAL;
       else
        return error(array,buffer,@"unexpected character %02X '%C' at %d",code,code,index);
      }
      else if(code==';'){
       if(expect==EXPECT_SEMI)
        expect=EXPECT_KEY;
       else if(expect==EXPECT_EQUAL_SEMI){
        expect=EXPECT_KEY;
        [array addObject:[array lastObject]];
       }
       else
        return error(array,buffer,@"unexpected character %02X '%C' at %d",code,code,index);
      }
      else if(code=='\"'){
       if(expect!=EXPECT_KEY && expect!=EXPECT_VAL)
        return error(array,buffer,@"unexpected character %02X '%C' at %d",code,code,index);

       bufferCount=0;
       state=STATE_STRING;
      }
      else if(code>' '){
       if(expect!=EXPECT_KEY)
        return error(array,buffer,@"unexpected character %02X '%C' at %d",code,code,index);

       buffer[0]=code;
       bufferCount=1;
       state=STATE_STRING_KEY;
      }
      break;

     case STATE_COMMENT_SLASH:
      if(code=='*')
       state=STATE_COMMENT;
      else
       return error(array,buffer,@"unexpected character %02X '%C',after /",code,code);
      break;

     case STATE_COMMENT:
      if(code=='*')
       state=STATE_COMMENT_STAR;
      break;

     case STATE_COMMENT_STAR:
      if(code=='/')
       state=STATE_WHITESPACE;
      else if(code!='*')
       state=STATE_COMMENT;
      break;

     case STATE_STRING_KEY:
      switch(code){
       case '\"':
        return error(array,buffer,@"unexpected character %02X '%C' at %d",code,code,index);
       case '=':
         index-=2;
       case ' ':
         code='\"';
      }
     case STATE_STRING:
      if(code=='\"'){
       NSString *string=[[NSString allocWithZone:NULL] initWithCharacters:buffer length:bufferCount];

       [array addObject:string];
       [string release];
       state=STATE_WHITESPACE;
       if(expect==EXPECT_KEY)
        expect=EXPECT_EQUAL_SEMI;
       else
        expect=EXPECT_SEMI;
      }
      else{
       if(bufferCount>=bufferCapacity){
        bufferCapacity*=2;
        buffer=NSZoneRealloc(NSZoneFromPointer(buffer),buffer,bufferCapacity*sizeof(unichar));
       }
       if(code=='\\')
        state=STATE_STRING_SLASH;
       else 
        buffer[bufferCount++]=code;
      }
      break;

     case STATE_STRING_SLASH:
      switch(code){
       case 'a': buffer[bufferCount++]='\a'; state=STATE_STRING; break;
       case 'b': buffer[bufferCount++]='\b'; state=STATE_STRING; break;
       case 'f': buffer[bufferCount++]='\f'; state=STATE_STRING; break;
       case 'n': buffer[bufferCount++]='\n'; state=STATE_STRING; break;
       case 'r': buffer[bufferCount++]='\r'; state=STATE_STRING; break;
       case 't': buffer[bufferCount++]='\t'; state=STATE_STRING; break;
       case 'v': buffer[bufferCount++]='\v'; state=STATE_STRING; break;
       case '0': case '1': case '2': case '3':
       case '4': case '5': case '6': case '7':
        buffer[bufferCount++]=code-'0';
        state=STATE_STRING_SLASH_X00;
        break;

       default:
        buffer[bufferCount++]=code;
        state=STATE_STRING; 
        break;
      }
      break;

     case STATE_STRING_SLASH_X00:
      if(code<'0' || code>'7'){
       state=STATE_STRING;
       index--;
      }
      else{
       state=STATE_STRING_SLASH_XX0;
       buffer[bufferCount-1]*=8;
       buffer[bufferCount-1]+=code-'0';
      }
      break;

     case STATE_STRING_SLASH_XX0:
      state=STATE_STRING;
      if(code<'0' || code>'7')
       index--;
      else{
       buffer[bufferCount-1]*=8;
       buffer[bufferCount-1]+=code-'0';
      }
      break;

    }
   }

   NSZoneFree(NSZoneFromPointer(buffer),buffer);

   if(state!=STATE_WHITESPACE)
    return error(array,NULL,@"unexpected EOF\n");

   switch(expect){
    case EXPECT_EQUAL_SEMI:
     return error(array,NULL,@"unexpected EOF, expecting = or ;");

    case EXPECT_VAL:
     return error(array,NULL,@"unexpected EOF, expecting value");

    case EXPECT_SEMI:
     return error(array,NULL,@"unexpected EOF, expecting ;");

    default:
     break;
   }

   return array;
}

NSDictionary *NSDictionaryFromStringsFormatData(NSData *data) {
   NSArray      *array=stringListFromBytes((unichar *)[data bytes],[data length]);
   NSDictionary *dictionary;
   id           *keys,*values;
   NSInteger           i,count;

   if(array==nil)
    return nil;

   count=[array count]/2;

   keys=__builtin_alloca(sizeof(id)*count);
   values=__builtin_alloca(sizeof(id)*count);

   for(i=0;i<count;i++){
    keys[i]=[array objectAtIndex:i*2];
    values[i]=[array objectAtIndex:i*2+1];
   }

   dictionary=[[[NSDictionary allocWithZone:NULL] initWithObjects:values
      forKeys:keys count:count] autorelease];

   [array release];

   return dictionary;
}

NSDictionary *NSDictionaryFromStringsFormatString(NSString *string) {
   NSData *data=[string dataUsingEncoding:NSUnicodeStringEncoding];
   return NSDictionaryFromStringsFormatData(data);
}

NSDictionary *NSDictionaryFromStringsFormatFile(NSString *path) {
   NSData       *data;
   NSDictionary *dictionary;

   if((data=[[NSData allocWithZone:NULL] initWithContentsOfMappedFile:path])==nil)
    return nil;

   dictionary=NSDictionaryFromStringsFormatData(data);

   [data release];

   return dictionary;
}
