/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSStringSymbol.h>
#import <Foundation/NSRaise.h>

static unsigned convertUTF16toUTF8(const unichar *utf16,unsigned utf16Length,unsigned char *utf8){
   unsigned utf8Length=0;
   unsigned i;
   
   for(i=0;i<utf16Length;i++){
    unsigned      code32=utf16[i];
    unsigned char tmp[4];
	int           tmpLength=0;
	
	if(code32<0x80)
	 tmp[tmpLength++]=code32;
	else if(code32<0x800){
	 tmp[tmpLength++]=0x80|(code32&0x3F);
	 tmp[tmpLength++]=0xC0|(code32>>6);
	}
	else if(code32<0x10000) {
	 tmp[tmpLength++]=0x80|(code32&0x3F);
	 tmp[tmpLength++]=0x80|(code32>>6);
	 tmp[tmpLength++]=0xE0|(code32>>12);
	}
	else {
	 tmp[tmpLength++]=0x80|(code32&0x3F);
	 tmp[tmpLength++]=0x80|(code32>>6);
	 tmp[tmpLength++]=0x80|(code32>>12);
	 tmp[tmpLength++]=0xF0|(code32>>18);
	}
	
	if(utf8==NULL)
	 utf8Length+=tmpLength;
	else{
	 while(--tmpLength>=0)	 
	  utf8[utf8Length++]=tmp[tmpLength];
	}
   }
   
   return utf8Length;
}

char    *NSUnicodeToUTF8(const unichar *characters,unsigned length,
  BOOL lossy,unsigned *resultLength,NSZone *zone,BOOL zeroTerminate){
  unsigned  utf8Length=convertUTF16toUTF8(characters,length,NULL);
  char     *utf8=NSZoneMalloc(NULL,(utf8Length+(zeroTerminate?1:0))*sizeof(unsigned char));

  *resultLength=convertUTF16toUTF8(characters,length,(unsigned char *)utf8);
  if(zeroTerminate)
   utf8[*resultLength]='\0';
   
  return utf8;
}

static unsigned convertUTF8toUTF16(const unsigned char *utf8,unsigned utf8Length,unichar *utf16){
   unsigned i,utf16Length=0;
   unsigned code32=0;
   enum {
    stateThreeLeft,
	stateTwoLeft,
	stateOneLeft,
    stateFirstByte,
   } state=stateFirstByte;
   
   for(i=0;i<utf8Length;i++){
    unsigned char code8=utf8[i];
	
	switch(state){

	 case stateThreeLeft:
	 case stateTwoLeft:
	 case stateOneLeft:
	  code32<<=6;
	  code32|=code8&0x7F;
	  state++;
	  break;
	
	 case stateFirstByte:
	  if(code8<0x80)
	   code32=code8;
      else if((code8&0xF0)==0xF0){
	   code32=code8&0x0F;
	   state=stateThreeLeft;
	  }
	  else if((code8&0xE0)==0xE0){
	   code32=code8&0x1F;
	   state=stateTwoLeft;
	  }
	  else if((code8&0xC0)==0xC0){
	   code32=code8&0x3F;
	   state=stateOneLeft;
	  }
      break;
	  	  
	}
	if(state==stateFirstByte){
	 if(utf16!=NULL)
	  utf16[utf16Length]=code32;
	 utf16Length++;
	}
   }
   
   return utf16Length;
}

unichar *NSUTF8ToUnicode(const char *utf8,unsigned length,
  unsigned *resultLength,NSZone *zone) {
   unsigned utf16Length=convertUTF8toUTF16((unsigned char *)utf8,length,NULL);
   unichar *utf16=NSZoneMalloc(NULL,utf16Length*sizeof(unichar));

   *resultLength=convertUTF8toUTF16((unsigned char *)utf8,length,utf16);

   return utf16;
}

BOOL NSUTF8IsASCII(const char *utf8,unsigned length) {
  int i;

  for(i=0;i<length;i++)
   if(utf8[i]&0x80)
    return NO;

  return YES;
}

