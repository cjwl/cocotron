/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSRichTextReader.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSTextAttachment.h>

enum {
   STATE_SKIPLAST,
   STATE_SCANNING,
   STATE_CONTROL,
   STATE_CONTROL_ALPHA,
   STATE_CONTROL_DIGIT,
   STATE_UNICODE,
   STATE_UNICODE_X,
   STATE_UNICODE_XX,
   STATE_UNICODE_XXX,
   STATE_UNICODE_XXXX,
};

@implementation NSRichTextReader

-initWithData:(NSData *)data {
   _data=[data copy];
   _bytes=[_data bytes];
   _length=[_data length];
   _range=NSMakeRange(0,0);
   _state=STATE_SCANNING;
   _fontTable=[NSMutableDictionary new];
   _currentFontInfo=nil;
   _currentAttributes=[NSMutableDictionary new];
   [_currentAttributes setObject:[NSFont systemFontOfSize:0]
                          forKey:NSFontAttributeName];
   _attributedString=[NSMutableAttributedString new];
   return self;
}

-initWithContentsOfFile:(NSString *)path {
   NSString *type=[path pathExtension];

   if([type isEqualToString:@"rtf"]){
    NSData *data=[NSData dataWithContentsOfFile:path];

    if(data!=nil)
     return [self initWithData:data];
   }
   else if([type isEqualToString:@"rtfd"]){
    NSString *txt=[[path stringByAppendingPathComponent:@"TXT"] stringByAppendingPathExtension:@"rtf"];
    NSData   *data=[NSData dataWithContentsOfFile:txt];

    if(data!=nil)
     return [self initWithData:data];

    _imageDirectory=[path copy];
   }

   [self dealloc];
   return nil;
}

-(void)dealloc {
   [_imageDirectory release];
   [_data release];
   [_currentAttributes release];
   [_attributedString release];
   [super dealloc];
}

+(NSAttributedString *)attributedStringWithData:(NSData *)data {
   NSRichTextReader   *reader=[[self alloc] initWithData:data];
   NSAttributedString *result=[[[reader parseAttributedString] retain] autorelease];

   [reader release];

   return result;
}

+(NSAttributedString *)attributedStringWithContentsOfFile:(NSString *)path {
   NSRichTextReader   *reader=[[self alloc] initWithContentsOfFile:path];
   NSAttributedString *result=[[[reader parseAttributedString] retain] autorelease];

   [reader release];

   return result;
}

-(NSUInteger)length {
   return _range.length;
}

-(unichar)characterAtIndex:(NSUInteger)index {
   return _bytes[_range.location+index];
}

-(void)getCharacters:(unichar *)buffer {
   unsigned i;

   for(i=0;i<_range.length;i++)
    buffer[i]=_bytes[_range.location+i];
}

-(void)getCharacters:(unichar *)buffer range:(NSRange)range {
   unsigned location=range.location,max=NSMaxRange(range);
   unsigned i;

   for(i=0;location<max;i++,location++)
    buffer[i]=_bytes[_range.location+location];
}

-(void)appendStringWithCurrentAttributes:(NSString *)string {
   unsigned length=[_attributedString length];
   NSRange  append=NSMakeRange(length,0);
   NSRange  range=NSMakeRange(length,[string length]);

   [_attributedString replaceCharactersInRange:append withString:string];
   [_attributedString setAttributes:_currentAttributes range:range];
}

static inline void flushPreviousString(NSRichTextReader *self) {
   self->_range.length--;
   if(self->_range.length>0){
    [self appendStringWithCurrentAttributes:self];
   }

   self->_range.location=NSMaxRange(self->_range);
   self->_range.length=1;
}

-(void)flushFontName {
   _range.length--;
   if(_range.length>0){
    [_currentFontInfo setObject:[NSString stringWithString:self] forKey:@"fontname"];
   }

   _range.location=NSMaxRange(_range);
   _range.length=1;
}

-(BOOL)activeFontInfo {
   return (_currentFontInfo!=nil)?YES:NO;
}

-(void)flushFontInfo {
   NSString *key=[_currentFontInfo objectForKey:@"fontnum"];

   if(key!=nil)
    [_fontTable setObject:_currentFontInfo forKey:key];
   [_currentFontInfo release];
   _currentFontInfo=nil;
}

-(void)createFontInfo {
   _currentFontInfo=[NSMutableDictionary new];
}

-(BOOL)activeColorTable {
   return _activeColorTable;
}

-(void)processControlWithArgValue:(int)argument {
   NSRange save=_range;

   _range=_letterRange;
//NSLog(@"%s %@ %d",sel_getName(_cmd),self,argument);

   if([self isEqualToString:@"b"]){
    NSFont *font=[_currentAttributes objectForKey:NSFontAttributeName];

    font=[[NSFontManager sharedFontManager] convertFont:font toHaveTrait:argument?NSBoldFontMask:NSUnboldFontMask];
    [_currentAttributes setObject:font forKey:NSFontAttributeName];
   }
   else if([self isEqualToString:@"i"]){
    NSFont *font=[_currentAttributes objectForKey:NSFontAttributeName];

    font=[[NSFontManager sharedFontManager] convertFont:font toHaveTrait:argument?NSItalicFontMask:NSUnitalicFontMask];
    [_currentAttributes setObject:font forKey:NSFontAttributeName];
   }
   else if([self isEqualToString:@"par"]){
       [self appendStringWithCurrentAttributes:@"\n"];
   }
   else if([self isEqualToString:@"tab"]){
       [self appendStringWithCurrentAttributes:@"\t"];
   }
   else if([self isEqualToString:@"fs"]){
    NSFont *font=[_currentAttributes objectForKey:NSFontAttributeName];

    font=[[NSFontManager sharedFontManager] convertFont:font toSize:argument/2];
    [_currentAttributes setObject:font forKey:NSFontAttributeName];
   }
   else if([self isEqualToString:@"fonttbl"]){
    _currentFontInfo=[NSMutableDictionary new];
   }
   else if([self isEqualToString:@"f"]){
    NSString *key=[NSString stringWithFormat:@"%d",argument];

    if([self activeFontInfo]){
     [_currentFontInfo setObject:key forKey:@"fontnum"];
    }
    else {
     NSDictionary *info=[_fontTable objectForKey:key];
     NSString     *family=[info objectForKey:@"fontfamily"];
     NSFont       *font=[_currentAttributes objectForKey:NSFontAttributeName];

     if([family isEqualToString:@"roman"])
      font=[NSFont fontWithName:@"Times New Roman" size:12];
     else if([family isEqualToString:@"modern"])
      font=[NSFont fontWithName:@"Courier New" size:12];
     else if([family isEqualToString:@"swiss"])
      font=[NSFont fontWithName:@"Arial" size:12];
     else if([family isEqualToString:@"nil"]){
      font=[NSFont fontWithName:[info objectForKey:@"fontname"] size:12];
     }
     [_currentAttributes setObject:font forKey:NSFontAttributeName];

    }
   }
   else if([self isEqualToString:@"fnil"])
    [_currentFontInfo setObject:@"nil" forKey:@"fontfamily"];
   else if([self isEqualToString:@"froman"])
    [_currentFontInfo setObject:@"roman" forKey:@"fontfamily"];
   else if([self isEqualToString:@"fswiss"])
    [_currentFontInfo setObject:@"swiss" forKey:@"fontfamily"];
   else if([self isEqualToString:@"fmodern"])
    [_currentFontInfo setObject:@"modern" forKey:@"fontfamily"];
   else if([self isEqualToString:@"fscript"])
    [_currentFontInfo setObject:@"script" forKey:@"fontfamily"];
   else if([self isEqualToString:@"fdecor"])
    [_currentFontInfo setObject:@"decor" forKey:@"fontfamily"];
   else if([self isEqualToString:@"ftech"])
    [_currentFontInfo setObject:@"tech" forKey:@"fontfamily"];
   else if([self isEqualToString:@"fbidi"])
    [_currentFontInfo setObject:@"bidi" forKey:@"fontfamily"];
   else if([self isEqualToString:@"colortbl"]){
    _activeColorTable=YES;
   }
   else if([self isEqualToString:@"NeXTGraphic"]){

    _range.location=NSMaxRange(save);
    _range.length=0;

    for(;NSMaxRange(_range)<_length;){
     if(_bytes[NSMaxRange(_range)]=='\\')
      break;
     _range.length++;
    }
    _range.length--;
    {
     NSString         *path=[_imageDirectory stringByAppendingPathComponent:self];
     NSTextAttachment *attachment=[[[NSTextAttachment alloc] initWithContentsOfFile:path] autorelease];
     unichar           attachChar=NSAttachmentCharacter;

//NSLog(@"path=[%@],attachment=%@",path,attachment);

     if(attachment!=nil){
      [_currentAttributes setObject:attachment forKey:NSAttachmentAttributeName];

      [self appendStringWithCurrentAttributes:[NSString stringWithCharacters:&attachChar length:1]];

      [_currentAttributes removeObjectForKey:NSAttachmentAttributeName];
     }
    }
    _range.length++;
    save=_range;
   }
   _range=save;
}


-(void)tokenize {
   for(;NSMaxRange(_range)<_length;){
    unsigned position=NSMaxRange(_range);
    unsigned char code=_bytes[position];

    _range.length++;

    switch(_state){

     case STATE_SKIPLAST:
      _range.location=position;
      _range.length=1;
      _state=STATE_SCANNING;
      // fall thru
     case STATE_SCANNING:
      if(code=='\\'){
       flushPreviousString(self);
       _state=STATE_CONTROL;
       _range.location=NSMaxRange(_range);
       _range.length=0;
      }
      else if(code=='{'){
       flushPreviousString(self);
       _state=STATE_SKIPLAST;
      }
      else if(code=='}'){
       if([self activeFontInfo])
        [self flushFontInfo];
       else if([self activeColorTable])
        _activeColorTable=NO;
       else
        flushPreviousString(self);
       _state=STATE_SKIPLAST;
      }
      else if(code=='\r' || code=='\n'){
       flushPreviousString(self);
       _state=STATE_SKIPLAST;
      }
      else if(code==';'){
       if([self activeFontInfo]){
        [self flushFontName];
        [self flushFontInfo];
        [self createFontInfo];
        _state=STATE_SKIPLAST;
       }
       if([self activeColorTable]){
        _state=STATE_SKIPLAST;
       }
      }
      break;

     case STATE_CONTROL:
      if(code=='\''){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='*'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='-'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='\\'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='_'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='{'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='|'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='}'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='~'){
       _state=STATE_SKIPLAST;
       break;
      }
      else if(code=='\r' || code=='\n'){
       _state=STATE_SKIPLAST;
       [self appendStringWithCurrentAttributes:@"\n"];
       break;
      }
      else if(code=='U'){
       _state=STATE_UNICODE;
       _univalue=0;
       break;
      }

      // fallthru
     case STATE_CONTROL_ALPHA:
      if((code>='a' && code<='z') || (code>='A' && code<='Z'))
       _state=STATE_CONTROL_ALPHA;
      else if(code=='-'){
       _argSign=-1;
       _argValue=0;
       _letterRange=_range;
       _letterRange.length--;
       _state=STATE_CONTROL_DIGIT;
      }
      else if(code>='0' && code<='9'){
       _argSign=1;
       _argValue=code-'0';
       _letterRange=_range;
       _letterRange.length--;
       _state=STATE_CONTROL_DIGIT;
      }
      else if(code==' '){
       _letterRange=_range;
       _letterRange.length--;
       _state=STATE_SKIPLAST;
       [self processControlWithArgValue:1];
      }
      else {
       _range.length--;
       _letterRange=_range;
       _state=STATE_SCANNING;
       [self processControlWithArgValue:1];
       _range.location=position;
       _range.length=0;
      }
      break;

     case STATE_CONTROL_DIGIT:
      if(code>='0' && code<='9'){
       _argValue*=10;
       _argValue+=code-'0';
       _state=STATE_CONTROL_DIGIT;
      }
      else if(code==' '){
       _state=STATE_SKIPLAST;
       [self processControlWithArgValue:_argSign*_argValue];
      }
      else {
       _range.length--;
       _state=STATE_SCANNING;
       [self processControlWithArgValue:_argSign*_argValue];
       _range.location=position;
       _range.length=0;
      }
      break;

     case STATE_UNICODE:
     case STATE_UNICODE_X:
     case STATE_UNICODE_XX:
     case STATE_UNICODE_XXX:
      if(code>='0' && code<='9'){
       _univalue*=16;
       _univalue+=code-'0';
       _state++;
      }
      else if(code>='A' && code<='F'){
       _univalue*=16;
       _univalue+=code-'A'+10;
       _state++;
      }
      else {
       NSLog(@"error parsing unicode control in RTF");
       _state=STATE_SCANNING;
      }
      if(_state==STATE_UNICODE_XXXX){
       [self appendStringWithCurrentAttributes:[NSString stringWithCharacters:&_univalue length:1]];
       _state=STATE_SKIPLAST;
      }
      break;
    }
   }
}

-(NSAttributedString *)parseAttributedString {
   [self tokenize];
   return _attributedString;
}

@end
