#import <objc/runtime.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSString.h>
#import <string.h>
#import <stddef.h>
#import <stdlib.h>
#import <ctype.h>

const char *property_getAttributes(objc_property_t property){
   // UNIMPLEMENTED
   return NULL;
}

const char *property_getName(objc_property_t property) {
   // UNIMPLEMENTED
   return NULL;
}

void objc_copyStruct(void *dest, const void *src, size_t size, BOOL atomic,BOOL hasStrong) {
   int i;
   
   for(i=0;i<size;i++)
    ((uint8_t *)dest)[i]=((uint8_t *)src)[i];
}


void objc_setProperty (id self, SEL _cmd, size_t offset, id value, BOOL isAtomic, BOOL shouldCopy)
{
	if(isAtomic)
	{
	//	NSUnimplementedFunction();
	}
	
	const char* origName = sel_getName(_cmd);
	NSInteger selLen=strlen(origName);
	char *sel=__builtin_alloca(selLen+1);
	strcpy(sel, origName);
	sel[selLen-1]='\0';
	sel+=3;
	sel[0]=tolower(sel[0]);
	NSString *key=[[NSString alloc] initWithCString:sel];
	[self willChangeValueForKey:key];
	
	void *buffer=(void*)self+offset;
	id oldValue=*(id*)buffer;
	
	if(shouldCopy)
		*(id*)buffer=[value copy];
	else
		*(id*)buffer=[value retain];
	
	[oldValue release];
	[self didChangeValueForKey:key];

	[key release];
}

id objc_getProperty (id self, SEL _cmd, size_t offset, BOOL isAtomic)
{
	if(isAtomic)
	{
	//	NSUnimplementedFunction();
	}

	void *buffer=(void*)self+offset;
	id value=*(id*)buffer;
	
	return [[value retain] autorelease];
}

