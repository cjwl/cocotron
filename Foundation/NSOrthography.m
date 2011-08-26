#import <Foundation/NSOrthography.h>
#import <Foundation/NSRaise.h>

@implementation NSOrthography

+orthographyWithDominantScript:(NSString *)script languageMap:(NSDictionary *)languageMap {
    return [[[self alloc] initWithDominantScript:script languageMap:languageMap] autorelease];
}

-initWithDominantScript:(NSString *)script languageMap:(NSDictionary *)languageMap {
    _dominantScript=[script copy];
    _languageMap=[languageMap copy];
    return self;
}

-(void)dealloc {
    [_dominantScript release];
    [_languageMap release];
    [super dealloc];
}

-(NSDictionary *)languageMap {
    return _languageMap;
}

-(NSArray *)allLanguages {
    NSUnimplementedMethod();
    return nil;
}

-(NSArray *)allScripts {
    NSUnimplementedMethod();
    return nil;
}

-(NSString *)dominantLanguage {
    NSUnimplementedMethod();
    return nil;
}

-(NSString *)dominantScript {
    return _dominantScript;
}

-(NSString *)dominantLanguageForScript:(NSString *)script {
    NSUnimplementedMethod();
    return nil;
}

-(NSArray *)languagesForScript:(NSString *)script {
    NSUnimplementedMethod();
    return nil;
}

@end
