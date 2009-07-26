
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/CATransform3D.h>

@class CIFilter;

@interface CALayer : NSObject {
}

@property(copy) NSDictionary *actions;
@property CGPoint anchorPoint;
@property unsigned int autoresizingMask;
@property CGColorRef backgroundColor;
@property(copy) NSArray *backgroundFilters;
@property CGColorRef borderColor;
@property CGFloat borderWidth;
@property CGRect bounds;
@property(retain) CIFilter *compositingFilter;
@property NSArray *constraints;
@property(retain) id contents;
@property(copy) NSStrng *contentsGravity;
@property CGRect contentsRect;
@property CGFloat cornerRadius;
@property(assign) id delegate;
@property BOOL doubleSided;
@property unsigned int edgeAntialiasingMask;
@property(copy) NSArray *filters;
@property CGRect frame;
@property BOOL hidden;
@property(retain) id layoutManager;
@property(copy) NSString *magnificationFilter;
@property(retain) CALayer *mask;
@property BOOL masksToBounds;
@property(copy) NSString *minifiactionFilter;
@property(copy) NSString *name;
@property BOOL needsDisplayOnBoundsChange;
@property float opacity;
@property BOOL opaque;
@property CGPoint position;
@property CGColorRef shadowColor;
@property CGSize shadowOffset;
@property float shadowOpacity;
@property CGFloat shadowRadius;
@property(copy) NSDictionary *style;
@property(copy) NSArray *sublayers;
@property CATransform3D sublayerTransform;
@property(readonly) CALayer *superLayer;
@property CATransform3D transform;
@property(readonly) CGRect visibleRect;
@property CGFloat zPosition;

@end
