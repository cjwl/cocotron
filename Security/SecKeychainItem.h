//
//  SecKeychainItem.h
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface SecKeychainItem : NSObject {
   SecItemClass              _itemClass;
   SecKeychainAttributeList *_attributeList;
   UInt32                    _length;
   void                     *_bytes;
   NSString                 *_guid;
   SecKeychainRef            _keychain;
   SecAccessRef              _access;
}

-initWithItemClass:(SecItemClass)itemClass attributeList:(SecKeychainAttributeList *)attributeList length:(UInt32)length bytes:(const void *)bytes;

-(SecItemClass)itemClass;
-(SecKeychainAttributeList *)attributeList;
-(UInt32)blobLength;
-(void *)blobBytes;

-(NSString *)GUID;
-(SecKeychainRef)keychain;
-(SecAccessRef)access;

-(void)setGUID:(NSString *)value;
-(void)setKeychain:(SecKeychainRef)keychain;
-(void)setAccess:(SecAccessRef)access;

-(BOOL)isMatchToAttributeList:(const SecKeychainAttributeList *)other;

-(void)modifyAttributeList:(const SecKeychainAttributeList *)attributeList length:(UInt32)length bytes:(const void *)bytes;

-(void)copyAttributeInfo:(SecKeychainAttributeInfo *)info itemClass:(SecItemClass *)itemClass attributeList:(SecKeychainAttributeList **)attributeList length:(UInt32 *)length bytes:(void **)bytes;

@end
