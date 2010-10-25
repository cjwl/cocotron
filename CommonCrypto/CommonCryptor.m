#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/NSRaise.h>
#import <openssl/evp.h>

struct CCCryptor {
   CCOperation       operation;
   EVP_CIPHER_CTX   *context;
   const EVP_CIPHER *cipher;
};

CCCryptorStatus CCCryptorCreate(CCOperation operation,CCAlgorithm algorithm,CCOptions options,const void *key,size_t keyLength,const void *initVector,CCCryptorRef *result) {
   CCCryptorRef self=malloc(sizeof(struct CCCryptor));
   
   self->operation=operation;
   self->context=malloc(sizeof(EVP_CIPHER_CTX));
   EVP_CIPHER_CTX_init(self->context);

   self->cipher=NULL;
   
   switch(algorithm){
   
    case kCCAlgorithmAES128:
     if(options&kCCOptionECBMode){
      if(keyLength==kCCKeySizeAES128)
       self->cipher=EVP_aes_128_ecb();
      else if(keyLength==kCCKeySizeAES256)
       self->cipher=EVP_aes_256_ecb();
     }
     else {
      if(keyLength==kCCKeySizeAES128)
       self->cipher=EVP_aes_128_cbc();
      else if(keyLength==kCCKeySizeAES256)
       self->cipher=EVP_aes_256_cbc();
     }
     break;
   }
   
   if(self->cipher==NULL){
    NSLog(@"%s %d cipher==NULL",__FILE__,__LINE__);
    return kCCUnimplemented;
   }

   if(operation==kCCEncrypt){
    EVP_EncryptInit_ex(self->context,self->cipher,NULL,key,initVector);
   }
   else {
    EVP_DecryptInit_ex(self->context,self->cipher,NULL,key,initVector);
   }
   
   *result=self;
   
   return kCCSuccess;
}

CCCryptorStatus CCCryptorRelease(CCCryptorRef self) {
   EVP_CIPHER_CTX_cleanup(self->context);
   free(self->context);
   free(self);
   return kCCSuccess;
}

size_t CCCryptorGetOutputLength(CCCryptorRef self,size_t inputLength,bool final) {
   int blockSize=EVP_CIPHER_block_size(self->cipher);
   
   return inputLength+blockSize-1;
}

CCCryptorStatus CCCryptorUpdate(CCCryptorRef self,const void *dataIn,size_t dataInLength,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved) {

   if(self->operation==kCCEncrypt){
    int outSize;
    EVP_EncryptUpdate(self->context,dataOut,&outSize,dataIn,dataInLength);
    * dataOutMoved=outSize;
   }
   else {
    int outSize;
    EVP_DecryptUpdate(self->context,dataOut, &outSize,dataIn,dataInLength);
    * dataOutMoved=outSize;
   }
   
   return kCCSuccess;
}

CCCryptorStatus CCCryptorFinal(CCCryptorRef self,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved) {
   if(self->operation==kCCEncrypt){
    int outSize;
    EVP_EncryptFinal_ex(self->context,dataOut, &outSize);
    * dataOutMoved=outSize;
   }
   else {
    int outSize;
    EVP_DecryptFinal_ex(self->context,dataOut, &outSize);
    * dataOutMoved=outSize;
   }
   
   return kCCSuccess;
}

CCCryptorStatus CCCrypt(CCOperation operation,CCAlgorithm algorithm,CCOptions options,const void *key,size_t keyLength,const void *initVector,const void *dataIn,size_t dataInLength,void *dataOut,size_t dataOutAvailable,size_t *dataOutMoved) {
   CCCryptorRef cryptor;
   
   CCCryptorCreate(operation,algorithm,options,key,keyLength,initVector,&cryptor);
   CCCryptorUpdate(cryptor,dataIn,dataInLength,dataOut,dataOutAvailable,dataOutMoved);
   size_t dataOutChunk=0;
   if(options&kCCOptionPKCS7Padding){
    CCCryptorFinal(cryptor,dataOut+*dataOutMoved,dataOutAvailable-*dataOutMoved,&dataOutChunk);
    *dataOutMoved+=dataOutChunk;
   }
   
   return kCCSuccess;
}
