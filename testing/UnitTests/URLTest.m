//
//  URLTest.m
//  NSURLTests
//
//  Created by Sven Weidauer on 07.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "URLTest.h"

@implementation URLTest

- (void) setUp;
{
	baseUrl = [[NSURL URLWithString: @"http://a/b/c/d;p?q#f"] retain];
}

- (void) tearDown;
{
	[baseUrl release];
	baseUrl = nil;
}

- (void) testParsing;
{
	NSURL *url = [NSURL URLWithString: @"http://us:pw@a:42/b/c/d;p?q#f"];
	STAssertEqualObjects( [url scheme], @"http", nil );
	STAssertEqualObjects( [url host], @"a", nil );
	STAssertEqualObjects( [url path], @"/b/c/d", nil );
	STAssertEqualObjects( [url query], @"q", nil );
	STAssertEqualObjects( [url fragment], @"f", nil );
	STAssertEqualObjects( [url parameterString], @"p", nil );
	STAssertEqualObjects( [url user], @"us", nil );
	STAssertEqualObjects( [url password], @"pw", nil );
	STAssertEquals( [[url port] intValue], 42, nil );
}

#define TEST_URL( rel, abs ) do { NSURL *relative = [NSURL URLWithString: rel relativeToURL: baseUrl]; STAssertEqualObjects( [relative absoluteString], abs, @"URL %@ relative to %@ should resolve to %@", rel, baseUrl, abs ); } while(0)

- (void) testSimpleRelative;
{	
	TEST_URL( @"g:h", @"g:h" );
	TEST_URL( @"g", @"http://a/b/c/g" );
	TEST_URL( @"./g", @"http://a/b/c/g" );
	TEST_URL( @"g/", @"http://a/b/c/g/" );
	TEST_URL( @"/g", @"http://a/g" );
	TEST_URL( @"//g", @"http://g" );
	TEST_URL( @"?y", @"http://a/b/c/d;p?y" );
	TEST_URL( @"g?y", @"http://a/b/c/g?y" );
	TEST_URL( @"g?y/./x", @"http://a/b/c/g?y/./x" );
	TEST_URL( @"#s", @"http://a/b/c/d;p?q#s" );
	TEST_URL( @"g#s/./x", @"http://a/b/c/g#s/./x" );
	TEST_URL( @"g?y#s", @"http://a/b/c/g?y#s" );
	TEST_URL( @";x", @"http://a/b/c/d;x" );
	TEST_URL( @"g;x", @"http://a/b/c/g;x" );
	TEST_URL( @"g;x?y#s", @"http://a/b/c/g;x?y#s" );
	TEST_URL( @".", @"http://a/b/c/" );
	TEST_URL( @"./", @"http://a/b/c/" );
	TEST_URL( @"..", @"http://a/b/" );
	TEST_URL( @"../", @"http://a/b/" );
	TEST_URL( @"../g", @"http://a/b/g" );
	TEST_URL( @"../..", @"http://a/" );
	TEST_URL( @"../../", @"http://a/" );
	TEST_URL( @"../../g", @"http://a/g" );
}

- (void) testAbnormalRelative;
{
	TEST_URL( @"", @"http://a/b/c/d;p?q#f" );
	TEST_URL( @"../../../g", @"http://a/../g" );
	TEST_URL( @"../../../../g", @"http://a/../../g" );
	TEST_URL( @"/./g", @"http://a/./g" );
	TEST_URL( @"/../g", @"http://a/../g" );
	TEST_URL( @"g.", @"http://a/b/c/g." );
	TEST_URL( @".g", @"http://a/b/c/.g" );
	TEST_URL( @"g..", @"http://a/b/c/g.." );
	TEST_URL( @"..g", @"http://a/b/c/..g" );
	TEST_URL( @"./../g", @"http://a/b/g" );
	TEST_URL( @"./g/.", @"http://a/b/c/g/" );
	TEST_URL( @"g/./h", @"http://a/b/c/g/h" );
	TEST_URL( @"g/../h", @"http://a/b/c/h" );
	TEST_URL( @"http:g", @"http:g" );
	TEST_URL( @"http:", @"http:" );	
}

@end
