//
//  SecKeychainSearch.m
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SecKeychainSearch.h"
#import "SecKeychain.h"

@implementation SecKeychainSearch


-initWithKeychainOrArray:(CFTypeRef)keychainOrArray itemClass:(SecItemClass)itemClass attributeList:(const SecKeychainAttributeList *)attributeList {
   if(keychainOrArray==NULL)
    keychainOrArray=[SecKeychain defaultUserKeychain];
    
   if(![(id)keychainOrArray isKindOfClass:[NSArray class]])
    keychainOrArray=[NSArray arrayWithObject:(id)keychainOrArray];
   
   _array=(CFArrayRef)CFRetain(keychainOrArray);
   _itemClass=itemClass;
   _attributeList=SecCopyAttributeList(attributeList);

   _arrayCursor=0;
   _keychainCursor=nil;
   return self;
}

-(void)dealloc {
   CFRelease(_array);
   SecFreeAttributeList(_attributeList);   
   [_keychainCursor release];
   [super dealloc];
}

-(SecKeychainItemRef)copyNextItem {
   ("%s %d",__FUNCTION__,__LINE__);
  
  while(_arrayCursor<CFArrayGetCount(_array)){
   SecKeychainRef keychain=(id)CFArrayGetValueAtIndex(_array,_arrayCursor);
   ("%s %d",__FUNCTION__,__LINE__);
   
   if(_keychainCursor==nil)
    _keychainCursor=[keychain createCursorForItemClass:_itemClass];
   ("%s %d",__FUNCTION__,__LINE__);
    
   SecKeychainItemRef check=nil;
    
   if(_keychainCursor!=nil)
    check=[keychain createNextItemAtCursor:_keychainCursor attributeList:_attributeList];
    
   if(check!=nil)
    return check;
    
   _arrayCursor++;
   [_keychainCursor release];
   _keychainCursor=nil;
  }
   ("%s %d",__FUNCTION__,__LINE__);
   return nil;
}

@end
