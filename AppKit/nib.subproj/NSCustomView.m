/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSCustomView.h"
#import <Foundation/NSString.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSCustomView

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned           vFlags=[keyed decodeIntForKey:@"NSvFlags"];
    
    _className=[[keyed decodeObjectForKey:@"NSClassName"] retain];
    _frame=NSZeroRect;
    if([keyed containsValueForKey:@"NSFrame"])
     _frame=[keyed decodeRectForKey:@"NSFrame"];
    else if([keyed containsValueForKey:@"NSFrameSize"])
     _frame.size=[keyed decodeSizeForKey:@"NSFrameSize"];
    _autoresizingMask=vFlags&0x3F;
    _tag=-1;
    if([keyed containsValueForKey:@"NSTag"])
     _tag=[keyed decodeIntForKey:@"NSTag"];
   }
   else 
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] does not handle %@",isa,SELNAME(_cmd),[coder class]];
   
   return self;
}

-(void)dealloc {
   [_className release];
   [super dealloc];
}

-awakeAfterUsingCoder:(NSCoder *)coder {
   id    result;
   Class class=NSClassFromString(_className);

   if(class==Nil)
    NSLog(@"NSCustomView unknown class %@",_className);
    
   result=[[[class alloc] initWithFrame:_frame] autorelease];
   [result setAutoresizingMask:_autoresizingMask];
   [result setTag:_tag];
      
   return result;
}

@end
