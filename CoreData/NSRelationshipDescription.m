/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSRelationshipDescription.h"
#import "NSEntityDescription.h"
#import <Foundation/NSKeyedUnarchiver.h>

@implementation NSRelationshipDescription

- (id) initWithCoder: (NSCoder *) coder {
   if([coder isKindOfClass: [NSKeyedUnarchiver class]]) {
       NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *) coder;
       _deleteRule = [keyed decodeIntForKey: @"NSDeleteRule"];
       _destinationEntity = [keyed decodeObjectForKey: @"NSDestinationEntity"];
       _entity = [keyed decodeObjectForKey: @"NSEntity"];
       _inverseRelationship = [keyed decodeObjectForKey: @"NSInverseRelationship"];
       _optional = [keyed decodeBoolForKey: @"NSIsOptional"];
       _maxCount = [keyed decodeIntForKey: @"NSMaxCount"];
       _minCount = [keyed decodeIntForKey: @"NSMinCount"];
       _propertyName = [[keyed decodeObjectForKey: @"NSPropertyName"] retain];
       
       _destinationEntityName
	   = [keyed decodeObjectForKey: @"_NSDestinationEntityName"];
       _inverseRelationshipName
	   = [keyed decodeObjectForKey: @"_NSInverseRelationshipName"];
       
       return self;
   } else {
       [NSException raise: NSInvalidArgumentException
		    format: @"%@ can not initWithCoder:%@", isa, [coder class]];
       return nil;
   }
}


- (NSString *) description {
    return [NSString stringWithFormat: @"<NSRelationshipDescription: %@->%@>",
		     _propertyName, _destinationEntityName];
}


- (BOOL) isToMany {
    if(_maxCount > 1)
	return YES;
    else
	return NO;
}


- (int) maxCount {
    return _maxCount;
}


- (int) minCount {
    return _minCount;
}


- (NSDeleteRule) deleteRule {
    return _deleteRule;
}


- (NSEntityDescription *) destinationEntity {
    return _destinationEntity;
}


- (NSRelationshipDescription *) inverseRelationship {
    return _inverseRelationship;
}


- (void) setMaxCount: (int) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _maxCount = value;
}


- (void) setMinCount: (int) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _minCount = value;
}


- (void) setDeleteRule: (NSDeleteRule) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _deleteRule = value;
}


- (void) setDestinationEntity: (NSEntityDescription *) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _destinationEntity = value;
    _destinationEntityName = [value name];
}


- (void) setInverseRelationship: (NSRelationshipDescription *) value {
    if([_entity _hasBeenInstantiated]) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    _inverseRelationship = value;
    _inverseRelationshipName = [value name];
}


@end
