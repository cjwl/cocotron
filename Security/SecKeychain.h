//
//  SecKeychain.h
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Security/Security.h>

@class SecKeychainCursor;

@interface SecKeychain : NSObject {
   NSArray *_registryPath;
}

+(SecKeychain *)defaultUserKeychain;

-(NSString *)createGUID;

-(SecKeychainCursor *)createCursorForItemClass:(SecItemClass)itemClass;

-(SecKeychainItemRef)createNextItemAtCursor:(SecKeychainCursor *)cursor attributeList:(const SecKeychainAttributeList *)attributeList;

-(void)addKeychainItem:(SecKeychainItemRef)item;
-(void)removeKeychainItem:(SecKeychainItemRef)item;
-(void)modifyKeychainItem:(SecKeychainItemRef)item;

@end
