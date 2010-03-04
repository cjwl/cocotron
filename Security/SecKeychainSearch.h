//
//  SecKeychainSearch.h
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@class SecKeychainCursor;

@interface SecKeychainSearch : NSObject {
   CFArrayRef                _array;
   SecItemClass              _itemClass;
   SecKeychainAttributeList *_attributeList;
   
   int _arrayCursor;
   SecKeychainCursor *_keychainCursor;
}

-initWithKeychainOrArray:(CFTypeRef)keychainOrArray itemClass:(SecItemClass)itemClass attributeList:(const SecKeychainAttributeList *)attributeList;

-(SecKeychainItemRef)copyNextItem;

@end
