/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSDisplay.h>

NSString *NSColorPboardType=@"NSColorPboardType";
NSString *NSFileContentsPboardType=@"NSFileContentsPboardType";
NSString *NSFilenamesPboardType=@"NSFilenamesPboardType";
NSString *NSFontPboardType=@"NSFontPboardType";
NSString *NSPDFPboardType=@"NSPDFPboardType";
NSString *NSPICTPboardType=@"NSPICTPboardType";
NSString *NSPostScriptPboardType=@"NSPostScriptPboardType";
NSString *NSRTFDPboardType=@"NSRTFDPboardType";
NSString *NSRTFPboardType=@"NSRTFPboardType";
NSString *NSRulerPboardType=@"NSRulerPboardType";
NSString *NSStringPboardType=@"NSStringPboardType";
NSString *NSTabularTextPboardType=@"NSTabularTextPboardType";
NSString *NSTIFFPboardType=@"NSTIFFPboardType";
NSString *NSURLPboardType=@"NSURLPboardType";

NSString *NSDragPboard=@"NSDragPboard";
NSString *NSFindPboard=@"NSFindPboard";
NSString *NSFontPboard=@"NSFontPboard";
NSString *NSGeneralPboard=@"NSGeneralPboard";
NSString *NSRulerPboard=@"NSRulerPboard";

@implementation NSPasteboard

+(NSPasteboard *)generalPasteboard {
   return [self pasteboardWithName:NSGeneralPboard];
}

+(NSPasteboard *)pasteboardWithName:(NSString *)name {
   return [[NSDisplay currentDisplay] pasteboardWithName:name];
}

-(int)changeCount {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)types {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)availableTypeFromArray:(NSArray *)types {
   NSArray *available=[self types];
   int      i,count=[types count];

   for(i=0;i<count;i++){
    NSString *check=[types objectAtIndex:i];

    if([available containsObject:check])
     return check;
   }

   return nil;
}


-(NSData *)dataForType:(NSString *)type {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)stringForType:(NSString *)type {
   NSData *data=[self dataForType:type];

   return [[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
}

-(id)propertyListForType:(NSString *)type {
   NSUnimplementedMethod();
   return nil;
}

-(int)declareTypes:(NSArray *)types owner:(id)owner {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)setData:(NSData *)data forType:(NSString *)type {
   NSUnimplementedMethod();
   return NO;
}

-(BOOL)setString:(NSString *)string forType:(NSString *)type {
   NSData *data=[string dataUsingEncoding:NSUnicodeStringEncoding];
   return [self setData:data forType:type];
}

-(BOOL)setPropertyList:(id)plist forType:(NSString *)type {
   NSUnimplementedMethod();
   return NO;
}

@end
