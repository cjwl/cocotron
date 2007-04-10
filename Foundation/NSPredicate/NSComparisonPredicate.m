/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSRaise.h>

@implementation NSComparisonPredicate

-initWithLeftExpression:(NSExpression *)left rightExpression:(NSExpression *)right modifier:(NSComparisonPredicateModifier)modifier type:(NSPredicateOperatorType)type options:(unsigned)options {
   _left=[left retain];
   _right=[right retain];
   _modifier=modifier;
   _type=type;
   _options=options;
   _customSelector=NULL;
   return self;
}

-initWithLeftExpression:(NSExpression *)left rightExpression:(NSExpression *)right customSelector:(SEL)selector {
   _left=[left retain];
   _right=[right retain];
   _modifier=NSDirectPredicateModifier;
   _type=NSCustomSelectorPredicateOperatorType;
   _options=0;
   _customSelector=selector;
   return self;
}

-(void)dealloc {
   [_left release];
   [_right release];
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

+(NSPredicate *)predicateWithLeftExpression:(NSExpression *)left rightExpression:(NSExpression *)right modifier:(NSComparisonPredicateModifier)modifier type:(NSPredicateOperatorType)type options:(unsigned)options {
   return [[[self alloc] initWithLeftExpression:left rightExpression:right modifier:modifier type:type options:options] autorelease];
}

+(NSPredicate *)predicateWithLeftExpression:(NSExpression *)left rightExpression:(NSExpression *)right customSelector:(SEL)selector {
   return [[[self alloc] initWithLeftExpression:left rightExpression:right customSelector:selector] autorelease];
}

-(NSExpression *)leftExpression {
   return _left;
}

-(NSExpression *)rightExpression {
   return _right;
}

-(NSPredicateOperatorType)predicateOperatorType {
   return _type;
}

-(NSComparisonPredicateModifier)comparisonPredicateModifier {
   return _modifier;
}

-(unsigned)options {
   return _options;
}

-(SEL)customSelector {
   return _customSelector;
}

-(BOOL)evaluateObject:object {
   id leftResult=[_left expressionValueWithObject:object context:nil];
   id rightResult=[_right expressionValueWithObject:object context:nil];
   
   switch(_type){
   
    case NSLessThanPredicateOperatorType:
     break;
     
    case NSLessThanOrEqualToPredicateOperatorType:
     break;
     
    case NSGreaterThanPredicateOperatorType:
     break;
     
    case NSGreaterThanOrEqualToPredicateOperatorType:
     break;
     
    case NSEqualToPredicateOperatorType:
     break;
     
    case NSNotEqualToPredicateOperatorType:
     break;
     
    case NSMatchesPredicateOperatorType:
     break;
     
    case NSLikePredicateOperatorType:
     break;
     
    case NSBeginsWithPredicateOperatorType:
     break;
     
    case NSEndsWithPredicateOperatorType:
     break;
     
    case NSInPredicateOperatorType:
     break;
     
    case NSCustomSelectorPredicateOperatorType:
     break;
     
   }
}

@end
