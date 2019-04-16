#import "RNNSideMenuChildVC.h"
#import "UIViewController+LayoutProtocol.h"
@interface RNNSideMenuChildVC ()

@property (readwrite) RNNSideMenuChildType type;
@property (nonatomic, retain) UIViewController<RNNLayoutProtocol> *child;

@end

@implementation RNNSideMenuChildVC

- (instancetype)initWithLayoutInfo:(RNNLayoutInfo *)layoutInfo childViewControllers:(NSArray *)childViewControllers options:(RNNNavigationOptions *)options defaultOptions:(RNNNavigationOptions *)defaultOptions presenter:(RNNViewControllerPresenter *)presenter type:(RNNSideMenuChildType)type {
	self = [self initWithLayoutInfo:layoutInfo childViewControllers:childViewControllers options:options defaultOptions:defaultOptions presenter:presenter];
	
	self.type = type;

	return self;
}

- (instancetype)initWithLayoutInfo:(RNNLayoutInfo *)layoutInfo childViewControllers:(NSArray *)childViewControllers options:(RNNNavigationOptions *)options defaultOptions:(RNNNavigationOptions *)defaultOptions presenter:(RNNViewControllerPresenter *)presenter {
	self = [super init];
	
	self.child = childViewControllers[0];
	
	self.presenter = presenter;
	[self.presenter bindViewController:self];
	
	self.defaultOptions = defaultOptions;
	self.options = options;
	self.layoutInfo = layoutInfo;
	
	[self bindChildViewController:self.child];

	return self;
}

- (void)renderTreeAndWait:(BOOL)wait perform:(RNNReactViewReadyCompletionBlock)readyBlock {
	[self.getCurrentChild renderTreeAndWait:wait perform:readyBlock];
}

- (void)bindChildViewController:(UIViewController<RNNLayoutProtocol>*)child {
	self.child = child;
	[self addChildViewController:self.child];
	[self.child.view setFrame:self.view.bounds];
	[self.view addSubview:self.child.view];
	[self.view bringSubviewToFront:self.child.view];
}

- (void)setWidth:(CGFloat)width {
	CGRect frame = self.child.view.frame;
	frame.size.width = width;
	self.child.view.frame = frame;
	CALayer *TopBorder = [CALayer layer];
	CGFloat borderWidth = (1.0 / [UIScreen mainScreen].scale);
	TopBorder.frame = CGRectMake(frame.size.width - borderWidth, 0.0f, borderWidth, self.child.view.frame.size.height);
	TopBorder.backgroundColor = [UIColor colorWithRed:0.86 green:0.87 blue:0.87 alpha:1.0].CGColor;
	[self.child.view.layer addSublayer:TopBorder];
}

- (UIViewController *)getCurrentChild {
	return self.child;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return self.child.preferredStatusBarStyle;
}

@end
