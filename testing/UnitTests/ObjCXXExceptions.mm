//
//  ObjCXXExceptions.m
//  UnitTests
//
//  Created by Johannes Fortmann on 05.07.08.
//  Copyright 2008 -. All rights reserved.
//
#include <string>
#include <vector>

#import "ObjCXXExceptions.h"

@implementation ObjCXXExceptions
-(void)throwObjCException
{
   [NSException raise:NSInvalidArgumentException format:nil];
}

-(void)throwCXXException
{
   throw(std::string("c++ exception"));
}

-(void)testCXXThrow
{
   try {
      @try {
         [self throwCXXException];
      }
      @catch(id e) {
         STFail(@"objc exception caught");         
      }      
   }
   catch(std::vector<std::string> vec) {
      STFail(@"wrong type caught");
   }
   catch(std::string str) {
      STAssertTrue(str == std::string("c++ exception"), nil);
      return;
   }
   STFail(@"nothing caught");
}

-(void)testObjCThrow
{
   @try {
      try {
         [self throwObjCException];
      }
      catch(void* ex) {
         STFail(@"C++ exception caught");         
      }
   }
   @catch(NSString *str) {
      STFail(@"wrong type caught");
   }
   @catch(NSException *ex) {
      return;
   }
   STFail(@"nothing caught");
}

@end
