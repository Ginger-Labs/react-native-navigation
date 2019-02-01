
#import "RNNNavigationController.h"
#import "RNNModalAnimation.h"
#import "RNNRootViewController.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"

const NSInteger TOP_BAR_TRANSPARENT_TAG = 78264803;

@interface RNNNavigationController() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableDictionary* originalTopBarImages;

@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) SSWAnimator *sswAnimator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;

@end

@implementation RNNNavigationController

- (instancetype)initWithLayoutInfo:(RNNLayoutInfo *)layoutInfo childViewControllers:(NSArray *)childViewControllers options:(RNNNavigationOptions *)options defaultOptions:(RNNNavigationOptions *)defaultOptions presenter:(RNNNavigationControllerPresenter *)presenter {
	self = [super init];
	
	self.presenter = presenter;
	[self.presenter bindViewController:self];
	
	self.defaultOptions = defaultOptions;
	self.options = options;
	
	self.layoutInfo = layoutInfo;
	
	[self setViewControllers:childViewControllers];
	
	_sswAnimator = [[SSWAnimator alloc] init];
	
	SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	panRecognizer.direction = SSWPanDirectionRight;
	panRecognizer.maximumNumberOfTouches = 1;
	panRecognizer.delegate = self;
	
	_panRecognizer = panRecognizer;
	
	[self.view addGestureRecognizer:self.panRecognizer];
	
	self.delegate = self;
	
	return self;
}

- (void)dealloc {
	if (_panRecognizer) {
		[_panRecognizer removeTarget:self action:@selector(pan:)];
		[self.view removeGestureRecognizer:_panRecognizer];
	}
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
	if (parent) {
		[_presenter applyOptionsOnWillMoveToParentViewController:self.resolveOptions];
	}
}

- (void)onChildWillAppear {
	[_presenter applyOptions:self.resolveOptions];
	[((UIViewController<RNNParentProtocol> *)self.parentViewController) onChildWillAppear];
}

- (RNNNavigationOptions *)resolveOptions {
	return [(RNNNavigationOptions *)[self.getCurrentChild.resolveOptions.copy mergeOptions:self.options] withDefault:self.defaultOptions];
}

- (void)mergeOptions:(RNNNavigationOptions *)options {
	[_presenter mergeOptions:options currentOptions:self.options defaultOptions:self.defaultOptions];
	[((UIViewController<RNNLayoutProtocol> *)self.parentViewController) mergeOptions:options];
}

- (void)overrideOptions:(RNNNavigationOptions *)options {
	[self.options overrideOptions:options];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return self.getCurrentChild.supportedInterfaceOrientations;
}

- (UINavigationController *)navigationController {
	return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return self.getCurrentChild.preferredStatusBarStyle;
}

- (UIModalPresentationStyle)modalPresentationStyle {
	return self.getCurrentChild.modalPresentationStyle;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
	if (self.viewControllers.count > 1) {
		UIViewController *controller = self.viewControllers[self.viewControllers.count - 2];
		if ([controller isKindOfClass:[RNNRootViewController class]]) {
			RNNRootViewController *rnnController = (RNNRootViewController *)controller;
			[self.presenter applyOptionsBeforePopping:rnnController.resolveOptions];
		}
	}
	
	return [super popViewControllerAnimated:animated];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return [[RNNModalAnimation alloc] initWithScreenTransition:self.getCurrentChild.resolveOptions.animations.showModal isDismiss:NO];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return [[RNNModalAnimation alloc] initWithScreenTransition:self.getCurrentChild.resolveOptions.animations.dismissModal isDismiss:YES];
}

- (UIViewController *)getCurrentChild {
	return ((UIViewController<RNNParentProtocol>*)self.topViewController);
}

- (UIViewController<RNNLeafProtocol> *)getCurrentLeaf {
	return [[self getCurrentChild] getCurrentLeaf];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
	return self.topViewController;
}

- (void)setTopBarBackgroundColor:(UIColor *)backgroundColor {
	if (backgroundColor) {
		CGFloat bgColorAlpha = CGColorGetAlpha(backgroundColor.CGColor);
		
		if (bgColorAlpha == 0.0) {
			if (![self.navigationBar viewWithTag:TOP_BAR_TRANSPARENT_TAG]){
				[self storeOriginalTopBarImages:self];
				UIView *transparentView = [[UIView alloc] initWithFrame:CGRectZero];
				transparentView.backgroundColor = [UIColor clearColor];
				transparentView.tag = TOP_BAR_TRANSPARENT_TAG;
				[self.navigationBar insertSubview:transparentView atIndex:0];
			}
			self.navigationBar.translucent = YES;
			[self.navigationBar setBackgroundColor:[UIColor clearColor]];
			self.navigationBar.shadowImage = [UIImage new];
			[self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
		} else {
			self.navigationBar.barTintColor = backgroundColor;
			UIView *transparentView = [self.navigationBar viewWithTag:TOP_BAR_TRANSPARENT_TAG];
			if (transparentView){
				[transparentView removeFromSuperview];
				[self.navigationBar setBackgroundImage:self.originalTopBarImages[@"backgroundImage"] forBarMetrics:UIBarMetricsDefault];
				self.navigationBar.shadowImage = self.originalTopBarImages[@"shadowImage"];
				self.originalTopBarImages = nil;
			}
		}
	} else {
		UIView *transparentView = [self.navigationBar viewWithTag:TOP_BAR_TRANSPARENT_TAG];
		if (transparentView){
			[transparentView removeFromSuperview];
			[self.navigationBar setBackgroundImage:self.originalTopBarImages[@"backgroundImage"] ? self.originalTopBarImages[@"backgroundImage"] : [self.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault] forBarMetrics:UIBarMetricsDefault];
			self.navigationBar.shadowImage = self.originalTopBarImages[@"shadowImage"] ? self.originalTopBarImages[@"shadowImage"] : self.navigationBar.shadowImage;
			self.originalTopBarImages = nil;
		}
		
		self.navigationBar.barTintColor = nil;
	}
}

- (void)storeOriginalTopBarImages:(UINavigationController *)navigationController {
	NSMutableDictionary *originalTopBarImages = [@{} mutableCopy];
	UIImage *bgImage = [navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
	if (bgImage != nil) {
		originalTopBarImages[@"backgroundImage"] = bgImage;
	}
	UIImage *shadowImage = navigationController.navigationBar.shadowImage;
	if (shadowImage != nil) {
		originalTopBarImages[@"shadowImage"] = shadowImage;
	}
	self.originalTopBarImages = originalTopBarImages;
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
	UIView *view = self.view;
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		if (self.viewControllers.count > 1 && !self.duringAnimation) {
			self.delegate = self;
			self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
			self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
			
			[self popViewControllerAnimated:YES];
		}
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		self.topViewController.view.userInteractionEnabled = NO;
		CGPoint translation = [recognizer translationInView:view];
		// Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
		CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
		[self.interactionController updateInteractiveTransition:d];
	} else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
		if ([recognizer velocityInView:view].x > 0) {
			[self.interactionController finishInteractiveTransition];
		} else {
			[self.interactionController cancelInteractiveTransition];
			// When the transition is cancelled, `navigationController:didShowViewController:animated:` isn't called, so we have to maintain `duringAnimation`'s state here too.
			self.duringAnimation = NO;
		}
		self.interactionController = nil;
		self.topViewController.view.userInteractionEnabled = YES;
	}
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
	if (operation == UINavigationControllerOperationPop) {
		return self.sswAnimator;
	}
	return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
	return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (animated) {
		self.duringAnimation = YES;
	}
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	self.duringAnimation = NO;
	
	if (navigationController.viewControllers.count <= 1) {
		self.panRecognizer.enabled = NO;
	}
	else {
		self.panRecognizer.enabled = YES;
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)pan shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other
{
	return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
	return YES;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return [self.options.popGesture getWithDefaultValue:YES];
}

@end
