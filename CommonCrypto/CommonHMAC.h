#import <CommonCrypto/CommonCryptoExport.h>

#import <stdlib.h>

#define CC_SHA1_DIGEST_LENGTH 20

typedef enum {
  kCCHmacAlgSHA1,
} CCHmacAlgorithm;

typedef struct {
   void *sslContext;
} CCHmacContext;

COMMONCRYPTO_EXPORT void CCHmacInit(CCHmacContext *context,CCHmacAlgorithm algorithm,const void *key,size_t keyLength);

COMMONCRYPTO_EXPORT void CCHmacUpdate(CCHmacContext *context,const void *data,size_t dataLength);
COMMONCRYPTO_EXPORT void CCHmacFinal(CCHmacContext *context,void *macOut);

COMMONCRYPTO_EXPORT void CCHmac(CCHmacAlgorithm algorithm,const void *key,size_t keyLength,const void *data,size_t dataLength,void *macOut);
