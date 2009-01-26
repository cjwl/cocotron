/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <AppKit/AppKitExport.h>

@class NSDictionary,NSAffineTransform,NSArray,NSSet;

APPKIT_EXPORT NSString *NSFontNameAttribute;
APPKIT_EXPORT NSString *NSFontFamilyAttribute;
APPKIT_EXPORT NSString *NSFontSizeAttribute;
APPKIT_EXPORT NSString *NSFontMatrixAttribute;
APPKIT_EXPORT NSString *NSFontCharacterSetAttribute;
APPKIT_EXPORT NSString *NSFontTraitsAttribute;
APPKIT_EXPORT NSString *NSFontFaceAttribute;
APPKIT_EXPORT NSString *NSFontFixedAdvanceAttribute;
APPKIT_EXPORT NSString *NSFontVisibleNameAttribute;

typedef unsigned NSFontSymbolicTraits;

@interface NSFontDescriptor : NSObject <NSCopying> {
   NSDictionary *_attributes;
}

-initWithFontAttributes:(NSDictionary *)attributes;

+fontDescriptorWithFontAttributes:(NSDictionary *)attributes;
+fontDescriptorWithName:(NSString *)name matrix:(NSAffineTransform *)matrix;
+fontDescriptorWithName:(NSString *)name size:(float)pointSize;

-(NSDictionary *)fontAttributes;

-objectForKey:(NSString *)attributeKey;

-(float)pointSize;
-(NSAffineTransform *)matrix;
-(NSFontSymbolicTraits)symbolicTraits;

-(NSFontDescriptor *)fontDescriptorByAddingAttributes:(NSDictionary *)attributes;
-(NSFontDescriptor *)fontDescriptorWithFace:(NSString *)face;
-(NSFontDescriptor *)fontDescriptorWithFamily:(NSString *)family;
-(NSFontDescriptor *)fontDescriptorWithMatrix:(NSAffineTransform *)matrix;
-(NSFontDescriptor *)fontDescriptorWithSize:(float)pointSize;
-(NSFontDescriptor *)fontDescriptorWithSymbolicTraits:(NSFontSymbolicTraits)traits;

-(NSArray *)matchingFontDescriptorsWithMandatoryKeys:(NSSet *)keys;
-(NSFontDescriptor *)matchingFontDescriptorWithMandatoryKeys:(NSSet *)keys;

@end
