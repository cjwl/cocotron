#import <UIKit/UIView.h>
#import <UIKit/UIInterface.h>

@class UINavigationItem,UIBarButtonItem;

@interface UINavigationBar : UIView {
}

@property(nonatomic,assign) UIBarStyle barStyle;
@property(nonatomic,assign) id delegate;

@property(nonatomic,readonly,retain) UINavigationItem *backItem;
@property(nonatomic,readonly,retain) UINavigationItem *topItem;

@property(nonatomic,copy) NSArray *items;
@property(nonatomic,retain) UIColor *tintColor;
@property(nonatomic,assign,getter=isTranslucent) BOOL translucent;

-(UINavigationItem *)popNavigationItemAnimated:(BOOL)animated;

-(void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;

-(void)setItems:(NSArray *)items animated:(BOOL)animated;


@end

@interface UINavigationItem : NSObject {
}

@property(nonatomic,copy) NSString *prompt;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,retain) UIView *titleView;

@property(nonatomic,retain) UIBarButtonItem *backBarButtonItem;
@property(nonatomic,assign) BOOL hidesBackButton;
@property(nonatomic,retain) UIBarButtonItem *leftBarButtonItem;
@property(nonatomic,retain) UIBarButtonItem *rightBarButtonItem;

-initWithTitle:(NSString *)title;
-(void)setHidesBackButton:(BOOL)hidesBackButton animated:(BOOL)animated;
-(void)setLeftBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;
-(void)setRightBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;

@end
