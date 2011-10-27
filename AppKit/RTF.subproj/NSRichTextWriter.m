/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSRichTextWriter.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSAttributedString.h>
#ifdef WIN32
#import <malloc.h>
#endif 

@implementation NSRichTextWriter

-initWithAttributedString:(NSAttributedString *)attributedString range:(NSRange)range {
   _attributedString=[attributedString retain];
   _string=[[_attributedString string] retain];
   _range=range;
   _data=[NSMutableData new];
   return self;
}

-(void)dealloc {
   [_attributedString release];
   [_string release];
   [_data release];
   [super dealloc];
}

+(NSData *)dataWithAttributedString:(NSAttributedString *)attributedString range:(NSRange)range {
   NSRichTextWriter *writer=[[self alloc] initWithAttributedString:attributedString range:range];
   NSData           *result=[[[writer generateData] retain] autorelease];

   [writer release];

   return result;
}

-(void)appendCString:(const char *)cString {
   [_data appendBytes:cString length:strlen(cString)];
}

-(void)appendStringFromRange:(NSRange)range {
   unichar        buffer[range.length];
   unsigned char *ansi;
   int            i,ansiLength=0;

   [_string getCharacters:buffer range:range];
   for(i=0;i<range.length;i++){
    if(buffer[i]=='\n' || buffer[i]=='\\')
     ansiLength+=2;
    else if(buffer[i]>127)
     ansiLength+=6;
   }

   ansi=alloca(sizeof(unsigned char)*ansiLength);
   ansiLength=0;
   for(i=0;i<range.length;i++){
    unichar code=buffer[i];

    if(code=='\n'){
     ansi[ansiLength++]='\\';
     ansi[ansiLength++]='\n';
    }
	   else if(code=='\\'){
		   ansi[ansiLength++]='\\';
		   ansi[ansiLength++]='\\';
	   }
	   else if(code>127){
     char *hex="0123456789ABCDEF";

     ansi[ansiLength++]='\\';
     ansi[ansiLength++]='U';
     ansi[ansiLength++]=hex[(code>>12)&0x0F];
     ansi[ansiLength++]=hex[(code>>8)&0x0F];
     ansi[ansiLength++]=hex[(code>>4)&0x0F];
     ansi[ansiLength++]=hex[code&0x0F];
    }
    else {
     ansi[ansiLength++]=code;
    }
   }

   [_data appendBytes:ansi length:ansiLength];
}

-(void)writeRichText {
   unsigned  location=_range.location;
   unsigned  limit=NSMaxRange(_range);

   [self appendCString:"{\\rtf0\\ansi "];

   while(location<limit){
    NSRange         effectiveRange;
    NSDictionary   *attributes=[_attributedString attributesAtIndex:location effectiveRange:&effectiveRange];
    NSFont         *font=NSFontAttributeInDictionary(attributes);
    NSFontTraitMask traits=[[NSFontManager sharedFontManager] traitsOfFont:font];

    if(effectiveRange.location<location){
     effectiveRange.length=NSMaxRange(effectiveRange)-location;
     effectiveRange.location=location;
    }
    if(NSMaxRange(effectiveRange)>limit)
     effectiveRange.length=limit-effectiveRange.location;

    if(traits&NSBoldFontMask)
     [self appendCString:"\\b "];

    [self appendStringFromRange:effectiveRange];

    if(traits&NSBoldFontMask)
     [self appendCString:"\\b0 "];

    location=NSMaxRange(effectiveRange);
   }
   [self appendCString:"}"];
}

-(NSData *)generateData {
   [self writeRichText];
   return _data;
}

@end
