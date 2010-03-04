//
//  SecKeychainItem.m
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SecKeychainItem.h"


@implementation SecKeychainItem

-initWithItemClass:(SecItemClass)itemClass attributeList:(SecKeychainAttributeList *)attributeList length:(UInt32)length bytes:(const void *)bytes {
   _itemClass=itemClass;
   _attributeList=SecCopyAttributeList(attributeList);
   _length=length;
   _bytes=NSZoneMalloc(NULL,_length);
   SecByteCopy(bytes,_bytes,_length);
   return self;
}

-(void)dealloc {
   SecFreeAttributeList(_attributeList);
   NSZoneFree(NULL,_bytes);
   [super dealloc];
}

-(SecItemClass)itemClass {
   return _itemClass;
}

-(SecKeychainAttributeList *)attributeList {
   return _attributeList;
}

-(UInt32)blobLength {
   return _length;
}

-(void *)blobBytes {
   return _bytes;
}

-(NSString *)GUID {
   return _guid;
}

-(void)setGUID:(NSString *)value {
   value=[value copy];
   [_guid release];
   _guid=value;
}

-(SecKeychainRef)keychain {
   return _keychain;
}

-(SecAccessRef)access {
   return _access;
}

-(void)setKeychain:(SecKeychainRef)keychain {
   _keychain=[keychain retain];
}

-(void)setAccess:(SecAccessRef)access {
   _access=[access retain];
}

static BOOL bytesAreEqual(uint8_t *bytes1,uint8_t *bytes2,UInt32 length){
   UInt32 i;
  
   for(i=0;i<length;i++)
    if(bytes1[i]!=bytes2[i])
     return NO;
  
   return YES;
}

-(BOOL)isMatchToAttributeList:(const SecKeychainAttributeList *)other {
   int i;
   
   if(other==NULL)
    return YES;
    
   for(i=0;i<other->count;i++){
    UInt32 tag=other->attr[i].tag;
    int    j;
    
    for(j=0;j<_attributeList->count;j++){
     if(_attributeList->attr[j].tag==tag){
      
      if(other->attr[i].length!=_attributeList->attr[j].length){
       return NO;
      }
       
      if(!bytesAreEqual(other->attr[i].data,_attributeList->attr[j].data,other->attr[i].length)){
       return NO;
      }
      break;
     }
    }
    
    if(j>=_attributeList->count){ // didn't find tag in self
     return NO;
    }
   }
   
   return YES;
}

-(void)modifyAttributeList:(const SecKeychainAttributeList *)attributeList length:(UInt32)length bytes:(const void *)bytes {
   if(attributeList!=NULL){
// FIXME: implement
   }
   
   if(bytes!=NULL){
    NSZoneFree(NULL,_bytes);
    
    _length=length;
    _bytes=NSZoneMalloc(NULL,_length);
    SecByteCopy(bytes,_bytes,_length);
   }
}

-(void)copyAttributeInfo:(SecKeychainAttributeInfo *)info itemClass:(SecItemClass *)itemClass attributeList:(SecKeychainAttributeList **)attributeList length:(UInt32 *)length bytes:(void **)bytes {
   if(info!=NULL){
// FIXME: implement
   }
   
   if(itemClass!=NULL)
    *itemClass=_itemClass;
   
   if(attributeList!=NULL)
    *attributeList=SecCopyAttributeList(_attributeList);
   
   if(length!=NULL)
    *length=_length;
    
   if(bytes!=NULL){
    *bytes=NSZoneMalloc(NULL,_length);
    SecByteCopy(_bytes,*bytes,_length);
   }
}


@end
