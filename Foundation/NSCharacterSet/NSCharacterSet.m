/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSCharacterSet_range.h>
#import <Foundation/NSCharacterSet_bitmap.h>
#import <Foundation/NSMutableCharacterSet_bitmap.h>
#import <Foundation/NSCharacterSet_string.h>
#import <Foundation/bitmapRepresentation.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSRaise.h>

@implementation NSCharacterSet

static NSMapTable *nameToSet=NULL;

+(void)initialize {
   if(self==[NSCharacterSet class]){
    nameToSet=NSCreateMapTable(NSObjectMapKeyCallBacks,
      NSObjectMapValueCallBacks,0);
   }
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}


-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableCharacterSet_bitmap allocWithZone:NULL] initWithCharacterSet:self];
}

-(Class)classForCoder {
   NSUnsupportedMethod();
   return Nil;
}

-initWithCoder:(NSCoder *)coder {
   NSUnsupportedMethod();
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnsupportedMethod();
}

+(NSCharacterSet *)characterSetWithBitmapRepresentation:(NSData *)data {
   return NSAutorelease(NSCharacterSet_bitmapNewWithBitmap(NULL,data));
}

+(NSCharacterSet *)characterSetWithCharactersInString:(NSString *)string {
   return NSAutorelease([[NSCharacterSet_string allocWithZone:NULL] initWithString:string inverted:NO]);
}

+(NSCharacterSet *)characterSetWithContentsOfFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];

   if(data==nil)
    return nil;

   return [self characterSetWithBitmapRepresentation:data];
}

+(NSCharacterSet *)characterSetWithRange:(NSRange)range {
   return NSAutorelease([[NSCharacterSet_range allocWithZone:NULL] initWithRange:range]);
}

static NSString *pathForCharacterSet(NSString *name){
   NSBundle *bundle=[NSBundle bundleForClass:[NSCharacterSet class]];
   NSString *path=[bundle pathForResource:name ofType:@"bitmap"];

   if(path==nil)
    [NSException raise:@"NSCharacterSetFailedException"
                format:@"NSCharacterSet unable to find bitmap for %@",name];

   return path;
}

static NSCharacterSet *sharedSetWithName(NSString *name){
   NSCharacterSet *set;

   if((set=NSMapGet(nameToSet,name))==nil){
    NSString *path=pathForCharacterSet(name);

    if((set=[NSCharacterSet characterSetWithContentsOfFile:path])!=nil)
     NSMapInsert(nameToSet,name,set);
   }

   return set;
}

+(NSCharacterSet *)alphanumericCharacterSet {
   return sharedSetWithName(@"alphanumericCharacterSet");
}

+(NSCharacterSet *)controlCharacterSet {
   return sharedSetWithName(@"controlCharacterSet");
}

+(NSCharacterSet *)decimalDigitCharacterSet {
   return sharedSetWithName(@"decimalDigitCharacterSet");
}

+(NSCharacterSet *)decomposableCharacterSet {
   return sharedSetWithName(@"decomposableCharacterSet");
}

+(NSCharacterSet *)illegalCharacterSet {
   return sharedSetWithName(@"illegalCharacterSet");
}

+(NSCharacterSet *)letterCharacterSet {
   return sharedSetWithName(@"letterCharacterSet");
}

+(NSCharacterSet *)lowercaseLetterCharacterSet {
   return sharedSetWithName(@"lowercaseLetterCharacterSet");
}

+(NSCharacterSet *)nonBaseCharacterSet {
   return sharedSetWithName(@"nonBaseCharacterSet");
}

+(NSCharacterSet *)punctuationCharacterSet {
   return sharedSetWithName(@"punctuationCharacterSet");
}

+(NSCharacterSet *)uppercaseLetterCharacterSet {
   return sharedSetWithName(@"uppercaseLetterCharacterSet");
}

+(NSCharacterSet *)whitespaceAndNewlineCharacterSet {
   return sharedSetWithName(@"whitespaceAndNewlineCharacterSet");
}

+(NSCharacterSet *)whitespaceCharacterSet {
   return sharedSetWithName(@"whitespaceCharacterSet");
}


-(BOOL)characterIsMember:(unichar)character {
   NSInvalidAbstractInvocation();
   return NO;
}

-(NSCharacterSet *)invertedSet {
   unsigned char *bitmap=bitmapBytes(self);
   unsigned       i;

   for(i=0;i<NSBitmapCharacterSetSize;i++)
    bitmap[i]=~bitmap[i];

   return NSAutorelease(NSCharacterSet_bitmapNewWithBitmap(NULL,
     [NSData dataWithBytesNoCopy:bitmap length:NSBitmapCharacterSetSize]));
}

-(NSData *)bitmapRepresentation {
   return [NSData dataWithBytesNoCopy:bitmapBytes(self)
                               length:NSBitmapCharacterSetSize];
}

// yea this is terrible
-(BOOL)isSupersetOfSet:(NSCharacterSet *)other {
   unsigned i;
   
   for(i=0;i<=0xFFFF;i++){
    if([other characterIsMember:i] && ![self characterIsMember:i])
     return NO;
   }
   
   return YES;
}

@end
