/* Copyright (c) 2006-2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSKeyValueObserving.h>
#include <objc/objc-class.h>
#include <malloc.h>
#include <string.h>

#import "NSKVCMutableArray.h"
#import "NSString+KVCAdditions.h"

@implementation NSObject (KeyValueCoding)
#pragma mark -
#pragma mark Private helper methods
-(void)_demangleTypeEncoding:(const char*)type to:(char*)cleanType
{
	while(*type)
	{
		if(*type=='"')
		{
			type++;
			while(*type && *type!='"')
				type++;
			type++;
		}
		*cleanType=*type;
		type++; cleanType++;
		*cleanType=0;
	}
}

-(id)_wrapValue:(void*)value ofType:(const char*)type
{
	if(type[0]!='@' && strlen(type)>1)
	{
		// valueWithBytes:objCType: doesn't like quotes in its types
		char* cleanType=alloca(strlen(type)+1);
		[self _demangleTypeEncoding:type to:cleanType];

		return [NSValue valueWithBytes:value objCType:cleanType];
	}

	switch(type[0])
	{
		case '@':
			return *(id*)value;
		case 'i':
			return [NSNumber numberWithInt:*(int*)value];
		case 'I':
			return [NSNumber numberWithUnsignedInt:*(int*)value];
		case 'f':
			return [NSNumber numberWithFloat:*(float*)value];
		case 'd':
			return [NSNumber numberWithDouble:*(double*)value];
		case 's':
			return [NSNumber numberWithShort:*(short*)value];
		case 'S':
			return [NSNumber numberWithUnsignedShort:*(unsigned short*)value];
		case 'c':
			return [NSNumber numberWithChar:*(char*)value];
		case 'C':
			return [NSNumber numberWithUnsignedChar:*(unsigned char*)value];
		default:
// FIX #warning some wrapping types unimplemented
			return [NSString stringWithFormat:@"FIXME: wrap value of type %s unimplemented for get", type];	
	}
}

-(BOOL)_setValue:(id)value toBuffer:(void*)buffer ofType:(const char*)type
{
	if(type[0]!='@' && strlen(type)>1)
	{
		char* cleanType=alloca(strlen(type)+1);
		[self _demangleTypeEncoding:type to:cleanType];

		if(strcmp([value objCType], cleanType))
		{
			return NO;
		}
		[value getValue:buffer];
		return YES;
	}
	
	switch(type[0])
	{
		case '@':
			*(id*)buffer = value;
			return YES;
		case 'i':
			*(int*)buffer = [value intValue];
			return YES;
		case 'I':
			*(unsigned int*)buffer = [value unsignedIntValue];
			return YES;
		case 'f':
			*(float*)buffer = [value floatValue];
			return YES;
		case 'd':
			*(double*)buffer = [value doubleValue];
			return YES;

		case 'c':
			*(char*)buffer = [value charValue];
			return YES;
		case 'C':
			*(unsigned char*)buffer = [value unsignedCharValue];
			return YES;

		default:
// FIX #warning some wrapping types unimplemented
			NSLog(@"FIXME: wrap value of type %s unimplemented for set", type);
			return NO;
	}
}

-(id)_wrapReturnValueForSelector:(SEL)sel
{
	id sig=[self methodSignatureForSelector:sel];
	const char* type=[sig methodReturnType];
	if(strcmp(type, "@"))
	{
		id inv=[NSInvocation invocationWithMethodSignature:sig];
		[inv setSelector:sel];
		[inv setTarget:self];
		[inv invoke];
		
		int returnLength=[sig methodReturnLength];
		void *returnValue=alloca(returnLength);
		[inv getReturnValue:returnValue];
		
		return [self _wrapValue:returnValue ofType:type];
	}
	return [self performSelector:sel];
}

-(void)_setValue:(id)value withSelector:(SEL)sel fromKey:(id)key
{
	id sig=[self methodSignatureForSelector:sel];
	const char* type=[sig getArgumentTypeAtIndex:2];
	if(strcmp(type, "@"))
	{
		if(!value)
		{
			// value is nil and accessor doesn't take object type
			return [self setNilValueForKey:key];
		}
		unsigned int size, align;
		NSInvocation* inv=[NSInvocation invocationWithMethodSignature:sig];
		[inv setSelector:sel];
		[inv setTarget:self];
		
		NSGetSizeAndAlignment(type, &size, &align);
		void *buffer=alloca(size);		
		[self _setValue:value toBuffer:buffer ofType:type];
		
		[inv setArgument:buffer atIndex:2];

		[inv invoke];
		return;
	}
	[self performSelector:sel withObject:value];
}

#pragma mark -
#pragma mark Primary methods

-(id)valueForKey:(NSString*)key
{
	SEL sel=NSSelectorFromString(key);
	// FIXME: getKey, _getKey, isKey, _isKey are missing
	
	if([self respondsToSelector:sel])
	{
		return [self _wrapReturnValueForSelector:sel];
	}
	
	if([isa accessInstanceVariablesDirectly])
	{
		sel=NSSelectorFromString([NSString stringWithFormat:@"_%@", key]);
		if([self respondsToSelector:sel])
		{
			return [self _wrapReturnValueForSelector:sel];
		}
		
		Ivar ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"_%@", key] cString]);
		if(!ivar)
			ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"%@", key] cString]);
		if(ivar)
		{
			return [self _wrapValue:(void*)self+ivar->ivar_offset ofType:ivar->ivar_type];
		}
		
	}
	
	return [self valueForUndefinedKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	NSString* ukey = [NSString stringWithFormat:@"%@%@", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
	SEL sel = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ukey]);
	if([self respondsToSelector:sel])
	{
		return [self _setValue:value withSelector:sel fromKey:key];
	}

	if([isa accessInstanceVariablesDirectly])
	{
		sel = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ukey]);
		if([self respondsToSelector:sel])
		{
			return [self _setValue:value withSelector:sel fromKey:key];
		}

		Ivar ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"_%@", key] cString]);
		if(!ivar)
			ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"_is%@", ukey] cString]);
		if(!ivar)
			ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"%@", key] cString]);
		if(!ivar)
			ivar = class_getInstanceVariable(isa, [[NSString stringWithFormat:@"is%@", ukey] cString]);

		if(ivar)
		{
			[self willChangeValueForKey:key];
			// if value is nil and ivar is not an object type
			if(!value && ivar->ivar_type[0]!='@')
				return [self setNilValueForKey:key];

			[self _setValue:value toBuffer:(void*)self+ivar->ivar_offset ofType:ivar->ivar_type];
			[self didChangeValueForKey:key];
			return;
		}
	}

	[self setValue:value forUndefinedKey:key];	
}

- (BOOL)validateValue:(id *)ioValue forKey:(NSString *)key error:(NSError **)outError
{
	SEL sel=NSSelectorFromString([NSString stringWithFormat:@"validate%@:error:", [key capitalizedString]]);
	if([self respondsToSelector:sel])
	{
		id inv=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
		[inv setSelector:sel];
		[inv setTarget:self];
		[inv setArgument:ioValue atIndex:2];
		[inv setArgument:outError atIndex:3];
		[inv invoke];
		BOOL ret;
		[inv getReturnValue:&ret];
		return ret;
	}
	return YES;
}


#pragma mark -
#pragma mark Secondary methods
+(BOOL)accessInstanceVariablesDirectly
{
	return YES;
}

- (id)valueForUndefinedKey:(NSString *)key
{
	[NSException raise:@"NSUndefinedKeyException" 
				format:@"%@: trying to get undefined key %@", [self className], key];
	return nil;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[NSException raise:@"NSUndefinedKeyException" 
				format:@"%@: trying to set undefined key %@", [self className], key];
}

-(void)setNilValueForKey:(id)key
{
	[NSException raise:@"NSInvalidArgumentException" 
				format:@"%@: trying to set nil value for key %@", [self className], key];
}

-(id)valueForKeyPath:(NSString*)keyPath
{
	NSString* firstPart, *rest;
	[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];
	if(rest)
		return [[self valueForKeyPath:firstPart] valueForKeyPath:rest];
	else
		return [self valueForKey:firstPart];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	NSString* firstPart, *rest;
	[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];

	if(rest)
		[[self valueForKey:firstPart] setValue:value
									forKeyPath:rest];
	else
	{
		[self setValue:value 
				forKey:firstPart];
	}
}

- (BOOL)validateValue:(id *)ioValue forKeyPath:(NSString *)keyPath error:(NSError **)outError
{
// FIX: should this be recursive or not?
	id array=[[[keyPath componentsSeparatedByString:@"."] mutableCopy] autorelease];
	id lastPathComponent=[array lastObject];
	[array removeObject:lastPathComponent];
	id en=[array objectEnumerator];
	id pathComponent;
	id ret=self;
	while((pathComponent = [en nextObject]) && ret)
	{
		ret = [ret valueForKey:pathComponent];
	}
	return [self validateValue:ioValue forKey:lastPathComponent error:outError];
}


-(NSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys
{
	id en=[keys objectEnumerator];
	id ret=[NSMutableDictionary dictionary];
	id key;
	while(key=[en nextObject])
	{
		id value=[self valueForKey:key];
		[ret setObject:value ? value : [NSNull null] forKey:key];
	}
	return ret;
}


- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues
{
	id en=[keyedValues keyEnumerator];
	NSString* key;
	NSNull* null=[NSNull null];
	while(key=[en nextObject])
	{
		id value=[keyedValues objectForKey:key];
		[self setValue:value == null ? nil : value forKey:key];
	}
}

-(id)mutableArrayValueForKey:(id)key
{
	return [[[NSKVCMutableArray alloc] initWithKey:key forProxyObject:self] autorelease];
}
@end



