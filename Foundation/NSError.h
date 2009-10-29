/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>

@class NSDictionary,NSArray;

FOUNDATION_EXPORT NSString *NSPOSIXErrorDomain;
FOUNDATION_EXPORT NSString *NSOSStatusErrorDomain;
// temporary until we can map it
FOUNDATION_EXPORT NSString *NSWINSOCKErrorDomain;
FOUNDATION_EXPORT NSString *NSCocoaErrorDomain;

FOUNDATION_EXPORT NSString *NSUnderlyingErrorKey;
FOUNDATION_EXPORT NSString *NSLocalizedDescriptionKey;
FOUNDATION_EXPORT NSString *NSLocalizedFailureReasonErrorKey;
FOUNDATION_EXPORT NSString *NSLocalizedRecoveryOptionsErrorKey;
FOUNDATION_EXPORT NSString *NSLocalizedRecoverySuggestionErrorKey;
FOUNDATION_EXPORT NSString *NSRecoveryAttempterErrorKey;

FOUNDATION_EXPORT NSString *NSStringEncodingErrorKey;
FOUNDATION_EXPORT NSString *NSFilePathErrorKey;
FOUNDATION_EXPORT NSString *NSErrorFailingURLStringKey;
FOUNDATION_EXPORT NSString *NSURLErrorKey;

@interface NSError : NSObject <NSCoding,NSCopying> {
   NSString     *_domain;
   NSInteger     _code;
   NSDictionary *_userInfo;
}

-initWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userInfo;

+errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)userInfo;

-(NSString *)domain;
-(NSInteger)code;
-(NSDictionary *)userInfo;

-(NSString *)localizedDescription;
-(NSString *)localizedFailureReason;
-(NSArray *)localizedRecoveryOptions;
-(NSString *)localizedRecoverySuggestion;

-recoveryAttempter;

@end

@interface NSObject(NSErrorRecoveryAttempting)

-(void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)info;
-(BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex;

@end