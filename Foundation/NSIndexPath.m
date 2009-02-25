/* Copyright (c) 2007 Dirk Theisen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSIndexPath.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSRaise.h>
#import <string.h>

@implementation NSIndexPath

+ (NSIndexPath*) indexPathWithIndex: (unsigned int) index {
	return [[[self alloc] initWithIndexes: &index length: 1] autorelease];
}

+ (NSIndexPath*) indexPathWithIndexes: (unsigned int*) indexes length: (unsigned int) length {
	return [[[self alloc] initWithIndexes: indexes length: length] autorelease];
}

- (id) initWithIndex: (unsigned int) index {
	return [self initWithIndexes: &index length: 1];
}

- (id) initWithIndexes: (unsigned int*) indexes length: (unsigned int) length {
	if ((self = [self init])) {
		int i;
		
		_length  = length;
		_indexes = indexes;
		_hash    = 0;
		// Calculate hash:
		for (i=0; i<_length; i++) {
			_hash = _hash*2 + _indexes[i];
		}
		_hash = 2*_hash + _length;
   		_indexes = malloc(length*sizeof(unsigned int));
		memcpy(_indexes, indexes, length*sizeof(unsigned int));
   	}
	return self;
}

- (BOOL) isEqual: (id) other {
	if ([other isKindOfClass: [NSIndexPath class]]) {
		NSIndexPath* otherPath = other;
		return _length == otherPath->_length && memcmp(_indexes, otherPath->_indexes, _length);
	}
	return NO;
}

- (void) dealloc {
	if (_indexes) free(_indexes);
	[super dealloc];
}

- (NSIndexPath*) indexPathByAddingIndex: (unsigned int) index {
	// Use lazy copying, if possible:
	unsigned int* indexesCopy = realloc(_indexes, (_length+1)*sizeof(unsigned int));
	// Add the index:
	indexesCopy[_length] = index;
	// Make sure to use the designated initializer:
	NSIndexPath* result = [self initWithIndexes: indexesCopy length: _length+1];
	
	if (indexesCopy != _indexes) {
		// We actually got a copy (not an extension), so free it:
		free(indexesCopy);
	}
	
	return [result autorelease];
}

- (NSIndexPath*) indexPathByRemovingLastIndex {
	NSAssert(_length>1, @"Unable to remove index from zero length path.");
	return [[[NSIndexPath alloc] initWithIndexes: _indexes length: _length-1] autorelease];
}

- (unsigned int) indexAtPosition: (unsigned int) position {
	NSParameterAssert(position < _length);
	return _indexes[position];
}

- (unsigned int) length {
	return _length;
}

- (void) getIndexes: (unsigned int*) indexes {
	memcpy(indexes, _indexes, _length * sizeof(unsigned int));
}

/** Note: Sorting an array of indexPaths using this comparison method results in an array representing nodes in depth-first traversal order. */
- (NSComparisonResult) compare: (NSIndexPath*) otherObject {
	int i;
	for (i=0; i<_length; i++) {
		if (_indexes[i] != otherObject->_indexes[i]) {
			return _indexes[i] < otherObject->_indexes[i] ? NSOrderedAscending : NSOrderedDescending;
		}
	}
	return NSOrderedSame;
}

- (id) copyWithZone: (NSZone*) zone
{
	return [self retain];
}


- (id) copy 
{
	return [self retain];
}

- (unsigned) hash {
	return _hash;
}

- (void) encodeWithCoder: (NSCoder*) aCoder {
	NSUnimplementedMethod();
}

- (id) initWithCoder: (NSCoder*) aDecoder {
	NSUnimplementedMethod();
    return nil;
}

@end
