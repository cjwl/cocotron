/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSURL.h>
#import <Foundation/NSRaise.h>

@implementation NSURL

-initWithScheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path {
   NSUnimplementedMethod();
   return nil;
}

-initFileURLWithPath:(NSString *)path {
   _scheme=@"file";
   _path=[path copy];
   return self;
}

-initWithString:(NSString *)string {
   NSUnimplementedMethod();
   return nil;
}

-initWithString:(NSString *)string relativeToURL:(NSURL *)parent {
   NSUnimplementedMethod();
   return nil;
}

+fileURLWithPath:(NSString *)path {
   return [[[self alloc] initFileURLWithPath:path] autorelease];
}

+URLWithString:(NSString *)string {
   return [[[self alloc] initWithString:string] autorelease];
}

+URLWithString:(NSString *)string relativeToURL:(NSURL *)parent {
   return [[[self alloc] initWithString:string relativeToURL:parent] autorelease];
}

-(void)dealloc {
   [_scheme release];
   [_path release];
   [super dealloc];
}

-(BOOL)isEqual:other {
   NSURL *otherURL;
   
   if(![other isKindOfClass:[NSURL class]])
    return NO;
    
   otherURL=other;
   if(![otherURL->_scheme isEqual:_scheme])
    return NO;
    
   if(![otherURL->_path isEqual:_path])
    return NO;
    
   return YES;
}

-(NSString *)absoluteString {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)parameterString {
   NSUnimplementedMethod();
   return nil;
}

-propertyForKey:(NSString *)key {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)scheme {
   return _scheme;
}

-(NSString *)host {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)user {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)password {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)fragment {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)path {
   return _path;
}

-(NSNumber *)port {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)query {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)relativePath {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)relativeString {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)resourceSpecifier {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)isFileURL {
   return [_scheme isEqualToString:@"file"];
}

-(NSURL *)standardizedURL {
   NSUnimplementedMethod();
   return nil;
}

-(NSURL *)absoluteURL {
   NSUnimplementedMethod();
   return nil;
}

-(NSURL *)baseURL {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)setProperty:property forKey:(NSString *)key {
   NSUnimplementedMethod();
   return NO;
}

-(BOOL)setResourceData:(NSData *)data {
   NSUnimplementedMethod();
   return NO;
}

-(NSData *)resourceDataUsingCache:(BOOL)useCache {
   NSUnimplementedMethod();
   return nil;
}

-(NSURLHandle *)URLHandleUsingCache:(BOOL)useCache {
   NSUnimplementedMethod();
   return nil;
}

-(void)laodResourceDataNotifyingClient:client usingCache:(BOOL)useCache {
   NSUnimplementedMethod();
}


@end
