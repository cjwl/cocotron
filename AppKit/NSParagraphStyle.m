/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSTextTab.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSParagraphStyle

+(NSParagraphStyle *)defaultParagraphStyle {
   static NSParagraphStyle *shared=nil;

   if(shared==nil)
    shared=[self new];

   return shared;
}

+(NSArray *)_defaultTabStops {
   static NSArray *shared=nil;

   if(shared==nil){
    int        i,count=12;
    NSTextTab *tabs[count];

    for(i=0;i<count;i++){
     tabs[i]=[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:(i+1)*28.0] autorelease];
    }
    shared=[[NSArray alloc] initWithObjects:tabs count:count];
   }

   return shared;
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;

    _textAlignment=NSLeftTextAlignment;
    _lineBreakMode=NSLineBreakByWordWrapping;

    _tabStops=[[isa _defaultTabStops] retain];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }
   
   return self;
}

-init {

   _textAlignment=NSLeftTextAlignment;
   _lineBreakMode=NSLineBreakByWordWrapping;

   _tabStops=[[isa _defaultTabStops] retain];

   return self;
}

-initWithParagraphStyle:(NSParagraphStyle *)other {
   _textAlignment=[other alignment];
   _lineBreakMode=[other lineBreakMode];
   _tabStops=[[other tabStops] copy];
   return self;
}

-(void)dealloc {
   [_tabStops release];
   [super dealloc];
}

-copy {
   return [self retain];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

static inline id mutableCopyWithZone(NSParagraphStyle *self,NSZone *zone){
   id copy=[[NSMutableParagraphStyle allocWithZone:zone] init];

   [copy setAlignment:self->_textAlignment];
   [copy setLineBreakMode:self->_lineBreakMode];
   [copy setTabStops:self->_tabStops];

   return copy;
}

-mutableCopy {
   return mutableCopyWithZone(self,NULL);
}

-mutableCopyWithZone:(NSZone *)zone {
   return mutableCopyWithZone(self,zone);
}

-(NSTextAlignment)alignment {
   return _textAlignment;
}

-(NSLineBreakMode)lineBreakMode {
   return _lineBreakMode;
}

-(NSArray *)tabStops {
   return _tabStops;
}

@end
