/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSExpression.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSKeyValueCoding.h>

@implementation NSExpression

-initWithExpressionType:(NSExpressionType)type {
   _type=type;
   _value=nil;
   _arguments=nil;
   return self;
}

-initWithExpressionType:(NSExpressionType)type value:value arguments:(NSArray *)arguments {
   _type=type;
   _value=[value copy];
   _arguments=[arguments retain];
   return self;
}

-(void)dealloc {
   [_value release];
   [_arguments release];
   [super dealloc];
}

-initWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

+(NSExpression *)expressionForConstantValue:value {
   return [[[self alloc] initWithExpressionType:NSConstantValueExpressionType value:value arguments:nil] autorelease];
}

+(NSExpression *)expressionForEvaluatedObject {
   return [[[self alloc] initWithExpressionType:NSEvaluatedObjectExpressionType value:nil arguments:nil] autorelease];
}

+(NSExpression *)expressionForVariable:(NSString *)string {
   return [[[self alloc] initWithExpressionType:NSVariableExpressionType value:string arguments:nil] autorelease];
}

+(NSExpression *)expressionForKeyPath:(NSString *)keyPath {
   return [[[self alloc] initWithExpressionType:NSKeyPathExpressionType value:keyPath arguments:nil] autorelease];
}

+(NSExpression *)expressionForFunction:(NSString *)name arguments:(NSArray *)arguments {
// FIX validate name ?
   return [[[self alloc] initWithExpressionType:NSFunctionExpressionType value:name arguments:arguments] autorelease];
}

+(NSExpression *)expressionForVariable:(NSString *)name assignment:(NSExpression *)assignment {
   return nil;
}

+(NSExpression *)expressionForKeyPathLeft:(NSExpression *)left right:(NSExpression *)right {
   return nil;
}

-(NSExpressionType)expressionType {
   return _type;
}

-constantValue {
   if(_type!=NSConstantValueExpressionType)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not of NSConstantValueExpressionType",isa,SELNAME(_cmd)];
    
   return _value;
}

-(NSString *)variable {
   if(_type!=NSVariableExpressionType)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not of NSVariableExpressionType",isa,SELNAME(_cmd)];
    
   return _value;
}

-(NSString *)keyPath {
   if(_type!=NSKeyPathExpressionType)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not of NSKeyPathExpressionType",isa,SELNAME(_cmd)];
    
   return _value;
}

-(NSString *)function {
   if(_type!=NSFunctionExpressionType)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not of NSFunctionExpressionType",isa,SELNAME(_cmd)];
    
   return _value;
}

-(NSArray *)arguments {
   if(_type!=NSFunctionExpressionType)
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not of NSFunctionExpressionType",isa,SELNAME(_cmd)];
    
   return _arguments;
}

-(NSExpression *)operand {
}

-expressionValueWithObject:object context:(NSMutableDictionary *)context {
   switch(_type){
    case NSConstantValueExpressionType:
     return _value;
     
    case NSEvaluatedObjectExpressionType:
     return object;
     
    case NSVariableExpressionType:
     NSUnimplementedMethod();
     return nil;
     
    case NSKeyPathExpressionType:
     return [object valueForKeyPath:_value];
     
    case NSFunctionExpressionType:
     NSUnimplementedMethod();
     return nil;
   }
}

@end
