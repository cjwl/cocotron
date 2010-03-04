#import <Foundation/NSObject.h>
#import <Security/Security.h>
#import <windows.h>

@class NSArray;

@interface SecKeychainCursor : NSObject {
   NSArray *_path;
   SecItemClass _itemClass;
   HKEY _handle;
   int  _index;
}

-initWithRegistryPath:(NSArray *)path itemClass:(SecItemClass)itemClass handle:(HKEY)handle;

-(NSArray *)registryPath;
-(SecItemClass)itemClass;
-(HKEY)handle;
-(int)index;
-(void)incrementIndex;

@end
