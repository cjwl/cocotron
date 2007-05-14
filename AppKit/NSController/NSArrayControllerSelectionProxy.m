/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSArrayControllerSelectionProxy.h"
#import <AppKit/NSArrayController.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyValueCoding.h>

@implementation NSArrayControllerSelectionProxy
-(id)initWithArrayController:(id)cont
{
	if(self=[super init])
	{
		values=[NSMutableDictionary new];
		controller = [cont retain];
	}
	return self;
}

-(void)dealloc
{
	[values release];
	[controller release];
	[super dealloc];
}

-(id)valueForKey:(id)key
{
	id val=[values objectForKey:key];
	if(val)
		return val;
	id allValues=[[controller selectedObjects] valueForKeyPath:key];
	
	switch([allValues count])
	{
		case 0:
			val=NSNoSelectionMarker;
			break;
		case 1:
			val=[allValues lastObject];
			break;
		default:
		{
			if([controller alwaysUsesMultipleValuesMarker])
			{
				val=NSMultipleValuesMarker;
			}
			else
			{
				val=[allValues objectAtIndex:0];
				id en=[allValues objectEnumerator];
				id obj;
				while((obj=[en nextObject]) && val!=NSMultipleValuesMarker)
				{
					if(![val isEqual:obj])
						val=NSMultipleValuesMarker;
				}
			}
			break;
		}
	}
	
	[values setValue:val forKey:key];
	return val;
}

-(int)count
{
	return [values count];
}

-(id)keyEnumerator
{
	return [values keyEnumerator];
}

-(void)setValue:(id)value forKey:(NSString *)key
{
	[[controller selectedObjects] setValue:value forKey:key];
}

-(id)description
{
	return [NSString stringWithFormat:
		@"%@ <0x%x>",
		[self className],
		self];
}
@end
