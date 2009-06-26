/* Copyright (c) 2006-2007 Dr. Rolf Jansen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSCustomView.h"
#import <Foundation/NSString.h>
#import <Foundation/NSKeyedArchiver.h>

@implementation NSCustomView

- (id)initWithCoder:(NSCoder *)coder {
   if ([coder allowsKeyedCoding]) {
      NSString *className = [(NSKeyedUnarchiver *)coder decodeObjectForKey:@"NSClassName"];
      Class     class = NSClassFromString(className);
      if (class == nil) {
         NSLog(@"NSCustomView unknown class %@", className);
         return self;
      }
      else {
         NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
         NSRect frame=NSZeroRect;
         if([keyed containsValueForKey:@"NSFrame"])
            frame=[keyed decodeRectForKey:@"NSFrame"];
         else if([keyed containsValueForKey:@"NSFrameSize"])
            frame.size=[keyed decodeSizeForKey:@"NSFrameSize"];

         NSView *newView=[[class alloc] initWithFrame:frame];
         if([keyed containsValueForKey:@"NSvFlags"])
             newView->_autoresizingMask=((unsigned int)[keyed decodeIntForKey:@"NSvFlags"])&0x3F;
         if([keyed containsValueForKey:@"NSTag"])
             newView->_tag=[keyed decodeIntForKey:@"NSTag"];
         [newView->_subviews addObjectsFromArray:[keyed decodeObjectForKey:@"NSSubviews"]];
         [newView->_subviews makeObjectsPerformSelector:@selector(_setSuperview:) withObject:newView];
         [_subviews removeAllObjects];
         [self release];
         return newView;
      }
   }
   else {
      [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] does not handle %@",isa,sel_getName(_cmd),[coder class]];
      return self;
   }
}

@end
