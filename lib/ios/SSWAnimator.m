//
//  SSWAnimator.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SSWAnimator.h"

UIViewAnimationOptions const SSWNavigationTransitionCurve = 7 << 16;

@interface SSWAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@end

@implementation SSWAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Approximated lengths of the default animations.
    return [transitionContext isInteractive] ? 0.25f : 0.5f;
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];

    // parallax effect; the offset matches the one used in the pop animation in iOS 7.1
    CGFloat toViewControllerXTranslation = - CGRectGetWidth([transitionContext containerView].bounds) * 0.3f;
    toViewController.view.bounds = [transitionContext containerView].bounds;
    toViewController.view.center = [transitionContext containerView].center;
    toViewController.view.transform = CGAffineTransformMakeTranslation(toViewControllerXTranslation, 0);

    BOOL previousClipsToBounds = fromViewController.view.clipsToBounds;
    fromViewController.view.clipsToBounds = NO;

    // in the default transition the view controller below is a little dimmer than the frontmost one
    UIView *dimmingView = [[UIView alloc] initWithFrame:toViewController.view.bounds];
    CGFloat dimAmount = [self.delegate animatorTransitionDimAmount:self];
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:dimAmount];
    [toViewController.view addSubview:dimmingView];

    // fix hidesBottomBarWhenPushed not animated properly
    UITabBarController *tabBarController = toViewController.tabBarController;
    UINavigationController *navController = toViewController.navigationController;
    UITabBar *tabBar = tabBarController.tabBar;
    BOOL shouldAddTabBarBackToTabBarController = NO;

    BOOL tabBarControllerContainsToViewController = [tabBarController.viewControllers containsObject:toViewController];
    BOOL tabBarControllerContainsNavController = [tabBarController.viewControllers containsObject:navController];
    BOOL isToViewControllerFirstInNavController = [navController.viewControllers firstObject] == toViewController;
    BOOL shouldAnimateTabBar = [self.delegate animatorShouldAnimateTabBar:self];
    if (shouldAnimateTabBar && tabBar && (tabBarControllerContainsToViewController || (isToViewControllerFirstInNavController && tabBarControllerContainsNavController))) {
        [tabBar.layer removeAllAnimations];
        
        CGRect tabBarRect = tabBar.frame;
        tabBarRect.origin.x = toViewController.view.bounds.origin.x;
        tabBar.frame = tabBarRect;
        
        [toViewController.view addSubview:tabBar];
        shouldAddTabBarBackToTabBarController = YES;
    }

    // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
    UIViewAnimationOptions curveOption = [transitionContext isInteractive] ? UIViewAnimationOptionCurveLinear : SSWNavigationTransitionCurve;

    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionTransitionNone | curveOption animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0);
        dimmingView.alpha = 0.0f;

    } completion:^(BOOL finished) {
        if (shouldAddTabBarBackToTabBarController) {
            [tabBarController.view addSubview:tabBar];
            
            CGRect tabBarRect = tabBar.frame;
            tabBarRect.origin.x = tabBarController.view.bounds.origin.x;
            tabBar.frame = tabBarRect;
        }

        [dimmingView removeFromSuperview];
        fromViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.clipsToBounds = previousClipsToBounds;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        self.toViewController.view.transform = CGAffineTransformIdentity;
    }
}

@end
