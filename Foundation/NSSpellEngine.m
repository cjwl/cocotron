//
//  NSSpellEngine.m
//  Foundation
//
//  Created by Christopher Lloyd on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSSpellEngine.h>
#import <Foundation/NSRaise.h>

@implementation NSSpellEngine

-(NSRange)spellServer:(NSSpellServer *)sender checkGrammarInString:(NSString *)string language:(NSString *)language details:(NSArray **)outDetails {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSArray *)spellServer:(NSSpellServer *)sender checkString:(NSString *)stringToCheck offset:(NSUInteger)offset types:(NSTextCheckingTypes)checkingTypes options:(NSDictionary *)options orthography:(NSOrthography *)orthography wordCount:(NSInteger *)wordCount {
   NSUnimplementedMethod();
   return nil;
}

-(void)spellServer:(NSSpellServer *)sender didForgetWord:(NSString *)word inLanguage:(NSString *)language {
   NSUnimplementedMethod();
}

-(void)spellServer:(NSSpellServer *)sender didLearnWord:(NSString *)word inLanguage:(NSString *)language {
   NSUnimplementedMethod();
}

-(NSRange)spellServer:(NSSpellServer *)sender findMisspelledWordInString:(NSString *)stringToCheck language:(NSString *)language wordCount:(NSInteger *)wordCount countOnly:(BOOL)countOnly {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSArray *)spellServer:(NSSpellServer *)sender suggestCompletionsForPartialWordRange:(NSRange)range inString:(NSString *)string language:(NSString *)language {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)spellServer:(NSSpellServer *)sender suggestGuessesForWord:(NSString *)word inLanguage:(NSString *)language {
   NSUnimplementedMethod();
   return nil;
}

@end
