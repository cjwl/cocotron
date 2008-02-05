/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSLocale.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSString_unicodePtr.h>
#import <Foundation/NSString_cString.h> //appendCString
#import <Foundation/NSAutoreleasePool-private.h>
#import "unibuffer.h"
#import <string.h>

#import <math.h>

typedef struct {
   NSZone *zone;
   unsigned max,length;
   unichar *characters;
} NSStringBuffer;

static inline void prepForUse(NSStringBuffer *buffer,NSZone *zone){
   buffer->zone=zone;
   buffer->max=1024;
   buffer->length=0;
   buffer->characters=NSZoneMalloc(buffer->zone,sizeof(unichar)*buffer->max);
}

static inline void makeRoomForNcharacters(NSStringBuffer *buffer,unsigned n){
   if(buffer->length+n>buffer->max){
    while(buffer->length+n>buffer->max)
     buffer->max*=2;

    buffer->characters=NSZoneRealloc(buffer->zone,buffer->characters,
       sizeof(unichar)*buffer->max);
   }
}

static inline void appendCharacter(NSStringBuffer *buffer,unichar unicode){
   makeRoomForNcharacters(buffer,1);

   buffer->characters[buffer->length++]=unicode;
}

static inline void appendCharacters(NSStringBuffer *buffer,unichar *characters,unsigned length,unichar fillChar,BOOL leftAdj,int fieldWidth){
   unsigned i;

   makeRoomForNcharacters(buffer,(fieldWidth>length)?fieldWidth:length);

   if(!leftAdj && fieldWidth>length){
    for(i=0;i<fieldWidth-length;i++)
     buffer->characters[buffer->length++]=fillChar;
   }

   for(i=0;i<length;i++)
    buffer->characters[buffer->length++]=characters[i];

   if(leftAdj && fieldWidth>length){
    for(i=0;i<fieldWidth-length;i++)
     buffer->characters[buffer->length++]=' ';
   }
}

static inline void appendUnichar(NSStringBuffer *buffer,unichar code,unichar fillChar,BOOL leftAdj,int fieldWidth){
   appendCharacters(buffer,&code,1,fillChar,leftAdj,fieldWidth);
}

static inline void reverseCharacters(unichar *characters,unsigned length){
   unsigned i;
   unichar  tmp;

    // reverse chars
   for(i=0;i<length/2;i++){
    tmp=characters[i];
    characters[i]=characters[(length-1)-i];
    characters[(length-1)-i]=tmp;
   }
}

static inline void appendReversed(NSStringBuffer *buffer,
 unichar *characters,unsigned length,
 unichar fillChar,BOOL leftAdj,int fieldWidth){
   reverseCharacters(characters,length);
   appendCharacters(buffer,characters,length,fillChar,leftAdj,fieldWidth);
}

static inline void appendDecimal(NSStringBuffer *buffer,long long value,
  unichar fillChar,BOOL leftAdj,BOOL plusSign,BOOL spaceSign,int fieldWidth){
    unsigned length=0;
    unichar  characters[100];
    unichar  sign=(value<0)?'-':plusSign?'+':spaceSign?' ':'\0';

    if(value<0)
     value=-value;

    while(value){
     characters[length++]=(value%10)+'0';
     value/=10;
    }

    if(length==0)
     characters[length++]='0';
    else if(sign)
     characters[length++]=sign;

    appendReversed(buffer,characters,length,fillChar,leftAdj,fieldWidth);
}

static inline void appendOctal(NSStringBuffer *buffer,unsigned long long value,
  unichar fillChar,BOOL leftAdj,int fieldWidth){
    unsigned length=0;
    unichar  characters[100];

    while(value){
     characters[length++]=(value&0x07)+'0';
     value>>=3;
    }

    if(length==0)
     characters[length++]='0';

    appendReversed(buffer,characters,length,fillChar,leftAdj,fieldWidth);
}

static inline void appendHex(NSStringBuffer *buffer,unsigned long long value,
  unichar fillChar,BOOL leftAdj,int fieldWidth,const char *hexes){
    unsigned length=0;
    unichar  characters[100];

    while(value){
     characters[length++]=hexes[value&0x0F];
     value>>=4;
    }

    if(length==0)
     characters[length++]='0';

    appendReversed(buffer,characters,length,fillChar,leftAdj,fieldWidth);
}

static inline void appendUnsigned(NSStringBuffer *buffer,unsigned long long value,
  unichar fillChar,BOOL leftAdj,int fieldWidth){
    unsigned length=0;
    unichar  characters[100];

    while(value){
     characters[length++]=(value%10)+'0';
     value/=10;
    }

    if(length==0)
     characters[length++]='0';

    appendReversed(buffer,characters,length,fillChar,leftAdj,fieldWidth);
}

static inline void appendCString(NSStringBuffer *buffer,const char *cString,
  unichar fillChar,BOOL leftAdj,int fieldWidth){
   unsigned length;
   unichar *characters;

   if(cString==NULL)
    cString="(null pointer)";

   characters=NSCharactersFromCString(cString,strlen(cString),&length,NULL);

   appendCharacters(buffer,characters,length,fillChar,leftAdj,fieldWidth);

   NSZoneFree(NULL,characters);
}

static inline void appendCStringChar(NSStringBuffer *buffer,char c,
  unichar fillChar,BOOL leftAdj,int fieldWidth){
   char cString[2]={c,'\0'};
   appendCString(buffer,cString,fillChar,leftAdj,fieldWidth);
}

static inline void appendFloat(NSStringBuffer *buffer,double value,
  unichar fillChar,BOOL leftAdj,BOOL plusSign,BOOL spaceSign,
  int fieldWidth,int precision,BOOL gFormat,BOOL altForm,NSDictionary *locale){
   if(1.0/0.0==value)
    appendCString(buffer,"1.#INF00",' ',leftAdj,fieldWidth);
   else if(log(0)==value)
    appendCString(buffer,"-1.#INF00",' ',leftAdj,fieldWidth);
   else if(value!=value)
    appendCString(buffer,"NaN",' ',leftAdj,fieldWidth);
   else{
    double   integral,fractional,power;
    unsigned i,j,length=0;
    unichar  characters[100];
    unichar  sign=(value<0)?'-':plusSign?'+':spaceSign?' ':'\0';

    if (value != 0.0)
    {
       value=fabs(value);
       if (!gFormat)
         power=pow(10.0,precision);
       else 
         power=pow(10.0,precision-1-floor(log10(value)));
       value=(1.0 + 1.0e-15)*round(value*power)/power;
    }

    fractional=modf(value,&integral);
    BOOL intZero=integral<1.0; 

    while(integral>=1.0){
     characters[length++]=(unichar)fmod(integral,10.0)+'0';
     integral/=10.0;
    }

    if(gFormat)
      precision -= length;

    if(length==0)
     characters[length++]='0';
    if(sign)
     characters[length++]=sign;

    reverseCharacters(characters,length);

    if(precision>0){
     NSString *seperatorString;
     unichar   decimalSeperator;
     
     if(locale)
      seperatorString = [locale objectForKey:NSLocaleDecimalSeparator];
     else
      seperatorString = [[NSLocale systemLocale] objectForKey:NSLocaleDecimalSeparator];
      
     decimalSeperator=([seperatorString length]>0)?[seperatorString characterAtIndex:0]:'.';
     
     unsigned start=length;
     BOOL     fractZero=YES;
     characters[length++]=decimalSeperator;
     for(i=0,j=0;i<precision;i++,j++,length++){
      fractional*=10.0;
      if((characters[length]=(unichar)fmod(fractional,10.0)+'0')!='0')
       fractZero=NO;
      else if (gFormat && intZero && fractZero && (j - i) < 5)
         i--;
     }

     if (gFormat)
     {
         if (intZero && fractZero)
            if(altForm)
               length=start + precision;
            else
               length=start;
       
         else if(!altForm)
         {
            while (characters[length-1] == '0')
               length--;
            if (characters[length-1] == decimalSeperator)
               length--;
         }
      }
    }

    appendCharacters(buffer,characters,length,fillChar,leftAdj,fieldWidth);
   }
}

static inline void appendObject(NSStringBuffer *buffer,id object,
  unichar fillChar,BOOL leftAdj,int fieldWidth){
   if(object==nil)
    appendCString(buffer,"*nil*",fillChar,leftAdj,fieldWidth);
   else {
    NSString *string=[object description];
    unibuffer ubuffer=NewUnibufferWithString(string);

    appendCharacters(buffer,ubuffer.characters,ubuffer.length,fillChar,leftAdj,fieldWidth);

    FreeUnibuffer(ubuffer);
   }
}

static inline unichar *prepForReturn(NSStringBuffer *buffer,unsigned *lengthp){

   *lengthp=buffer->max=buffer->length;
   buffer->characters=NSZoneRealloc(buffer->zone,buffer->characters,
       sizeof(unichar)*buffer->max);

   return buffer->characters;
}

unichar *NSCharactersNewWithFormat(NSString *format,NSDictionary *locale,
     va_list arguments,unsigned *lengthp,NSZone *zone){
   unsigned  pos,fmtLength=[format length];
   unichar   fmtBuffer[fmtLength],unicode;
   NSStringBuffer result;

   unichar fillChar=' ',dwModify=' ';
   BOOL    altForm=NO,leftAdj=NO,plusSign=NO,spaceSign=NO;
   int     fieldWidth=0,precision=6;

   enum {
    STATE_SCANNING,
    STATE_PERCENT,
    STATE_FIELDWIDTH,
    STATE_PRECISION,
    STATE_MODIFIER,
    STATE_CONVERSION
   } state=STATE_SCANNING;

   [format getCharacters:fmtBuffer];

   prepForUse(&result,zone);

   for(pos=0;pos<fmtLength;pos++){
    unicode=fmtBuffer[pos];

    switch(state){

     case STATE_SCANNING:
      if(unicode!='%')
       appendCharacter(&result,unicode);
      else{
       fillChar=dwModify=' ';
       altForm=leftAdj=plusSign=spaceSign=NO;
       fieldWidth=0;
       precision=6;
       state=STATE_PERCENT;
      }
      break;

     case STATE_PERCENT:
      switch(unicode){

       case '#': altForm=YES; break;
       case '0': fillChar='0'; break;
       case '-': leftAdj=YES; break;
       case '+': plusSign=YES; break;
       case ' ': spaceSign=YES; break;

       default:
        pos--;
        state=STATE_FIELDWIDTH;
        break;
      }
      break;

     case STATE_FIELDWIDTH:
      switch(unicode){

       case '0': case '1': case '2': case '3': case '4':
       case '5': case '6': case '7': case '8': case '9':
        fieldWidth=fieldWidth*10+(unicode-'0');
        break;

       case '*':
        fieldWidth=va_arg(arguments,int);
        if(fieldWidth<0){
         leftAdj=YES;
         fieldWidth=-fieldWidth;
        }
        break;

       case '.':
        precision=0;
        state=STATE_PRECISION;
        break;

       default:
        pos--;
        state=STATE_MODIFIER;
        break;
      }
      break;

     case STATE_PRECISION:
      switch(unicode){

       case '0': case '1': case '2': case '3': case '4':
       case '5': case '6': case '7': case '8': case '9':
        precision=precision*10+(unicode-'0');
        break;

       case '*': // fix
        precision=va_arg(arguments,int);
        break;

       default:
        pos--;
        state=STATE_MODIFIER;
        break;
      }
      break;

     case STATE_MODIFIER:
      switch(unicode){

       case 'h': case 'l': case 'q':
        dwModify=unicode;
        break;

       default:
        pos--;
        state=STATE_CONVERSION;
        break;
      }
      break;

     case STATE_CONVERSION:
      switch(unicode){

       case 'd': case 'i':{
         long long value;

         if(dwModify=='h')
          value=(short)va_arg(arguments,int);
         else if(dwModify=='l')
          value=va_arg(arguments,long);
         else if(dwModify=='q')
          value=va_arg(arguments,long long);
         else
          value=va_arg(arguments,int);

         appendDecimal(&result,value,fillChar,leftAdj,plusSign,
            spaceSign,fieldWidth);
        }
        break;

       case 'o': {
         unsigned long long value;

         if(dwModify=='h')
          value=(unsigned short)va_arg(arguments,int);
         else if(dwModify=='l')
          value=va_arg(arguments,unsigned long);
         else if(dwModify=='q')
          value=va_arg(arguments,unsigned long long);
         else
          value=va_arg(arguments,unsigned int);

         appendOctal(&result,value,fillChar,leftAdj,fieldWidth);
        }
        break;

       case 'x':{
         unsigned long long value;

         if(dwModify=='h')
          value=(unsigned short)va_arg(arguments,int);
         else if(dwModify=='l')
          value=va_arg(arguments,unsigned long);
         else if(dwModify=='q')
          value=va_arg(arguments,unsigned long long);
         else
          value=va_arg(arguments,unsigned int);

         appendHex(&result,value,fillChar,leftAdj,fieldWidth,
          "0123456789abcdef");
        }
        break;

       case 'X':{
         unsigned long long value;

         if(dwModify=='h')
          value=(unsigned short)va_arg(arguments,int);
         else if(dwModify=='l')
          value=va_arg(arguments,unsigned long);
         else if(dwModify=='q')
          value=va_arg(arguments,unsigned long long);
         else
          value=va_arg(arguments,unsigned int);

         appendHex(&result,value,fillChar,leftAdj,fieldWidth,
          "0123456789ABCDEF");
        }
        break;

       case 'u':{
         unsigned long long value;

         if(dwModify=='h')
          value=(unsigned short)va_arg(arguments,int);
         else if(dwModify=='l')
          value=va_arg(arguments,unsigned long);
         else if(dwModify=='q')
          value=va_arg(arguments,unsigned long long);
         else
          value=va_arg(arguments,unsigned int);

         appendUnsigned(&result,value,fillChar,leftAdj,fieldWidth);
        }
        break;

       case 'c':
        appendCStringChar(&result,va_arg(arguments,int),fillChar,leftAdj,fieldWidth);
        break;

       case 'C':
        appendUnichar(&result,va_arg(arguments,int),fillChar,leftAdj,fieldWidth);
        break;

       case 's':
        appendCString(&result,va_arg(arguments,char *),
               fillChar,leftAdj,fieldWidth);
        break;

       case 'f':{
         double value;

         if(dwModify=='l')
          value=va_arg(arguments,double);
         else
          value=va_arg(arguments,double);

         appendFloat(&result,value,fillChar,leftAdj,plusSign,spaceSign,fieldWidth,precision,NO,NO,locale);
        }
        break;

       case 'e': case 'E':{
         double value;

         if(dwModify=='l')
          value=va_arg(arguments,double);
         else
          value=va_arg(arguments,double);

         appendFloat(&result,value,fillChar,leftAdj,plusSign,spaceSign,fieldWidth,precision,NO,NO,locale);
        }
        break;

       case 'g': case 'G':{
         double value;

         if(dwModify=='l')
          value=va_arg(arguments,double);
         else
          value=va_arg(arguments,double);

         appendFloat(&result,value,fillChar,leftAdj,plusSign,spaceSign,fieldWidth,precision,YES,altForm,locale);
        }
        break;

       case 'p':
        appendHex(&result,(long)va_arg(arguments,void *),
          fillChar,leftAdj,fieldWidth,"0123456789ABCDEF");
        break;

       case 'n':
        *va_arg(arguments,int *)=result.length;
        break;

       case '@':
        appendObject(&result,va_arg(arguments,id),fillChar,leftAdj,fieldWidth);
        break;

       case '%':
        appendCharacter(&result,'%');
        break;
      }
      state=STATE_SCANNING;
      break;
    }

   }

   return prepForReturn(&result,lengthp);
}

NSString *NSStringNewWithFormat(NSString *format,NSDictionary *locale,
  va_list arguments,NSZone *zone) {
   unsigned  length;
   unichar  *unicode;

   unicode=NSCharactersNewWithFormat(format,locale,arguments,&length,NULL);

   return NSString_unicodePtrNewNoCopy(zone,unicode,length);
}

NSString *NSStringWithFormat(NSString *format,...) {
   va_list arguments;

   va_start(arguments,format);

   return NSAutorelease(NSStringNewWithFormat(format,nil,arguments,NULL));
}

NSString *NSStringWithFormatArguments(NSString *format,va_list arguments) {
   return NSAutorelease(NSStringNewWithFormat(format,nil,arguments,NULL));
}

NSString *NSStringWithFormatAndLocale(NSString *format,NSDictionary *locale,...) {
   va_list arguments;

   va_start(arguments,locale);

   return NSAutorelease(NSStringNewWithFormat(format,locale,arguments,NULL));
}

