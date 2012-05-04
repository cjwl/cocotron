//
//  NSSpellEngine_hunspell.m
//  NSSpellEngine_hunspell
//
//  Created by Christopher Lloyd on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSSpellEngine_hunspell.h"
#import "NSSpellEngine_hunspellDictionary.h"
#import <Foundation/NSOrthography.h>

@implementation NSSpellEngine_hunspell

+(NSArray *)spellEngines {
   NSBundle *bundle=[NSBundle bundleForClass:self];
   NSString *directory=[[bundle resourcePath] stringByAppendingPathComponent:@"Spelling"];

   NSSpellEngine_hunspell *engine=[[[NSSpellEngine_hunspell alloc] initWithContentsOfFile:directory] autorelease];
   
   return [NSArray arrayWithObject: engine];
}

-initWithContentsOfFile:(NSString *)path {
   NSArray *contents=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
   
   _dictionaries=[[NSMutableDictionary alloc] init];
      
   for(NSString *aff in contents){
       
    if([[aff pathExtension] isEqualToString:@"aff"]){
     NSString *affPath=[path stringByAppendingPathComponent:aff];
     NSSpellEngine_hunspellDictionary *dict=[[[NSSpellEngine_hunspellDictionary alloc] initWithContentsOfFile:affPath] autorelease];
     
     [_dictionaries setObject:dict forKey:[dict language]];
    }
        
   }
   
   return self;
}

-(NSString *)vendor {
   return @"Hunspell";
}

-(NSArray *)languages {
   NSMutableArray *result=[NSMutableArray array];
   
   for(NSSpellEngine_hunspellDictionary *dict in [_dictionaries allValues]){
    [result addObject:[dict language]];
   }
   
   [result sortUsingSelector:@selector(caseInsensitiveCompare:)];
   
   return result;
}

- (NSSpellEngine_hunspellDictionary *)_dictionaryForLanguage:(NSString *)language
{
	if (language == nil) {
		language = [[NSLocale currentLocale] localeIdentifier];
	}
	NSSpellEngine_hunspellDictionary *dict=[_dictionaries objectForKey:language];
	if (dict == nil) {
		// If the lang is "xx_YY", then try the first dict starting with "xx"
		// So "fr_CA", "fr_BE"... can use the french dictionary for example if no canadian or belgium
		// dictionary is available
		NSArray *elements = [language componentsSeparatedByString:@"_"];
		if ([elements count] >= 1) {
			NSString *langPrefix = [elements objectAtIndex:0];
			for (NSString *lang in _dictionaries.allKeys) {
				if ([lang hasPrefix:langPrefix]) {
					dict=[_dictionaries objectForKey:lang];
				}
			}
		}
	}
	if (dict == nil) {
		// Couldnt find any dictionary that seems interesting for the user
		// Fallback to the US one
		dict=[_dictionaries objectForKey:@"en_US"];
	}	
	return [[dict retain] autorelease];
}

-(NSArray *)checkString:(NSString *)stringToCheck offset:(NSUInteger)offset types:(NSTextCheckingTypes)checkingTypes options:(NSDictionary *)options orthography:(NSOrthography *)orthography wordCount:(NSInteger *)wordCount {
   NSMutableArray *result=[NSMutableArray array];
   
   NSString *language=[orthography dominantLanguage];
   NSSpellEngine_hunspellDictionary *dict=[self _dictionaryForLanguage:language];
   NSUInteger length=[stringToCheck length];
   
   NSUInteger bufferCapacity=10,bufferOffset=offset,bufferIndex=0,bufferLength=0;
   unichar    buffer[bufferCapacity];
   
   NSUInteger wordCapacity=10,wordLength=0;
   unichar   *wordBuffer=(unichar *)NSZoneMalloc(NULL,sizeof(unichar)*wordCapacity);
   
   NSCharacterSet *letters=[NSCharacterSet letterCharacterSet];
   
   enum {
    STATE_WHITESPACE,
    STATE_WORD,
   } state=STATE_WHITESPACE;
   
   for(;bufferOffset+bufferIndex<=length;bufferIndex++){
    BOOL    appendToWord=NO;
    BOOL    checkWord=NO;
    unichar code;
        
    if(bufferOffset+bufferIndex==length)
     code=' ';
    else {
     if(bufferIndex>=bufferLength){
      bufferOffset+=bufferLength;
     
      bufferIndex=0;
      bufferLength=MIN(bufferCapacity,length-bufferOffset);
     
      [stringToCheck getCharacters:buffer range:NSMakeRange(bufferOffset,bufferLength)];
     }
    
     code=buffer[bufferIndex];
    }
    
    switch(state){
    
     case STATE_WHITESPACE:
      if(![letters characterIsMember:code])
       break;
      else {
       state=STATE_WORD;
       appendToWord=YES;
      }
      break;
    
     case STATE_WORD:
      if(![letters characterIsMember:code]){
       state=STATE_WHITESPACE;
       checkWord=YES;
      }
      else
       appendToWord=YES;
      break;
      
    }
    
    if(appendToWord){
    
     if(wordLength>=wordCapacity){
      wordCapacity*=2;
      wordBuffer=(unichar *)NSZoneRealloc(NULL,wordBuffer,sizeof(unichar)*wordCapacity);
     }
     
     wordBuffer[wordLength++]=code;
    }
    
    if(checkWord){
     [result addObjectsFromArray:[dict textCheckingResultWithRange:NSMakeRange(bufferOffset+(bufferIndex-wordLength),wordLength) forCharacters:wordBuffer length:wordLength]];
     wordLength=0;
    }
    
   }
   
   
   return result;
}

-(NSArray *)suggestGuessesForWord:(NSString *)word inLanguage:(NSString *)language {
	NSSpellEngine_hunspellDictionary *dict = [self _dictionaryForLanguage:language];
   return [dict suggestGuessesForWord:word];    
}

@end
