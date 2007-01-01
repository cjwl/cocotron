/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontFamily.h>
#import <AppKit/NSFontTypeface.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenu.h>

@implementation NSFontManager

+(NSFontManager *)sharedFontManager {
   return NSThreadSharedInstance(@"NSFontManager");
}

-init {
   _panel=nil;
   _selectedFont=[[NSFont userFontOfSize:0] retain];
   _isMultiple=NO;
   return self;
}

-(void)setFontPanel:(NSFontPanel *)panel {
   panel=[panel retain];
   [_panel release];
   _panel=panel;
}

-(NSFontPanel *)fontPanel:(BOOL)create {
   if(_panel==nil && create){
    [NSBundle loadNibNamed:@"NSFontPanel" owner:self];
   }

   [_panel setPanelFont:_selectedFont isMultiple:_isMultiple];
   return _panel;
}

-(NSFontTraitMask)traitsOfFont:(NSFont *)font {
   NSFontTypeface *typeface=[NSFontFamily fontTypefaceWithName:[font fontName]];

   return [typeface traits];
}

-(NSFont *)convertFont:(NSFont *)font {
   if(_panel==nil)
    return _selectedFont;

   return [_panel panelConvertFont:font];
}

-(NSFont *)convertFont:(NSFont *)font toSize:(float)size {
   if(size==[font pointSize])
    return font;

   return [NSFont fontWithName:[font fontName] size:size];
}

-(NSFont *)convertFont:(NSFont *)font toHaveTrait:(NSFontTraitMask)addTraits {
   NSFontFamily   *family=[NSFontFamily fontFamilyWithTypefaceName:[font fontName]];
   NSFontTypeface *typeface=[family typefaceWithName:[font fontName]];
   NSFontTraitMask traits=[typeface traits];
   NSFontTypeface *newface;

   if(addTraits&NSItalicFontMask)
    traits|=NSItalicFontMask;
   if(addTraits&NSBoldFontMask)
    traits|=NSBoldFontMask;
   if(addTraits&NSUnboldFontMask)
    traits&=~NSBoldFontMask;
   if(addTraits&NSUnitalicFontMask)
    traits&=~NSItalicFontMask;

   newface=[family typefaceWithTraits:traits];

   if(newface!=nil)
    return [NSFont fontWithName:[newface name] size:[font pointSize]];

   NSLog(@"%s failed, %@ %d",SELNAME(_cmd),[font fontName],addTraits);
   NSUnimplementedMethod();
   return font;
}

-(BOOL)isMultiple {
   return _isMultiple;
}

-(NSFont *)selectedFont {
   return _selectedFont;
}

-(void)_configureMenu:(NSMenu *)menu forFont:(NSFont *)font {
   NSArray *items=[menu itemArray];
   int      i,count=[items count];

   for(i=0;i<count;i++){
    NSMenuItem *item=[items objectAtIndex:i];

    if([item hasSubmenu])
     [self _configureMenu:[item submenu] forFont:font];
    else if([item action]==@selector(addFontTrait:) && [item target]==self){
     unsigned        tag=[item tag];
     NSFontTraitMask traits=[self traitsOfFont:font];

     if(tag&(NSItalicFontMask|NSUnitalicFontMask)){
      if(traits&NSItalicFontMask){
       [item setTag:NSUnitalicFontMask];
       [item setTitle:@"Unitalic"];
      }
      else {
       [item setTag:NSItalicFontMask];
       [item setTitle:@"Italic"];
      }
     }
     if(tag&(NSBoldFontMask|NSUnboldFontMask)){
      if(traits& NSBoldFontMask){
       [item setTag:NSUnboldFontMask];
       [item setTitle:@"Unbold"];
      }
      else {
       [item setTag:NSBoldFontMask];
       [item setTitle:@"Bold"];
      }
     }
    }
   }
}

-(void)setSelectedFont:(NSFont *)font isMultiple:(BOOL)flag {
   [_selectedFont autorelease];
   _selectedFont=[font retain];
   _isMultiple=flag;

   [[self fontPanel:NO] setPanelFont:font isMultiple:flag];
   [self _configureMenu:[NSApp mainMenu] forFont:font];
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-delegate {
   return _delegate;
}

-(NSArray *)availableFonts {
   NSMutableArray *result=[NSMutableArray array];
   NSArray        *families=[NSFontFamily allFontFamilyNames];
   int             i,count=[families count];

   for(i=0;i<count;i++){
    NSString     *familyName=[families objectAtIndex:i];
    NSFontFamily *family=[NSFontFamily fontFamilyWithName:familyName];
    NSArray      *typefaces=[family typefaces];
    int           t,tcount=[typefaces count];

    for(t=0;t<tcount;t++){
     NSFontTypeface *typeface=[typefaces objectAtIndex:t];
     NSString       *name=[typeface name];

     [result addObject:name];
    }
   }

   return result;
}

-(NSArray *)availableFontFamilies {
   NSArray *families=[NSFontFamily allFontFamilyNames];

   if(![_delegate respondsToSelector:@selector(fontManager:willIncludeFont:)])
    return families;
   else {
    NSMutableArray *result=[NSMutableArray array];
    int             i,count=[families count];

    for(i=0;i<count;i++){
     NSString     *familyName=[families objectAtIndex:i];
     NSFontFamily *family=[NSFontFamily fontFamilyWithName:familyName];
     NSArray      *typefaces=[family typefaces];
     int           t,tcount=[typefaces count];

     for(t=0;t<tcount;t++){
      NSFontTypeface *typeface=[typefaces objectAtIndex:t];
      NSString       *name=[typeface name];

      if([_delegate fontManager:self willIncludeFont:name]){
       [result addObject:familyName];
       break;
      }
     }
    }

    return result;
   }
}

-(NSArray *)availableMembersOfFontFamily:(NSString *)familyName {
   NSMutableArray *result=[NSMutableArray array];
   NSFontFamily   *family=[NSFontFamily fontFamilyWithName:familyName];
   NSArray        *typefaces=[family typefaces];
   int             i,count=[typefaces count];

   for(i=0;i<count;i++){
    NSFontTypeface *typeface=[typefaces objectAtIndex:i];
    NSString       *name=[typeface name];
    NSString       *traitName=[typeface traitName];

    [result addObject:[NSArray arrayWithObjects:name,traitName,nil]];
   }

   return result;
}

-(void)addFontTrait:sender {
   NSFont *font=[self convertFont:[self selectedFont] toHaveTrait:[sender tag]];

   [self setSelectedFont:font isMultiple:NO];
   [NSApp sendAction:@selector(changeFont:) to:nil from:[NSFontManager sharedFontManager]];
}

-(void)orderFrontFontPanel:sender {
   [[NSFontPanel sharedFontPanel] orderFront:sender];
}

@end
