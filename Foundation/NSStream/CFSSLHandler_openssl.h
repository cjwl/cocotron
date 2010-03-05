#import <Foundation/CFSSLHandler.h>
#import <CoreFoundation/CFDictionary.h>
#import <CFNetwork/CFSocketStream.h>

#ifdef OPENSSL_ENABLED
#import <openssl/ssl.h>
#endif

@class NSSocket,NSMutableData;

@interface CFSSLHandler_openssl : CFSSLHandler {
   CFDictionaryRef _properties;
#ifdef OPENSSL_ENABLED
   SSL_METHOD *_method;
   SSL_CTX    *_context;
   SSL        *_connection;
   BIO        *_incoming;
   BIO        *_outgoing;
#endif
   NSInteger   _stableBufferCapacity;
   uint8_t    *_stableBuffer;
   NSMutableData *_readBuffer;
}

-initWithProperties:(CFDictionaryRef)properties;

-(BOOL)isHandshaking;

-(NSInteger)writePlaintext:(const uint8_t *)buffer maxLength:(NSUInteger)length;
-(NSInteger)writeBytesAvailable;
-(BOOL)wantsMoreIncoming;
-(NSInteger)readEncrypted:(uint8_t *)buffer maxLength:(NSUInteger)length;

-(NSInteger)writeEncrypted:(const uint8_t *)buffer maxLength:(NSUInteger)length;
-(NSInteger)readBytesAvailable;
-(NSInteger)readPlaintext:(uint8_t *)buffer maxLength:(NSUInteger)length;

-(NSInteger)transferOneBufferFromSSLToSocket:(NSSocket *)socket;
-(NSInteger)transferOneBufferFromSocketToSSL:(NSSocket *)socket;

-(void)runWithSocket:(NSSocket *)socket;

@end
