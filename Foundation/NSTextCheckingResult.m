#import <Foundation/NSTextCheckingResult.h>
#import <Foundation/NSRaise.h>

@implementation NSTextCheckingResult

+(NSTextCheckingResult *)addressCheckingResultWithRange:(NSRange)range components:(NSDictionary *)components {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)correctionCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacement {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)dashCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacement {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)dateCheckingResultWithRange:(NSRange)range date:(NSDate *)date {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)dateCheckingResultWithRange:(NSRange)range date:(NSDate *)date timeZone:(NSTimeZone *)timeZone duration:(NSTimeInterval)duration {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)grammarCheckingResultWithRange:(NSRange)range details:(NSArray *)details {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)linkCheckingResultWithRange:(NSRange)range URL:(NSURL *)url {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)orthographyCheckingResultWithRange:(NSRange)range orthography:(NSOrthography *)orthography {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)quoteCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacement {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)replacementCheckingResultWithRange:(NSRange)range replacementString:(NSString *)replacement {
    NSUnimplementedMethod();
    return nil;
}

+(NSTextCheckingResult *)spellCheckingResultWithRange:(NSRange)range {
    NSUnimplementedMethod();
    return nil;
}

-(NSDictionary *)addressComponents {
    NSUnimplementedMethod();
    return nil;
}

-(NSDate *)date {
    NSUnimplementedMethod();
    return nil;
}

-(NSTimeInterval)duration {
    NSUnimplementedMethod();
    return nil;
}

-(NSArray *)grammarDetails {
    NSUnimplementedMethod();
    return nil;
}

-(NSOrthography *)orthography {
    NSUnimplementedMethod();
    return nil;
}

-(NSRange)range {
    NSUnimplementedMethod();
    return NSMakeRange(0,0);
}

-(NSString *)replacementString {
    NSUnimplementedMethod();
    return nil;
}

-(NSTextCheckingType)resultType {
    NSUnimplementedMethod();
    return nil;
}

-(NSTimeZone *)timeZone {
    NSUnimplementedMethod();
    return nil;
}

-(NSURL *)URL {
    NSUnimplementedMethod();
    return nil;
}

@end
