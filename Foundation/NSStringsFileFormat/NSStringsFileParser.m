/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSStringsFileParser.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString_cString.h>
#import <malloc.h>

static NSArray *error(NSArray *array,char *strBuf,NSString *fmt,...) {
   va_list list;
   va_start(list,fmt);

   [array release];
   if(strBuf!=NULL)
    NSZoneFree(NSZoneFromPointer(strBuf),strBuf);

   NSLogv(fmt,list);

   return nil;
}

static NSArray *stringListFromBytes(const char *bytes,int length){
   NSMutableArray *array=[[NSMutableArray allocWithZone:NULL] initWithCapacity:1024];
   int index,c,strSize=0,strMax=2048;
   char *strBuf=NSZoneMalloc(NSDefaultMallocZone(),strMax);

   enum {
    STATE_WHITESPACE,
    STATE_COMMENT_SLASH,
    STATE_COMMENT,
    STATE_COMMENT_STAR,
    STATE_STRING,
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

   for(index=0;index<length;){
    c=bytes[index++];
    switch(state){

     case STATE_WHITESPACE:
      if(c=='/')
       state=STATE_COMMENT_SLASH;
      else if(c=='='){
       if(expect==EXPECT_EQUAL_SEMI)
        expect=EXPECT_VAL;
       else
        return error(array,strBuf,@"unexpected character %02X '%c'",c,c);
      }
      else if(c==';'){
       if(expect==EXPECT_SEMI)
        expect=EXPECT_KEY;
       else if(expect==EXPECT_EQUAL_SEMI){
        expect=EXPECT_KEY;
        [array addObject:[array lastObject]];
       }
       else
        return error(array,strBuf,@"unexpected character %02X '%c'",c,c);
      }
      else if(c=='\"'){
       if(expect!=EXPECT_KEY && expect!=EXPECT_VAL)
        return error(array,strBuf,@"unexpected character %02X '%c'",c,c);

       strSize=0;
       state=STATE_STRING;
      }
      else if(c>' ')
       return error(array,strBuf,@"unexpected character %02X '%c'",c,c);
      break;

     case STATE_COMMENT_SLASH:
      if(c=='*')
       state=STATE_COMMENT;
      else
       return error(array,strBuf,@"unexpected character %02X '%c',after /",c,c);
      break;

     case STATE_COMMENT:
      if(c=='*')
       state=STATE_COMMENT_STAR;
      break;

     case STATE_COMMENT_STAR:
      if(c=='/')
       state=STATE_WHITESPACE;
      else if(c!='*')
       state=STATE_COMMENT;
      break;

     case STATE_STRING:
      if(c=='\"'){
       NSString *string=[[NSString allocWithZone:NULL] initWithCString:strBuf
                                     length:strSize];
       [array addObject:string];
       [string release];
       state=STATE_WHITESPACE;
       if(expect==EXPECT_KEY)
        expect=EXPECT_EQUAL_SEMI;
       else
        expect=EXPECT_SEMI;
      }
      else{
       if(strSize>=strMax){
        strMax*=2;
        strBuf=NSZoneRealloc(NSZoneFromPointer(strBuf),strBuf,strMax);
       }
       if(c=='\\')
        state=STATE_STRING_SLASH;
       else
        strBuf[strSize++]=c;
      }
      break;

     case STATE_STRING_SLASH:
      switch(c){
       case 'a': strBuf[strSize++]='\a'; state=STATE_STRING; break;
       case 'b': strBuf[strSize++]='\b'; state=STATE_STRING; break;
       case 'f': strBuf[strSize++]='\f'; state=STATE_STRING; break;
       case 'n': strBuf[strSize++]='\n'; state=STATE_STRING; break;
       case 'r': strBuf[strSize++]='\r'; state=STATE_STRING; break;
       case 't': strBuf[strSize++]='\t'; state=STATE_STRING; break;
       case 'v': strBuf[strSize++]='\v'; state=STATE_STRING; break;
       case '0': case '1': case '2': case '3':
       case '4': case '5': case '6': case '7':
        strBuf[strSize++]=c-'0';
        state=STATE_STRING_SLASH_X00;
        break;

       default:
        strBuf[strSize++]=c;
        state=STATE_STRING; 
        break;
      }
      break;

     case STATE_STRING_SLASH_X00:
      if(c<'0' || c>'7'){
       state=STATE_STRING;
       index--;
      }
      else{
       state=STATE_STRING_SLASH_XX0;
       strBuf[strSize-1]*=8;
       strBuf[strSize-1]+=c-'0';
      }
      break;

     case STATE_STRING_SLASH_XX0:
      state=STATE_STRING;
      if(c<'0' || c>'7')
       index--;
      else{
       strBuf[strSize-1]*=8;
       strBuf[strSize-1]+=c-'0';
      }
      break;

    }
   }

   NSZoneFree(NSZoneFromPointer(strBuf),strBuf);

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
   NSArray      *array=stringListFromBytes([data bytes],[data length]);
   NSDictionary *dictionary;
   id           *keys,*values;
   int           i,count;

   if(array==nil)
    return nil;

   count=[array count]/2;

   keys=alloca(sizeof(id)*count);
   values=alloca(sizeof(id)*count);

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
   NSData *data=[string dataUsingEncoding:NSNEXTSTEPStringEncoding];
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
