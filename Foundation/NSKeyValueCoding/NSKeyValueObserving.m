/* Copyright (c) 2007-2008 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSDebug.h>

#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#import <string.h>
#import <ctype.h>

#import "NSString+KVCAdditions.h"
#import "NSKeyValueObserving-Private.h"

NSString *const NSKeyValueChangeKindKey=@"NSKeyValueChangeKindKey";
NSString *const NSKeyValueChangeNewKey=@"NSKeyValueChangeNewKey";
NSString *const NSKeyValueChangeOldKey=@"NSKeyValueChangeOldKey";
NSString *const NSKeyValueChangeIndexesKey=@"NSKeyValueChangeIndexesKey";
NSString *const NSKeyValueChangeNotificationIsPriorKey=@"NSKeyValueChangeNotificationIsPriorKey";

NSString *const _KVO_DependentKeysTriggeringChangeNotification=@"_KVO_DependentKeysTriggeringChangeNotification";
NSString *const _KVO_KeyPathsForValuesAffectingValueForKey=@"_KVO_KeyPathsForValuesAffectingValueForKey";

static BOOL CreateClassDefinition( const char * name, const char * superclassName );

#pragma mark -
#pragma mark KVO implementation

static NSMutableDictionary *observationInfos=nil;
static NSLock *kvoLock=nil;

@interface NSObject (KVOSettersForwardReferencs)
+(void)_KVO_buildDependencyUnion;
@end

@interface NSObject (KVCPrivateMethod)
-(void)_demangleTypeEncoding:(const char*)type to:(char*)cleanType;
@end

@implementation NSObject (KeyValueObserving)

-(void*)observationInfo
{
	return [[observationInfos objectForKey:[NSValue valueWithPointer:self]] pointerValue];
}

-(void)setObservationInfo:(void*)info
{
	if(!observationInfos)
		observationInfos=[NSMutableDictionary new];
	[observationInfos setObject:[NSValue valueWithPointer:info] forKey:[NSValue valueWithPointer:self]];
}

+(void*)observationInfo
{
	return [[observationInfos objectForKey:[NSValue valueWithPointer:self]] pointerValue];
}

+(void)setObservationInfo:(void*)info
{
	if(!observationInfos)
		observationInfos=[NSMutableDictionary new];
	[observationInfos setObject:[NSValue valueWithPointer:info] forKey:[NSValue valueWithPointer:self]];
}

-(void)addObserver:(id)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context;
{
	[self _KVO_swizzle];
	NSString* remainingKeyPath;
	NSString* key;
	[keyPath _KVC_partBeforeDot:&key afterDot:&remainingKeyPath];
	
	// get observation info dictionary, creating it if it's not there
	NSMutableDictionary* dict=[self observationInfo];
	if(!dict)
	{
		[self setObservationInfo:[NSMutableDictionary new]];
		dict=[self observationInfo];
	}

	// get all observers for current key
	NSMutableArray *observers=[dict objectForKey:key];
	if(!observers)
	{
		observers = [NSMutableArray array];
		[dict setObject:observers forKey:key];
	}

	// find if already observing
	NSEnumerator *en=[observers objectEnumerator];
	_NSObservationInfo *current;
	_NSObservationInfo *info=nil;
	while((current=[en nextObject]))
	{
		if([current observer]==observer)
			info=current;
	}
	// create new info if not already observing
	if(!info)
	{
		info=[_NSObservationInfo new];
		[observers addObject:info];
		[info release];
	}

	// set info options
	info->observer=observer;
	info->options=options;
	info->context=context;
	info->object=self;
	[info setKeyPath:keyPath];

	// if observing a key path, also observe all deeper levels
	// info object acts as a proxy replacing remainingKeyPath with keyPath 
	if([remainingKeyPath length])
	{
		[[self valueForKey:key] addObserver:info
									forKeyPath:remainingKeyPath
									   options:options
									   context:context];
	}
	
	NSSet* keysPathsForKey=[isa keyPathsForValuesAffectingValueForKey:key];
	for(NSString *path in keysPathsForKey)
	{
		[self addObserver:info
			   forKeyPath:path
				  options:options
				  context:context];
	}
	
	if(options & NSKeyValueObservingOptionInitial)
	{
		[self willChangeValueForKey:keyPath];
		[self didChangeValueForKey:keyPath];
	}
}


-(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath;
{
	NSString* key, *remainingKeyPath;
	[keyPath _KVC_partBeforeDot:&key afterDot:&remainingKeyPath];

	// now remove own observer
	NSMutableDictionary* observationInfo=[self observationInfo];
	NSMutableArray *observers=[observationInfo objectForKey:key];

	NSEnumerator *en=[observers objectEnumerator];
	_NSObservationInfo *info;
	while((info=[en nextObject]))
	{
		if(info->observer==observer)
		{
			[[info retain] autorelease];
			[observers removeObject:info];
			if(![observers count])
			{
				[observationInfo removeObjectForKey:key];
			}
			if(![observationInfo count])
			{
				[self setObservationInfo:nil];
            [observationInfo release];
			}

			if(remainingKeyPath)
				[[self valueForKey:key] removeObserver:info forKeyPath:remainingKeyPath];
			
			NSSet* keysPathsForKey=[isa keyPathsForValuesAffectingValueForKey:key];
			for(NSString *path in keysPathsForKey)
			{
				[self removeObserver:info
					   forKeyPath:path];
			}
			
			return;
		}
	}
	// 10.4 Apple implementation will crash at this point...
	[NSException raise:@"NSKVOException" format:@"trying to remove observer %@ for unobserved key path %@", observer, keyPath];
}

-(void)willChangeValueForKey:(NSString*)key
{
	NSMutableDictionary *dict=[NSMutableDictionary new];
	[dict setObject:[NSNumber numberWithInt:NSKeyValueChangeSetting] 
			 forKey:NSKeyValueChangeKindKey];
	[self _willChangeValueForKey:key changeOptions:dict];
	[dict release];
}

-(void)didChangeValueForKey:(NSString*)key
{
	[self _didChangeValueForKey:key changeOptions:nil];
}

- (void)willChange:(NSKeyValueChange)change valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
	NSMutableDictionary *dict=[NSMutableDictionary new];
	[dict setObject:[NSNumber numberWithInt:change]
			 forKey:NSKeyValueChangeKindKey];
	[dict setObject:indexes
			 forKey:NSKeyValueChangeIndexesKey];
	[self _willChangeValueForKey:key changeOptions:dict];
	[dict release];
}

- (void)didChange:(NSKeyValueChange)change valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
	[self _didChangeValueForKey:key changeOptions:nil];
}


#pragma mark Observer notification

-(void)_willChangeValueForKey:(NSString*)key changeOptions:(NSDictionary*)changeOptions
{
	NSMutableDictionary* observationInfo=[self observationInfo];
	
	if(!observationInfo)
		return;

	NSMutableArray *observers=[observationInfo objectForKey:key];
	
	NSEnumerator *en=[observers objectEnumerator];
	_NSObservationInfo *info;
	// for all observers
	while((info=[en nextObject]))
	{
		// increment change count for nested did/willChangeValue's
		info->willChangeCount++;
		if(info->willChangeCount>1)
			continue;
		NSString* keyPath=info->keyPath;
		
		if(![info changeDictionary])
		{
			id cd=[changeOptions mutableCopy];
			[info setChangeDictionary:cd];
			[cd release];
		}

		// store old value if applicable
		if(info->options & NSKeyValueObservingOptionOld)
		{
			id idxs=[info->changeDictionary objectForKey:NSKeyValueChangeIndexesKey];

			if(idxs)
			{
				int type=[[info->changeDictionary objectForKey:NSKeyValueChangeKindKey] intValue];
				// for to-many relationships, oldvalue is only sensible for replace and remove
				if(type == NSKeyValueChangeReplacement ||
				   type == NSKeyValueChangeRemoval)
					[info->changeDictionary setValue:[[self mutableArrayValueForKeyPath:keyPath] objectsAtIndexes:idxs] forKey:NSKeyValueChangeOldKey];
			}
			else	
			{
				[info->changeDictionary setValue:[self valueForKeyPath:keyPath] forKey:NSKeyValueChangeOldKey];
			}
		}
		
		// inform observer of change
		if(info->options & NSKeyValueObservingOptionPrior)
		{
			[info->changeDictionary setObject:[NSNumber numberWithBool:YES] 
			 forKey:NSKeyValueChangeNotificationIsPriorKey];
			[info->observer observeValueForKeyPath:info->keyPath
			 ofObject:self 
			 change:info->changeDictionary
			 context:info->context];
			[info->changeDictionary removeObjectForKey:NSKeyValueChangeNotificationIsPriorKey];
		}

		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];

		// remove deeper levels (those items will change)
		if(rest)
			[[self valueForKey:firstPart] removeObserver:info forKeyPath:rest];
	}
}

-(void)_didChangeValueForKey:(NSString*)key changeOptions:(NSDictionary*)ignored
{
	NSMutableDictionary* observationInfo=[self observationInfo];

	if(!observationInfo)
		return;

	NSMutableArray *observers=[[observationInfo objectForKey:key] copy];

	NSEnumerator *en=[observers objectEnumerator];
	_NSObservationInfo *info;
	// for all observers
	while((info=[en nextObject]))
	{
		// decrement count and only notify after last didChange
		info->willChangeCount--;
		if(info->willChangeCount>0)
			continue;
		NSString* keyPath=info->keyPath;

		// store new value if applicable
		if(info->options & NSKeyValueObservingOptionNew)
		{
			id idxs=[info->changeDictionary objectForKey:NSKeyValueChangeIndexesKey];			
			if(idxs)
			{
				int type=[[info->changeDictionary objectForKey:NSKeyValueChangeKindKey] intValue];
				// for to-many relationships, newvalue is only sensible for replace and insert

				if(type == NSKeyValueChangeReplacement ||
				   type == NSKeyValueChangeInsertion)
					[info->changeDictionary setValue:[[self mutableArrayValueForKeyPath:keyPath] objectsAtIndexes:idxs] forKey:NSKeyValueChangeNewKey];
			}
			else	
			{
				[info->changeDictionary setValue:[self valueForKeyPath:keyPath] forKey:NSKeyValueChangeNewKey];
			}
		}

		// restore deeper observers if applicable
		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];

		if(rest)
		{
			[[self valueForKey:firstPart]
			addObserver:info
				forKeyPath:rest
				   options:info->options
				   context:info->context];
		}

		// inform observer of change
		[info->observer observeValueForKeyPath:info->keyPath
									  ofObject:self 
										change:info->changeDictionary
									   context:info->context];
		
		[info setChangeDictionary:nil];
	}
	[observers release];
}

+(void)setKeys:(NSArray *)keys triggerChangeNotificationsForDependentKey:(NSString *)dependentKey
{
	NSMutableDictionary* observationInfo=[self observationInfo];
	if(!observationInfo)
	{
		[self setObservationInfo:[NSMutableDictionary new]];
		observationInfo=[self observationInfo];
	}
	
	NSMutableDictionary *dependencies=[observationInfo objectForKey:_KVO_DependentKeysTriggeringChangeNotification];
	if(!dependencies)
	{
		dependencies=[NSMutableDictionary dictionary];
		[observationInfo setObject:dependencies
				 forKey:_KVO_DependentKeysTriggeringChangeNotification];
	}

	id key;
	id en=[keys objectEnumerator];
	while((key = [en nextObject]))
	{
		NSMutableSet* allDependencies=[dependencies objectForKey:key];
		if(!allDependencies)
		{
			allDependencies=[NSMutableSet new];
			[dependencies setObject:allDependencies 
						   forKey:key];
			[allDependencies release];
		}
		[allDependencies addObject:dependentKey];
	}
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSString *methodName=[[NSString alloc] initWithFormat:@"keyPathsForValuesAffecting%@", [key capitalizedString]];
	NSSet* ret=nil;
	SEL sel=NSSelectorFromString(methodName);
	if([self respondsToSelector:sel])
	{
		ret=[self performSelector:sel];		
	}
	else
	{
		[self _KVO_buildDependencyUnion];
		NSMutableDictionary* observationInfo=[self observationInfo];
		NSMutableDictionary *keyPathsByKey=[observationInfo objectForKey:_KVO_KeyPathsForValuesAffectingValueForKey];
		ret=[keyPathsByKey objectForKey:key];
	}
	[methodName release];
	return ret;
}
@end


#pragma mark -
#pragma mark KVO-notifying setters and swizzeling code
/* The following functions define suitable setters and getters which
 call willChangeValueForKey: and didChangeValueForKey: on their superclass
 _KVO_swizzle changes the class of its object to a subclass which overrides
 each setter with a suitable KVO-Notifying one.
*/

// selector for change type
#define CHANGE_SELECTOR(type) KVO_notifying_change_ ## type :

// definition for change type
#define CHANGE_DEFINE(type) -( void ) KVO_notifying_change_ ## type : ( type ) value

// original selector called by swizzled selector
#define ORIGINAL_SELECTOR(name) NSSelectorFromString([NSString stringWithFormat:@"_original_%@", name])

// declaration of change function:
// extracts key from selector called, calls original function
#define CHANGE_DECLARATION(type) CHANGE_DEFINE(type) \
{ \
	const char* origName = sel_getName(_cmd); \
	int selLen=strlen(origName); \
	char *sel=__builtin_alloca(selLen+1); \
	strcpy(sel, origName); \
	sel[selLen-1]='\0'; \
	if(sel[0]=='_') \
		sel+=4; \
	else \
		sel+=3; \
	sel[0]=tolower(sel[0]); \
	NSString *key=[[NSString alloc] initWithCString:sel]; \
	[self willChangeValueForKey:key]; \
	typedef id (*sender)(id obj, SEL selector, type value); \
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd]; \
	(void)*implementation(self, _cmd, value); \
	[self didChangeValueForKey:key]; \
	[key release]; \
}


// FIX: add more types
@interface NSObject (KVOSetters)
CHANGE_DEFINE(float);
CHANGE_DEFINE(double);
CHANGE_DEFINE(id);
CHANGE_DEFINE(int);
CHANGE_DEFINE(NSSize);
CHANGE_DEFINE(NSPoint);
CHANGE_DEFINE(NSRect);
CHANGE_DEFINE(NSRange);
CHANGE_DEFINE(char);
CHANGE_DEFINE(long);
CHANGE_DEFINE(SEL);
@end

@implementation NSObject (KVOSetters)
CHANGE_DECLARATION(float)
CHANGE_DECLARATION(double)
CHANGE_DECLARATION(id)
CHANGE_DECLARATION(int)
CHANGE_DECLARATION(NSSize)
CHANGE_DECLARATION(NSPoint)
CHANGE_DECLARATION(NSRect)
CHANGE_DECLARATION(NSRange)
CHANGE_DECLARATION(char)
CHANGE_DECLARATION(long)
CHANGE_DECLARATION(SEL)

-(void)KVO_notifying_change_setObject:(id)object forKey:(NSString*)key
{
	[self willChangeValueForKey:key];
	typedef id (*sender)(id obj, SEL selector, id object, id key);
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd];
	implementation(self, _cmd, object, key);
	[self didChangeValueForKey:key];
}

-(void)KVO_notifying_change_removeObjectForKey:(NSString*)key
{
	[self willChangeValueForKey:key];
	typedef id (*sender)(id obj, SEL selector, id key);
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd];
	implementation(self, _cmd, key);
	[self didChangeValueForKey:key];
}


-(void)KVO_notifying_change_insertObject:(id)object inKeyAtIndex:(NSInteger)index
{ 
	const char* origName = sel_getName(_cmd); 

	int selLen=strlen(origName); 
	char *sel=__builtin_alloca(selLen+1); 
	strcpy(sel, origName); 
	sel[selLen-1]='\0';
	sel+=strlen("insertObject:in"); 
	sel[strlen(sel)-strlen("AtIndex:")+1]='\0';

	sel[0]=tolower(sel[0]); 

	NSString *key=[[NSString alloc] initWithCString:sel]; 
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	typedef id (*sender)(id obj, SEL selector, id value, int index); 
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd]; 
	(void)*implementation(self, _cmd, object, index); 
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	[key release]; 
}

-(void)KVO_notifying_change_removeObjectFromKeyAtIndex:(int)index
{ 
	const char* origName = sel_getName(_cmd); 
	int selLen=strlen(origName); 
	char *sel=__builtin_alloca(selLen+1); 
	strcpy(sel, origName); 
	sel[selLen-1]='\0';
	sel+=strlen("removeObjectFrom"); 
	sel[strlen(sel)-strlen("AtIndex:")+1]='\0';
	
	sel[0]=tolower(sel[0]); 
	NSString *key=[[NSString alloc] initWithCString:sel]; 
	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	typedef id (*sender)(id obj, SEL selector, int index); 
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd]; 
	(void)*implementation(self, _cmd, index); 
	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	[key release]; 
}

-(void)KVO_notifying_change_replaceObjectInKeyAtIndex:(int)index withObject:(id)object
{ 
	const char* origName = sel_getName(_cmd); 
	int selLen=strlen(origName); 
	char *sel=__builtin_alloca(selLen+1); 
	strcpy(sel, origName); 
	sel[selLen-1]='\0';
	sel+=strlen("replaceObjectIn"); 
	sel[strlen(sel)-strlen("AtIndex:WithObject:")+1]='\0';
	sel[0]=tolower(sel[0]);

	NSString *key=[[NSString alloc] initWithCString:sel]; 
	[self willChange:NSKeyValueChangeReplacement valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	typedef id (*sender)(id obj, SEL selector, int index, id object); 
	sender implementation=(sender)[[self superclass] instanceMethodForSelector:_cmd]; 
	(void)*implementation(self, _cmd, index, object); 
	[self didChange:NSKeyValueChangeReplacement valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:key];
	[key release];
}


-(id)_KVO_className
{
	return [NSString stringWithCString:isa->name+strlen("KVONotifying_")];
}

+(void)_KVO_buildDependencyUnion
{
	/*
	 This method gathers dependent keys from all superclasses and merges them together
	 */
	NSMutableDictionary* observationInfo=[self observationInfo];
	if(!observationInfo)
	{
		[self setObservationInfo:[NSMutableDictionary new]];
		observationInfo=[self observationInfo];
	}

	NSMutableDictionary *keyPathsByKey=[NSMutableDictionary dictionary];

	id class=self;
	while(class != [NSObject class])
	{
		NSDictionary* classDependents=[(NSDictionary*)[class observationInfo] objectForKey:_KVO_DependentKeysTriggeringChangeNotification];

		for(id key in [classDependents allKeys])
		{
			for(id value in [classDependents objectForKey:key])
			{
				NSMutableSet *pathSet=[keyPathsByKey objectForKey:value];
				if(!pathSet)
				{
					pathSet=[NSMutableSet set];
					[keyPathsByKey setObject:pathSet forKey:value];
				}
				[pathSet addObject:key];
			}
		}

		class=[class superclass];
	}
	[observationInfo setObject:keyPathsByKey
						forKey:_KVO_KeyPathsForValuesAffectingValueForKey];
}



-(void)_KVO_swizzle
{
	NSString* className=[self className];
	if([className hasPrefix:@"KVONotifying_"])
		return; // this class is already swizzled
	[kvoLock lock];
	isa=[self _KVO_swizzledClass];
	[kvoLock unlock];
}


-(Class)_KVO_swizzledClass
{
	// find swizzled class
	const char* swizzledName=[[NSString stringWithFormat:@"KVONotifying_%@", [self className]] cString];
	Class swizzledClass = objc_lookUpClass(swizzledName);
	
	if(swizzledClass)
		return swizzledClass;
	
	// swizzled class doesn't exist; create	
	const char *originalName=[[self className] cString];
	if(!CreateClassDefinition(swizzledName, originalName))
		[NSException raise:@"NSClassCreationException" format:@"couldn't swizzle class %@ for KVO", [self className]];

	swizzledClass = objc_lookUpClass(swizzledName);

	// add KVO-Observing methods
	int maxMethods=20;
	struct objc_method *newMethods=calloc(sizeof(struct objc_method), maxMethods);
	int currentMethod=0;

#if 1 // Cocotron
	{
		// override className so it returns the original class name
		struct objc_method *newMethod=&newMethods[currentMethod];
		
		newMethod->method_name=@selector(className);
		newMethod->method_types=@encode(id*(id, SEL));
		newMethod->method_imp=[self methodForSelector:@selector(_KVO_className)];
		
		currentMethod++;
	}
#else // Apple
	if(0)
	{
		// override className so it returns the original class name
		struct objc_method *newMethod=&newMethods[currentMethod];
		
		newMethod->method_name=@selector(className);
		newMethod->method_types=@encode(typeof(objc_msgSend));
		newMethod->method_imp=[self methodForSelector:@selector(_KVO_className)];
		
		currentMethod++;
	}
#endif
	
	void *iterator=0;
	Class currentClass=isa;	
	struct objc_method_list* list = class_nextMethodList(currentClass, &iterator);
	while(list)
	{
		int i;
		for(i=0; i<list->method_count; i++)
		{
			struct objc_method *method=&list->method_list[i];
			NSString* methodName = NSStringFromSelector(method->method_name);
			SEL kvoSelector=nil;
			
			// current method is a setter?
			if(([methodName hasPrefix:@"set"] || [methodName hasPrefix:@"_set"]) &&
			   [[self methodSignatureForSelector:method->method_name] numberOfArguments]==3 &&
			   [[self class] automaticallyNotifiesObserversForKey:[methodName _KVC_setterKeyNameFromSelectorName]])
			{
				const char* firstParameterType=[[self methodSignatureForSelector:method->method_name] getArgumentTypeAtIndex:2];
				const char* returnType=[[self methodSignatureForSelector:method->method_name] methodReturnType];

            char *cleanFirstParameterType=__builtin_alloca(strlen(firstParameterType)+1);
            [self _demangleTypeEncoding:firstParameterType to:cleanFirstParameterType];
            
            
				/* check for correct type: either perfect match
				or primitive signed type matching unsigned type
				(i.e. tolower(@encode(unsigned long)[0])==@encode(long)[0])
				*/
#define CHECK_AND_ASSIGN(a) \
				if(!strcmp(cleanFirstParameterType, @encode(a)) || \
				   (strlen(@encode(a))==1 && \
					strlen(cleanFirstParameterType)==1 && \
					tolower(cleanFirstParameterType[0])==@encode(a)[0])) \
				{ \
					kvoSelector = @selector( CHANGE_SELECTOR(a) ); \
				}
				// FIX: add more types
				CHECK_AND_ASSIGN(id);
				CHECK_AND_ASSIGN(float);
				CHECK_AND_ASSIGN(double);
				CHECK_AND_ASSIGN(int);
				CHECK_AND_ASSIGN(NSSize);
				CHECK_AND_ASSIGN(NSPoint);
				CHECK_AND_ASSIGN(NSRect);
				CHECK_AND_ASSIGN(NSRange);
				CHECK_AND_ASSIGN(char);
				CHECK_AND_ASSIGN(long);
				CHECK_AND_ASSIGN(SEL);
				
            if(kvoSelector==0 && NSDebugEnabled)
				{
					NSLog(@"type %s not defined in %s:%i (selector %s on class %@)", cleanFirstParameterType, __FILE__, __LINE__, SELNAME(method->method_name), [self className]);
				}
				if(returnType[0]!=_C_VOID)
				{
					if(NSDebugEnabled)
						NSLog(@"selector %s on class %@ has return type %s and will not be modified for automatic KVO notification", SELNAME(method->method_name), [self className], returnType);
					kvoSelector=0;
				}
            

			}
         

         
			// long selectors
			if(kvoSelector==0)
			{
				id ret=nil;
			
				if([methodName _KVC_setterKeyName:&ret forSelectorNameStartingWith:@"insertObject:in" endingWith:@"AtIndex:"] &&
				   ret &&
				   [[self methodSignatureForSelector:method->method_name] numberOfArguments] == 4)
				{
					kvoSelector = @selector(KVO_notifying_change_insertObject:inKeyAtIndex:);
				}
				else if([methodName _KVC_setterKeyName:&ret forSelectorNameStartingWith:@"removeObjectFrom" endingWith:@"AtIndex:"] &&
						ret &&
						[[self methodSignatureForSelector:method->method_name] numberOfArguments] == 3)
				{
					kvoSelector = @selector(KVO_notifying_change_removeObjectFromKeyAtIndex:);
				}
				else if([methodName _KVC_setterKeyName:&ret forSelectorNameStartingWith:@"replaceObjectIn" endingWith:@"AtIndex:withObject:"] &&
						ret &&
						[[self methodSignatureForSelector:method->method_name] numberOfArguments] == 4)
				{
					kvoSelector = @selector(KVO_notifying_change_replaceObjectInKeyAtIndex:withObject:);
				}
			}
			
			// these are swizzled so e.g. subclasses of NSMutableDictionary get change notifications in setObject:forKey:
			if([methodName isEqualToString:@"setObject:forKey:"])
			{
				kvoSelector = @selector(KVO_notifying_change_setObject:forKey:);
			}
			if([methodName isEqualToString:@"removeObjectForKey:"])
			{
				kvoSelector = @selector(KVO_notifying_change_removeObjectForKey:forKey:);
			}

			// there's a suitable selector for us
			if(kvoSelector!=0)
			{
				// if we already added too many methods, increase the size of the method list array
				if(currentMethod>=maxMethods)
				{
					maxMethods*=2;
					newMethods=realloc(newMethods, maxMethods*sizeof(struct objc_method));
				}
				struct objc_method *newMethod=&newMethods[currentMethod];

				// fill in the new method: 
				// same name as the method in the superclass
				newMethod->method_name=method->method_name;
				// takes the same types
				newMethod->method_types=strdup(method->method_types);
				// and its implementation is the respective setter
				newMethod->method_imp=[self methodForSelector:kvoSelector];

				currentMethod++;
				
				//NSLog(@"replaced method %@ by %@ in class %@", methodName, NSStringFromSelector(newMethod->method_name), [self className]);
			}
		}
		list=class_nextMethodList(currentClass, &iterator);
		if(!list)
		{
			currentClass=currentClass->super_class;
			iterator=0;
			if(currentClass && currentClass->super_class!=currentClass)
				list=class_nextMethodList(currentClass, &iterator);
		}
	}
#undef CHECK_AND_ASSIGN

	// crop the method array to currently used size
	list = calloc(sizeof(struct objc_method_list)+currentMethod*sizeof(struct objc_method), 1);
	list->method_count=currentMethod;
	memcpy(list->method_list, newMethods, sizeof(struct objc_method)*currentMethod);
	
	// add methods
	class_addMethods(swizzledClass, list);

	free(newMethods);

	// done
	return swizzledClass;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key;
{
	return YES;
}
@end

#pragma mark -
#pragma mark Observation info structure


@implementation _NSObservationInfo
- (NSString*)keyPath {
    return [[keyPath retain] autorelease];
}

- (void)setKeyPath:(NSString*)value {
    if (keyPath != value) {
        [keyPath release];
        keyPath = [value copy];
    }
}



- (id)changeDictionary 
{
    return [[changeDictionary retain] autorelease];
}

- (void)setChangeDictionary:(id)value 
{
    if (changeDictionary != value) 
	{
        [changeDictionary release];
        changeDictionary = [value retain];
    }
}

-(id)observer
{
	return observer;
}

-(void)dealloc
{
	[keyPath release];
	[changeDictionary release];
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)subKeyPath ofObject:(id)subObject change:(NSDictionary*)changeDict context:(void*)subContext;
{
	[observer observeValueForKeyPath:keyPath
							ofObject:object
							  change:changeDict
							 context:context];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p (%@ -> %@)>", [self className], self, keyPath, observer];
}
@end

BOOL CreateClassDefinition( const char * name, 
							const char * superclassName )
{
    struct objc_class * meta_class;
    struct objc_class * super_class;
    struct objc_class * new_class;
    struct objc_class * root_class;
	
    // Ensure that the superclass exists and that someone
    // hasn't already implemented a class with the same name
    //
    super_class = (struct objc_class *)objc_lookUpClass (superclassName);
    if (super_class == nil)
    {
        return NO;
    }
	
    if (objc_lookUpClass (name) != nil) 
    {
        return NO;
    }
	
    // Find the root class
    //
    root_class = super_class;
    while( root_class->super_class != nil )
    {
        root_class = root_class->super_class;
    }
	
    // Allocate space for the class and its metaclass
    //
    new_class = calloc( 2, sizeof(struct objc_class) );
    meta_class = &new_class[1];
	
    // setup class
    new_class->isa      = meta_class;
    new_class->info     = CLS_CLASS;
    meta_class->info    = CLS_META;
	
    // Create a copy of the class name.
    // For efficiency, we have the metaclass and the class itself 
    // to share this copy of the name, but this is not a requirement
    // imposed by the runtime.
    //
    new_class->name = malloc (strlen (name) + 1);
    strcpy ((char*)new_class->name, name);
    meta_class->name = new_class->name;
	
    // Allocate empty method lists.
    // We can add methods later.
    //
#if 1 // Cocotron
    new_class->methodLists = calloc( 1, sizeof(struct objc_method_list  *) );
    new_class->methodLists->method_count = -1;
    meta_class->methodLists = calloc( 1, sizeof(struct objc_method_list  *) );
    meta_class->methodLists->method_count = -1;
#else // Apple
    new_class->methodLists = calloc( 1, sizeof(struct objc_method_list  *) );
    *new_class->methodLists = -1;
    meta_class->methodLists = calloc( 1, sizeof(struct objc_method_list  *) );
    *meta_class->methodLists = -1;
#endif
    // Connect the class definition to the class hierarchy:
    // Connect the class to the superclass.
    // Connect the metaclass to the metaclass of the superclass.
    // Connect the metaclass of the metaclass to the metaclass of  the root class.
    //
    new_class->super_class  = super_class;
    meta_class->super_class = super_class->isa;
    meta_class->isa         = (void *)root_class->isa;
	
    // Set the sizes of the class and the metaclass.
    //
    new_class->instance_size = super_class->instance_size;
    meta_class->instance_size = meta_class->super_class->instance_size;
	
    // Finally, register the class with the runtime.
    //
    objc_addClass( new_class ); 
    return YES;
}
