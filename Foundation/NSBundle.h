/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class NSArray,NSDictionary,NSString;

FOUNDATION_EXPORT NSString *NSBundleDidLoadNotification;
FOUNDATION_EXPORT NSString *NSLoadedClasses;	

@interface NSBundle : NSObject {
   NSString     *_path;
   NSString     *_resourcePath;
   NSDictionary *_infoDictionary;
   BOOL          _isLoaded;
}

+(NSArray *)allBundles;
+(NSArray *)allFrameworks;

+(NSBundle *)mainBundle;

+(NSBundle *)bundleForClass:(Class)aClass;

-initWithPath:(NSString *)path;

+(NSBundle *)bundleWithPath:(NSString *)path;

-(NSString *)bundlePath;
-(NSString *)resourcePath;
-(NSDictionary *)infoDictionary;
-objectForInfoDictionaryKey:(NSString *)key;
-(NSString *)bundleIdentifier;

-(Class)principalClass;
-(Class)classNamed:(NSString *)className;

-(BOOL)load;

-(NSString *)pathForResource:(NSString *)name ofType:(NSString *)type;
-(NSString *)pathForResource:(NSString *)name ofType:(NSString *)type
  inDirectory:(NSString *)path;

-(NSArray *)pathsForResourcesOfType:(NSString *)type
  inDirectory:(NSString *)path;

-(NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)table;

@end

FOUNDATION_EXPORT NSString *NSLocalizedString(NSString *key,NSString *comment);
FOUNDATION_EXPORT NSString *NSLocalizedStringFromTable(NSString *key,NSString *table,NSString *comment);
FOUNDATION_EXPORT NSString *NSLocalizedStringFromTableInBundle(NSString *key,NSString *table,NSBundle *bundle,NSString *comment);
