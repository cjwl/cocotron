#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import <CoreGraphics/CoreGraphics.h>

@class NSBundle,UINavigationController,UINavigationItem,UISearchDisplayController,UISplitViewController,UITabBarController,UITabBarItem,UIBarButtonItem;

typedef enum {
   UIModalTransitionStyleCoverVertical=0,
   UIModalTransitionStyleFlipHorizontal=1,
   UIModalTransitionStyleCrossDissolve=2,
   UIModalTransitionStylePartialCurl=3,
} UIModalTransitionStyle;

typedef enum {
   UIModalPresentationFullScreen=0,
   UIModalPresentationPageSheet=1,
   UIModalPresentationFormSheet=2,
   UIModalPresentationCurrentContext=3,
} UIModalPresentationStyle;

@interface UIViewController : UIResponder {

}

@property(nonatomic,readonly,copy) NSString *nibName;
@property(nonatomic,readonly,retain) NSBundle *nibBundle;
@property(nonatomic,retain) UIView *view;
@property(nonatomic,copy) NSString *title;

@property(nonatomic,readwrite) CGSize contentSizeForViewInPopover;
@property(nonatomic,getter=isEditing) BOOL editing;
@property(nonatomic) BOOL hidesBottomBarWhenPushed;
@property(nonatomic,readonly) UIInterfaceOrientation interfaceOrientation;
@property(nonatomic,readwrite,getter=isModalInPopover) BOOL modalInPopover;
@property(nonatomic,assign) UIModalPresentationStyle modalPresentationStyle;
@property(nonatomic,assign) UIModalTransitionStyle modalTransitionStyle;
@property(nonatomic,readonly) UIViewController *modalViewController;
@property(nonatomic,readonly,retain) UINavigationController *navigationController;
@property(nonatomic,readonly,retain) UINavigationItem *navigationItem;
@property(nonatomic,readonly) UIViewController *parentViewController;
@property(nonatomic,readonly,retain) UISearchDisplayController *searchDisplayController;
@property(nonatomic,readonly,retain) UISplitViewController *splitViewController;
@property(nonatomic,readonly,retain) UITabBarController *tabBarController;
@property(nonatomic,retain) UITabBarItem *tabBarItem;
@property(nonatomic,retain) NSArray *toolbarItems;
@property(nonatomic,assign) BOOL wantsFullScreenLayout;

-initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle;

-(void)didReceiveMemoryWarning;
-(void)dismissModalViewControllerAnimated:(BOOL)animated;
-(UIBarButtonItem *)editButtonItem;
-(BOOL)isViewLoaded;
-(void)loadView;
-(void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated;
-(UIView *)rotatingFooterView;
-(UIView *)rotatingHeaderView;
-(void)setEditing:(BOOL)editing animated:(BOOL)animated;
-(void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated;
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
-(void)viewDidAppear:(BOOL)animated;
-(void)viewDidDisappear:(BOOL)animated;
-(void)viewDidLoad;
-(void)viewDidUnload;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
-(void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration;

-(void)didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end
