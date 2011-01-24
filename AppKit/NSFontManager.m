/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSFontManager.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontFamily.h>
#import <AppKit/NSFontTypeface.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSRaise.h>

@implementation NSFontManager

static Class _fontManagerFactory;
static Class _fontPanelFactory;

+(NSFontManager *)sharedFontManager {
   NSString *name=@"NSFontManager";
   
   if(_fontManagerFactory!=Nil)
    name=NSStringFromClass(_fontManagerFactory);
   
   return NSThreadSharedInstance(name);
}

+(void)setFontManagerFactory:(Class)value {
   _fontManagerFactory=value;
}

+(void)setFontPanelFactory:(Class)value {
   _fontPanelFactory=value;
}

-init {
   _panel=nil;
   _action=@selector(changeFont:);
   _selectedFont=[[NSFont userFontOfSize:0] retain];
   _isMultiple=NO;
   return self;
}

-delegate {
   return _delegate;
}

-(SEL)action {
   return _action;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setAction:(SEL)value {
   _action=value;
}

-(NSArray *)collectionNames {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)addCollection:(NSString *)name options:(int)options {
   NSUnimplementedMethod();
   return 0;
}

-(void)addFontDescriptors:(NSArray *)descriptors toCollection:(NSString *)name {
   NSUnimplementedMethod();
}

-(BOOL)removeCollection:(NSString *)name {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)fontDescriptorsInCollection:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
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

	   // Callers expect an array of four objects
    [result addObject:[NSArray arrayWithObjects:name,traitName, [NSNumber numberWithInt: 0], [NSNumber numberWithInt: 0], nil]];
   }

   return result;
}

-(NSArray *)availableFontNamesMatchingFontDescriptor:(NSFontDescriptor *)descriptor {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)availableFontNamesWithTraits:(NSFontTraitMask)traits {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)fontNamed:(NSString *)name hasTraits:(NSFontTraitMask)traits {
   NSUnimplementedMethod();
   return 0;
}

-(NSFont *)fontWithFamily:(NSString *)familyName traits:(NSFontTraitMask)traits weight:(int)weight size:(float)size {
#if 0
   NSFontFamily *family=[NSFontFamily fontFamilyWithName:familyName];
   NSArray      *typefaces=[family typefaces];
   int           i,count=[typefaces count];
   NSString     *fontName=nil; 
   
   for(i=0;i<count;i++){
    NSFontTypeface *typeface=[typefaces objectAtIndex:i];
    NSFontTraitMask checkTraits=[typeface traits];
    
    if(((traits&NSItalicFontMask)==(checkTraits&NSItalicFontMask)) &&
        ((traits&NSBoldFontMask)==(checkTraits&NSBoldFontMask))
   }
   
   if(fontName!=nil)
    return [NSFont fontWithName:fontName size:size];
#endif
   NSUnimplementedMethod();
   return nil;
}

-(int)weightOfFont:(NSFont *)font {
   NSUnimplementedMethod();
   return 0;
}

-(NSFontTraitMask)traitsOfFont:(NSFont *)font {
   NSFontTypeface *typeface=[NSFontFamily fontTypefaceWithName:[font fontName]];

   return [typeface traits];
}

-(NSString *)localizedNameForFamily:(NSString *)family face:(NSString *)face {
   NSUnimplementedMethod();
   return 0;
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

-(BOOL)sendAction {
   return [NSApp sendAction:_action to:nil from:[NSFontManager sharedFontManager]];
}

-(BOOL)isEnabled {
   NSUnimplementedMethod();
   return 0;
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

   NSLog(@"%s failed, %@ %d",sel_getName(_cmd),[font fontName],addTraits);
   return font;
}

-(NSFont *)convertFont:(NSFont *)font toNotHaveTrait:(NSFontTraitMask)trait {
   NSUnimplementedMethod();
   return nil;
}

-(NSFont *)convertFont:(NSFont *)font toFace:(NSString *)typeface {
   NSUnimplementedMethod();
   return nil;
}

-(NSFont *)convertFont:(NSFont *)font toFamily:(NSString *)family {
   NSUnimplementedMethod();
   return nil;
}

-(NSFont *)convertWeight:(BOOL)heavierNotLighter ofFont:(NSFont *)font {
   NSUnimplementedMethod();
   return nil;
}

-(NSDictionary *)convertAttributes:(NSDictionary *)attributes {
   NSUnimplementedMethod();
   return nil;
}

-(void)addFontTrait:sender {
   NSFont *font=[self convertFont:[self selectedFont] toHaveTrait:[sender tag]];

   [self setSelectedFont:font isMultiple:NO];
   [self sendAction];
}

-(void)modifyFont:sender {
   NSFont *font=[self selectedFont];
   
   _currentFontAction=[sender tag];
   
   switch(_currentFontAction){
   
    case NSNoFontChangeAction:
     break;
     
    case NSViaPanelFontAction:
     font=[_panel panelConvertFont:font];
     break;
     
    case NSAddTraitFontAction:
     NSUnimplementedMethod();
     font=[self convertFont:font toHaveTrait:0];
     break;
     
    case NSSizeUpFontAction:
     font=[self convertFont:font toSize:[font pointSize]+1];
     break;
     
    case NSSizeDownFontAction:{
     float ps=[font pointSize];
     
     if(ps>1)
      ps-=1;
      
     font=[self convertFont:font toSize:ps];
     }
     break;
     
    case NSHeavierFontAction:
     font=[self convertWeight:YES ofFont:font];
     break;
     
    case NSLighterFontAction:
     font=[self convertWeight:NO ofFont:font];
     break;
     
    case NSRemoveTraitFontAction:
     NSUnimplementedMethod();
//     font=[self convertFont:font toNotHaveTrait:];
     break;
   }
   
   NSUnimplementedMethod();
}

-(void)modifyFontViaPanel:sender {
   NSUnimplementedMethod();
}

-(void)removeFontTrait:sender {
   NSFont *font=[self convertFont:[self selectedFont] toNotHaveTrait:[sender tag]];

   [self setSelectedFont:font isMultiple:NO];
   [self sendAction];
}

-(void)orderFrontFontPanel:sender {
   [[NSFontPanel sharedFontPanel] orderFront:sender];
}

-(void)orderFrontStylesPanel:sender {
   NSUnimplementedMethod();
}

@end
