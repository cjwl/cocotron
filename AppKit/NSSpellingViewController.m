/* Copyright (c) 2011 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSSpellingViewController.h"
#import <Foundation/NSSpellEngine.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSSpellChecker.h>

@class NSTableColumn;

@implementation NSSpellingViewController

-(NSString *)_currentLanguage {
    return [[NSLocale currentLocale] localeIdentifier];
}

-(NSSpellEngine *)currentSpellEngine {
    return [[NSSpellEngine allSpellEngines] objectAtIndex:0];
}

-(NSString *)currentWord {
    return _misspelledWord;
}

-(NSArray *)currentGuesses
{
	NSString* currentWord = [self currentWord];
	NSString* currentLanguage = [self _currentLanguage];
    NSArray* currentGuesses = [[self currentSpellEngine] suggestGuessesForWord: currentWord inLanguage: currentLanguage];
	
	return currentGuesses;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self currentGuesses] count];
}

-tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[self currentGuesses] objectAtIndex:row];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	NSString* selectedGuess = [[self currentGuesses] objectAtIndex: row];
	[_currentWord setStringValue: selectedGuess];
	[_spellingHint setHidden: YES];
	return YES;
}

-(void)reloadGuessesForCurrentWord {
    [_suggestionTable reloadData];
}

-(void)updateSpellingPanelWithMisspelledWord:(NSString *)word
{
	[_misspelledWord autorelease];
	_misspelledWord = [word copy];
    [_currentWord setStringValue: _misspelledWord];
	[_suggestionTable deselectAll: nil];
    [self reloadGuessesForCurrentWord];
	[_spellingHint setHidden: [word isEqualToString: @""]];
}

-(void)change:sender {
    [NSApp sendAction:@selector(changeSpelling:) to: nil from: _currentWord];
}

-(void)findNext:sender {
    [NSApp sendAction:@selector(checkSpelling:) to:nil from:[NSSpellChecker sharedSpellChecker]];
}

-(void)ignore:sender {
    [NSApp sendAction:@selector(ignoreSpelling:) to:nil from:_currentWord];
}

-(void)learn:sender {
    [[NSSpellChecker sharedSpellChecker] learnWord:[_currentWord stringValue]];
}

-(void)guess:sender {
    [self reloadGuessesForCurrentWord];
}

@end
