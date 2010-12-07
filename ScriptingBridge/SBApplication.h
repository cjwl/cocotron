#import <Foundation/Foundation.h>

@interface SBApplication : NSObject

+applicationWithBundleIdentifier:(NSString *)identifier;

-(void)activate;
-(Class)classForScriptingClass:(NSString *)className;

@end
