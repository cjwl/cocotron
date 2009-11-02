#import <CoreFoundation/CFArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCFTypeID.h>
#import <Foundation/NSArray_concrete.h>

const CFArrayCallBacks kCFTypeArrayCallBacks={
};

#define nsrange(r) NSMakeRange(r.location,r.length)

CFTypeID CFArrayGetTypeID(void) {
   return kNSCFTypeArray;
}

CFArrayRef CFArrayCreate(CFAllocatorRef allocator,const void **values,CFIndex count,const CFArrayCallBacks *callbacks) {
	return (CFArrayRef)NSArray_concreteNew(NULL, (id*)values, count);
}

CFArrayRef CFArrayCreateCopy(CFAllocatorRef allocator,CFArrayRef self) {
	return (CFArrayRef)[(id) self copy]; 
}


CFIndex CFArrayGetCount(CFArrayRef self) {
	return [(NSArray*)self count];
}

const void *CFArrayGetValueAtIndex(CFArrayRef self,CFIndex index) {
	return [(NSArray*)self objectAtIndex:index];
}

void CFArrayGetValues(CFArrayRef self,CFRange range,const void **values) {
	[(NSArray*)self getObjects:(id*)values range:nsrange(range)];
}

Boolean CFArrayContainsValue(CFArrayRef self,CFRange range,const void *value) {
	int i;
	for(i=range.location;i<range.location+range.length;i++)
	{
		if([[(NSArray*)self objectAtIndex:i]isEqual:(id)value]) return YES;
	}
	return NO;
	
}

CFIndex CFArrayGetFirstIndexOfValue(CFArrayRef self,CFRange range,const void *value) {
	int i;
	for(i=range.location;i<range.location+range.length;i++)
	{
		if([[(NSArray*)self objectAtIndex:i]isEqual:(id)value]) return i;
	}
	return NSNotFound;
	
   
}

CFIndex CFArrayGetLastIndexOfValue(CFArrayRef self,CFRange range,const void *value) {
	int i;
	for(i=range.location+range.length;i>range.location;i--)
	{
		if([[(NSArray*)self objectAtIndex:i]isEqual:(id)value]) return i;
	}
	return NSNotFound;
}

CFIndex CFArrayGetCountOfValue(CFArrayRef self,CFRange range,const void *value) {
	int i;
	int count=0;
	for(i=range.location+range.length;i>range.location;i--)
	{
		if([[(NSArray*)self objectAtIndex:i]isEqual:(id)value]) return count++;
	}
	return count;
	
}

void CFArrayApplyFunction(CFArrayRef self,CFRange range,CFArrayApplierFunction function,void *context) {
	int i;
	for(i=range.location+range.length;i>range.location;i--)
	{
		if([(NSArray*)self objectAtIndex:i]) function(self,context);
	}
	
}

CFIndex CFArrayBSearchValues(CFArrayRef self,CFRange range,const void *value,CFComparatorFunction function,void *context) {
   NSUnimplementedFunction();
}


// mutable

CFMutableArrayRef CFArrayCreateMutable(CFAllocatorRef allocator,CFIndex capacity,const CFArrayCallBacks *callbacks) {
	return (CFMutableArrayRef)[NSMutableArray new];
}


CFMutableArrayRef CFArrayCreateMutableCopy(CFAllocatorRef allocator,CFIndex capacity,CFArrayRef self) {
			return (CFMutableArrayRef)[(id)self mutableCopy];
}


void CFArrayAppendValue(CFMutableArrayRef self,const void *value) {
	return [(NSMutableArray*)self addObject:(id) value];
}

void CFArrayAppendArray(CFMutableArrayRef self,CFArrayRef other,CFRange range) {
	[(NSMutableArray*)self addObjectsFromArray:[(NSMutableArray*)other subarrayWithRange:nsrange(range)]];
}

void CFArrayRemoveValueAtIndex(CFMutableArrayRef self,CFIndex index) {
	[(NSMutableArray*)self removeObjectAtIndex:index];
}

void CFArrayRemoveAllValues(CFMutableArrayRef self) {
	[(NSMutableArray*)self removeAllObjects];
}

void CFArrayInsertValueAtIndex(CFMutableArrayRef self,CFIndex index,const void *value) {
	[(NSMutableArray*)self insertObject:(id)value atIndex:index];
}

void CFArraySetValueAtIndex(CFMutableArrayRef self,CFIndex index,const void *value) {
	[(NSMutableArray*)self replaceObjectAtIndex:index withObject:(id) value];
}

void CFArrayReplaceValues(CFMutableArrayRef self,CFRange range,const void **values,CFIndex count) {
   NSUnimplementedFunction();
}

void CFArrayExchangeValuesAtIndices(CFMutableArrayRef self,CFIndex index,CFIndex other) {
	[(NSMutableArray*)self exchangeObjectAtIndex:index withObjectAtIndex:other];
}

void CFArraySortValues(CFMutableArrayRef self,CFRange range,CFComparatorFunction function,void *context) {
   NSUnimplementedFunction();
}



