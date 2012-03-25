/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/*
  retargetBundle
  
  Synopsis:
  
  Quickly copies the essential parts of a .framework in the Mac OS X layout to a layout
  more suitable for Windows or Unix using the Cocotron runtime.
  
  Options:
  
   -F <directory>
   
   Adds a directory to the beginning of the search path. The initial search path is the value of the
   environment variable FRAMEWORK_SEARCH_PATHS if present, typically set by Xcode. The search path can not be empty.
   
   -framework <name>
   
   Name of framework to copy, e.g. "Foundation". The path of the framework is immediately resolved using the current search
   path. Subsequent changes to the search path will not affect the resolved path of this framework. At least
   one framework must be specified.
      
   -destination <directory>
   
   Directory to place the resulting files. If no directory is specified, the current directory is used.
  
  Discussion:
  
   While the default OS X framework organization is perfectly suitable as a compile/link time solution it
   poses cumbersome execution time implications on Windows and Unix. The OS X layout would require altering
   the dynamic link path or placing frameworks at absolute paths, which is inconvenient for developers and users.

   The convention with the Cocotron runtime is locate frameworks alongside the executables that need them, typically
   inside the .app wrapper, or in the same directory as a command line tool. Both Windows and Unix have functionality
   which makes this easy to accomplish provided the framework is reorganized.
   
   The Windows dynamic linker will automatically recognize dll's located in the same directory as the .exe and
   most Unix systems allow similar behavior to be configured using the -rpath linking option and $ORIGIN.
   
   retargetBundle will copy a framework's dynamic library to the destination directory and copy the .framework directory
   and resources to the destination directory. Symbolic links, headers and link libraries are not copied. 
      
   retargetBundle is intended to be used as the final build stage in an Xcode project, copying the essential framework
   pieces into a .app wrapper for immediate execution. The copy is done efficiently, only copying changed files.
   
   retargetBundle will not delete files, if the framework's structure has changed, you should clean your target and rebuild.
 */
 
#import <Foundation/Foundation.h>
#import <stdint.h>

static BOOL useSymlinks=NO;
static BOOL ignoreTime=NO;

static void usageAndExit(){
   NSLog(@"usage: retargetBundle [-link] [-force] -framework <name> [ -F <directory> ] -destination <directory>");
   exit(-1);
}

static void copyRegularAtInto(NSFileManager *fileManager,NSString *original,NSString *copy){
   NSError *error;
      
   [fileManager removeItemAtPath:copy error:&error];
   
	if(useSymlinks)
	{
		if(![fileManager createSymbolicLinkAtPath:copy withDestinationPath:original error:&error])
			NSLog(@"createSymbolicLinkAtPath:%@ pathContent:%@ FAILED, error=%@",copy,original,error);
	}
	else
	{
		if(![fileManager copyItemAtPath:original toPath:copy error:&error])
			NSLog(@"copyPath:%@ toPath:%@ FAILED, error=%@",original,copy,error);

	}
}

static void copyPathAtInto(NSFileManager *fileManager,NSString *original,NSString *copy,NSArray *ignore){
   NSError *error=nil;

   if([ignore containsObject:original])
    return;

   NSDictionary *attributes=[fileManager attributesOfItemAtPath:original error:&error];
   NSString     *fileType=[attributes objectForKey:NSFileType];
   
   if([fileType isEqual:NSFileTypeSymbolicLink]){
    NSString *dest;
    
    if((dest=[fileManager destinationOfSymbolicLinkAtPath:original error:&error])==nil){
     NSLog(@"destinationOfSymbolicLinkAtPath FAILED, path=%@, error=%@",original,error);
     return;
    }
    original=[[original stringByDeletingLastPathComponent] stringByAppendingPathComponent:dest];
    attributes=[fileManager attributesOfItemAtPath:original error:&error];
    fileType=[attributes objectForKey:NSFileType];
   }
   
   if([fileType isEqual:NSFileTypeRegular])
    copyRegularAtInto(fileManager,original,copy);
   else if([fileType isEqual:NSFileTypeDirectory]){
    NSArray        *children=[fileManager contentsOfDirectoryAtPath:original error:&error];
    unsigned        i,count=[children count];
    
    [fileManager createDirectoryAtPath:copy withIntermediateDirectories:YES attributes:nil error:&error];
    
    for(i=0;i<count;i++){
     NSString *check=[children objectAtIndex:i];
     NSString *originalChild=[original stringByAppendingPathComponent:check];
     NSString *copyChild=[copy stringByAppendingPathComponent:check];
      
     copyPathAtInto(fileManager,originalChild,copyChild,ignore);
    }
   }
}

static void copyChangedFilesAtInto(NSFileManager *fileManager,NSString *original,NSString *copy,NSArray *ignore){
   NSError *error;
   
   if([ignore containsObject:original])
    return;
    
   NSDictionary *attributes=[fileManager attributesOfItemAtPath:original error:&error];
   NSString     *fileType=[attributes objectForKey:NSFileType];

   if([fileType isEqual:NSFileTypeSymbolicLink]){
    NSString *dest;
    
    if((dest=[fileManager destinationOfSymbolicLinkAtPath:original error:&error])==nil){
     NSLog(@"destinationOfSymbolicLinkAtPath FAILED, path=%@, error=%@",original,error);
     return;
    }
    original=[[original stringByDeletingLastPathComponent] stringByAppendingPathComponent:dest];
    attributes=[fileManager attributesOfItemAtPath:original error:&error];
    fileType=[attributes objectForKey:NSFileType];
   }

   if(attributes==nil){
    NSLog(@"no attributes at path %@",original);
    exit(-1);
   }
   
   NSDictionary *shouldBe=[fileManager attributesOfItemAtPath:copy error:&error];
   BOOL          duplicate=NO;
   
   if(shouldBe==nil)
    copyPathAtInto(fileManager,original,copy,ignore);
   else if(![fileType isEqual:[shouldBe objectForKey:NSFileType]]){
    NSLog(@"Unable to copy file %@ onto file  %@, differing types %@!=%@",original,copy,fileType,[shouldBe objectForKey:NSFileType]);
    exit(-1);
   }
   else if([fileType isEqual:NSFileTypeRegular]){
    if(![[attributes objectForKey:NSFileSize] isEqual:[shouldBe objectForKey:NSFileSize]])
     copyRegularAtInto(fileManager,original,copy);
    if(ignoreTime || ([[attributes objectForKey:NSFileModificationDate] compare:[shouldBe objectForKey:NSFileModificationDate]]==NSOrderedDescending))
     copyRegularAtInto(fileManager,original,copy);
   }
   else if([fileType isEqual:NSFileTypeDirectory]){
    NSArray  *children=[fileManager contentsOfDirectoryAtPath:original error:&error];
    unsigned  i,count=[children count];
     
    for(i=0;i<count;i++){
     NSString *check=[children objectAtIndex:i];
     NSString *originalChild=[original stringByAppendingPathComponent:check];
     NSString *copyChild=[copy stringByAppendingPathComponent:check];
      
     copyChangedFilesAtInto(fileManager,originalChild,copyChild,ignore);
    }
   }
   else {
    NSLog(@"Unable to handle file type %@ at %@",fileType,original);
    exit(-1);
   }
}

static NSString *sharedObjectFileInFramework(NSFileManager *fileManager,NSString *original){
   NSError *error;
   NSArray *children=[fileManager contentsOfDirectoryAtPath:original error:&error];
   int      i,count=[children count];
   
   for(i=0;i<count;i++){
    NSString *check=[children objectAtIndex:i];
    NSString *extension=[check pathExtension];
    
    if([extension isEqual:@"dll"] || [extension isEqual:@"so"]){
     return check;
    }
   }
   return nil;
}

static NSMutableArray *ignoredFilesInFramework(NSFileManager *fileManager,NSString *original){
   NSString       *name=[[original lastPathComponent] stringByDeletingPathExtension];
   NSMutableArray *result=[NSMutableArray array];
   
   [result addObject:[[[original stringByAppendingPathComponent:@"lib"] stringByAppendingString:name] stringByAppendingPathExtension:@"a"]];
   [result addObject:[original stringByAppendingPathComponent:@"Versions"]];
   [result addObject:[original stringByAppendingPathComponent:@"Headers"]];
   [result addObject:[original stringByAppendingPathComponent:@"PrivateHeaders"]];
   
   return result;
}

static void copyFrameworkAtIntoDirectory(NSFileManager *fileManager,NSString *original,NSString *destination) {
   NSMutableArray  *ignore=ignoredFilesInFramework(fileManager,original);

   NSString *soFile=sharedObjectFileInFramework(fileManager,original);
   NSString *soOriginal=[original stringByAppendingPathComponent:soFile];
   NSString *soDestination=[destination stringByAppendingPathComponent:soFile];
   
   [ignore addObject:soOriginal];

   soOriginal=[soOriginal stringByResolvingSymlinksInPath];
   copyChangedFilesAtInto(fileManager,soOriginal,soDestination,nil);
   
   NSString *copy=[destination stringByAppendingPathComponent:[original lastPathComponent]];

	if(useSymlinks)
	{
		copyRegularAtInto(fileManager, original, copy);
	}
	else
		copyChangedFilesAtInto(fileManager,original,copy,ignore);
}

NSString *resolveFrameworkWithPath(NSFileManager *fileManager,NSString *name,NSArray *path){
   int i,count=[path count];
   
   for(i=0;i<count;i++){
    NSString *directory=[path objectAtIndex:i];
    NSString *check=[[directory stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"framework"];
    BOOL      isDirectory;
    
    if([fileManager fileExistsAtPath:check isDirectory:&isDirectory] && isDirectory)
     return check;
   }
   
   return nil;
}

int main(int argc,char **argv){
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   NSFileManager     *fileManager=[NSFileManager defaultManager];
   NSMutableArray    *frameworks=[NSMutableArray new];
   NSMutableArray    *searchPath=[NSMutableArray new];
   NSArray           *arguments=[[NSProcessInfo processInfo] arguments];
   NSDictionary      *environment=[[NSProcessInfo processInfo] environment];
   NSString          *destination=nil;
   
   NSArray           *settingsPath=[[environment objectForKey:@"FRAMEWORK_SEARCH_PATHS"] componentsSeparatedByString:@" "];

   [searchPath addObjectsFromArray:settingsPath];
   
   unsigned i,count=[arguments count];
   
   for(i=1;i<count;i++){
    NSString *check=[arguments objectAtIndex:i];
    
    if([check isEqual:@"-framework"]){
     i++;
     if(i>=count)
      usageAndExit();
     else {
      NSString *name=[arguments objectAtIndex:i];
      NSString *path=resolveFrameworkWithPath(fileManager,name,searchPath);
      
      if(path==nil){
       NSLog(@"Unable to find -framework %@ on path %@",name,path);
       exit(-1);
      }
      
      [frameworks addObject:path];
     }
    }
    else if([check isEqual:@"-F"]){
     i++;
     if(i>=count)
      usageAndExit();
     else {
      NSString *directory=[arguments objectAtIndex:i];
      
      [searchPath insertObject:directory atIndex:0];
     }
    }
    else if([check isEqual:@"-destination"]){
     i++;
     if(i>=count)
      usageAndExit();
     else {
      destination=[arguments objectAtIndex:i];
     }
    }
	else if([check isEqual:@"-link"])
	{
		useSymlinks = YES;
	}
	else if([check isEqual:@"-force"])
	{
		ignoreTime = YES;
	}
    else {
     usageAndExit();
    }
   }
   
   if([frameworks count]==0)
    usageAndExit();
   if([searchPath count]==0)
    usageAndExit();
    
   if(destination==nil)
    destination=[[NSFileManager defaultManager] currentDirectoryPath];

   for(i=0;i<[frameworks count];i++){
    NSString *original=[frameworks objectAtIndex:i];

    copyFrameworkAtIntoDirectory(fileManager,original,destination);
   }
   
   NSString *gdbserver=[environment objectForKey:@"GDBSERVER"];
   NSString *gdbserverPort=[environment objectForKey:@"GDBSERVER_PORT"];
   NSString *gdbserverHost=[environment objectForKey:@"GDBSERVER_HOST"];
   NSString *builtProductsDir=[environment objectForKey:@"BUILT_PRODUCTS_DIR"];
   
   if(gdbserver!=nil){
    NSString *debugger=[[destination stringByAppendingPathComponent:@"gdbserver"] stringByAppendingPathExtension:@"exe"];
    
    copyPathAtInto(fileManager,gdbserver,debugger,nil);

    if(gdbserverPort==nil)
     gdbserverPort=@"999";
     
    NSString *startline=[NSString stringWithFormat:@"START \"GDBServer listening at port %@\" gdbserver --multi localhost:%@\x0D\x0A",gdbserverPort,gdbserverPort];
    NSData *data=[startline dataUsingEncoding:NSASCIIStringEncoding];
    NSString *debug=[[destination stringByAppendingPathComponent:@"debug"] stringByAppendingPathExtension:@"bat"];

    [fileManager createFileAtPath:debug contents:data attributes:nil];
    
    NSString *wrapperName=[environment objectForKey:@"WRAPPER_NAME"];
    NSString *executableName=[environment objectForKey:@"EXECUTABLE_NAME"];
    NSString *remoteTarget=[NSString stringWithFormat:@"cd %@/Contents/Windows\nset remote exec-file %@\ntarget extended-remote %@:%@\n",wrapperName,executableName,gdbserverHost,gdbserverPort];
    NSData *remoteTargetData=[remoteTarget dataUsingEncoding:NSASCIIStringEncoding];
    NSString *remoteTargetTxt=[builtProductsDir stringByAppendingPathComponent:@"Remote-Target.txt"];
    
    [fileManager createFileAtPath:remoteTargetTxt contents:remoteTargetData attributes:nil];
   }
   
   exit(0);
}
