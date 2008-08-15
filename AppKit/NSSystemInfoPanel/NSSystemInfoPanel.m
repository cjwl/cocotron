/* Copyright (c) 2007 Dr. Rolf Jansen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSDictionary.h>
#import <Foundation/NSPropertyListReader.h>
#import <Appkit/NSAttributedString.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSSystemInfoPanel.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSText.h>

@implementation NSSystemInfoPanel

static NSSystemInfoPanel *_sharedInfoPanel = nil;

+ (NSSystemInfoPanel *)standardAboutPanel
{
   if(_sharedInfoPanel == nil)
   {
      _sharedInfoPanel = [NSSystemInfoPanel alloc];
      if(![NSBundle loadNibNamed:@"NSSystemInfoPanel" owner:_sharedInfoPanel])
         NSLog(@"Cannot load NSSystemInfoPanel.nib");
   }
   return _sharedInfoPanel;
}


- (void)awakeFromNib
{
   NSImage *icon = [NSImage imageNamed:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFile"]];
   if (icon != nil)
      [appIconView setImage:icon];
   
   [appNameField setStringValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
   [versionField setStringValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];

   NSRect frame = [infoPanel frame];
   NSString *resourceFileName = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
   if (resourceFileName != nil)
   {
      frame.size.height += 90;
      [creditView readRTFDFromFile:resourceFileName];
   }
   else
      [creditScrollView setFrame:NSMakeRect(0, 0, 0, 0)];

   [legalTextField setStringValue:[[NSBundle mainBundle] localizedStringForKey:@"NSHumanReadableCopyright" value:@" " table:@"InfoPlist"]];

   frame.origin.y = [[NSScreen mainScreen] frame].size.height - 150 - frame.size.height;
   frame.origin.x = ([[NSScreen mainScreen] frame].size.width - frame.size.width)/2.0;
   [infoPanel setFrame:frame display:NO];
}


- (IBAction)showInfoPanel:(id)sender
{
   [infoPanel makeKeyAndOrderFront:sender];
}

@end
