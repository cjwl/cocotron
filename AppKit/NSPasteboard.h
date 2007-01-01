/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/AppKitExport.h>

APPKIT_EXPORT NSString *NSColorPboardType;
APPKIT_EXPORT NSString *NSFileContentsPboardType;
APPKIT_EXPORT NSString *NSFilenamesPboardType;
APPKIT_EXPORT NSString *NSFontPboardType;
APPKIT_EXPORT NSString *NSPDFPboardType;
APPKIT_EXPORT NSString *NSPICTPboardType;
APPKIT_EXPORT NSString *NSPostScriptPboardType;
APPKIT_EXPORT NSString *NSRTFDPboardType;
APPKIT_EXPORT NSString *NSRTFPboardType;
APPKIT_EXPORT NSString *NSRulerPboardType;
APPKIT_EXPORT NSString *NSStringPboardType;
APPKIT_EXPORT NSString *NSTabularTextPboardType;
APPKIT_EXPORT NSString *NSTIFFPboardType;
APPKIT_EXPORT NSString *NSURLPboardType;

APPKIT_EXPORT NSString *NSDragPboard;
APPKIT_EXPORT NSString *NSFindPboard;
APPKIT_EXPORT NSString *NSFontPboard;
APPKIT_EXPORT NSString *NSGeneralPboard;
APPKIT_EXPORT NSString *NSRulerPboard;

@interface NSPasteboard : NSObject

+(NSPasteboard *)generalPasteboard;
+(NSPasteboard *)pasteboardWithName:(NSString *)name;

-(int)changeCount;

-(NSArray *)types;
-(NSString *)availableTypeFromArray:(NSArray *)types;

-(NSData *)dataForType:(NSString *)type;
-(NSString *)stringForType:(NSString *)type;
-propertyListForType:(NSString *)type;

-(int)declareTypes:(NSArray *)types owner:owner;

-(BOOL)setData:(NSData *)data forType:(NSString *)type;
-(BOOL)setString:(NSString *)string forType:(NSString *)type;
-(BOOL)setPropertyList:plist forType:(NSString *)type;

@end

@interface NSObject(NSPasteboard)
-(void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
-(void)pasteboardChangedOwner:(NSPasteboard *)sender;
@end
