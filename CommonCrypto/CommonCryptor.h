#import <CommonCrypto/CommonCryptoExport.h>
#import <stdlib.h>
#import <stdint.h>
#import <stdbool.h>

enum {
	kCCKeySizeAES128	= 16,
	kCCKeySizeAES256	= 32,
};

enum {
	kCCBlockSizeAES128	= 16,
};

enum {
   kCCSuccess        = 0,
   kCCParamError     = -4300,
   kCCBufferTooSmall = -4301,
   kCCMemoryFailure	 = -4302,
   kCCAlignmentError = -4303,
   kCCDecodeError    = -4304,
   kCCUnimplemented  = -4305,
};
typedef int32_t CCCryptorStatus;

enum {
	kCCEncrypt = 0,	
	kCCDecrypt,		
};
typedef uint32_t CCOperation;

enum {
	kCCAlgorithmAES128 = 0,
};
typedef uint32_t CCAlgorithm;

enum {
	kCCOptionPKCS7Padding	= 0x0001,
	kCCOptionECBMode		= 0x0002,
};
typedef uint32_t CCOptions;

typedef struct CCCryptor *CCCryptorRef;

COMMONCRYPTO_EXPORT CCCryptorStatus CCCryptorCreate(CCOperation operation,CCAlgorithm algorithm,CCOptions options,const void *key,size_t keyLength,const void *initVector,CCCryptorRef *result);

COMMONCRYPTO_EXPORT CCCryptorStatus CCCryptorRelease(CCCryptorRef cryptor);

COMMONCRYPTO_EXPORT size_t          CCCryptorGetOutputLength(CCCryptorRef cryptor,size_t inputLength,bool final);

COMMONCRYPTO_EXPORT CCCryptorStatus CCCryptorUpdate(CCCryptorRef cryptor,const void *dataIn,size_t dataInLength,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved);		

COMMONCRYPTO_EXPORT CCCryptorStatus CCCryptorFinal(CCCryptorRef cryptor,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved);

COMMONCRYPTO_EXPORT CCCryptorStatus CCCrypt(CCOperation operation,CCAlgorithm algorithm,CCOptions options,const void *key,size_t keyLength,const void *initVector,const void *dataIn,size_t dataInLength,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved);	
