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

-(void)_initWithDefaults {
   _writingDirection=NSWritingDirectionLeftToRight;
   _paragraphSpacing=0;
   _paragraphSpacingBefore=0;
   _textBlocks=nil;
   _textLists=nil;
   _headerLevel=0;
   _firstLineHeadIndent=0;
   _headIndent=0;
   _tailIndent=0;
   _alignment=NSLeftTextAlignment;
   _lineBreakMode=NSLineBreakByWordWrapping;
   _minimumLineHeight=0;
   _maximumLineHeight=0;
   _lineHeightMultiple=0;
   _lineSpacing=0;
   _defaultTabInterval=0;
   _tabStops=[[isa _defaultTabStops] retain];
   _hyphenationFactor=0;
   _tighteningFactorForTruncation=0;
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    [self _initWithDefaults];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }
   
   return self;
}

-init {
   [self _initWithDefaults];
   return self;
}

-initWithParagraphStyle:(NSParagraphStyle *)other {
   _writingDirection=[other baseWritingDirection];
   _paragraphSpacing=[other paragraphSpacing];
   _paragraphSpacingBefore=[other paragraphSpacingBefore];
   _textBlocks=[[other textBlocks] copy];
   _textLists=[[other textLists] copy];
   _headerLevel=[other headerLevel];
   _firstLineHeadIndent=[other firstLineHeadIndent];
   _headIndent=[other headIndent];
   _tailIndent=[other tailIndent];
   _alignment=[other alignment];
   _lineBreakMode=[other lineBreakMode];
   _minimumLineHeight=[other minimumLineHeight];
   _maximumLineHeight=[other maximumLineHeight];
   _lineHeightMultiple=[other lineHeightMultiple];
   _lineSpacing=[other lineSpacing];
   _defaultTabInterval=[other defaultTabInterval];
   _tabStops=[[other tabStops] copy];
   _hyphenationFactor=[other hyphenationFactor];
   _tighteningFactorForTruncation=[other tighteningFactorForTruncation];
   return self;
}

-(void)dealloc {
   [_textBlocks release];
   [_textLists release];
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
   return [[NSMutableParagraphStyle allocWithZone:zone] initWithParagraphStyle:self];
}

-mutableCopy {
   return mutableCopyWithZone(self,NULL);
}

-mutableCopyWithZone:(NSZone *)zone {
   return mutableCopyWithZone(self,zone);
}

-(NSWritingDirection)baseWritingDirection {
   return _writingDirection;
}

-(float)paragraphSpacing {
   return _paragraphSpacing;
}

-(float)paragraphSpacingBefore {
   return _paragraphSpacingBefore;
}

-(NSArray *)textBlocks {
   return _textBlocks;
}

-(NSArray *)textLists {
   return _textLists;
}

-(int)headerLevel {
   return _headerLevel;
}

-(float)firstLineHeadIndent {
   return _firstLineHeadIndent;
}

-(float)headIndent {
   return _headIndent;
}

-(float)tailIndent {
   return _tailIndent;
}

-(NSTextAlignment)alignment {
   return _alignment;
}

-(NSLineBreakMode)lineBreakMode {
   return _lineBreakMode;
}

-(float)minimumLineHeight {
   return _minimumLineHeight;
}

-(float)maximumLineHeight {
   return _maximumLineHeight;
}

-(float)lineHeightMultiple {
   return _lineHeightMultiple;
}

-(float)lineSpacing {
   return _lineSpacing;
}

-(float)defaultTabInterval {
   return _defaultTabInterval;
}

-(NSArray *)tabStops {
   return _tabStops;
}

-(float)hyphenationFactor {
   return _hyphenationFactor;
}

-(float)tighteningFactorForTruncation {
   return _tighteningFactorForTruncation;
}

@end
