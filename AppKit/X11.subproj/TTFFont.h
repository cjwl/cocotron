//
//  TTFFont.h
//  AppKit
//
//  Created by Johannes Fortmann on 13.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/KGFont.h>

#import <ft2build.h>
typedef size_t ptrdiff_t;
#import FT_FREETYPE_H

@interface TTFFont : KGFont {
   FT_Face _face;  
}

@end
