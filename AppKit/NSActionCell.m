/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSActionCell.h>
#import <Foundation/NSKeyedArchiver.h>

@implementation NSActionCell

-(void)encodeWithCoder:(NSCoder *)coder {
   [super encodeWithCoder:coder];
   [coder encodeInt:_tag forKey:@"NSActionCell tag"];
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];
   
   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
 
    _tag=[keyed decodeIntForKey:@"NSTag"];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
   }
   return self;
}

-(NSView *)controlView {
   return _controlView;
}

-target {
   return _target;
}

-(SEL)action {
   return _action;
}

-(int)tag {
   return _tag;
}


-(void)setControlView:(NSView *)value {
   _controlView=value;
}

-(void)setTarget:target {
   _target=target;
}

-(void)setAction:(SEL)action {
   _action=action;
}

-(void)setTag:(int)tag {
   _tag=tag;
}

@end
