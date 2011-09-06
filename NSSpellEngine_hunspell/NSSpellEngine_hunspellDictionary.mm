//
//  NSSpellEngine_hunspellDictionary.m
//  NSSpellEngine_hunspell
//
//  Created by Christopher Lloyd on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSSpellEngine_hunspellDictionary.h"
#import <Foundation/NSTextCheckingResult.h>

/* hunspelldll.h is a rough C cover over the C++ library, if more functionality is needed use the C++
   library directly.
 */
 
// hunspell includes use 'near' identifier for method name, but windows.h #defines near
// However, windows.h should not be included in public Foundation headers, so that needs to be
// cleaned up. For now we #undef near

#undef near
#import "hunspelldll.h"

@implementation NSSpellEngine_hunspellDictionary

-initWithContentsOfFile:(NSString *)path {
   _path=[path copy];
   NSString *affPath=_path;
   NSString *dicPath=[[_path stringByDeletingPathExtension] stringByAppendingPathExtension:@"dic"];
   
   _hunspell=hunspell_initialize((char *)[affPath fileSystemRepresentation],(char *)[dicPath fileSystemRepresentation]);
   return self;
}

-(NSString *)localeIdentifier {
   return [[_path lastPathComponent] stringByDeletingPathExtension];
}

-(NSString *)language {
   return [self localeIdentifier];

}

-(NSArray *)textCheckingResultWithRange:(NSRange)range forCharacters:(unichar *)characters length:(NSUInteger)length {
      
   char *encoding=hunspell_get_dic_encoding((Hunspell *)_hunspell);
   
   if(encoding==NULL || strcmp(encoding,"ISO8859-1")==0){
    NSUInteger i;
    char latin1[length+1];
   
    
    for(i=0;i<length;i++){
     if(characters[i]<256)
      latin1[i]=characters[i];
     else {
      /* Word contains a character outside of IS8859-1, I guess this is a spelling error. */
      NSTextCheckingResult *result=[NSTextCheckingResult spellCheckingResultWithRange:range];
      return [NSArray arrayWithObject:result];
     }
     
    }
    latin1[i]='\0';
    
    if(hunspell_spell((Hunspell *)_hunspell,latin1)==0){
     NSTextCheckingResult *result=[NSTextCheckingResult spellCheckingResultWithRange:range];
     return [NSArray arrayWithObject:result];
    }
   }
   else {
    NSLog(@"Unhandled hunspell dictionary encoding %s",encoding);
   }
   
   return nil;
}

@end
