//
//  NSSpellEngine_hunspellDictionary.h
//  NSSpellEngine_hunspell
//
//  Created by Christopher Lloyd on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSSpellEngine_hunspellDictionary : NSObject {
   NSString *_path;
   void     *_hunspell;
}

// Path to .aff file, there must be a .dic file in the same directory

-initWithContentsOfFile:(NSString *)path;

-(NSString *)localeIdentifier;
-(NSString *)language;

-(NSArray *)textCheckingResultWithRange:(NSRange)range forCharacters:(unichar *)characters length:(NSUInteger)length;

-(NSArray *)suggestGuessesForWord:(NSString *)word;

@end
