/* Copyright (c) 2011 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSSpellingViewController.h"
#import <Foundation/NSSpellEngine.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSSpellChecker.h>

@class NSTableColumn;

@implementation NSSpellingViewController

-(NSArray *)availableLanguages {
   NSMutableArray *result=[NSMutableArray array];
   
   for(NSSpellEngine *engine in [NSSpellEngine allSpellEngines]){
    [result addObjectsFromArray:[engine languages]];
   }
   
   [result sortUsingSelector:@selector(caseInsensitiveCompare:)];
   
   NSLog(@"result=%@",result);
   return result;
}



-(NSSpellEngine *)currentSpellEngine {
    return [[NSSpellEngine allSpellEngines] objectAtIndex:0];
}

-(NSString *)currentWord {
    return [_currentWord stringValue];
}

-(NSString *)currentLanguage {
    return [[NSLocale currentLocale] localeIdentifier];
}

-(NSArray *)currentGuesses {
    return [[self currentSpellEngine] suggestGuessesForWord:[self currentWord] inLanguage:[self currentLanguage]];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self currentGuesses] count];
}

-tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[self currentGuesses] objectAtIndex:row];
}

-(void)reloadGuessesForCurrentWord {
    [_suggestionTable reloadData];
}

-(void)updateSpellingPanelWithMisspelledWord:(NSString *)word {
    [_currentWord setStringValue:word];
    [self reloadGuessesForCurrentWord];
}

-(void)change:sender {
    [NSApp sendAction:@selector(changeSpelling:) to:nil from:_currentWord];
}

-(void)findNext:sender {
    [NSApp sendAction:@selector(checkSpelling:) to:nil from:[NSSpellChecker sharedSpellChecker]];
}

-(void)ignore:sender {
    [NSApp sendAction:@selector(ignoreSpelling:) to:nil from:[NSSpellChecker sharedSpellChecker]];
}

-(void)learn:sender {
    [[NSSpellChecker sharedSpellChecker] learnWord:[_currentWord stringValue]];
}

-(void)guess:sender {
    [self reloadGuessesForCurrentWord];
}

@end
