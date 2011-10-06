//
//  NSSpellEngine_hunspell.h
//  NSSpellEngine_hunspell
//
//  Created by Christopher Lloyd on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSSpellEngine.h>

@class NSMutableDictionary;


@interface NSSpellEngine_hunspell : NSSpellEngine {
   NSMutableDictionary *_dictionaries;
   
   NSString *_directory;
   NSString *_localeIdentifier;
   
   void *_hunspell;
}

-initWithContentsOfFile:(NSString *)path;

@end
