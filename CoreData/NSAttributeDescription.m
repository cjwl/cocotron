/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSAttributeDescription.h"
#import "NSEntityDescription.h"
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSAttributeDescription

- (id) initWithCoder: (NSCoder *) coder {
   if([coder isKindOfClass: [NSNibKeyedUnarchiver class]]) {
       NSNibKeyedUnarchiver *keyed = (NSNibKeyedUnarchiver *) coder;
       _attributeType = [keyed decodeIntForKey: @"NSAttributeType"];
       _valueClassName
	   = [[keyed decodeObjectForKey: @"NSAttributeValueClassName"] retain];
       _defaultValue = [[keyed decodeObjectForKey: @"NSDefaultValue"] retain];
       _entity = [keyed decodeObjectForKey: @"NSEntity"];
       _propertyName = [[keyed decodeObjectForKey: @"NSPropertyName"] retain];
       _valueTransformerName
	   = [[keyed decodeObjectForKey: @"NSValueTransformerName"] retain];
       
       return self;
   } else {
       [NSException raise: NSInvalidArgumentException
		    format: @"%@ can not initWithCoder:%@", isa, [coder class]];
       return nil;
   }
}


- (id) copyWithZone: (NSZone *) zone {
    return [self retain];
}


- (void) dealloc {
    if(_valueClassName) [_valueClassName release];
    if(_defaultValue) [_defaultValue release];
    if(_propertyName) [_propertyName release];
    if(_valueTransformerName) [_valueTransformerName release];
    [super dealloc];
}


- (NSString *) description {
    return [NSString stringWithFormat: @"<NSAttributeDescription: %@ %@>",
		     _valueClassName, _propertyName];
}


- (NSString *) attributeValueClassName {
    return _valueClassName;
}


- (NSAttributeType) attributeType {
    return _attributeType;
}


- (id) defaultValue {
    return _defaultValue;
}


- (void) setAttributeType: (NSAttributeType) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _attributeType = value;
}


- (void) setDefaultValue: (id) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    if(_defaultValue == value) return;
    if(_defaultValue) [_defaultValue release];
    if(value) [value retain];
    _defaultValue = value;
}

@end

