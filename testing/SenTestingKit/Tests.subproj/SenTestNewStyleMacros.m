// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// (1) Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// 
// (2) Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation 
// and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Note: this license is equivalent to the FreeBSD license.
// 
// This notice may not be removed from this file.

#import "SenTestNewstyleMacros.h"
#import <SenTestingKit/SenTestingKit.h>

@interface TestFooException : NSException
+ quickThrow;
@end
@implementation TestFooException
+ quickThrow
{
    @throw [[TestFooException alloc] initWithName: @"Test Foo Exception Name"
                                           reason: @"Quick Foo"
                                         userInfo: nil];
}
@end
@interface TestBarException : NSException
+ quickThrow;
@end
@implementation TestBarException
+ quickThrow
{
    @throw [[TestBarException alloc] initWithName: @"Test Bar Exception Name"
                                           reason: @"Quick Bar"
                                         userInfo: nil];
}
@end

#define TestSuccessfulFailure(_testExpr, specificExceptionName, msg, ...) \
do {\
    SEL originalFailureAction = [self failureAction];\
	NSString *failureMessage = STComposeString((msg), #__VA_ARGS__);\
	@try {\
		[self setFailureAction: @selector(raiseException:)];\
		@try {\
			failureMessage = @"Sometimes, to fail is to succeed.";\
				_testExpr;\
			@throw [NSException failureInFile: [NSString stringWithCString: __FILE__]\
									   atLine: __LINE__\
							  withDescription: STComposeString(@"%s failed to fail.", #_testExpr)];\
		}\
		@catch (NSException *exc) {\
			if ((specificExceptionName) && ( ![[exc name] isEqualToString:(specificExceptionName)] ))\
				@throw exc; \
			if ([[exc reason] rangeOfString: failureMessage].location == NSNotFound )\
				@throw exc;\
		}\
	}\
	@catch (id anException) {\
		[self setFailureAction:originalFailureAction];\
		[self failWithException:anException];\
	}\
	@finally {\
		[self setFailureAction:originalFailureAction];\
	}\
} while(0)


@implementation SenTestNewstyleMacros
- (void) testSTComposeString
{
    if (![STComposeString(nil) isEqualToString: @""])
        [self failWithException:[NSException failureInFile: [NSString stringWithCString: __FILE__] 
                                                    atLine: __LINE__ 
                                           withDescription: @"nil test failed."]];
    if (![STComposeString(@"Basic description") isEqualToString: @"Basic description"])
        [self failWithException:[NSException failureInFile: [NSString stringWithCString: __FILE__] 
                                                    atLine: __LINE__ 
                                           withDescription: @"no arg test failed."]];
    if (![STComposeString(@"Description with %d arg.", 1) isEqualToString: @"Description with 1 arg."])
        [self failWithException:[NSException failureInFile: [NSString stringWithCString: __FILE__] 
                                                    atLine: __LINE__ 
                                           withDescription: @"one arg test failed."]];
    
    if (![STComposeString(@"Description with %d %@", 2, @"args.") isEqualToString: @"Description with 2 args."])
        [self failWithException:[NSException failureInFile: [NSString stringWithCString: __FILE__] 
                                                    atLine: __LINE__ 
                                           withDescription: @"two arg test failed."]];
}

- (void) testEqualObjects
{
    STAssertNotNil(@"foo", @"foo is not nil.");
    STAssertEqualObjects(@"foo", @"foo", @"Basic objects are equal.");
    STAssertEqualObjects(nil, nil, @"nil == nil test.");
    
    TestSuccessfulFailure(STAssertEqualObjects(@"foo", nil, failureMessage),
                          SenTestFailureException,
                          @"(obj == nil) should fail.");
	TestSuccessfulFailure(STAssertEqualObjects(self, [NSBundle mainBundle], failureMessage),
                          SenTestFailureException,
                          @"random objects aren't equal.");
    
    STAssertEqualObjects(NSClassFromString(@"NSArray"), [NSArray class], @"random objects aren't equal.");
}

- (void) testEquals
{
    int a = 2;
    
    STAssertEquals (0, 0, @"Basic integer equals.");
    STAssertEquals (a + 1 + 1, a + a, @"Expression equality.");

	TestSuccessfulFailure (STAssertEquals ([[[NSObject alloc] init] autorelease], [[[NSObject alloc] init] autorelease], failureMessage),
						   SenTestFailureException,
						   nil);

    TestSuccessfulFailure (STAssertEquals (NO, YES, failureMessage),
						   SenTestFailureException,
						   @"Fail with Not Equal.");
}

- (void) testEqualRanges
{
	STAssertEquals (NSMakeRange (1, 100), NSMakeRange (1, 100), nil);
	TestSuccessfulFailure (STAssertEquals (NSMakeRange (1, 100), 0, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualStructs
{
	struct {
		int a;
		float b;
	} x, y;
	
	x.a = 0;
	x.b = 3.14;
	
	y.a = 1;
	y.b = 3.14;

	STAssertEquals (x, x, nil);
	TestSuccessfulFailure (STAssertEquals (x, y, failureMessage), SenTestFailureException, nil);
}


- (void) testEqualUnions
{
	union {
		long a;
		float b;
	} x, y;
	
	x.a = 0;
	y.b = 3.14;
	
	STAssertEquals (x, x, nil);
	STAssertEquals (y, y, nil);
	TestSuccessfulFailure (STAssertEquals (x, 0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEquals (x, y, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualRects
{
	NSRect r1 = NSMakeRect (0, 0, 0, 0);
	NSRect r2 = NSMakeRect (0, 0, 1, 1);
	
	STAssertEquals (r1, NSMakeRect (0, 0, 0, 0), nil);
	TestSuccessfulFailure (STAssertEquals (r1, r2, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualPoints
{
	NSPoint p1 = NSMakePoint (0, 0);
	NSPoint p2 = NSMakePoint (1, 1);
	NSSize s1 = NSMakeSize (0, 0);
	
	STAssertEquals (p1, NSMakePoint (0, 0), nil);
	TestSuccessfulFailure (STAssertEquals (p1, p2, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEquals (p1, s1, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualSizes
{
	NSSize s1 = NSMakeSize (0, 0);
	NSSize s2 = NSMakeSize (1, 1);
	NSPoint p1 = NSMakePoint (0, 0);

	STAssertEquals (s1, NSMakeSize (0, 0), nil);
	TestSuccessfulFailure (STAssertEquals (s1, s2, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEquals (s1, p1, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualPointers
{
	int x = 0;
	int y = 1;
	STAssertEquals (&x, &x, @"");
	TestSuccessfulFailure (STAssertEquals (&x, &y, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualScalarsTypeChecking
{
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned int) -1, (int) -1, 0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned int) 0, (int) 0, 0, failureMessage), SenTestFailureException, nil);	
	
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long long) 0, (long) 0, 0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long long) 0, (int) 0, 0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long long) 0, (float) 0, 0, failureMessage), SenTestFailureException, nil);
	
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long long) 0, (float) 0.5, 1.0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned char) -1, (int) 255, 0, failureMessage), SenTestFailureException, nil);
	
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned char) -1, -1, 0, failureMessage), SenTestFailureException, nil);
	
	TestSuccessfulFailure (STAssertEqualsWithAccuracy (0.0f, 0.0, 0.0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((float)0.0, (double)0.0, 0.0, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualCharsWithAccuracy
{
	STAssertEqualsWithAccuracy ((unsigned char) 0, (unsigned char) 0, 0, nil);
	STAssertEqualsWithAccuracy ((unsigned char) 0, (unsigned char) 1, 1, nil);
	STAssertEqualsWithAccuracy ((unsigned char) -1, (unsigned char) -1, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned char) 0, (unsigned char) 1, 0, failureMessage), SenTestFailureException, nil);
	
	STAssertEqualsWithAccuracy ((char) 0, (char) 0, 0, nil);
	STAssertEqualsWithAccuracy ('a', 'a', 0, nil);
	STAssertEqualsWithAccuracy ('a', 'b', 1, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((char) 0, (char) 1, 0, failureMessage), SenTestFailureException, nil);
}


- (void) testEqualIntegersWithAccuracy
{
	STAssertEqualsWithAccuracy ((short) 0, (short) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((short) 0, (short) 1, 0, failureMessage), SenTestFailureException, nil);	
	STAssertEqualsWithAccuracy ((unsigned short) 0, (unsigned short) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned short) 0, (unsigned short) 1, 0, failureMessage), SenTestFailureException, nil);
	
	STAssertEqualsWithAccuracy ((int) 0, (int) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((int) 0, (int) 1, 0, failureMessage), SenTestFailureException, nil);
	STAssertEqualsWithAccuracy ((unsigned int) 0, (unsigned int) 0, 0, nil);
	STAssertEqualsWithAccuracy ((unsigned int) -1, (unsigned int) -1, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned int) 0, (unsigned int) 1, 0, failureMessage), SenTestFailureException, nil);
	
	STAssertEqualsWithAccuracy ((long) 0, (long) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long) 0, (long) 1, 0, failureMessage), SenTestFailureException, nil);
	STAssertEqualsWithAccuracy ((unsigned long) 0, (unsigned long) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned long) 0, (unsigned long) 1, 0, failureMessage), SenTestFailureException, nil);
	
	STAssertEqualsWithAccuracy ((long long) 0, (long long) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((long long) 0, (long long) 1, 0, failureMessage), SenTestFailureException, nil);
	STAssertEqualsWithAccuracy ((unsigned long long) 0, (unsigned long long) 0, 0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((unsigned long long) 0, (unsigned long long) 1, 0, failureMessage), SenTestFailureException, nil);
}


- (void) testEqualFloatingWithAccuracy
{
	STAssertEqualsWithAccuracy (1.99, 1.99, 0.0, nil);
	STAssertEqualsWithAccuracy (1.99999999999999999, 2.0, 0.0, nil);
	STAssertEqualsWithAccuracy (1.99, 2.0, 0.1, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy (0.0, 1.0, 0, failureMessage), SenTestFailureException, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy (1.99, 2.0, 0.0, failureMessage), SenTestFailureException, nil);
	
	STAssertEqualsWithAccuracy ((double) 0.0, (double) 0.0, 0.0, nil);
	STAssertEqualsWithAccuracy ((double) 1.99, (double) 1.99, 0.0, nil);
	TestSuccessfulFailure (STAssertEqualsWithAccuracy ((double) 0, (double) 1, 0, failureMessage), SenTestFailureException, nil);
}

- (void) testEqualScalars
{
	char B = 'B';
    unsigned short aShortA = 2;
	
	STAssertEquals (aShortA, (unsigned short) 2, @"Basic shorts equals.");
	STAssertEquals (3L, 3L, @"Basic longs equals.");
	STAssertEquals (4LL, 4LL, @"Basic long longs equals.");
	STAssertEquals ((unsigned long long) 12, 12ULL, @"unsigned long long equals.");
	STAssertEquals (B, (char)'B', @"Basic char equals.");
	STAssertEquals ('a', 'a', @"Basic char not equals.");
	STAssertEquals (20, 20, @"Basic integer equals.");
    STAssertEquals ((float) 21.99, (float) 21.99, @"Basic float equals.");
    STAssertEquals (21.999999999, 21.999999999, @"Basic float equals.");
    TestSuccessfulFailure (STAssertEquals (NO, YES, failureMessage), SenTestFailureException, @"Fail with Not Equal.");
}

- (void) testSTFail
{
    TestSuccessfulFailure(STFail(failureMessage),
                          SenTestFailureException,
                          @"Sometimes, to fail is to succeed.");
}

- (void) testTrueFalse
{
    STAssertTrue (YES, @"Boolean YES is true.");
    STAssertTrue (NO == NO, @"True comparison of truth values.");
    STAssertTrue ("foo" != "bar", @"Handle random pointer.");
    STAssertTrue ([@"foo" isEqualToString: @"foo"], @"Random object expression.");
    STAssertFalse (NO, @"Boolean NO is false.");
    STAssertFalse (YES == NO, @"False comparison of truth values.");
    STAssertFalse ("foo" == "bar", @"Handle random pointer.");
    STAssertFalse ([@"foo" isEqualToString: @"bar"], @"Random object expression.");
	
    TestSuccessfulFailure (STAssertTrue(NO, failureMessage),
                          SenTestFailureException,
                          @"NO should not assert true.");
    TestSuccessfulFailure (STAssertFalse(YES, failureMessage),
                          SenTestFailureException,
                          @"YES should not assert false.");
}

- (void) testThrows
{
    STAssertThrows([TestFooException quickThrow],
                   @"Should throw something.");
    STAssertThrows([NSObject performSelector:@selector(completelyRandomMethodThatDoesNotExist)],
                   @"Should throw not implemented exception.");
    TestSuccessfulFailure(STAssertThrows([NSBundle mainBundle], failureMessage),
                          nil,
                          @"Should have failed because no exception thrown.");
}

- (void) testThrowsSpecific
{
    STAssertThrowsSpecific([TestFooException quickThrow],
                           TestFooException,
                           @"Should specifically throw TestFooExceptionName.");
    TestSuccessfulFailure(STAssertThrowsSpecific([TestFooException quickThrow],
                                                 TestBarException,
                                                 failureMessage),
                          nil,
                          @"Should specifically throw TestBarException, but expecting TestFooException.");
}

- (void) testThrowsSpecificNamed
{
    STAssertThrowsSpecificNamed([TestFooException quickThrow],
								TestFooException, @"Test Foo Exception Name",
								@"Should specifically throw TestFooExceptionName.");
    TestSuccessfulFailure(STAssertThrowsSpecificNamed([TestFooException quickThrow], 
													  TestFooException,
													  @"Test Bar Exception Name",
													  failureMessage),
                          nil,
                          @"Should specifically throw TestFooException named \"Test Foo Exception Name\", but expecting TestFooException named \"Test Bar Exception Name\".");
}

- (void) testNoThrow
{
    STAssertNoThrow([NSBundle mainBundle],
                    @"Should not throw anything."); 
    TestSuccessfulFailure(STAssertNoThrow([TestFooException quickThrow], failureMessage),
                          nil,
                          @"Should have failed by throwing a TestFooException.");
}

- (void) testNoThrowSpecific
{
    STAssertNoThrowSpecific([NSBundle mainBundle],
                            TestFooException,
                            @"Should not throw anything."); 
    STAssertNoThrowSpecific([TestBarException quickThrow],
                            TestFooException,
                            @"Should throw something other than TestBarException, but that is OK.");
    TestSuccessfulFailure(STAssertNoThrowSpecific([TestBarException quickThrow],
                                                  TestBarException,
                                                  failureMessage),
                          nil,
                          @"Should have failed because it tossed a TestBarException.");
}

- (void) testNoThrowSpecificNamed
{
    STAssertNoThrowSpecificNamed([NSBundle mainBundle],
								 TestFooException,
								 @"Test Foo Exception Name",
								 @"Should not throw anything."); 
    STAssertNoThrowSpecificNamed([TestBarException quickThrow],
								 TestFooException,
								 @"Test Foo Exception Name",
								 @"Should throw something other than TestBarException, but that is OK.");
    STAssertNoThrowSpecificNamed([TestFooException quickThrow],
								 TestFooException,
								 @"Test Bar Exception Name",
								 @"Should throw TestFooException but the name \"Test Foo Exception Name\" is not the one expected, but that is OK.");    
    TestSuccessfulFailure(STAssertNoThrowSpecificNamed([TestBarException quickThrow],
													   TestBarException,
													   @"Test Bar Exception Name",
													   failureMessage),
                          nil,
                          @"Should have failed because it tossed a TestBarException with the name \"Test Bar Exception Name\" .");
}
@end
