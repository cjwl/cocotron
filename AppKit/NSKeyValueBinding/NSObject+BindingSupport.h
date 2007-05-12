/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>

@class NSDictionary,NSArray;

@interface NSObject (BindingSupport)
-(void)bind:(NSString *)binding toObject:(id)destination withKeyPath:(NSString*)keyPath options:(NSDictionary*)options;
-(NSDictionary *)infoForBinding:(NSString*)binding;
-(void)unbind:(NSString*)binding;
@end


@interface NSObject (InternalBindingSupport)
+(Class)_binderClassForBinding:(id)binding;
-(id)_binderForBinding:(id)binding create:(BOOL)create;
-(id)_replacementKeyPathForBinding:(id)binding;
-(void)_cleanupBinders;
-(NSArray*)_allUsedBinders;
@end
