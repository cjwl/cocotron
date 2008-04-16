/*$Id: NSException_SenTestFailure.m,v 1.20 2005/04/02 03:18:19 phink Exp $*/

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

#import "NSException_SenTestFailure.h"
#import "SenTestCase.h"
#import "SenTestingUtilities.h"
#import <Foundation/Foundation.h>
#include <stdarg.h>


#define AsNotNilObject(object) ((object != nil) ? (id)object : (id)[NSNull null])

@implementation NSException (SenTestFailure)

- (NSString *) filename
/*" The filename containing the code that caused this exception.
"*/
{
    return [[self userInfo] objectForKey:SenTestFilenameKey];
}


- (NSSet *) ignoredSubdirectories
{
    static NSSet *ignoredSubdirectories = nil;
    if (ignoredSubdirectories == nil) {
        NSString *path = [[NSBundle bundleForClass:[SenTestCase class]] pathForResource:@"NoSourceDirectoryExtensions" ofType:@"plist"];
        ASSIGN (ignoredSubdirectories, [NSSet setWithArray:[[NSString stringWithContentsOfFile:path] propertyList]]);
    }
    return ignoredSubdirectories;
}


- (NSString *) currentDirectoryPath
{
#ifndef WIN32
    return [[NSFileManager defaultManager] currentDirectoryPath];
#else
    return [[[[NSProcessInfo processInfo] arguments] lastObject] stringByDeletingLastPathComponent];
#endif
}

- (NSString *) pathForFilename:(NSString *) aFilename
/*" This method returns the path to the file named in aFilename.
    If the aFilename is nil or empty then %Unknown.m is returned. If
    the file cannot be found in the current directory or any of sub-directories
    then the name of aFilename is returned. Note that the current 
    directory is searched only if it is a project directory. A project directory
    is one that contains the file %PB.project or XXX.xcode or XXX.pbproj where
    XXX is the name of the current directory.
"*/
{
    if ((aFilename == nil) || [aFilename isEqualToString:@""]) {
        return @"Unknown.m";
    }
    else {
        BOOL isInProjectDirectory = NO;
        NSFileManager *theFileManager = [NSFileManager defaultManager];
        NSString *currentDirectoryPath = [self currentDirectoryPath];
        NSString *currentDirectory = nil;
        NSString *projectPath = nil;
        
		NSLog(@"currentDirectoryPath %@", currentDirectoryPath);
        projectPath = [currentDirectoryPath stringByAppendingPathComponent:@"PB.project"];

        isInProjectDirectory = [theFileManager fileExistsAtPathOrLink:projectPath];
        if ( isInProjectDirectory == NO ) {
            NSString *xcodeProjectName = nil;

            currentDirectory = [currentDirectoryPath lastPathComponent];
            xcodeProjectName = [currentDirectory stringByAppendingPathExtension:@"xcode"];
            projectPath = [currentDirectoryPath stringByAppendingPathComponent:xcodeProjectName];
            isInProjectDirectory = [theFileManager fileExistsAtPathOrLink:projectPath];
        }
        if ( isInProjectDirectory == NO ) {
            NSString *pbprojProjectName = nil;
            
            currentDirectory = [currentDirectoryPath lastPathComponent];
            pbprojProjectName = [currentDirectory stringByAppendingPathExtension:@"pbproj"];
            projectPath = [currentDirectoryPath stringByAppendingPathComponent:pbprojProjectName];
            isInProjectDirectory = [theFileManager fileExistsAtPathOrLink:projectPath];
        }

		NSLog(@"projectPath %@", projectPath);
        if ( isInProjectDirectory == YES ) {
            NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:currentDirectoryPath];
            NSString *each = nil;
            while (nil != (each = [directoryEnumerator nextObject])) {
                if ([[self ignoredSubdirectories] containsObject:[each pathExtension]]) {
                    [directoryEnumerator skipDescendents];
                }
                else if ([[each lastPathComponent] isEqualToString:aFilename]) {
                    return [currentDirectoryPath stringByAppendingPathComponent:each];
                    //return each; // for OPENSTEP.
                }
            }
        }
        return aFilename;
    }
}


- (NSString *) filePathInProject
/*" This method returns the path to the source code file that caused this
    exception. If [self filename] is nil or empty then %Unknown.m is returned. If
    the file cannot be found in the current directory or any of sub-directories
    then the name of aFilename is returned. Note that the current 
    directory is searched only if it is a project directory. A project directory
    is one that contains the file %PB.project or XXX.xcode or XXX.pbproj where
    XXX is the name of the current directory.
"*/
{
	return [self filename];
 //   return [self pathForFilename:[self filename]];
}


- (NSNumber *) lineNumber
/*" The line number of the code that caused the exception.
"*/
{
    NSNumber *n = [[self userInfo] objectForKey:SenTestLineNumberKey];
    return (n == nil) ? [NSNumber numberWithInt:0] : n;
}

+ (NSException *) failureInFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the formatString and the variable number of 
    arguments that follow it (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
    given keys:
    _{SenFailureTypeKey SenUnconditionalFailure.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
"*/
{
    NSString *stkDescription = nil;
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
    
    if ( formatString != nil ) {
        va_list argList;
        
        va_start(argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString 
                                                arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } else {
        stkDescription = @"";
    }
    aReason = stkDescription;
    aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        SenUnconditionalFailure, SenFailureTypeKey,
        filename, SenTestFilenameKey,
        [NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
        stkDescription, SenTestDescriptionKey,
        nil];
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}


+ (NSException *) failureInCondition:(NSString *) condition isTrue:(BOOL) isTrue inFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the condition, the boolean isTrue and the 
    formatString and the variable number of arguments that follow it 
    (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
    given keys:
    _{SenFailureTypeKey SenConditionFailure.}
    _{SenTestConditionKey The condition (as a string) that caused this failure.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
"*/
{
    NSString *stkDescription = nil;
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
   
    if ( formatString != nil ) {
        va_list argList;
        
        va_start(argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString 
                                                arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } else {
        stkDescription = @"";
    }
    
    aReason = [NSString stringWithFormat:@"\"%@\" should be %@. %@", 
                condition, (isTrue ? @"false" : @"true"), stkDescription];
    aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    SenConditionFailure, SenFailureTypeKey,
                    condition, SenTestConditionKey,
                    filename, SenTestFilenameKey,
                    [NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
                    stkDescription, SenTestDescriptionKey,
                    nil];
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}


+ (NSException *) failureInEqualityBetweenObject:(id) left andObject:(id) right inFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the descriptions of the left and right objects and 
    the formatString and the variable number of arguments that follow it 
    (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
    given keys:
    _{SenFailureTypeKey SenEqualityFailure.}
    _{SenTestEqualityLeftKey The left object.}
    _{SenTestEqualityRightKey The right object.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
"*/
{
    NSString *stkDescription = nil;
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
	
    if ( formatString != nil ) {
        va_list argList;
        
        va_start(argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString 
                                                arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } else {
        stkDescription = @"";
    }
    
    aReason = [NSString stringWithFormat:@"'%@' should be equal to '%@' %@",
        [left description], [right description], stkDescription];
    aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        SenEqualityFailure, SenFailureTypeKey,
        AsNotNilObject (left), SenTestEqualityLeftKey,
        AsNotNilObject (right), SenTestEqualityRightKey,
        filename, SenTestFilenameKey,
        [NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
        stkDescription, SenTestDescriptionKey,
        nil];
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}


+ (NSException *) failureInEqualityBetweenValue:(NSValue *) left andValue:(NSValue *) right withAccuracy:(NSValue *) accuracy inFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
	/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the descriptions of the left and right objects and 
    the formatString and the variable number of arguments that follow it 
    (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
									  given keys:
    _{SenFailureTypeKey SenEqualityFailure.}
    _{SenTestEqualityLeftKey The left object.}
    _{SenTestEqualityRightKey The right object.}
    _{SenTestEqualityAccuracyKey The difference object.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
	"*/
{
    NSString *stkDescription = @"";
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
	
    if (formatString != nil) {
        va_list argList;
        va_start (argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } 
    	
	if (accuracy != nil) {
		aReason = [NSString stringWithFormat:
			@"'%@' should be equal to '%@' + or - '%@': %@",
			[left contentDescription], 
			[right contentDescription], 
			[accuracy contentDescription], 
			stkDescription];
		aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			SenEqualityFailure, SenFailureTypeKey,
			AsNotNilObject (left), SenTestEqualityLeftKey,
			AsNotNilObject (right), SenTestEqualityRightKey,
			AsNotNilObject (accuracy), SenTestEqualityAccuracyKey,
			filename, SenTestFilenameKey,
			[NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
			stkDescription, SenTestDescriptionKey,
			nil];		
	} 
	else {
		aReason = [NSString stringWithFormat:@"'%@' should be equal to '%@': %@",
			[left contentDescription], 
			[right contentDescription], 
			stkDescription];
		aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			SenEqualityFailure, SenFailureTypeKey,
			AsNotNilObject (left), SenTestEqualityLeftKey,
			AsNotNilObject (right), SenTestEqualityRightKey,
			filename, SenTestFilenameKey,
			[NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
			stkDescription, SenTestDescriptionKey,
			nil];		
	}	
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}


+ (NSException *) failureInRaise:(NSString *) expression exception:(NSException *) exception inFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the expression, the reason for the exception and the 
    formatString and the variable number of arguments that follow it 
    (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
    given keys:
    _{SenFailureTypeKey SenRaiseFailure.}
    _{SenTestConditionKey The expression as a string.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
"*/
{
    NSString *stkDescription = nil;
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
    
    if ( formatString != nil ) {
        va_list argList;
        
        va_start(argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString 
                                                arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } else {
        stkDescription = @"";
    }
    
    aReason = [NSString stringWithFormat:@"%@ raised %@. %@", 
        expression, [exception reason], stkDescription];
    aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        SenRaiseFailure, SenFailureTypeKey,
        expression, SenTestConditionKey,
        filename, SenTestFilenameKey,
        [NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
        stkDescription, SenTestDescriptionKey,
        nil];
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}



+ (NSException *) failureInRaise:(NSString *) expression inFile:(NSString *) filename atLine:(int) lineNumber withDescription:(NSString *)formatString, ...
/*" This method returns a NSException with a name of "SenTestFailureException".
    A reason constructed from the expression and the 
    formatString and the variable number of arguments that follow it 
    (just like in the NSString method -stringWithFormat:). 
    And an user info dictionary that contain the following information for the
    given keys:
    _{SenFailureTypeKey SenRaiseFailure.}
    _{SenTestConditionKey The expression as a string.}
    _{SenTestFilenameKey The filename containing the code that caused the exception.}
    _{SenTestLineNumberKey The lineNumber of the code that caused the exception.}
    _{SenTestDescriptionKey A description constructed from the formatString and 
    the variable number of arguments that follow it.}
"*/
{
    NSString *stkDescription = nil;
    NSString *aReason = nil;
    NSDictionary *aUserInfo = nil;
    
    if ( formatString != nil ) {
        va_list argList;
        
        va_start(argList, formatString);
        stkDescription = [[NSString alloc] initWithFormat:formatString 
                                                arguments:argList];
        [stkDescription autorelease];
        va_end(argList);
    } else {
        stkDescription = @"";
    }
    
    aReason = [NSString stringWithFormat:@"%@ should raise. %@", 
                expression, stkDescription];
    aUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        SenRaiseFailure, SenFailureTypeKey,
        expression, SenTestConditionKey,
        filename, SenTestFilenameKey,
        [NSNumber numberWithInt:lineNumber], SenTestLineNumberKey,
        stkDescription, SenTestDescriptionKey,
        nil];
    return [self exceptionWithName:SenTestFailureException
                            reason:aReason
                          userInfo:aUserInfo];
}


@end


NSString * const SenTestFailureException = @"SenTestFailureException";

NSString * const SenFailureTypeKey = @"SenFailureTypeKey";
NSString * const SenUnconditionalFailure = @"SenUnconditionalFailure";
NSString * const SenConditionFailure = @"SenConditionFailure";
NSString * const SenEqualityFailure = @"SenEqualityFailure";
NSString * const SenRaiseFailure = @"SenRaiseFailure";

NSString * const SenTestConditionKey = @"SenTestConditionKey";
NSString * const SenTestEqualityLeftKey = @"SenTestEqualityLeftKey";
NSString * const SenTestEqualityRightKey = @"SenTestEqualityRightKey";
NSString * const SenTestEqualityAccuracyKey = @"SenTestEqualityAccuracyKey";

NSString * const SenTestFilenameKey = @"SenTestFilenameKey";
NSString * const SenTestLineNumberKey = @"SenTestLineNumberKey";
NSString * const SenTestDescriptionKey = @"SenTestDescriptionKey";
