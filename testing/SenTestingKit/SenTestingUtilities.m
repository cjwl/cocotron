/*$Id: SenTestingUtilities.m,v 1.8 2005/04/02 03:18:22 phink Exp $*/

// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// (1) Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// 
// (2) Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation 
// and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Note: this license is equivalent to the FreeBSD license.
// 
// This notice may not be removed from this file.

#import "SenTestingUtilities.h"

NSString *STComposeString(NSString *format, ...) {
    if (!format) return @"";
    
    NSString *composedString;
    va_list args;
    
    va_start(args, format);
    composedString = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
    va_end(args);
    
    return composedString;
}

@implementation NSValue (SenTestingAdditions)
- (NSString *) contentDescription
{
	const char *objCType = [self objCType];
	if (objCType != NULL) {
		if (strlen (objCType) == 1) {
			switch (objCType[0]) {
				case 'c': {
					char scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%c", scalarValue];
				}
				case 'C': {
					unsigned char scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%c", scalarValue];
				}
				case 's': {
					short scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%hi", scalarValue];
				}
				case 'S': {
					unsigned short scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%hu", scalarValue];
				}
				case 'l': {
					long scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%li", scalarValue];
				}
				case 'L': {
					unsigned long scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%lu", scalarValue];
				}
				case 'q': {
					long long scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%lli", scalarValue];
				}
				case 'Q': {
					unsigned long long scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%llu", scalarValue];
				}
				case 'i': {
					int scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%i", scalarValue];
				}
				case 'I': {
					unsigned int long scalarValue = 0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%u", scalarValue];
				}
				case 'f': {
					float scalarValue = 0.0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%f", scalarValue];
				}
				case 'd': {
					double scalarValue = 0.0;
					[self getValue:(void *)&scalarValue];
					return [NSString stringWithFormat:@"%.12g", scalarValue];
				}
				default: {
					return [self description];
				}
			}
		}
		else if (strncmp (objCType, "^", 1) == 0) {
			return [NSString stringWithFormat:@"%p", [self pointerValue]];
		} 
		else if (strcmp (objCType, "{_NSPoint=ff}") == 0) {
			return [NSString stringWithFormat:@"%@", NSStringFromPoint ([self pointValue])];	
		} 
		else if (strcmp (objCType, "{_NSSize=ff}") == 0) {
			return [NSString stringWithFormat:@"%@", NSStringFromSize ([self sizeValue])];	
		} 
		else if (strcmp (objCType, "{_NSRange=II}") == 0) {
			return [NSString stringWithFormat:@"%@", NSStringFromRange ([self rangeValue])];		
		} 
		else if (strcmp (objCType, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}") == 0) {
			return [NSString stringWithFormat:@"%@", NSStringFromRect ([self rectValue])];			
		}
	}
	return [self description];
}
@end

@implementation NSFileManager (SenTestingAdditions)
- (BOOL) fileExistsAtPathOrLink:(NSString *)aPath
    /*" This checks to see if the file path in the argument aPath points to an 
	existing file or directory. If it does then this method returns YES; 
	otherwise NO is returned (i.e. aPath is nil, empty or does not exists).
	This method follows links.

	We are using this method in place of #{-fileExistsAtPath:} in 
	NSFileManager since that method does not follow links even though the
	documentation says it does. This was the case with Xcode on Jaguar says
	William Swats as of 22-Oct-2003.
    "*/
{
    if ((aPath != nil) && ![aPath isEqualToString:@""]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:aPath traverseLink:YES];
        if ((fileAttributes != nil) && ([fileAttributes count] > 0)) {
            return YES;
        }        
    }
    return NO;
}
@end


