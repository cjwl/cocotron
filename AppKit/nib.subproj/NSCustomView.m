/* Copyright (c) 2006-2007 Dr. Rolf Jansen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSCustomView.h"
#import <Foundation/NSString.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSCustomView

- (id)initWithCoder:(NSCoder *)coder {
   if ([coder isKindOfClass:[NSNibKeyedUnarchiver class]]) {
      NSString *className = [(NSNibKeyedUnarchiver *)coder decodeObjectForKey:@"NSClassName"];
      Class     class = NSClassFromString(className);
      if (class == nil) {
         NSLog(@"NSCustomView unknown class %@", className);
         return self;
      }
      else {
         NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
         NSRect frame=NSZeroRect;
         if([keyed containsValueForKey:@"NSFrame"])
            frame=[keyed decodeRectForKey:@"NSFrame"];
         else if([keyed containsValueForKey:@"NSFrameSize"])
            frame.size=[keyed decodeSizeForKey:@"NSFrameSize"];

         [self release];
         self=[[class alloc] initWithFrame:frame];
         if([keyed containsValueForKey:@"NSvFlags"])
            _autoresizingMask=((unsigned int)[keyed decodeIntForKey:@"NSvFlags"])&0x3F;
         if([keyed containsValueForKey:@"NSTag"])
            _tag=[keyed decodeIntForKey:@"NSTag"];
         [_subviews addObjectsFromArray:[keyed decodeObjectForKey:@"NSSubviews"]];
         [_subviews makeObjectsPerformSelector:@selector(_setSuperview:) withObject:self];
         return self;
      }
   }
   else {
      [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] does not handle %@",isa,SELNAME(_cmd),[coder class]];
      return self;
   }
}

@end
