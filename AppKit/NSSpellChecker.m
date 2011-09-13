/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSpellChecker.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSRaise.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSOrthography.h>
#import <Foundation/NSSpellEngine.h>
#import "NSSpellCheckerTagData.h"
#import "NSSpellingViewController.h"

NSString * const NSSpellCheckerDidChangeAutomaticTextReplacementNotification=@"NSSpellCheckerDidChangeAutomaticTextReplacementNotification";
NSString * const NSSpellCheckerDidChangeAutomaticSpellingCorrectionNotification=@"NSSpellCheckerDidChangeAutomaticSpellingCorrectionNotification";

NSString * const NSTextCheckingOrthographyKey=@"NSTextCheckingOrthographyKey";
NSString * const NSTextCheckingQuotesKey=@"NSTextCheckingQuotesKey";
NSString * const NSTextCheckingReplacementsKey=@"NSTextCheckingReplacementsKey";
NSString * const NSTextCheckingReferenceDateKey=@"NSTextCheckingReferenceDateKey";
NSString * const NSTextCheckingReferenceTimeZoneKey=@"NSTextCheckingReferenceTimeZoneKey";
NSString * const NSTextCheckingDocumentURLKey=@"NSTextCheckingDocumentURLKey";
NSString * const NSTextCheckingDocumentTitleKey=@"NSTextCheckingDocumentTitleKey";
NSString * const NSTextCheckingDocumentAuthorKey=@"NSTextCheckingDocumentAuthorKey";

@implementation NSSpellChecker

-init {
   _tagToData=[[NSMutableDictionary alloc] init];
   _learnedWords=[[NSMutableSet alloc] init];
   return self;
}

-(void)dealloc {
   [super dealloc];
}

static NSSpellChecker *shared=nil;

+(NSSpellChecker *)sharedSpellChecker {
   
   if(shared==nil)
    shared=[[NSSpellChecker alloc] init];

   return shared;
}

+(BOOL)sharedSpellCheckerExists {
   return (shared!=nil)?YES:NO;
}

+(BOOL)isAutomaticSpellingCorrectionEnabled {
   NSUnimplementedMethod();
   return 0;
}

+(BOOL)isAutomaticTextReplacementEnabled {
   NSUnimplementedMethod();
   return 0;
}

+(NSInteger)uniqueSpellDocumentTag {
   /* These start at 1, don't change */
   static NSInteger tag=1;
    
   return tag++;
}

-(NSSpellCheckerTagData *)_dataForDocumentTag:(NSInteger)tagInt {
   NSNumber *tag=[NSNumber numberWithInteger:tagInt];
   NSSpellCheckerTagData *result=[_tagToData objectForKey:tag];
   
   if(result==nil){
    result=[[[NSSpellCheckerTagData alloc] init] autorelease];
    [_tagToData setObject:result forKey:tag];
   }
   
   return result;
}

-(NSView *)accessoryView {
   return _accessoryView;
}

-(void)setAccessoryView:(NSView *)view {
   view=[view retain];
   [_accessoryView release];
   _accessoryView=view;
   NSUnimplementedMethod();
}


-(BOOL)automaticallyIdentifiesLanguages {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)availableLanguages {
   NSUnimplementedMethod();
   return 0;
}

-(NSRange)checkGrammarOfString:(NSString *)string startingAt:(NSInteger)start language:(NSString *)language wrap:(BOOL)wrap inSpellDocumentWithTag:(NSInteger)documentTag details:(NSArray **)outDetails {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSRange)checkSpellingOfString:(NSString *)string startingAt:(NSInteger)offset {
   return [self checkSpellingOfString:string startingAt:offset language:nil wrap:NO inSpellDocumentWithTag:0 wordCount:NULL];
}

-(NSRange)checkSpellingOfString:(NSString *)string startingAt:(NSInteger)offset language:(NSString *)language wrap:(BOOL)wrap inSpellDocumentWithTag:(NSInteger)tag wordCount:(NSInteger *)wordCount {
   NSMutableDictionary *options=[NSMutableDictionary dictionary];
   
   if(language==nil)
    language=[[NSLocale currentLocale] localeIdentifier];
    
   if(language!=nil){
    NSDictionary  *languageMap=[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:language] forKey:@"Latn"];
    NSOrthography *orthography=[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap];
    
    [options setObject:orthography forKey:NSTextCheckingOrthographyKey];
   }

   NSArray *checking=[self checkString:string range:NSMakeRange(offset,[string length]-offset) types:NSTextCheckingTypeSpelling options:options inSpellDocumentWithTag:tag orthography:NULL wordCount:wordCount];
   
   if([checking count]==0)
    return NSMakeRange(0,0);
    
   NSTextCheckingResult *first=[checking objectAtIndex:0];
   
   return [first range];
}

-(NSSpellEngine *)currentSpellEngine {
   return [[NSSpellEngine allSpellEngines] objectAtIndex:0];
}

-(NSArray *)checkString:(NSString *)string range:(NSRange)range types:(NSTextCheckingTypes)types options:(NSDictionary *)options inSpellDocumentWithTag:(NSInteger)tag orthography:(NSOrthography **)orthography wordCount:(NSInteger *)wordCount {
   NSSpellEngine *spellEngine=[self currentSpellEngine];
   
   /* NSSpellChecker and NSSpellServer have inconsistent API, we accept a range but the server only takes an offset. */
   /* NSSpellChecker returns by ref an orthography, yet NSSpellServer accepts one as argument. */
   /* I guess this isn't one to one and there is some extra work being done in NSSpellChecker. */
   
   NSString *substring=[string substringToIndex:NSMaxRange(range)];
   
   return [spellEngine checkString:substring offset:range.location types:types options:options orthography:[options objectForKey:NSTextCheckingOrthographyKey] wordCount:wordCount];
}

-(void)closeSpellDocumentWithTag:(NSInteger)tag { 
   NSUnimplementedMethod();
}

-(NSArray *)completionsForPartialWordRange:(NSRange)partialWordRange inString:(NSString *)string language:(NSString *)language inSpellDocumentWithTag:(NSInteger)tag {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)correctionForWordRange:(NSRange)range inString:(NSString *)string language:(NSString *)language inSpellDocumentWithTag:(NSInteger)tag {
   NSUnimplementedMethod();
   return 0;
}

-(NSInteger)countWordsInString:(NSString *)string language:(NSString *)language {
   NSUnimplementedMethod();
   return 0;
}

-(void)dismissCorrectionIndicatorForView:(NSView *)view {
   NSUnimplementedMethod();
}

-(NSArray *)guessesForWordRange:(NSRange)range inString:(NSString *)string language:(NSString *)language inSpellDocumentWithTag:(NSInteger)tag {
   NSUnimplementedMethod();
   return 0;
}

-(void)learnWord:(NSString *)word {
   [_learnedWords addObject:[[word copy] autorelease]];
}

-(BOOL)hasLearnedWord:(NSString *)word {
   return [_learnedWords containsObject:word];
}

-(NSString *)language {
   return _language;
}

-(BOOL)setLanguage:(NSString *)language {
   language=[language copy];
   NSUnimplementedMethod();
   // Check if known language, return YES if so. TODO: Does NO still set the language?
   return YES;
}



-(NSMenu *)menuForResult:(NSTextCheckingResult *)result string:(NSString *)checkedString options:(NSDictionary *)options atLocation:(NSPoint)location inView:(NSView *)view {
   NSUnimplementedMethod();
   return 0;
}

-(void)recordResponse:(NSCorrectionResponse)response toCorrection:(NSString *)correction forWord:(NSString *)word language :(NSString *)language inSpellDocumentWithTag :(NSInteger)tag {
   NSUnimplementedMethod();
}

#ifdef NS_BLOCKS
-(NSInteger)requestCheckingOfString:(NSString *)stringToCheck range:(NSRange)range types:(NSTextCheckingTypes)checkingTypes options:(NSDictionary *)options inSpellDocumentWithTag:(NSInteger)tag completionHandler:(void (^)(NSInteger sequenceNumber, NSArray *results, NSOrthography *orthography, NSInteger wordCount))completionHandler {
   NSUnimplementedMethod();
   return 0;
}

#endif

-(void)setAutomaticallyIdentifiesLanguages:(BOOL)flag {
   NSUnimplementedMethod();
}


-(void)ignoreWord:(NSString *)word inSpellDocumentWithTag:(NSInteger)tag {
   [[self _dataForDocumentTag:tag] ignoreWord:word];
}

-(NSArray *)ignoredWordsInSpellDocumentWithTag:(NSInteger)tag {
   return [[self _dataForDocumentTag:tag] ignoredWords];
}

-(void)setIgnoredWords:(NSArray *)ignoredWords inSpellDocumentWithTag:(NSInteger)tag {
   [[self _dataForDocumentTag:tag] setIgnoredWords:ignoredWords];
}

-(void)setSubstitutionsPanelAccessoryViewController:(NSViewController *)viewController {
   NSUnimplementedMethod();
}

-(void)setWordFieldStringValue:(NSString *)string {
   NSUnimplementedMethod();
}

#ifdef NS_BLOCKS
-(void)showCorrectionIndicatorOfType:(NSCorrectionIndicatorType)type primaryString:(NSString *)primaryString alternativeStrings:(NSArray *)alternativeStrings forStringInRect:(NSRect)rect view:(NSView *)view completionHandler:(void (^)(NSString *acceptedString))completionBlock {
   NSUnimplementedMethod();
}
#endif

-(NSPanel *)spellingPanel {
   if(_spellingPanel==nil){
    _spellingViewController=[[NSSpellingViewController alloc] initWithNibName:@"NSSpellingViewController" bundle:[NSBundle bundleForClass:[NSSpellingViewController class]]];
    
    NSView *view=[_spellingViewController view];
    _spellingPanel=[[NSPanel alloc] initWithContentRect:[view frame] styleMask:NSUtilityWindowMask backing:NSBackingStoreBuffered defer:YES];
    
    [_spellingPanel setContentView:view];
    
    [_spellingPanel center];
   }
   
   return _spellingPanel;
}

-(NSPanel *)substitutionsPanel {
   return _substitutionsPanel;
}

-(NSViewController *)substitutionsPanelAccessoryViewController {
   NSUnimplementedMethod();
   return 0;
}

-(void)unlearnWord:(NSString *)word {
   NSUnimplementedMethod();
}

-(void)updatePanels {
   NSUnimplementedMethod();
}

-(void)updateSpellingPanelWithGrammarString:(NSString *)problemString detail:(NSDictionary *)detail {
   NSUnimplementedMethod();
}

-(void)updateSpellingPanelWithMisspelledWord:(NSString *)word {
   NSUnimplementedMethod();
}

-(NSArray *)userPreferredLanguages {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)userQuotesArrayForLanguage:(NSString *)language {
   NSUnimplementedMethod();
   return 0;
}

-(NSDictionary *)userReplacementsDictionary {
   NSUnimplementedMethod();
   return 0;
}

@end
