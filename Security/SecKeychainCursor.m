#import "SecKeychainCursor.h"

@implementation SecKeychainCursor

-initWithRegistryPath:(NSArray *)path itemClass:(SecItemClass)itemClass handle:(HKEY)handle {
   _path=[path copy];
   _itemClass=itemClass;
   _handle=handle;
   _index=0;
   return self;
}

-(void)dealloc {
   [_path release];
   RegCloseKey(_handle);
   [super dealloc];
}

-(NSArray *)registryPath {
   return _path;
}

-(SecItemClass)itemClass {
   return _itemClass;
}

-(HKEY)handle {
   return _handle;
}

-(int)index {
   return _index;
}

-(void)incrementIndex {
   _index++;
}

@end
