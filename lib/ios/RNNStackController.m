#import "RNNStackController.h"
#import "RNNComponentViewController.h"
#import "UIViewController+Utils.h"
#import "StackControllerDelegate.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"

@interface RNNStackController() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableDictionary* originalTopBarImages;

@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) SSWAnimator *sswAnimator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;

@end

@implementation RNNStackController {
    UIViewController* _presentedViewController;
    StackControllerDelegate* _stackDelegate;
}

- (instancetype)initWithLayoutInfo:(RNNLayoutInfo *)layoutInfo creator:(id<RNNComponentViewCreator>)creator options:(RNNNavigationOptions *)options defaultOptions:(RNNNavigationOptions *)defaultOptions presenter:(RNNBasePresenter *)presenter eventEmitter:(RNNEventEmitter *)eventEmitter childViewControllers:(NSArray *)childViewControllers {
    self = [super initWithLayoutInfo:layoutInfo creator:creator options:options defaultOptions:defaultOptions presenter:presenter eventEmitter:eventEmitter childViewControllers:childViewControllers];
    _stackDelegate = [[StackControllerDelegate alloc] initWithEventEmitter:self.eventEmitter];
    self.delegate = _stackDelegate;
    if (@available(iOS 11.0, *)) {
        self.navigationBar.prefersLargeTitles = YES;
    }
    return self;
}

- (void)setDefaultOptions:(RNNNavigationOptions *)defaultOptions {
	[super setDefaultOptions:defaultOptions];
	[self.presenter setDefaultOptions:defaultOptions];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self.presenter applyOptionsOnViewDidLayoutSubviews:self.resolveOptions];

	self.sswAnimator = [[SSWAnimator alloc] init];

	SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	panRecognizer.direction = SSWPanDirectionRight;
	panRecognizer.maximumNumberOfTouches = 1;
	panRecognizer.delegate = self;

	self.panRecognizer = panRecognizer;

	[self.view addGestureRecognizer:self.panRecognizer];

	self.delegate = self;
}

- (void)mergeChildOptions:(RNNNavigationOptions *)options child:(UIViewController *)child {
    if (child.isLastInStack) {
        [self.presenter mergeOptions:options resolvedOptions:self.resolveOptions];
    }
    [self.parentViewController mergeChildOptions:options child:child];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    [self prepareForPop];
	return [super popViewControllerAnimated:animated];
}

- (void)prepareForPop {
    if (self.viewControllers.count > 1) {
        UIViewController *controller = self.viewControllers[self.viewControllers.count - 2];
        if ([controller isKindOfClass:[RNNComponentViewController class]]) {
            RNNComponentViewController *rnnController = (RNNComponentViewController *)controller;
            [self.presenter applyOptionsBeforePopping:rnnController.resolveOptions];
        }
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
	return self.topViewController;
}

# pragma mark - UIViewController overrides

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [self.presenter willMoveToParentViewController:parent];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.presenter getStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden {
    return [self.presenter getStatusBarVisibility];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.presenter getOrientation];
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

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
	return UIMenuController.sharedMenuController.isMenuVisible == NO;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return self.navigationController.viewControllers.count > 1;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
	if ([otherGestureRecognizer isKindOfClass:NSClassFromString(@"RCTTouchHandler")] && [otherGestureRecognizer respondsToSelector:@selector(cancel)]) {
		[(id)otherGestureRecognizer cancel];
	}
	return NO;
}

@end
