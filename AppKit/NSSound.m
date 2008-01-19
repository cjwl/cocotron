/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSound.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>

static unsigned int uniquenum = 0;

@implementation NSSound

+(NSArray *)soundUnfilteredFileTypes {
	//	FIXME: Instead of returned this predetermined set (XPSP2) we should query it something *like* GetProfileString("mci extensions",....);
	  
   return [NSArray arrayWithObjects:@"wav",@"aif",@"aifc",@"aiff",@"asf",@"asx",@"au",@"m1v",@"m3u",@"mp2",@"mp2v",@"mp3",@"mpa",@"mpe",@"mpeg",@"mpg",@"mpv2",@"snd",@"wax",@"wm",@"wma",@"wmv",@"wmx",@"wpl",@"wvx",nil];
}

+(NSSound *)soundNamed:(NSString *)name {
	// FIXME: We really have to search in other places too, like the docs say

	NSArray *types = [NSSound soundUnfilteredFileTypes];
	NSString *type;
	NSEnumerator *enumerator = [types objectEnumerator];
	while (type = [enumerator nextObject])
	{
		if ([[NSBundle mainBundle] pathForResource:name ofType:type])
			return [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:type] byReference:NO];
	}	
	 
   return nil;
}

-initWithContentsOfFile:(NSString *)path byReference:(BOOL)byReference {
	if (self = [super init])
	{
		_soundFilePath = [path copy];
		_paused = FALSE;
		_handle = uniquenum++;
	}
	return self;
}

-(BOOL)setName:(NSString *)name {
   NSUnimplementedMethod();
   return NO;
}

-(BOOL)play {
	NSString *loadStr = [NSString stringWithFormat:@"open \"%@\" type %@ alias %i", _soundFilePath, [[_soundFilePath pathExtension] isEqualToString:@"wav"] ? @"waveaudio" : @"MPEGVideo", _handle];
	if (mciSendString([loadStr UTF8String], NULL, 0, 0))
		return NO;

	NSString *playStr = [NSString stringWithFormat:@"play %i from 0", _handle];
	if (mciSendString([playStr UTF8String], NULL, 0, 0))
		return NO;

	return YES;
}

-(BOOL)pause {
	if (_paused)
		return NO;
	else
	{
		NSString *pauseStr = [NSString stringWithFormat:@"pause %i", _handle];
		mciSendString([pauseStr UTF8String], NULL, 0, 0);
		_paused = TRUE;
	}
	return YES;
}

-(BOOL)resume {
	if (!_paused)
		return NO;
	else
	{
		NSString *pauseStr = [NSString stringWithFormat:@"resume %i", _handle];
		mciSendString([pauseStr UTF8String], NULL, 0, 0);
		_paused = FALSE;
	}
	return YES;
}

-(BOOL)stop {
	NSString *stopStr = [NSString stringWithFormat:@"stop %i", _handle];
	mciSendString([stopStr UTF8String], NULL, 0, 0);
	
	return YES;
}

-(void)dealloc {
	[super dealloc];
	NSString *stopStr = [NSString stringWithFormat:@"close %i", _handle];
	mciSendString([stopStr UTF8String], NULL, 0, 0);
}

@end

@implementation NSBundle(NSSound)

-(NSString *)pathForSoundResource:(NSString *)name {
   NSArray *types=[NSSound soundUnfilteredFileTypes];
   int      i,count=[types count];

   for(i=0;i<count;i++){
    NSString *type=[types objectAtIndex:i];
    NSString *path=[self pathForResource:name ofType:type];

    if(path!=nil)
     return path;
   }

   return nil;
}

@end

