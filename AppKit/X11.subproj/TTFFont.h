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
#import FT_RENDER_H

@interface TTFFont : NSObject {
   FT_Face _face; 
   float _size;
   id _name;
}
-(CGPoint)positionOfGlyph:(CGGlyph)current precededByGlyph:(CGGlyph)previous isNominal:(BOOL *)isNominalp;
-(CGSize)advancementForGlyph:(CGGlyph)glyph;
-(float)pointSize;
-(FT_Face)face;
@end
