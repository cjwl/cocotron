/* Copyright (c) 2007 Dirk Theisen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// 01/08/2007 original - Dirk Theisen
#import <AppKit/NSFileWrapper.h>
#import <Foundation/NSDebug.h>

@implementation NSFileWrapper

/**
 * Init an instance from the file, directory, or symbolic link at the given path.<br /> 
 */
- (id) initWithPath: (NSString*)path
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (NSDebugEnabled) NSLog(@"NSFileWrapper", @"initWithPath: %@", path);
	
	// Store the full path in filename, the specification is unclear in this point
	[self setFilename: path];
	[self setPreferredFilename: [path lastPathComponent]];
	[self setFileAttributes: [fm fileAttributesAtPath: path traverseLink: NO]];
	
	NSString* fileType = [[self fileAttributes] fileType];
	if ([fileType isEqualToString: @"NSFileTypeDirectory"]) {
		NSMutableDictionary* fileWrappers = [NSMutableDictionary dictionary];
		NSEnumerator* enumerator = [fm enumeratorAtPath: path];
		NSString* filename;

		while ((filename = [enumerator nextObject]) != nil) {
			NSFileWrapper* wrapper = [[NSFileWrapper alloc] initWithPath: 
				[path stringByAppendingPathComponent: filename]];
			[fileWrappers setObject: wrapper forKey: filename]; 
			[wrapper release];
        }
		self = [self initDirectoryWithFileWrappers: fileWrappers];
    } else if ([fileType isEqualToString: @"NSFileTypeRegular"]) {
		self = [self initRegularFileWithContents: [[[NSData alloc] initWithContentsOfFile: path] autorelease]];
    } else if ([fileType isEqualToString: @"NSFileTypeSymbolicLink"]) {
		self = [self initSymbolicLinkWithDestination: 
			[fm pathContentOfSymbolicLinkAtPath: path]];
    }
	[pool release];
	return self;
}

- (NSData*) regularFileContent
{
	if (_contentType != NSFileWrapperRegularFileType) {
		[NSException raise: NSInternalInconsistencyException format: @"Try to access regular file content of something not regular file."];
	}
	return _content;
}

// Init instance of regular file type
- (id) initRegularFileWithContents: (NSData*) data
{
	if (self = [super init]) {
		_content     = [data copy];
		_contentType = NSFileWrapperRegularFileType;
	} 
	return self;
}

- (id)initDirectoryWithFileWrappers:(NSDictionary *)docs;
{
	NSParameterAssert(NO); // Not implemented yet
	return nil;
}

- (id)initSymbolicLinkWithDestination:(NSString *)path
{
	NSParameterAssert(NO); // Not implemented yet
	return nil;
}

-(void)setFilename:(NSString *)filename {
	NSParameterAssert(NO); // Not implemented yet
}

-(void)setPreferredFilename:(NSString *)filename {
	NSParameterAssert(NO); // Not implemented yet
}

- (void) setFileAttributes: (NSDictionary*) attributes
{
	if (! _fileAttributes) {
		_fileAttributes = [[NSMutableDictionary alloc] init];
    }
	
	[_fileAttributes addEntriesFromDictionary: attributes];
}

- (NSDictionary*) fileAttributes
{
	return _fileAttributes;
}

- (BOOL) isRegularFile
{
	return YES;
}
- (BOOL) isDirectory
{
	return NO; // implement
}

- (BOOL) isSymbolicLink
{
	return NO;
}


- (void) dealloc
{
	[_content release];
	[_fileAttributes release];
	[super dealloc];
}


@end
