#import <Foundation/NSObject.h>
#import <UIKit/UIKitExport.h>

typedef enum {
   UIDeviceBatteryStateUnknown=0,
   UIDeviceBatteryStateUnplugged=1,
   UIDeviceBatteryStateCharging=2,
   UIDeviceBatteryStateFull=3,
} UIDeviceBatteryState;

typedef enum {
   UIDeviceOrientationUnknown=0,
   UIDeviceOrientationPortrait=1,
   UIDeviceOrientationPortraitUpsideDown=2,
   UIDeviceOrientationLandscapeLeft=3,
   UIDeviceOrientationLandscapeRight=4,
   UIDeviceOrientationFaceUp=5,
   UIDeviceOrientationFaceDown=6,
} UIDeviceOrientation;

typedef enum {
   UIUserInterfaceIdiomPhone=0,
   UIUserInterfaceIdiomPad=1,
} UIUserInterfaceIdiom;

UIKIT_EXPORT NSString *const UIDeviceBatteryLevelDidChangeNotification;
UIKIT_EXPORT NSString *const UIDeviceBatteryStateDidChangeNotification;
UIKIT_EXPORT NSString *const UIDeviceOrientationDidChangeNotification;
UIKIT_EXPORT NSString *const UIDeviceProximityStateDidChangeNotification;

@interface UIDevice : NSObject {
}

@property(nonatomic,readonly) float batteryLevel;
@property(nonatomic,getter=isBatteryMonitoringEnabled) BOOL batteryMonitoringEnabled;
@property(nonatomic,readonly) UIDeviceBatteryState batteryState;
@property(nonatomic,readonly,getter=isGeneratingDeviceOrientationNotifications) BOOL generatesDeviceOrientationNotifications;
@property(nonatomic,readonly,retain) NSString *localizedModel;
@property(nonatomic,readonly,retain) NSString *model;
@property(nonatomic,readonly,getter=isMultitaskingSupported) BOOL multitaskingSupported;
@property(nonatomic,readonly,retain) NSString *name;
@property(nonatomic,readonly) UIDeviceOrientation orientation;
@property(nonatomic,getter=isProximityMonitoringEnabled) BOOL proximityMonitoringEnabled;
@property(nonatomic,readonly) BOOL proximityState;
@property(nonatomic,readonly,retain) NSString *systemName;
@property(nonatomic,readonly,retain) NSString *systemVersion;
@property(nonatomic,readonly,retain) NSString *uniqueIdentifier;
@property(nonatomic,readonly) UIUserInterfaceIdiom userInterfaceIdiom;

+(UIDevice *)currentDevice;

-(void)beginGeneratingDeviceOrientationNotifications;
-(void)endGeneratingDeviceOrientationNotifications;

@end
