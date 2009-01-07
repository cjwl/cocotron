/*
Original Author: Michael Ash on 11/9/08.
Copyright (c) 2008 Rogue Amoeba Software LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import "NSOperation.h"
#import <Foundation/NSString.h>
#import <Foundation/NSMethodSignature.h>
#import "NSLatchTrigger.h"


@implementation NSOperation

- (void)run
{
	NSLog( @"NSOperation is an abstract class, implement -[%@ %@]", [self class], NSStringFromSelector( _cmd ) );
	[self doesNotRecognizeSelector: _cmd];
}

@end

@implementation NSSelectorOperation

- (id)initWithTarget: (id)obj selector: (SEL)sel object: (id)arg
{
	if( (self = [super init]) )
	{
		_obj = [obj retain];
		_sel = sel;
		_arg = [arg retain];
	}
	return self;
}

- (void)dealloc
{
	[_obj release];
	[_arg release];
	[_result release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat: @"<%@:%p: %@ %@ %@>", [self class], self, _obj, NSStringFromSelector( _sel ), _arg];
}

- (void)run
{
	NSMethodSignature *sig = [_obj methodSignatureForSelector: _sel];
    IMP                imp=[_obj instanceMethodForSelector:_sel];
    
	if( [sig methodReturnType][0] == '@' )
		_result = [imp( _obj, _sel, _arg ) retain];
	else
		imp( _obj, _sel, _arg );
}

- (id)result
{
	return _result;
}

@end

@implementation NSWaitableSelectorOperation

- (id)initWithTarget: (id)obj selector: (SEL)sel object: (id)arg
{
	if( (self = [super initWithTarget: obj selector: sel object: arg]) )
	{
		_trigger = [[NSLatchTrigger alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_trigger release];
	
	[super dealloc];
}

- (void)run
{
	[super run];
	[_trigger signal];
}

- (void)waitUntilDone
{
	[_trigger wait];
}

@end

