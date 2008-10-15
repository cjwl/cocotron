//
//  NSPlatform_linux.m
//  AppKit
//
//  Created by Johannes Fortmann on 07.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSPlatform_linux.h>
#import <Foundation/NSString.h>


@implementation NSPlatform_linux (GTKAppKit)

-(NSString *)displayClassName {
	return @"X11Display";
}

@end
